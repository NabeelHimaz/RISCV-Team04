# Personal Statement 

***Nabeel***

This document provides a comprehensive overview of my contributions to the RISC-V project. It outlines the completed work, the methodologies employed, the rationale behind key design decisions, the strategies used to address challenges, any mistakes encountered along the way and their subsequent resolution, as well as the insights and lessons learned from this experience.

---

# Single Cycle RISCV-32I Design

## Control Unit
[System Verilog](../rtl/decode/controlunit.sv) | [Testbench with test cases](../tb/our_tests/control_test_tb.cpp) | [Shell script for testing](../tb/bash/control_test.sh)

### Aims
- Create a module that decodes the 32-bit instruction and produces the required control signals
- Support all RISC-V 32I instruction types with correct control signal generation
- Implement branch decision logic for all six branch types
- Handle memory operations with byte, halfword, and word addressing
- Support both signed and unsigned loads

### Implementation
The control unit is the "brain" of the processor, generating all control signals based on the instruction opcode and function fields. The inputs and outputs are:

**Inputs:**
- `Instr_i` - 32-bit instruction containing opcode, funct3, funct7
- `branchTaken_i` - Branch decision from ALU (based on comparison result)

**Outputs:**
- `RegWrite_o` - Enable writing to register file
- `ALUCtrl_o` - 4-bit ALU operation select
- `ALUSrcB_o` - Select immediate (1) or register (0) for ALU operand B
- `ALUSrcA_o` - Select PC (1) or register (0) for ALU operand A (for AUIPC)
- `ImmSrc_o` - 3-bit select for immediate extraction format
- `PCSrc_o` - Select next PC source (sequential or jump/branch target)
- `MemWrite_o` - Enable writing to data memory
- `ResultSrc_o` - 2-bit select for result to write back to register
- `MemType_o` - 2-bit select for memory access size (byte/half/word)
- `MemSign_o` - Select signed (1) or unsigned (0) load extension
- `JumpSrc_o` - Select between JAL (0) and JALR (1) for jump target
- `Branch_o` - 3-bit branch type encoding

The control unit extracts key instruction fields:
```systemverilog
logic [6:0]     op;
logic           funct7_5;
logic [2:0]     funct3;

assign op       = Instr_i[6:0];
assign funct3   = Instr_i[14:12];
assign funct7_5 = Instr_i[30];
```

### Instruction Decoding by Type

**Key Design Decision**: Used `MemType_o` to specify access size and `MemSign_o` to control sign extension, allowing data memory to handle all load variants correctly.

#### Arithmetic Instructions (I-type and R-type, opcodes = 7'd19, 7'd51)
Handles all ALU operations including ADDI, SUBI, SLTI, XORI, ORI, ANDI, shifts, and their register variants:
```systemverilog
7'd19, 7'd51: begin                                             
    Branch_o = 3'b010;  //Not a branch                                  

    case(funct3)
        3'b000: ALUCtrl_o = (funct7_5 && (op != 7'd19)) ? 4'b0001 : 4'b0000;  //SUB, ADD
        ...
```

**Key Design Decision**: Used `funct7_5` (bit 30 of instruction) to distinguish SUB from ADD and SRA from SRL. Prevented SUB encoding for I-type by checking `op != 7'd19`.

#### Upper Immediate Instructions (U-type, opcodes = 7'd23, 7'd55)
Handles LUI and AUIPC:
```systemverilog
7'd23, 7'd55: begin  //LUI, AUIPC
    ImmSrc_o    = 3'b011;  //Extract upper 20 bits
    ALUCtrl_o   = 4'b0000; //ADD
    Branch_o    = 3'b010;  //Not a branch
end
```

**Note**: AUIPC uses `ALUSrcA_o = 1` to select PC instead of register value, implemented in the always_comb block.

#### Branch Instructions (B-type, opcode = 7'd99)
Handles all six branch types: BEQ, BNE, BLT, BGE, BLTU, BGEU:
```systemverilog
7'd99: begin  //B-type
    ImmSrc_o    = 3'b010;  //B-type immediate format
    ALUCtrl_o   = 4'b0000; //ADD for target calculation
    
    case(funct3)
        3'b000: Branch_o = 3'b000;  //BEQ
        3'b001: Branch_o = 3'b001;  //BNE
        3'b100: Branch_o = 3'b100;  //BLT
        3'b101: Branch_o = 3'b101;  //BGE
        3'b110: Branch_o = 3'b110;  //BLTU
        3'b111: Branch_o = 3'b111;  //BGEU
        default: Branch_o = 3'b010; //Not a branch
    endcase
end
```

