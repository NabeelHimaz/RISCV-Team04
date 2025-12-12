# RISC-V

# Table of Contents:

- [Quick Start](#quick-start)
- [Single Cycle CPU Implementation](#single-cycle)
- [Pipelined CPU Implementation](#pipelined-risc-v-cpu)
- [Cached Implementation](#data-memory-cache)
- [Complete RISC-V](#complete-riscv-cpu)
- [Superscalar](#superscalar)
- [Appendix](#appendix)

# Quick Start
This repository contains our complete implementation of a RISC-V RV32I processor with several major design iterations.

We completed the Single-Cycle and all of the stretch goals (Pipelined, Two-Way Set Associative Write-Back Cache, Full RV32I Design). We started with the Stretch goal 3 first by doing the full implementation of the RV32I instruction set, and then naturally progressed into doing pipelining complete with hazard detection. 

 

| Branch | Description |
| ------ | ----------- |
|`main` | Full 32VI Single-Cycle Implementation |
|`Pipelined` | Pipelined + Full RV32I Implementation |
|`Cache` | Cache + Full 32VI Single-Cycle Implementation |
|`Complete` | Pipelined + Cache + Full RV32I Implementation |


### Prerequisites

- **Verilator** (version 4.0 or higher)
- **RISC-V GNU Toolchain** (for assembly compilation)
- **GTKWave** (for waveform viewing)
- **GoogleTest** (for C++ testbenches)
- **Vbuddy** (optional, for F1 and PDF demonstrations)

### Quick Build & Test

To access each implementation version:

```bash
git checkout <branch-name>
```

**IMPORTANT:** All testbench scripts must be run from the `/tb` directory.

#### Running Provided Test Suite

```bash
cd tb
./doit.sh
```

You will be given the option to execute:

- **Unit tests** (testbenches we have written to verify the logic of individual modules).
- **Program tests** (verifies execution of test programs to ensure the processor meets requirements).
- **Both** (to run all test files).

The distribution for the pdf test can be changed by overwriting the distribution name.

To do this in `./tb/program_tests/verify.cpp`, change line 43.
```cpp
// can change to "noisy", "triangle", or "sine"
setData("reference/gaussian.mem");
```

To do this in `./tb/program_tests/execute_pdf.cpp`, change line 144.
```cpp
// can change to "noisy", "triangle", or "sine"
tb.setData("reference/gaussian.mem");
```
The execute_pdf.cpp program also allows you to skip vbuddy clock cycle plotting to a specific target in order to save execution time. The suggested thresholds for each datasource are hardcoded in lines 18-22. Uncomment the appropriate line depending on your datasource.

For unit testing each module, we run:
```bash
cd tb
./doit.sh unit_tests/<"test name">.cpp
```
This will run the individual unit tests.


#### Quick Start - Vbuddy Tests

##### **Windows only**: the doit.sh script automatically attempts to run the attach_usb.sh script on execution in order to pair to vbuddy if connected.

To run the f1 light test within the `./tb/` folder,

```bash
cd tb
./doit.sh program_tests/execute_f1.cpp
```



## Team Members & Contributions

### Team Details

| Team Member | GitHub | CID | Email | Personal Statement |
|-------------|--------|-----|-------|-------------------|
| [Team Member 1] | [@Asad-Tarq](https://github.com/Asad-Tarq) | [02582153] | [art24@ic.ac.uk] | [Link to Statement](./statements/Asad.md) |
| [Team Member 2] | [@Marc0s-ikp](https://github.com/Marc0s-ikp) | [02415338] | [mi624@ic.ac.uk] | [Link to Statement](./statements/Marcus.md) |
| [Team Member 3] | [@NabeelHimaz](https://github.com/NabeelHimaz) | [02605511] | [nh1324@ic.ac.uk] | [Link to Statement](./statements/Nabeel.md) |
| [Team Member 4] | [@archit-ku](https://github.com/archit-ku) | [02560961] | [archit.kumar24@imperial.ac.uk] | [Link to Statement](./statements/Archit.md) |


## Single-Cycle CPU Implementation

### Overview

The single-cycle implementation forms the foundation of our RISC-V processor, executing each instruction in a single clock cycle. This version implements the complete RV32I base instruction set, providing support for:

- **R-type:** Arithmetic and logical operations
- **I-type:** Immediate operations 
- **S-type:** Store operations
- **B-type:** Conditional branches
- **U-type:** Upper immediate operations
- **J-type:** Unconditional jumps

### Architecture Diagram

![Single-Cycle Architecture Diagram](./images/singlecycleschematic.jpg)


### Supported Instructions

| Instruction Type | Instructions Implemented |
|-----------------|-------------------------|
| **R-type** | `add`, `sub`, `xor`, `or`, `and`, `sll`, `srl`, `sra`, `slt`, `sltu` |
| **I-type (ALU)** | `addi`, `xori`, `ori`, `andi`, `slli`, `srli`, `srai`, `slti`, `sltiu` |
| **I-type (Load)** | `lb`, `lh`, `lw`, `lbu`, `lhu` |
| **I-type (Jump)** | `jalr` |
| **S-type** | `sb`, `sh`, `sw` |
| **B-type** | `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` |
| **U-type** | `lui`, `auipc` |
| **J-type** | `jal` |

### Module Breakdown



### Key Design Decisions

1. **Top Module Stages:**
Since we knew we would be implementing pipelining soon, we divided our top into 5 different stages: `fetch.sv`, `decode.sv`, `execute.sv`, `memoryblock.sv`, `writeback.sv`.

2. **ALU Control Logic:**
   -   We implemented a **single-level decode architecture** where the control unit directly generates all ALU control signals from the instruction's `opcode`, `funct3`, and `funct7` fields in one combinational step, rather than using a two-level decode with an intermediate ALU decoder. This simplified the control logic and reduced decode latency at the cost of a slightly more complex control unit.


### Contributions

| Module                        | Asad | Nabeel | Marcus | Archit |
|-------------------------------|:----:|:------:|:------:|:------:|
| ALU.sv                        |  X   |        |        |        |
| controlunit.sv                |      |    X    |        |        |
| data_mem.sv                   |      |        |   X    |        |
| data_mem_i.sv                 |      |        |   X    |        |
| data_mem_o.sv                 |      |        |   X    |        |
| data_mem_top.sv               |      |        |   X    |        |
| extend.sv                     |  X    |        |        |        |
| instrmem.sv                   |      |       |    X    |        |
| pc_module.sv                  |   X   |       |        |        |
| regfile.sv                    |  X    |        |        |        |
| top.sv                        |  C   |   X    |    C    |       |
| System Testing & Debugging   |      |        |        |   X    |
| PDF Testing                  |      |        |        |   X    |
| F1 Testing                   |      |        |        |   X    |

`X` - Lead Contributor  `C` - Contributor

## File Structure

```
[NEED TO DO]
```

The processor development is done in the register transfer level (`rtl`) folder and the testing is performed in the test bench folder (`tb`).
The test bench folder contains:
- Assembly files (1 to 5 provided and f1_fsm) - in later versions
- `assemble.sh` - translating RISCV assembly to machine code
- `vbuddy_test` - Tests creating to verify RISCV performance with VBuddy (provided)
Other files are either a result of these files (testing outputs e.g. `*.vcd`) or were provided.

Note: only for this version, is the `tb` folder shown, this contains the tests and shows all other execution files

## Implementation
Instructions implemented:

| Type     | Instruction                                                    |
| -------- | -------------------------------------------------------------- |
| R        | `add` `sub` `xor` `or` `and` `sll` `srl` `sra` `slt` `sltu`    |
| I (ALU)  | `addi` `xori` `ori` `andi` `slli` `srli` `srai` `slti` `sltiu` |
| I (load) | `lbu` `lw`                                                     |
| I (jump) | `jalr`                                                         |
| S        | `sb` `sw`                                                      |
| B        | `beq` `bne`                                                    |
| U        | `lui`                                                          |
| J        | `jal`                                                          |

## Testing
### Test cases
##### Note: if any of the videos fail to load, please find the videos in `./images/vbuddy_tests/`

For the tests provided (`1_addi_bne` `2_li_add` `3_lbu_sb` `4_jal_ret` `5_pdf`):

![Single cycle testing](/images/single-cycle-tests.png)

### F1
https://github.com/user-attachments/assets/d6e40790-56d4-4d95-b67c-37f45b6d86d5

### PDF: Gaussian
https://github.com/user-attachments/assets/78df51d1-e5ad-4024-bef0-96da9c50b70a

### PDF: Noisy
https://github.com/user-attachments/assets/eef1a4e2-7991-4c1d-afa6-7ff94e41b589

### PDF: Triangle
https://github.com/user-attachments/assets/07633f81-343f-42c6-8fd5-e5dfc97a4d0a

### PDF: Sine
https://github.com/user-attachments/assets/fc73e31b-ed6a-421a-bb6c-efd21d2088e7

---
# Pipelined RISC-V CPU

## Overview
The pipelined implementation supports the full RV32I instruction set, dividing the processor into five main stages: fetch, decode, execute, memory and writeback. The fundamental principle of pipelining is parallel instruction execution, where different stages of multiple instructions are processed simultaneously. This architecture achieves higher throughput by overlapping the execution of multiple instructions, though at the cost of increased complexity in hazard detection and resolution. Together, these improvements result in faster program execution compared to the single-cycle variant.

## Schematic
![RISC-V 32I Pipelined implementation](images/Pipelined.png)

## Contributions

| Module / Task               | Asad | Nabeel | Marcus | Archit |
|-----------------------------|:----:|:------:|:------:|:------:|
| fetch.sv                    |  X   |        |        |        |
| decode.sv                   |  X   |        |        |        |
| execute.sv                  |  X   |   C    |        |        |
| memoryblock.sv              |      |   X    |        |        |
| writeback.sv                |      |   X    |        |        |
| top.sv                      |  C   |   C    |   C     |        |
| hazardunit.sv               |     |    X    |        |        |
| pipereg_FD_1.sv            |      |        |   X    |        |
| pipereg_DE_1.sv              | X     |        |   C     |        |
| pipereg_EM_1.sv             |      |        |   X    |        |
| pipereg_MW_1.sv             |      |        |    X    |        |
| System Testing & Debugging  |      |        |        |   X    |
| PDF Testing                 |      |        |        |   X    |
| F1 Testing                  |      |        |        |   X    |

`X` - Lead Contributor   `C` - Contributor
## File Structure
```
[NEED TO DO]
```
## Implementation
Transitioning from single-cycle to pipelined introduces various significant changes to the design structure. Combined with the full RV32I instruction set, there are many new modules and concepts in the pipelined version.

### Implementation Details

1. **Pipeline Registers:**
   - Four pipeline registers separate the five processor stages: Fetch/Decode (FD), Decode/Execute (DE), Execute/Memory (EM), and Memory/Writeback (MW)
   - Store all instruction data, control signals, and intermediate results required for the next stage

2. **Enhanced Control Unit Signals:**
   - **Branch/Jump Flags:** Determine branch evaluation and control flow changes in the execute stage
   - **UpperOp Flag:** Enables upper immediate operations for LUI and AUIPC instructions
   - **Memory Operation Flags:** Drive the load/store parsing unit for correct byte/halfword/word handling
   - All control signals propagate through pipeline registers to maintain instruction context

3. **Branch Resolution:**
   - Branch decisions made in the execute stage using ALU comparison results
   - Branch target address calculated using dedicated adder (PC + sign-extended immediate)
   - One-cycle branch penalty when branch is taken due to instruction fetch already in progress

4. **Hazard Detection Unit:**
   - **Data Hazard Detection:** Compares source register addresses in decode/execute stages with destination registers in execute/memory/writeback stages
   - **Forwarding Paths:** Three forwarding multiplexers route correct data (EX/MEM result, MEM/WB result, or register file data) to ALU inputs
   - **Stalling:** Inserts NOPs when load-use hazard detected (data needed before available from memory)
   - Forwarding priorities: Most recent result takes precedence (EX/MEM → MEM/WB → Register File)

5. **Pipeline Flushing:**
   - Converts instructions in fetch and decode stages to NOPs when branch/jump taken
   - Prevents incorrect instructions from executing after control flow change
   - Implemented by clearing control signals in FD and DE pipeline registers


## Testing
### Test Cases: 1-5
For the tests provided in the repo `tb` file, (`1_addi_bne` `2_li_add` `3_lbu_sb` `4_jal_ret` `5_pdf`):

![pipelined tb case 1-5 testing](images/pipelined-testcases1-5.png)


We also ran the same `pdf` and `f1_fsm` tests on Vbuddy, and observed the similar outputs as in single-cycle.

---
# Data Memory Cache

## Overview

Cache memory in RISC-V employs direct-mapped, set-associative, or fully associative mapping to determine data placement, in this implementation we utilise 2-way set associative cache.
**Tags** and **valid bits** identify cached data, while **replacement policies** like LRU handle evictions. Write policies such as **write-through** and **write-back** manage consistency between cache and memory.
These techniques ensure efficient data access, reducing latency and leveraging locality principles for optimised performance.  
## Schematic
![](/images/cache-schematic.png)
## Contributions

| Module / Task                | Asad | Marcus |
|------------------------------|------|--------|
| data_cache.sv                |      |   X    |
| memoryblock.sv               |   X  |        |
| Single-cycle cache           |   X  |   C    |
| Pipelined cache              |      |   X    |
| System Testing & Debugging   |   C  |   X    |
   

`X` - Lead Contributor   `C` - Contributor
## File Structure
```
.
├── rtl
│   ├── adder.sv
│   ├── decode
│   │   ├── control.sv
│   │   ├── decode_top.sv
│   │   ├── reg_file.sv
│   │   └── signextend.sv
│   ├── execute
│   │   ├── alu.sv
│   │   └── execute_top.sv
│   ├── fetch
│   │   ├── fetch_top.sv
│   │   ├── instr_mem.sv
│   │   └── pc_register.sv
│   ├── memory
│   │   ├── memory_top.sv
│   │   ├── ram2port.sv
│   │   ├── sram.sv
│   │   ├── two_way_cache_controller.sv
│   │   └── two_way_cache_top.sv
│   ├── mux.sv
│   ├── mux_4x2.sv
│   └── top.sv
└── tb
```
## Implementation
The two-way set-associative cache design consists of the following components:
1. Cache Controller:
    - Manages cache operations such as hits, misses, evictions, and updates.
    - Tracks the valid bits, dirty bits, and tags for each block in a set.
    - Uses an LRU (Least Recently Used) bit to determine which block to evict on a miss.
    - Handles read and write operations:
        - On a cache hit, data is retrieved or updated directly in the cache.
        - On a cache miss, the controller fetches the data from RAM, updates the cache, and potentially writes back evicted data if dirty.
2. Top Module (For cache):
    - Instantiates the cache controller and connects it to the SRAM.
    - Extracts the set index, tag, and byte offset from the input address.
    - Handles interactions between the cache controller and the SRAM, ensuring consistency between cache and main memory.
3. **Cache Structure**:
    - Each set contains:
        - Two data blocks with corresponding valid, dirty, and tag bits.
        - An LRU bit to track usage.
    - Designed to store 32-bit data across 512 sets (1024 words in total).

This implementation efficiently handles data locality with low-latency access on hits and ensures correctness during evictions using write-back and read-through policies.

## Testing

  For unit testing, we initially setup the environment to provide clear debug information and supports waveform analysis for issue tracking with gtkwave and also outputting variable status in between. We were then able to analyse the following through test cases:
- Basic read and write operations perform correctly in isolation.
- Proper handling of read and write hits for word and byte addressing.
- Eviction Logic
- Write Miss Handling
- LRU Replacement policy and fetching from memory

Moving onto the given test cases, we can see that the complete execution takes 646 ms in comparison to the 1054 ms for the single cycle model.

![Cache testing](images/cache-testing.png)

We also ran the same `pdf` and `f1_fsm` tests on Vbuddy, and observed the similar outputs as in single-cycle.

---
# Complete RISCV CPU

## Overview
The complete system integration for a RISC-V project involves implementing all instructions defined by the RISC-V instruction set architecture.
Here, we integrate a cache system to enhance memory access speed and reduce latency (seen in the `cache` branch). 
Pipelining is incorporated to improve throughput by enabling the concurrent execution of multiple instructions (from `pipelined` branch).  
The design ensures that each component, including the cache and pipeline, operates cohesively for optimal performance. This integration results in a high-performance RISC-V processor capable of handling complex tasks efficiently.

## Schematic
![RISC-V 32I Pipelined + Cache implementation](images/Complete.png)

## Contributions



`X` - Lead Contributor   `C` - Contributor
## File Structure
```
RISCV-Team04/
│
├── rtl/
│   ├── ALU.sv
│   ├── controlunit.sv
│   ├── data_cache.sv
│   ├── data_mem.sv
│   ├── data_mem_i.sv
│   ├── data_mem_o.sv
│   ├── data_mem_top.sv
│   ├── decode.sv
│   ├── execute.sv
│   ├── extend.sv
│   ├── fetch.sv
│   ├── hazardunit.sv
│   ├── instrmem.sv
│   ├── memoryblock.sv
│   ├── mux.sv
│   ├── pc_module.sv
│   ├── pipereg_DE_1.sv
│   ├── pipereg_EM_1.sv
│   ├── pipereg_FD_1.sv
│   ├── pipereg_MW_1.sv
│   ├── program.hex
│   ├── regfile.sv
│   ├── top.sv
│   └── writeback.sv
│
├── tb/
│   ├── asm/
│   │   ├── 1_addi_bne.s
│   │   ├── 2_li_add.s
│   │   ├── 3_lbu_sb.s
│   │   ├── 4_jal_ret.s
│   │   ├── 5_pdf.s
│   │   ├── 6_all_instructions.s
│   │   ├── 7_control_hazards.s
│   │   └── 8_hazards.s
│   │
│   ├── reference/
│   │   ├── gaussian.mem
│   │   └── pdf.asm
│   │
│   ├── our_tests/
│   │   ├── ALU_tb.cpp
│   │   ├── base_testbench.h
│   │   ├── controlunit_tb.cpp
│   │   ├── cpu_testbench.h
│   │   ├── data_mem_1_tb.cpp
│   │   ├── data_mem_0_tb.cpp
│   │   ├── data_mem_tb.cpp
│   │   ├── data_mem_top_tb.cpp
│   │   └── verify.cpp
│   │
│   ├── assemble.sh
│   ├── doit.sh
│   ├── testall.sh
│   └── .gitignore
│
├── statements/
│   ├── Archit.md
│   ├── Asad.md
│   └── Nabeel.md
│   └── Marcus.md
│
├── .gitignore
└── README.md
```

Only key relevant files are shown over here.

## Implementation
The implementation of the complete version remains structurally similar to the pipelined, full RV32I version. Note that with the addition of cache, the CPU now stalls upon a cache miss in order to better emulate a real-world processsor.

## Testing
### Test Cases 1-8
Similar to pipelined, test cases 1-8 assess the full RV32I instruction set for the complete version. 

![alt text](images/complete-vers-testcase.png)

All tests pass as expected.

We also ran the same `pdf` and `f1_fsm` tests on Vbuddy, and observed the similar outputs as in single-cycle.

---
# Superscalar
## Overview

A simplified superscalar RISC-V processor that can execute two independent instructions simultaneously in a single clock cycle, achieving up to 2x throughput compared to a traditional scalar processor.
## Design Simplifications

- No hazard detection: Since it's non-pipelined, we assume independent instructions
- No memory operations: Only arithmetic to avoid memory port conflicts
- No branches

Implementing only I/R type instructions greatly reduced the complexity. It removed the need for a data memory and meant only the ALU had to be duplicated.

# Appendix
### A. Design Philosophy & Decisions

#### Modular Design Approach

Our design emphasizes modularity and reusability:

1. **Clear Interfaces:** Each module has well-defined inputs/outputs
2. **Hierarchical Structure:** Top-level modules composed of sub-modules
3. **Parameterisation:** Configurable data widths and memory sizes
4. **Encapsulation:** Internal signals hidden from parent modules

#### Coding Standards

We followed industry best practices:

- **Naming Conventions:**
  - `_i` suffix for module inputs
  - `_o` suffix for module outputs
  
- **Documentation:**

  - Inline comments for complex logic
  - Signal descriptions in port lists

- **Version Control:**
  - Meaningful commit messages
  - Feature branches for major changes
  - Code reviews before merging

### B. References & Resources
  #### Official RISC-V Documentation

- [RISC-V Specification v2.2](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf)
- [RISC-V Instruction Set Manual](https://github.com/riscv/riscv-isa-manual)


#### Textbooks

- *Computer Organization and Design: RISC-V Edition* by Patterson & Hennessy
- *Digital Design and Computer Architecture: RISC-V Edition* by Harris & Harris

