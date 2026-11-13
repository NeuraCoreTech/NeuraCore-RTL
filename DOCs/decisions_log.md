# Design decisions log

Format per entry: **Context -> Options -> Decision -> Why -> Evidence -> Status.**

Evidence tags used throughout:

- `[xsim]` verified in Vivado xsim with the real Xilinx MAC IP
- `[verilator]` verified in Verilator with a behavioral model of the IP
- `[synth]` Vivado synthesis report
- `[impl]` post-route implementation data on `xc7a100t-csg324-1` (Vivado 2025.1)
- `[estimate]` reasoning or arithmetic, not measured

A claim without a tag is a description of the design, not a result.

## A. Verification methodology

### A1. Self-checking convolution testbench with a golden model
- Context: the first testbench pulsed `start`, loaded streams, and only checked that
  the output FIFOs were non-empty and not X. It would pass with garbage data.
- Decision: `tb_cluster_conv.sv` computes the expected convolution in the TB
  (per output: psum_in + sum over rows/channels/taps of ifmap x filter) and compares
  every word read from the output FIFOs.
- Why: arithmetic correctness is the product; structure checks are not.
- Evidence: the TB found three real RTL bugs (B1-B3) `[xsim]`. It includes a drain
  hold-on-full coverage gate that fails the suite on zero hits (2,741 hold cycles at 2x2,
  2,768 at 4x2, 0 of 45 tests failing) and per-tile cycle and utilization counters `[xsim]`.
- Details: per-stream valid/ready drivers with random stalls, output back-pressure,
  FIFO-fill test (24 filters, 1 channel, E=16, slow collector), watchdog, back-to-back
  tiles without reset, multi-seed (`+seeds=N +seed0=S +verbose`), tests across nf 1..24,
  nc 1..4, E 1..16.
- Limit: the golden model uses the same stream ordering as the RTL, so it checks the
  array against the interface spec. It is not an independent convolution reference
  (planned: int8 Python model).

### A2. Prove the TB can fail
- The TB was run on the unpatched RTL first. Results matched predictions exactly
  (hazard fingerprint 24/30 instead of 40/52; staggered `pe_done`; sign-error
  signature of exact multiples of 256), which showed the TB detects bugs `[xsim]`.

## B. RTL bugs found and fixed (cluster/PE)

### B1. psum read-after-write hazard (PEControlUnit)
- Problem: loop order x->f->c->k with k innermost re-read psum slot f on
  consecutive cycles, but a MAC result is visible only after the pipeline latency,
  so the result was "last product only". The header comment claimed 12 cycles
  between visits; that was wrong.
- Decision: loop order x->c->k->f (f innermost); pad the f loop to at least
  `MAC_LATENCY+1` cycles with bubble cycles that issue no write-back.
- Why: guarantees same-slot revisit distance >= latency+1 for any nf, without
  stalls or forwarding logic. Cost: a few idle cycles when nf is small.
- Alternatives rejected: forwarding/bypass of in-flight psums (more logic and area),
  stalling the pipeline (lower throughput).
- Status: `[xsim]` passing.

### B2. Cluster `done` never asserted (cluster_ctrl)
- Problem: `&pe_done` needs every PE's one-cycle done pulse in the same cycle, but
  rows finish at different times in chained mode.
- Decision: latch each PE's done (sticky) and advance when all are latched.
- Status: `[xsim]` passing.

### B3. ifmap valid/ready mismatch (cluster_top)
- Problem: valid was broadcast to every PE in a row but ready was the AND of the
  row; an early PE consumed beats the rest had not accepted (skewed loads timed out).
- Decision: gate the per-PE valid with the whole row's ready.
- Evidence: the skewed-load test fails without the gate and passes with it `[xsim]`.

## C. Functional scope

### C1. Dense data only (no sparsity)
- Decision: dense 3x3 convolution, stride 1, no padding (pad upstream).
- Why: the project goal is the NoC; Eyeriss v2's sparse PEs are a separate large effort.
- Consequence: no zero-skipping; ReLU-induced zeros waste MACs but not correctness.
- Not supported: other kernel sizes, stride 2, dilation, depthwise (the psum chain sums
  rows), FC/1x1 only via reshaping with poor reuse. See `Limitations.txt`.

