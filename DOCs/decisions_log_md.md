# Design decisions log

Format per entry: **Context -> Options -> Decision -> Why -> Evidence -> Status.**
Evidence tags: `[xsim]` verified in Vivado xsim with the real Xilinx MAC IP,
`[verilator]` verified in Verilator with my behavioral IP model,
`[synth]` Vivado synthesis report, `[impl]` post-route implementation data on xc7a100t, `[estimate]` my reasoning, not measured.
Be precise about these tags when talking about the project.

## 0. Project Origin Context
- **Context:** The repository has origins as a university group course project (`rtl/V1.0/`).
- **Decision:** Clarify that the university group project provided only the basic, unverified RTL skeleton of `PE_top`, `PEControlUnit`, and `cluster_top`.
- **Status:** Everything beyond that (`v2_post_course/`)—including golden-model verification (`tb_cluster_conv`, `tb_noc_*`), critical RTL bug fixes (`B1–B3`), BRAM scratchpad migration (`D2`), the 3-network hierarchical NoC (64 PEs), and 125 MHz post-route timing closure (`[impl]`)—was designed and completed independently post-course.

## A. Verification methodology

### A1. Self-checking convolution testbench with a golden model
- Context: the first testbench pulsed `start`, loaded streams, and only checked that
  the output FIFOs were non-empty and not X. It would pass with garbage data.
- Decision: `tb_cluster_conv.sv` computes the expected convolution in the TB
  (per output: psum_in + sum over rows/channels/taps of ifmap x filter) and compares
  every word read from the output FIFOs.
- Why: arithmetic correctness is the product; structure checks are not.
- Evidence: found three real RTL bugs (B1-B3); includes a drain hold-on-full coverage
  gate (`2,741` cycles hit at `2x2`, `2,768` cycles hit at `4x2`, `0 / 45` failures) and
  per-tile cycle/utilization counters `[xsim]`.
- Details: per-stream valid/ready drivers with random stalls, output back-pressure,
  FIFO-fill test (`24f/1c/E=16`, `gap_out=8`), watchdog, back-to-back tiles without reset,
  multi-seed (`+seeds=N +seed0=S +verbose`), tests across nf 1..24, nc 1..4, E 1..16.

### A2. Prove the TB can fail
- The TB was run on the unpatched RTL first. Results matched predictions exactly
  (hazard fingerprint 24/30 instead of 40/52; staggered `pe_done`; sign-error
  signature of exact multiples of 256), which is what showed the TB detects bugs.

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
- Evidence: the skewed-load test fails without the gate and passes with it. `[xsim]`

## C. Functional scope

### C1. Dense data only (no sparsity)
- Decision: dense 3x3 convolution, stride 1, no padding (pad upstream).
- Why: the project goal is the NoC; Eyeriss v2's sparse PEs are a separate large effort.
- Consequence: no zero-skipping; ReLU-induced zeros waste MACs but not correctness.
- Not supported: other kernel sizes, stride 2, dilation, depthwise (psum chain sums
  rows), FC/1x1 only via reshaping with poor reuse.

### C2. Unsigned operands, positive-only testing (for now)
- Context: input data is images (unsigned). The Xilinx multiply-add IP was configured
  unsigned; negative weights produced errors that were exact multiples of 256.
- Decision: leave the IP unchanged; test positive/unsigned only; defer signed weights.
- Planned fix when needed: store `w+128` (unsigned) and subtract `128 x sum(x)`,
  with the sum obtained from one extra all-ones filter in the same tile. `[estimate]`
- Interview note: say "unsigned datapath, signed weights via offset trick is planned,
  not implemented".

### C3. Output-width extension E > 1 (sliding window)
- Problem: the first PE computed one output position per filter, not a convolution.
- Decision: ifmap spad holds a full row per channel (W = E+2 pixels), read address
  `c*W + x + k`; psum slot per output `x*nf + f`; stream and drain order x-major.
  `MAXOFMAP = 16` (a parameter).
- Why: simplest change that gives a real convolution without changing the dataflow.
- Cost: psum spad grew from 24 to 384 entries, which is why area became an issue (D1-D3).
- Status: `[xsim]` passing (E up to 16).

## D. Area & timing optimization (synthesis & implementation on xc7a100t)

### D1. Derive all layer config once per cluster
- Observation: one of four identical PEs reported ~150-290 more LUTs and 17 more FFs.
  Count of the 17 config registers across the cluster = 17 (not 68), i.e. Vivado had
  merged identical per-PE config registers and config-only logic into one PE.
- Decision: register all config and every config-only derived value (totals, last-index
  constants, `nc*3`) once in `cluster_top`; PEs hold no config state.
- Why: makes PE cost uniform and independent of tool merging; removes multipliers
  from every PE.
