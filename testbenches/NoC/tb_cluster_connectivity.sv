`timescale 1ns / 1ps
//==============================================================================
// Testbench  : tb_cluster_connectivity
// DUT        : cluster_top (2×2, PE stubs replacing real PE_top)
//
// Setup
// ─────────────────────────────────────────────────────────────────────────────
//   In Vivado: add pe_stub.sv to SIMULATION sources only (not synthesis).
//   pe_stub.sv defines module PE_top — during simulation cluster_top picks
//   up the stub instead of the real implementation.
//
// Tests
// ─────────────────────────────────────────────────────────────────────────────
//   T1  Filter routing   — each PE[r][c] receives its unique filter stream
//   T2  IFmap broadcast  — PE[r][0] and PE[r][1] get identical ifmap data
//   T3  IFmap ready      — cluster ifmap_ready[r] = AND of PE[r][*].ifmap_ready
//   T4  Psum chain       — cluster psum_in feeds bottom PE (row 0)
//                       — PE[0][c].psum_out feeds PE[1][c].psum_in
//                       — cluster psum_out comes from top PE (row 1)
//   T5  FSM — pe_start   — fires exactly 1 cycle after cluster start
//   T6  FSM — done       — fires exactly 1 cycle after all PE stubs complete
//   T7  FSM — restart    — cluster can re-enter START from IDLE correctly
//==============================================================================

module tb_cluster_connectivity;

    //=========================================================================
    // Parameters — must match pe_stub and cluster_top defaults
    //=========================================================================
    localparam PE_ROWS    = 2;
    localparam PE_COLS    = 2;
    localparam DATA_WIDTH = 8;
    localparam PSUM_WIDTH = 24;
    localparam CFG_F_W    = 5;
    localparam CFG_C_W    = 3;
    localparam CFG_X_W    = 8;

    localparam CLK_PERIOD  = 10;   // 100 MHz
    localparam DONE_DELAY  = 20;   // must match pe_stub DONE_DELAY default
    localparam PSUM_STUB   = 24'hCAFE00; // must match pe_stub PSUM_OUT_VAL

    //=========================================================================
    // Clock & reset
    //=========================================================================
    logic clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    logic reset;

    //=========================================================================
    // DUT ports
    //=========================================================================
    logic start, done;

    logic [CFG_F_W-1:0] cfg_num_filters;
    logic [CFG_C_W-1:0] cfg_num_channels;
    logic [CFG_X_W-1:0] cfg_ofmap_len;
    logic               cfg_psum_in_valid;

    logic [PE_ROWS-1:0][PE_COLS-1:0]                  filter_valid;
    logic [PE_ROWS-1:0][PE_COLS-1:0][DATA_WIDTH-1:0]  filter_data;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  filter_ready;

    logic [PE_ROWS-1:0]                  ifmap_valid;
    logic [PE_ROWS-1:0][DATA_WIDTH-1:0]  ifmap_data;
    logic [PE_ROWS-1:0]                  ifmap_ready;

    logic [PE_COLS-1:0]                  psum_in_valid;
    logic [PE_COLS-1:0][PSUM_WIDTH-1:0]  psum_in_data;
    logic [PE_COLS-1:0]                  psum_in_ready;

    logic [PE_COLS-1:0][PSUM_WIDTH-1:0]  psum_out_data;
    logic [PE_COLS-1:0]                   psum_out_valid;
    logic [PE_COLS-1:0]                   psum_out_re;

    //=========================================================================
    // DUT instantiation
    //=========================================================================
    cluster_top #(
        .PE_ROWS    (PE_ROWS),
        .PE_COLS    (PE_COLS),
        .DATA_WIDTH (DATA_WIDTH),
        .PSUM_WIDTH (PSUM_WIDTH)
    ) dut (
        .clk               (clk),
        .reset             (reset),
        .start             (start),
        .done              (done),
        .cfg_num_filters   (cfg_num_filters),
        .cfg_num_channels  (cfg_num_channels),
        .cfg_ofmap_len     (cfg_ofmap_len),
        .cfg_psum_in_valid (cfg_psum_in_valid),
        .filter_valid      (filter_valid),
        .filter_data       (filter_data),
        .filter_ready      (filter_ready),
        .ifmap_valid       (ifmap_valid),
        .ifmap_data        (ifmap_data),
        .ifmap_ready       (ifmap_ready),
        .psum_in_valid     (psum_in_valid),
        .psum_in_data      (psum_in_data),
        .psum_in_ready     (psum_in_ready),
        .psum_out_data     (psum_out_data),
        .psum_out_valid    (psum_out_valid),
        .psum_out_re       (psum_out_re)
    );

    //=========================================================================
    // Utility tasks
    //=========================================================================
    int pass_cnt = 0;
    int fail_cnt = 0;

    task automatic chk(input string name, input logic cond);
        if (cond) begin
            $display("    PASS  %s", name);
            pass_cnt++;
        end else begin
            $display("    FAIL  %s", name);
            fail_cnt++;
        end
    endtask

    task automatic tick(input int n = 1);
        repeat(n) @(posedge clk);
        #1;  // small delta after edge so FFs have settled
    endtask

    //=========================================================================
    // Shorthand hierarchical paths to PE stub internals
    // Update these if generate block names in cluster_top change.
    //=========================================================================
    // filter capture
    `define PE(R,C) dut.gen_pe_row[R].gen_pe_col[C].u_pe

    //=========================================================================
    // Main test sequence
    //=========================================================================
    initial begin
        // ── defaults ────────────────────────────────────────────────────
        reset             = 1'b1;
        start             = 1'b0;
        filter_valid      = '0;
        filter_data       = '0;
        ifmap_valid       = '0;
        ifmap_data        = '0;
        psum_in_valid     = '0;
        psum_in_data      = '0;
        psum_out_re       = '0;
        cfg_num_filters   = 5'd4;
        cfg_num_channels  = 3'd2;
        cfg_ofmap_len     = 8'd8;
        cfg_psum_in_valid = 1'b0;

        tick(3);
        reset = 1'b0;
        tick(2);

        // ================================================================
        // T1 : Filter routing — each PE gets its own unique stream
        // ================================================================
        $display("\n── T1: Filter routing ──────────────────────────────────");
        filter_valid[0][0] = 1'b1;  filter_data[0][0] = 8'hA0;
        filter_valid[0][1] = 1'b1;  filter_data[0][1] = 8'hA1;
        filter_valid[1][0] = 1'b1;  filter_data[1][0] = 8'hB0;
        filter_valid[1][1] = 1'b1;  filter_data[1][1] = 8'hB1;
        tick(1);
        filter_valid = '0;
        tick(1);

        chk("PE[0][0] captured filter = 0xA0",
            `PE(0,0).captured_filter_data === 8'hA0);
        chk("PE[0][1] captured filter = 0xA1",
            `PE(0,1).captured_filter_data === 8'hA1);
        chk("PE[1][0] captured filter = 0xB0",
            `PE(1,0).captured_filter_data === 8'hB0);
        chk("PE[1][1] captured filter = 0xB1",
            `PE(1,1).captured_filter_data === 8'hB1);

        // ================================================================
        // T2 : IFmap broadcast — row broadcast, unique per row
        // ================================================================
        $display("\n── T2: IFmap broadcast ─────────────────────────────────");
        ifmap_valid[0] = 1'b1;  ifmap_data[0] = 8'hC0;
        ifmap_valid[1] = 1'b1;  ifmap_data[1] = 8'hD0;
        tick(1);
        ifmap_valid = '0;
        tick(1);

        chk("PE[0][0] captured ifmap = 0xC0",
            `PE(0,0).captured_ifmap_data === 8'hC0);
        chk("PE[0][1] captured ifmap = 0xC0  (broadcast from row 0)",
            `PE(0,1).captured_ifmap_data === 8'hC0);
        chk("PE[1][0] captured ifmap = 0xD0",
            `PE(1,0).captured_ifmap_data === 8'hD0);
        chk("PE[1][1] captured ifmap = 0xD0  (broadcast from row 1)",
            `PE(1,1).captured_ifmap_data === 8'hD0);

        // ================================================================
        // T3 : IFmap ready = AND reduction across row
        // All stubs have ifmap_ready=1 → cluster ready should be 1
        // ================================================================
        $display("\n── T3: IFmap ready AND-reduction ───────────────────────");
        chk("ifmap_ready[0] = 1  (AND of PE[0][0] and PE[0][1] ready)",
            ifmap_ready[0] === 1'b1);
        chk("ifmap_ready[1] = 1  (AND of PE[1][0] and PE[1][1] ready)",
            ifmap_ready[1] === 1'b1);

        // ================================================================
        // T4 : Psum chain routing
        // ================================================================
        $display("\n── T4: Psum chain routing ──────────────────────────────");

        // T4a: cluster psum_in → bottom PE (row 0)
        psum_in_valid[0] = 1'b1;  psum_in_data[0] = 24'h111111;
        psum_in_valid[1] = 1'b1;  psum_in_data[1] = 24'h222222;
        tick(1);
        psum_in_valid = '0;
        tick(1);

        chk("PE[0][0] received cluster psum_in[0] = 0x111111",
            `PE(0,0).captured_psum_in_data === 24'h111111);
        chk("PE[0][1] received cluster psum_in[1] = 0x222222",
            `PE(0,1).captured_psum_in_data === 24'h222222);

        // T4b: PE[0][c].psum_out → PE[1][c].psum_in
        // Stub has psum_out_valid=1, psum_out_data=PSUM_STUB always.
        // Since pe_stub captures on every cycle when psum_in_valid=1,
        // PE[1] has already captured PSUM_STUB from PE[0] by now.
        chk("PE[1][0] psum_in_data = PE[0][0] psum_out (chain ok)",
            `PE(1,0).captured_psum_in_data === PSUM_STUB);
        chk("PE[1][1] psum_in_data = PE[0][1] psum_out (chain ok)",
            `PE(1,1).captured_psum_in_data === PSUM_STUB);

        // T4c: cluster psum_out comes from top row (row 1)
        chk("cluster psum_out_data[0] = PE[1][0] psum_out = 0xCAFE00",
            psum_out_data[0] === PSUM_STUB);
        chk("cluster psum_out_data[1] = PE[1][1] psum_out = 0xCAFE00",
            psum_out_data[1] === PSUM_STUB);
        chk("cluster psum_out_valid[0] = 1",
            psum_out_valid[0] === 1'b1);
        chk("cluster psum_out_valid[1] = 1",
            psum_out_valid[1] === 1'b1);

        // T4d: psum_in_ready at cluster level driven by bottom PE row
        chk("psum_in_ready[0] = PE[0][0].psum_in_ready = 1",
            psum_in_ready[0] === 1'b1);
        chk("psum_in_ready[1] = PE[0][1].psum_in_ready = 1",
            psum_in_ready[1] === 1'b1);

        // ================================================================
        // T5 : FSM — pe_start fires exactly 1 cycle
        // ================================================================
        $display("\n── T5: FSM — pe_start pulse width ──────────────────────");
        start = 1'b1;
        tick(1);           // IDLE → START: pe_start goes high
        start = 1'b0;

        chk("pe_start high in START state",
            dut.pe_start === '1);
        chk("FSM in START state (2'b01)",
            dut.u_ctrl.state === 2'b01);

        tick(1);           // START → COMPUTE: pe_start drops

        chk("pe_start = 0 in COMPUTE state (1-cycle pulse verified)",
            dut.pe_start === '0);
        chk("FSM in COMPUTE state (2'b10)",
            dut.u_ctrl.state === 2'b10);

        // ================================================================
        // T6 : FSM — cluster done fires exactly 1 cycle after all PE done
        //
        // Timeline from cluster start:
        //   Cycle 0 : start asserted            → IDLE→START latches
        //   Cycle 1 : START state, pe_start=1   → pe_stub running=1, cnt=0
        //   Cycle 2 : COMPUTE, pe_stub cnt=1
        //   ...
        //   Cycle DONE_DELAY : pe_stub cnt=DONE_DELAY-1, pe_done=1
        //   Cycle DONE_DELAY+1 : DONE state, cluster done=1
        // ================================================================
        $display("\n── T6: FSM — done pulse timing ─────────────────────────");
        // Already in COMPUTE (started in T5). Wait for all PE stubs to finish.
        // From COMPUTE entry we need DONE_DELAY cycles, then +1 for DONE state.
        tick(DONE_DELAY + 1);

        chk("cluster done = 1 after all PE stubs complete",
            done === 1'b1);
        chk("FSM in DONE state (2'b11)",
            dut.u_ctrl.state === 2'b11);

        tick(1);  // DONE → IDLE

        chk("cluster done drops after 1 cycle",
            done === 1'b0);
        chk("FSM back in IDLE (2'b00)",
            dut.u_ctrl.state === 2'b00);

        // ================================================================
        // T7 : FSM — restart from IDLE
        // ================================================================
        $display("\n── T7: FSM — restart from IDLE ─────────────────────────");
        start = 1'b1;
        tick(1);
        start = 1'b0;

        chk("FSM enters START on second start pulse",
            dut.u_ctrl.state === 2'b01);

        tick(1);

        chk("FSM enters COMPUTE on restart",
            dut.u_ctrl.state === 2'b10);

        // ================================================================
        // Summary
        // ================================================================
        tick(2);
        $display("\n════════════════════════════════════════");
        $display("  CONNECTIVITY TEST SUMMARY");
        $display("  PASSED : %0d", pass_cnt);
        $display("  FAILED : %0d", fail_cnt);
        if (fail_cnt == 0)
            $display("  RESULT : ALL TESTS PASSED");
        else
            $display("  RESULT : SOME TESTS FAILED — check wiring");
        $display("════════════════════════════════════════\n");
        $finish;
    end

    //=========================================================================
    // Watchdog — kills runaway simulation
    //=========================================================================
    initial begin
        #500000;
        $display("WATCHDOG: simulation timeout");
        $finish;
    end

endmodule
