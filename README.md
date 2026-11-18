# NeuraCore: Dense Row-Stationary CNN Accelerator with Hierarchical NoC

FPGA-oriented (Xilinx 7-Series) SystemVerilog CNN accelerator inspired by Eyeriss v2, featuring a 64-PE row-stationary compute array interconnected via a parameterized, circuit-switched 3-network Network-on-Chip (NoC). See [`docs/decisions_log.md`](docs/decisions_log.md) for architectural trade-offs, bug logs, and measured metrics.

---

## Project Origin & Academic Context
* **Course Origins (`rtl/V1.0/`):** This project originated alongside a university group course framework, which provided the initial unverified RTL skeleton for `PE_top`, `PEControlUnit`, and `cluster_top`.
* **Independent Extension (`v2_post_course/`):** Everything beyond the baseline skeleton was designed, verified, and timing-closed independently post-course—including self-checking golden-model testbenches, hazard fixes, BRAM migration, the 3-network hierarchical NoC, system profiling, and 125 MHz post-route timing closure.

---

## Architectural References and Research Background
The accelerator architecture and system design were developed after studying multiple ML accelerator and computer architecture research works, with particular inspiration drawn from:
- *Eyeriss: An Energy-Efficient Reconfigurable Accelerator for Deep Convolutional Neural Networks* (and Eyeriss v2 hierarchical mesh ideas).
- TPU architectures, DianNao, and Xilinx DPU.
- H. T. Kung and Charles E. Leiserson, *Systolic Arrays for VLSI*, 1978.

The project direction was additionally influenced by independent architectural exploration conducted alongside the university course framework.

---

## Architecture
```text
GLB bank ─► router ──── router        3 networks (weight / ifmap / psum),
              │ x4 local   │          one router per group of PE clusters,
           noc_node      noc_node     routers in a MESH_X x MESH_Y mesh
              │            │
        cluster_top   cluster_top     PE_ROWS x PE_COLS PEs, ifmap broadcast per row,
        (PE array)    (PE array)      unique filter per PE, vertical psum chain
```
- **PE & Cluster (`PE_top`, `cluster_top`):** Row-stationary 1D convolution (`3x3`, stride 1, unsigned 8-bit operands, 24-bit accumulation). Synchronous BRAM scratchpads, Xilinx `xbip_multadd_8bit` DSP mapping (`MAC_LATENCY = 4`), running address registers, and hazard-free `x->c->k->f` loop ordering.
- **Hierarchical NoC (`noc_router`, `noc_node`, `noc_top`):** Data-agnostic, circuit-switched routers supporting unicast, broadcast, and grouped/interleaved multicast. 2-entry elastic output FIFOs eliminate cross-mesh combinational loops. Nodes handle word tagging and cluster routing.

---

## Implementation & Verification Status (`v2_post_course`)
- **Post-Route Timing (`xc7a100t-csg324-1`, 125 MHz):** **Met at 8.0 ns period** (single run: `WNS +0.061 ns`, `WHS +0.025 ns`, `0` failing endpoints).
- **Post-Route Utilization (`64-PE u_noc`):** `36,554` LUTs (`57.7%`), `21,651` FFs, `128` RAMB18, `64` DSP48 blocks. The NoC logic occupies ~30% of total LUTs `[impl]`.
- **System Profiling (`tb_noc_top_perf`):** Reaches **4.86 GOPS** (30.4% per-PE utilization against a 16.0 GOPS ideal ceiling) at 125 MHz on the 64-PE max tile (`nf=24, nc=4, E=16`) using split-tiles weight broadcast mapping `[xsim]`. 
- **Functional Gate-Level Simulation:** `tb_noc_top` passes 14/14 tests on the routed `noc_top_func_impl.v` netlist without SDF delays, confirming DSP and BRAM inference survive implementation `[impl]`.

---

## Repository Layout
```text
NeuraCore-RTL/
├── README.md
├── docs/
│   ├── CHANGELOG.md                 # Revision history including performance profiling
│   ├── decisions_log.md             # Design decisions, bug logs, and [impl]/[xsim] metrics
│   └── Limitations.txt              # Structural constraints and performance limiters
├── rtl/V1.0/                        # [FROZEN] Original ESDP Lab course RTL
├── testbenches/                     # [FROZEN] Original ESDP Lab course testbenches
└── v2_post_course/                  # Active post-course architecture
    ├── rtl/pe/                      # PE_top.sv, PEControlUnit.sv, scratchpad_*.sv, mac.sv, fifo_block.sv
    ├── rtl/cluster/                 # cluster_top.sv, cluster_ctrl.sv
    ├── rtl/noc/                     # noc_router*.sv, noc_mesh*.sv, noc_top.sv, noc_node.sv
    ├── rtl/impl/                    # noc_impl_top.sv & constraints
    ├── tb/                          # tb_cluster_conv.sv, tb_noc_top_perf.sv, etc.
    └── reports/                     # Post-route Vivado timing & utilization reports
```

## Simulating (Vivado xsim)
- **Cluster:** Top `tb_cluster_conv` (`-testplusarg seeds=30 -testplusarg seed0=1 +verbose`). Requires `xbip_multadd_8bit` IP.
- **System (64 PEs):** Top `tb_noc_top_perf` (`-testplusarg seed=N`). Includes cycle-accurate profiling tracking MAC issues, PE phase cycles, and per-network words.

---

## Limitations
Dense only; fixed `3x3` kernel, stride 1; unsigned 8-bit weights; pad upstream. Primary NoC throughput limiters are row-chain serialization and zero-preload bandwidth (see `docs/Limitations.txt`).

## Contributors
- Krishna H. Patil
- Arnav Yadnopavit

*Disclaimer: This project is an independent architectural exploration inspired by Eyeriss, not an official implementation.*
