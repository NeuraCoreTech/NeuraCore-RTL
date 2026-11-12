`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: noc_mesh
// Project Name: Eyeriss-style CNN accelerator with hierarchical NoC
// Target Devices: Xilinx 7-series
// Tool Versions: Vivado 2025.1
// Description: One NoC network: a MESH_X x MESH_Y grid of noc_router instances.
//              Each router has CPR local ports (to PE-cluster nodes), four mesh
//              ports (N,S,E,W) and NEXT external ports (GLB side).
// 
// Dependencies: noc_router
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// Port numbering of every router (P = CPR + 4 + NEXT):
//   0 .. CPR-1        local port k   (in: from node, out: to node)
//   CPR+0  N   CPR+1  S   CPR+2  E   CPR+3  W      (mesh links)
//   CPR+4 .. P-1      external port e (GLB side; each has an in and an out side,
//                     the instantiator uses whichever direction it needs)
//
// Router id = y*MESH_X + x. Link rule: router (x,y) output S feeds router
// (x,y+1) input N, output E feeds (x+1,y) input W, and so on.
// Edge ports without a neighbour: input tied idle, output ready tied low (a
// misconfigured output stalls instead of silently dropping data).
// HORIZ_ONLY=1 forces the N/S outputs off (weight network).
//==============================================================================
module noc_mesh #(
    parameter MESH_X     = 2,
    parameter MESH_Y     = 2,
    parameter CPR        = 4,
    parameter NEXT       = 1,
    parameter WIDTH      = 16,
    parameter HORIZ_ONLY = 0,
    parameter R          = MESH_X * MESH_Y,
    parameter P          = CPR + 4 + NEXT,
    parameter SRCW       = $clog2(P),
    parameter CW         = 4
)(
    input  logic clk,
    input  logic reset,
    input  logic cfg_clear,

    input  logic [R-1:0][P-1:0]            cfg_en,
    input  logic [R-1:0][P-1:0][SRCW-1:0]  cfg_src,
    input  logic [R-1:0][P-1:0][CW-1:0]    cfg_k,
    input  logic [R-1:0][P-1:0][CW-1:0]    cfg_g,
    input  logic [R-1:0][P-1:0][CW-1:0]    cfg_ph,

    // local ports: in = from node, out = to node
    input  logic [R-1:0][CPR-1:0]               loc_in_valid,
    input  logic [R-1:0][CPR-1:0]               loc_in_last,
    input  logic [R-1:0][CPR-1:0][WIDTH-1:0]    loc_in_data,
    output logic [R-1:0][CPR-1:0]               loc_in_ready,
    output logic [R-1:0][CPR-1:0]               loc_out_valid,
    output logic [R-1:0][CPR-1:0]               loc_out_last,
    output logic [R-1:0][CPR-1:0][WIDTH-1:0]    loc_out_data,
    input  logic [R-1:0][CPR-1:0]               loc_out_ready,

    // external ports
    input  logic [R-1:0][NEXT-1:0]              ext_in_valid,
    input  logic [R-1:0][NEXT-1:0]              ext_in_last,
    input  logic [R-1:0][NEXT-1:0][WIDTH-1:0]   ext_in_data,
    output logic [R-1:0][NEXT-1:0]              ext_in_ready,
    output logic [R-1:0][NEXT-1:0]              ext_out_valid,
    output logic [R-1:0][NEXT-1:0]              ext_out_last,
    output logic [R-1:0][NEXT-1:0][WIDTH-1:0]   ext_out_data,
    input  logic [R-1:0][NEXT-1:0]              ext_out_ready
);

    localparam PN = CPR + 0;
    localparam PS = CPR + 1;
    localparam PE = CPR + 2;
    localparam PWST = CPR + 3;

    // per-router port vectors (wires so every bit has one driver)
    wire [P-1:0]               iv [R];
    wire [P-1:0]               il [R];
    wire [P-1:0][WIDTH-1:0]    id [R];
    wire [P-1:0]               ir [R];
    wire [P-1:0]               ov [R];
    wire [P-1:0]               ol [R];
    wire [P-1:0][WIDTH-1:0]    od [R];
    wire [P-1:0]               orr [R];

    genvar gr, gk, ge;
    generate
        for (gr = 0; gr < R; gr++) begin : g_router
            localparam X     = gr % MESH_X;
            localparam Y     = gr / MESH_X;
            localparam HAS_N = (Y > 0);
            localparam HAS_S = (Y < MESH_Y - 1);
            localparam HAS_W = (X > 0);
            localparam HAS_E = (X < MESH_X - 1);

            // ---- local ports ----
            for (gk = 0; gk < CPR; gk++) begin : g_loc
                assign iv[gr][gk]  = loc_in_valid[gr][gk];
                assign il[gr][gk]  = loc_in_last [gr][gk];
                assign id[gr][gk]  = loc_in_data [gr][gk];
                assign loc_in_ready [gr][gk] = ir[gr][gk];
                assign loc_out_valid[gr][gk] = ov[gr][gk];
                assign loc_out_last [gr][gk] = ol[gr][gk];
                assign loc_out_data [gr][gk] = od[gr][gk];
                assign orr[gr][gk]           = loc_out_ready[gr][gk];
            end

            // ---- external ports ----
            for (ge = 0; ge < NEXT; ge++) begin : g_ext
                assign iv[gr][CPR+4+ge] = ext_in_valid[gr][ge];
                assign il[gr][CPR+4+ge] = ext_in_last [gr][ge];
                assign id[gr][CPR+4+ge] = ext_in_data [gr][ge];
                assign ext_in_ready [gr][ge] = ir[gr][CPR+4+ge];
                assign ext_out_valid[gr][ge] = ov[gr][CPR+4+ge];
                assign ext_out_last [gr][ge] = ol[gr][CPR+4+ge];
                assign ext_out_data [gr][ge] = od[gr][CPR+4+ge];
                assign orr[gr][CPR+4+ge]     = ext_out_ready[gr][ge];
            end

            // ---- mesh links: read the neighbour's port vectors ----
            if (HAS_N) begin : g_n
                assign iv[gr][PN]  = ov[gr-MESH_X][PS];
                assign il[gr][PN]  = ol[gr-MESH_X][PS];
                assign id[gr][PN]  = od[gr-MESH_X][PS];
                assign orr[gr][PN] = ir[gr-MESH_X][PS];
            end else begin : g_n0
                assign iv[gr][PN]  = 1'b0;
                assign il[gr][PN]  = 1'b0;
                assign id[gr][PN]  = '0;
                assign orr[gr][PN] = 1'b0;
            end
            if (HAS_S) begin : g_s
                assign iv[gr][PS]  = ov[gr+MESH_X][PN];
                assign il[gr][PS]  = ol[gr+MESH_X][PN];
                assign id[gr][PS]  = od[gr+MESH_X][PN];
                assign orr[gr][PS] = ir[gr+MESH_X][PN];
            end else begin : g_s0
                assign iv[gr][PS]  = 1'b0;
                assign il[gr][PS]  = 1'b0;
                assign id[gr][PS]  = '0;
                assign orr[gr][PS] = 1'b0;
            end
            if (HAS_E) begin : g_e
                assign iv[gr][PE]  = ov[gr+1][PWST];
                assign il[gr][PE]  = ol[gr+1][PWST];
                assign id[gr][PE]  = od[gr+1][PWST];
                assign orr[gr][PE] = ir[gr+1][PWST];
            end else begin : g_e0
                assign iv[gr][PE]  = 1'b0;
                assign il[gr][PE]  = 1'b0;
                assign id[gr][PE]  = '0;
                assign orr[gr][PE] = 1'b0;
            end
            if (HAS_W) begin : g_w
                assign iv[gr][PWST]  = ov[gr-1][PE];
                assign il[gr][PWST]  = ol[gr-1][PE];
                assign id[gr][PWST]  = od[gr-1][PE];
                assign orr[gr][PWST] = ir[gr-1][PE];
            end else begin : g_w0
                assign iv[gr][PWST]  = 1'b0;
                assign il[gr][PWST]  = 1'b0;
                assign id[gr][PWST]  = '0;
                assign orr[gr][PWST] = 1'b0;
            end

            // ---- config mask (weight network has no vertical links) ----
            logic [P-1:0] en_m;
            always_comb begin
                en_m = cfg_en[gr];
                if (HORIZ_ONLY) begin
                    en_m[PN] = 1'b0;
                    en_m[PS] = 1'b0;
                end
            end

            noc_router #(.P(P), .WIDTH(WIDTH), .SRCW(SRCW), .CW(CW)) u_router (
                .clk       (clk),
                .reset     (reset),
                .cfg_clear (cfg_clear),
                .cfg_en    (en_m),
                .cfg_src   (cfg_src[gr]),
                .cfg_k     (cfg_k[gr]),
                .cfg_g     (cfg_g[gr]),
                .cfg_ph    (cfg_ph[gr]),
                .in_valid  (iv[gr]),
                .in_last   (il[gr]),
                .in_data   (id[gr]),
                .in_ready  (ir[gr]),
                .out_valid (ov[gr]),
                .out_last  (ol[gr]),
                .out_data  (od[gr]),
                .out_ready (orr[gr])
            );
        end
    endgenerate

endmodule