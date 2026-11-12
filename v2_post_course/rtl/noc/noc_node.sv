`timescale 1ns / 1ps
//==============================================================================
// Module      : noc_node
// Description : One PE cluster plus its network interface (NI). This is the only
//               place that knows cluster_top's ports; the routers just move words.
//
// Link words (opaque to routers): { tag[TAGW-1:0], payload }
//   weight net  in : tag = PE index (r*PE_COLS + c), payload = 8-bit filter byte
//   ifmap  net  in : tag = PE row,                  payload = 8-bit ifmap byte
//   psum   in      : tag = PE column,               payload = 24-bit psum
//   psum   out     : tag = PE column,               payload = 24-bit psum, `last`
//                    set on the final word of each column's stream
// Words for different PEs/rows/columns may be interleaved in any order; order
// within one PE/row/column is preserved. Upstream `last` flags on the input
// streams are ignored (the cluster counts words from its config).
//
// Config registers (cfg_we/cfg_addr/cfg_wdata):
//   0 num_filters  1 num_channels  2 ofmap_len  3 psum_in_valid  4 enable
//   enable=0: node is inert and reports layer_done=1.
// Control: `start` pulses the cluster (config is latched in the cluster on
// start); `clear` clears layer_done. layer_done = cluster done AND every output
// word delivered (PE_COLS * nf * E words). tag_err latches on an out-of-range tag
// (word is dropped).
//==============================================================================
module noc_node #(
    parameter PE_ROWS        = 2,
    parameter PE_COLS        = 2,
    parameter DATA_WIDTH     = 8,
    parameter PSUM_WIDTH     = 24,
    parameter MAXKERNELS     = 24,
    parameter MAXCHANNELS    = 4,
    parameter MAXOFMAP       = 16,
    parameter FIFO_DEPTH     = 32,
    parameter NPE            = PE_ROWS * PE_COLS,
    parameter TAGW           = (NPE > 1) ? $clog2(NPE) : 1,
    parameter CFG_F_W        = $clog2(MAXKERNELS  + 1),
    parameter CFG_C_W        = $clog2(MAXCHANNELS + 1),
    parameter CFG_X_W        = 8,
    parameter TOTW           = $clog2(MAXKERNELS * MAXOFMAP + 1)
)(
    input  logic clk,
    input  logic reset,

    // config / control
    input  logic        cfg_we,
    input  logic [2:0]  cfg_addr,
    input  logic [15:0] cfg_wdata,
    input  logic        start,
    input  logic        clear,
    output logic        layer_done,
    output logic        tag_err,

    // weight network -> node
    input  logic                         w_valid,
    input  logic [TAGW+DATA_WIDTH-1:0]   w_data,
    output logic                         w_ready,
    // ifmap network -> node
    input  logic                         i_valid,
    input  logic [TAGW+DATA_WIDTH-1:0]   i_data,
    output logic                         i_ready,
    // psum network -> node (bottom row preload)
    input  logic                         pi_valid,
    input  logic [TAGW+PSUM_WIDTH-1:0]   pi_data,
    output logic                         pi_ready,
    // node -> psum network (top row results)
    output logic                         po_valid,
    output logic [TAGW+PSUM_WIDTH-1:0]   po_data,
    output logic                         po_last,
    input  logic                         po_ready
);

    // ---------------- config ----------------
    logic [CFG_F_W-1:0] nf;
    logic [CFG_C_W-1:0] nc;
    logic [CFG_X_W-1:0] ne;
    logic               psin;
    logic               enable;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            nf <= '0; nc <= '0; ne <= '0; psin <= 1'b0; enable <= 1'b0;
        end else if (cfg_we) begin
            case (cfg_addr)
                3'd0: nf     <= cfg_wdata[CFG_F_W-1:0];
                3'd1: nc     <= cfg_wdata[CFG_C_W-1:0];
                3'd2: ne     <= cfg_wdata[CFG_X_W-1:0];
                3'd3: psin   <= cfg_wdata[0];
                3'd4: enable <= cfg_wdata[0];
                default: ;
            endcase
        end
    end

    // ---------------- cluster ----------------
    logic                                    c_start, c_done;
    logic [PE_ROWS-1:0][PE_COLS-1:0]         filter_valid, filter_ready;
    logic [PE_ROWS-1:0][PE_COLS-1:0][DATA_WIDTH-1:0] filter_data;
    logic [PE_ROWS-1:0]                      ifmap_valid, ifmap_ready;
    logic [PE_ROWS-1:0][DATA_WIDTH-1:0]      ifmap_data;
    logic [PE_COLS-1:0]                      psum_in_valid, psum_in_ready;
    logic [PE_COLS-1:0][PSUM_WIDTH-1:0]      psum_in_data;
    logic [PE_COLS-1:0][PSUM_WIDTH-1:0]      psum_out_data;
    logic [PE_COLS-1:0]                      psum_out_valid, psum_out_re;

    assign c_start = start & enable;

    cluster_top #(
        .PE_ROWS(PE_ROWS), .PE_COLS(PE_COLS), .DATA_WIDTH(DATA_WIDTH),
        .PSUM_WIDTH(PSUM_WIDTH), .MAXKERNELS(MAXKERNELS), .MAXCHANNELS(MAXCHANNELS),
        .MAXOFMAP(MAXOFMAP), .FIFO_DEPTH(FIFO_DEPTH)
    ) u_cluster (
        .clk(clk), .reset(reset), .start(c_start), .done(c_done),
        .cfg_num_filters(nf), .cfg_num_channels(nc), .cfg_ofmap_len(ne),
        .cfg_psum_in_valid(psin),
        .filter_valid(filter_valid), .filter_data(filter_data), .filter_ready(filter_ready),
        .ifmap_valid(ifmap_valid),   .ifmap_data(ifmap_data),   .ifmap_ready(ifmap_ready),
        .psum_in_valid(psum_in_valid), .psum_in_data(psum_in_data), .psum_in_ready(psum_in_ready),
        .psum_out_data(psum_out_data), .psum_out_valid(psum_out_valid), .psum_out_re(psum_out_re)
    );

    // ---------------- weight demux (tag = PE index) ----------------
    logic [TAGW-1:0] w_tag;
    logic            w_tag_ok;
    assign w_tag    = w_data[DATA_WIDTH +: TAGW];
    assign w_tag_ok = (int'(w_tag) < NPE);
    always_comb begin
        filter_valid = '0;
        filter_data  = '0;
        w_ready      = 1'b1;               // out-of-range tag: drop (tag_err)
        for (int r = 0; r < PE_ROWS; r++)
            for (int c = 0; c < PE_COLS; c++) begin
                filter_data[r][c] = w_data[DATA_WIDTH-1:0];
                if (w_tag_ok && int'(w_tag) == r*PE_COLS + c) begin
                    filter_valid[r][c] = w_valid;
                    w_ready            = filter_ready[r][c];
                end
            end
    end

    // ---------------- ifmap demux (tag = row) ----------------
    logic [TAGW-1:0] i_tag;
    logic            i_tag_ok;
    assign i_tag    = i_data[DATA_WIDTH +: TAGW];
    assign i_tag_ok = (int'(i_tag) < PE_ROWS);
    always_comb begin
        ifmap_valid = '0;
        ifmap_data  = '0;
        i_ready     = 1'b1;
        for (int r = 0; r < PE_ROWS; r++) begin
            ifmap_data[r] = i_data[DATA_WIDTH-1:0];
            if (i_tag_ok && int'(i_tag) == r) begin
                ifmap_valid[r] = i_valid;
                i_ready        = ifmap_ready[r];
            end
        end
    end

    // ---------------- psum-in demux (tag = column) ----------------
    logic [TAGW-1:0] pi_tag;
    logic            pi_tag_ok;
    assign pi_tag    = pi_data[PSUM_WIDTH +: TAGW];
    assign pi_tag_ok = (int'(pi_tag) < PE_COLS);
    always_comb begin
        psum_in_valid = '0;
        psum_in_data  = '0;
        pi_ready      = 1'b1;
        for (int c = 0; c < PE_COLS; c++) begin
            psum_in_data[c] = pi_data[PSUM_WIDTH-1:0];
            if (pi_tag_ok && int'(pi_tag) == c) begin
                psum_in_valid[c] = pi_valid;
                pi_ready         = psum_in_ready[c];
            end
        end
    end
    
        // ---------------- psum-out elastic buffer (2 entries) ----------------
    // m_ready depends only on ocnt (a register), so no ready path crosses it.
    logic [TAGW+PSUM_WIDTH-1:0] od0, od1;
    logic                       ol0, ol1;
    logic [1:0]                 ocnt;
    logic                       m_valid, m_last, m_ready, m_push, o_pop;
    logic [TAGW+PSUM_WIDTH-1:0] m_data;

    assign m_ready  = (ocnt < 2'd2);
    assign po_valid = (ocnt != 2'd0);
    assign po_data  = od0;
    assign po_last  = ol0;
    assign o_pop    = po_valid && po_ready;
    assign m_push   = m_valid && m_ready;

    // ---------------- psum-out merge (round robin over columns) ----------------
    logic [TOTW-1:0]              tot;         // words per column = nf * E
    logic [PE_COLS-1:0][TOTW-1:0] sent;
    logic [$clog2(PE_COLS+1)-1:0] rr;
    logic [$clog2(PE_COLS+1)-1:0] sel;
    logic                         any_v;
    int                           cand;

    always_comb begin
        sel   = '0;
        any_v = 1'b0;
        for (int k = 0; k < PE_COLS; k++) begin
            cand = (int'(rr) + k) % PE_COLS;   // assign separately: a declaration
            if (!any_v && psum_out_valid[cand]) begin   // initializer in a static block runs once
                any_v = 1'b1;
                sel   = cand;
            end
        end
               m_valid      = any_v;
        m_data       = {TAGW'(sel), psum_out_data[sel]};
        m_last       = any_v && (sent[sel] == tot - 1'b1);
        psum_out_re  = '0;
        if (m_push) psum_out_re[sel] = 1'b1;
    end

    logic done_seen;
    logic all_sent;
    always_comb begin
        all_sent = 1'b1;
        for (int c = 0; c < PE_COLS; c++) if (sent[c] != tot) all_sent = 1'b0;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tot <= '0; sent <= '0; rr <= '0; done_seen <= 1'b0; tag_err <= 1'b0;
        end else begin
            if (c_start) begin
                tot       <= TOTW'(nf) * TOTW'(ne);
                sent      <= '0;
                done_seen <= 1'b0;
            end else begin
                if (c_done) done_seen <= 1'b1;
                if (clear)  done_seen <= 1'b0;
                if (m_push) begin
                    sent[sel] <= sent[sel] + 1'b1;
                    rr        <= (int'(sel) + 1) % PE_COLS;
                end
            end
            if ((w_valid && !w_tag_ok) || (i_valid && !i_tag_ok) || (pi_valid && !pi_tag_ok))
                tag_err <= 1'b1;
            if (clear) tag_err <= 1'b0;
        end
    end
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ocnt <= '0; od0 <= '0; od1 <= '0; ol0 <= 1'b0; ol1 <= 1'b0;
        end else begin
            case ({m_push, o_pop})
                2'b10: if (ocnt == 2'd0) begin
                           od0 <= m_data; ol0 <= m_last; ocnt <= 2'd1;
                       end else begin
                           od1 <= m_data; ol1 <= m_last; ocnt <= 2'd2;
                       end
                2'b01: begin od0 <= od1; ol0 <= ol1; ocnt <= ocnt - 2'd1; end
                2'b11: begin od0 <= m_data; ol0 <= m_last; end  // ocnt == 1
                default: ;
            endcase
        end
    end    

    assign layer_done = !enable || (done_seen && all_sent && (ocnt == 2'd0));

endmodule