`timescale 1ns / 1ps

module mac_simple_tb;

    localparam DATA_WIDTH = 8;
    localparam MULT_WIDTH = 24;

    // ==========================================
    // DUT Signals
    // ==========================================
    logic clk = 0;
    logic ce = 1;
    logic sclr = 0;

    logic signed [DATA_WIDTH-1:0]  ifmap;
    logic signed [DATA_WIDTH-1:0]  filter;
    logic signed [MULT_WIDTH-1:0]  psumin;
    logic signed [MULT_WIDTH-1:0]  psumout;

    // ==========================================
    // DUT
    // ==========================================
    mac #(
        .DATA_WIDTH(DATA_WIDTH),
        .MULT_WIDTH(MULT_WIDTH)
    ) dut (
        .clk(clk),
        .ce(ce),
        .sclr(sclr),
        .ifmap(ifmap),
        .filter(filter),
        .psumin(psumin),
        .psumout(psumout)
    );

    // ==========================================
    // Clock Generation
    // ==========================================
    always #5 clk = ~clk;

    // ==========================================
    // Cycle Counter + Monitor
    // ==========================================
    integer cycle = 0;

    always @(posedge clk) begin
        cycle <= cycle + 1;

        $display(
            "Cycle=%0d | A=%4d B=%4d C=%8d || P=%8d",
            cycle,
            ifmap,
            filter,
            psumin,
            psumout
        );
    end

    // ==========================================
    // Stimulus
    // ==========================================
    initial begin

        // Initial values
        ifmap  = 0;
        filter = 0;
        psumin = 0;

        // Reset
        sclr = 1;

        repeat(2) @(posedge clk);

        sclr = 0;

        // ======================================
        // TEST 1
        // 3*4 + 10 = 22
        // ======================================
        @(negedge clk);
        ifmap  = 3;
        filter = 4;
        psumin = 10;

        // ======================================
        // TEST 2
        // 5*(-2) + 100 = 90
        // ======================================
        @(negedge clk);
        ifmap  = 5;
        filter = -2;
        psumin = 100;

        // ======================================
        // TEST 3
        // (-8)*7 + 20 = -36
        // ======================================
        @(negedge clk);
        ifmap  = -8;
        filter = 7;
        psumin = 20;

        // Hold zeros afterward
        @(negedge clk);
        ifmap  = 0;
        filter = 0;
        psumin = 0;

        // Observe pipeline behavior
        repeat(15) @(posedge clk);

        $finish;
    end

endmodule