# Custom RISC CPU with Systolic Matrix Accelerator

A synthesizable System-on-Chip (SoC) architecture designed in Verilog HDL, integrating a custom pipelined RISC CPU core with a dedicated 2D 4x4 systolic array coprocessor for accelerated 2D image filtering, convolution, and matrix processing.

---

## Architectural Overview

```
                      +---------------------------------------+
                      |          pixel_processor_top          |
                      +---------------------------------------+
                                   |             |
                 +-----------------+             +-----------------+
                 |                                                 |
        +------------------+                              +------------------+
        |     cpu_core     | <--- Instructions / Data --- | instruction_mem  |
        +------------------+                              |    data_mem      |
                 |                                        +------------------+
                 | Coprocessor Control / Stream Interface
                 v
        +-------------------------------------------------+
        |                 coprocessor_top                 |
        |  +------------------+     +------------------+  |
        |  | stream_fifo_4x4  | --> |matrix_systolic_4x|  |
        |  +------------------+     | (16 PEs Mesh)    |  |
        |                           +------------------+  |
        |                                     |           |
        |  +------------------+               v           |
        |  |coprocessor_fsm_4x| <--- +------------------+ |
        |  +------------------+      | output_fifo_4x4  | |
        |                            +------------------+ |
        +-------------------------------------------------+
```

### Key Subsystems

1. **Custom Pipelined CPU Core:**
   - **Instruction Fetch (`Instruction_Fetch.v`):** Program counter management and ROM interface.
   - **Instruction Decode (`Instruction_Decode.v` & `control_unit.v`):** Opcode decoding, branch logic, and coprocessor instruction dispatch.
   - **Register File (`registerfile.v`):** Multi-port general-purpose registers.
   - **Execute Stage (`execute_stage.v`):** Arithmetic/logic execution and memory address calculation.

2. **Systolic Array Coprocessor (`coprocessor_top.v`):**
   - **2D Systolic Array Mesh (`matrix_systolic_4x4.v`):** Grid of 4x4 = 16 Processing Elements (`matrix_pe.v`) computing high-throughput multiply-accumulate (MAC) operations for image kernels.
   - **Stream Input FIFO (`stream_fifo_4x4.v`):** Buffers and skews incoming image pixel streams and kernel weights.
   - **Output Buffer FIFO (`output_fifo_4x4.v`):** Captures processed pixel results from array wavefronts.
   - **Coprocessor FSM (`coprocessor_fsm_4x4.v`):** Coordinates matrix streaming, execution timing, CPU stall signals, and memory writebacks.

3. **Memory Subsystem:**
   - **Instruction Memory (`instruction_memory.v`):** Program ROM for instructions.
   - **Data Memory (`data_memory.v`):** Dual-ported RAM for pixel buffers and filter weights.

---

## Repository Structure

```text
Pixel-Processor-Systolic-Array/
|-- rtl/
|   |-- pixel_processor_top.v      # SoC Top-Level Integration
|   |-- instruction_memory.v       # Program ROM
|   |-- data_memory.v              # Data RAM
|   |-- cpu_core.v                 # Pipelined CPU Core Top
|   |-- Instruction_Fetch.v        # CPU Fetch Stage
|   |-- Instruction_Decode.v       # CPU Decode Stage
|   |-- control_unit.v             # Main Control Logic
|   |-- registerfile.v             # General-Purpose Register File
|   |-- execute_stage.v            # Execution ALU Stage
|   |-- coprocessor_top.v          # Coprocessor Top-Level Wrapper
|   |-- coprocessor_fsm_4x4.v      # Coprocessor Control State Machine
|   |-- stream_fifo_4x4.v          # Input Pixel/Weight Stream FIFO
|   |-- matrix_systolic_4x4.v      # 4x4 Systolic Array Mesh
|   |-- matrix_pe.v                # Individual Processing Element (MAC)
|   +-- output_fifo_4x4.v          # Processed Output Stream FIFO
|-- tb/
|   +-- tb_processor.v             # SoC System-Level Verification Testbench
|-- docs/                          # Architectural Block Diagrams & Waveforms
|-- .gitignore                     # Vivado build and artifact exclusions
+-- README.md                      # Technical Documentation
```

---

## Simulation & Verification Flow

1. Open **AMD Xilinx Vivado** and create a new project.
2. Add all source files under `rtl/` to **Design Sources** with `pixel_processor_top.v` set as the top module.
3. Add `tb/tb_processor.v` to **Simulation Sources**.
4. Launch **Behavioral Simulation** in Vivado.
5. The testbench boots the CPU from reset, executes kernel setup instructions, streams image blocks into the systolic coprocessor, and verifies pixel convolution results against expected values.
