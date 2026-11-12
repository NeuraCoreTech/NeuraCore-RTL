`timescale 1ns / 1ps
//==============================================================================
// Module      : cluster_ctrl
// Description : Cluster-level FSM for a PE_ROWS x PE_COLS PE array.
//               Gang-start, then wait until EVERY PE has finished.
//
// FIX: PE done is a 1-cycle pulse and PEs finish at different times (row 1
//      waits on row 0's drain via the psum chain). The old `&pe_done` could
//      never be true. Each PE's pulse is now latched (done_seen) and the
//      cluster advances once all bits are set.
//
// FSM: IDLE -> START (pe_start pulse) -> COMPUTE (wait all done) -> DONE -> IDLE
//==============================================================================
module cluster_ctrl #(
    parameter PE_ROWS = 2,
    parameter PE_COLS = 2
)(
    input  logic clk,
    input  logic reset,

    input  logic start,
    output logic done,

    output logic [PE_ROWS-1:0][PE_COLS-1:0] pe_start,
    input  logic [PE_ROWS-1:0][PE_COLS-1:0] pe_done
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        START   = 2'b01,
        COMPUTE = 2'b10,
        DONE    = 2'b11
    } state_t;

    state_t state, next_state;

    // latched per-PE done
    logic [PE_ROWS-1:0][PE_COLS-1:0] done_seen;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)                   done_seen <= '0;
        else if (state == START)     done_seen <= '0;
        else if (state == COMPUTE)   done_seen <= done_seen | pe_done;
    end

    // include same-cycle pulses so the last PE doesn't cost an extra cycle
    logic all_pe_done;
    assign all_pe_done = &(done_seen | pe_done);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else       state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE    : if (start)       next_state = START;
            START   :                  next_state = COMPUTE;
            COMPUTE : if (all_pe_done) next_state = DONE;
            DONE    :                  next_state = IDLE;
            default :                  next_state = IDLE;
        endcase
    end

    assign pe_start = (state == START) ? '1 : '0;
    assign done     = (state == DONE);

endmodule