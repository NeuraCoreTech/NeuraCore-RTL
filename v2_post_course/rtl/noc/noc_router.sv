`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2026
// Design Name: 
// Module Name: noc_router
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Generic circuit-switched NoC router core (opaque words + last, multicast fork, grouped/interleaved filters).
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//==============================================================================
// Module      : noc_router
// Description : Generic circuit-switched NoC router (one instance per cluster
//               per network: weight, ifmap, psum). Data-agnostic: moves opaque
//               WIDTH-bit words plus a `last` flag. No lengths or dataflow
//               knowledge.
//
// Ports       : P bidirectional ports (each has an input and an output).
//               Port numbering is chosen by the instantiator (e.g.
//               0=LOCAL 1=N 2=S 3=E 4=W).
//
// Config (held stable during a layer; pulse cfg_clear when changing it):
//   cfg_en[o]   : output o is used
//   cfg_src[o]  : which input drives output o  (multicast = several outputs
//                 choose the same input; broadcast = all of them)
//   cfg_k/g/ph  : optional per-output word filter for grouped / interleaved
//                 multicast. Output o takes word idx of its source stream iff
//                     ((idx / G) % K) == PH      (K<=1: take every word)
//                 idx counts words of the source stream and restarts after a
//                 word with last=1. G<=1 means groups of one word.
//
// Multicast fork: each input keeps a `pending` mask of outputs that have not
// yet accepted the current word; the word is released (in_ready) only when no
// output is still pending. No word is lost or duplicated under back-pressure.
//
// Each output is a 2-entry elastic buffer, so in_ready never depends on
// out_ready combinationally (no ready path through the router or across a mesh).
// Config must still be acyclic at the stream level. An input that no output
// selects stalls (does not drop).
//==============================================================================
module noc_router #(
    parameter P     = 5,
    parameter WIDTH = 16,
    parameter SRCW  = (P > 1) ? $clog2(P) : 1,
    parameter CW    = 4
)(
    input  logic clk,
    input  logic reset,
    input  logic cfg_clear,

    input  logic [P-1:0]                cfg_en,
    input  logic [P-1:0][SRCW-1:0]      cfg_src,
    input  logic [P-1:0][CW-1:0]        cfg_k,
    input  logic [P-1:0][CW-1:0]        cfg_g,
    input  logic [P-1:0][CW-1:0]        cfg_ph,

    input  logic [P-1:0]                in_valid,
    input  logic [P-1:0]                in_last,
    input  logic [P-1:0][WIDTH-1:0]     in_data,
    output logic [P-1:0]                in_ready,

    output logic [P-1:0]                out_valid,
    output logic [P-1:0]                out_last,
    output logic [P-1:0][WIDTH-1:0]     out_data,
    input  logic [P-1:0]                out_ready
);

    // ---------------- output registers ----------------
    // Each output is a 2-entry elastic buffer (d0 = head, d1 = second). can_load
    // depends only on registers (cnt), never on out_ready, so there is no
    // combinational ready path through the router (required for a mesh: links run
    // in both directions and would otherwise form a structural loop).
    logic [P-1:0][WIDTH-1:0] d0, d1;
    logic [P-1:0]            l0, l1;
    logic [P-1:0][1:0]       cnt;
    logic [P-1:0]            can_load;

    always_comb begin
        for (int o = 0; o < P; o++) begin
            out_valid[o] = (cnt[o] != 2'd0);
            out_data[o]  = d0[o];
            out_last[o]  = l0[o];
            can_load[o]  = (cnt[o] < 2'd2);
        end
    end

    // ---------------- per-output word filter state ----------------
    logic [P-1:0][CW-1:0] g_pos, g_idx;
    logic [P-1:0]         pass;

    always_comb begin
        for (int o = 0; o < P; o++)
            pass[o] = (cfg_k[o] <= CW'(1)) || (g_idx[o] == cfg_ph[o]);
    end

    // ---------------- per-input fork state ----------------
    logic [P-1:0][P-1:0] tmask;      // tmask[i][o]: output o wants input i's current word
    logic [P-1:0][P-1:0] pending;
    logic [P-1:0]        active;
    logic [P-1:0][P-1:0] eff;
    logic [P-1:0][P-1:0] remaining;
    logic [P-1:0]        sel;        // some output selects input i
    logic [P-1:0]        done_w;     // input word completes this cycle

    always_comb begin
        for (int i = 0; i < P; i++) begin
            sel[i] = 1'b0;
            for (int o = 0; o < P; o++) begin
                tmask[i][o] = cfg_en[o] && (int'(cfg_src[o]) == i) && pass[o];
                if (cfg_en[o] && (int'(cfg_src[o]) == i)) sel[i] = 1'b1;
            end
            eff[i]       = active[i] ? pending[i] : tmask[i];
            remaining[i] = eff[i] & ~can_load;
            in_ready[i]  = sel[i] && (remaining[i] == '0);
            done_w[i]    = in_valid[i] && in_ready[i];
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pending <= '0;
            active  <= '0;
        end else if (cfg_clear) begin
            pending <= '0;
            active  <= '0;
        end else begin
            for (int i = 0; i < P; i++) begin
                if (done_w[i]) begin
                    active[i]  <= 1'b0;
                    pending[i] <= '0;
                end else if (in_valid[i] && sel[i]) begin
                    active[i]  <= 1'b1;
                    pending[i] <= remaining[i];
                end
            end
        end
    end

    // ---------------- output stage (2-entry buffers) ----------------
    logic [P-1:0] load_o, pop_o;
    always_comb begin
        for (int o = 0; o < P; o++) begin
            load_o[o] = cfg_en[o] && in_valid[cfg_src[o]] && eff[cfg_src[o]][o] && can_load[o];
            pop_o[o]  = out_valid[o] && out_ready[o];
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt <= '0;
            d0  <= '0;
            d1  <= '0;
            l0  <= '0;
            l1  <= '0;
        end else if (cfg_clear) begin
            cnt <= '0;
        end else begin
            for (int o = 0; o < P; o++) begin
                case ({load_o[o], pop_o[o]})
                    2'b10: begin                       // push only
                        if (cnt[o] == 2'd0) begin
                            d0[o] <= in_data[cfg_src[o]];
                            l0[o] <= in_last[cfg_src[o]];
                            cnt[o] <= 2'd1;
                        end else begin
                            d1[o] <= in_data[cfg_src[o]];
                            l1[o] <= in_last[cfg_src[o]];
                            cnt[o] <= 2'd2;
                        end
                    end
                    2'b01: begin                       // pop only
                        d0[o]  <= d1[o];
                        l0[o]  <= l1[o];
                        cnt[o] <= cnt[o] - 2'd1;
                    end
                    2'b11: begin                       // push and pop (cnt == 1)
                        d0[o] <= in_data[cfg_src[o]];
                        l0[o] <= in_last[cfg_src[o]];
                    end
                    default: ;
                endcase
            end
        end
    end

    // ---------------- word-filter counters ----------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            g_pos <= '0;
            g_idx <= '0;
        end else if (cfg_clear) begin
            g_pos <= '0;
            g_idx <= '0;
        end else begin
            for (int o = 0; o < P; o++) begin
                if (cfg_en[o] && done_w[cfg_src[o]]) begin
                    if (in_last[cfg_src[o]]) begin
                        g_pos[o] <= '0;
                        g_idx[o] <= '0;
                    end else if (cfg_g[o] <= CW'(1) || g_pos[o] == cfg_g[o] - 1'b1) begin
                        g_pos[o] <= '0;
                        g_idx[o] <= (cfg_k[o] <= CW'(1) || g_idx[o] == cfg_k[o] - 1'b1)
                                    ? '0 : g_idx[o] + 1'b1;
                    end else begin
                        g_pos[o] <= g_pos[o] + 1'b1;
                    end
                end
            end
        end
    end

endmodule