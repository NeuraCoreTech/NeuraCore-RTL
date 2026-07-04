`timescale 1ns / 1ps
//==============================================================================
// Module      : PEControlUnit
// Description : Single FSM controlling the entire Eyeriss-style PE.
//               Implements Row-Stationary dataflow for LineCNN_OCR
//               (all-3×3 conv, 8-bit data, 24-bit accumulation).
//
// MAC latency = 3 cycles, derived from mac.sv:
//   Cycle 0 : inputs presented (ifmap, filter, psum_spad[f] async read)
//   Cycle 1 : buffer_psumin FF in mac.sv registers psumin
//   Cycle 2 : xbip_multadd_8bit multiply stage
//   Cycle 3 : xbip adder + output register → psumout valid
//
// All scratchpads have SYNCHRONOUS write, ASYNCHRONOUS read (distributed RAM).
//   → addr_rd change produces data_out on the same cycle combinatorially.
//   → Write takes effect on the NEXT clock edge.
//
// RAW hazard analysis (psum scratchpad):
//   Between two visits to the same filter slot f, there are
//   num_channels × S = 4×3 = 12 MAC cycles minimum.
//   12 > 3 (MAC latency) → write-back lands before next read of same slot. ✓
//
// ┌─────────────────────────────────────────────────────────────────┐
// │ STATE MACHINE                                                   │
// │                                                                 │
// │  IDLE → FILTER_LOAD → IFMAP_LOAD → [PSUM_LOAD] →                │
// │         COMPUTE → PSUM_DRAIN → PE_DONE → IDLE                   │
// │                                                                 │
// │  FILTER_LOAD : stream num_filters×num_channels×3 weights        │
// │                into kernel scratchpad (valid/ready)             │
// │  IFMAP_LOAD  : stream num_channels×3 pixels into ifmap spad     │
// │  PSUM_LOAD   : optional pre-load of num_filters psums from LN   │
// │                (skipped when cfg_psum_in_valid=0)               │
// │  COMPUTE     : run (x,f,c,k) MAC loop, write-back via           │
// │                3-deep pipeline tag shift register               │
// │  PSUM_DRAIN  : read psum spad → push to output fifo_block       │
// │  PE_DONE     : 1-cycle done pulse                               │
// └─────────────────────────────────────────────────────────────────┘
//
// SCRATCHPAD PORT NAMES (must match your existing modules exactly):
//   scratchpad_ifmap  : data_in, we, addr_wr, addr_rd, data_out
//   scratchpad_kernel : data_in, we, addr_wr, addr_rd, data_out
//   scratchpad_psum   : data_in, we, addr_wr, addr_rd, data_out
//   fifo_block        : we, re, data_in, data_out, full_flag, empty_flag
//   mac               : ce, sclr, ifmap, filter, psumin, psumout
//==============================================================================

module PEControlUnit #(
    parameter DATA_WIDTH     = 8,
    parameter PSUM_WIDTH     = 24,
    parameter MAXKERNELS     = 24,      // p : max filters per PE
    parameter MAXCHANNELS    = 4,       // q : max channels per PE
    parameter MAXKERNELWIDTH = 3,       // S : always 3 for LineCNN_OCR
    parameter MAC_LATENCY    = 3,       // see derivation in header above

    // Derived - must match your scratchpad DEPTH / ADDR_WIDTH parameters
    parameter IFMAP_DEPTH  = MAXCHANNELS * MAXKERNELWIDTH,                // 12
    parameter KERNEL_DEPTH = MAXKERNELS  * MAXCHANNELS * MAXKERNELWIDTH,  // 288
    parameter PSUM_DEPTH   = MAXKERNELS,                                  // 24

    parameter IFMAP_AW  = $clog2(IFMAP_DEPTH),   // 4
    parameter KERNEL_AW = $clog2(KERNEL_DEPTH),  // 9
    parameter PSUM_AW   = $clog2(PSUM_DEPTH),    // 5

    // Runtime configuration field widths
    parameter CFG_F_W = $clog2(MAXKERNELS  + 1), // 5  (values 1..24)
    parameter CFG_C_W = $clog2(MAXCHANNELS + 1), // 3  (values 1..4)
    parameter CFG_X_W = 8                         // ofmap_len up to 255
)(
    input  logic clk,
    input  logic reset,

    //------------------------------------------------------------------
    // Tile handshake
    //------------------------------------------------------------------
    input  logic start,   // 1-cycle pulse → begin new tile
    output logic done,    // 1-cycle pulse → tile complete, fifo loaded

    //------------------------------------------------------------------
    // Configuration - sampled on the `start` pulse, held stable until done
    //------------------------------------------------------------------
    input  logic [CFG_F_W-1:0] cfg_num_filters,   // p  (1..MAXKERNELS)
    input  logic [CFG_C_W-1:0] cfg_num_channels,  // q  (1..MAXCHANNELS)
    input  logic [CFG_X_W-1:0] cfg_ofmap_len,     // E  (ofmap columns)
    input  logic               cfg_psum_in_valid,  // 1 = pre-load psums from LN

    //------------------------------------------------------------------
    // Filter load - from NoC GIN (valid/ready handshake)
    //------------------------------------------------------------------
    input  logic                  filter_valid,
    input  logic [DATA_WIDTH-1:0] filter_data,
    output logic                  filter_ready,

    //------------------------------------------------------------------
    // IFmap load - from NoC GIN (valid/ready handshake)
    //------------------------------------------------------------------
    input  logic                  ifmap_valid,
    input  logic [DATA_WIDTH-1:0] ifmap_data,
    input  logic                  ifmap_fresh,  
    output logic                  ifmap_ready,

    //------------------------------------------------------------------
    // Input psum - from Local Network / PE below (valid/ready)
    // Used to pre-load psum scratchpad before COMPUTE.
    //------------------------------------------------------------------
    input  logic                   psum_in_valid,
    input  logic [PSUM_WIDTH-1:0]  psum_in_data,
    output logic                   psum_in_ready,

    //------------------------------------------------------------------
    // Output psum fifo - to fifo_block instance (in PE top-level)
    // PE top-level wires: pe_ctrl → fifo_block → NoC GON / LN above
    //------------------------------------------------------------------
    output logic                   fifo_we,       // → fifo_block.we
    output logic [PSUM_WIDTH-1:0]  fifo_data_in,  // → fifo_block.data_in
    input  logic                   fifo_full,     // ← fifo_block.full_flag

    //------------------------------------------------------------------
    // Scratchpad: ifmap  (scratchpad_ifmap)
    //------------------------------------------------------------------
    output logic                  ifmap_we,
    output logic [IFMAP_AW-1:0]  ifmap_addr_wr,
    output logic [DATA_WIDTH-1:0] ifmap_data_in,  // → scratchpad_ifmap.data_in
    output logic [IFMAP_AW-1:0]  ifmap_addr_rd,
    input  logic [DATA_WIDTH-1:0] ifmap_data_out, // ← scratchpad_ifmap.data_out → mac.ifmap

    //------------------------------------------------------------------
    // Scratchpad: kernel  (scratchpad_kernel)
    //------------------------------------------------------------------
    output logic                   kernel_we,
    output logic [KERNEL_AW-1:0]  kernel_addr_wr,
    output logic [DATA_WIDTH-1:0]  kernel_data_in, // → scratchpad_kernel.data_in
    output logic [KERNEL_AW-1:0]  kernel_addr_rd,
    input  logic [DATA_WIDTH-1:0]  kernel_data_out,// ← scratchpad_kernel.data_out → mac.filter

    //------------------------------------------------------------------
    // Scratchpad: psum  (scratchpad_psum)
    // Single write port - muxed between PSUM_LOAD (LN data) and COMPUTE (MAC wb)
    //------------------------------------------------------------------
    output logic                   psum_we,
    output logic [PSUM_AW-1:0]    psum_addr_wr,
    output logic [PSUM_WIDTH-1:0]  psum_data_in,  // → scratchpad_psum.data_in
    output logic [PSUM_AW-1:0]    psum_addr_rd,
    input  logic [PSUM_WIDTH-1:0]  psum_data_out, // ← scratchpad_psum.data_out → mac.psumin

    //------------------------------------------------------------------
    // MAC  (mac.sv)
    //------------------------------------------------------------------
    output logic mac_ce,
    output logic mac_sclr,
    // mac.ifmap   ← ifmap_data_out   (wire in PE top-level)
    // mac.filter  ← kernel_data_out  (wire in PE top-level)
    // mac.psumin  ← psum_data_out    (wire in PE top-level)
    input  logic [PSUM_WIDTH-1:0] mac_psumout    // ← mac.psumout
);

    //==========================================================================
    // STATE ENCODING
    //==========================================================================
    typedef enum logic [2:0] {
        IDLE        = 3'd0,
        FILTER_LOAD = 3'd1,
        IFMAP_LOAD  = 3'd2,
        PSUM_LOAD   = 3'd3,
        COMPUTE     = 3'd4,
        PSUM_DRAIN  = 3'd5,
        PE_DONE     = 3'd6,
        PSUM_CLEAR  = 3'd7   // zero-fill psum spad when no LN pre-load
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge reset)
        if (reset) state <= IDLE;
        else        state <= next_state;

    //==========================================================================
    // CONFIGURATION REGISTERS  (latched on start)
    //==========================================================================
    logic [CFG_F_W-1:0] num_filters;
    logic [CFG_C_W-1:0] num_channels;
    logic [CFG_X_W-1:0] ofmap_len;
    logic               use_psum_in;   // cfg_psum_in_valid latched

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            num_filters  <= '0;
            num_channels <= '0;
            ofmap_len    <= '0;
            use_psum_in  <= 1'b0;
        end else if (start) begin
            num_filters  <= cfg_num_filters;
            num_channels <= cfg_num_channels;
            ofmap_len    <= cfg_ofmap_len;
            use_psum_in  <= cfg_psum_in_valid;
        end
    end

    //==========================================================================
    // LOAD / DRAIN COUNTERS
    //==========================================================================
    // filter_cnt : counts beats accepted in FILTER_LOAD  (0..filter_total-1)
    // ifmap_cnt  : counts beats accepted in IFMAP_LOAD   (0..ifmap_total-1)
    // psum_cnt   : counts beats in PSUM_LOAD / PSUM_DRAIN (0..num_filters-1)

    logic [KERNEL_AW-1:0] filter_cnt;
    logic [IFMAP_AW-1:0]  ifmap_cnt;
    logic [PSUM_AW-1:0]   psum_cnt;

    // Pre-computed totals (combinatorial)
    logic [KERNEL_AW-1:0] filter_total;
    logic [IFMAP_AW-1:0]  ifmap_total;
    assign filter_total = KERNEL_AW'(num_filters)  * KERNEL_AW'(num_channels) * KERNEL_AW'(MAXKERNELWIDTH);
    assign ifmap_total  = IFMAP_AW'(num_channels) * IFMAP_AW'(MAXKERNELWIDTH);

    // Handshake fire signals
    logic filt_fire, imap_fire, psin_fire, drain_fire;
    assign filt_fire  = filter_valid  & filter_ready;
    assign imap_fire  = ifmap_valid   & ifmap_ready;
    assign psin_fire  = psum_in_valid & psum_in_ready;
    assign drain_fire = (state == PSUM_DRAIN) & ~fifo_full;

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
                PSUM_DRAIN: begin
                    if (drain_fire) psum_cnt <= psum_cnt + 1'b1;
                end
                default: ;
            endcase
        end
    end

    //==========================================================================
    // COMPUTE LOOP COUNTERS  (x → f → c → k, innermost k)
    // Active only in COMPUTE state. Each cycle one MAC input is presented.
    //
    //   k : kernel column        0..S-1        (2 bits)
    //   c : channel index        0..q-1        (CFG_C_W bits)
    //   f : filter index         0..p-1        (CFG_F_W bits)
    //   x : ofmap column         0..E-1        (CFG_X_W bits)
    //
    // Addresses generated combinatorially:
    //   ifmap_addr_rd  = c * S + k                              (0..11)
    //   kernel_addr_rd = f * (num_channels * S) + c * S + k    (0..287)
    //   psum_addr_rd   = f                                      (0..23)
    //==========================================================================
    logic [CFG_X_W-1:0]              cnt_x;
    logic [CFG_F_W-1:0]              cnt_f;
    logic [CFG_C_W-1:0]              cnt_c;
    logic [$clog2(MAXKERNELWIDTH)-1:0] cnt_k;

    // Boundary flags
    logic last_k, last_c, last_f, last_x, last_mac_in;
    assign last_k      = (cnt_k == ($clog2(MAXKERNELWIDTH))'(MAXKERNELWIDTH - 1));
    assign last_c      = (cnt_c == CFG_C_W'(num_channels) - 1'b1);
    assign last_f      = (cnt_f == CFG_F_W'(num_filters)  - 1'b1);
    assign last_x      = (cnt_x == CFG_X_W'(ofmap_len)   - 1'b1);
    assign last_mac_in = last_k & last_c & last_f & last_x;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_x <= '0; cnt_f <= '0; cnt_c <= '0; cnt_k <= '0;
        end else if (state == COMPUTE) begin
            if (last_k) begin
                cnt_k <= '0;
                if (last_c) begin
                    cnt_c <= '0;
                    if (last_f) begin
                        cnt_f <= '0;
                        if (!last_x) cnt_x <= cnt_x + 1'b1;
                    end else cnt_f <= cnt_f + 1'b1;
                end else cnt_c <= cnt_c + 1'b1;
            end else cnt_k <= cnt_k + 1'b1;
        end else begin
            cnt_x <= '0; cnt_f <= '0; cnt_c <= '0; cnt_k <= '0;
        end
    end

    //==========================================================================
    // DRAIN COUNTER  (flush MAC pipeline after last input)
    // After last_mac_in, stay in COMPUTE for MAC_LATENCY more cycles
    // so the final results emerge from mac.psumout before transitioning.
    //==========================================================================
    logic [$clog2(MAC_LATENCY+1)-1:0] drain_cnt;
    logic draining;   // set after last_mac_in, cleared when drain done

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
    // PIPELINE TAG  (3-deep shift register)
    // Tracks which filter slot f produced the MAC result that emerges
    // MAC_LATENCY cycles later, so we write it back to the correct psum_spad[f].
    //
    // v_tag[MAC_LATENCY-1] = 1 → psum_spad[f_tag[MAC_LATENCY-1]] ← mac_psumout
    //==========================================================================
    logic [CFG_F_W-1:0] f_tag [0:MAC_LATENCY-1];
    logic               v_tag [0:MAC_LATENCY-1];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < MAC_LATENCY; i++) begin
                f_tag[i] <= '0;
                v_tag[i] <= 1'b0;
            end
        end else begin
            // Shift pipeline left
            for (int i = MAC_LATENCY-1; i > 0; i--) begin
                f_tag[i] <= f_tag[i-1];
                v_tag[i] <= v_tag[i-1];
            end
            // New entry at stage 0: valid only when actively issuing MAC inputs
            f_tag[0] <= cnt_f;
            v_tag[0] <= (state == COMPUTE) && !draining;
        end
    end

    //==========================================================================
    // NEXT-STATE LOGIC
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
                if (psum_cnt == PSUM_AW'(num_filters) - 1'b1)
                    next_state = COMPUTE;

            PSUM_LOAD:
                if (psin_fire && (psum_cnt == PSUM_AW'(num_filters) - 1'b1))
                    next_state = COMPUTE;

            COMPUTE:
                if (compute_finished) next_state = PSUM_DRAIN;

            PSUM_DRAIN:
                if (drain_fire && (psum_cnt == PSUM_AW'(num_filters) - 1'b1))
                    next_state = PE_DONE;

            PE_DONE:
                next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

    //==========================================================================
    // OUTPUT LOGIC
    //==========================================================================

    //------ ready / back-pressure signals ------------------------------------
    assign filter_ready  = (state == FILTER_LOAD);
    assign ifmap_ready   = (state == IFMAP_LOAD);
    assign psum_in_ready = (state == PSUM_LOAD);

    //------ ifmap scratchpad -------------------------------------------------
    assign ifmap_we       = (state == IFMAP_LOAD) && imap_fire;
    assign ifmap_addr_wr  = ifmap_cnt;
    assign ifmap_data_in  = ifmap_data;
    // Read address: c*S + k during COMPUTE; 0 otherwise
    assign ifmap_addr_rd  = (state == COMPUTE) ?
                            IFMAP_AW'(cnt_c) * IFMAP_AW'(MAXKERNELWIDTH) + IFMAP_AW'(cnt_k)
                            : '0;

    //------ kernel scratchpad ------------------------------------------------
    assign kernel_we       = (state == FILTER_LOAD) && filt_fire;
    assign kernel_addr_wr  = filter_cnt;
    assign kernel_data_in  = filter_data;
    // Read address: f*(num_ch*S) + c*S + k during COMPUTE
    assign kernel_addr_rd  = (state == COMPUTE) ?
                             KERNEL_AW'(cnt_f) * (KERNEL_AW'(num_channels) * KERNEL_AW'(MAXKERNELWIDTH))
                             + KERNEL_AW'(cnt_c) * KERNEL_AW'(MAXKERNELWIDTH)
                             + KERNEL_AW'(cnt_k)
                             : '0;

    //------ psum scratchpad (single write port, muxed) -----------------------
    // Priority: PSUM_LOAD (LN input) or COMPUTE write-back - mutually exclusive states
    always_comb begin
        psum_we       = 1'b0;
        psum_addr_wr  = '0;
        psum_data_in  = '0;

        if (state == PSUM_LOAD && psin_fire) begin
            // Pre-load psums from Local Network
            psum_we       = 1'b1;
            psum_addr_wr  = psum_cnt;
            psum_data_in  = psum_in_data;
        end else if (state == PSUM_CLEAR) begin
            // Zero-fill psum spad before first COMPUTE (no LN pre-load)
            psum_we       = 1'b1;
            psum_addr_wr  = psum_cnt;
            psum_data_in  = '0;
        end else if (state == COMPUTE && v_tag[MAC_LATENCY-1]) begin
            // Write-back MAC result to correct filter slot
            psum_we       = 1'b1;
            psum_addr_wr  = PSUM_AW'(f_tag[MAC_LATENCY-1]);
            psum_data_in  = mac_psumout;
        end
    end

    // Read address:
    //   COMPUTE     → current f  (feeds mac.psumin via psum_data_out)
    //   PSUM_DRAIN  → psum_cnt   (sequential drain to output FIFO)
    //   other       → 0
    assign psum_addr_rd = (state == COMPUTE)    ? PSUM_AW'(cnt_f)  :
                          (state == PSUM_DRAIN) ? psum_cnt          : '0;

    //------ output FIFO (fifo_block) -----------------------------------------
    // psum_spad has async read: data_out valid same cycle as addr_rd changes.
    // We write to FIFO each cycle we are draining AND FIFO is not full.
    assign fifo_we      = drain_fire;
    assign fifo_data_in = psum_data_out;   // directly from psum scratchpad

    //------ MAC control ------------------------------------------------------
    // mac_ce: high during active MAC issuing AND pipeline drain
    // mac_sclr: clear when not computing (keeps MAC clean between tiles)
    assign mac_ce   = (state == COMPUTE);
    assign mac_sclr = (state == IDLE) || (state == FILTER_LOAD) ||
                      (state == IFMAP_LOAD) || (state == PSUM_LOAD) ||
                      (state == PSUM_CLEAR);

    //------ done pulse -------------------------------------------------------
    assign done = (state == PE_DONE);

endmodule