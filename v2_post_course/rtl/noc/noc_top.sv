`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: noc_top
// Project Name: Eyeriss-style CNN accelerator with hierarchical NoC
// Target Devices: Xilinx 7-series
// Tool Versions: Vivado 2025.1
// Description: Two-level hierarchical NoC: a MESH_X x MESH_Y mesh of routers, each
//              serving CPR PE-cluster nodes, in three networks (weight, ifmap,
//              psum). Holds router/node configuration registers and the global
//              start / all_done control.
// 
// Dependencies: noc_mesh, noc_router, noc_node
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// Networks (index used in rcfg_net):  0 = weight (horizontal links only),
//                                      1 = ifmap, 2 = psum.
// GLB side (modelled as streams, one set per router):
//   glbw_*  : weight words in            (W net external port 0)
//   glbi_*  : ifmap  words in            (I net external port 0)
//   glbp_in_*  : psum preload words in   (P net external port CPR)
//   glbp_out_* : psum results out, one stream per local cluster
//                (P net external ports 0..CPR-1) -- dedicated result ports,
//                because a router output has a single source and cannot merge.
//
// Router config (word-addressed, one field per write):
//   rcfg_net, rcfg_router, rcfg_port (output port index), rcfg_field:
//     0 en   1 src   2 k   3 g   4 ph     (see noc_router)
//   rcfg_clear clears every config register and router state.
// Node config: ncfg_node (or ncfg_bcast=1 for all nodes), ncfg_addr, ncfg_data
//   (see noc_node: 0 nf, 1 nc, 2 ofmap_len, 3 psum_in_valid, 4 enable).
// Control: `start` pulses every node; all_done = every node reports layer_done
//   (disabled nodes report done immediately); `clear` clears node done/tag_err.
//
// Port numbers (W/I nets, P = CPR+5): local 0..CPR-1, N=CPR, S=CPR+1, E=CPR+2,
//   W=CPR+3, GLB=CPR+4.   P net (P = 2*CPR+5): local, N/S/E/W as above,
//   result e = CPR+4+e (e<CPR), GLB psum-in = 2*CPR+4.
//==============================================================================
module noc_top #(
    parameter MESH_X      = 2,
    parameter MESH_Y      = 2,
    parameter CPR         = 4,
    parameter PE_ROWS     = 2,
    parameter PE_COLS     = 2,
    parameter DATA_WIDTH  = 8,
    parameter PSUM_WIDTH  = 24,
    parameter MAXKERNELS  = 24,
    parameter MAXCHANNELS = 4,
    parameter MAXOFMAP    = 16,
    parameter FIFO_DEPTH  = 32,

    parameter R    = MESH_X * MESH_Y,
    parameter NN   = R * CPR,
    parameter NPE  = PE_ROWS * PE_COLS,
    parameter TAGW = (NPE > 1) ? $clog2(NPE) : 1,
    parameter LW   = TAGW + DATA_WIDTH,
    parameter LP   = TAGW + PSUM_WIDTH,
    parameter PWI  = CPR + 5,           // ports per router, weight / ifmap nets
    parameter PPS  = 2 * CPR + 5,       // ports per router, psum net
    parameter PMAX = PPS,
    parameter SRCW = $clog2(PMAX),
    parameter CW   = 4,
    parameter RIDW = (R  > 1) ? $clog2(R)  : 1,
    parameter PIDW = $clog2(PMAX),
    parameter NIDW = (NN > 1) ? $clog2(NN) : 1
)(
    input  logic clk,
    input  logic reset,

    // router config
    input  logic                rcfg_we,
    input  logic                rcfg_clear,
    input  logic [1:0]          rcfg_net,
    input  logic [RIDW-1:0]     rcfg_router,
    input  logic [PIDW-1:0]     rcfg_port,
    input  logic [2:0]          rcfg_field,
    input  logic [15:0]         rcfg_data,
    // node config / control
    input  logic                ncfg_we,
    input  logic                ncfg_bcast,
    input  logic [NIDW-1:0]     ncfg_node,
    input  logic [2:0]          ncfg_addr,
    input  logic [15:0]         ncfg_data,
    input  logic                start,
    input  logic                clear,
    output logic                all_done,
    output logic                tag_err_any,

    // GLB streams
    input  logic [R-1:0]                  glbw_valid,
    input  logic [R-1:0]                  glbw_last,
    input  logic [R-1:0][LW-1:0]          glbw_data,
    output logic [R-1:0]                  glbw_ready,
    input  logic [R-1:0]                  glbi_valid,
    input  logic [R-1:0]                  glbi_last,
    input  logic [R-1:0][LW-1:0]          glbi_data,
    output logic [R-1:0]                  glbi_ready,
    input  logic [R-1:0]                  glbp_in_valid,
    input  logic [R-1:0]                  glbp_in_last,
    input  logic [R-1:0][LP-1:0]          glbp_in_data,
    output logic [R-1:0]                  glbp_in_ready,
    output logic [R-1:0][CPR-1:0]         glbp_out_valid,
    output logic [R-1:0][CPR-1:0]         glbp_out_last,
    output logic [R-1:0][CPR-1:0][LP-1:0] glbp_out_data,
    input  logic [R-1:0][CPR-1:0]         glbp_out_ready
);

    // ------------------------------------------------------------------
    // Router configuration registers  [net][router][port]
    // ------------------------------------------------------------------
    logic               c_en  [3][R][PMAX];
    logic [SRCW-1:0]    c_src [3][R][PMAX];
    logic [CW-1:0]      c_k   [3][R][PMAX];
    logic [CW-1:0]      c_g   [3][R][PMAX];
    logic [CW-1:0]      c_ph  [3][R][PMAX];

    always_ff @(posedge clk or posedge reset) begin
        if (reset || rcfg_clear) begin
            for (int n = 0; n < 3; n++)
                for (int r = 0; r < R; r++)
                    for (int p = 0; p < PMAX; p++) begin
                        c_en [n][r][p] <= 1'b0;
                        c_src[n][r][p] <= '0;
                        c_k  [n][r][p] <= '0;
                        c_g  [n][r][p] <= '0;
                        c_ph [n][r][p] <= '0;
                    end
        end else if (rcfg_we && int'(rcfg_net) < 3 && int'(rcfg_router) < R && int'(rcfg_port) < PMAX) begin
            case (rcfg_field)
                3'd0: c_en [rcfg_net][rcfg_router][rcfg_port] <= rcfg_data[0];
                3'd1: c_src[rcfg_net][rcfg_router][rcfg_port] <= rcfg_data[SRCW-1:0];
                3'd2: c_k  [rcfg_net][rcfg_router][rcfg_port] <= rcfg_data[CW-1:0];
                3'd3: c_g  [rcfg_net][rcfg_router][rcfg_port] <= rcfg_data[CW-1:0];
                3'd4: c_ph [rcfg_net][rcfg_router][rcfg_port] <= rcfg_data[CW-1:0];
                default: ;
            endcase
        end
    end

    // pack config into per-network vectors
    logic [R-1:0][PWI-1:0]           w_en, i_en;
    logic [R-1:0][PWI-1:0][SRCW-1:0] w_src, i_src;
    logic [R-1:0][PWI-1:0][CW-1:0]   w_k, w_g, w_ph, i_k, i_g, i_ph;
    logic [R-1:0][PPS-1:0]           p_en;
    logic [R-1:0][PPS-1:0][SRCW-1:0] p_src;
    logic [R-1:0][PPS-1:0][CW-1:0]   p_k, p_g, p_ph;

    always_comb begin
        for (int r = 0; r < R; r++) begin
            for (int p = 0; p < PWI; p++) begin
                w_en[r][p] = c_en[0][r][p]; w_src[r][p] = c_src[0][r][p];
                w_k [r][p] = c_k [0][r][p]; w_g  [r][p] = c_g  [0][r][p]; w_ph[r][p] = c_ph[0][r][p];
                i_en[r][p] = c_en[1][r][p]; i_src[r][p] = c_src[1][r][p];
                i_k [r][p] = c_k [1][r][p]; i_g  [r][p] = c_g  [1][r][p]; i_ph[r][p] = c_ph[1][r][p];
            end
            for (int p = 0; p < PPS; p++) begin
                p_en[r][p] = c_en[2][r][p]; p_src[r][p] = c_src[2][r][p];
                p_k [r][p] = c_k [2][r][p]; p_g  [r][p] = c_g  [2][r][p]; p_ph[r][p] = c_ph[2][r][p];
            end
        end
    end

    // ------------------------------------------------------------------
    // Node <-> mesh signals
    // ------------------------------------------------------------------
    // weight / ifmap networks: mesh local OUT -> node
    logic [R-1:0][CPR-1:0]          w_lo_valid, w_lo_last, w_lo_ready;
    logic [R-1:0][CPR-1:0][LW-1:0]  w_lo_data;
    logic [R-1:0][CPR-1:0]          i_lo_valid, i_lo_last, i_lo_ready;
    logic [R-1:0][CPR-1:0][LW-1:0]  i_lo_data;
    logic [R-1:0][CPR-1:0]          w_li_ready, i_li_ready;       // unused local-in sides
    // psum network
    logic [R-1:0][CPR-1:0]          p_lo_valid, p_lo_last, p_lo_ready;   // -> node pi
    logic [R-1:0][CPR-1:0][LP-1:0]  p_lo_data;
    logic [R-1:0][CPR-1:0]          p_li_valid, p_li_last, p_li_ready;   // <- node po
    logic [R-1:0][CPR-1:0][LP-1:0]  p_li_data;

    // external port arrays
    logic [R-1:0][0:0]              w_ei_ready, i_ei_ready;
    logic [R-1:0][0:0]              w_eo_valid, w_eo_last, i_eo_valid, i_eo_last;
    logic [R-1:0][0:0][LW-1:0]      w_eo_data, i_eo_data;
    logic [R-1:0][CPR:0]            p_ei_valid, p_ei_last, p_ei_ready;
    logic [R-1:0][CPR:0][LP-1:0]    p_ei_data;
    logic [R-1:0][CPR:0]            p_eo_valid, p_eo_last, p_eo_ready;
    logic [R-1:0][CPR:0][LP-1:0]    p_eo_data;

    // GLB hookup
    always_comb begin
        for (int r = 0; r < R; r++) begin
            glbw_ready[r]    = w_ei_ready[r][0];
            glbi_ready[r]    = i_ei_ready[r][0];
            glbp_in_ready[r] = p_ei_ready[r][CPR];
            for (int k = 0; k < CPR; k++) begin
                glbp_out_valid[r][k] = p_eo_valid[r][k];
                glbp_out_last [r][k] = p_eo_last [r][k];
                glbp_out_data [r][k] = p_eo_data [r][k];
            end
            // psum external ports: results (e<CPR) are outputs, e=CPR is the GLB input
            for (int e = 0; e < CPR; e++) begin
                p_ei_valid[r][e] = 1'b0;
                p_ei_last [r][e] = 1'b0;
                p_ei_data [r][e] = '0;
                p_eo_ready[r][e] = glbp_out_ready[r][e];
            end
            p_ei_valid[r][CPR] = glbp_in_valid[r];
            p_ei_last [r][CPR] = glbp_in_last [r];
            p_ei_data [r][CPR] = glbp_in_data [r];
            p_eo_ready[r][CPR] = 1'b0;
        end
    end

    // ------------------------------------------------------------------
    // Three mesh networks
    // ------------------------------------------------------------------
    noc_mesh #(.MESH_X(MESH_X), .MESH_Y(MESH_Y), .CPR(CPR), .NEXT(1), .WIDTH(LW),
               .HORIZ_ONLY(1), .SRCW(SRCW), .CW(CW)) u_net_w (
        .clk(clk), .reset(reset), .cfg_clear(rcfg_clear),
        .cfg_en(w_en), .cfg_src(w_src), .cfg_k(w_k), .cfg_g(w_g), .cfg_ph(w_ph),
        .loc_in_valid('0), .loc_in_last('0), .loc_in_data('0), .loc_in_ready(w_li_ready),
        .loc_out_valid(w_lo_valid), .loc_out_last(w_lo_last), .loc_out_data(w_lo_data),
        .loc_out_ready(w_lo_ready),
        .ext_in_valid(glbw_valid), .ext_in_last(glbw_last), .ext_in_data(glbw_data),
        .ext_in_ready(w_ei_ready),
        .ext_out_valid(w_eo_valid), .ext_out_last(w_eo_last), .ext_out_data(w_eo_data),
        .ext_out_ready('0)
    );

    noc_mesh #(.MESH_X(MESH_X), .MESH_Y(MESH_Y), .CPR(CPR), .NEXT(1), .WIDTH(LW),
               .HORIZ_ONLY(0), .SRCW(SRCW), .CW(CW)) u_net_i (
        .clk(clk), .reset(reset), .cfg_clear(rcfg_clear),
        .cfg_en(i_en), .cfg_src(i_src), .cfg_k(i_k), .cfg_g(i_g), .cfg_ph(i_ph),
        .loc_in_valid('0), .loc_in_last('0), .loc_in_data('0), .loc_in_ready(i_li_ready),
        .loc_out_valid(i_lo_valid), .loc_out_last(i_lo_last), .loc_out_data(i_lo_data),
        .loc_out_ready(i_lo_ready),
        .ext_in_valid(glbi_valid), .ext_in_last(glbi_last), .ext_in_data(glbi_data),
        .ext_in_ready(i_ei_ready),
        .ext_out_valid(i_eo_valid), .ext_out_last(i_eo_last), .ext_out_data(i_eo_data),
        .ext_out_ready('0)
    );

    noc_mesh #(.MESH_X(MESH_X), .MESH_Y(MESH_Y), .CPR(CPR), .NEXT(CPR+1), .WIDTH(LP),
               .HORIZ_ONLY(0), .SRCW(SRCW), .CW(CW)) u_net_p (
        .clk(clk), .reset(reset), .cfg_clear(rcfg_clear),
        .cfg_en(p_en), .cfg_src(p_src), .cfg_k(p_k), .cfg_g(p_g), .cfg_ph(p_ph),
        .loc_in_valid(p_li_valid), .loc_in_last(p_li_last), .loc_in_data(p_li_data),
        .loc_in_ready(p_li_ready),
        .loc_out_valid(p_lo_valid), .loc_out_last(p_lo_last), .loc_out_data(p_lo_data),
        .loc_out_ready(p_lo_ready),
        .ext_in_valid(p_ei_valid), .ext_in_last(p_ei_last), .ext_in_data(p_ei_data),
        .ext_in_ready(p_ei_ready),
        .ext_out_valid(p_eo_valid), .ext_out_last(p_eo_last), .ext_out_data(p_eo_data),
        .ext_out_ready(p_eo_ready)
    );

    // ------------------------------------------------------------------
    // Nodes (router r, local port k  ->  node index r*CPR + k)
    // ------------------------------------------------------------------
    logic [NN-1:0] node_done, node_tag_err;

    genvar gr, gk;
    generate
        for (gr = 0; gr < R; gr++) begin : g_r
            for (gk = 0; gk < CPR; gk++) begin : g_k
                localparam NIDX = gr * CPR + gk;
                logic n_cfg_we;
                assign n_cfg_we = ncfg_we && (ncfg_bcast || (int'(ncfg_node) == NIDX));

                noc_node #(
                    .PE_ROWS(PE_ROWS), .PE_COLS(PE_COLS), .DATA_WIDTH(DATA_WIDTH),
                    .PSUM_WIDTH(PSUM_WIDTH), .MAXKERNELS(MAXKERNELS),
                    .MAXCHANNELS(MAXCHANNELS), .MAXOFMAP(MAXOFMAP), .FIFO_DEPTH(FIFO_DEPTH)
                ) u_node (
                    .clk(clk), .reset(reset),
                    .cfg_we(n_cfg_we), .cfg_addr(ncfg_addr), .cfg_wdata(ncfg_data),
                    .start(start), .clear(clear),
                    .layer_done(node_done[NIDX]), .tag_err(node_tag_err[NIDX]),
                    .w_valid (w_lo_valid[gr][gk]), .w_data (w_lo_data[gr][gk]), .w_ready (w_lo_ready[gr][gk]),
                    .i_valid (i_lo_valid[gr][gk]), .i_data (i_lo_data[gr][gk]), .i_ready (i_lo_ready[gr][gk]),
                    .pi_valid(p_lo_valid[gr][gk]), .pi_data(p_lo_data[gr][gk]), .pi_ready(p_lo_ready[gr][gk]),
                    .po_valid(p_li_valid[gr][gk]), .po_data(p_li_data[gr][gk]),
                    .po_last (p_li_last [gr][gk]), .po_ready(p_li_ready[gr][gk])
                );
            end
        end
    endgenerate

    assign all_done    = &node_done;
    assign tag_err_any = |node_tag_err;

endmodule