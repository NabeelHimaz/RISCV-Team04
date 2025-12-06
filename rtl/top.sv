module top #(
    parameter DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    trigger,
    output logic [DATA_WIDTH-1:0]   a0
);

// --- Fetch Stage Signals ---
logic [DATA_WIDTH-1:0] PCPlus4F, PCF, InstrF;
logic                  PCSrcE; // Feedback from Execute stage

// --- Decode Stage Signals ---
logic [DATA_WIDTH-1:0] InstrD, PCD, PCPlus4D;
logic [DATA_WIDTH-1:0] RD1D, RD2D, ImmExtD;
logic [4:0]            A1D, A2D, A3D, RDD; // Register addresses
logic [DATA_WIDTH-1:0] a0_internal; // Test output

// Control Signals (Decode)
logic       RegWriteD, MemWriteD, ALUSrcD, MemSignD, JumpD, BranchD;
logic [1:0] ResultSrcD, MemTypeD;
logic [3:0] ALUCtrlD;
logic [2:0] ImmSrcD;

// --- Execute Stage Signals ---
logic [DATA_WIDTH-1:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
logic [4:0]            RDE;
logic [DATA_WIDTH-1:0] ALUResultE, WriteDataE, PCTargetE;
logic                  ZeroE;

// Control Signals (Execute)
logic       RegWriteE, MemWriteE, ALUSrcE, MemSignE, JumpE, BranchE;
logic [1:0] ResultSrcE, MemTypeE;
logic [3:0] ALUCtrlE;

// --- Memory Stage Signals ---
logic [DATA_WIDTH-1:0] ALUResultM, WriteDataM, PCPlus4M;
logic [DATA_WIDTH-1:0] ReadDataM;
logic [4:0]            RDM;

// Control Signals (Memory)
logic       RegWriteM, MemWriteM, MemSignM;
logic [1:0] ResultSrcM, MemTypeM;

// --- Writeback Stage Signals ---
logic [DATA_WIDTH-1:0] ALUResultW, ReadDataW, PCPlus4W, ResultW;
logic [4:0]            RDW;

// Control Signals (Writeback)
logic       RegWriteW;
logic [1:0] ResultSrcW;

// Note: A1, A2, A3 outputs from fetch are unused here because we extract them
// in the Decode stage from InstrD.
logic [4:0] unused_A1, unused_A2, unused_A3;

fetch fetch(
    .PCSrc_i(PCSrcE),           // Branch decision from Execute stage
    .clk(clk),
    .rst(rst),
    .PCTargetE_i(PCTargetE),    // Branch target from Execute stage

    .PC_Plus4_F(PCPlus4F),
    .PC_F(PCF),
    .Instr_o(InstrF),
    .A1_o(unused_A1), 
    .A2_o(unused_A2), 
    .A3_o(unused_A3)
);

// --- F/D Pipeline Registers ---
// Flush these on branch taken (PCSrcE)
pipereg #(DATA_WIDTH) reg_FD_Instr   (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(InstrF),   .q(InstrD));
pipereg #(DATA_WIDTH) reg_FD_PC      (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(PCF),      .q(PCD));
pipereg #(DATA_WIDTH) reg_FD_PCPlus4 (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(PCPlus4F), .q(PCPlus4D));

logic ctrl_PCSrc_unused; // The control unit calculates this but we regen it in Execute

controlunit controlunit (
    .Instr_i(InstrD),
    .Zero_i(1'b0),          // Zero is calculated in Execute, unused here

    .RegWrite_o(RegWriteD),
    .ALUCtrl_o(ALUCtrlD),     
    .ALUSrc_o(ALUSrcD),
    .ImmSrc_o(ImmSrcD),       
    .PCSrc_o(ctrl_PCSrc_unused), // Ignored
    .MemWrite_o(MemWriteD),    
    .ResultSrc_o(ResultSrcD),
    .MemSign_o(MemSignD),
    .MemType_o(MemTypeD)
);

// Identify Jump/Branch instructions locally for pipeline control
assign BranchD = (InstrD[6:0] == 7'd99);
assign JumpD   = (InstrD[6:0] == 7'd111 || InstrD[6:0] == 7'd103);

assign A1D = InstrD[19:15];
assign A2D = InstrD[24:20];
assign RDD = InstrD[11:7]; // Destination Register

// Dummy wires for unused decode outputs (since we use pipeline regs)
logic [DATA_WIDTH-1:0] pcplus4_dummy_d, pc_dummy_d;

decode decode(
    .ImmSrc_i(ImmSrcD),
    .PC_Plus4_F_i(PCPlus4D),
    .PC_F_i(PCD),
    .clk(clk),
    .A1_i(A1D),
    .A2_i(A2D),
    .A3_i(RDW),             // Writeback Address from W stage
    .instr_i(InstrD),
    .WD3_i(ResultW),        // Writeback Data from W stage
    .WE3_i(RegWriteW),      // Writeback Enable from W stage

    .RD1_o(RD1D),
    .RD2_o(RD2D),
    .ImmExtD_o(ImmExtD),
    .PC_Plus4D_o(pcplus4_dummy_d),
    .PCD_o(pc_dummy_d), 
    .a0_o(a0_internal)
);

// Output a0 for testing
assign a0 = a0_internal;

// --- D/E Pipeline Registers ---
// Control Signals
pipereg #(1) reg_DE_RegWrite (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(RegWriteD), .q(RegWriteE));
pipereg #(1) reg_DE_MemWrite (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(MemWriteD), .q(MemWriteE));
pipereg #(1) reg_DE_Jump     (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(JumpD),     .q(JumpE));
pipereg #(1) reg_DE_Branch   (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(BranchD),   .q(BranchE));
pipereg #(1) reg_DE_ALUSrc   (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(ALUSrcD),   .q(ALUSrcE));
pipereg #(1) reg_DE_MemSign  (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(MemSignD),  .q(MemSignE));
pipereg #(2) reg_DE_ResultSrc(.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(ResultSrcD),.q(ResultSrcE));
pipereg #(2) reg_DE_MemType  (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(MemTypeD),  .q(MemTypeE));
pipereg #(4) reg_DE_ALUCtrl  (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(ALUCtrlD),  .q(ALUCtrlE));

// Data Signals
pipereg #(DATA_WIDTH) reg_DE_RD1     (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(RD1D),     .q(RD1E));
pipereg #(DATA_WIDTH) reg_DE_RD2     (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(RD2D),     .q(RD2E));
pipereg #(DATA_WIDTH) reg_DE_PC      (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(PCD),      .q(PCE));
pipereg #(DATA_WIDTH) reg_DE_ImmExt  (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(ImmExtD),  .q(ImmExtE));
pipereg #(DATA_WIDTH) reg_DE_PCPlus4 (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(PCPlus4D), .q(PCPlus4E));
pipereg #(5)          reg_DE_RD      (.clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE), .d(RDD),      .q(RDE));

logic [DATA_WIDTH-1:0] pcplus4_dummy_e;

execute execute(
    .RD1E_i(RD1E),
    .RD2E_i(RD2E),
    .PCE_i(PCE),
    .ImmExtE_i(ImmExtE),
    .PCPlus4E_i(PCPlus4E),
    .ALUCtrl_i(ALUCtrlE),
    .ALUSrc_i(ALUSrcE),
    .JumpCtrl_i(JumpE),  // Renamed to match your execute.sv port

    .ALUResultE_o(ALUResultE),
    .WriteDataE_o(WriteDataE),
    .PCPlus4E_o(pcplus4_dummy_e),
    .PCTargetE_o(PCTargetE),
    .Zero_o(ZeroE)
);

// Branch Logic: Decides whether to take branch/jump (Feedback to Fetch)
assign PCSrcE = (BranchE & ZeroE) | JumpE;

// --- E/M Pipeline Registers ---
// Control Signals
pipereg #(1) reg_EM_RegWrite (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(RegWriteE), .q(RegWriteM));
pipereg #(1) reg_EM_MemWrite (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(MemWriteE), .q(MemWriteM));
pipereg #(1) reg_EM_MemSign  (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(MemSignE),  .q(MemSignM));
pipereg #(2) reg_EM_ResultSrc(.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(ResultSrcE),.q(ResultSrcM));
pipereg #(2) reg_EM_MemType  (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(MemTypeE),  .q(MemTypeM));

// Data Signals
pipereg #(DATA_WIDTH) reg_EM_ALURes  (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(ALUResultE), .q(ALUResultM));
pipereg #(DATA_WIDTH) reg_EM_WriteDat(.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(WriteDataE), .q(WriteDataM));
pipereg #(DATA_WIDTH) reg_EM_PCPlus4 (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(PCPlus4E),   .q(PCPlus4M));
pipereg #(5)          reg_EM_RD      (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(RDE),        .q(RDM));

logic [DATA_WIDTH-1:0] ALUResultW_internal, PCPlus4W_internal;

memoryblock memory(
    .ALUResultM_i(ALUResultM),
    .WriteDataM_i(WriteDataM),
    .PCPlus4M_i(PCPlus4M),
    .MemWrite_i(MemWriteM),
    .clk(clk),
    .MemSign_i(MemSignM),
    .MemType_i(MemTypeM),

    .ALUResultM_o(ALUResultW_internal), // Passes through memoryblock
    .RD_o(ReadDataM),
    .PCPlus4M_o(PCPlus4W_internal)      // Passes through memoryblock
);

// --- M/W Pipeline Registers ---
// Control Signals
pipereg #(1) reg_MW_RegWrite (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(RegWriteM), .q(RegWriteW));
pipereg #(2) reg_MW_ResultSrc(.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(ResultSrcM),.q(ResultSrcW));

// Data Signals
// ALUResultW_internal and PCPlus4W_internal coming out of memoryblock are 
// M-stage signals. We register them here to become W-stage signals.
pipereg #(DATA_WIDTH) reg_MW_ALURes  (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(ALUResultW_internal), .q(ALUResultW));
pipereg #(DATA_WIDTH) reg_MW_ReadData(.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(ReadDataM),           .q(ReadDataW));
pipereg #(DATA_WIDTH) reg_MW_PCPlus4 (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(PCPlus4W_internal),   .q(PCPlus4W));
pipereg #(5)          reg_MW_RD      (.clk(clk), .rst(rst), .en(1'b1), .clr(1'b0), .d(RDM),                 .q(RDW));

writeback writeback(
    .ALUResultM_i(ALUResultW),
    .ReadDataW_i(ReadDataW),
    .PCPlus4W_i(PCPlus4W),
    .ResultSrc_i(ResultSrcW),

    .ResultW_o(ResultW),
    .RdW_o(RdW)
);

endmodule
