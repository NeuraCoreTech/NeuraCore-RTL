# Dense row-stationary CNN accelerator with a configurable hierarchical NoC

FPGA-oriented (Xilinx 7-series), SystemVerilog, inspired by Eyeriss v2. Dense 3x3
convolution, unsigned 8-bit operands, 24-bit accumulation. The main contribution is a
parameterized, circuit-switched, three-network (weight / ifmap / psum) hierarchical NoC
connecting 16 PE clusters (64 PEs by default).

Work in progress: the NoC and PE array are verified in simulation and have met timing in
an out-of-context implementation run. The global buffer, layer sequencer and board
bring-up are not written yet.

Reasoning, evidence and status for every design choice are in
[docs/decisions_log.md](docs/decisions_log.md). Release history is in
[docs/CHANGELOG.md](docs/CHANGELOG.md). Scope limits are in
[docs/Limitations.txt](docs/Limitations.txt).

## Results at a glance

All implementation numbers are for `xc7a100t-csg324-1`, Vivado 2025.1, 64-PE `noc_top`.
Evidence tags (`[xsim]`, `[impl]`, `[estimate]`) are defined in the decisions log.

| Item | Result |
|---|---|
| Timing | 8.0 ns (125 MHz) met in one routed out-of-context run of the `noc_impl_top` wrapper: WNS +0.061 ns, WHS +0.025 ns, 0 failing endpoints `[impl]` |
| Area (`u_noc`) | 36,554 LUTs (57.7%), 21,651 FFs, 128 RAMB18, 64 DSP `[impl]` |
| Cluster verification | Self-checking golden-model TB passes at 2x2, 3x3, 4x2 and 4x4 clusters, E up to 16, nf up to 24, nc up to 4 `[xsim]` |
| NoC verification | `tb_noc_router`, `tb_noc_node`, `tb_noc_top` (16 clusters, 64 PEs) pass `[xsim]` |
| Chained-row utilization | Per-PE duty cycle 42.9% at 2 rows and 22.2% at 4 rows on E=16, nf=24, nc=4 `[xsim]` |

The 125 MHz result comes from an LFSR-driven wrapper with no real I/O or global buffer in
the path, and the setup margin is thin. Treat it as "met in the measured run", not as a
guaranteed Fmax.

## Architecture

```text
GLB bank ─► router ──── router        3 networks (weight / ifmap / psum),
              │ x4 local   │          one router per group of PE clusters,
           noc_node      noc_node     routers in a MESH_X x MESH_Y mesh
              │            │
        cluster_top   cluster_top     PE_ROWS x PE_COLS PEs, ifmap broadcast per row,
        (PE array)    (PE array)      unique filter per PE, vertical psum chain
```

- **PE** (`PE_top`, `PEControlUnit`): row-stationary 1-D convolution, BRAM kernel and
  psum scratchpads, Xilinx multiply-add IP, 4-cycle MAC latency, hazard-free loop order,
  running address registers.
- **Cluster** (`cluster_top`, `cluster_ctrl`): PE array, layer config registered once per
  cluster, gang start, sticky done.
- **NoC** (`noc_router`, `noc_mesh`, `noc_top`, `noc_node`): data-agnostic router with
  unicast, broadcast and grouped/interleaved multicast, 2-entry elastic output buffers,
  word-addressed config interface. The node (`noc_node`) maps router words to cluster ports.

Defaults: 2x2 routers x 4 clusters per router x 4 PEs per cluster = 64 PEs. All sizes are
parameters (`MESH_X`, `MESH_Y`, `CPR`, `PE_ROWS`, `PE_COLS`).

## Repository layout

```text
rtl/V1.0/                    original course baseline, kept unchanged
v2_post_course/
  rtl/pe/       PE_top.sv PEControlUnit.sv scratchpad_ifmap.sv scratchpad_kernel.sv
                scratchpad_psum.sv mac.sv fifo_block.sv
  rtl/cluster/  cluster_top.sv cluster_ctrl.sv
  rtl/noc/      noc_router.sv noc_mesh.sv noc_top.sv noc_node.sv
  rtl/impl/     noc_impl_top.sv  (implementation-only wrapper, not a functional test)
  tb/           tb_cluster_conv.sv tb_noc_router.sv tb_noc_node.sv tb_noc_top.sv
  reports/      post-route timing and utilization reports
docs/           decisions_log.md CHANGELOG.md Limitations.txt
```

## Simulating (Vivado xsim)

All testbenches need the `xbip_multadd_8bit` IP (A unsigned, B unsigned, C/P 24-bit,
latency 3).

| Testbench | Top module | Plusargs |
|---|---|---|
| Cluster | `tb_cluster_conv` | `seeds=N` (default 8), `seed0=S` (default 1), `verbose` |
| Router | `tb_noc_router` | `seed=N` |
| Node (end to end) | `tb_noc_node` | `seed=N` |
| System (16 clusters) | `tb_noc_top` | `seed=N` |

Example, 30 seeds of the cluster suite (Vivado Tcl console):

```tcl
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg seeds=30 -testplusarg seed0=1} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
launch_simulation
```

Add `-testplusarg verbose` to print per-tile PASS lines with cycle counts and per-PE
utilization. Cluster shape is set by `ROWS` and `COLS` at the top of the testbench.

The cluster testbench fails the run if the pipelined drain's hold-on-full path is never
exercised, so a clean run also means that path was hit.

## Implementation

`rtl/impl/noc_impl_top.sv` wraps `noc_top` with a 1024-bit LFSR driving every input and
one XOR-reduced output bit, so place and route can run without hundreds of I/O pins and
nothing is trimmed. Use it only for area and timing. Set it as the top module with a
single 8.0 ns clock constraint on `clk`.

## Not yet done

Global buffer (BRAM banks and stream engines), layer sequencer, layer config generator (router/node config words for a given mesh size and layer mapping; the testbench currently hard-codes them for a 2x2 mesh), board
bring-up, independent int8 reference model, benchmarks, power measurement, synthesis for
`xc7z020`.

## Limitations

Dense only; 3x3, stride 1, no padding; unsigned weights; no depthwise; software lowering
needed for other layer shapes. Details in [docs/Limitations.txt](docs/Limitations.txt).

## Provenance

The project started as a university group course project that supplied an unverified RTL
skeleton of `PE_top`, `PEControlUnit` and `cluster_top` (kept in `rtl/V1.0/`). Everything in
`v2_post_course/` was written afterwards, including the verification environment, the
RTL fixes, the BRAM scratchpads, the NoC and the timing work.
