`timescale 1ns / 1ps
//==============================================================================
// Module      : cluster_top
// Description : Structural wrapper for a PE_ROWS x PE_COLS PE cluster
//               (Eyeriss row-stationary).
//
// CHANGES vs previous version
//   * ALL layer config (raw + derived + "last index" constants) is registered
//     ONCE here on `start`; PEs receive it as ports and hold no config state.
//     Removes per-PE multipliers and avoids Vivado merging config registers
//     and config-only logic into a single PE.
//   * New parameter MAXOFMAP (default 16), passed to every PE.
//   * PE-side ifmap valid is gated with the row's AND-ready (skew fix).
//
// Psum chain: cluster psum_in[c] -> PE[0][c] -> PE[1][c] -> ... -> psum_out[c]
// Ordering of all streams: see CHANGELOG.md (interface spec).
//==============================================================================
module cluster_top #(
    parameter PE_ROWS        = 2,
    parameter PE_COLS        = 2,
    parameter DATA_WIDTH     = 8,
    parameter PSUM_WIDTH     = 24,
    parameter MAXKERNELS     = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXKERNELWIDTH = 3,
    parameter MAC_LATENCY    = 4,   // addr issue -> psumout (1 BRAM + 3 MAC)
    parameter MAXOFMAP       = 16,
    parameter FIFO_DEPTH     = 32,

    parameter CFG_F_W = $clog2(MAXKERNELS  + 1),
    parameter CFG_C_W = $clog2(MAXCHANNELS + 1),
    parameter CFG_X_W = 8,

    // derived widths (must match PE_top / PEControlUnit)
    parameter IFMAP_DEPTH  = MAXCHANNELS * (MAXOFMAP + MAXKERNELWIDTH - 1),
    parameter KERNEL_DEPTH = MAXKERNELS  * MAXCHANNELS * MAXKERNELWIDTH,
    parameter PSUM_DEPTH   = MAXKERNELS  * MAXOFMAP,
    parameter IFMAP_AW     = $clog2(IFMAP_DEPTH),
    parameter KERNEL_AW    = $clog2(KERNEL_DEPTH),
    parameter PSUM_AW      = $clog2(PSUM_DEPTH)
)(
    input  logic clk,
    input  logic reset,

    input  logic start,
    output logic done,

    input  logic [CFG_F_W-1:0] cfg_num_filters,
    input  logic [CFG_C_W-1:0] cfg_num_channels,
    input  logic [CFG_X_W-1:0] cfg_ofmap_len,
    input  logic               cfg_psum_in_valid,

    input  logic [PE_ROWS-1:0][PE_COLS-1:0]                  filter_valid,
    input  logic [PE_ROWS-1:0][PE_COLS-1:0][DATA_WIDTH-1:0]  filter_data,
    output logic [PE_ROWS-1:0][PE_COLS-1:0]                  filter_ready,

    input  logic [PE_ROWS-1:0]                 ifmap_valid,
    input  logic [PE_ROWS-1:0][DATA_WIDTH-1:0] ifmap_data,
    output logic [PE_ROWS-1:0]                 ifmap_ready,

    input  logic [PE_COLS-1:0]                  psum_in_valid,
    input  logic [PE_COLS-1:0][PSUM_WIDTH-1:0]  psum_in_data,
    output logic [PE_COLS-1:0]                  psum_in_ready,

    output logic [PE_COLS-1:0][PSUM_WIDTH-1:0]  psum_out_data,
    output logic [PE_COLS-1:0]                   psum_out_valid,
    input  logic [PE_COLS-1:0]                   psum_out_re
);

    // ------------------------------------------------------------------
    // ALL layer config lives here: registered once on start, shared by every PE.
    // PEs hold no config registers and no config-only logic, so they are
    // structurally identical (no cross-PE merging artifacts in synthesis).
    // PEs begin using these one cycle after the latch (they start on pe_start).
    // ------------------------------------------------------------------
    localparam int MIN_F = MAC_LATENCY + 1;

    logic [CFG_F_W-1:0]   r_num_filters;
    logic                 r_use_psum_in;
    logic [KERNEL_AW-1:0] r_filter_total;   // nf * nc * S
    logic [IFMAP_AW-1:0]  r_ifmap_w;        // E + S - 1
    logic [IFMAP_AW-1:0]  r_ifmap_total;    // nc * ifmap_w
    logic [PSUM_AW-1:0]   r_psum_total;     // nf * E
    logic [CFG_F_W-1:0]   r_f_last;         // max(nf, MIN_F) - 1
    logic [CFG_C_W-1:0]   r_c_last;         // nc - 1
    logic [CFG_X_W-1:0]   r_x_last;         // E - 1
    logic [KERNEL_AW-1:0] r_nc3;            // nc * S

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_num_filters  <= '0;
            r_use_psum_in  <= 1'b0;
            r_filter_total <= '0;
            r_ifmap_w      <= '0;
            r_ifmap_total  <= '0;
            r_psum_total   <= '0;
            r_f_last       <= '0;
            r_c_last       <= '0;
            r_x_last       <= '0;
            r_nc3          <= '0;
        end else if (start) begin
            r_num_filters  <= cfg_num_filters;
            r_use_psum_in  <= cfg_psum_in_valid;
            r_filter_total <= KERNEL_AW'(cfg_num_filters) * KERNEL_AW'(cfg_num_channels)
                              * KERNEL_AW'(MAXKERNELWIDTH);
            r_ifmap_w      <= IFMAP_AW'(cfg_ofmap_len) + IFMAP_AW'(MAXKERNELWIDTH - 1);
            r_ifmap_total  <= IFMAP_AW'(cfg_num_channels)
                              * (IFMAP_AW'(cfg_ofmap_len) + IFMAP_AW'(MAXKERNELWIDTH - 1));
            r_psum_total   <= PSUM_AW'(cfg_num_filters) * PSUM_AW'(cfg_ofmap_len);
            r_f_last       <= ((cfg_num_filters < CFG_F_W'(MIN_F)) ? CFG_F_W'(MIN_F)
                                                                   : cfg_num_filters) - 1'b1;
            r_c_last       <= cfg_num_channels - 1'b1;
            r_x_last       <= cfg_ofmap_len    - 1'b1;
            r_nc3          <= KERNEL_AW'(cfg_num_channels) * KERNEL_AW'(MAXKERNELWIDTH);
        end
    end

    // ------------------------------------------------------------------
    // Internal arrays
    // ------------------------------------------------------------------
    logic [PE_ROWS-1:0][PE_COLS-1:0] pe_start;
    logic [PE_ROWS-1:0][PE_COLS-1:0] pe_done;
    logic [PE_ROWS-1:0][PE_COLS-1:0] pe_ifmap_ready;

    logic [PE_ROWS-1:0][PE_COLS-1:0][PSUM_WIDTH-1:0] pe_psum_in_data;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  pe_psum_in_valid;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  pe_psum_in_ready;

    logic [PE_ROWS-1:0][PE_COLS-1:0][PSUM_WIDTH-1:0] pe_psum_out_data;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  pe_psum_out_valid;
    logic [PE_ROWS-1:0][PE_COLS-1:0]                  pe_psum_out_re;

    genvar r, c;

    // Psum chain routing
    generate
        for (r = 0; r < PE_ROWS; r++) begin : gen_psum_route_row
            for (c = 0; c < PE_COLS; c++) begin : gen_psum_route_col

                if (r == 0) begin : bottom_row
                    assign pe_psum_in_valid[r][c] = psum_in_valid[c];
                    assign pe_psum_in_data [r][c] = psum_in_data [c];
                    assign psum_in_ready   [c]    = pe_psum_in_ready[r][c];
                end else begin : upper_rows
                    assign pe_psum_in_valid [r][c]   = pe_psum_out_valid[r-1][c];
                    assign pe_psum_in_data  [r][c]   = pe_psum_out_data [r-1][c];
                    assign pe_psum_out_re   [r-1][c] = pe_psum_in_ready [r][c];
                end

                if (r == PE_ROWS-1) begin : top_row
                    assign psum_out_data [c]    = pe_psum_out_data [r][c];
                    assign psum_out_valid[c]    = pe_psum_out_valid[r][c];
                    assign pe_psum_out_re[r][c] = psum_out_re[c];
                end

            end
        end
    endgenerate

    // IFmap ready: AND across the row (all PEs must be ready)
    generate
        for (r = 0; r < PE_ROWS; r++) begin : gen_ifmap_ready
            assign ifmap_ready[r] = &pe_ifmap_ready[r];
        end
    endgenerate

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
                    .MAXOFMAP       (MAXOFMAP),
                    .FIFO_DEPTH     (FIFO_DEPTH)
                ) u_pe (
                    .clk               (clk),
                    .reset             (reset),
                    .start             (pe_start[r][c]),
                    .done              (pe_done [r][c]),
                    .cfg_num_filters   (r_num_filters),
                    .cfg_psum_in_valid (r_use_psum_in),
                    .cfg_filter_total  (r_filter_total),
                    .cfg_ifmap_w       (r_ifmap_w),
                    .cfg_ifmap_total   (r_ifmap_total),
                    .cfg_psum_total    (r_psum_total),
                    .cfg_f_last        (r_f_last),
                    .cfg_c_last        (r_c_last),
                    .cfg_x_last        (r_x_last),
                    .cfg_nc3           (r_nc3),
                    .filter_valid      (filter_valid[r][c]),
                    .filter_data       (filter_data [r][c]),
                    .filter_ready      (filter_ready[r][c]),
                    // valid gated by the whole row's readiness
                    .ifmap_valid       (ifmap_valid[r] & (&pe_ifmap_ready[r])),
                    .ifmap_data        (ifmap_data [r]),
                    .ifmap_ready       (pe_ifmap_ready[r][c]),
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