# Changelog

All notable architectural, verification, and timing milestones for `NeuraCore-RTL`.

## [v2.2] - 2026-11-12 — 125 MHz Post-Route Timing Closure & Coverage Gating
### Added
- **`noc_node.sv`:** Added a 2-entry elastic output buffer (`od0`, `od1`, `ocnt`) on the Psum merge interface (`+1` cycle output latency) and updated `layer_done` to require `ocnt == 0`.
- **`PEControlUnit.sv`:** Replaced variable multipliers (`x*nf`, `f*nc3`, `c*W`) with running stride accumulators (`psum_xbase`, `psum_ptr`, `k_ck`, `k_addr`, `i_cbase`, `i_addr`) and registered `f_real_r` to clear BRAM address setup paths.
- **`tb_cluster_conv.sv`:** Added a drain hold-on-full (`dv && fifo_full`) coverage monitor that fails the suite on zero hits, a `24f/1c/E=16` slow-collector FIFO-fill test, and per-tile cycle/utilization reporting under `+verbose`.

### Verification & Implementation (`[xsim]` / `[impl]`)
- **Simulation (`[xsim]`):** `tb_cluster_conv` passed across `2x2`, `3x3`, `4x2`, and `4x4` geometries; `+verbose` measurements confirmed drain hold-on-full coverage (`2,741` cycles at `2x2`, `2,768` cycles at `4x2`) and peak chained per-PE utilization (`42.9%` at `ROWS=2`, `22.2%` at `ROWS=4` on `E=16, nf=24, nc=4`); `tb_noc_node` and `tb_noc_top` reran clean.
- **Timing (`8.0 ns` / `125 MHz`):** Post-route timing closed on `xc7a100t-csg324-1` (`WNS +0.061 ns`, `WHS +0.025 ns`, `0` failing endpoints across `75,882` endpoints) `[impl]`.
- **Utilization (`u_noc`):** `36,554` LUTs (`57.7%`), `21,651` FFs, `128` RAMB18, `64` DSP48 `[impl]`.

---

## [v2.1] - 2026-11-10 — 64-PE 3-Network Hierarchical NoC & 100 MHz Closure
### Added
- **`noc_router.sv`:** Implemented data-agnostic circuit-switched router with 2-entry elastic output FIFOs to break cross-router combinational ready loops, supporting unicast, broadcast, and grouped/interleaved multicast (`K`, `G`, `PH`).
- **`noc_node.sv`, `noc_mesh.sv`, `noc_top.sv`:** Built 2-level hierarchical mesh (`2x2` routers x `4` clusters x `4` PEs = `64` PEs) across three independent networks (`weight`, `ifmap`, `psum`) with word-addressed configuration.
- **Testbenches:** Added `tb_noc_router`, `tb_noc_node`, and `tb_noc_top`.

### Implementation (`[impl]`)
- **Timing (`10.0 ns` / `100 MHz`):** Closed post-route timing with `WNS +0.133 ns`, `WHS +0.025 ns`, `0` failing endpoints (`37,032` LUTs, `17,525` FFs, `128` RAMB18, `64` DSP) `[impl]`.

---

## [v2.0] - Post-Course PE & Cluster Overhaul
### Fixed & Changed
- **RAW Hazard Fix (`PEControlUnit.sv`):** Reordered compute loops to `x -> c -> k -> f` (`f` innermost) and padded `f_eff = max(nf, MAC_LATENCY + 1)` with bubble cycles.
- **Deadlock & Skew Fixes (`cluster_ctrl.sv`, `cluster_top.sv`):** Latched per-PE `done` pulses (sticky done) and gated per-PE `ifmap_valid` with row-wide `&pe_ifmap_ready`.
- **Sliding Window (`E > 1`):** Extended `ifmap` scratchpad to hold `W = E + 2` pixels per channel (`MAXOFMAP = 16`) with `x`-major psum indexing.
- **Area Optimization (`D1`, `D2`):** Hoisted all layer config registers to `cluster_top` and migrated `kernel` and `psum` scratchpads to synchronous BRAM (`MAC_LATENCY = 4`), cutting `2x2` cluster LUTs from `2,649` to `1,546` `[synth]`.

---

## [v1.0] - ESDP Lab Course Baseline (`rtl/V1.0/`)
- Initial unverified RTL skeleton for `PEControlUnit`, `PETopModule`, `cluster_top`, distributed scratchpads, and basic unit testbenches.