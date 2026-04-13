`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2026 15:10:36
// Design Name: 
// Module Name: scratchpad_keernel
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


module scratchpad_kernel #(
    parameter MAXKERNELS = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXKERNELWIDTH = 3,
    parameter DATA_WIDTH     = 8,
    parameter DEPTH          = MAXCHANNELS * MAXKERNELWIDTH * MAXKERNELS, // 288
    parameter ADDR_WIDTH     = $clog2(DEPTH)                 //9
)(
    input  logic                   clk,
    input  logic [DATA_WIDTH-1:0]  data_in,
    input  logic                   we,
    input  logic [ADDR_WIDTH-1:0]  addr_wr,   // caller computes chan*3 + kern
    input  logic [ADDR_WIDTH-1:0]  addr_rd,
    output logic [DATA_WIDTH-1:0]  data_out
);
    (* ram_style = "distributed" *)
    logic [DATA_WIDTH-1:0] kernel_sp [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (we)
            kernel_sp[addr_wr] <= data_in;
    end

    assign data_out = kernel_sp[addr_rd];

endmodule