- Evidence: after the change the four PEs synthesize to 348-358 LUTs. `[synth]`

### D2. Kernel and psum scratchpads in block RAM
- Problem: LUT-RAM scratchpads cost 292 LUTRAM per PE; 64 PEs would use essentially
  all distributed RAM on a Zynq-7020 `[estimate]`.
- Decision: sync-read BRAM for kernel and psum spads; ifmap spad stays LUTRAM with
  one alignment register. Effective MAC latency becomes 4 (1 BRAM + 3 IP) so the
  existing hazard padding grows automatically. Drain pipelined with hold-on-full.
- Evidence: cluster 2x2: 2649 -> 1546 LUTs; 8 RAMB18; PE ~350 LUTs `[synth]`.
  Functional and hold-on-full back-pressure verified (`2,741` hold cycles at `2x2`,
  `2,768` at `4x2`, `0 / 45` failures) `[xsim]`.

### D3. Running address registers in PEControlUnit (125 MHz Timing Closure)
- Context: Originally deferred at 100 MHz (`~350` LUTs/PE fit easily). When tightening the clock target to `8.0 ns` (`125 MHz`), the `x*nf + f`, `f*nc3 + c*3 + k`, and `c*W + x + k` multipliers created 9-level CARRY4 chains into BRAM address pins (`WNS -0.757 ns`, `TNS -97.3 ns`, `433` failing endpoints) `[impl]`.
- Decision: Replaced all three variable multipliers in `PEControlUnit` with running stride accumulators (`psum_xbase`, `psum_ptr`, `k_ck`, `k_addr`, `i_cbase`, `i_addr`) and registered `f_real_r`.
- Evidence: Eliminated all 433 failing endpoints at `8.0 ns` (`TNS = 0`), reduced controller LUTs by ~20 per PE (`291–301` synth -> `271–278` routed), and added `51` FFs per PE (`91 -> 142` FFs) `[impl]`.
- Deferred: Shared BRAM per cluster for output FIFOs (deferred until GLB defines drain); PYNQ-Z2 (`xc7z020`) synthesis not yet run.

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
  mask (no loss/duplication under back-pressure), grouped/interleaved multicast
  filters (K, G, PH per output), unconfigured inputs stall instead of dropping.
- Known limits: combinational ready path through each router; config must be acyclic;
  group fields are 4 bits (parameter).
- Evidence: `[verilator]` unit TB, 8 scenarios x 6 stall rounds x 25 seeds, 0 failures.

### E3b. Router output buffers: 2-entry elastic FIFO
- Problem: the first router version had a combinational ready path (`out_ready ->
  in_ready`). In a mesh whose links run in both directions this forms a structural
  combinational loop even when every legal configuration is acyclic (Verilator
  flagged it as circular logic; Vivado would report a timing loop).
- Decision: each router output is a 2-entry buffer; `can_load` depends only on
  registers, so no ready path crosses a router or a link. Full throughput (one word
  per cycle) is kept.
- Cost: one extra word register per output port (area) and no change to functional
  behavior. Router unit TB re-passed in Verilator (10 seeds) and xsim. `[xsim]`

### E3c. One source per output: psum results use dedicated result ports
- Limitation: a router output has a single configured source, so it cannot merge
  several streams. Psum results from several clusters therefore cannot share one GLB
  port without arbitration.
- Decision (v0): the psum network gets one dedicated result port per local cluster
  (P net ports = 2*CPR+5 vs CPR+5 for weight/ifmap). No arbitration logic.
- Tradeoff: more ports (area) vs. no new router logic and no source-ID tags. A
  merge/arbitration option would reduce ports but needs tagged words and a new
  verification effort.
- Mesh links carry one stream per output per layer, so two clusters cannot send psums
  over the same link in the same layer.

### E4. Two-level hierarchy (clusters and router mesh)
- Decision: router serves CPR PE clusters via local ports; routers form a MESH_X x
  MESH_Y mesh. Defaults 2x2 routers x 4 clusters x 4 PEs = 64 PEs. Matches the
  project's block diagram.
- Why not a third level: conv traffic is mostly multicast, extra tiers add latency and a
  top-level bottleneck, and this FPGA cannot hold more than ~64 PEs anyway. For larger
  arrays, enlarge the level-2 mesh instead. Eyeriss v2 is also two-level.
- Router group size tradeoff: a full-crossbar router is not slowed by serving more
  clusters; the limits are words per cycle entering the group and mux/ready timing.

### E5. Scaling rules for arbitrary sizes
- Per dimension: PEs = PE_per_cluster x clusters_per_router x routers.
- Non-factorable sizes: pad up and disable spare clusters (enable bit; excluded from the
  done tree). No ragged edge clusters (would need per-cluster special cases).