### C2. Unsigned operands, positive-only testing (for now)
- Context: input data is images (unsigned). The Xilinx multiply-add IP is configured
  unsigned; negative weights produced errors that were exact multiples of 256.
- Decision: leave the IP unchanged; test unsigned data only; defer signed weights.
- Planned fix when needed: store `w+128` (unsigned) and subtract `128 x sum(x)`, with the
  sum obtained from one extra all-ones filter in the same tile. `[estimate]`
- Status: unsigned datapath only. The offset trick is planned, not implemented.

### C3. Output-width extension E > 1 (sliding window)
- Problem: the first PE computed one output position per filter, not a convolution.
- Decision: ifmap spad holds a full row per channel (W = E+2 pixels), read address
  `c*W + x + k`; psum slot per output `x*nf + f`; stream and drain order x-major.
  `MAXOFMAP = 16` (a parameter).
- Why: simplest change that gives a real convolution without changing the dataflow.
- Cost: psum spad grew from 24 to 384 entries, which is why area became an issue (D2).
- Status: `[xsim]` passing (E up to 16).

## D. Area and timing optimization (xc7a100t)

### D1. Derive all layer config once per cluster
- Observation: one of four identical PEs reported ~150-290 more LUTs and 17 more FFs.
  The 17 config registers appeared once across the cluster (not four times), i.e. Vivado
  had merged identical per-PE config registers and config-only logic into one PE.
- Decision: register all config and every config-only derived value (totals, last-index
  constants, `nc*3`) once in `cluster_top`; PEs hold no config state.
- Why: makes PE cost uniform and independent of tool merging; removes multipliers
  from every PE.
- Evidence: after the change the four PEs synthesize to 348-358 LUTs `[synth]`.

### D2. Kernel and psum scratchpads in block RAM
- Problem: LUT-RAM scratchpads cost 292 LUTRAM per PE; 64 PEs would use essentially
  all distributed RAM on the device `[estimate]`.
- Decision: sync-read BRAM for kernel and psum spads; ifmap spad stays LUTRAM with
  one alignment register. Effective MAC latency becomes 4 (1 BRAM + 3 IP), so the
  existing hazard padding grows automatically. Drain is pipelined with hold-on-full.
- Evidence: 2x2 cluster 2,649 -> 1,546 LUTs; 8 RAMB18; PE ~350 LUTs `[synth]`.
  Function and hold-on-full back-pressure verified (see A1) `[xsim]`.

### D3. Running address registers in PEControlUnit (timing at 8.0 ns)
- Context: at 100 MHz the controller's address multipliers were not worth touching. At
  8.0 ns the `x*nf + f`, `f*nc3 + c*3 + k` and `c*W + x + k` multipliers formed 9-level
  carry chains into the BRAM address pins: WNS -0.757 ns, TNS -97.3 ns, 433 failing
  endpoints, and the top 49 paths were all scratchpad address pins `[impl]`.
- Decision: replace the three variable multipliers with running stride accumulators
  (`psum_xbase`, `psum_ptr`, `k_ck`, `k_addr`, `i_cbase`, `i_addr`) and register
  `f_real_r`. Ports and `MAC_LATENCY` are unchanged.
- Evidence: all 433 failing endpoints cleared at 8.0 ns (TNS = 0) `[impl]`. Cost: +51 FFs
  per controller (91 -> 142) and about 20 fewer LUTs per controller (291-301 in synthesis
  vs 271-278 routed, so the two figures come from different stages and are approximate)
  `[synth]` `[impl]`. An earlier estimate of 80-120 LUTs saved per PE was wrong.
- Not done: shared BRAM per cluster for output FIFOs (waits for the GLB to define drain);
  synthesis for `xc7z020`.

## E. NoC architecture

### E1. Goal and reference
- Decision: the NoC is the project deliverable; model it on Eyeriss v2's hierarchical
  mesh (separate network per data type, per-layer configurable modes). "Inspired by",
  not a replica: no sparsity, no all-to-all in-cluster network, no GLB clusters yet.

