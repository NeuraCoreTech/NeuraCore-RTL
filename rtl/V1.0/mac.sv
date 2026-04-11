`timescale 1ns / 1ps

(* use_dsp = "yes" *)
module mac#(
    parameter DATA_WIDTH = 8,
    parameter MULT_WIDTH = 24
)(
    input  logic clk,
    input  logic ce,
    input  logic sclr,
    input  logic [DATA_WIDTH-1:0]  ifmap,
    input  logic [DATA_WIDTH-1:0]  filter,
    input  logic [MULT_WIDTH-1:0]  psumin,   // ← 24b
    output logic [MULT_WIDTH-1:0]  psumout   // ← 24b
);
    // Internal signals
    logic [MULT_WIDTH-1:0] mac_out;
    logic [MULT_WIDTH-1:0] c_ext;

    // psumin already MULT_WIDTH so no extension needed
    assign c_ext = psumin;

    // ================================
    // Xilinx Multiply-Adder IP
    // ================================
    xbip_multadd_8bit mac_ip (
        .CLK(clk),
        .CE(ce),
        .SCLR(sclr),
        .A(ifmap),
        .B(filter),
        .C(c_ext),
        .SUBTRACT(1'b0),
        .P(mac_out),
        .PCOUT()
    );

    // ================================
    // Output stage - NO saturation
    // just register mac_out directly
    // BN+quantize handles range later
    // ================================
    always_ff @(posedge clk) begin
        if (sclr)
            psumout <= '0;
        else if (ce)
            psumout <= mac_out;   // ← just pass through, no clamping
    end

endmodule