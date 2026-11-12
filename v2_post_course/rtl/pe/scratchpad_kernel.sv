`timescale 1ns / 1ps
//==============================================================================
// scratchpad_kernel : filter weights. Block RAM, sync write, SYNC READ
// (data_out valid 1 cycle after addr_rd). Read-first on same-address collision.
//==============================================================================
module scratchpad_kernel #(
    parameter MAXKERNELS     = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXKERNELWIDTH = 3,
    parameter DATA_WIDTH     = 8,
    parameter DEPTH          = MAXCHANNELS * MAXKERNELWIDTH * MAXKERNELS, // 288
    parameter ADDR_WIDTH     = $clog2(DEPTH)                              // 9
)(
    input  logic                   clk,
    input  logic [DATA_WIDTH-1:0]  data_in,
    input  logic                   we,
    input  logic [ADDR_WIDTH-1:0]  addr_wr,
    input  logic [ADDR_WIDTH-1:0]  addr_rd,
    output logic [DATA_WIDTH-1:0]  data_out
);
    (* ram_style = "block" *)
    logic [DATA_WIDTH-1:0] kernel_sp [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (we) kernel_sp[addr_wr] <= data_in;
        data_out <= kernel_sp[addr_rd];
    end
endmodule