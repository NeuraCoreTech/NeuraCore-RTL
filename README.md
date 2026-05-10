## Architectural References and Research Background

The accelerator architecture and system design were developed after studying multiple ML accelerator and computer architecture research works, including:

- Eyeriss
- DianNao
- TPU architectures
- Xilinx DPU
- Angel-Eye
- Cerebras systems
- Systolic array architectures

The project direction was additionally influenced by discussions and architectural guidance from Prof. Rajesh Kedia during independent exploration conducted alongside the ESDP Lab course framework.

Particular inspiration was drawn from:

- *Eyeriss: An Energy-Efficient Reconfigurable Accelerator for Deep Convolutional Neural Networks*
- H. T. Kung and Charles E. Leiserson,  
  *Systolic Arrays for VLSI*  
  Carnegie Mellon University Technical Report, 1978.

Reference:  
https://www.eecs.harvard.edu/htk/static/files/1978-cmu-cs-report-kung-leiserson.pdf

---

## Design Philosophy

The project focuses on exploring:

- spatial compute architectures
- dataflow-aware accelerator design
- memory reuse optimization
- FPGA-oriented implementation strategies
- scalable processing element arrays
- systolic and semi-systolic compute organizations

rather than reproducing any single accelerator architecture exactly.

---

## Current Scope

Implemented / planned modules:

- Processing Element (PE) array
- Global buffer
- NoC / interconnect
- Scheduler and control logic
- SRAM interfaces
- DMA subsystem
- Quantization support
- Convolution pipelines

---

## Design Goals

- Efficient data reuse
- Reduced DRAM accesses
- Scalable PE arrays
- FPGA-friendly implementation
- Energy-efficient computation
- Modular and extensible RTL design

---
## Contributors

-Krishna H. Patil
-Arnav Yadnopavit

## Disclaimer

This project is not an official implementation of Eyeriss and is not affiliated with the original authors.

The architecture and implementation details may differ from the original publications based on project goals, FPGA constraints, and ongoing experimentation.
