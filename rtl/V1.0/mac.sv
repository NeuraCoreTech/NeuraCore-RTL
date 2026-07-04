`timescale 1ns / 1ps
(* use_dsp = "yes" *)
module mac#(
    parameter DATA_WIDTH = 8,
    parameter MULT_WIDTH = 24
)(
    input  logic clk,
    input  logic ce,
    input  logic sclr,
    input  logic signed [DATA_WIDTH-1:0]  ifmap,
    input  logic signed [DATA_WIDTH-1:0]  filter,
    input  logic signed [MULT_WIDTH-1:0]  psumin,
    output logic signed [MULT_WIDTH-1:0]  psumout
);
    
    // ================================
    // Xilinx Multiply-Adder IP
    // Latency: 3 cycles total
    // Output P is already registered inside the IP
    // ================================
    logic signed [MULT_WIDTH-1:0] buffer_psumin;
    always_ff @(posedge clk) begin
        if (sclr)    buffer_psumin <= '0;
        else if (ce) buffer_psumin <= psumin;  
    end
    xbip_multadd_8bit mac_ip (
        .CLK      (clk),
        .CE       (ce),
        .SCLR     (sclr),
        .A        (ifmap),
        .B        (filter),
        .C        (buffer_psumin),
        .SUBTRACT (1'b0),
        .P        (psumout),
        .PCOUT    ()
    );

endmodule