- Example: 10x10 with 2x2 clusters = 5x5 clusters, zero waste if the router grouping
  divides 5 (e.g. a flat 5x5 router mesh).

### E6. Node = cluster + NI (`noc_node`)
- Word format: `{tag, payload}`; weight tag = PE index, ifmap tag = row, psum tag =
  column. Words for different PEs/rows/columns may interleave; per-PE order preserved.
- Psum-out merge: round-robin over columns, `last` flagged per column from the
  config (nf*E words). `layer_done` = cluster done AND all outputs delivered (including
  emptying the 2-entry elastic output buffer `ocnt == 0`).
- Evidence: end-to-end TB through the word interface, interleaved and PE-major orders,
  stalls, disabled node, 5 seeds x 36 tests. `[xsim]`

### E7. Mesh and top level (`noc_mesh`, `noc_top`)
- `noc_mesh`: one network = MESH_X x MESH_Y `noc_router`s; port map per router:
  local 0..CPR-1, N/S/E/W, then external ports. Edge outputs without a neighbour stall
  (not drop). `HORIZ_ONLY` disables vertical links for the weight network.
- `noc_top`: three meshes + CPR nodes per router; word-addressed config interface
  (net, router, port, field, data) and node config; global `start`, sticky `all_done`
  (AND of node `layer_done`, disabled nodes report done).
- Interleaved multicast is how one GLB stream feeds several clusters with different
  data (weights): word i goes to local output (i/G) % K.
- Status: `tb_noc_top` passes in xsim. Verified Post-Route implementation `[impl]`.

### E8. Area, Timing, and Optimization Results (Implementation)
- **Timing (`125 MHz` / `8.0 ns`, single routed run):** Place and Route **MET** (`WNS +0.061 ns`, `WHS +0.025 ns`, `0` failing endpoints across `75,882` endpoints) `[impl]`. Note: `+0.061 ns` is a single-run closure with thin margin, not a guaranteed multi-seed Fmax ceiling.
- **Optimization Progression:**
  1. *Baseline (`10.0 ns`):* `WNS +0.133 ns` (`9.550 ns` data delay from `noc_node` psum FIFO flags -> `po_last` compare -> router `l0_reg` / `g_idx_reg` CE) `[impl]`.
  2. *Node Elastic Output Buffer:* Added a 2-entry elastic buffer on `noc_node` psum-out (`+1` cycle latency, `layer_done` gated by `ocnt == 0`). Removed NoC paths from the top 50 critical paths (`+864` FFs across 16 nodes) `[impl]`.
  3. *PE Running Address Registers (`8.0 ns`):* Cleared the `433` BRAM address setup violations (`+3,264` FFs across 64 PEs) `[impl]`.
- **Current Critical Path (`8.0 ns`):** Starts at psum router config registers (`u_noc/c_src_reg` / `c_en_reg`, fanout 76–83) through 6 LUT levels into `g_idx_reg/CE` (`7.65 ns` data delay, 83% routing) `[impl]`.
- **Hierarchical Utilization (`u_noc` 64-PE array at `8.0 ns`):** `36,554` LUTs (`57.7%` of `xc7a100t`), `21,651` FFs (`+4,126` vs 100 MHz baseline), `128` RAMB18, `64` DSP `[impl]`.
  - Weight mesh (`u_net_w`): `1,712` LUTs (`792` FFs) `[impl]`
  - Ifmap mesh (`u_net_i`): `1,888` LUTs (`976` FFs) `[impl]`
  - Psum mesh (`u_net_p`): `7,416` LUTs (`3,040` FFs) - Dominates because of dedicated per-cluster result ports and 13-port full crossbars `[impl]`.
  - `noc_top` config/glue logic: `942` LUTs `[impl]`
  - Per `noc_node` (16 total): `1,529–1,542` LUTs (`cluster_top` `1,483–1,495` LUTs + NI `39–52` LUTs) `[impl]`
- **Methodology Notes (Intentional Warnings):**
  - `128` `SYNTH-6` warnings: BRAM output registers disabled to preserve 1-cycle BRAM read (maintains strict 4-cycle `MAC_LATENCY`).
  - `80` `SYNTH-9` warnings: Address/config math routed to small fabric multipliers so all 64 DSP48s remain dedicated to the datapath MACs.

## F. Evaluation plan & measured cluster utilization
- **Measured Cluster Utilization (`[xsim]` via `tb_cluster_conv +verbose`):**
  - Peak workload (`E=16, nf=24, nc=4, chain=1`): **`42.9%`** per-PE MAC utilization (`10,745` cycles) at `ROWS=2`, scaling to **`22.2%`** (`20,743` cycles) at `ROWS=4` `[xsim]`.
  - Unchained baseline (`E=4, nf=3, nc=2, chain=0`): **`39.1%`** (`184` cycles) regardless of `ROWS` `[xsim]`.
  - **Architectural Takeaway:** Because `PEControlUnit` waits in `PSUM_LOAD` until all `psum_total` words arrive from the row below, chained rows execute sequentially (`~1/ROWS` per-PE utilization). Overlapping `PSUM_LOAD` with `COMPUTE` (streaming partial sums per slot) is a clear future throughput optimization.
