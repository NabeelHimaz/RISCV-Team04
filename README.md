# RISC-V

# Table of Contents:

- [Quick Start](#quick-start)
- [Single Cycle CPU Implementation](#single-cycle)
- [Pipelined CPU Implementation](#pipelined-risc-v-cpu)
- [Cached Implementation](#data-memory-cache)
- [Complete RISC-V](#complete-riscv-cpu)
- [Appendix](#appendix)

# Quick Start
This repository contains our complete implementation of a RISC-V RV32I processor with several major design iterations.

We completed the Single-Cycle and all of the stretch goals (Pipelined, Two-Way Set Associative Write-Back Cache, Full RV32I Design). We started with the Stretch goal 3 first by doing the full implementation of the RV32I instruction set, and then naturally progressed into doing pipelining complete with hazard detection. 

 

| Branch | Description |
| ------ | ----------- |
|`main` | Full 32VI Single-Cycle Implementation |
|`Pipeline-registers` | Pipelined + Full RV32I Implementation |
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
cd ./tb
./doit.sh
```

This will execute all five provided test cases (`1_addi_bne`, `2_li_add`, `3_lbu_sb`, `4_jal_ret`, `5_pdf`) and verify correct execution.


For unit testing each module...
**ARCHIT FILL IN HERE**



#### Quick Start - Vbuddy Tests

##### **Windows only**: remember to include `~/Documents/iac/lab0-devtools/tools/attach_usb.sh` command to connect Vbuddy.

To run the f1 light test within the `./tb/` folder,

```bash
sudo chmod +x f1_test.sh
./f1_test.sh
```

To run the pdf test within the `./tb/` folder,
```bash
sudo chmod +x pdf_test.sh
./pdf_test.sh
```

Both `cpp` scripts can be found in `./tb/vbuddy_test`. The distribution for the pdf test can be changed by overwriting the distribution name in `./tb/vbuddy_test/pdf_tb.cpp` in line 13.
```cpp
// can change to "noisy" or "triangle"
const std::string distribution = "gaussian";
```

## Team Members & Contributions

### Team Details

| Team Member | GitHub | CID | Email | Personal Statement |
|-------------|--------|-----|-------|-------------------|
| [Team Member 1] | [@username1](https://github.com/username1) | [CID] | [email] | [Link to Statement](./statements/Member1.md) |
| [Team Member 2] | [@username2](https://github.com/username2) | [CID] | [email] | [Link to Statement](./statements/Member2.md) |
| [Team Member 3] | [@username3](https://github.com/username3) | [CID] | [email] | [Link to Statement](./statements/Member3.md) |
| [Team Member 4] | [@username4](https://github.com/username4) | [CID] | [email] | [Link to Statement](./statements/Member4.md) |


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

![Single-Cycle Architecture Diagram](./images/single-cycle-diagram.png)

*[Insert single-cycle architecture diagram here]*

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

| Module | Lead | Support | Description |
|--------|------|---------|-------------|
| **ALU** | | | Arithmetic and logic unit with full operation support |
| **Control Unit** | | | Generates all control signals based on opcode |
| **Register File** | | | 32 registers with dual read, single write ports |
| **Instruction Memory** | | | ROM containing program machine code |
| **Data Memory** | | | RAM for load/store operations |
| **PC Register** | | | Program counter with branch/jump support |
| **Sign Extend** | | | Immediate value sign extension logic |
| **Top Integration** | | | System-level integration and testing |
