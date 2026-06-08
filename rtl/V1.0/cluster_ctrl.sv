`timescale 1ns / 1ps
//==============================================================================
// Module      : cluster_ctrl
// Description : Cluster-level FSM for a PE_ROWS × PE_COLS PE array.
//               Sequences gang-start / wait-for-done across all PEs.
//               Psum draining is managed externally by the global router
//               via psum_out_re / psum_out_valid on cluster_top's ports.
//
// FSM States
// ─────────────────────────────────────────────────────────────────────────────
//   IDLE    : waiting for start pulse from global router
//   START   : one-cycle pe_start pulse to all PEs simultaneously (gang-start)
//   COMPUTE : waiting for all PE done signals to go high
//   DONE    : one-cycle done pulse back to global router, then back to IDLE
//==============================================================================

module cluster_ctrl #(
    parameter PE_ROWS = 2,
    parameter PE_COLS = 2
)(
    input  logic clk,
    input  logic reset,

    // Global router / noc_top handshake 
    input  logic start,   // pulse from router: begin new tile
    output logic done,    // pulse to router: compute complete, psum in FIFOs

    // PE array control 
    output logic [PE_ROWS-1:0][PE_COLS-1:0] pe_start,  // one-cycle gang pulse
    input  logic [PE_ROWS-1:0][PE_COLS-1:0] pe_done    // all must be high to advance
);

    
    // State encoding
    
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        START   = 2'b01,   // one cycle: drive pe_start high
        COMPUTE = 2'b10,   // wait for all PEs to finish
        DONE    = 2'b11    // one cycle: drive done high
    } state_t;

    state_t state, next_state;

    // All-PE-done reduction
    
    logic all_pe_done;
    assign all_pe_done = &pe_done;   // bitwise AND reduction across entire array

    
    // State register
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else       state <= next_state;
    end

    
    // Next-state logic
    
    always_comb begin
        next_state = state;   // default: hold
        case (state)
            IDLE    : if (start)       next_state = START;
            START   :                  next_state = COMPUTE;   // always advance
            COMPUTE : if (all_pe_done) next_state = DONE;
            DONE    :                  next_state = IDLE;      // always advance
            default :                  next_state = IDLE;
        endcase
    end

    // Output logic (Moore)

    // pe_start: one-cycle high only in START state => all PEs start together
    assign pe_start = (state == START)  ? '1 : '0;

    // done: one-cycle high in DONE state
    assign done     = (state == DONE);

endmodule
