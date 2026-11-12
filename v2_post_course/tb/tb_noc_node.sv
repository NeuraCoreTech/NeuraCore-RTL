`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2026
// Design Name: 
// Module Name: tb_noc_node
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: End-to-end testbench for noc_node driven only through the NoC word interface, checked against a golden model.
// 
// Dependencies: noc_node, cluster_top
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// End-to-end TB: noc_node (NI + cluster_top) driven purely through the NoC word interface.
module tb_noc_node;
    localparam ROWS=4, COLS=2, NPE=ROWS*COLS, TAGW=$clog2(NPE), MAXF=24, MAXC=4, MAXE=16, K=3;
    logic clk=0; always #5 clk=~clk;
    logic reset, cfg_we, start, clear, layer_done, tag_err;
    logic [2:0] cfg_addr; logic [15:0] cfg_wdata;
    logic w_valid, w_ready, i_valid, i_ready, pi_valid, pi_ready, po_valid, po_last, po_ready;
    logic [TAGW+7:0] w_data, i_data; logic [TAGW+23:0] pi_data, po_data;
    noc_node #(.PE_ROWS(ROWS), .PE_COLS(COLS)) dut(.*);

    int ifm [ROWS][MAXC*(MAXE+2)]; int flt [ROWS][COLS][MAXF*MAXC*K];
    int ext [COLS][MAXF*MAXE]; int expv [COLS][MAXF*MAXE]; int got [COLS][MAXF*MAXE]; int ngot[COLS]; int lastseen[COLS];
    int fails=0, tests=0;
    int gap;

    // true when every column has delivered nout words (works for any COLS)
    function automatic bit all_got(input int nout);
        for (int c = 0; c < COLS; c++) if (ngot[c] < nout) return 1'b0;
        return 1'b1;
    endfunction

    task automatic cfgw(input int a, input int d);
        @(negedge clk); cfg_we=1; cfg_addr=a; cfg_wdata=d; @(negedge clk); cfg_we=0;
    endtask

    // ordering: 0 = word-major (interleave PEs), 1 = PE-major
    task automatic run(input int nf,nc,E,order,ext_nz, input int ena);
        int W=E+2, nout=nf*E, errs=0, cyc=0;
        int nw = nf*nc*K, ni = nc*W;
        int wpos=0, ipos=0, ppos=0, wtot=NPE*nw, itot=ROWS*ni, ptot=COLS*nout;
        for (int r=0;r<ROWS;r++) for (int i=0;i<ni;i++) ifm[r][i]=$urandom_range(0,255);
        for (int r=0;r<ROWS;r++) for (int c=0;c<COLS;c++) for (int i=0;i<nw;i++) flt[r][c][i]=$urandom_range(0,255);
        for (int c=0;c<COLS;c++) for (int i=0;i<nout;i++) ext[c][i]= ext_nz ? $urandom_range(0,2000):0;
        for (int c=0;c<COLS;c++) for (int x=0;x<E;x++) for (int f=0;f<nf;f++) begin
            int acc=ext[c][x*nf+f];
            for (int r=0;r<ROWS;r++) for (int ch=0;ch<nc;ch++) for (int k=0;k<K;k++) acc += ifm[r][ch*W+x+k]*flt[r][c][(f*nc+ch)*K+k];
            expv[c][x*nf+f]=acc;
        end
        for (int c=0;c<COLS;c++) begin ngot[c]=0; lastseen[c]=0; end
        cfgw(0,nf); cfgw(1,nc); cfgw(2,E); cfgw(3,1); cfgw(4,ena);
        @(negedge clk); clear=1; @(negedge clk); clear=0;
        @(negedge clk); start=1; @(negedge clk); start=0;
        w_valid=0; i_valid=0; pi_valid=0; po_ready=0;
        if (ena) begin
            while ((wpos<wtot || ipos<itot || ppos<ptot || !all_got(nout)) && cyc<400000) begin
                // choose next words
                int wp, wj, ip, ij, pc, pj;
                if (order==0) begin wj=wpos/NPE; wp=wpos%NPE; end else begin wp=wpos/nw; wj=wpos%nw; end
                if (order==0) begin ij=ipos/ROWS; ip=ipos%ROWS; end else begin ip=ipos/ni; ij=ipos%ni; end
                pc=ppos%COLS; pj=ppos/COLS;
                w_valid  = (wpos<wtot) && ($urandom_range(0,99)>=gap);
                w_data   = {TAGW'(wp), 8'(flt[wp/COLS][wp%COLS][wj])};
                i_valid  = (ipos<itot) && ($urandom_range(0,99)>=gap);
                i_data   = {TAGW'(ip), 8'(ifm[ip][ij])};
                pi_valid = (ppos<ptot) && ($urandom_range(0,99)>=gap);
                pi_data  = {TAGW'(pc), 24'(ext[pc][pj])};
                po_ready = ($urandom_range(0,99)>=gap);
                #1;
                if (w_valid && w_ready) wpos++;
                if (i_valid && i_ready) ipos++;
                if (pi_valid && pi_ready) ppos++;
                if (po_valid && po_ready) begin
                    int t = po_data[24 +: TAGW];
                    got[t][ngot[t]] = po_data[23:0]; ngot[t]++;
                    if (po_last) begin if (ngot[t]!=nout) begin errs++; $display("  early last col%0d at %0d",t,ngot[t]); end lastseen[t]++; end
                    else if (ngot[t]==nout) begin errs++; $display("  missing last col%0d",t); end
                end
                @(negedge clk); cyc++;
            end
            w_valid=0; i_valid=0; pi_valid=0; po_ready=0;
            repeat (30) @(negedge clk);
            if (cyc>=400000) begin errs++; $display("  TIMEOUT"); end
            if (!layer_done) begin errs++; $display("  layer_done not asserted"); end
            if (tag_err) begin errs++; $display("  tag_err set"); end
            for (int c=0;c<COLS;c++) begin
                if (ngot[c]!=nout) begin errs++; $display("  col%0d got %0d/%0d",c,ngot[c],nout); end
                else begin
                    if (lastseen[c]!=1) begin errs++; $display("  col%0d last count %0d",c,lastseen[c]); end
                    for (int i=0;i<nout;i++) if (got[c][i]!==expv[c][i]) begin errs++; if (errs<6) $display("  MISMATCH col%0d x%0d f%0d got %0d exp %0d",c,i/nf,i%nf,got[c][i],expv[c][i]); end
                end
            end
        end else begin
            repeat (10) @(negedge clk);
            if (!layer_done) begin errs++; $display("  disabled node must report layer_done"); end
        end
        tests++; if (errs) begin fails++; $display("[FAIL] nf=%0d nc=%0d E=%0d order=%0d ext=%0d ena=%0d gap=%0d",nf,nc,E,order,ext_nz,ena,gap); end
        else $display("[PASS] nf=%0d nc=%0d E=%0d order=%0d ext=%0d ena=%0d gap=%0d",nf,nc,E,order,ext_nz,ena,gap);
        repeat(5) @(negedge clk);
    endtask

    initial begin
        int sd; if ($value$plusargs("seed=%d", sd)) begin int d; d=$urandom(sd); end
        reset=1; cfg_we=0; start=0; clear=0; cfg_addr=0; cfg_wdata=0; w_valid=0; i_valid=0; pi_valid=0; po_ready=0;
        w_data=0; i_data=0; pi_data=0;
        repeat(4) @(negedge clk); reset=0; repeat(2) @(negedge clk);
        for (int g=0; g<3; g++) begin
            gap = g*35;
            run(1,1,1,0,0,1); run(2,1,3,1,0,1); run(4,2,5,0,1,1); run(3,3,8,1,1,1);
            run(24,4,16,0,1,1); run(6,2,16,1,0,1); run(5,4,1,0,1,1); run(8,2,2,0,0,0);
            for (int i=0;i<4;i++) run($urandom_range(1,MAXF),$urandom_range(1,MAXC),$urandom_range(1,MAXE),$urandom_range(0,1),$urandom_range(0,1),1);
        end
        $display("%0d / %0d failed", fails, tests); $finish;
    end
endmodule