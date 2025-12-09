# Execute Module Port Updates - Complete Integration ✅

## Summary of Changes

The `top.sv` file has been successfully updated to match all the port changes made in `execute.sv`. The execute module now has pipelined control signals and outputs the PCSrcE signal directly.

## Key Changes to Execute Module Ports

### Inputs Changed

#### Removed Individual Control Signals:
- ❌ `ALUCtrl_i` 
- ❌ `JumpCtrl_i`
- ❌ `ALUSrcB_i`
- ❌ `ALUSrcA_i`

#### Added Pipelined Control Inputs:
```systemverilog
input logic                     RegWriteE_i,
input logic [1:0]               ResultSrcE_i,
input logic                     MemWriteE_i,
input logic                     JumpE_i,
input logic                     BranchE_i,
input logic [3:0]               ALUCtrlE_i,
input logic                     ALUSrcE_i,
```

**Why?** These signals now come already pipelined from the D/E pipeline register, avoiding redundant logic.

### Outputs Changed

#### Added:
```systemverilog
output logic                    PCSrcE_o
```

**Why?** The execute module now computes PCSrcE internally from `branchTaken_o | JumpE_i`, eliminating the need for external computation in top.sv.

## Updated Execute Instantiation in top.sv

### Before:
```systemverilog
execute execute(
    .RD1E_i(RD1E), .RD2E_i(RD2E), .PCE_i(PCE),
    .ImmExtE_i(ImmExtE), .PCPlus4E_i(PCPlus4E),
    .ALUCtrl_i(ALUCtrlE),        // ❌ Old port
    .ALUSrcB_i(ALUSrcE),         // ❌ Old port
    .ALUSrcA_i(1'b0),            // ❌ Old port
    .JumpCtrl_i(JumpE),          // ❌ Old port
    .RdD_i(RDE),
    .BranchSrc_i({1'b0, BranchE}),
    .Rs1D_i(A1D),
    .Rs2D_i(A2D),
    .ResultW_i(ResultW),
    .ALUResultM_i(ALUResultM),
    .ForwardAEctrl_i(ForwardAE),
    .ForwardBEctrl_i(ForwardBE),

    .Rs1E_o(Rs1E_out), .Rs2E_o(Rs2E_out),
    .ALUResultE_o(ALUResultE), .WriteDataE_o(WriteDataE),
    .PCPlus4E_o(pcplus4_dummy_e), .PCTargetE_o(PCTargetE),
    .RdE_o(RdE_out), .branchTaken_o(BranchTakenE)
);

assign PCSrcE = BranchTakenE | JumpE;  // ❌ Old computation
```

### After:
```systemverilog
execute execute(
    .RD1E_i(RD1E),
    .RD2E_i(RD2E),
    .PCE_i(PCE),
    .ImmExtE_i(ImmExtE),
    .PCPlus4E_i(PCPlus4E),
    .RdD_i(RDE),
    .BranchSrc_i({1'b0, BranchE}),
    .Rs1D_i(A1D),
    .Rs2D_i(A2D),
    .ResultW_i(ResultW),
    .ALUResultM_i(ALUResultM),
    
    // Control inputs (pipelined from decode)
    .RegWriteE_i(RegWriteE),      // ✅ New port
    .ResultSrcE_i(ResultSrcE),    // ✅ New port
    .MemWriteE_i(MemWriteE),      // ✅ New port
    .JumpE_i(JumpE),              // ✅ New port (pipelined)
    .BranchE_i(BranchE),          // ✅ New port (pipelined)
    .ALUCtrlE_i(ALUCtrlE),        // ✅ New port (pipelined)
    .ALUSrcE_i(ALUSrcE),          // ✅ New port (pipelined)
    
    // From hazard unit
    .ForwardAEctrl_i(ForwardAE),
    .ForwardBEctrl_i(ForwardBE),

    // Outputs
    .Rs1E_o(Rs1E_out),
    .Rs2E_o(Rs2E_out),
    .ALUResultE_o(ALUResultE),
    .WriteDataE_o(WriteDataE),
    .PCPlus4E_o(pcplus4_dummy_e),
    .RdE_o(RdE_out),
    .branchTaken_o(BranchTakenE),
    .PCTargetE_o(PCTargetE),
    .PCSrcE_o(PCSrcE)            // ✅ New output
);

// PCSrcE computation now handled inside execute module
```

