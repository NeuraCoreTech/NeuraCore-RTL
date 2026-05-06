`timescale 1ns / 1ps

module mac_tb;

// =========================================================
// Parameters
// =========================================================
localparam DATA_WIDTH  = 8;
localparam MULT_WIDTH  = 24;
localparam MAC_LATENCY = 3;         // A:B=3 + C=2
// The golden value is registered into pipe[0] on the SAME
// rising edge that the DUT sees the input, so we need one
// extra slot: pipe depth = MAC_LATENCY + 1, read from [MAC_LATENCY].
localparam PIPE_DEPTH  = MAC_LATENCY + 1;
localparam CLK_PERIOD  = 10;
localparam NUM_TESTS   = 20;

// =========================================================
// DUT ports
// =========================================================
logic                      clk    = 0;
logic                      ce     = 1;
logic                      sclr   = 0;
logic [DATA_WIDTH-1:0]     ifmap;
logic [DATA_WIDTH-1:0]     filter;
logic [MULT_WIDTH-1:0]     psumin;
logic [MULT_WIDTH-1:0]     psumout;

// =========================================================
// DUT
// =========================================================
mac #(
    .DATA_WIDTH (DATA_WIDTH),
    .MULT_WIDTH (MULT_WIDTH)
) dut (
    .clk     (clk),
    .ce      (ce),
    .sclr    (sclr),
    .ifmap   (ifmap),
    .filter  (filter),
    .psumin  (psumin),
    .psumout (psumout)
);

// =========================================================
// Clock
// =========================================================
always #(CLK_PERIOD/2) clk = ~clk;

// =========================================================
// Golden reference pipeline
//
//  negedge: inputs driven
//  posedge: DUT latches inputs AND we register golden into pipe[0]
//           → pipe[0] = A*B+C seen this cycle
//           → pipe[1] = seen 1 cycle ago
//           → ...
//           → pipe[MAC_LATENCY] = seen MAC_LATENCY cycles ago
//                               = what psumout reflects NOW
// =========================================================
logic signed [MULT_WIDTH-1:0] expected_pipe [0:PIPE_DEPTH-1];

// Combinatorial golden (uses inputs BEFORE the posedge latch)
wire signed [MULT_WIDTH-1:0] golden =
    ($signed(ifmap) * $signed(filter)) + $signed(psumin);

integer k;
always_ff @(posedge clk) begin
    if (sclr) begin
        for (k = 0; k < PIPE_DEPTH; k++)
            expected_pipe[k] <= '0;
    end else if (ce) begin
        expected_pipe[0] <= golden;
        for (k = 1; k < PIPE_DEPTH; k++)
            expected_pipe[k] <= expected_pipe[k-1];
    end
end

// This now correctly lines up with psumout
wire signed [MULT_WIDTH-1:0] expected_now = expected_pipe[MAC_LATENCY-1];

// =========================================================
// Scoreboard
//   Wait PIPE_DEPTH cycles before comparing so the pipe is full
// =========================================================
int  cycle_count  = 0;
int  pass_count   = 0;
int  fail_count   = 0;
bit  check_active = 0;

always_ff @(posedge clk) begin
    if (!sclr && ce) begin
        cycle_count++;
        if (cycle_count > PIPE_DEPTH)
            check_active = 1;
    end

    if (check_active) begin
        if ($signed(psumout) === $signed(expected_now)) begin
            pass_count++;
            $display("[PASS] cy=%-2d  A=%-5d B=%-5d C=%-10d | got=%-10d  exp=%-10d",
                cycle_count, $signed(ifmap), $signed(filter),
                $signed(psumin), $signed(psumout), $signed(expected_now));
        end else begin
            fail_count++;
            $display("[FAIL] cy=%-2d  A=%-5d B=%-5d C=%-10d | got=%-10d  exp=%-10d  *** MISMATCH ***",
                cycle_count, $signed(ifmap), $signed(filter),
                $signed(psumin), $signed(psumout), $signed(expected_now));
        end
    end
end

// =========================================================
// Stimulus task  (drive on negedge → stable before posedge)
// =========================================================
task automatic apply_input(
    input logic signed [DATA_WIDTH-1:0] a,
    input logic signed [DATA_WIDTH-1:0] b,
    input logic signed [MULT_WIDTH-1:0] c
);
    @(negedge clk);
    ifmap  = a;
    filter = b;
    psumin = c;
endtask

// =========================================================
// Main sequence
// =========================================================
initial begin
    ifmap = '0; filter = '0; psumin = '0;
    ce = 1; sclr = 1;

    // Reset
    repeat(4) @(posedge clk);
    @(negedge clk); sclr = 0;

    // ── Corner cases ──────────────────────────────────────
    $display("\n=== Corner Cases ===");
    apply_input(  8'sd0,    8'sd0,    24'sd0    );  // 0
    apply_input(  8'sd1,    8'sd1,    24'sd0    );  // 1
    apply_input(  8'sd127,  8'sd127,  24'sd0    );  // 16129
    apply_input( -8'sd128, -8'sd128,  24'sd0    );  // 16384
    apply_input(  8'sd127, -8'sd128,  24'sd0    );  // -16256
    apply_input(  8'sd10,   8'sd20,   24'sd500  );  // 700
    apply_input( -8'sd5,    8'sd3,   -24'sd100  );  // -115

    // ── Random vectors ────────────────────────────────────
    $display("\n=== Random Vectors ===");
    repeat(NUM_TESTS) begin
        automatic logic signed [DATA_WIDTH-1:0] ra = $urandom;
        automatic logic signed [DATA_WIDTH-1:0] rb = $urandom;
        automatic logic signed [MULT_WIDTH-1:0] rc = $urandom;
        apply_input(ra, rb, rc);
    end

    // Drain pipeline
    repeat(PIPE_DEPTH + 2) @(posedge clk);

    // ── SCLR clears output ────────────────────────────────
    $display("\n=== SCLR Test ===");
    apply_input(8'sd50, 8'sd50, 24'sd0);
    repeat(MAC_LATENCY) @(posedge clk);
    @(negedge clk); sclr = 1;
    @(posedge clk);
    @(negedge clk); sclr = 0;
    @(posedge clk);
    if (psumout === '0)
        $display("[PASS] SCLR cleared psumout to 0");
    else
        $display("[FAIL] SCLR did NOT clear psumout (got %0d)", $signed(psumout));

    // ── CE freezes output ─────────────────────────────────
    $display("\n=== CE Gating Test ===");
    apply_input(8'sd10, 8'sd10, 24'sd0);   // expect 100 after latency
    repeat(MAC_LATENCY + 1) @(posedge clk);
    begin
        automatic logic signed [MULT_WIDTH-1:0] frozen = psumout;
        $display("     Freezing at psumout = %0d", $signed(frozen));
        @(negedge clk); ce = 0;
        repeat(5) @(posedge clk);
        if (psumout === frozen)
            $display("[PASS] CE=0 held psumout at %0d", $signed(frozen));
        else
            $display("[FAIL] CE=0 failed: was %0d, now %0d",
                      $signed(frozen), $signed(psumout));
        @(negedge clk); ce = 1;
    end

    // Final drain
    repeat(3) @(posedge clk);

    // ── Summary ───────────────────────────────────────────
    $display("\n========================================");
    $display(" TEST SUMMARY");
    $display("  PASS : %0d", pass_count);
    $display("  FAIL : %0d", fail_count);
    if (fail_count == 0)
        $display("  *** ALL TESTS PASSED ***");
    else
        $display("  *** %0d FAILURE(S) DETECTED ***", fail_count);
    $display("========================================\n");
    $finish;
end

// Watchdog
initial begin
    #(CLK_PERIOD * 600);
    $display("[WATCHDOG] Timeout!"); $finish;
end
endmodule
