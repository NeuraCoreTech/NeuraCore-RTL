`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: noc_impl_top
// Project Name: Eyeriss-style CNN accelerator with hierarchical NoC
// Target Devices: Xilinx 7-series
// Tool Versions: Vivado 2025.1
// Description: Implementation-only wrapper around noc_top. Exposes just clk, rst
//              and one output bit so place & route and timing can run without
//              hundreds of I/O pins. All noc_top inputs come from a 1024-bit LFSR
//              (so nothing is constant-folded) and every output is XOR-reduced into
//              one register (so nothing is trimmed). NOT a functional test.
// 
// Dependencies: noc_top
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Use only for area/timing. Set this as the top module.
// 
//////////////////////////////////////////////////////////////////////////////////
module noc_impl_top #(
    parameter MESH_X = 2, parameter MESH_Y = 2, parameter CPR = 4,
    parameter PE_ROWS = 2, parameter PE_COLS = 2,
    parameter DATA_WIDTH = 8, parameter PSUM_WIDTH = 24,
    parameter R    = MESH_X * MESH_Y,
    parameter NN   = R * CPR,
    parameter NPE  = PE_ROWS * PE_COLS,
    parameter TAGW = (NPE > 1) ? $clog2(NPE) : 1,
    parameter LW   = TAGW + DATA_WIDTH,
    parameter LP   = TAGW + PSUM_WIDTH,
    parameter PMAX = 2 * CPR + 5,
    parameter RIDW = (R  > 1) ? $clog2(R)  : 1,
    parameter PIDW = $clog2(PMAX),
    parameter NIDW = (NN > 1) ? $clog2(NN) : 1
)(
    input  logic clk,
    input  logic rst,
    output logic dout
);

    // ---------------- stimulus: wide LFSR ----------------
    logic [1023:0] lfsr;
    always_ff @(posedge clk) begin
        if (rst) lfsr <= {1'b1, 1023'd12345};
        else     lfsr <= {lfsr[1022:0], lfsr[1023] ^ lfsr[1000] ^ lfsr[3] ^ lfsr[0]};
    end

    // ---------------- noc_top ports ----------------
    logic                rcfg_we, rcfg_clear;
    logic [1:0]          rcfg_net;
    logic [RIDW-1:0]     rcfg_router;
    logic [PIDW-1:0]     rcfg_port;
    logic [2:0]          rcfg_field;
    logic [15:0]         rcfg_data;
    logic                ncfg_we, ncfg_bcast;
    logic [NIDW-1:0]     ncfg_node;
    logic [2:0]          ncfg_addr;
    logic [15:0]         ncfg_data;
    logic                start, clear, all_done, tag_err_any;
    logic [R-1:0]                  glbw_valid, glbw_last, glbw_ready;
    logic [R-1:0][LW-1:0]          glbw_data;
    logic [R-1:0]                  glbi_valid, glbi_last, glbi_ready;
    logic [R-1:0][LW-1:0]          glbi_data;
    logic [R-1:0]                  glbp_in_valid, glbp_in_last, glbp_in_ready;
    logic [R-1:0][LP-1:0]          glbp_in_data;
    logic [R-1:0][CPR-1:0]         glbp_out_valid, glbp_out_last, glbp_out_ready;
    logic [R-1:0][CPR-1:0][LP-1:0] glbp_out_data;

    // every input bit comes from a different LFSR bit (RHS is wider; extra bits unused)
    assign {rcfg_we, rcfg_clear, rcfg_net, rcfg_router, rcfg_port, rcfg_field, rcfg_data,
            ncfg_we, ncfg_bcast, ncfg_node, ncfg_addr, ncfg_data, start, clear,
            glbw_valid, glbw_last, glbw_data,
            glbi_valid, glbi_last, glbi_data,
            glbp_in_valid, glbp_in_last, glbp_in_data,
            glbp_out_ready} = lfsr;

    noc_top #(.MESH_X(MESH_X), .MESH_Y(MESH_Y), .CPR(CPR),
              .PE_ROWS(PE_ROWS), .PE_COLS(PE_COLS)) u_noc (
        .clk(clk), .reset(rst),
        .rcfg_we(rcfg_we), .rcfg_clear(rcfg_clear), .rcfg_net(rcfg_net),
        .rcfg_router(rcfg_router), .rcfg_port(rcfg_port), .rcfg_field(rcfg_field),
        .rcfg_data(rcfg_data),
        .ncfg_we(ncfg_we), .ncfg_bcast(ncfg_bcast), .ncfg_node(ncfg_node),
        .ncfg_addr(ncfg_addr), .ncfg_data(ncfg_data),
        .start(start), .clear(clear), .all_done(all_done), .tag_err_any(tag_err_any),
        .glbw_valid(glbw_valid), .glbw_last(glbw_last), .glbw_data(glbw_data), .glbw_ready(glbw_ready),
        .glbi_valid(glbi_valid), .glbi_last(glbi_last), .glbi_data(glbi_data), .glbi_ready(glbi_ready),
        .glbp_in_valid(glbp_in_valid), .glbp_in_last(glbp_in_last),
        .glbp_in_data(glbp_in_data), .glbp_in_ready(glbp_in_ready),
        .glbp_out_valid(glbp_out_valid), .glbp_out_last(glbp_out_last),
        .glbp_out_data(glbp_out_data), .glbp_out_ready(glbp_out_ready)
    );

    // fold every output into one registered bit so no logic is trimmed
    logic red;
    always_comb
        red = ^{all_done, tag_err_any, glbw_ready, glbi_ready, glbp_in_ready,
                glbp_out_valid, glbp_out_last, glbp_out_data};
    always_ff @(posedge clk) dout <= red;

endmodule