### E2. Three networks (weight, ifmap, psum), circuit-switched, configured per layer
- Why: matches how data types are reused differently; circuit-switched with per-layer
  config is the cheapest design that still supports unicast / broadcast / multicast.
- Open alternative: packet-routed with headers (more flexible, more LUTs).

### E3. Router core is data-agnostic
- Decision: `noc_router` moves opaque words plus a `last` flag; it knows nothing
  about lengths, loop order or PE internals. PE-specific knowledge lives only in the
  node/NI (`noc_node`).
- Why: a PE redesign (even a different dataflow) should not require touching the
  router; only the NI changes if cluster ports change.
- Features: per-output source select (multicast/broadcast), fork rule with a pending
  mask (no loss or duplication under back-pressure), grouped/interleaved multicast
  filters (K, G, PH per output), unconfigured inputs stall instead of dropping.
- Known limits: config must be acyclic at the stream level; group fields are 4 bits
  (parameter).
- Evidence: first version `[verilator]`, 8 scenarios x 6 stall rounds x 25 seeds, 0
  failures. The current version (E3b) was re-verified in xsim `[xsim]`.

### E3b. Router output buffers: 2-entry elastic FIFO
- Problem: the first router version had a combinational ready path (`out_ready ->
  in_ready`). In a mesh whose links run in both directions this forms a structural
  combinational loop even when every legal configuration is acyclic (Verilator
  flagged it as circular logic; Vivado would report a timing loop).
- Decision: each router output is a 2-entry buffer; `can_load` depends only on
  registers, so no ready path crosses a router or a link. Full throughput (one word
  per cycle) is kept.
- Cost: one extra word register per output port, no change to functional behavior.
- Evidence: router TB re-passed `[xsim]`; `check_timing` reports 0 combinational loops
  on the routed design `[impl]`.

### E3c. One source per output: psum results use dedicated result ports
- Limitation: a router output has a single configured source, so it cannot merge
  several streams. Psum results from several clusters therefore cannot share one GLB
  port without arbitration.
- Decision (v0): the psum network gets one dedicated result port per local cluster
  (13 ports per router instead of 9). No arbitration logic.
- Tradeoff: more ports (area) vs. no new router logic and no source-ID tags. A
  merge/arbitration option would reduce ports but needs tagged words and a new
  verification effort.
- Mesh links carry one stream per output per layer, so two clusters cannot send psums
  over the same link in the same layer.

### E4. Two-level hierarchy (clusters and router mesh)
- Decision: a router serves CPR PE clusters via local ports; routers form a MESH_X x
  MESH_Y mesh. Defaults: 2x2 routers x 4 clusters x 4 PEs = 64 PEs.
- Why not a third level: conv traffic is mostly multicast, extra tiers add latency and a
  top-level bottleneck, and this FPGA cannot hold much more than 64 PEs anyway. For
  larger arrays, enlarge the level-2 mesh instead. Eyeriss v2 is also two-level.
- Router group size tradeoff: a full-crossbar router is not slowed by serving more
  clusters; the limits are words per cycle entering the group and mux/ready timing.

### E5. Scaling rules for arbitrary sizes
- Per dimension: PEs = PE_per_cluster x clusters_per_router x routers.
- Non-factorable sizes: pad up and disable spare clusters (enable bit; excluded from the
  done tree). No ragged edge clusters (they would need per-cluster special cases).
- Example: 10x10 with 2x2 clusters = 5x5 clusters, zero waste if the router grouping
  divides 5 (e.g. a flat 5x5 router mesh).
- Status: design rule only; sizes other than the default 2x2 mesh are not exercised
  at the NoC level.

### E6. Node = cluster + NI (`noc_node`)
- Word format: `{tag, payload}`; weight tag = PE index, ifmap tag = row, psum tag =
  column. Words for different PEs/rows/columns may interleave; per-PE order preserved.
- Psum-out merge: round-robin over columns, `last` flagged per column from the config
  (nf*E words), then a 2-entry elastic output buffer (+1 cycle latency).
  `layer_done` = cluster done AND all outputs delivered AND output buffer empty.
