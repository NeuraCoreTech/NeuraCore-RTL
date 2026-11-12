`timescale 1ns / 1ps
//==============================================================================
// scratchpad_psum : partial sums. Block RAM, sync write, SYNC READ with enable
// (data_out valid 1 cycle after addr_rd when rd_en=1; holds when rd_en=0).
// Read-first on same-address collision.
//==============================================================================
module scratchpad_psum #(
    parameter MAXOUTPUTS = 24,
    parameter DATA_WIDTH = 24,
    parameter ADDR_WIDTH = $clog2(MAXOUTPUTS)
)(
    input  logic                   clk,
    input  logic [DATA_WIDTH-1:0]  data_in,
    input  logic                   we,
    input  logic [ADDR_WIDTH-1:0]  addr_wr,
    input  logic [ADDR_WIDTH-1:0]  addr_rd,
    input  logic                   rd_en,
    output logic [DATA_WIDTH-1:0]  data_out
);
    (* ram_style = "block" *)
    logic [DATA_WIDTH-1:0] psum_sp [0:MAXOUTPUTS-1];

    always_ff @(posedge clk) begin
        if (we)    psum_sp[addr_wr] <= data_in;
        if (rd_en) data_out <= psum_sp[addr_rd];
    end
endmodule