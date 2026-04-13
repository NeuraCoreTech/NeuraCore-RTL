`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2026 15:10:36
// Design Name: 
// Module Name: scratchpad_psum
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


module scratchpad_psum #(
    parameter MAXOUTPUTS    = 24,
    parameter DATA_WIDTH     = 24,
    parameter ADDR_WIDTH     = $clog2(MAXOUTPUTS)                 // 4
)(
    input  logic                   clk,
    input  logic [DATA_WIDTH-1:0]  data_in,
    input  logic                   we,
    input  logic [ADDR_WIDTH-1:0]  addr_wr, 
    input  logic [ADDR_WIDTH-1:0]  addr_rd,
    output logic [DATA_WIDTH-1:0]  data_out
);
    (* ram_style = "distributed" *)
    logic [DATA_WIDTH-1:0] psum_sp [0:MAXOUTPUTS-1];

    always_ff @(posedge clk) begin
        if (we)
            psum_sp[addr_wr] <= data_in;
    end

    assign data_out = psum_sp[addr_rd];

endmodule