- Why the buffer: the combinational handoff from the node to the router limited timing at
  10 ns (see E8).
- Evidence: end-to-end TB through the word interface, interleaved and PE-major orders,
  stalls, disabled node, 2x2, 3x3 and 4x2 clusters `[xsim]`.

### E7. Mesh and top level (`noc_mesh`, `noc_top`)
- `noc_mesh`: one network = MESH_X x MESH_Y `noc_router`s; port map per router:
  local 0..CPR-1, N/S/E/W, then external ports. Edge outputs without a neighbour stall
  (not drop). `HORIZ_ONLY` disables vertical links for the weight network.
- `noc_top`: three meshes + CPR nodes per router; word-addressed config interface
  (net, router, port, field, data) and node config; global `start`, sticky `all_done`
  (AND of node `layer_done`; disabled nodes report done).
- Interleaved multicast is how one GLB stream feeds several clusters with different
  data (weights): word i goes to local output (i/G) % K.
- Evidence: `tb_noc_top` passes (16 clusters, 64 PEs, with a mesh-forwarded ifmap and a
  cross-router psum chain) `[xsim]`.

### E8. Area, timing and optimization results
- **Timing (8.0 ns, 125 MHz):** met in one routed run of the out-of-context
  `noc_impl_top` wrapper: WNS +0.061 ns, WHS +0.025 ns, 0 failing endpoints out of 75,882
  `[impl]`. The wrapper is LFSR-driven with no real I/O or global buffer, and +0.061 ns is
  thin, so this is a measured result for this RTL and strategy, not a guaranteed Fmax.
- **Progression:**
  1. 10.0 ns baseline: WNS +0.133 ns. Worst path 9.550 ns (77% routing) from the `noc_node`
     psum FIFO flags through the `po_last` compare into the router's `l0_reg` and
     `g_idx_reg` enable `[impl]`.
  2. Node elastic output buffer (E6): removed NoC paths from the top 50 critical paths
     (+54 FFs per node, +864 across 16 nodes by arithmetic).
  3. Running address registers (D3) at 8.0 ns: cleared 433 BRAM address setup violations
     (+3,264 FFs across 64 PEs by arithmetic).
  Together these account for the +4,126 FF increase from 17,525 to 21,651 `[impl]`.
- **Current critical path (8.0 ns):** psum-router config registers (`c_src_reg`,
  `c_en_reg`, fanout 76-83) through 6 LUT levels into `g_idx_reg` CE; 7.65 ns data delay,
  83% routing `[impl]`. The start point is static during a layer, so registering the
  decoded per-output select is a candidate fix `[estimate]`; it would touch the verified
  router.
- **Utilization (`u_noc`, 8.0 ns run):** 36,554 LUTs (57.7% of `xc7a100t`), 21,651 FFs,
  128 RAMB18, 64 DSP `[impl]`.
  - Weight mesh (`u_net_w`): 1,712 LUTs, 792 FFs
  - Ifmap mesh (`u_net_i`): 1,888 LUTs, 976 FFs
  - Psum mesh (`u_net_p`): 7,416 LUTs, 3,040 FFs. It dominates the NoC because of the
    dedicated per-cluster result ports and 13-port full crossbars (E3c).
  - `noc_top` config/glue: 942 LUTs
  - Per `noc_node` (16 total): 1,529-1,542 LUTs (`cluster_top` 1,483-1,495 + NI 39-52)
  - The 10.0 ns run reported 37,032 LUTs and 17,525 FFs. The two runs used different
    clock targets, so the 478-LUT difference is not a clean comparison.
- **Methodology notes (intentional warnings):** 128 `SYNTH-6` warnings: BRAM output
  registers are disabled to keep the 1-cycle BRAM read (strict 4-cycle `MAC_LATENCY`).
  80 `SYNTH-9` warnings: address/config math maps to small fabric multipliers so all 64
  DSP48s stay on the datapath MACs.

## F. Evaluation plan and measured cluster utilization