**Branch Encoding Design**:
The 3-bit `Branch_o` signal is decoded elsewhere to determine if branch is taken:
- `Branch_o[2:1]` selects comparison type (equal, less than signed, less than unsigned)
- `Branch_o[0]` selects polarity (equal vs not equal, less than vs greater/equal)
- `3'b010` indicates no branch

#### Jump Instructions (J-type and I-type, opcodes = 7'd103, 7'd111)

**JALR (opcode = 7'd103)**:
```systemverilog
7'd103: begin  //JALR   
    ImmSrc_o  = 3'b000;  //I-type immediate [31:20]
    ALUCtrl_o = 4'b0000; //ADD for target (rs1 + imm)
    PCSrc_o   = 1;       //Take jump
end
```

**JAL (opcode = 7'd111)**:
```systemverilog
7'd111: begin  //JAL
    ImmSrc_o  = 3'b100;  //J-type immediate format
    ALUCtrl_o = 4'b0000; //ADD for target (PC + imm)
    PCSrc_o   = 1;       //Take jump
end
```

### Common Control Signal Generation

The second `always_comb` block generates control signals that depend on opcode but not funct3/funct7:
```systemverilog
always_comb begin
    //Memory write only for store instructions
    MemWrite_o  = (op == 7'd35) ? 1'b1 : 1'b0;
    
    //Register write disabled for stores and branches only
    RegWrite_o  = (op == 7'd35 || op == 7'd99) ? 1'b0 : 1'b1; 
    
    //ALU source B: immediate for all except R-type and branches
    ALUSrcB_o   = (op == 7'd51 || op == 7'd99) ? 1'b0 : 1'b1;
    
    //PC source: jump for JAL/JALR, or branch if taken
    PCSrc_o     = (op == 7'd103 || op == 7'd111 || (op == 7'd99 && branchTaken_i)) ? 1'b1 : 1'b0;
    
    //Jump source: JALR uses rs1+imm, JAL uses PC+imm
    JumpSrc_o   = (op == 7'd103) ? 1'b1 : 1'b0;
    
    //ALU source A: PC for AUIPC, register otherwise
    ALUSrcA_o   = (op == 7'd23) ? 1'b1 : 1'b0;

    if (op == 7'd3)                         //Loads: use data from memory
        ResultSrc_o = 2'b01;
    else if (op == 7'd103 || op == 7'd111)  //JAL/JALR: use PC+4
        ResultSrc_o = 2'b10;
    else                                    //Default: use ALU result
        ResultSrc_o = 2'b00;
end
```

### Control Signal Summary Table

| **Instruction** | **RegWrite** | **ALUSrc** | **MemWrite** | **ResultSrc** | **PCSrc** | **Branch** | **ALUCtrl** |
|-----------------|--------------|------------|--------------|---------------|-----------|------------|-------------|
| R-type          | 1            | 0          | 0            | 00            | 0         | 010        | by funct3   |
| I-type (ALU)    | 1            | 1          | 0            | 00            | 0         | 010        | by funct3   |
| I-type (load)   | 1            | 1          | 0            | 01            | 0         | 010        | 0000        |
| S-type          | 0            | 1          | 1            | XX            | 0         | 010        | 0000        |
| B-type          | 0            | 0          | 0            | XX            | by taken  | by funct3  | 0000        |
| JAL             | 1            | 1          | 0            | 10            | 1         | 010        | 0000        |
| JALR            | 1            | 1          | 0            | 10            | 1         | 010        | 0000        |
| LUI             | 1            | 1          | 0            | 00            | 0         | 010        | 0000        |
| AUIPC           | 1            | 1          | 0            | 00            | 0         | 010        | 0000        |


### Challenges and Solutions

**Challenge 1: Memory Access Control**
- **Problem**: Initially didn't have proper control for byte/halfword loads and stores
- **Solution**: Added `MemType_o` and `MemSign_o` signals to handle all memory access variants

**Challenge 2: ALU Operation Encoding**
- **Problem**: Distinguishing SUB from ADD and SRA from SRL using limited instruction bits
- **Solution**: Used `funct7_5` (bit 30) as distinguisher, checked opcode to prevent SUB for I-type

**Challenge 3: Branch Logic Complexity**
- **Problem**: Six different branch types need different comparison logic
- **Solution**: Encoded branch type in 3-bit `Branch_o` signal, decoded by ALU/branch unit

**Challenge 4: Result Multiplexer Control**
- **Problem**: Different instructions write different data back to registers (ALU result, memory data, PC+4)
- **Solution**: Used 2-bit `ResultSrc_o` to select from three sources

**Challenge 5: Jump Instruction Differences**
- **Problem**: JAL and JALR compute targets differently (PC+imm vs rs1+imm)
- **Solution**: Added `JumpSrc_o` signal to select correct target calculation

### Design Decisions and Rationale

**Decision 1: Separate Memory Type and Sign Signals**
Rather than encoding all load/store variants in a single signal, I used:
- `MemType_o` for size (byte/half/word)
- `MemSign_o` for sign extension

**Rationale**: Separates orthogonal concerns, makes memory unit logic cleaner

**Decision 2: 3-bit Branch Encoding**
Encoded branch type rather than generating branch decision in control unit

**Rationale**: Branch decision requires flag inputs which come from ALU; better separation of concerns

---

## Single Cycle CPU Debugging and Testing

### System Debugging Process

I used GTKWave extensively for waveform analysis

### Critical Bugs Found and Fixed

#### Bug 1: Branch Target Calculation Error
**Problem**: Branches were jumping to incorrect addresses, sometimes causing program to execute invalid instructions or loop incorrectly.

**Root Cause**: Operator precedence issue in expression `PC + ImmOp << 2`
- SystemVerilog shifts PC instead of ImmOp
- Should be `PC + (ImmOp << 2)`

**Solution**: Added explicit parentheses in PC target calculation

#### Bug 2: JAL Byte Addressing Issue
**Problem**: JAL instruction jumping to addresses 4x too large, causing immediate crash or wrong function calls.

**Key Discovery**: JAL immediate has implicit `0` at LSB (bit 0) for byte addressing
- Instruction encodes bits [20:1] of offset
- Bit [0] is always 0 (instructions are 4-byte aligned)
- Must shift immediate left by 1 before using

**Root Cause**: data_mem wasn't accounting for implicit left shift

**Solution**: Updated sign extension for J-type immediates to include left shift

### Debugging Tools and Techniques Developed

**GTKWave Signal Organization**:
- Grouped signals by pipeline stage
- Used markers for instruction boundaries
- Created saved signal configurations for reuse

**Systematic Verification Checklist**:
For each instruction execution, verified:
1. Instruction fetch from correct PC
2. Control signals match instruction type
3. Register file reads correct operands
4. ALU performs correct operation
5. Memory access (if applicable) correct
6. Result written to correct register
7. PC updates correctly

**Hand Calculations**:
- Manually calculated expected results for each instruction
- Compared against waveform values
- Caught errors in both hardware and test expectations

---

# Pipelined RISCV-32I Design

## Hazard Unit Implementation
[System Verilog](../rtl/hazard_unit.sv) | [Testbench with test cases](../tb/our_tests/hazard_unit_test_tb.cpp)

### Aims
- Detect and resolve pipeline hazards to maintain correct program execution
- Implement data forwarding to minimize pipeline stalls
- Handle load-use hazards with appropriate stalling
- Manage control hazards from branches and jumps
- Maximize pipeline throughput while ensuring correctness

### Background: Pipeline Hazards

Pipeline execution introduces three types of hazards that can cause incorrect program behavior:

**1. Data Hazards (RAW - Read After Write)**
Occur when an instruction needs a value that a previous instruction hasn't written yet:
```assembly
add x1, x2, x3   # Writes x1 in cycle 5 (writeback stage)
sub x4, x1, x5   # Reads x1 in cycle 3 (execute stage) - too early
```

**2. Control Hazards**
Occur when branch/jump decision isn't known until execute stage, but next instructions already fetched:
```assembly
beq x1, x2, target   # Decision in cycle 3
add x3, x4, x5       # Already fetched in cycle 2 - might be wrong the instruction
```

**3. Structural Hazards**
Occur when multiple instructions need same hardware resource simultaneously. Not present in our design due to separate instruction/data memories.

### Implementation

**Inputs**:
- `Rs1_D`, `Rs2_D` - Source registers in decode stage
- `Rs1_E`, `Rs2_E` - Source registers in execute stage  
- `Rd_E` - Destination register in execute stage
- `Rd_M` - Destination register in memory stage
- `Rd_W` - Destination register in writeback stage
- `RegWrite_M`, `RegWrite_W` - Write enables for later stages
- `MemRead_E` - Indicates load instruction in execute stage
- `PCSrc` - Branch/jump taken signal
- `ResultSrc_E` - Result source in execute (identifies loads)

**Outputs**:
- `ForwardA_E`, `ForwardB_E` - 2-bit forwarding controls for ALU operands
- `Stall_F`, `Stall_D` - Stall signals for fetch and decode stages
- `Flush_D`, `Flush_E` - Flush signals to insert pipeline bubbles

### Data Hazard Detection and Forwarding

The most common hazard occurs when an instruction reads a register that a previous instruction hasn't finished writing:
```systemverilog
//Forwarding logic for first ALU operand (SrcA)
always_comb begin
    //1: Forward from Memory stage (most recent uncommitted write)
    if ((Rs1_E == Rd_M) && RegWrite_M && (Rd_M != 5'b0))
        ForwardA_E = 2'b10;  //Forward ALU result from memory stage
    //2: Forward from Writeback stage (older write)
    else if ((Rs1_E == Rd_W) && RegWrite_W && (Rd_W != 5'b0))
        ForwardA_E = 2'b01;  //Forward result from writeback stage
    //No hazard detected
    else
        ForwardA_E = 2'b00;  //Use value from register file (no forwarding)
end

//Identical logic for second ALU operand (SrcB)
always_comb begin
    if ((Rs2_E == Rd_M) && RegWrite_M && (Rd_M != 5'b0))
        ForwardB_E = 2'b10;
    else if ((Rs2_E == Rd_W) && RegWrite_W && (Rd_W != 5'b0))
        ForwardB_E = 2'b01;
    else
        ForwardB_E = 2'b00;
end
```

**Forwarding Encoding**:
- `2'b00`: No forwarding, use register file output (no hazard)
- `2'b01`: Forward from writeback stage
- `2'b10`: Forward from memory stage (takes priority - most recent data)

**Key Design Decisions**:
1. **Priority**: Memory stage has priority over writeback because it contains more recent data
2. **Register x0**: Never forward from x0 (hardwired to zero) by checking `Rd != 5'b0`
3. **Write Enable**: Only forward if destination will actually be written (`RegWrite` signal)
4. **Separate Forwarding**: Independent control for each ALU operand allows different forwarding sources

**Example Scenario 1: Execute-to-Execute Forwarding**
```assembly
add x1, x2, x3   # Cycle 1: Writes x1
sub x4, x1, x5   # Cycle 2: Reads x1 (only 1 cycle apart!)
```
- Cycle 3: ADD in memory stage, SUB in execute stage
- SUB needs x1, ADD producing x1
- Hazard unit: `ForwardA_E = 2'b10` (forward from memory)
- Result: SUB gets correct x1 value, no stall needed

**Example Scenario 2: Memory-to-Execute Forwarding**
```assembly
add x1, x2, x3   # Cycle 1
nop              # Cycle 2
sub x4, x1, x5   # Cycle 3
```
- Cycle 4: ADD in writeback stage, SUB in execute stage
- Hazard unit: `ForwardA_E = 2'b01` (forward from writeback)
- Result: SUB gets correct x1 value

### Load-Use Hazard Detection

Load instructions create a special hazard because data isn't available until memory stage, but the immediately following instruction may need it in execute stage - forwarding isn't fast enough:
```systemverilog
//Detect load-use hazard (need to stall)
always_comb begin
    //Load instruction in execute stage producing result needed by instruction in decode stage
    if (ResultSrc_E == 2'b01 && ((Rd_E == Rs1_D) || (Rd_E == Rs2_D))) begin
        Stall_F = 1'b1;    //Stall fetch stage (hold PC)
        Stall_D = 1'b1;    //Stall decode stage 
        Flush_E = 1'b1;    //Insert bubble in execute stage (clear control signals)
    end else begin
        Stall_F = 1'b0;
        Stall_D = 1'b0;
        Flush_E = 1'b0;
    end
end
```

**Load-Use Hazard Example**:
```assembly
lw x1, 0(x2)     # Cycle 1: Load x1 (data available cycle 4)
add x3, x1, x4   # Cycle 2: Needs x1 (in execute = cycle 3) - TOO EARLY!
```

**Stall Behavior**:
- **Cycle 2**: Hazard detected (load in execute, add in decode needs loaded register)
  - `Stall_F = 1`, `Stall_D = 1`: Hold PC and IF/ID register
  - `Flush_E = 1`: Convert ADD in execute to NOP (bubble)
- **Cycle 3**: Stall continues, load moves to memory stage
- **Cycle 4**: Stall released, load in writeback, ADD can proceed with forwarding

**Why Stall is Necessary**:
- Load data not available until memory stage completes
- Following instruction in execute stage needs it
- Even with forwarding, data isn't ready in time
- One cycle stall allows data to become available for forwarding

**Key Design Decision**: Check `ResultSrc_E == 2'b01` instead of separate `MemRead_E` signal because it directly identifies load instructions producing memory data.

### Control Hazard Management

Branch and jump instructions cause control flow changes. The decision is made in execute stage, but by then two instructions have already been fetched that might be incorrect:
```systemverilog
//Flush pipeline on branch taken or jump
always_comb begin
    if (PCSrc) begin  //Branch taken or jump instruction
        Flush_D = 1'b1;  //Flush decode stage 
        Flush_E = 1'b1;  //Flush execute stage 
    end else begin
        Flush_D = 1'b0;
        Flush_E = 1'b0;
    end
end
```

**Control Hazard Example**:
```assembly
beq x1, x2, target   # Cycle 1: Branch decision in cycle 3
add x3, x4, x5       # Cycle 2: Incorrectly fetched
sub x6, x7, x8       # Cycle 3: Incorrectly fetched
target:
    or x9, x10, x11  # Correct target (should execute after branch)
```

**Flush Behavior**:
- **Cycle 1**: BEQ in decode, ADD fetched
- **Cycle 2**: BEQ in execute, ADD in decode, SUB fetched
- **Cycle 3**: BEQ decision made (taken), both ADD and SUB must be cancelled
  - `PCSrc = 1` triggers flush
  - `Flush_D = 1`, `Flush_E = 1`: Convert ADD and SUB to NOPs
  - PC updated to target
- **Cycle 4**: OR (correct instruction) fetched

**Performance Impact**: 2-cycle penalty for each taken branch/jump (two incorrectly fetched instructions flushed).

### Complete Hazard Unit Module

### Design Decisions and Rationale

**Decision 1: Two-Bit Forwarding Control**
Used 2-bit signals instead of separate mux controls for each forwarding source.

**Rationale**: 
- Clean abstraction for three-input mux
- Easily extendable if more forwarding sources needed
- Clear encoding (00 = no forward, 01 = WB, 10 = MEM)

**Decision 2: Separate Stall and Flush Signals**
Generated separate `Stall_F`, `Stall_D`, `Flush_D`, `Flush_E` instead of combined control.

**Rationale**:
- Different stages need different actions (stall vs flush)
- Clear semantics for each signal
- Easier to debug in waveforms

**Decision 3: Priority-Based Forwarding**
Memory stage always takes priority over writeback when both match.

**Rationale**:
- Memory stage contains more recent data
- Matches natural pipeline ordering
- Prevents forwarding stale data

**Decision 4: ResultSrc for Load Detection**
Check `ResultSrc_E == 2'b01` instead of separate MemRead signal.

**Rationale**:
- ResultSrc directly indicates memory-to-register data path
- More robust than tracking load opcodes separately
- Already available from control unit

---

## Pipeline Integration and Testing

### Control Unit Modifications for Pipeline

# Learnings and Project Summary

Working on the mainly of the Control Unit and the Hazard Unit helped me gain a strong understanding on how all the components withing the CPU work together. To construct the Control Unit, I had to fully understand the RISCV instruction set architecture and the control/data path. Creating the Hazard Unit deepened my understanding of pipelining and the critical importance of correctly managing data dependencies.

Debugging: tracing through waveforms to find subtle bugs, coordinating interfaces with teammates and ensuring every instruction executes properly was a gruelling task but was where I learnt the most. The satisfaction of seeing assembly programs execute correctly on hardware I helped design, knowing that the control signals generated by my control unit are orchestrating every single instruction was immensely rewarding.

---