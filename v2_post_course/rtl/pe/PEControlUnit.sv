`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: PEControlUnit
// Project Name: 
// Target Devices: xc7a100t / xc7z020
// Tool Versions: 
// Description: Single FSM controlling the Eyeriss-style PE (row-stationary,
//              3x3 conv, 8-bit data, 24-bit accumulation).
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Running address registers replace x*nf, f*nc3, c*W multipliers
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//==============================================================================
// Module      : PEControlUnit
//
// FIX (psum RAW hazard):
//   Loop order x->c->k->f (f innermost). Two visits to the same psum slot are
//   f_eff cycles apart, f_eff = max(num_filters, MAC_LATENCY+1). When
//   num_filters < MAC_LATENCY+1 the f loop is padded with bubble cycles
//   (cnt_f >= num_filters) that issue no write-back, so same-slot spacing is
//   always >= MAC_LATENCY+1.
//
// FEATURE (E > 1, sliding window, stride 1, no padding):
//   ifmap_addr_rd = c*W + x + k, psum slot = x*nf + f, W = E + 2.
//   Stream/drain order is x-major: slot 0..E*nf-1. E <= MAXOFMAP.
//
// FEATURE (BRAM scratchpads): kernel and psum spads are sync-read BRAM
//   (1-cycle read). ifmap spad stays async LUTRAM; PE_top delays its output by
//   one register. MAC_LATENCY = 4 (1 BRAM + 3 IP). Drain is pipelined with
//   hold-on-full.
//
// CHANGE (timing): the three address multipliers are replaced by running
//   address registers that add a stride as the loops advance:
//     psum_ptr  = x*nf + f          (psum_xbase = x*nf)
//     k_addr    = f*nc3 + c*3 + k   (k_ck = c*3 + k)
//     i_addr    = c*W + x + k       (i_cbase = c*W)
//   Behavior is identical; bubbles still read psum slot 0.
//
// STATE MACHINE
//  IDLE -> FILTER_LOAD -> IFMAP_LOAD -> (PSUM_LOAD | PSUM_CLEAR) ->
//  COMPUTE -> PSUM_DRAIN -> PE_DONE -> IDLE
//==============================================================================

module PEControlUnit #(
    parameter DATA_WIDTH     = 8,
    parameter PSUM_WIDTH     = 24,
    parameter MAXKERNELS     = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXKERNELWIDTH = 3,
    parameter MAC_LATENCY    = 4,      // addr issue -> psumout: 1 (BRAM read) + 3 (MAC IP)
    parameter MAXOFMAP       = 16,      // max E (output columns per filter)

    parameter IFMAP_DEPTH  = MAXCHANNELS * (MAXOFMAP + MAXKERNELWIDTH - 1),
    parameter KERNEL_DEPTH = MAXKERNELS  * MAXCHANNELS * MAXKERNELWIDTH,
    parameter PSUM_DEPTH   = MAXKERNELS  * MAXOFMAP,

    parameter IFMAP_AW  = $clog2(IFMAP_DEPTH),
    parameter KERNEL_AW = $clog2(KERNEL_DEPTH),
    parameter PSUM_AW   = $clog2(PSUM_DEPTH),

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

    // Derived config, computed once per cluster (stable from start until done)
    input  logic [KERNEL_AW-1:0] filter_total,  // nf * nc * S
    input  logic [IFMAP_AW-1:0]  ifmap_w,       // E + S - 1  (ifmap row width/channel)
    input  logic [IFMAP_AW-1:0]  ifmap_total,   // nc * ifmap_w
    input  logic [PSUM_AW-1:0]   psum_total,    // nf * E
    input  logic [CFG_F_W-1:0]   f_last,        // max(nf, MAC_LATENCY+1) - 1
    input  logic [CFG_C_W-1:0]   c_last,        // nc - 1
    input  logic [CFG_X_W-1:0]   x_last,        // E - 1
    input  logic [KERNEL_AW-1:0] nc3,           // nc * S  (kernel stride per filter)

    input  logic                  filter_valid,
    input  logic [DATA_WIDTH-1:0] filter_data,
    output logic                  filter_ready,

    input  logic                  ifmap_valid,
    input  logic [DATA_WIDTH-1:0] ifmap_data,
    input  logic                  ifmap_fresh,   // unused (not connected in PE_top)
    output logic                  ifmap_ready,

    input  logic                   psum_in_valid,
    input  logic [PSUM_WIDTH-1:0]  psum_in_data,
    output logic                   psum_in_ready,

    output logic                   fifo_we,
    output logic [PSUM_WIDTH-1:0]  fifo_data_in,
    input  logic                   fifo_full,

    output logic                  ifmap_we,
    output logic [IFMAP_AW-1:0]   ifmap_addr_wr,
    output logic [DATA_WIDTH-1:0] ifmap_data_in,
    output logic [IFMAP_AW-1:0]   ifmap_addr_rd,
    input  logic [DATA_WIDTH-1:0] ifmap_data_out,

    output logic                   kernel_we,
    output logic [KERNEL_AW-1:0]   kernel_addr_wr,
    output logic [DATA_WIDTH-1:0]  kernel_data_in,
    output logic [KERNEL_AW-1:0]   kernel_addr_rd,
    input  logic [DATA_WIDTH-1:0]  kernel_data_out,

    output logic                   psum_we,
    output logic [PSUM_AW-1:0]     psum_addr_wr,
    output logic [PSUM_WIDTH-1:0]  psum_data_in,
    output logic [PSUM_AW-1:0]     psum_addr_rd,
    output logic                   psum_rd_en,
    input  logic [PSUM_WIDTH-1:0]  psum_data_out,

    output logic mac_ce,
    output logic mac_sclr,
    input  logic [PSUM_WIDTH-1:0] mac_psumout
);

    //==========================================================================
    // STATE
    //==========================================================================
    typedef enum logic [2:0] {
        IDLE        = 3'd0,
        FILTER_LOAD = 3'd1,
        IFMAP_LOAD  = 3'd2,
        PSUM_LOAD   = 3'd3,
        COMPUTE     = 3'd4,
        PSUM_DRAIN  = 3'd5,
        PE_DONE     = 3'd6,
        PSUM_CLEAR  = 3'd7
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge reset)
        if (reset) state <= IDLE;
        else       state <= next_state;

    //==========================================================================
    // CONFIG: no registers here (held in cluster_top, stable from start to done)
    //==========================================================================
    logic [CFG_F_W-1:0] num_filters;
    logic               use_psum_in;
    assign num_filters = cfg_num_filters;
    assign use_psum_in = cfg_psum_in_valid;

    //==========================================================================
    // LOAD / DRAIN COUNTERS
    //==========================================================================
    logic [KERNEL_AW-1:0] filter_cnt;
    logic [IFMAP_AW-1:0]  ifmap_cnt;
    logic [PSUM_AW-1:0]   psum_cnt;

    logic filt_fire, imap_fire, psin_fire;
    assign filt_fire  = filter_valid  & filter_ready;
    assign imap_fire  = ifmap_valid   & ifmap_ready;
    assign psin_fire  = psum_in_valid & psum_in_ready;

    //--------------------------------------------------------------------------
    // PIPELINED DRAIN  (psum spad has 1-cycle read latency)
    //   issue : present read address dr_iss_cnt, spad output valid next cycle
    //   dv    : spad output holds a word not yet written to the FIFO
    //   write : fifo_we_int = dv & ~fifo_full
    //   hold  : if dv && fifo_full, no new issue; psum spad rd_en low keeps output
    //--------------------------------------------------------------------------
    logic [PSUM_AW:0] dr_iss_cnt, dr_wr_cnt;
    logic             dv;
    logic             dr_more, dr_issue, fifo_we_int;

    assign dr_more     = (dr_iss_cnt != {1'b0, psum_total});
    assign fifo_we_int = dv & ~fifo_full;
    assign dr_issue    = (state == PSUM_DRAIN) & dr_more & (~dv | ~fifo_full);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            dr_iss_cnt <= '0;
            dr_wr_cnt  <= '0;
            dv         <= 1'b0;
        end else if (state != PSUM_DRAIN) begin
            dr_iss_cnt <= '0;
            dr_wr_cnt  <= '0;
            dv         <= 1'b0;
        end else begin
            if (dr_issue)    dr_iss_cnt <= dr_iss_cnt + 1'b1;
            if (fifo_we_int) dr_wr_cnt  <= dr_wr_cnt  + 1'b1;
            dv <= dr_issue | (dv & fifo_full);
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            filter_cnt <= '0;
            ifmap_cnt  <= '0;
            psum_cnt   <= '0;
        end else begin
            case (state)
                IDLE: begin
                    filter_cnt <= '0;
                    ifmap_cnt  <= '0;
                    psum_cnt   <= '0;
                end
                FILTER_LOAD: begin
                    if (next_state != FILTER_LOAD) filter_cnt <= '0;
                    else if (filt_fire)            filter_cnt <= filter_cnt + 1'b1;
                end
                IFMAP_LOAD: begin
                    if (next_state != IFMAP_LOAD)  ifmap_cnt <= '0;
                    else if (imap_fire)            ifmap_cnt <= ifmap_cnt + 1'b1;
                end
                PSUM_LOAD: begin
                    if (next_state == COMPUTE) psum_cnt <= '0;
                    else if (psin_fire)        psum_cnt <= psum_cnt + 1'b1;
                end
                COMPUTE: psum_cnt <= '0;
                PSUM_CLEAR: begin
                    if (next_state == COMPUTE) psum_cnt <= '0;
                    else                       psum_cnt <= psum_cnt + 1'b1;
                end
                PSUM_DRAIN: psum_cnt <= '0;   // drain uses dr_* counters
                default: ;
            endcase
        end
    end

    //==========================================================================
    // COMPUTE LOOP COUNTERS   x -> c -> k -> f   (f innermost)
    //==========================================================================
    localparam int MIN_F = MAC_LATENCY + 1;   // min same-slot revisit distance

    logic [CFG_X_W-1:0]                cnt_x;
    logic [CFG_F_W-1:0]                cnt_f;
    logic [CFG_C_W-1:0]                cnt_c;
    logic [$clog2(MAXKERNELWIDTH)-1:0] cnt_k;

    logic last_k, last_c, last_f, last_x, last_mac_in;
    assign last_f      = (cnt_f == f_last);
    assign last_k      = (cnt_k == ($clog2(MAXKERNELWIDTH))'(MAXKERNELWIDTH - 1));
    assign last_c      = (cnt_c == c_last);
    assign last_x      = (cnt_x == x_last);
    assign last_mac_in = last_f & last_k & last_c & last_x;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_x <= '0; cnt_f <= '0; cnt_c <= '0; cnt_k <= '0;
        end else if (state == COMPUTE) begin
            if (last_f) begin
                cnt_f <= '0;
                if (last_k) begin
                    cnt_k <= '0;
                    if (last_c) begin
                        cnt_c <= '0;
                        if (!last_x) cnt_x <= cnt_x + 1'b1;
                    end else cnt_c <= cnt_c + 1'b1;
                end else cnt_k <= cnt_k + 1'b1;
            end else cnt_f <= cnt_f + 1'b1;
        end else begin
            cnt_x <= '0; cnt_f <= '0; cnt_c <= '0; cnt_k <= '0;
        end
    end

    //==========================================================================
    // RUNNING ADDRESS REGISTERS (replace the variable multipliers)
    //   f_real_r   : registered (cnt_f < num_filters)
    //   psum_xbase : x*nf             psum_ptr : x*nf + f
    //   k_ck       : c*3 + k          k_addr   : f*nc3 + c*3 + k
    //   i_cbase    : c*W              i_addr   : c*W + x + k
    // Outside COMPUTE they sit at their loop-start values (f=c=k=x=0).
    //==========================================================================
    logic                 f_real_r;
    logic [PSUM_AW-1:0]   psum_xbase, psum_ptr;
    logic [KERNEL_AW-1:0] k_ck, k_addr;
    logic [IFMAP_AW-1:0]  i_cbase, i_addr;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            f_real_r   <= 1'b0;
            psum_xbase <= '0; psum_ptr <= '0;
            k_ck       <= '0; k_addr   <= '0;
            i_cbase    <= '0; i_addr   <= '0;
        end else if (state == COMPUTE) begin
            if (last_f) begin
                f_real_r <= (num_filters != '0);
                // psum slot: x*nf + f
                if (last_k && last_c && !last_x) begin
                    psum_xbase <= psum_xbase + PSUM_AW'(num_filters);
                    psum_ptr   <= psum_xbase + PSUM_AW'(num_filters);
                end else begin
                    psum_ptr   <= psum_xbase;
                end
                // kernel: f*nc3 + c*3 + k  (f restarts at 0, so addr = k_ck)
                if (last_k && last_c) begin
                    k_ck   <= '0;
                    k_addr <= '0;
                end else begin
                    k_ck   <= k_ck + 1'b1;
                    k_addr <= k_ck + 1'b1;
                end
                // ifmap: c*W + x + k
                if (!last_k) begin
                    i_addr <= i_addr + 1'b1;
                end else if (!last_c) begin
                    i_cbase <= i_cbase + ifmap_w;
                    i_addr  <= i_cbase + ifmap_w + IFMAP_AW'(cnt_x);
                end else begin
                    i_cbase <= '0;
                    i_addr  <= last_x ? IFMAP_AW'(cnt_x) : IFMAP_AW'(cnt_x) + 1'b1;
                end
            end else begin
                f_real_r <= f_real_r && (cnt_f != num_filters - 1'b1);
                psum_ptr <= psum_ptr + 1'b1;
                k_addr   <= k_addr + nc3;
            end
        end else begin
            f_real_r   <= (num_filters != '0);
            psum_xbase <= '0; psum_ptr <= '0;
            k_ck       <= '0; k_addr   <= '0;
            i_cbase    <= '0; i_addr   <= '0;
        end
    end

    // real filter (not a bubble) this cycle
    logic f_real;
    assign f_real = f_real_r;

    // psum slot of the MAC input being issued: x*nf + f (bubbles -> 0)
    logic [PSUM_AW-1:0] psum_slot;
    assign psum_slot = f_real ? psum_ptr : '0;

    //==========================================================================
    // PIPELINE DRAIN (flush MAC after last input)
    //==========================================================================
    logic [$clog2(MAC_LATENCY+1)-1:0] drain_cnt;
    logic draining;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            drain_cnt <= '0;
            draining  <= 1'b0;
        end else if (state == COMPUTE) begin
            if (last_mac_in && !draining) begin
                draining  <= 1'b1;
                drain_cnt <= '0;
            end else if (draining) begin
                drain_cnt <= drain_cnt + 1'b1;
            end
        end else begin
            drain_cnt <= '0;
            draining  <= 1'b0;
        end
    end

    logic compute_finished;
    assign compute_finished = draining &&
                              (drain_cnt == ($clog2(MAC_LATENCY+1))'(MAC_LATENCY));

    //==========================================================================
    // PIPELINE TAG (MAC_LATENCY deep). Bubbles are tagged invalid.
    //==========================================================================
    logic [PSUM_AW-1:0] a_tag [0:MAC_LATENCY-1];   // psum slot address tag
    logic               v_tag [0:MAC_LATENCY-1];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < MAC_LATENCY; i++) begin
                a_tag[i] <= '0;
                v_tag[i] <= 1'b0;
            end
        end else begin
            for (int i = MAC_LATENCY-1; i > 0; i--) begin
                a_tag[i] <= a_tag[i-1];
                v_tag[i] <= v_tag[i-1];
            end
            a_tag[0] <= psum_slot;
            v_tag[0] <= (state == COMPUTE) && !draining && f_real;
        end
    end

    //==========================================================================
    // NEXT STATE
    //==========================================================================
    always_comb begin
        next_state = state;
        case (state)
            IDLE:
                if (start) next_state = FILTER_LOAD;

            FILTER_LOAD:
                if (filt_fire && (filter_cnt == filter_total - 1'b1))
                    next_state = IFMAP_LOAD;

            IFMAP_LOAD:
                if (imap_fire && (ifmap_cnt == ifmap_total - 1'b1))
                    next_state = use_psum_in ? PSUM_LOAD : PSUM_CLEAR;

            PSUM_CLEAR:
                if (psum_cnt == psum_total - 1'b1)
                    next_state = COMPUTE;

            PSUM_LOAD:
                if (psin_fire && (psum_cnt == psum_total - 1'b1))
                    next_state = COMPUTE;

            COMPUTE:
                if (compute_finished) next_state = PSUM_DRAIN;

            PSUM_DRAIN:
                if (fifo_we_int && (dr_wr_cnt == {1'b0, psum_total} - 1'b1))
                    next_state = PE_DONE;

            PE_DONE:
                next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

    //==========================================================================
    // OUTPUTS
    //==========================================================================
    assign filter_ready  = (state == FILTER_LOAD);
    assign ifmap_ready   = (state == IFMAP_LOAD);
    assign psum_in_ready = (state == PSUM_LOAD);

    // ifmap spad
    assign ifmap_we       = (state == IFMAP_LOAD) && imap_fire;
    assign ifmap_addr_wr  = ifmap_cnt;
    assign ifmap_data_in  = ifmap_data;
    assign ifmap_addr_rd  = (state == COMPUTE) ? i_addr : '0;

    // kernel spad
    assign kernel_we       = (state == FILTER_LOAD) && filt_fire;
    assign kernel_addr_wr  = filter_cnt;
    assign kernel_data_in  = filter_data;
    assign kernel_addr_rd  = (state == COMPUTE) ? k_addr : '0;

    // psum spad write port (muxed)
    always_comb begin
        psum_we       = 1'b0;
        psum_addr_wr  = '0;
        psum_data_in  = '0;

        if (state == PSUM_LOAD && psin_fire) begin
            psum_we       = 1'b1;
            psum_addr_wr  = psum_cnt;
            psum_data_in  = psum_in_data;
        end else if (state == PSUM_CLEAR) begin
            psum_we       = 1'b1;
            psum_addr_wr  = psum_cnt;
            psum_data_in  = '0;
        end else if (state == COMPUTE && v_tag[MAC_LATENCY-1]) begin
            psum_we       = 1'b1;
            psum_addr_wr  = a_tag[MAC_LATENCY-1];
            psum_data_in  = mac_psumout;
        end
    end

    // bubbles read slot 0 (harmless, result is discarded)
    assign psum_addr_rd = (state == COMPUTE)    ? psum_slot :
                          (state == PSUM_DRAIN) ? dr_iss_cnt[PSUM_AW-1:0] : '0;

    // spad read-enable: always in COMPUTE, only on issue during drain
    assign psum_rd_en   = (state == COMPUTE) | dr_issue;

    // output FIFO
    assign fifo_we      = fifo_we_int;
    assign fifo_data_in = psum_data_out;

    // MAC control
    assign mac_ce   = (state == COMPUTE);
    assign mac_sclr = (state == IDLE) || (state == FILTER_LOAD) ||
                      (state == IFMAP_LOAD) || (state == PSUM_LOAD) ||
                      (state == PSUM_CLEAR);

    assign done = (state == PE_DONE);

endmodule