- **Measured (`tb_cluster_conv +verbose`, one cluster, ideal TB drivers) `[xsim]`:**
  - E=16, nf=24, nc=4, chained: 42.9% per-PE MAC utilization (10,745 cycles) at 2 rows,
    22.2% (20,743 cycles) at 4 rows. The cycle ratio is 1.93.
  - E=4, nf=3, nc=2, unchained: 39.1% (184 cycles) at both 2 and 4 rows.
  - Utilization here is useful MAC cycles divided by `start`-to-`done` cycles, so it
    includes load and drain time.
- **Reading:** `PEControlUnit` waits in `PSUM_LOAD` until all `psum_total` words arrive
  from the row below, and each row drains only after its whole compute. Chained rows
  therefore run one after another and per-PE utilization falls roughly as 1/ROWS. A
  2-row chained cluster is capped at 50%, so 42.9% leaves about 7 points of load and
  drain overhead. Overlapping `PSUM_LOAD` with compute would need streamed per-slot
  psums on both sides of the chain; it is not implemented.
- **Throughput:** peak ceiling at 100% MAC duty is 16.0 GOPS (2 x 64 x 125 MHz)
  `[estimate]`. If all 16 clusters sustained the best measured shape at 42.9%, that
  would be about 6.9 GOPS `[estimate]`. NoC delivery and GLB bandwidth are not
  measured, so this is not a system result.
- **Planned baselines:** ARM core (Cortex-A9 on Zynq) running the same layers in int8;
  the design at 1, 4 and 16 clusters; optionally a no-multicast configuration.
- **Planned metrics:** bit-exact match against an int8 reference, latency, GOPS,
  utilization from cycle counters, scaling efficiency, area, GOPS per watt (external
  meter), words moved per network.
- **Planned workloads:** LineCNN_OCR; AlexNet/VGG conv layers via software lowering
  (5x5 split into 3x3 pieces, stride 2 as stride 1 plus discard or polyphase).

## G. Status snapshot

| Item | State |
|---|---|
| Cluster conv (2x2, 3x3, 4x2, 4x4; E<=16, nf<=24, nc<=4) | `[xsim]` pass, with drain hold-on-full coverage gate |
| `noc_router` unit TB | `[xsim]` pass on the 2-entry-buffer version |
| `noc_node` end-to-end TB (2x2, 3x3, 4x2) | `[xsim]` pass, including the output buffer and address-register changes |
| `noc_mesh` / `noc_top` + `tb_noc_top` (16 clusters = 64 PEs) | `[xsim]` pass |
| `noc_top` place and route, 8.0 ns, out-of-context wrapper | Met, single run, thin margin: WNS +0.061 ns, WHS +0.025 ns; 36,554 LUTs, 21,651 FFs, 128 RAMB18, 64 DSP `[impl]` |
| Synthesis or implementation for `xc7z020` | Not done |
| GLB adapters, stream engines, layer sequencer | Not written (GLB is modeled as streams in the TB) |
| Independent int8 reference, board bring-up, benchmarks, power | Not done |

## H. Mapping to the Eyeriss block diagram (Eyeriss v1 chip diagram, for reference)

| Eyeriss block | This project | State |
|---|---|---|
| PE (spad + MAC + control) | `PE_top`, `PEControlUnit`, BRAM spads, Xilinx MAC IP | done, xsim verified |
| PE array (12x14) | `cluster_top` (PE_ROWS x PE_COLS), clusters in `noc_top` (default 64 PEs) | done, xsim verified |
| Filter / ifmap / psum networks between GLB and PE array | `noc_router`, `noc_mesh`, `noc_top` (3 networks, two-level mesh), `noc_node` | done, 8.0 ns met in out-of-context run |
| Config scan chain | word-addressed config registers (router + node) | done (different mechanism, same role) |
| Top-level control | `start` / `all_done` only | layer sequencer not written |
| Global buffer (108 KB) | modeled as streams in the testbench | not written (BRAM banks + stream engines) |
| ReLU, RLC encode/decode, off-chip DRAM + clock crossing | none (dense design, no compression; post-processing in software for now) | not written |

Note: Eyeriss v1 uses a flat multicast network; this design follows the hierarchical
mesh ideas of Eyeriss v2 instead.