- **Effective vs. Peak Throughput (`125 MHz`, 64 PEs = 16 clusters of `2x2`):**
  - Peak theoretical ceiling (100% MAC duty cycle): `16.0 GOPS` (`2 * 64 * 125 MHz`) `[estimate]`.
  - Realistic effective throughput on `2x2` chained clusters at `42.9%` duty cycle: **`~6.86 GOPS`** (`[xsim]`-derived).
- **Remaining Evaluation Work:** ARM Cortex-A9 baseline on PYNQ-Z2, bit-exact int8 Python reference model, end-to-end NoC+GLB layer latency, and board power measurements.

## G. Status snapshot
| Item | State |
|---|---|
| Cluster conv (`2x2`, `3x3`, `4x2`, `4x4`, `E<=16`, `nf<=24`, `nc<=4`) | `[xsim]` pass with drain hold-on-full coverage gate (`2,741` hold cycles at `2x2`, `2,768` at `4x2`) |
| `noc_router` unit TB | `[xsim]` pass on 2-entry elastic output buffer version |
| `noc_node` end-to-end TB (`2x2`, `3x3`, `4x2`) | `[xsim]` pass after 2-entry psum-out buffer & address register edits |
| `noc_mesh` / `noc_top` + `tb_noc_top` (16 clusters = 64 PEs) | `[xsim]` pass, all tests |
| `noc_top` Place & Route (`xc7a100t`, `8.0 ns` / `125 MHz`) | **MET (single run, thin margin):** `WNS +0.061 ns`, `WHS +0.025 ns`, `36,554` LUTs, `21,651` FFs, `128` RAMB18, `64` DSP `[impl]` |
| GLB adapters, stream engines, layer sequencer | Not written (GLB modeled as streams in TB; next milestone) |
| Python reference, board bring-up, benchmarks | Not done |

## H. Interview prep: likely questions and honest answers
1. *What did you actually build?* A dense Eyeriss-style row-stationary conv engine
   (PE, cluster, verified) and a parameterized circuit-switched NoC (router core,
   cluster node); the NoC is the main contribution. Mention it started as a university course base skeleton, completed independently.
2. *What bugs did your verification find?* The psum RAW hazard, the cluster done
   deadlock, and the ifmap valid/ready mismatch (B1-B3), each with a signature in the log.
3. *Why BRAM and why latency 4?* D2; the hazard distance follows the latency
   automatically because spacing is MAC_LATENCY+1.
4. *Why did one PE synthesize larger?* Vivado merged identical config registers
   across PEs (17 FFs counted once); fixed by hoisting config to the cluster (D1).
5. *How does the NoC survive a PE redesign?* E3: router is data-agnostic, NI isolates
   cluster ports; a new stream type (e.g. sparsity) is the only thing that would force
   router-level change.
6. *How would it scale to 10x10 or an ASIC?* E5 formula and the disable-spare rule.
7. *What are the limits?* C1, C2, router ready chain, chained-row serialization (~1/ROWS per-PE duty cycle), energy not measured.
8. *How does it compare to Eyeriss v2?* Same structural ideas (per-type networks,
   per-layer modes, two levels); it is dense, FPGA, much smaller, and unmeasured.
   Never claim parity.

## I. Mapping to the Eyeriss block diagram (Eyeriss v1 chip diagram, for reference)
| Eyeriss block | This project | State |
|---|---|---|
| PE (spad + MAC + control) | `PE_top`, `PEControlUnit`, BRAM spads, Xilinx MAC IP | done, xsim verified |
| PE array (12x14) | `cluster_top` (PE_ROWS x PE_COLS), clusters in `noc_top` (default 64 PEs) | done, xsim verified |
| Filter / ifmap / psum networks between GLB and PE array | `noc_router`, `noc_mesh`, `noc_top` (3 networks, two-level mesh), `noc_node` | done, timing closed @ 125 MHz |
| Config scan chain | word-addressed config registers (router + node) | done (different mechanism, same role) |
| Top-level control | `start` / `all_done` only | layer sequencer not written |
| Global buffer (108 KB) | modeled as streams in the testbench | not written (BRAM banks + stream engines) |
| ReLU, RLC encode/decode, off-chip DRAM + clock crossing | none (dense design, no compression; post-processing in software for now) | not written |
Note: Eyeriss v1 uses a flat multicast network; this design follows the hierarchical
mesh ideas of Eyeriss v2 instead.