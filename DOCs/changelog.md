# Changelog

Architectural, verification and timing milestones. Evidence tags (`[xsim]`, `[impl]`,
`[estimate]`) are defined in [decisions_log.md](decisions_log.md).

## [v2.2] - 2026-11-12 - 8.0 ns timing and coverage gating

### Changed
- **`noc_node.sv`:** psum merge now feeds a 2-entry elastic output buffer (`od0`, `od1`,
  `ocnt`), adding 1 cycle of output latency. `layer_done` also requires `ocnt == 0`.
- **`PEControlUnit.sv`:** the `x*nf`, `f*nc3` and `c*W` multipliers are replaced by
  running address registers (`psum_xbase`, `psum_ptr`, `k_ck`, `k_addr`, `i_cbase`,
  `i_addr`) and a registered `f_real_r`. Ports and `MAC_LATENCY` are unchanged.
- **`tb_cluster_conv.sv`:** added a drain hold-on-full (`dv && fifo_full`) coverage
  monitor that fails the suite on zero hits, a 24-filter / 1-channel / E=16 FIFO-fill test
  with a slow collector, and per-tile cycle and utilization reporting under `+verbose`.

### Verification and implementation
- **Simulation `[xsim]`:** `tb_cluster_conv` passes at 2x2, 3x3, 4x2 and 4x4 clusters.
  Hold-on-full coverage: 2,741 cycles at 2x2 and 2,768 at 4x2. Measured per-PE
  utilization on E=16, nf=24, nc=4: 42.9% at 2 rows, 22.2% at 4 rows. `tb_noc_node` and
  `tb_noc_top` pass on this RTL.
- **Timing `[impl]`:** 8.0 ns (125 MHz) met in one routed out-of-context run of the
  `noc_impl_top` wrapper on `xc7a100t-csg324-1`: WNS +0.061 ns, WHS +0.025 ns, 0 failing
  endpoints out of 75,882. Setup margin is thin and the wrapper has no real I/O or
  global buffer in the path. The 8.0 ns run before the address-register change had WNS
  -0.757 ns, TNS -97.3 ns and 433 failing endpoints.
- **Utilization (`u_noc`) `[impl]`:** 36,554 LUTs (57.7%), 21,651 FFs, 128 RAMB18, 64 DSP.

---

## [v2.1] - 2026-11-10 - 64-PE hierarchical NoC

### Added
- **`noc_router.sv`:** data-agnostic circuit-switched router with 2-entry elastic output
  buffers (no combinational ready path across routers), unicast, broadcast and
  grouped/interleaved multicast (`K`, `G`, `PH`).
- **`noc_node.sv`, `noc_mesh.sv`, `noc_top.sv`:** two-level hierarchical mesh (2x2 routers
  x 4 clusters x 4 PEs = 64 PEs) over three independent networks (weight, ifmap, psum)
  with a word-addressed config interface.
- **Testbenches:** `tb_noc_router`, `tb_noc_node`, `tb_noc_top`.

### Implementation `[impl]`
- 10.0 ns (100 MHz) met in a routed out-of-context run: WNS +0.133 ns, WHS +0.025 ns, 0
  failing endpoints; 37,032 LUTs, 17,525 FFs, 128 RAMB18, 64 DSP.

---

## [v2.0] - PE and cluster overhaul

### Fixed and changed
- **RAW hazard (`PEControlUnit.sv`):** loop order is now x -> c -> k -> f (f innermost),
  with the f loop padded to `max(nf, MAC_LATENCY + 1)` using bubble cycles.
- **Deadlock and skew (`cluster_ctrl.sv`, `cluster_top.sv`):** per-PE `done` is latched
  (sticky), and per-PE `ifmap_valid` is gated by the whole row's ready.
- **Sliding window (E > 1):** the ifmap scratchpad holds W = E + 2 pixels per channel
  (`MAXOFMAP = 16`) with x-major psum indexing.
- **Area:** all layer config moved into `cluster_top`; kernel and psum scratchpads moved
  to synchronous BRAM (`MAC_LATENCY = 4`). The 2x2 cluster dropped from 2,649 to 1,546
  LUTs `[synth]`.
- **Verification:** self-checking golden-model testbench `tb_cluster_conv`.

---

## [v1.0] - Course baseline (`rtl/V1.0/`)

- Initial RTL skeleton for `PEControlUnit`, `PE_top`, `cluster_top`, distributed
  scratchpads and basic unit testbenches. Kept unchanged.
