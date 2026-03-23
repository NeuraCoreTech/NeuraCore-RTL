`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2026 15:21:42
// Design Name: 
// Module Name: mac
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

(* use_dsp = "yes" *)
module mac#(
    parameter DATA_WIDTH = 8,
    parameter MULT_WIDTH = 16
)(
    input  logic clk,
    input  logic ce,
    input  logic sclr,
    input  logic [DATA_WIDTH-1:0] ifmap,
    input  logic [DATA_WIDTH-1:0] filter,
    input  logic [DATA_WIDTH-1:0] psumin,
    output logic [DATA_WIDTH-1:0] psumout
);

    // Internal signals
    logic [MULT_WIDTH-1:0] mac_out;
    logic [MULT_WIDTH-1:0] c_ext;
    logic [MULT_WIDTH-1:0] out_raw;

    // Extend psumin to match C width
    assign c_ext = {{(MULT_WIDTH-DATA_WIDTH){1'b0}}, psumin};

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
        .SUBTRACT(1'b0),     // always add
        .P(mac_out),
        .PCOUT()             // unused
    );

    // ================================
    // Output stage (clamp / truncate)
    // ================================
    always_ff @(posedge clk) begin
        if (sclr)
            psumout <= 0;
        else if (ce) begin
            out_raw <= mac_out;

            // Saturation logic
            if (out_raw > {DATA_WIDTH{1'b1}})
                psumout <= {DATA_WIDTH{1'b1}};
            else
                psumout <= out_raw[DATA_WIDTH-1:0];
        end
    end

endmodule