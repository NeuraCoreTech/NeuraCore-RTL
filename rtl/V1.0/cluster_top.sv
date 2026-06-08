`timescale 1ns / 1ps
//==============================================================================
// Module      : cluster_top
// Description : Structural wrapper for a PE_ROWS × PE_COLS PE cluster following
//               Eyeriss row-stationary dataflow.
//
// Hierarchy
// ─────────────────────────────────────────────────────────────────────────────
//   cluster_top
//   ├── u_ctrl          : cluster_ctrl  (gang-start FSM)
//   └── gen_row/gen_col : PE_top [PE_ROWS][PE_COLS]
//
// Dataflow (row-stationary)
// ─────────────────────────────────────────────────────────────────────────────
//   Filter  : unique per PE  → PE_ROWS × PE_COLS independent filter streams
//   IFmap   : one stream per row, broadcast to all PE_COLS in that row
//   Psum    : vertical chain per column
//               cluster psum_in[c] → PE[0][c] → PE[1][c] → cluster psum_out[c]
//               (row 0 = bottom, row PE_ROWS-1 = top)
//
// External interfaces (to global router / noc_top)
// ─────────────────────────────────────────────────────────────────────────────
//   Filter  : filter_valid/data/ready  [PE_ROWS][PE_COLS]
//   IFmap   : ifmap_valid/data/ready   [PE_ROWS]   (ready = AND of row PEs)
//   Psum in : psum_in_valid/data/ready [PE_COLS]   (feeds bottom row)
//   Psum out: psum_out_valid/data/re   [PE_COLS]   (from top row, to router)
//   Handshake: start / done
//==============================================================================

module cluster_top #(
    parameter PE_ROWS        = 2,
    parameter PE_COLS        = 2,
    parameter DATA_WIDTH     = 8,
    parameter PSUM_WIDTH     = 24,
    parameter MAXKERNELS     = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXKERNELWIDTH = 3,
    parameter MAC_LATENCY    = 3,
    parameter FIFO_DEPTH     = 32,

    // Config field widths (must match PE_top / PEControlUnit)
    parameter CFG_F_W = $clog2(MAXKERNELS  + 1),   // 5
    parameter CFG_C_W = $clog2(MAXCHANNELS + 1),   // 3
    parameter CFG_X_W = 8
)(
    input  logic clk,
    input  logic reset,

    // Cluster handshake (to/from global router) 
    input  logic start,
    output logic done,

    // Configuration — broadcast identically to every PE 
    input  logic [CFG_F_W-1:0] cfg_num_filters,
    input  logic [CFG_C_W-1:0] cfg_num_channels,
    input  logic [CFG_X_W-1:0] cfg_ofmap_len,
    input  logic               cfg_psum_in_valid,

    // Filter streams — unique per PE [row][col] 
    input  logic [PE_ROWS-1:0][PE_COLS-1:0]                  filter_valid,
    input  logic [PE_ROWS-1:0][PE_COLS-1:0][DATA_WIDTH-1:0]  filter_data,
    output logic [PE_ROWS-1:0][PE_COLS-1:0]                  filter_ready,

    // IFmap streams — one per row, broadcast across columns 
    // ifmap_ready[r] = AND of all PE[r][*].ifmap_ready
    // (all PEs in row must be ready before upstream sends next word)
    input  logic [PE_ROWS-1:0]                 ifmap_valid,
    input  logic [PE_ROWS-1:0][DATA_WIDTH-1:0] ifmap_data,
    output logic [PE_ROWS-1:0]                 ifmap_ready,

    // Psum in — from cluster below / global router, per column 
    // Drives the psum_in port of the bottom PE row (row 0)
    input  logic [PE_COLS-1:0]                  psum_in_valid,
    input  logic [PE_COLS-1:0][PSUM_WIDTH-1:0]  psum_in_data,
    output logic [PE_COLS-1:0]                  psum_in_ready,

    // Psum out — from top PE row (row PE_ROWS-1), to cluster above 
    // Backed by PE internal output FIFOs; psum_out_re is driven by router
    output logic [PE_COLS-1:0][PSUM_WIDTH-1:0]  psum_out_data,
    output logic [PE_COLS-1:0]                   psum_out_valid,
    input  logic [PE_COLS-1:0]                   psum_out_re
);

    // Internal signal arrays
    // All PE ports are named pe_<signal>[row][col] so the generate loop
    // can connect them uniformly without conditionals in the port map.

    // ── cluster_ctrl -> PE array 
    logic [PE_ROWS-1:0][PE_COLS-1:0] pe_start;
    logic [PE_ROWS-1:0][PE_COLS-1:0] pe_done;

    // PE ifmap_ready (captured so we can AND-reduce per row) 
    logic [PE_ROWS-1:0][PE_COLS-1:0] pe_ifmap_ready;

    // Full PE psum in/out arrays 
    logic [PE_ROWS-1:0][PE_COLS-1:0][PSUM_WIDTH-1:0] pe_psum_in_data;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  pe_psum_in_valid;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  pe_psum_in_ready;

    logic [PE_ROWS-1:0][PE_COLS-1:0][PSUM_WIDTH-1:0] pe_psum_out_data;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  pe_psum_out_valid;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  pe_psum_out_re;

    
    // Psum chain routing
    //
    //
    //   row 0 (bottom): pe_psum_in  <- cluster psum_in  ports
    //                   pe_psum_out -> pe_psum_in of row 1
    //   row r (middle): pe_psum_in  <- pe_psum_out of row r-1
    //                   pe_psum_out -> pe_psum_in of row r+1
    //   row PE_ROWS-1 (top): pe_psum_in  <- pe_psum_out of row r-1
    //                        pe_psum_out -> cluster psum_out ports
    
    genvar r, c;

    generate
        for (r = 0; r < PE_ROWS; r++) begin : gen_psum_route_row
            for (c = 0; c < PE_COLS; c++) begin : gen_psum_route_col

                if (r == 0) begin : bottom_row
                    // Bottom PE: receives psum from outside cluster
                    assign pe_psum_in_valid[r][c] = psum_in_valid[c];
                    assign pe_psum_in_data [r][c] = psum_in_data [c];
                    assign psum_in_ready   [c]    = pe_psum_in_ready[r][c];
                end else begin : upper_rows
                    // Upper PEs: receive psum from PE below
                    assign pe_psum_in_valid [r][c]   = pe_psum_out_valid[r-1][c];
                    assign pe_psum_in_data  [r][c]   = pe_psum_out_data [r-1][c];
                    // re of the PE below is driven by the ready of this PE's input
                    assign pe_psum_out_re   [r-1][c] = pe_psum_in_ready [r][c];
                end

                if (r == PE_ROWS-1) begin : top_row
                    // Top PE: output goes to cluster boundary (global router)
                    assign psum_out_data [c]    = pe_psum_out_data [r][c];
                    assign psum_out_valid[c]    = pe_psum_out_valid[r][c];
                    assign pe_psum_out_re[r][c] = psum_out_re[c];
                end
                // For non-top rows: pe_psum_out_re[r][c] is assigned in the
                // r+1 iteration's upper_rows block above — no double-drive.

            end
        end
    endgenerate

    // IFmap ready: AND-reduce across all columns in each row
    // All PEs in the same row must be ready before the upstream sends a word.
    generate
        for (r = 0; r < PE_ROWS; r++) begin : gen_ifmap_ready
            assign ifmap_ready[r] = &pe_ifmap_ready[r];
        end
    endgenerate

    // u_ctrl : cluster_ctrl

    cluster_ctrl #(
        .PE_ROWS (PE_ROWS),
        .PE_COLS (PE_COLS)
    ) u_ctrl (
        .clk      (clk),
        .reset    (reset),
        .start    (start),
        .done     (done),
        .pe_start (pe_start),
        .pe_done  (pe_done)
    );

    // PE array instantiation
    // All psum routing is pre-resolved in the arrays above; the port map here
    // is fully uniform across all (r, c) — no conditionals inside.
    
    generate
        for (r = 0; r < PE_ROWS; r++) begin : gen_pe_row
            for (c = 0; c < PE_COLS; c++) begin : gen_pe_col
                PE_top #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .PSUM_WIDTH     (PSUM_WIDTH),
                    .MAXKERNELS     (MAXKERNELS),
                    .MAXCHANNELS    (MAXCHANNELS),
                    .MAXKERNELWIDTH (MAXKERNELWIDTH),
                    .MAC_LATENCY    (MAC_LATENCY),
                    .FIFO_DEPTH     (FIFO_DEPTH)
                ) u_pe (
                    .clk               (clk),
                    .reset             (reset),
                    // handshake from cluster_ctrl
                    .start             (pe_start[r][c]),
                    .done              (pe_done [r][c]),
                    // config: identical to all PEs
                    .cfg_num_filters   (cfg_num_filters),
                    .cfg_num_channels  (cfg_num_channels),
                    .cfg_ofmap_len     (cfg_ofmap_len),
                    .cfg_psum_in_valid (cfg_psum_in_valid),
                    // filter: unique per PE
                    .filter_valid      (filter_valid[r][c]),
                    .filter_data       (filter_data [r][c]),
                    .filter_ready      (filter_ready[r][c]),
                    // ifmap: broadcast within row
                    .ifmap_valid       (ifmap_valid[r]),
                    .ifmap_data        (ifmap_data [r]),
                    .ifmap_ready       (pe_ifmap_ready[r][c]),
                    // psum (routed via arrays)
                    .psum_in_valid     (pe_psum_in_valid [r][c]),
                    .psum_in_data      (pe_psum_in_data  [r][c]),
                    .psum_in_ready     (pe_psum_in_ready [r][c]),
                    .psum_out_data     (pe_psum_out_data [r][c]),
                    .psum_out_valid    (pe_psum_out_valid[r][c]),
                    .psum_out_re       (pe_psum_out_re   [r][c])
                );
            end
        end
    endgenerate

endmodule
