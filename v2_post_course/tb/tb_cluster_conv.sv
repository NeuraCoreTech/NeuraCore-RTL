`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_cluster_conv
// Project Name: 
// Target Devices: xc7a100t / xc7z020
// Tool Versions: 
// Description: Self-checking convolution TB for cluster_top (golden model,
//              valid/ready-aware drivers, stalls, multi-seed, coverage gate).
// 
// Dependencies: cluster_top, xbip_multadd_8bit IP
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Drain hold-on-full coverage gate, FIFO-fill test, cycle/util report
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//==============================================================================
// tb_cluster_conv : self-checking TB for cluster_top (ROWS x COLS below)
//
// Golden model (E output columns, stride 1, no padding), slot = x*nf + f:
//   out[c][x*nf+f] = psum_in[c][x*nf+f]
//     + sum_r sum_ch sum_k  ifm[r][ch*W + x + k] * flt[r][c][(f*nc+ch)*3+k]
//   with W = E + 2 (ifmap row width per channel)
//
// Stream ordering matches PEControlUnit addressing:
//   filter stream per PE : f-major, then channel, then k   (nf*nc*3 words)
//   ifmap stream per row : channel-major, W pixels each    (nc*W words)
//   psum_in / psum_out   : x-major, then f                 (E*nf words)
//
// Every output word read from the top-row FIFOs is compared to the model.
// Each test: config -> start -> concurrent filter/ifmap/psum_in drivers and
// output collectors (all valid/ready aware) -> watchdog -> compare.
//
// Coverage gate: the pipelined drain's hold-on-full path (dv & fifo_full) must
// be hit at least once over the whole run, otherwise the suite fails.
//
// Plusargs: +seeds=N (default 8)  +seed0=S (first seed, default 1)  +verbose
//==============================================================================
module tb_cluster_conv;

    localparam ROWS    = 2;
    localparam COLS    = 2;
    localparam DW      = 8;
    localparam PW      = 24;
    localparam MAXF    = 24;
    localparam MAXC    = 4;
    localparam MAXE    = 16;     // must be <= PE_top MAXOFMAP (default 16; cluster_top doesn't override it)
    localparam K       = 3;
    localparam CFG_F_W = $clog2(MAXF + 1);
    localparam CFG_C_W = $clog2(MAXC + 1);
    localparam CFG_X_W = 8;
    localparam TIMEOUT = 60000;   // cycles per tile

    // Positive-only testing: ifmap AND filter are unsigned, all psums >= 0.
    // Matches an unsigned xbip_multadd_8bit. (Set FLT_SIGNED=1 later if the
    // IP is switched to signed weights; negative psum_in is not generated.)
    localparam bit IFM_SIGNED = 1'b0;
    localparam bit FLT_SIGNED = 1'b0;

    logic clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------- DUT I/O
    logic reset, start, done;

    logic [CFG_F_W-1:0] cfg_num_filters;
    logic [CFG_C_W-1:0] cfg_num_channels;
    logic [CFG_X_W-1:0] cfg_ofmap_len;
    logic               cfg_psum_in_valid;

    logic [ROWS-1:0][COLS-1:0]          filter_valid;
    logic [ROWS-1:0][COLS-1:0][DW-1:0]  filter_data;
    logic [ROWS-1:0][COLS-1:0]          filter_ready;

    logic [ROWS-1:0]                    ifmap_valid;
    logic [ROWS-1:0][DW-1:0]            ifmap_data;
    logic [ROWS-1:0]                    ifmap_ready;

    logic [COLS-1:0]                    psum_in_valid;
    logic [COLS-1:0][PW-1:0]            psum_in_data;
    logic [COLS-1:0]                    psum_in_ready;

    logic [COLS-1:0][PW-1:0]            psum_out_data;
    logic [COLS-1:0]                    psum_out_valid;
    logic [COLS-1:0]                    psum_out_re;

    cluster_top #(
        .PE_ROWS    (ROWS),
        .PE_COLS    (COLS),
        .DATA_WIDTH (DW),
        .PSUM_WIDTH (PW),
        .MAXKERNELS (MAXF),
        .MAXCHANNELS(MAXC)
    ) dut (.*);

    // ------------------------------------------------------------- TB storage
    logic        [DW-1:0] ifm  [ROWS][MAXC*(MAXE+K-1)];
    logic        [DW-1:0] flt  [ROWS][COLS][MAXF*MAXC*K];
    logic signed [PW-1:0] ext  [COLS][MAXF*MAXE];
    logic signed [PW-1:0] expv [COLS][MAXF*MAXE];
    logic        [PW-1:0] got  [COLS][MAXF*MAXE];

    // random stall knobs (max idle cycles inserted between beats)
    int gap_filt = 0, gap_ifm = 0, gap_psum = 0, gap_out = 0;

    bit abort_tile, streams_done, timed_out;
    int done_cnt = 0;
    int cyc = 0, done_cyc = 0;
    int tests_run = 0, tests_failed = 0;
    int cur_seed = 1, nseeds = 30, seed0 = 1, seed_dummy;
    bit verbose = 0;

    task automatic set_gaps(input int f, input int i, input int p, input int o);
        gap_filt = f; gap_ifm = i; gap_psum = p; gap_out = o;
    endtask

    // ---------------------------------------------------------------- monitors
    // cycle counter + done monitor in one block so cyc and done_cyc can't race
    always @(posedge clk) begin
        cyc = cyc + 1;
        if (done === 1'b1) begin
            done_cnt = done_cnt + 1;
            done_cyc = cyc;
        end
    end

    // coverage: drain hold-on-full (dv & fifo_full) per PE
    int hold_cyc [ROWS][COLS];
    for (genvar r = 0; r < ROWS; r++) begin : g_cov_r
        for (genvar c = 0; c < COLS; c++) begin : g_cov_c
            always @(posedge clk)
                if (!reset &&
                    dut.gen_pe_row[r].gen_pe_col[c].u_pe.u_ctrl.dv === 1'b1 &&
                    dut.gen_pe_row[r].gen_pe_col[c].u_pe.fifo_full === 1'b1)
                    hold_cyc[r][c] = hold_cyc[r][c] + 1;
        end
    end

    // ---------------------------------------------------------------- stimulus
    // raw 8-bit patterns; interpretation (signed/unsigned) is applied in the model
    function automatic logic [DW-1:0] rnd8(input int mode, input bit is_signed);
        case (mode)
            0:       return DW'($urandom_range(1, 7));
            1:       return is_signed ? DW'(int'($urandom_range(0, 15)) - 8)
                                      : DW'($urandom_range(0, 15));
            2:       return DW'($urandom);
            default: return is_signed ? (($urandom_range(0, 1) != 0) ? 8'h7F : 8'h80)
                                      : (($urandom_range(0, 1) != 0) ? 8'hFF : 8'h00);
        endcase
    endfunction

    function automatic longint ival(input logic [DW-1:0] x);
        return IFM_SIGNED ? longint'($signed(x)) : longint'(x);
    endfunction
    function automatic longint fval(input logic [DW-1:0] x);
        return FLT_SIGNED ? longint'($signed(x)) : longint'(x);
    endfunction

    // mode 0: small +   1: small/mid   2: full-range
    // mode 3: extremes (0/255)   4: directed (original TB values)
    task automatic gen_stim(input int nf, input int nc, input int E, input int mode, input bit ext_nz);
        for (int r = 0; r < ROWS; r++)
            for (int i = 0; i < nc*(E+K-1); i++)
                ifm[r][i] = (mode == 4) ? DW'(i + 1) : rnd8(mode, IFM_SIGNED);

        for (int r = 0; r < ROWS; r++)
            for (int c = 0; c < COLS; c++)
                for (int i = 0; i < nf*nc*K; i++)
                    flt[r][c][i] = (mode == 4) ? DW'(2*r + c + 1 + i) : rnd8(mode, FLT_SIGNED);

        for (int c = 0; c < COLS; c++)
            for (int i = 0; i < MAXF*MAXE; i++)
                ext[c][i] = ext_nz ? PW'($urandom_range(0, 2000)) : '0;
    endtask

    // chain=1 : every row contributes, bottom row preloads ext psum
    // chain=0 : cfg_psum_in_valid=0 -> rows don't chain, top row only
    task automatic compute_expected(input int nf, input int nc, input int E, input bit chain);
        int W;
        W = E + K - 1;
        for (int c = 0; c < COLS; c++)
            for (int x = 0; x < E; x++)
                for (int f = 0; f < nf; f++) begin
                    longint acc;
                    acc = chain ? longint'(ext[c][x*nf+f]) : 0;
                    for (int r = (chain ? 0 : ROWS-1); r < ROWS; r++)
                        for (int ch = 0; ch < nc; ch++)
                            for (int k = 0; k < K; k++)
                                acc += ival(ifm[r][ch*W+x+k]) * fval(flt[r][c][(f*nc+ch)*K+k]);
                    expv[c][x*nf+f] = PW'(acc);
                end
    endtask

    // ----------------------------------------------------------------- drivers
    // All drivers start aligned to a negedge. DUT samples at the next posedge,
    // ready only changes on posedge, so "ready seen at negedge" == "fires".
    task automatic drive_filter(input int r, input int c, input int n);
        for (int i = 0; i < n && !abort_tile; i++) begin
            repeat ($urandom_range(0, gap_filt)) @(negedge clk);
            filter_valid[r][c] = 1'b1;
            filter_data [r][c] = flt[r][c][i];
            while (filter_ready[r][c] !== 1'b1 && !abort_tile) @(negedge clk);
            @(negedge clk);
            filter_valid[r][c] = 1'b0;
        end
        filter_valid[r][c] = 1'b0;
    endtask

    task automatic drive_ifmap(input int r, input int n);
        for (int i = 0; i < n && !abort_tile; i++) begin
            repeat ($urandom_range(0, gap_ifm)) @(negedge clk);
            ifmap_valid[r] = 1'b1;
            ifmap_data [r] = ifm[r][i];
            while (ifmap_ready[r] !== 1'b1 && !abort_tile) @(negedge clk);
            @(negedge clk);
            ifmap_valid[r] = 1'b0;
        end
        ifmap_valid[r] = 1'b0;
    endtask

    task automatic drive_psum_in(input int c, input int n);
        for (int i = 0; i < n && !abort_tile; i++) begin
            repeat ($urandom_range(0, gap_psum)) @(negedge clk);
            psum_in_valid[c] = 1'b1;
            psum_in_data [c] = ext[c][i];
            while (psum_in_ready[c] !== 1'b1 && !abort_tile) @(negedge clk);
            @(negedge clk);
            psum_in_valid[c] = 1'b0;
        end
        psum_in_valid[c] = 1'b0;
    endtask

    // FIFO is first-word-fall-through: data valid whenever valid=1
    task automatic collect_col(input int c, input int n);
        for (int i = 0; i < n && !abort_tile; i++) begin
            while (psum_out_valid[c] !== 1'b1 && !abort_tile) begin
                psum_out_re[c] = 1'b0;
                @(negedge clk);
            end
            if (abort_tile) break;
            repeat ($urandom_range(0, gap_out)) begin
                psum_out_re[c] = 1'b0;
                @(negedge clk);
            end
            got[c][i]      = psum_out_data[c];
            psum_out_re[c] = 1'b1;
            @(negedge clk);
        end
        psum_out_re[c] = 1'b0;
    endtask

    task automatic do_streams(input int nf, input int nc, input int E, input bit chain);
        for (int r = 0; r < ROWS; r++) begin
            automatic int rr = r;
            fork drive_ifmap(rr, nc*(E+K-1)); join_none
            for (int c = 0; c < COLS; c++) begin
                automatic int cc = c;
                fork drive_filter(rr, cc, nf*nc*K); join_none
            end
        end
        for (int c = 0; c < COLS; c++) begin
            automatic int cc = c;
            if (chain) begin
                fork drive_psum_in(cc, nf*E); join_none
            end
            fork collect_col(cc, nf*E); join_none
        end
        wait fork;   // children of this process only
    endtask

    // ------------------------------------------------------------------- reset
    task automatic do_reset();
        @(negedge clk);
        reset = 1'b1;
        start = 1'b0;
        filter_valid = '0; filter_data = '0;
        ifmap_valid  = '0; ifmap_data  = '0;
        psum_in_valid = '0; psum_in_data = '0;
        psum_out_re  = '0;
        repeat (4) @(negedge clk);
        reset = 1'b0;
        repeat (2) @(negedge clk);
    endtask

    // ---------------------------------------------------------------- one tile
    task automatic run_tile(input string name, input int nf, input int nc, input int E,
                            input bit chain, input int mode, input bit ext_nz);
        int errs = 0;
        int t_start;
        gen_stim(nf, nc, E, mode, ext_nz);
        compute_expected(nf, nc, E, chain);

        cfg_num_filters   = nf;
        cfg_num_channels  = nc;
        cfg_ofmap_len     = E;
        cfg_psum_in_valid = chain;

        for (int c = 0; c < COLS; c++)
            for (int f = 0; f < MAXF*MAXE; f++) got[c][f] = 'x;

        done_cnt = 0; abort_tile = 0; timed_out = 0; streams_done = 0;
        tests_run++;

        @(negedge clk); start = 1'b1;  t_start = cyc;
        @(negedge clk); start = 1'b0;

        fork
            begin : streams
                do_streams(nf, nc, E, chain);
                streams_done = 1;
            end
            begin : wd
                for (int t = 0; t < TIMEOUT && !streams_done; t++) @(posedge clk);
                if (!streams_done) begin
                    timed_out = 1; abort_tile = 1;   // drivers/collectors bail out
                end
            end
        join

        repeat (30) @(negedge clk);   // let done + any stray outputs show up

        if (timed_out) begin
            errs++;
            $display("    TIMEOUT: streams did not complete in %0d cycles", TIMEOUT);
        end else begin
            if (done_cnt != 1) begin
                errs++;
                $display("    DONE pulses seen = %0d (expected exactly 1 per tile).", done_cnt);
            end

            for (int c = 0; c < COLS; c++)
                for (int i = 0; i < nf*E; i++)
                    if (got[c][i] !== expv[c][i]) begin
                        errs++;
                        if (errs <= 8)
                            $display("    MISMATCH col%0d x%0d filt%0d: got %0d, exp %0d",
                                     c, i/nf, i%nf, $signed(got[c][i]), $signed(expv[c][i]));
                    end

            if (|psum_out_valid) begin
                errs++;
                $display("    EXTRA output words left in top-row FIFO: valid=%b", psum_out_valid);
            end
            if (chain)
                for (int r = 0; r < ROWS-1; r++)
                    for (int c = 0; c < COLS; c++)
                        if (dut.pe_psum_out_valid[r][c] === 1'b1) begin
                            errs++;
                            $display("    row %0d col %0d FIFO not drained by row above", r, c);
                        end
        end

        if (errs == 0) begin
            if (verbose)
                $display("[PASS] %s  (nf=%0d nc=%0d E=%0d chain=%0d)  cycles=%0d  util=%0.1f%%",
                         name, nf, nc, E, chain, done_cyc - t_start,
                         100.0 * nf * nc * K * E / (done_cyc - t_start));
        end
        else begin
            $display("[FAIL] seed=%0d %s  (nf=%0d nc=%0d E=%0d chain=%0d)  %0d error(s)", cur_seed, name, nf, nc, E, chain, errs);
            tests_failed++;
        end

        // after a failure, or unchained run (row-0 FIFOs never popped), start clean
        if (errs != 0 || !chain) do_reset();
    endtask

    // -------------------------------------------------------------- test suite
    task automatic run_suite();
        set_gaps(0, 0, 0, 0);
        // ---- E = 1 (regression of the original single-output behaviour)
        run_tile("directed: original TB values", 1, 1, 1, 1, 4, 0);
        run_tile("unchained (cfg_psum_in_valid=0), top row only", 1, 1, 1, 0, 4, 0);
        run_tile("small positive",            1, 1, 1, 1, 0, 0);
        run_tile("mid-range, 3 channels",     1, 3, 1, 1, 1, 0);
        run_tile("mid-range, 4 filters",      4, 1, 1, 1, 1, 0);
        run_tile("5f/4c + nonzero psum_in",   5, 4, 1, 1, 2, 1);
        run_tile("max 24f/4c + psum_in",     24, 4, 1, 1, 2, 1);
        run_tile("extremes (0/255 operands)", 8, 4, 1, 1, 3, 0);

        // ---- E > 1 (sliding window, per-x psum slots)
        run_tile("E=3 directed",              1, 1, 3, 1, 4, 0);
        run_tile("E=2 small positive",        2, 1, 2, 1, 0, 0);
        run_tile("E=5, 4f/2c",                4, 2, 5, 1, 2, 0);
        run_tile("E=8, 3f/3c + psum_in",      3, 3, 8, 1, 2, 1);
        run_tile("E=16 max, 24f/4c + psum_in",24, 4, 16, 1, 2, 1);
        run_tile("E=16 extremes",             6, 4, 16, 1, 3, 0);
        run_tile("E=4 unchained",             3, 2, 4, 0, 2, 0);

        set_gaps(0, 3, 3, 3);   // ifmap/psum_in stalls + output back-pressure
        run_tile("stalls + back-pressure E=1", 6, 3, 1, 1, 2, 1);
        run_tile("stalls + back-pressure E=6", 5, 2, 6, 1, 2, 1);

        // drain back-pressure: 384 words/col >> FIFO_DEPTH (32), slow collector
        set_gaps(0, 0, 0, 8);
        run_tile("drain back-pressure, FIFO fills", 24, 1, 16, 1, 2, 1);

        set_gaps(0, 0, 0, 0);
        for (int i = 0; i < 25; i++)
            run_tile($sformatf("random back-to-back #%0d", i),
                     $urandom_range(1, MAXF), $urandom_range(1, MAXC), $urandom_range(1, MAXE),
                     1, 2, $urandom_range(0, 1));

        // Per-PE random filter stalls -> PEs leave FILTER_LOAD at different times.
        set_gaps(4, 0, 0, 0);
        run_tile("SKEWED filter load (ifmap valid/ready protocol)", 3, 2, 1, 1, 2, 0);
        run_tile("SKEWED filter load, E=4",                         3, 2, 4, 1, 2, 1);

    endtask

    // -------------------------------------------------------------------- main
    initial begin
        cfg_num_filters = 1; cfg_num_channels = 1; cfg_ofmap_len = 1; cfg_psum_in_valid = 0;
        reset = 1; start = 0;
        if (!$value$plusargs("seeds=%d", nseeds)) nseeds = 8;
        if (!$value$plusargs("seed0=%d", seed0))  seed0  = 1;
        if ($test$plusargs("verbose")) verbose = 1;
        do_reset();

        $display("\n=========== cluster_top convolution TB (%0d seeds from %0d) ===========", nseeds, seed0);

        for (int sd = 0; sd < nseeds; sd++) begin
            int f0;
            cur_seed = seed0 + sd;
            seed_dummy = $urandom(cur_seed);   // reseed this thread; forked drivers inherit
            f0 = tests_failed;
            run_suite();
            $display("seed %0d: %0d failing test(s)", cur_seed, tests_failed - f0);
        end

        // coverage gate: hold-on-full must have been exercised
        begin
            int hold_total = 0;
            for (int r = 0; r < ROWS; r++)
                for (int c = 0; c < COLS; c++) hold_total += hold_cyc[r][c];
            $display(" drain hold-on-full cycles (dv & fifo_full): %0d", hold_total);
            if (hold_total == 0) begin
                tests_failed++;
                $display("[FAIL] coverage: hold-on-full path never exercised");
            end
        end

        $display("\n==================================================");
        $display(" %0d / %0d tests failed over %0d seed(s)", tests_failed, tests_run, nseeds);
        $display("==================================================");
        if (tests_failed == 0) $display("CLUSTER TEST PASSED");
        else                   $display("CLUSTER TEST FAILED");
        $finish;
    end

endmodule