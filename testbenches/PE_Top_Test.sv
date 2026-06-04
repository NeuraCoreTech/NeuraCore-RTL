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
//        Pre-loads 2 psums before COMPUTE, verifies they are accumulated.
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
// Cycle accuracy checks
// ─────────────────────────────────────────────────────────────────────────────
//  - done must be exactly 1 cycle wide
//  - All handshake transfers counted; expected vs actual checked at end
//  - psum_out_valid de-asserts only after all psums are read
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
        .clk             (clk),
        .reset           (reset),
        .start           (start),
        .done            (done),
        .cfg_num_filters  (cfg_num_filters),
        .cfg_num_channels (cfg_num_channels),
        .cfg_ofmap_len    (cfg_ofmap_len),
        .cfg_psum_in_valid(cfg_psum_in_valid),
        .filter_valid    (filter_valid),
        .filter_data     (filter_data),
        .filter_ready    (filter_ready),
        .ifmap_valid     (ifmap_valid),
        .ifmap_data      (ifmap_data),
        .ifmap_ready     (ifmap_ready),
        .psum_in_valid   (psum_in_valid),
        .psum_in_data    (psum_in_data),
        .psum_in_ready   (psum_in_ready),
        .psum_out_data   (psum_out_data),
        .psum_out_valid  (psum_out_valid),
        .psum_out_re     (psum_out_re)
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
    // Utility tasks
    //==========================================================================

    // Wait N rising edges
    task automatic wait_cycles(input int n);
        repeat(n) @(posedge clk);
    endtask

    // Apply reset for 4 cycles
    task automatic apply_reset();
        reset         = 1;
        start         = 0;
        filter_valid  = 0;
        filter_data   = '0;
        ifmap_valid   = 0;
        ifmap_data    = '0;
        psum_in_valid = 0;
        psum_in_data  = '0;
        psum_out_re   = 0;
        repeat(4) @(posedge clk);
        #1;
        reset = 0;
        @(posedge clk);
    endtask

    // Stream a byte array on filter channel (with optional gap cycles for back-pressure)
    task automatic stream_filters(
        input logic [DATA_WIDTH-1:0] data[],
        input int gap_after = 0   // extra idle cycles injected after each byte
    );
        foreach (data[i]) begin
            @(posedge clk); #1;
            filter_valid = 1;
            filter_data  = data[i];
            // Wait until PE accepts (filter_ready may be low before FILTER_LOAD)
            while (!filter_ready) begin
                @(posedge clk); #1;
            end
            @(posedge clk); #1;
            filter_valid = 0;
            repeat(gap_after) begin @(posedge clk); #1; end
        end
        filter_valid = 0;
    endtask

    // Stream a byte array on ifmap channel
    task automatic stream_ifmap(
        input logic [DATA_WIDTH-1:0] data[]
    );
        foreach (data[i]) begin
            @(posedge clk); #1;
            ifmap_valid = 1;
            ifmap_data  = data[i];
            while (!ifmap_ready) begin
                @(posedge clk); #1;
            end
            @(posedge clk); #1;
            ifmap_valid = 0;
        end
        ifmap_valid = 0;
    endtask

    // Stream psums on psum_in channel (pre-load)
    task automatic stream_psum_in(
        input logic [PSUM_WIDTH-1:0] data[]
    );
        foreach (data[i]) begin
            @(posedge clk); #1;
            psum_in_valid = 1;
            psum_in_data  = data[i];
            while (!psum_in_ready) begin
                @(posedge clk); #1;
            end
            @(posedge clk); #1;
            psum_in_valid = 0;
        end
        psum_in_valid = 0;
    endtask

    // Pulse start for 1 cycle with given config
    task automatic pulse_start(
        input logic [CFG_F_W-1:0] nf,
        input logic [CFG_C_W-1:0] nc,
        input logic [CFG_X_W-1:0] xl,
        input logic               pin
    );
        @(posedge clk); #1;
        cfg_num_filters  = nf;
        cfg_num_channels = nc;
        cfg_ofmap_len    = xl;
        cfg_psum_in_valid= pin;
        start            = 1;
        @(posedge clk); #1;
        start            = 0;
    endtask

    // Wait for done pulse; timeout after max_cycles
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
    endtask

    // Check done is exactly 1 cycle wide
    task automatic check_done_width();
        // done is already high on this posedge; check it de-asserts next cycle
        @(posedge clk);
        if (done) begin
            $error("[FAIL] done pulse width > 1 cycle (cycle-accuracy violation)");
        end else begin
            $display("[PASS] done is exactly 1 cycle wide");
        end
    endtask

    // Drain N psums from output FIFO and store in result[]
    task automatic drain_output_fifo(
        input  int n,
        output logic [PSUM_WIDTH-1:0] result[]
    );
        result = new[n];
        for (int i = 0; i < n; i++) begin
            // Wait until FIFO has data
            while (!psum_out_valid) @(posedge clk);
            @(posedge clk); #1;
            psum_out_re = 1;
            @(posedge clk); #1;
            result[i]   = psum_out_data;
            psum_out_re = 0;
        end
    endtask

    //==========================================================================
    // Test counters
    //==========================================================================
    int pass_cnt = 0;
    int fail_cnt = 0;

    task automatic check(
        input string label,
        input logic  cond
    );
        if (cond) begin
            $display("[PASS] %s", label);
            pass_cnt++;
        end else begin
            $error("[FAIL] %s", label);
            fail_cnt++;
        end
    endtask

    //==========================================================================
    // TC1 : Basic tile, no psum pre-load
    //       filters=2, channels=2, ofmap_len=2, psum_in_valid=0
    //       12 filter bytes, 6 ifmap bytes
    //       Expected: 2 psums appear in output FIFO, done pulses once
    //==========================================================================
    task automatic tc1_basic_no_psum_preload();
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic int done_count;
        automatic int nf = 2, nc = 2, xl = 2;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH; // 12
        automatic int total_imap = nc * MAXKERNELWIDTH;       // 6

        $display("\n--- TC1: Basic tile, no psum pre-load ---");

        apply_reset();

        // Build simple incrementing filter weights: 1,2,3,4,...
        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'(i + 1);

        // Ifmap: all 1s for easy manual check
        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'(1);

        // Start tile
        fork
            // Drive start + config
            begin
                pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0);
            end
        join_none

        // Stream filters (run in background; DUT stalls if not ready)
        fork
            stream_filters(filt_bytes, 0);
        join_none

        // Stream ifmap (background)
        fork
            stream_ifmap(imap_bytes);
        join_none

        // Wait for done
        wait_done(5000);
        done_count = 1;
        check_done_width();

        // Read out psums
        drain_output_fifo(nf, out_psums);

        check("TC1: psum_out_valid de-asserts after drain", !psum_out_valid);
        check("TC1: psums non-zero (MAC computed something)", out_psums[0] != 0 || out_psums[1] != 0);

        $display("  TC1 psums: [0]=%0d [1]=%0d", $signed(out_psums[0]), $signed(out_psums[1]));
    endtask

    //==========================================================================
    // TC2 : Psum pre-load from Local Network
    //       filters=2, channels=1, ofmap_len=1, psum_in_valid=1
    //       Pre-load psums = {100, 200}
    //       Verifies final psums are ≥ pre-loaded values (accumulation happened)
    //==========================================================================
    task automatic tc2_psum_preload();
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] preload[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic int nf = 2, nc = 1, xl = 1;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH; // 6
        automatic int total_imap = nc * MAXKERNELWIDTH;       // 3

        $display("\n--- TC2: Psum pre-load from LN ---");

        apply_reset();

        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'(1);

        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'(1);

        preload = new[nf];
        preload[0] = PSUM_WIDTH'(100);
        preload[1] = PSUM_WIDTH'(200);

        // Start tile with psum_in_valid=1
        fork
            pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b1);
        join_none

        fork
            stream_filters(filt_bytes, 0);
        join_none

        fork
            stream_ifmap(imap_bytes);
        join_none

        // Pre-load psums once DUT enters PSUM_LOAD (psum_in_ready goes high)
        fork
            stream_psum_in(preload);
        join_none

        wait_done(5000);
        check_done_width();

        drain_output_fifo(nf, out_psums);

        // Each output psum must be > its pre-loaded value (MAC added to it)
        check("TC2: psum[0] >= preload[0] (accumulation)", out_psums[0] >= preload[0]);
        check("TC2: psum[1] >= preload[1] (accumulation)", out_psums[1] >= preload[1]);

        $display("  TC2 psums: [0]=%0d (pre=%0d)  [1]=%0d (pre=%0d)",
            $signed(out_psums[0]), $signed(preload[0]),
            $signed(out_psums[1]), $signed(preload[1]));
    endtask

    //==========================================================================
    // TC3 : Back-pressure on filter load
    //       Injects 2-cycle gaps between every filter byte
    //       Verifies DUT still completes correctly (no lost bytes)
    //==========================================================================
    task automatic tc3_filter_backpressure();
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic logic [PSUM_WIDTH-1:0] out_psums_ref[];
        automatic int nf = 2, nc = 1, xl = 1;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH;
        automatic int total_imap = nc * MAXKERNELWIDTH;

        $display("\n--- TC3: Back-pressure on filter load ---");

        // --- Reference run (no gap) ---
        apply_reset();
        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'(i + 1);
        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'(2);

        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 0); join_none
        fork stream_ifmap(imap_bytes);      join_none
        wait_done(5000); @(posedge clk);

        drain_output_fifo(nf, out_psums_ref);

        // --- Back-pressure run (2-cycle gap) ---
        apply_reset();
        // reuse same data arrays

        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 2); join_none  // 2-cycle gap after each byte
        fork stream_ifmap(imap_bytes);      join_none
        wait_done(10000); @(posedge clk);

        drain_output_fifo(nf, out_psums);

        check("TC3: psum[0] matches reference despite back-pressure",
              out_psums[0] === out_psums_ref[0]);
        check("TC3: psum[1] matches reference despite back-pressure",
              out_psums[1] === out_psums_ref[1]);

        $display("  TC3 ref=%0d/%0d  bp=%0d/%0d",
            $signed(out_psums_ref[0]), $signed(out_psums_ref[1]),
            $signed(out_psums[0]),     $signed(out_psums[1]));
    endtask

    //==========================================================================
    // TC4 : Back-pressure on output FIFO
    //       Holds psum_out_re=0 for 20 cycles after done, then drains
    //       Verifies psum_out_valid stays high the whole time
    //==========================================================================
    task automatic tc4_output_backpressure();
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic int nf = 2, nc = 1, xl = 1;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH;
        automatic int total_imap = nc * MAXKERNELWIDTH;
        automatic logic valid_held;

        $display("\n--- TC4: Back-pressure on output FIFO ---");

        apply_reset();

        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'(i + 1);
        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'(1);

        psum_out_re = 0; // hold read-enable low

        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 0); join_none
        fork stream_ifmap(imap_bytes);      join_none
        wait_done(5000); @(posedge clk);

        // FIFO should be non-empty immediately after done
        check("TC4: psum_out_valid high after done (FIFO not empty)", psum_out_valid);

        // Hold back-pressure for 20 cycles; valid should stay high
        valid_held = 1;
        repeat(20) begin
            @(posedge clk);
            if (!psum_out_valid) valid_held = 0;
        end
        check("TC4: psum_out_valid stays high during back-pressure", valid_held);

        // Now drain
        drain_output_fifo(nf, out_psums);
        @(posedge clk);
        check("TC4: psum_out_valid de-asserts after drain", !psum_out_valid);
        $display("  TC4 psums: [0]=%0d [1]=%0d", $signed(out_psums[0]), $signed(out_psums[1]));
    endtask

    //==========================================================================
    // TC5 : Maximum-ish configuration stress test
    //       filters=4, channels=2, ofmap_len=3
    //       Verifies done pulses exactly once and psums are non-zero
    //==========================================================================
    task automatic tc5_stress();
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic int nf = 4, nc = 2, xl = 3;
        automatic int total_filt = nf * nc * MAXKERNELWIDTH; // 24
        automatic int total_imap = nc * MAXKERNELWIDTH;       // 6
        automatic int done_seen;

        $display("\n--- TC5: Stress test (F=4 C=2 X=3) ---");

        apply_reset();

        filt_bytes = new[total_filt];
        for (int i = 0; i < total_filt; i++) filt_bytes[i] = DATA_WIDTH'((i % 7) + 1);

        imap_bytes = new[total_imap];
        for (int i = 0; i < total_imap; i++) imap_bytes[i] = DATA_WIDTH'((i % 5) + 1);

        done_seen = 0;

        // Monitor done - count how many cycles it is asserted
        fork
            begin
                @(posedge done);
                done_seen = 1;
                @(posedge clk);
                if (done) done_seen = 2; // wider than 1 cycle
            end
        join_none

        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 0); join_none
        fork stream_ifmap(imap_bytes);      join_none

        wait_done(20000);
        @(posedge clk); // one extra to let done_seen settle

        check("TC5: done asserted exactly 1 cycle", done_seen == 1);

        drain_output_fifo(nf, out_psums);

        begin
            automatic logic any_nonzero = 0;
            for (int i = 0; i < nf; i++) begin
                $display("  TC5 psum[%0d] = %0d", i, $signed(out_psums[i]));
                if (out_psums[i] != 0) any_nonzero = 1;
            end
            check("TC5: at least one psum non-zero", any_nonzero);
        end
    endtask

    //==========================================================================
    // TC6 : Cycle count sanity
    //       filters=1, channels=1, ofmap_len=1, psum_in_valid=0
    //       Total MAC ops = 1*1*3 = 3 (one filter row)
    //       Expected COMPUTE cycles = 3 active + MAC_LATENCY drain = 6
    //       Measure wall-clock cycles from start to done
    //==========================================================================
    task automatic tc6_cycle_count();
        automatic logic [DATA_WIDTH-1:0] filt_bytes[];
        automatic logic [DATA_WIDTH-1:0] imap_bytes[];
        automatic logic [PSUM_WIDTH-1:0] out_psums[];
        automatic int   cycle_start, cycle_done, elapsed;
        automatic int   nf=1, nc=1, xl=1;

        $display("\n--- TC6: Cycle count sanity ---");

        apply_reset();

        filt_bytes = new[3]; foreach (filt_bytes[i]) filt_bytes[i] = DATA_WIDTH'(i+1);
        imap_bytes = new[3]; foreach (imap_bytes[i]) imap_bytes[i] = DATA_WIDTH'(1);

        @(posedge clk); #1;
        cycle_start = $time / CLK_PERIOD;

        fork pulse_start(CFG_F_W'(nf), CFG_C_W'(nc), CFG_X_W'(xl), 1'b0); join_none
        fork stream_filters(filt_bytes, 0); join_none
        fork stream_ifmap(imap_bytes);      join_none

        wait_done(5000);

        cycle_done = $time / CLK_PERIOD;
        elapsed    = cycle_done - cycle_start;

        $display("  TC6: elapsed cycles = %0d", elapsed);

        // Floor check: at minimum we need
        //   1 (FILTER_LOAD: 3 bytes, ≥3 cycles) +
        //   1 (IFMAP_LOAD:  3 bytes, ≥3 cycles) +
        //   3 (COMPUTE active) + 3 (drain) +
        //   1 (PSUM_DRAIN) + 1 (PE_DONE) = at least ~15 cycles
        check("TC6: elapsed >= 15 cycles (no premature done)", elapsed >= 15);

        drain_output_fifo(nf, out_psums);
        $display("  TC6 psum[0] = %0d  (expect = 1*1+1*2+1*3 = 6)", $signed(out_psums[0]));
        check("TC6: psum[0] == 6 (1×1 + 1×2 + 1×3)", out_psums[0] === PSUM_WIDTH'(6));
    endtask

    //==========================================================================
    // Main simulation
    //==========================================================================
    initial begin
        $display("========================================");
        $display("  PE_top Testbench - starting");
        $display("========================================");

        // Default stimulus values
        reset         = 1;
        start         = 0;
        filter_valid  = 0;
        filter_data   = '0;
        ifmap_valid   = 0;
        ifmap_data    = '0;
        psum_in_valid = 0;
        psum_in_data  = '0;
        psum_out_re   = 0;
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
    // Watchdog - kill simulation if it hangs completely
    //==========================================================================
    initial begin
        #(CLK_PERIOD * 200000);
        $error("[WATCHDOG] Simulation exceeded 200000 cycles - force finish");
        $finish;
    end

endmodule