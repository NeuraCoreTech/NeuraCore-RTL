# NeuraCore-RTL: Dense Row-Stationary CNN Accelerator with Hierarchical NoC

FPGA-oriented (Xilinx 7-Series) SystemVerilog CNN accelerator inspired by Eyeriss v2, featuring a 64-PE row-stationary compute array interconnected via a parameterized, circuit-switched 3-network Network-on-Chip (NoC). See [`docs/decisions_log.md`](docs/decisions_log.md) for architectural trade-offs and verified vs. estimated metrics.

---

## Project Origin & Academic Context
* **Course Origins (`rtl/V1.0/`):** This project originated alongside the ESDP Lab course framework, which provided the initial unverified RTL skeleton for `PE_top`, `PEControlUnit`, and `cluster_top`.
* **Independent Post-Course Extension (`v2_post_course/`):** Everything beyond the baseline skeleton was designed, verified, and timing-closed independently post-course—including self-checking golden-model testbenches (`tb_cluster_conv`, `tb_noc_*`), hazard fixes (`B1–B3`), BRAM scratchpad migration (`D2`), the 3-network hierarchical NoC (64 PEs), and **125 MHz** post-route timing closure.

---

## Architectural References and Research Background

The accelerator architecture and system design were developed after studying multiple ML accelerator and computer architecture research works, including:
- Eyeriss & Eyeriss v2
- DianNao
- TPU architectures
- Xilinx DPU
- Angel-Eye
- Cerebras systems
- Systolic array architectures

The project direction was additionally influenced by discussions and architectural guidance from Prof. Rajesh Kedia during independent exploration conducted alongside the ESDP Lab course framework.

Particular inspiration was drawn from:
- *Eyeriss: An Energy-Efficient Reconfigurable Accelerator for Deep Convolutional Neural Networks*
- H. T. Kung and Charles E. Leiserson, *Systolic Arrays for VLSI*, Carnegie Mellon University Technical Report, 1978 ([PDF](https://www.eecs.harvard.edu/htk/static/files/1978-cmu-cs-report-kung-leiserson.pdf)).

---

## Design Philosophy & Goals
- **Spatial Compute & Data Reuse:** Row-stationary 1D convolution with local IFmap/weight reuse across rows and vertical partial-sum accumulation.
- **FPGA-Oriented Implementation:** Synchronous BRAM scratchpads, DSP48E1 multiply-accumulate mapping, and elastic output buffering to eliminate cross-mesh combinational loops.
- **Modular & Extensible RTL:** Data-agnostic NoC routers decoupled from PE microarchitecture via Network Interfaces (`noc_node`).

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
- **PE (`PE_top`, `PEControlUnit`):** Row-stationary 1D convolution (`3x3`, stride 1, unsigned 8-bit operands, 24-bit accumulation), BRAM scratchpads, Xilinx `xbip_multadd_8bit` IP (`MAC_LATENCY = 4`), running address registers, and hazard-free `x->c->k->f` loop ordering.
- **Cluster (`cluster_top`, `cluster_ctrl`):** Parameterized `PE_ROWS x PE_COLS` PE array, single-point layer config registration, gang start, sticky done, and row-synchronized valid/ready gating.
- **NoC (`noc_router`, `noc_node`, `noc_mesh`, `noc_top`):** Data-agnostic circuit-switched routers with 2-entry elastic output FIFOs supporting unicast, broadcast, and grouped/interleaved multicast; `noc_node` handles word tagging and 2-entry elastic Psum output buffering.

---

## Repository Layout
```text
NeuraCore-RTL/
├── README.md
├── docs/
│   ├── CHANGELOG.md                 # Revision history from V1.0 to 125 MHz closure
│   ├── decisions_log.md             # Design decisions, bug logs, and [impl]/[xsim] metrics
│   └── Limitations.txt              # Structural constraints and software lowering notes
├── rtl/V1.0/                        # [FROZEN] Original ESDP Lab course RTL
├── testbenches/                     # [FROZEN] Original ESDP Lab course testbenches
└── v2_post_course/                  # Active post-course architecture
    ├── rtl/pe/                      # PE_top.sv, PEControlUnit.sv, scratchpad_*.sv, mac.sv, fifo_block.sv
    ├── rtl/cluster/                 # cluster_top.sv, cluster_ctrl.sv
    ├── rtl/noc/                     # noc_router*.sv, noc_mesh*.sv, noc_top.sv, noc_node.sv
    ├── rtl/glb/                     # Global Buffer & stream engines (in progress)
    ├── rtl/impl/                    # noc_impl_top.sv & constraints
    ├── tb/                          # tb_cluster_conv.sv, tb_noc_router.sv, tb_noc_node.sv, tb_noc_top.sv
    └── reports/                     # Post-route Vivado timing & utilization reports
```

---

## Implementation & Verification Status (`v2_post_course`)
- **Post-Route Timing (`xc7a100t-csg324-1`, Vivado 2025.1):** **Met at 125 MHz** (`8.0 ns` period, single routed run: `WNS +0.061 ns`, `WHS +0.025 ns`, `0` failing endpoints across `75,882` endpoints) `[impl]`.
- **Post-Route Utilization (`u_noc`, 64-PE Array):** `36,554` LUTs (`57.7%` of device), `21,651` FFs, `128` RAMB18, `64` DSP48 blocks `[impl]`.
- **Simulation (`Vivado xsim`):**
  - `tb_cluster_conv`: Passing across `2x2`, `3x3`, `4x2`, and `4x4` geometries (`E <= 16`, `nf <= 24`, `nc <= 4`) with drain hold-on-full coverage gating (`2,741` hold cycles at `2x2`, `2,768` at `4x2`; peak chained per-PE utilization `42.9%` at `ROWS=2`, `22.2%` at `ROWS=4`) `[xsim]`.
  - `tb_noc_router`, `tb_noc_node` (`2x2`, `3x3`, `4x2`), and `tb_noc_top` (16 clusters / 64 PEs): All passing `[xsim]`.
- **Current Scope & Roadmap:**
  - **Completed:** PE array, Cluster wrapper, 3-network hierarchical NoC, 125 MHz timing closure.
  - **Next / Planned:** Global Buffer (`GLB`) BRAM banks & stream engines, top-level layer sequencer, Python bit-exact reference model, and board bring-up.

---

## Simulating (Vivado xsim)
- **Cluster:** Top `tb_cluster_conv` (`-testplusarg seeds=30 -testplusarg seed0=1`, optional `-testplusarg verbose=1`). Requires `xbip_multadd_8bit` IP (A unsigned, B unsigned, C/P 24-bit).
- **Router:** Top `tb_noc_router` (`-testplusarg seed=N`).
- **Node:** Top `tb_noc_node` (`-testplusarg seed=N`, requires MAC IP).
- **System (64 PEs):** Top `tb_noc_top` (`-testplusarg seed=N`, requires MAC IP).

---

## Limitations
Dense only; fixed `3x3` kernel, stride 1, no hardware zero-padding (pad upstream); unsigned 8-bit weights; no depthwise mode; software lowering required for other layer shapes (e.g., `1x1`, `5x5`, stride 2). See [`docs/Limitations.txt`](docs/Limitations.txt) for details.

---

## Contributors
- Krishna H. Patil
- Arnav Yadnopavit

## Disclaimer
This project is not an official implementation of Eyeriss and is not affiliated with the original authors. The architecture and implementation details differ from the original publications based on project goals, FPGA constraints, and ongoing experimentation.