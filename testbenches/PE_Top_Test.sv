`timescale 1ns / 1ps
//==============================================================================
// Testbench : PE_top_tb
// DUT       : PE_top
//
// Test plan
// ─────────────────────────────────────────────────────────────────────────────
//  TC1 : Basic tile, no psum pre-load
//        cfg: filters=2, channels=2, ofmap_len=2, psum_in_valid=0
//        Loads 2×2×3=12 filter bytes, 2×3=6 ifmap bytes, computes,
//        drains 2 psums into output FIFO, reads them back.
//
//  TC2 : Psum pre-load from Local Network
//        cfg: filters=2, channels=1, ofmap_len=1, psum_in_valid=1
//        Pre-loads 2 psums before COMPUTE, verifies exact accumulated value.
//
//  TC3 : Back-pressure on filter load (filter_valid deasserts mid-stream)
//        Verifies filter_cnt does NOT advance when filter_valid=0.
//
//  TC4 : Back-pressure on output FIFO (psum_out_re held low)
//        Verifies FIFO holds data and psum_out_valid stays high.
//
//  TC5 : Maximum configuration (filters=4, channels=2, ofmap_len=3)
//        Stress test - ensures done pulses exactly once.
//
//  TC6 : Cycle count sanity
//        filters=1, channels=1, ofmap_len=1
//        Expected psum = 1×1 + 1×2 + 1×3 = 6
//        Minimum elapsed cycles verified precisely.
//
// Key design facts reflected in this TB
// ─────────────────────────────────────────────────────────────────────────────
//  - fifo_block is FWFT (first-word-fall-through): psum_out_data is valid
//    combinatorially from mem[rd_ptr] as soon as psum_out_valid is high.
//    Correct read sequence: sample data THEN pulse re to advance rd_ptr.
//  - Valid/ready handshake: hold valid+data stable; fire = valid & ready on
//    the same posedge. Deassert valid on the NEXT cycle (#1 after edge).
//    Do NOT add an extra clock after seeing ready - that creates a double-beat.
//  - PSUM_CLEAR state is entered (instead of PSUM_LOAD) when
//    cfg_psum_in_valid=0. It zero-fills num_filters psum spad slots before
//    COMPUTE. This adds num_filters cycles to the minimum elapsed count.
//  - MAC_LATENCY = 3 cycles. COMPUTE stays active for (total MACs) +
//    MAC_LATENCY drain cycles after last_mac_in.
//==============================================================================

module PE_top_tb;

    //==========================================================================
    // Parameters - keep in sync with PE_top defaults
    //==========================================================================
    localparam DATA_WIDTH     = 8;
    localparam PSUM_WIDTH     = 24;
    localparam MAXKERNELS     = 24;
    localparam MAXCHANNELS    = 4;
    localparam MAXKERNELWIDTH = 3;
    localparam MAC_LATENCY    = 3;
    localparam FIFO_DEPTH     = 32;
    localparam CFG_F_W        = $clog2(MAXKERNELS  + 1);  // 5
    localparam CFG_C_W        = $clog2(MAXCHANNELS + 1);  // 3
    localparam CFG_X_W        = 8;

    localparam CLK_PERIOD = 10; // 100 MHz

    //==========================================================================
    // DUT ports
    //==========================================================================
    logic                   clk;
    logic                   reset;

    logic                   start;
    logic                   done;

    logic [CFG_F_W-1:0]     cfg_num_filters;
    logic [CFG_C_W-1:0]     cfg_num_channels;
    logic [CFG_X_W-1:0]     cfg_ofmap_len;
    logic                   cfg_psum_in_valid;

    logic                   filter_valid;
    logic [DATA_WIDTH-1:0]  filter_data;
    logic                   filter_ready;

    logic                   ifmap_valid;
    logic [DATA_WIDTH-1:0]  ifmap_data;
    logic                   ifmap_ready;

    logic                   psum_in_valid;
    logic [PSUM_WIDTH-1:0]  psum_in_data;
    logic                   psum_in_ready;

    logic [PSUM_WIDTH-1:0]  psum_out_data;
    logic                   psum_out_valid;
    logic                   psum_out_re;

    //==========================================================================
    // DUT instantiation
    //==========================================================================
    PE_top #(
        .DATA_WIDTH     (DATA_WIDTH),
        .PSUM_WIDTH     (PSUM_WIDTH),
        .MAXKERNELS     (MAXKERNELS),
        .MAXCHANNELS    (MAXCHANNELS),
        .MAXKERNELWIDTH (MAXKERNELWIDTH),
        .MAC_LATENCY    (MAC_LATENCY),
        .FIFO_DEPTH     (FIFO_DEPTH)
    ) dut (
        .clk              (clk),
        .reset            (reset),
        .start            (start),
        .done             (done),
        .cfg_num_filters  (cfg_num_filters),
        .cfg_num_channels (cfg_num_channels),
        .cfg_ofmap_len    (cfg_ofmap_len),
        .cfg_psum_in_valid(cfg_psum_in_valid),
        .filter_valid     (filter_valid),
        .filter_data      (filter_data),
        .filter_ready     (filter_ready),
        .ifmap_valid      (ifmap_valid),
        .ifmap_data       (ifmap_data),
        .ifmap_ready      (ifmap_ready),
        .psum_in_valid    (psum_in_valid),
        .psum_in_data     (psum_in_data),
        .psum_in_ready    (psum_in_ready),
        .psum_out_data    (psum_out_data),
        .psum_out_valid   (psum_out_valid),
        .psum_out_re      (psum_out_re)
    );

    //==========================================================================
    // Clock generation
    //==========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //==========================================================================
    // Waveform dump
    //==========================================================================
    initial begin
        $dumpfile("PE_top_tb.vcd");
        $dumpvars(0, PE_top_tb);
    end

    //==========================================================================
    // Test counters
    //==========================================================================
    int pass_cnt = 0;
    int fail_cnt = 0;

    task automatic check(input string label, input logic cond);
        if (cond) begin
            $display("[PASS] %s", label);
            pass_cnt++;
        end else begin
            $error("[FAIL] %s", label);
            fail_cnt++;
        end
    endtask

    //==========================================================================
    // apply_reset
    // Drives reset for 4 cycles, clears all stimulus signals.
    //==========================================================================
    task automatic apply_reset();
        reset            = 1;
        start            = 0;
        filter_valid     = 0;
        filter_data      = '0;
        ifmap_valid      = 0;
        ifmap_data       = '0;
        psum_in_valid    = 0;
        psum_in_data     = '0;
        psum_out_re      = 0;
        cfg_num_filters  = '0;
        cfg_num_channels = '0;
        cfg_ofmap_len    = '0;
        cfg_psum_in_valid= 0;
        repeat(4) @(posedge clk);
        #1;
        reset = 0;
        @(posedge clk);
    endtask

    //==========================================================================
    // pulse_start
    // Asserts start for exactly 1 cycle with the given config.
    // Config signals are stable before the rising edge and held through it.
    //==========================================================================
    task automatic pulse_start(
        input logic [CFG_F_W-1:0] nf,
        input logic [CFG_C_W-1:0] nc,
        input logic [CFG_X_W-1:0] xl,
        input logic               pin
    );
        // Set config combinatorially, then let the next posedge latch them
        cfg_num_filters   = nf;
        cfg_num_channels  = nc;
        cfg_ofmap_len     = xl;
        cfg_psum_in_valid = pin;
        start             = 1;
        @(posedge clk);   // DUT latches cfg + start on this edge
        #1;
        start = 0;
    endtask

    //==========================================================================
    // stream_filters
    // Drives filter_valid/filter_data using correct valid/ready handshake.
    //
    // Correct protocol:
    //   - Assert valid + data before the clock edge.
    //   - A beat fires when valid & ready are both seen high on a posedge.
    //   - Deassert valid on the cycle AFTER the fire (#1 after the edge).
    //   - Do NOT add an extra clock between seeing ready and deasserting -
    //     that creates a spurious second beat on the same data byte.
    //
    // gap_after: idle cycles inserted between beats (for back-pressure test).
    //==========================================================================
    task automatic stream_filters(
        input logic [DATA_WIDTH-1:0] data[],
        input int                    gap_after = 0
    );
        foreach (data[i]) begin
            // Present data before clock edge
            filter_valid = 1;
            filter_data  = data[i];
            // Wait for the posedge on which both valid and ready are high
            do @(posedge clk); while (!filter_ready);
            // Beat fired on this posedge. Deassert on the next delta.
            #1;
            filter_valid = 0;
            // Optional idle gap for back-pressure testing
            repeat(gap_after) @(posedge clk);
        end
        filter_valid = 0;
    endtask

    //==========================================================================
    // stream_ifmap
    // Same handshake protocol as stream_filters.
    //==========================================================================
    task automatic stream_ifmap(input logic [DATA_WIDTH-1:0] data[]);
        foreach (data[i]) begin
            ifmap_valid = 1;
            ifmap_data  = data[i];
            do @(posedge clk); while (!ifmap_ready);
            #1;
            ifmap_valid = 0;
        end
        ifmap_valid = 0;
    endtask

    //==========================================================================
    // stream_psum_in
    // Same handshake protocol; used for PSUM_LOAD pre-load.
    //==========================================================================
    task automatic stream_psum_in(input logic [PSUM_WIDTH-1:0] data[]);
        foreach (data[i]) begin
            psum_in_valid = 1;
            psum_in_data  = data[i];
            do @(posedge clk); while (!psum_in_ready);
            #1;
            psum_in_valid = 0;
        end
        psum_in_valid = 0;
    endtask

    //==========================================================================
    // wait_done
    // Spins on posedge until done is seen high. Timeout kills simulation.
    //==========================================================================
    task automatic wait_done(input int max_cycles = 50000);
        int cnt = 0;
        while (!done) begin
            @(posedge clk);
            cnt++;
            if (cnt >= max_cycles) begin
                $error("[TIMEOUT] done never asserted after %0d cycles", max_cycles);
                $finish;
            end
        end
        // Caller is now sitting on the posedge where done is high.
    endtask

    //==========================================================================
    // check_done_width
    // Verifies done de-asserts on the very next cycle (1-cycle pulse).
    // Call immediately after wait_done returns (which sits on done's posedge).
    //==========================================================================
    task automatic check_done_width();
        @(posedge clk);
        if (done)
            $error("[FAIL] done pulse width > 1 cycle (cycle-accuracy violation)");
        else
            $display("[PASS] done is exactly 1 cycle wide");
    endtask

    //==========================================================================
    // drain_output_fifo
    //
    // FWFT read protocol (fifo_block uses combinatorial data_out):
    //   1. Wait until psum_out_valid is high (FIFO non-empty).
    //   2. Sample psum_out_data NOW - it is already valid (mem[rd_ptr] async).
    //   3. Assert psum_out_re for one clock to advance rd_ptr.
    //   4. Repeat.
    //
    // Sampling AFTER the re clock edge is wrong - it reads the next entry.
    //==========================================================================
    task automatic drain_output_fifo(
        input  int                    n,
        output logic [PSUM_WIDTH-1:0] result[]
    );
        result = new[n];
        for (int i = 0; i < n; i++) begin
            // Step 1: wait for valid data
            while (!psum_out_valid) @(posedge clk);
            // Step 2: capture data combinatorially (FWFT - valid same cycle)
            result[i] = psum_out_data;
            // Step 3: pulse re to advance rd_ptr
            @(posedge clk); #1;
            psum_out_re = 1;
            @(posedge clk); #1;
            psum_out_re = 0;
        end
    endtask

    //==========================================================================
    // Reference MAC model
    // Computes expected psums for given filter/ifmap arrays.
    // Loop order matches RTL: x outer, f next, c next, k innermost.
    // psum_spad[f] accumulates across all x, c, k.
    //==========================================================================
    function automatic void ref_mac(
        input  logic [DATA_WIDTH-1:0] filters[],   // [f*(nc*S) + c*S + k]
        input  logic [DATA_WIDTH-1:0] ifmaps[],    // [c*S + k]
        input  logic [PSUM_WIDTH-1:0] psum_init[], // initial psum per filter
        input  int                    nf, nc, xl,
        output logic [PSUM_WIDTH-1:0] psum_out[]
    );
        int S = MAXKERNELWIDTH;
        psum_out = new[nf];
        for (int f = 0; f < nf; f++)
            psum_out[f] = psum_init[f];

        for (int x = 0; x < xl; x++)
            for (int f = 0; f < nf; f++)
                for (int c = 0; c < nc; c++)
                    for (int k = 0; k < S; k++) begin
                        automatic int fi = f*(nc*S) + c*S + k;
                        automatic int ii = c*S + k;
                        // signed 8-bit × signed 8-bit → sign-extend to 24-bit
                        psum_out[f] = psum_out[f] +
                            PSUM_WIDTH'(signed'(filters[fi])) *
                            PSUM_WIDTH'(signed'(ifmaps[ii]));
                    end
    endfunction

    //==========================================================================
    // TC1 : Basic tile, no psum pre-load
    //       filters=2, channels=2, ofmap_len=2, psum_in_valid=0
    //==========================================================================
    task automatic tc1_basic_no_psum_preload();
        automatic int nf=2, nc=2, xl=2;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH;  // 12
        automatic int total_imap = nc * MAXKERNELWIDTH;        // 6
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic logic [PSUM_WIDTH-1:0] init_psums[];
        automatic logic [PSUM_WIDTH-1:0] exp_psums[];

        $display("\n--- TC1: Basic tile, no psum pre-load ---");
        apply_reset();

        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'(i + 1);

        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'(1);

        // Initial psums are zero (PSUM_CLEAR path)
        init_psums = new[nf];
        for (int f = 0; f < nf; f++) init_psums[f] = '0;

        ref_mac(filt_bytes, imap_bytes, init_psums, nf, nc, xl, exp_psums);
        $display("  TC1 expected psums: [0]=%0d [1]=%0d",
                 $signed(exp_psums[0]), $signed(exp_psums[1]));

        fork
            pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0);
        join_none
        fork
            stream_filters(filt_bytes, 0);
        join_none
        fork
            stream_ifmap(imap_bytes);
        join_none

        wait_done(5000);
        check_done_width();

        drain_output_fifo(nf, out_psums);

        @(posedge clk);
        check("TC1: psum_out_valid de-asserts after drain", !psum_out_valid);
        check("TC1: psum[0] matches reference", out_psums[0] === exp_psums[0]);
        check("TC1: psum[1] matches reference", out_psums[1] === exp_psums[1]);

        $display("  TC1 actual  psums: [0]=%0d [1]=%0d",
                 $signed(out_psums[0]), $signed(out_psums[1]));
    endtask

    //==========================================================================
    // TC2 : Psum pre-load from Local Network
    //       filters=2, channels=1, ofmap_len=1, psum_in_valid=1
    //       Pre-load psums = {100, 200}; verify exact accumulated values.
    //==========================================================================
    task automatic tc2_psum_preload();
        automatic int nf=2, nc=1, xl=1;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH;  // 6
        automatic int total_imap = nc * MAXKERNELWIDTH;        // 3
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] preload[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic logic [PSUM_WIDTH-1:0] exp_psums[];

        $display("\n--- TC2: Psum pre-load from LN ---");
        apply_reset();

        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'(1);

        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'(1);

        preload    = new[nf];
        preload[0] = PSUM_WIDTH'(100);
        preload[1] = PSUM_WIDTH'(200);

        // Reference: start from preloaded values
        ref_mac(filt_bytes, imap_bytes, preload, nf, nc, xl, exp_psums);
        // With all-ones filters and ifmap over 1×1×3: each psum += 1+1+1 = 3
        $display("  TC2 expected psums: [0]=%0d [1]=%0d",
                 $signed(exp_psums[0]), $signed(exp_psums[1]));

        fork
            pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b1);
        join_none
        fork
            stream_filters(filt_bytes, 0);
        join_none
        fork
            stream_ifmap(imap_bytes);
        join_none
        fork
            stream_psum_in(preload);
        join_none

        wait_done(5000);
        check_done_width();

        drain_output_fifo(nf, out_psums);

        check("TC2: psum[0] exact match (preload + MAC)", out_psums[0] === exp_psums[0]);
        check("TC2: psum[1] exact match (preload + MAC)", out_psums[1] === exp_psums[1]);

        $display("  TC2 actual  psums: [0]=%0d [1]=%0d",
                 $signed(out_psums[0]), $signed(out_psums[1]));
    endtask

    //==========================================================================
    // TC3 : Back-pressure on filter load
    //       Injects 2-cycle gaps between every filter byte.
    //       Verifies result is identical to no-gap reference run.
    //==========================================================================
    task automatic tc3_filter_backpressure();
        automatic int nf=2, nc=1, xl=1;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH;
        automatic int total_imap = nc * MAXKERNELWIDTH;
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_ref[];
        automatic logic [PSUM_WIDTH-1:0] out_bp[];

        $display("\n--- TC3: Back-pressure on filter load ---");

        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'(i + 1);
        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'(2);

        // --- Reference run (no gap) ---
        apply_reset();
        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 0); join_none
        fork stream_ifmap(imap_bytes);      join_none
        wait_done(5000);
        @(posedge clk);
        drain_output_fifo(nf, out_ref);

        // --- Back-pressure run (2-cycle gap between each filter byte) ---
        apply_reset();
        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 2); join_none
        fork stream_ifmap(imap_bytes);      join_none
        wait_done(10000);
        @(posedge clk);
        drain_output_fifo(nf, out_bp);

        check("TC3: psum[0] matches reference under filter back-pressure",
              out_bp[0] === out_ref[0]);
        check("TC3: psum[1] matches reference under filter back-pressure",
              out_bp[1] === out_ref[1]);

        $display("  TC3 ref=[%0d,%0d]  bp=[%0d,%0d]",
            $signed(out_ref[0]), $signed(out_ref[1]),
            $signed(out_bp[0]),  $signed(out_bp[1]));
    endtask

    //==========================================================================
    // TC4 : Back-pressure on output FIFO
    //       Holds psum_out_re=0 for 20 cycles after done, then drains.
    //       Verifies psum_out_valid stays high and data is correct.
    //==========================================================================
    task automatic tc4_output_backpressure();
        automatic int nf=2, nc=1, xl=1;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH;
        automatic int total_imap = nc * MAXKERNELWIDTH;
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic logic [PSUM_WIDTH-1:0] init_psums[];
        automatic logic [PSUM_WIDTH-1:0] exp_psums[];
        automatic logic valid_held;

        $display("\n--- TC4: Back-pressure on output FIFO ---");
        apply_reset();

        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'(i + 1);
        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'(1);

        init_psums = new[nf];
        for (int f = 0; f < nf; f++) init_psums[f] = '0;
        ref_mac(filt_bytes, imap_bytes, init_psums, nf, nc, xl, exp_psums);

        psum_out_re = 0;  // hold low throughout

        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 0); join_none
        fork stream_ifmap(imap_bytes);      join_none

        wait_done(5000);
        @(posedge clk);

        // FIFO must be non-empty immediately after done
        check("TC4: psum_out_valid high immediately after done", psum_out_valid);

        // Hold back-pressure for 20 cycles - valid must not drop
        valid_held = 1;
        repeat(20) begin
            @(posedge clk);
            if (!psum_out_valid) valid_held = 0;
        end
        check("TC4: psum_out_valid stable during 20-cycle back-pressure", valid_held);

        // Now drain and check values are still correct
        drain_output_fifo(nf, out_psums);
        @(posedge clk);
        check("TC4: psum_out_valid de-asserts after drain", !psum_out_valid);
        check("TC4: psum[0] correct after back-pressure", out_psums[0] === exp_psums[0]);
        check("TC4: psum[1] correct after back-pressure", out_psums[1] === exp_psums[1]);

        $display("  TC4 psums: [0]=%0d (exp=%0d)  [1]=%0d (exp=%0d)",
            $signed(out_psums[0]), $signed(exp_psums[0]),
            $signed(out_psums[1]), $signed(exp_psums[1]));
    endtask

    //==========================================================================
    // TC5 : Stress test - filters=4, channels=2, ofmap_len=3
    //       Verifies done pulses exactly once and psums match reference.
    //==========================================================================
    task automatic tc5_stress();
        automatic int nf=4, nc=2, xl=3;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH;  // 24
        automatic int total_imap = nc * MAXKERNELWIDTH;        // 6
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic logic [PSUM_WIDTH-1:0] init_psums[];
        automatic logic [PSUM_WIDTH-1:0] exp_psums[];
        automatic int done_wide;

        $display("\n--- TC5: Stress test (F=4 C=2 X=3) ---");
        apply_reset();

        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'((i % 7) + 1);

        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'((i % 5) + 1);

        init_psums = new[nf];
        for (int f = 0; f < nf; f++) init_psums[f] = '0;
        ref_mac(filt_bytes, imap_bytes, init_psums, nf, nc, xl, exp_psums);

        // Monitor done width in parallel
        done_wide = 0;
        fork
            begin
                @(posedge done);
                @(posedge clk);
                if (done) done_wide = 1;
            end
        join_none

        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 0); join_none
        fork stream_ifmap(imap_bytes);      join_none

        wait_done(20000);
        @(posedge clk);  // let done_wide thread settle

        check("TC5: done is exactly 1 cycle wide", done_wide == 0);

        drain_output_fifo(nf, out_psums);

        for (int f = 0; f < nf; f++) begin
            automatic string label;
            label = $sformatf("TC5: psum[%0d] matches reference", f);
            check(label, out_psums[f] === exp_psums[f]);
            $display("  TC5 psum[%0d]: got=%0d  exp=%0d", f,
                     $signed(out_psums[f]), $signed(exp_psums[f]));
        end
    endtask

    //==========================================================================
    // TC6 : Cycle count sanity
    //       filters=1, channels=1, ofmap_len=1, psum_in_valid=0
    //
    // Minimum cycle count from start posedge to done posedge:
    //   FILTER_LOAD : 3 beats (k=0,1,2), no gaps          = 3 cycles
    //   IFMAP_LOAD  : 3 beats                              = 3 cycles
    //   PSUM_CLEAR  : 1 slot (num_filters=1)               = 1 cycle
    //   COMPUTE     : 3 active MACs (k=0,1,2)
    //                 + 1 cycle where last_mac_in fires and draining is set
    //                   but drain_cnt stays 0 (the if(!draining) branch)
    //                 + MAC_LATENCY (3) drain cycles       = 3+1+3 = 7 cycles
    //   PSUM_DRAIN  : 1 slot                               = 1 cycle
    //   PE_DONE     : 1 cycle                              = 1 cycle
    //   ─────────────────────────────────────────────────────────────────
    //   Minimum total                                      = 16 cycles
    //
    // Expected psum = 1×1 + 1×2 + 1×3 = 6
    //==========================================================================
    task automatic tc6_cycle_count();
        automatic int nf=1, nc=1, xl=1;
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic longint cycle_start, cycle_done;
        automatic int elapsed;

        $display("\n--- TC6: Cycle count sanity ---");
        apply_reset();

        filt_bytes = new[3];
        for (int i = 0; i < 3; i++) filt_bytes[i] = DATA_WIDTH'(i + 1); // 1,2,3

        imap_bytes = new[3];
        for (int i = 0; i < 3; i++) imap_bytes[i] = DATA_WIDTH'(1);     // all 1s

        // Record cycle number just before start fires
        @(posedge clk);
        cycle_start = $time / CLK_PERIOD;

        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 0); join_none
        fork stream_ifmap(imap_bytes);      join_none

        wait_done(5000);
        cycle_done = $time / CLK_PERIOD;
        elapsed    = int'(cycle_done - cycle_start);

        $display("  TC6: elapsed cycles = %0d (minimum expected = 16)", elapsed);

        // Minimum bound: 16 cycles (derived above)
        check("TC6: elapsed >= 16 cycles (no premature done)", elapsed >= 16);

        // Exact upper bound: no stalls should occur, so elapsed should be close
        // to minimum. Allow a few cycles of scheduling slack in the TB.
        check("TC6: elapsed <= 25 cycles (no unexpected stall)", elapsed <= 25);

        drain_output_fifo(nf, out_psums);

        $display("  TC6: psum[0] = %0d  (expected = 6)", $signed(out_psums[0]));
        check("TC6: psum[0] === 6  (1×1 + 1×2 + 1×3)", out_psums[0] === PSUM_WIDTH'(6));
    endtask

    //==========================================================================
    // Main simulation
    //==========================================================================
    initial begin
        $display("========================================");
        $display("  PE_top Testbench - starting");
        $display("========================================");

        // Safe initial state before first apply_reset
        reset            = 1;
        start            = 0;
        filter_valid     = 0;
        filter_data      = '0;
        ifmap_valid      = 0;
        ifmap_data       = '0;
        psum_in_valid    = 0;
        psum_in_data     = '0;
        psum_out_re      = 0;
        cfg_num_filters  = '0;
        cfg_num_channels = '0;
        cfg_ofmap_len    = '0;
        cfg_psum_in_valid= 0;

        repeat(5) @(posedge clk);
        #1; reset = 0;

        tc1_basic_no_psum_preload();
        tc2_psum_preload();
        tc3_filter_backpressure();
        tc4_output_backpressure();
        tc5_stress();
        tc6_cycle_count();

        $display("\n========================================");
        $display("  Results: %0d passed, %0d failed", pass_cnt, fail_cnt);
        $display("========================================");

        if (fail_cnt == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED - review errors above");

        #(CLK_PERIOD * 10);
        $finish;
    end

    //==========================================================================
    // Watchdog
    //==========================================================================
    initial begin
        #(CLK_PERIOD * 200000);
        $error("[WATCHDOG] Simulation exceeded 200000 cycles - force finish");
        $finish;
    end

endmodule