## Port Mapping Summary

| Signal | Type | Source | Destination | Change |
|--------|------|--------|-------------|--------|
| RegWriteE_i | Input | D/E reg output | Execute | ✅ New |
| ResultSrcE_i | Input[1:0] | D/E reg output | Execute | ✅ New |
| MemWriteE_i | Input | D/E reg output | Execute | ✅ New |
| JumpE_i | Input | D/E reg output | Execute | ✅ Moved (was individual) |
| BranchE_i | Input | D/E reg output | Execute | ✅ Moved (was individual) |
| ALUCtrlE_i | Input[3:0] | D/E reg output | Execute | ✅ Moved (was individual) |
| ALUSrcE_i | Input | D/E reg output | Execute | ✅ Moved (was individual) |
| PCSrcE_o | Output | Execute | Fetch | ✅ New |

## Logic Improvements

### Before:
```
D/E Register outputs → Execute receives individual signals
                    → Compute PCSrcE = BranchTakenE | JumpE in top.sv
                    → Feed back to Fetch
```

### After:
```
D/E Register outputs → Execute (already pipelined)
                    → Execute computes PCSrcE internally
                    → Feed back to Fetch
```

**Benefits:**
- ✅ Cleaner signal organization
- ✅ Control signals properly grouped
- ✅ Single source of truth for PCSrcE computation
- ✅ Execute module is more self-contained
- ✅ Easier to maintain and debug

## Files Modified

### `/home/inciendary/Documents/iac/RISC-V/RISC-V/RISC-V/rtl/top.sv`
- **Lines 189-228**: Updated execute instantiation with new ports
- **Removed**: `assign PCSrcE = BranchTakenE | JumpE;`

### `/home/inciendary/Documents/iac/RISC-V/RISC-V/RISC-V/rtl/execute.sv`
- (Already updated in previous iterations)

## Verification

✅ **No compilation errors** in top.sv
✅ **All execute ports correctly mapped**
✅ **Control signals properly routed from D/E pipeline register**
✅ **PCSrcE now sourced directly from execute module**
✅ **Pipeline architecture maintains proper data flow**

## Complete Signal Flow (Execute Stage)

```
D/E Pipeline Register
├── RegWriteE ──────────→ .RegWriteE_i
├── ResultSrcE ─────────→ .ResultSrcE_i
├── MemWriteE ──────────→ .MemWriteE_i
├── JumpE ──────────────→ .JumpE_i
├── BranchE ────────────→ .BranchE_i
├── ALUCtrlE ────────────→ .ALUCtrlE_i
├── ALUSrcE ────────────→ .ALUSrcE_i
├── RD1E ───────────────→ .RD1E_i
├── RD2E ───────────────→ .RD2E_i
├── PCE ────────────────→ .PCE_i
├── ImmExtE ────────────→ .ImmExtE_i
├── PCPlus4E ────────────→ .PCPlus4E_i
└── RDE ────────────────→ .RdD_i

Execute Module (Internal Processing)
├── Forwards: RD1/RD2 based on hazard unit signals
├── Computes: ALU result, branch decision
├── Computes: PCSrcE = branchTaken | JumpE
└── Outputs:
    ├── ALUResultE ──────→ E/M Register
    ├── WriteDataE ──────→ E/M Register
    ├── RdE_o ──────────→ E/M Register (via pipeline)
    ├── PCTargetE ──────→ Fetch (branch target)
    ├── PCSrcE_o ───────→ Fetch (branch signal)
    ├── branchTaken_o ──→ Hazard Unit
    ├── Rs1E_o ────────→ Hazard Unit
    └── Rs2E_o ────────→ Hazard Unit
```

The execute stage integration is now complete with all ports correctly aligned! 🎯
