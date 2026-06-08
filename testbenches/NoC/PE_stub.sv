`timescale 1ns / 1ps
//==============================================================================
// Module      : PE_top  (BEHAVIORAL STUB — SIMULATION ONLY)
// Description : Replaces the real PE_top for cluster_top connectivity testing.
//               Add this file to Vivado simulation sources ONLY — do NOT add
//               to synthesis sources. The real PE_top.sv handles synthesis.
//
// Behavior
// ─────────────────────────────────────────────────────────────────────────────
//   • Accepts filter/ifmap/psum_in freely (ready = 1 always).
//   • Captures last received value on each input port for TB inspection.
//   • On pe_start: counts DONE_DELAY cycles, then pulses done for 1 cycle.
//   • psum_out_data = PSUM_OUT_VAL (constant), psum_out_valid = 1 always.
//     This lets the testbench verify psum chain wiring by value.
//==============================================================================

module PE_top #(
    // ── Match real PE_top parameters exactly so cluster_top port maps work ──
    parameter DATA_WIDTH     = 8,
    parameter PSUM_WIDTH     = 24,
    parameter MAXKERNELS     = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXKERNELWIDTH = 3,
    parameter MAC_LATENCY    = 3,
    parameter IFMAP_DEPTH    = MAXCHANNELS * MAXKERNELWIDTH,
    parameter KERNEL_DEPTH   = MAXKERNELS  * MAXCHANNELS * MAXKERNELWIDTH,
    parameter PSUM_DEPTH     = MAXKERNELS,
    parameter IFMAP_AW       = $clog2(IFMAP_DEPTH),
    parameter KERNEL_AW      = $clog2(KERNEL_DEPTH),
    parameter PSUM_AW        = $clog2(PSUM_DEPTH),
    parameter FIFO_DEPTH     = 32,
    parameter CFG_F_W        = $clog2(MAXKERNELS  + 1),
    parameter CFG_C_W        = $clog2(MAXCHANNELS + 1),
    parameter CFG_X_W        = 8,
    // ── Stub-specific ────────────────────────────────────────────────────────
    parameter integer         DONE_DELAY   = 20,           // cycles start→done
    parameter [23:0]          PSUM_OUT_VAL = 24'hCAFE00   // fixed psum output
)(
    input  logic clk,
    input  logic reset,
    input  logic start,
    output logic done,

    input  logic [CFG_F_W-1:0] cfg_num_filters,
    input  logic [CFG_C_W-1:0] cfg_num_channels,
    input  logic [CFG_X_W-1:0] cfg_ofmap_len,
    input  logic               cfg_psum_in_valid,

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

    //=========================================================================
    // Captured inputs — readable hierarchically from testbench
    //=========================================================================
    logic [DATA_WIDTH-1:0] captured_filter_data;
    logic [DATA_WIDTH-1:0] captured_ifmap_data;
    logic [PSUM_WIDTH-1:0] captured_psum_in_data;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            captured_filter_data  <= '0;
            captured_ifmap_data   <= '0;
            captured_psum_in_data <= '0;
        end else begin
            if (filter_valid)    captured_filter_data  <= filter_data;
            if (ifmap_valid)     captured_ifmap_data   <= ifmap_data;
            if (psum_in_valid)   captured_psum_in_data <= psum_in_data;
        end
    end

    //=========================================================================
    // Always ready — accept any incoming data immediately
    //=========================================================================
    assign filter_ready  = 1'b1;
    assign ifmap_ready   = 1'b1;
    assign psum_in_ready = 1'b1;

    //=========================================================================
    // Done counter — DONE_DELAY cycles after start, pulse done for 1 cycle
    //=========================================================================
    logic [7:0] cnt;    // 8-bit: supports DONE_DELAY up to 255
    logic       running;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt     <= 8'h0;
            running <= 1'b0;
        end else begin
            if (start && !running) begin
                // Fresh start: begin counting
                running <= 1'b1;
                cnt     <= 8'h0;
            end else if (running) begin
                if (cnt == 8'(DONE_DELAY - 1)) begin
                    // Last count: stop, done will fire this cycle
                    running <= 1'b0;
                end else begin
                    cnt <= cnt + 8'h1;
                end
            end
        end
    end

    // done: combinational, 1 cycle wide
    assign done = running && (cnt == 8'(DONE_DELAY - 1));

    //=========================================================================
    // Psum output — constant, always valid
    // Allows TB to verify psum chain wiring by checking the known value
    // arrives at the correct downstream PE's psum_in.
    //=========================================================================
    assign psum_out_data  = PSUM_WIDTH'(PSUM_OUT_VAL);
    assign psum_out_valid = 1'b1;

endmodule
