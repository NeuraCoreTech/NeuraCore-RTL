`timescale 1ns / 1ps
//==============================================================================
// Module      : PE_top
// Description : Top-level Processing Element for the Eyeriss-style CNN
//               accelerator targeting LineCNN_OCR (all-3×3 conv, 8-bit data).
//
// Hierarchy
// ─────────────────────────────────────────────────────────────────────────────
//   PE_top
//   ├── u_ctrl        : PEControlUnit   (single FSM - all control logic)
//   ├── u_ifmap_spad  : scratchpad_ifmap  (12 × 8b  distributed RAM)
//   ├── u_kernel_spad : scratchpad_kernel (288 × 8b distributed RAM)
//   ├── u_psum_spad   : scratchpad_psum   (24 × 24b distributed RAM)
//   ├── u_mac         : mac               (3-cycle pipelined DSP)
//   └── u_psum_fifo   : fifo_block        (32 × 24b output FIFO)
//
// Data path (read-only wires, no logic added here)
// ─────────────────────────────────────────────────────────────────────────────
//   ifmap_spad.data_out  ──► mac.ifmap
//   kernel_spad.data_out ──► mac.filter
//   psum_spad.data_out   ──► mac.psumin   AND  fifo_block.data_in (drain)
//   mac.psumout          ──► PEControlUnit.mac_psumout (write-back tag)
//
// External ports exposed to the NoC / GLB / Local Network
// ─────────────────────────────────────────────────────────────────────────────
//   Filter load  : filter_valid / filter_data / filter_ready
//   IFmap load   : ifmap_valid  / ifmap_data  / ifmap_ready
//   Input psum   : psum_in_valid / psum_in_data / psum_in_ready  (from LN below)
//   Output psum  : psum_out_valid / psum_out_data / psum_out_re  (to   LN above / GON)
//   Config       : cfg_num_filters, cfg_num_channels, cfg_ofmap_len, cfg_psum_in_valid
//   Handshake    : start, done
//==============================================================================

module PE_top #(
    parameter DATA_WIDTH     = 8,
    parameter PSUM_WIDTH     = 24,
    parameter MAXKERNELS     = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXKERNELWIDTH = 3,
    parameter MAC_LATENCY    = 3,

    // Scratchpad depths - must match sub-module defaults
    parameter IFMAP_DEPTH  = MAXCHANNELS * MAXKERNELWIDTH,               // 12
    parameter KERNEL_DEPTH = MAXKERNELS  * MAXCHANNELS * MAXKERNELWIDTH, // 288
    parameter PSUM_DEPTH   = MAXKERNELS,                                 // 24

    // Address widths
    parameter IFMAP_AW  = $clog2(IFMAP_DEPTH),   // 4
    parameter KERNEL_AW = $clog2(KERNEL_DEPTH),  // 9
    parameter PSUM_AW   = $clog2(PSUM_DEPTH),    // 5

    // Output FIFO depth - must be >= MAXKERNELS so a full drain never stalls
    parameter FIFO_DEPTH = 32,

    // Config field widths (match PEControlUnit)
    parameter CFG_F_W = $clog2(MAXKERNELS  + 1), // 5
    parameter CFG_C_W = $clog2(MAXCHANNELS + 1), // 3
    parameter CFG_X_W = 8
)(
    input  logic clk,
    input  logic reset,

    // ── Tile handshake ────────────────────────────────────────────────────
    input  logic start,
    output logic done,

    // ── Configuration (stable from start until done) ──────────────────────
    input  logic [CFG_F_W-1:0] cfg_num_filters,
    input  logic [CFG_C_W-1:0] cfg_num_channels,
    input  logic [CFG_X_W-1:0] cfg_ofmap_len,
    input  logic               cfg_psum_in_valid,  // 1 = pre-load psums from LN

    // ── Filter load - from NoC GIN ────────────────────────────────────────
    input  logic                  filter_valid,
    input  logic [DATA_WIDTH-1:0] filter_data,
    output logic                  filter_ready,

    // ── IFmap load - from NoC GIN ─────────────────────────────────────────
    input  logic                  ifmap_valid,
    input  logic [DATA_WIDTH-1:0] ifmap_data,
    output logic                  ifmap_ready,

    // ── Input psum - from Local Network (PE below in same column) ─────────
    input  logic                   psum_in_valid,
    input  logic [PSUM_WIDTH-1:0]  psum_in_data,
    output logic                   psum_in_ready,

    // ── Output psum - to Local Network (PE above) or NoC GON ─────────────
    // fifo_block read interface exposed directly so the NoC can back-pressure
    output logic [PSUM_WIDTH-1:0]  psum_out_data,
    output logic                   psum_out_valid,  // = ~empty_flag
    input  logic                   psum_out_re      // read enable from NoC
);

    //=========================================================================
    // Internal wires
    //=========================================================================

    // ── Control → ifmap scratchpad ──────────────────────────────────────────
    logic                  ctrl_ifmap_we;
    logic [IFMAP_AW-1:0]  ctrl_ifmap_addr_wr;
    logic [DATA_WIDTH-1:0] ctrl_ifmap_data_in;
    logic [IFMAP_AW-1:0]  ctrl_ifmap_addr_rd;
    logic [DATA_WIDTH-1:0] ifmap_spad_data_out;

    // ── Control → kernel scratchpad ─────────────────────────────────────────
    logic                   ctrl_kernel_we;
    logic [KERNEL_AW-1:0]  ctrl_kernel_addr_wr;
    logic [DATA_WIDTH-1:0]  ctrl_kernel_data_in;
    logic [KERNEL_AW-1:0]  ctrl_kernel_addr_rd;
    logic [DATA_WIDTH-1:0]  kernel_spad_data_out;

    // ── Control → psum scratchpad ───────────────────────────────────────────
    logic                   ctrl_psum_we;
    logic [PSUM_AW-1:0]    ctrl_psum_addr_wr;
    logic [PSUM_WIDTH-1:0]  ctrl_psum_data_in;
    logic [PSUM_AW-1:0]    ctrl_psum_addr_rd;
    logic [PSUM_WIDTH-1:0]  psum_spad_data_out;

    // ── Control → MAC ───────────────────────────────────────────────────────
    logic                   ctrl_mac_ce;
    logic                   ctrl_mac_sclr;
    logic [PSUM_WIDTH-1:0]  mac_psumout;

    // ── Control → output FIFO ───────────────────────────────────────────────
    logic                   ctrl_fifo_we;
    logic [PSUM_WIDTH-1:0]  ctrl_fifo_data_in;
    logic                   fifo_full;

    //=========================================================================
    // u_ctrl : PEControlUnit
    //=========================================================================
    PEControlUnit #(
        .DATA_WIDTH     (DATA_WIDTH),
        .PSUM_WIDTH     (PSUM_WIDTH),
        .MAXKERNELS     (MAXKERNELS),
        .MAXCHANNELS    (MAXCHANNELS),
        .MAXKERNELWIDTH (MAXKERNELWIDTH),
        .MAC_LATENCY    (MAC_LATENCY)
    ) u_ctrl (
        .clk                (clk),
        .reset              (reset),

        // tile handshake
        .start              (start),
        .done               (done),

        // configuration
        .cfg_num_filters    (cfg_num_filters),
        .cfg_num_channels   (cfg_num_channels),
        .cfg_ofmap_len      (cfg_ofmap_len),
        .cfg_psum_in_valid  (cfg_psum_in_valid),

        // filter load
        .filter_valid       (filter_valid),
        .filter_data        (filter_data),
        .filter_ready       (filter_ready),

        // ifmap load
        .ifmap_valid        (ifmap_valid),
        .ifmap_data         (ifmap_data),
        .ifmap_ready        (ifmap_ready),

        // input psum (LN)
        .psum_in_valid      (psum_in_valid),
        .psum_in_data       (psum_in_data),
        .psum_in_ready      (psum_in_ready),

        // output fifo
        .fifo_we            (ctrl_fifo_we),
        .fifo_data_in       (ctrl_fifo_data_in),
        .fifo_full          (fifo_full),

        // ifmap scratchpad
        .ifmap_we           (ctrl_ifmap_we),
        .ifmap_addr_wr      (ctrl_ifmap_addr_wr),
        .ifmap_data_in      (ctrl_ifmap_data_in),
        .ifmap_addr_rd      (ctrl_ifmap_addr_rd),
        .ifmap_data_out     (ifmap_spad_data_out),

        // kernel scratchpad
        .kernel_we          (ctrl_kernel_we),
        .kernel_addr_wr     (ctrl_kernel_addr_wr),
        .kernel_data_in     (ctrl_kernel_data_in),
        .kernel_addr_rd     (ctrl_kernel_addr_rd),
        .kernel_data_out    (kernel_spad_data_out),

        // psum scratchpad
        .psum_we            (ctrl_psum_we),
        .psum_addr_wr       (ctrl_psum_addr_wr),
        .psum_data_in       (ctrl_psum_data_in),
        .psum_addr_rd       (ctrl_psum_addr_rd),
        .psum_data_out      (psum_spad_data_out),

        // MAC
        .mac_ce             (ctrl_mac_ce),
        .mac_sclr           (ctrl_mac_sclr),
        .mac_psumout        (mac_psumout)
    );

    //=========================================================================
    // u_ifmap_spad : scratchpad_ifmap
    //=========================================================================
    scratchpad_ifmap #(
        .MAXCHANNELS    (MAXCHANNELS),
        .MAXKERNELWIDTH (MAXKERNELWIDTH),
        .DATA_WIDTH     (DATA_WIDTH)
    ) u_ifmap_spad (
        .clk      (clk),
        .data_in  (ctrl_ifmap_data_in),
        .we       (ctrl_ifmap_we),
        .addr_wr  (ctrl_ifmap_addr_wr),
        .addr_rd  (ctrl_ifmap_addr_rd),
        .data_out (ifmap_spad_data_out)
    );

    //=========================================================================
    // u_kernel_spad : scratchpad_kernel
    //=========================================================================
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

    //=========================================================================
    // u_psum_spad : scratchpad_psum
    //=========================================================================
    scratchpad_psum #(
        .MAXOUTPUTS (MAXKERNELS),
        .DATA_WIDTH (PSUM_WIDTH)
    ) u_psum_spad (
        .clk      (clk),
        .data_in  (ctrl_psum_data_in),
        .we       (ctrl_psum_we),
        .addr_wr  (ctrl_psum_addr_wr),
        .addr_rd  (ctrl_psum_addr_rd),
        .data_out (psum_spad_data_out)
    );

    //=========================================================================
    // u_mac : mac
    // Data path wires - no logic, pure connectivity:
    //   ifmap_spad.data_out  → mac.ifmap
    //   kernel_spad.data_out → mac.filter
    //   psum_spad.data_out   → mac.psumin
    //=========================================================================
    mac #(
        .DATA_WIDTH (DATA_WIDTH),
        .MULT_WIDTH (PSUM_WIDTH)
    ) u_mac (
        .clk     (clk),
        .ce      (ctrl_mac_ce),
        .sclr    (ctrl_mac_sclr),
        .ifmap   (ifmap_spad_data_out),    // async read from ifmap spad
        .filter  (kernel_spad_data_out),   // async read from kernel spad
        .psumin  (psum_spad_data_out),     // async read from psum spad
        .psumout (mac_psumout)             // 3-cycle delayed result → ctrl
    );

    //=========================================================================
    // u_psum_fifo : fifo_block
    logic psum_out_valid_n;   // active-low empty; inverted to psum_out_valid
    // Holds completed psums until the NoC GON or LN reads them out.
    // DEPTH=32 ensures a full tile (up to 24 psums) always fits without stall.
    //=========================================================================
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
        .empty_flag (psum_out_valid_n),   // active-low; inverted below
        .full_flag  (fifo_full)
    );

    // psum_out_valid is active-high: data is available when FIFO is not empty
    assign psum_out_valid = ~psum_out_valid_n;

endmodule
