`timescale 1ns / 1ps
//==============================================================================
// Module      : PE_top
// Description : Top-level Processing Element (Eyeriss-style, LineCNN_OCR).
//   u_ctrl : PEControlUnit   u_ifmap_spad : scratchpad_ifmap
//   u_kernel_spad : scratchpad_kernel   u_psum_spad : scratchpad_psum
//   u_mac : mac   u_psum_fifo : fifo_block
//
// CHANGE (E>1 support): ifmap spad now holds a full ifmap row per channel
// (MAXCHANNELS x (MAXOFMAP+2)) and psum spad holds MAXKERNELS x MAXOFMAP
// slots. New parameter MAXOFMAP (default 16). Port list is unchanged.
//==============================================================================
module PE_top #(
    parameter DATA_WIDTH     = 8,
    parameter PSUM_WIDTH     = 24,
    parameter MAXKERNELS     = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXKERNELWIDTH = 3,
    parameter MAC_LATENCY    = 4,   // addr issue -> psumout (1 BRAM + 3 MAC)
    parameter MAXOFMAP       = 16,

    parameter IFMAP_DEPTH  = MAXCHANNELS * (MAXOFMAP + MAXKERNELWIDTH - 1),
    parameter KERNEL_DEPTH = MAXKERNELS  * MAXCHANNELS * MAXKERNELWIDTH,
    parameter PSUM_DEPTH   = MAXKERNELS  * MAXOFMAP,

    parameter IFMAP_AW  = $clog2(IFMAP_DEPTH),
    parameter KERNEL_AW = $clog2(KERNEL_DEPTH),
    parameter PSUM_AW   = $clog2(PSUM_DEPTH),

    // Output FIFO: backpressure-safe at any depth (drain stalls when full)
    parameter FIFO_DEPTH = 32,

    parameter CFG_F_W = $clog2(MAXKERNELS  + 1),
    parameter CFG_C_W = $clog2(MAXCHANNELS + 1),
    parameter CFG_X_W = 8
)(
    input  logic clk,
    input  logic reset,

    input  logic start,
    output logic done,

    input  logic [CFG_F_W-1:0] cfg_num_filters,
    input  logic               cfg_psum_in_valid,

    // derived config from cluster_top (computed once per cluster)
    input  logic [KERNEL_AW-1:0] cfg_filter_total,
    input  logic [IFMAP_AW-1:0]  cfg_ifmap_w,
    input  logic [IFMAP_AW-1:0]  cfg_ifmap_total,
    input  logic [PSUM_AW-1:0]   cfg_psum_total,
    input  logic [CFG_F_W-1:0]   cfg_f_last,
    input  logic [CFG_C_W-1:0]   cfg_c_last,
    input  logic [CFG_X_W-1:0]   cfg_x_last,
    input  logic [KERNEL_AW-1:0] cfg_nc3,

    input  logic                  filter_valid,
    input  logic [DATA_WIDTH-1:0] filter_data,
    output logic                  filter_ready,

    input  logic                  ifmap_valid,
    input  logic [DATA_WIDTH-1:0] ifmap_data,
    output logic                  ifmap_ready,

    input  logic                   psum_in_valid,
    input  logic [PSUM_WIDTH-1:0]  psum_in_data,
    output logic                   psum_in_ready,

    output logic [PSUM_WIDTH-1:0]  psum_out_data,
    output logic                   psum_out_valid,
    input  logic                   psum_out_re
);

    logic                  ctrl_ifmap_we;
    logic [IFMAP_AW-1:0]   ctrl_ifmap_addr_wr;
    logic [DATA_WIDTH-1:0] ctrl_ifmap_data_in;
    logic [IFMAP_AW-1:0]   ctrl_ifmap_addr_rd;
    logic [DATA_WIDTH-1:0] ifmap_spad_data_out;

    logic                  ctrl_kernel_we;
    logic [KERNEL_AW-1:0]  ctrl_kernel_addr_wr;
    logic [DATA_WIDTH-1:0] ctrl_kernel_data_in;
    logic [KERNEL_AW-1:0]  ctrl_kernel_addr_rd;
    logic [DATA_WIDTH-1:0] kernel_spad_data_out;

    logic                  ctrl_psum_we;
    logic [PSUM_AW-1:0]    ctrl_psum_addr_wr;
    logic [PSUM_WIDTH-1:0] ctrl_psum_data_in;
    logic [PSUM_AW-1:0]    ctrl_psum_addr_rd;
    logic                  ctrl_psum_rd_en;
    logic [DATA_WIDTH-1:0] ifmap_q;   // ifmap spad output delayed 1 cycle (BRAM alignment)
    logic [PSUM_WIDTH-1:0] psum_spad_data_out;

    logic                  ctrl_mac_ce;
    logic                  ctrl_mac_sclr;
    logic [PSUM_WIDTH-1:0] mac_psumout;

    logic                  ctrl_fifo_we;
    logic [PSUM_WIDTH-1:0] ctrl_fifo_data_in;
    logic                  fifo_full;
    logic                  psum_out_valid_n;

    PEControlUnit #(
        .DATA_WIDTH     (DATA_WIDTH),
        .PSUM_WIDTH     (PSUM_WIDTH),
        .MAXKERNELS     (MAXKERNELS),
        .MAXCHANNELS    (MAXCHANNELS),
        .MAXKERNELWIDTH (MAXKERNELWIDTH),
        .MAC_LATENCY    (MAC_LATENCY),
        .MAXOFMAP       (MAXOFMAP)
    ) u_ctrl (
        .clk               (clk),
        .reset             (reset),
        .start             (start),
        .done              (done),
        .cfg_num_filters   (cfg_num_filters),
        .cfg_psum_in_valid (cfg_psum_in_valid),
        .filter_total      (cfg_filter_total),
        .ifmap_w           (cfg_ifmap_w),
        .ifmap_total       (cfg_ifmap_total),
        .psum_total        (cfg_psum_total),
        .f_last            (cfg_f_last),
        .c_last            (cfg_c_last),
        .x_last            (cfg_x_last),
        .nc3               (cfg_nc3),
        .filter_valid      (filter_valid),
        .filter_data       (filter_data),
        .filter_ready      (filter_ready),
        .ifmap_valid       (ifmap_valid),
        .ifmap_data        (ifmap_data),
        .ifmap_fresh       (1'b0),
        .ifmap_ready       (ifmap_ready),
        .psum_in_valid     (psum_in_valid),
        .psum_in_data      (psum_in_data),
        .psum_in_ready     (psum_in_ready),
        .fifo_we           (ctrl_fifo_we),
        .fifo_data_in      (ctrl_fifo_data_in),
        .fifo_full         (fifo_full),
        .ifmap_we          (ctrl_ifmap_we),
        .ifmap_addr_wr     (ctrl_ifmap_addr_wr),
        .ifmap_data_in     (ctrl_ifmap_data_in),
        .ifmap_addr_rd     (ctrl_ifmap_addr_rd),
        .ifmap_data_out    (ifmap_spad_data_out),
        .kernel_we         (ctrl_kernel_we),
        .kernel_addr_wr    (ctrl_kernel_addr_wr),
        .kernel_data_in    (ctrl_kernel_data_in),
        .kernel_addr_rd    (ctrl_kernel_addr_rd),
        .kernel_data_out   (kernel_spad_data_out),
        .psum_we           (ctrl_psum_we),
        .psum_addr_wr      (ctrl_psum_addr_wr),
        .psum_data_in      (ctrl_psum_data_in),
        .psum_addr_rd      (ctrl_psum_addr_rd),
        .psum_rd_en        (ctrl_psum_rd_en),
        .psum_data_out     (psum_spad_data_out),
        .mac_ce            (ctrl_mac_ce),
        .mac_sclr          (ctrl_mac_sclr),
        .mac_psumout       (mac_psumout)
    );

    // DEPTH overridden so the spad matches the controller's address width
    scratchpad_ifmap #(
        .MAXCHANNELS    (MAXCHANNELS),
        .MAXKERNELWIDTH (MAXKERNELWIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .DEPTH          (IFMAP_DEPTH)
    ) u_ifmap_spad (
        .clk      (clk),
        .data_in  (ctrl_ifmap_data_in),
        .we       (ctrl_ifmap_we),
        .addr_wr  (ctrl_ifmap_addr_wr),
        .addr_rd  (ctrl_ifmap_addr_rd),
        .data_out (ifmap_spad_data_out)
    );

    scratchpad_kernel #(
        .MAXKERNELS     (MAXKERNELS),
        .MAXCHANNELS    (MAXCHANNELS),
        .MAXKERNELWIDTH (MAXKERNELWIDTH),
        .DATA_WIDTH     (DATA_WIDTH)
    ) u_kernel_spad (
        .clk      (clk),
        .data_in  (ctrl_kernel_data_in),
        .we       (ctrl_kernel_we),
        .addr_wr  (ctrl_kernel_addr_wr),
        .addr_rd  (ctrl_kernel_addr_rd),
        .data_out (kernel_spad_data_out)
    );

    // MAXOUTPUTS = total psum slots (MAXKERNELS x MAXOFMAP)
    scratchpad_psum #(
        .MAXOUTPUTS (PSUM_DEPTH),
        .DATA_WIDTH (PSUM_WIDTH)
    ) u_psum_spad (
        .clk      (clk),
        .data_in  (ctrl_psum_data_in),
        .we       (ctrl_psum_we),
        .addr_wr  (ctrl_psum_addr_wr),
        .addr_rd  (ctrl_psum_addr_rd),
        .rd_en    (ctrl_psum_rd_en),
        .data_out (psum_spad_data_out)
    );

    // ifmap spad is async LUTRAM; kernel/psum are sync BRAM (1-cycle read).
    // Delay ifmap by one register so all MAC operands arrive together.
    always_ff @(posedge clk) ifmap_q <= ifmap_spad_data_out;

    mac #(
        .DATA_WIDTH (DATA_WIDTH),
        .MULT_WIDTH (PSUM_WIDTH)
    ) u_mac (
        .clk     (clk),
        .ce      (ctrl_mac_ce),
        .sclr    (ctrl_mac_sclr),
        .ifmap   (ifmap_q),
        .filter  (kernel_spad_data_out),
        .psumin  (psum_spad_data_out),
        .psumout (mac_psumout)
    );

    fifo_block #(
        .DATA_WIDTH (PSUM_WIDTH),
        .DEPTH      (FIFO_DEPTH)
    ) u_psum_fifo (
        .clk        (clk),
        .reset      (reset),
        .we         (ctrl_fifo_we),
        .re         (psum_out_re),
        .data_in    (ctrl_fifo_data_in),
        .data_out   (psum_out_data),
        .empty_flag (psum_out_valid_n),
        .full_flag  (fifo_full)
    );

    assign psum_out_valid = ~psum_out_valid_n;

endmodule