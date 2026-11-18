`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_noc_top
// Project Name: Eyeriss-style CNN accelerator with hierarchical NoC
// Target Devices: Xilinx 7-series
// Tool Versions: Vivado 2025.1
// Description: System testbench for noc_top (2x2 router mesh, 4 clusters per router).
//              Drives only the GLB-side streams, configures routers/nodes through the
//              config interface, and checks every result word of every cluster
//              against a golden convolution.
// 
// Dependencies: noc_top
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// Scenarios (per test):
//   mode 0 : every router has its own ifmap stream (ncl clusters share it)
//   mode 1 : one ifmap stream enters at router 0 and is forwarded over the
//            mesh (E, then S; and S) to all 16 clusters (multi-hop multicast)
//   mode 2 : split tiles - each router broadcasts one filter set to its ncl
//            clusters, and each cluster gets its own ifmap (interleaved K=ncl)
//   chain  : cluster 0 of router 0 feeds its psum results over the mesh (S link)
//            into the psum-in of cluster 0 of router 2 (cross-router accumulate)
// Hard-wired to a 2x2 router mesh for the forwarding configs (mode 1 / chain).
//==============================================================================
module tb_noc_top_perf;
    localparam MX = 2, MY = 2, CPR = 4;
    localparam ROWS = 2, COLS = 2;
    localparam R   = MX * MY;
    localparam NN  = R * CPR;
    localparam NPE = ROWS * COLS;
    localparam TAGW = (NPE > 1) ? $clog2(NPE) : 1;
    localparam DW = 8, PW = 24;
    localparam LW = TAGW + DW, LP = TAGW + PW;
    localparam K = 3, MAXF = 24, MAXC = 4, MAXE = 16;
    localparam MAXLEN = 8192, MAXOUT = COLS * MAXF * MAXE;
    localparam RIDW = (R > 1) ? $clog2(R) : 1;
    localparam PMAX = 2 * CPR + 5;
    localparam PIDW = $clog2(PMAX);
    localparam NIDW = (NN > 1) ? $clog2(NN) : 1;
    // port numbers (see noc_top)
    localparam PN = CPR, PSS = CPR + 1, PEE = CPR + 2, PWW = CPR + 3;
    localparam GLB = CPR + 4, GLBP = 2 * CPR + 4;
    localparam TIMEOUT = 400000;

    logic clk = 0; always #5 clk = ~clk;
    logic reset;
    logic rcfg_we, rcfg_clear; logic [1:0] rcfg_net; logic [RIDW-1:0] rcfg_router;
    logic [PIDW-1:0] rcfg_port; logic [2:0] rcfg_field; logic [15:0] rcfg_data;
    logic ncfg_we, ncfg_bcast; logic [NIDW-1:0] ncfg_node; logic [2:0] ncfg_addr; logic [15:0] ncfg_data;
    logic start, clear, all_done, tag_err_any;
    logic [R-1:0] glbw_valid, glbw_last, glbw_ready;  logic [R-1:0][LW-1:0] glbw_data;
    logic [R-1:0] glbi_valid, glbi_last, glbi_ready;  logic [R-1:0][LW-1:0] glbi_data;
    logic [R-1:0] glbp_in_valid, glbp_in_last, glbp_in_ready; logic [R-1:0][LP-1:0] glbp_in_data;
    logic [R-1:0][CPR-1:0] glbp_out_valid, glbp_out_last, glbp_out_ready;
    logic [R-1:0][CPR-1:0][LP-1:0] glbp_out_data;

    noc_top #(.MESH_X(MX), .MESH_Y(MY), .CPR(CPR), .PE_ROWS(ROWS), .PE_COLS(COLS)) dut (.*);

    // ---------------- stimulus / model storage ----------------
    logic [DW-1:0] flt [NN][NPE][MAXF*MAXC*K];
    logic [DW-1:0] ifm [NN][ROWS][MAXC*(MAXE+K-1)];
    logic [PW-1:0] ext [NN][COLS][MAXF*MAXE];
    int            expv[NN][COLS][MAXF*MAXE];

    logic [LP-1:0] s_w [3*R][MAXLEN];
    bit            s_l [3*R][MAXLEN];
    int            s_n [3*R];
    int            s_pos [3*R];
    bit            s_v [3*R];
    int            cpos [NN][COLS];
    int            rx_n [NN];
    int            rx_last [NN][COLS];
    int            gap_src, gap_snk;
    int            fails = 0, tests = 0;
    int            errs_run;
    int            ncl = CPR;            // active clusters per router (sweep knob)
    
    // ---------------- perf counters ----------------
    int  cyc_now = 0;  always @(posedge clk) cyc_now <= cyc_now + 1;
    bit  meas = 0, done_cap = 0;
    int  t_start, t_end;
    int  pe_mac_cyc;                 // sum over PEs of cycles issuing a useful MAC
    int  ph_lo [8], ph_hi [8];       // cycles per PEControlUnit state: row 0 / top row of node 0
    int  w_inj, i_inj, p_inj, w_dlv, i_dlv, p_dlv, p_out;
    
    logic [NN*NPE-1:0] mac_v;
    logic [2:0]        st_lo, st_hi;
    genvar ng, pr, pc;
    generate
      for (ng = 0; ng < NN; ng++) begin : g_mac
        for (pr = 0; pr < ROWS; pr++) begin : g_r
          for (pc = 0; pc < COLS; pc++) begin : g_c
            assign mac_v[ng*NPE + pr*COLS + pc] =
              dut.g_r[ng/CPR].g_k[ng%CPR].u_node.u_cluster.gen_pe_row[pr].gen_pe_col[pc].u_pe.u_ctrl.v_tag[0];
          end
        end
      end
    endgenerate
    assign st_lo = dut.g_r[0].g_k[0].u_node.u_cluster.gen_pe_row[0].gen_pe_col[0].u_pe.u_ctrl.state;
    assign st_hi = dut.g_r[0].g_k[0].u_node.u_cluster.gen_pe_row[ROWS-1].gen_pe_col[0].u_pe.u_ctrl.state;
    
    always @(posedge clk) if (meas) begin
        if (!done_cap) t_end = cyc_now;
        if (all_done)  done_cap <= 1;
        if (!done_cap) begin
            pe_mac_cyc += $countones(mac_v);
            ph_lo[st_lo]++; ph_hi[st_hi]++;
            for (int r = 0; r < R; r++) begin
                if (glbw_valid[r]    && glbw_ready[r])    w_inj++;
                if (glbi_valid[r]    && glbi_ready[r])    i_inj++;
                if (glbp_in_valid[r] && glbp_in_ready[r]) p_inj++;
                for (int k = 0; k < CPR; k++) begin
                    if (dut.w_lo_valid[r][k] && dut.w_lo_ready[r][k]) w_dlv++;
                    if (dut.i_lo_valid[r][k] && dut.i_lo_ready[r][k]) i_dlv++;
                    if (dut.p_lo_valid[r][k] && dut.p_lo_ready[r][k]) p_dlv++;
                    if (glbp_out_valid[r][k] && glbp_out_ready[r][k]) p_out++;
                end
            end
        end
    end
    
    task automatic perf_arm();
        pe_mac_cyc = 0; w_inj = 0; i_inj = 0; p_inj = 0; w_dlv = 0; i_dlv = 0; p_dlv = 0; p_out = 0;
        for (int s = 0; s < 8; s++) begin ph_lo[s] = 0; ph_hi[s] = 0; end
        done_cap = 0; meas = 1; t_start = cyc_now; t_end = cyc_now;
    endtask

    // ---------------- helpers ----------------
    function automatic longint conv0(input int g, input int col, input int x, input int f,
                                     input int nc, input int E, input int mode);
        longint acc = 0;
        int W = E + K - 1;
        int isr = (mode == 0) ? ((g / CPR) * CPR) : (mode == 2) ? g : 0;
        for (int row = 0; row < ROWS; row++)
            for (int ch = 0; ch < nc; ch++)
                for (int k = 0; k < K; k++)
                    acc += longint'(ifm[isr][row][ch*W + x + k]) *
                           longint'(flt[g][row*COLS + col][(f*nc + ch)*K + k]);
        return acc;
    endfunction

    task automatic gen_data(input int nf, input int nc, input int E, input int mode);
        int W = E + K - 1;
        for (int r = 0; r < NN; r++)
            for (int row = 0; row < ROWS; row++)
                for (int i = 0; i < nc*W; i++) ifm[r][row][i] = $urandom_range(0, 255);
        for (int g = 0; g < NN; g++) begin
            for (int p = 0; p < NPE; p++)
                for (int i = 0; i < nf*nc*K; i++) flt[g][p][i] = $urandom_range(0, 255);
            for (int c = 0; c < COLS; c++)
                for (int i = 0; i < nf*E; i++) ext[g][c][i] = $urandom_range(0, 2000);
        end
        if (mode == 2)                                      // filters shared within a router
            for (int g = 0; g < NN; g++)
                for (int p = 0; p < NPE; p++)
                    for (int i = 0; i < nf*nc*K; i++) flt[g][p][i] = flt[(g/CPR)*CPR][p][i];
    endtask

    task automatic compute_expected(input int nf, input int nc, input int E, input int mode, input bit chain);
        for (int g = 0; g < NN; g++)
            for (int c = 0; c < COLS; c++)
                for (int x = 0; x < E; x++)
                    for (int f = 0; f < nf; f++) begin
                        longint base;
                        if (chain && g == 2*CPR) base = longint'(expv[0][c][x*nf+f]);   // fed by cluster 0
                        else                     base = longint'(ext[g][c][x*nf+f]);
                        expv[g][c][x*nf+f] = int'((base + conv0(g, c, x, f, nc, E, mode)) & ((1 << PW) - 1));
                    end
    endtask

    task automatic build_streams(input int nf, input int nc, input int E, input int mode, input bit chain);
        int nw = nf*nc*K, nout = nf*E, W = E + K - 1, ni = nc*W;
        for (int s = 0; s < 3*R; s++) begin s_n[s] = 0; s_pos[s] = 0; s_v[s] = 0; end
        for (int r = 0; r < R; r++) begin
            // weight stream
            int len = (mode == 2) ? NPE*nw : ncl*NPE*nw;
            for (int j = 0; j < len; j++) begin
                if (mode == 2) begin
                    int pe = j % NPE, idx = j / NPE;
                    s_w[r][j] = {TAGW'(pe), flt[r*CPR][pe][idx]};
                end else begin
                    int k = j % ncl, m = j / ncl, pe = m % NPE, idx = m / NPE;
                    s_w[r][j] = {TAGW'(pe), flt[r*CPR + k][pe][idx]};
                end
                s_l[r][j] = (j == len - 1);
            end
            s_n[r] = len;
            // ifmap stream
            if (mode != 1 || r == 0) begin
                int ilen = (mode == 2) ? ncl*ROWS*ni : ROWS*ni;
                for (int j = 0; j < ilen; j++) begin
                    if (mode == 2) begin
                        int k = j % ncl, m = j / ncl, idx = m / ROWS, row = m % ROWS;
                        s_w[R + r][j] = {TAGW'(row), ifm[r*CPR + k][row][idx]};
                    end else begin
                        int idx = j / ROWS, row = j % ROWS, isr = (mode == 0) ? r*CPR : 0;
                        s_w[R + r][j] = {TAGW'(row), ifm[isr][row][idx]};
                    end
                    s_l[R + r][j] = (j == ilen - 1);
                end
                s_n[R + r] = ilen;
            end
            // psum preload stream (cluster 0 of router 2 is fed by the mesh in chain mode)
            begin
                int cnt = (chain && r == 2) ? 3 : ncl;
                int first = (chain && r == 2) ? 1 : 0;
                int plen = cnt*COLS*nout;
                for (int j = 0; j < plen; j++) begin
                    int pos = j % cnt, m = j / cnt, col = m % COLS, i = m / COLS;
                    int g = r*CPR + first + pos;
                    s_w[2*R + r][j] = {TAGW'(col), ext[g][col][i]};
                    s_l[2*R + r][j] = (j == plen - 1);
                end
                s_n[2*R + r] = plen;
            end
        end
    endtask

    // ---------------- config ----------------
    task automatic rcfg1(input int net, input int r, input int port, input int field, input int data);
        @(negedge clk);
        rcfg_we = 1; rcfg_net = net; rcfg_router = r; rcfg_port = port; rcfg_field = field; rcfg_data = data;
        @(negedge clk); rcfg_we = 0;
    endtask
    task automatic rport(input int net, input int r, input int port, input int en, input int src,
                         input int k, input int g, input int ph);
        rcfg1(net, r, port, 0, en); rcfg1(net, r, port, 1, src);
        rcfg1(net, r, port, 2, k);  rcfg1(net, r, port, 3, g); rcfg1(net, r, port, 4, ph);
    endtask
    task automatic ncfg1(input int addr, input int data);
        @(negedge clk); ncfg_we = 1; ncfg_bcast = 1; ncfg_node = 0; ncfg_addr = addr; ncfg_data = data;
        @(negedge clk); ncfg_we = 0; ncfg_bcast = 0;
    endtask
    task automatic ncfg_one(input int node, input int addr, input int data);
        @(negedge clk); ncfg_we = 1; ncfg_bcast = 0; ncfg_node = node; ncfg_addr = addr; ncfg_data = data;
        @(negedge clk); ncfg_we = 0;
    endtask

    task automatic configure(input int nf, input int nc, input int E, input int mode, input bit chain);
        @(negedge clk); rcfg_clear = 1; @(negedge clk); rcfg_clear = 0;
        for (int r = 0; r < R; r++)
            for (int k = 0; k < ncl; k++) begin
                // weights
                if (mode == 2) rport(0, r, k, 1, GLB, 0,   0, 0);     // broadcast to active clusters
                else           rport(0, r, k, 1, GLB, ncl, 1, k);     // interleaved unicast
                // ifmap
                if (mode == 2)      rport(1, r, k, 1, GLB, ncl, 1, k);
                else if (mode == 0) rport(1, r, k, 1, GLB, 0, 0, 0);
                else                rport(1, r, k, 1, (r == 0) ? GLB : (r == 1) ? PWW : PN, 0, 0, 0);
                // psum results: dedicated result port per cluster
                rport(2, r, CPR + 4 + k, 1, k, 0, 0, 0);
                // psum preload into the node
                if (chain && r == 2 && k == 0)
                    rport(2, r, 0, 1, PN, 0, 0, 0);
                else begin
                    int cnt = (chain && r == 2) ? 3 : ncl;
                    int ph  = (chain && r == 2) ? (k - 1) : k;
                    rport(2, r, k, 1, GLBP, cnt, 1, ph);
                end
            end
        if (mode == 1) begin
            rport(1, 0, PEE, 1, GLB, 0, 0, 0);    // router 0 forwards ifmap east
            rport(1, 0, PSS, 1, GLB, 0, 0, 0);    // and south
            rport(1, 1, PSS, 1, PWW, 0, 0, 0);    // router 1 forwards it south (to router 3)
        end
        if (chain) rport(2, 0, PSS, 1, 0, 0, 0, 0);   // router 0 south link <- local port 0
        ncfg1(0, nf); ncfg1(1, nc); ncfg1(2, E); ncfg1(3, 1); ncfg1(4, 1);
        for (int g = 0; g < NN; g++) if ((g % CPR) < ncl) ; else ncfg_one(g, 4, 0);   // disable spare nodes
    endtask

    // ---------------- streams ----------------
    task automatic drive_src(input int sid);
        int net = sid / R, r = sid % R;
        int p = (s_pos[sid] < s_n[sid]) ? s_pos[sid] : 0;
        case (net)
            0: begin glbw_valid[r] = s_v[sid]; glbw_data[r] = s_w[sid][p][LW-1:0]; glbw_last[r] = s_l[sid][p]; end
            1: begin glbi_valid[r] = s_v[sid]; glbi_data[r] = s_w[sid][p][LW-1:0]; glbi_last[r] = s_l[sid][p]; end
            default: begin glbp_in_valid[r] = s_v[sid]; glbp_in_data[r] = s_w[sid][p]; glbp_in_last[r] = s_l[sid][p]; end
        endcase
    endtask
    function automatic bit src_ready(input int sid);
        int net = sid / R, r = sid % R;
        case (net)
            0: return glbw_ready[r];
            1: return glbi_ready[r];
            default: return glbp_in_ready[r];
        endcase
    endfunction

    task automatic run(input string name, input int nf, input int nc, input int E,
                       input int mode, input bit chain);
        int nout = nf*E, cyc = 0;
        bit finished;
        real lay, util, gops;
        errs_run = 0;
        gen_data(nf, nc, E, mode);
        compute_expected(nf, nc, E, mode, chain);
        build_streams(nf, nc, E, mode, chain);
        for (int g = 0; g < NN; g++) begin
            rx_n[g] = 0;
            for (int c = 0; c < COLS; c++) begin cpos[g][c] = 0; rx_last[g][c] = 0; end
        end
        configure(nf, nc, E, mode, chain);
        @(negedge clk); clear = 1; @(negedge clk); clear = 0;
        perf_arm();
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        tests++;

        do begin
            for (int sid = 0; sid < 3*R; sid++) begin
                if (s_pos[sid] < s_n[sid]) begin
                    if (!s_v[sid]) s_v[sid] = ($urandom_range(0, 99) >= gap_src);
                end else s_v[sid] = 0;
                drive_src(sid);
            end
            for (int r = 0; r < R; r++)
                for (int e = 0; e < CPR; e++) glbp_out_ready[r][e] = ($urandom_range(0, 99) >= gap_snk);
            #1;
            for (int sid = 0; sid < 3*R; sid++)
                if (s_v[sid] && src_ready(sid)) begin s_pos[sid]++; s_v[sid] = 0; end
            for (int r = 0; r < R; r++)
                for (int e = 0; e < CPR; e++)
                    if (glbp_out_valid[r][e] && glbp_out_ready[r][e]) begin
                        int g = r*CPR + e;
                        int col = int'(glbp_out_data[r][e][PW +: TAGW]);
                        if (col >= COLS) begin
                            errs_run++; $display("  cluster %0d: bad column tag %0d", g, col);
                        end else begin
                            int p = cpos[g][col];
                            if (p >= nout) begin
                                errs_run++; if (errs_run < 8) $display("  cluster %0d col %0d: extra word", g, col);
                            end else begin
                                if (glbp_out_data[r][e][PW-1:0] !== PW'(expv[g][col][p])) begin
                                    errs_run++;
                                    if (errs_run < 8)
                                        $display("  MISMATCH cluster %0d col %0d x%0d f%0d: got %0d exp %0d", g, col,
                                                 p/nf, p%nf, glbp_out_data[r][e][PW-1:0], PW'(expv[g][col][p]));
                                end
                                if (glbp_out_last[r][e] != (p == nout - 1)) begin
                                    errs_run++; if (errs_run < 8) $display("  cluster %0d col %0d: wrong last at word %0d", g, col, p);
                                end
                                if (glbp_out_last[r][e]) rx_last[g][col]++;
                            end
                            cpos[g][col]++; rx_n[g]++;
                        end
                    end
            @(negedge clk); cyc++;
            finished = 1;
            for (int sid = 0; sid < 3*R; sid++) if (s_pos[sid] < s_n[sid]) finished = 0;
            for (int g = 0; g < NN; g++) if ((g % CPR) < ncl && rx_n[g] < COLS*nout) finished = 0;
        end while (!finished && cyc < TIMEOUT);

        for (int sid = 0; sid < 3*R; sid++) begin
            s_v[sid] = 0; drive_src(sid);
        end
        glbp_out_ready = '1;
        repeat (40) @(negedge clk);
        if (cyc >= TIMEOUT) begin errs_run++; $display("  TIMEOUT"); end
        if (!all_done)      begin errs_run++; $display("  all_done not asserted"); end
        if (tag_err_any)    begin errs_run++; $display("  tag_err set"); end
        for (int g = 0; g < NN; g++) begin
            if ((g % CPR) < ncl) begin
                if (rx_n[g] != COLS*nout) begin errs_run++; if (errs_run < 8) $display("  cluster %0d got %0d/%0d words", g, rx_n[g], COLS*nout); end
                for (int c = 0; c < COLS; c++)
                    if (rx_last[g][c] != 1) begin errs_run++; if (errs_run < 8) $display("  cluster %0d col %0d: last count %0d", g, c, rx_last[g][c]); end
            end
        end

        lay  = real'(t_end - t_start);
        util = (lay > 0.0) ? 100.0 * real'(pe_mac_cyc) / (real'(R*ncl*NPE) * lay) : 0.0;
       gops = (lay > 0.0) ? 2.0 * real'(pe_mac_cyc) / (lay * 8.0) : 0.0; // 125 MHz, ideal GLB
        if (pe_mac_cyc != R*ncl*NPE*nf*nc*K*E) begin
            errs_run++;
            $display("  MAC count %0d != expected %0d", pe_mac_cyc, R*ncl*NPE*nf*nc*K*E);
        end
        if (gap_src == 0 && gap_snk == 0)
            $display("  PERF mode=%0d ncl=%0d cyc=%0.0f util=%0.1f%% GOPS=%0.2f | row0 fl/if/ps/cmp/drn=%0d/%0d/%0d/%0d/%0d | top fl/if/ps/cmp/drn=%0d/%0d/%0d/%0d/%0d | words w/i/p inj=%0d/%0d/%0d dlv=%0d/%0d/%0d out=%0d",
                mode, ncl, lay, util, gops,
                ph_lo[1], ph_lo[2], ph_lo[3], ph_lo[4], ph_lo[5],
                ph_hi[1], ph_hi[2], ph_hi[3], ph_hi[4], ph_hi[5],
                w_inj, i_inj, p_inj, w_dlv, i_dlv, p_dlv, p_out);

        if (errs_run == 0) $display("[PASS] %s  (nf=%0d nc=%0d E=%0d mode=%0d chain=%0d gap=%0d/%0d)", name, nf, nc, E, mode, chain, gap_src, gap_snk);
        else begin fails++; $display("[FAIL] %s  (nf=%0d nc=%0d E=%0d mode=%0d chain=%0d gap=%0d/%0d)  %0d error(s)", name, nf, nc, E, mode, chain, gap_src, gap_snk, errs_run); end
        repeat (5) @(negedge clk);
    endtask

    initial begin
        int sd, dmy;
        if ($value$plusargs("seed=%d", sd)) begin dmy = $urandom(sd); $display("seed %0d", sd); end
        reset = 1; rcfg_we = 0; rcfg_clear = 0; rcfg_net = 0; rcfg_router = 0; rcfg_port = 0; rcfg_field = 0; rcfg_data = 0;
        ncfg_we = 0; ncfg_bcast = 0; ncfg_node = 0; ncfg_addr = 0; ncfg_data = 0; start = 0; clear = 0;
        glbw_valid = '0; glbw_last = '0; glbw_data = '0; glbi_valid = '0; glbi_last = '0; glbi_data = '0;
        glbp_in_valid = '0; glbp_in_last = '0; glbp_in_data = '0; glbp_out_ready = '0;
        repeat (4) @(negedge clk); reset = 0; repeat (2) @(negedge clk);

        for (int g = 0; g < 2; g++) begin
            gap_src = g * 40; gap_snk = g * 40;
            run("per-router ifmap, tiny",              1, 1, 1, 0, 0);
            run("per-router ifmap",                    2, 1, 3, 0, 0);
            run("per-router ifmap, multi-channel",     4, 2, 5, 0, 0);
            run("ifmap multicast over mesh",           3, 3, 8, 1, 0);
            run("ifmap multicast over mesh, wide",     6, 2, 4, 1, 0);
            run("psum chain across routers",           2, 2, 3, 0, 1);
            run("mesh ifmap multicast + psum chain",   3, 1, 4, 1, 1);
        end

        gap_src = 0; gap_snk = 0;
        run("PERF max tile, per-router ifmap", 24, 4, 16, 0, 0);
        run("PERF max tile, mesh ifmap",       24, 4, 16, 1, 0);
        run("PERF mid tile",                    8, 2,  8, 0, 0);
        run("PERF small tile",                  2, 1,  3, 0, 0);
        run("PERF split-tiles max tile (weight bcast)", 24, 4, 16, 2, 0);
        for (int n = 1; n <= CPR; n *= 2) begin
            ncl = n;
            run("SWEEP unicast weights", 24, 4, 16, 0, 0);
            run("SWEEP bcast weights",   24, 4, 16, 2, 0);
        end
        ncl = CPR;

        $display("\n%0d / %0d tests failed", fails, tests);
        if (fails == 0) $display("NOC TOP TEST PASSED"); else $display("NOC TOP TEST FAILED");
        $finish;
    end
endmodule
