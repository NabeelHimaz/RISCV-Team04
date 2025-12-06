module top #(
    parameter DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    output logic [DATA_WIDTH-1:0]   a0
);

// Fetch Stage Signals
logic [DATA_WIDTH-1:0] PCPlus4F, PCF, InstrF;
logic                  PCSrcE; // Feedback from Execute

// Decode Stage Signals
logic [DATA_WIDTH-1:0] InstrD, PCD, PCPlus4D;
logic [DATA_WIDTH-1:0] RD1D, RD2D, ImmExtD;
logic [4:0]            A1D, A2D, A3D, RDD;
logic [DATA_WIDTH-1:0] a0_internal;

// Control Signals (Decode)
logic       RegWriteD, MemWriteD, ALUSrcD, MemSignD, JumpD, BranchD;
logic [1:0] ResultSrcD, MemTypeD;
logic [3:0] ALUCtrlD;
logic [2:0] ImmSrcD;

// Execute Stage Signals
logic [DATA_WIDTH-1:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
logic [4:0]            RDE;
logic [DATA_WIDTH-1:0] ALUResultE, WriteDataE, PCTargetE;
logic                  ZeroE;

// Control Signals (Execute)
logic       RegWriteE, MemWriteE, ALUSrcE, MemSignE, JumpE, BranchE;
logic [1:0] ResultSrcE, MemTypeE;
logic [3:0] ALUCtrlE;

// Memory Stage Signals
logic [DATA_WIDTH-1:0] ALUResultM, WriteDataM, PCPlus4M;
logic [DATA_WIDTH-1:0] ReadDataM;
logic [4:0]            RDM;

// Control Signals (Memory)
logic       RegWriteM, MemWriteM, MemSignM;
logic [1:0] ResultSrcM, MemTypeM;

// Writeback Stage Signals
logic [DATA_WIDTH-1:0] ALUResultW, ReadDataW, PCPlus4W, ResultW;
logic [4:0]            RDW;

// Control Signals (Writeback)
logic       RegWriteW;
logic [1:0] ResultSrcW;


/////////////////// Fetch Stage //////////////////////
logic [4:0] unused_A1, unused_A2, unused_A3;

fetch fetch(
    .PCSrc_i(PCSrcE),
    .clk(clk),
    .rst(rst),
    .PCTargetE_i(PCTargetE),

    .PC_Plus4_F(PCPlus4F),
    .PC_F(PCF),
    .Instr_o(InstrF),
    .A1_o(unused_A1), .A2_o(unused_A2), .A3_o(unused_A3)
);

// F/D Pipeline Register Module
pipereg_FD_1 #(DATA_WIDTH) fd_reg (
    .clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE),
    .InstrF(InstrF), .PCF(PCF), .PCPlus4F(PCPlus4F),
    
    .InstrD(InstrD), .PCD(PCD), .PCPlus4D(PCPlus4D)
);


///////////////// Decode Stage /////////////////
logic ctrl_PCSrc_unused; 

controlunit controlunit (
    .Instr_i(InstrD),
    .Zero_i(1'b0),          

    .RegWrite_o(RegWriteD),
    .ALUCtrl_o(ALUCtrlD),     
    .ALUSrc_o(ALUSrcD),
    .ImmSrc_o(ImmSrcD),       
    .PCSrc_o(ctrl_PCSrc_unused), 
    .MemWrite_o(MemWriteD),    
    .ResultSrc_o(ResultSrcD),
    .MemSign_o(MemSignD),
    .MemType_o(MemTypeD)
);

// Local Decode Logic
assign BranchD = (InstrD[6:0] == 7'd99);
assign JumpD   = (InstrD[6:0] == 7'd111 || InstrD[6:0] == 7'd103);
assign A1D     = InstrD[19:15];
assign A2D     = InstrD[24:20];
assign RDD     = InstrD[11:7];

logic [DATA_WIDTH-1:0] pcplus4_dummy_d, pc_dummy_d;

decode decode(
    .ImmSrc_i(ImmSrcD),
    .PC_Plus4_F_i(PCPlus4D),
    .PC_F_i(PCD),
    .clk(clk),
    .A1_i(A1D),
    .A2_i(A2D),
    .A3_i(RDW),
    .instr_i(InstrD),
    .WD3_i(ResultW),
    .WE3_i(RegWriteW),

    .RD1_o(RD1D),
    .RD2_o(RD2D),
    .ImmExtD_o(ImmExtD),
    .PC_Plus4D_o(pcplus4_dummy_d),
    .PCD_o(pc_dummy_d), 
    .a0_o(a0_internal)
);

assign a0 = a0_internal;

// D/E Pipeline Register Module
pipereg_DE_1 #(DATA_WIDTH) de_reg (
    .clk(clk), .rst(rst), .en(1'b1), .clr(PCSrcE),
    
    // Control
    .RegWriteD(RegWriteD), .MemWriteD(MemWriteD), .JumpD(JumpD), .BranchD(BranchD),
    .ALUSrcD(ALUSrcD), .MemSignD(MemSignD), .ResultSrcD(ResultSrcD), .MemTypeD(MemTypeD),
    .ALUCtrlD(ALUCtrlD),
    
    // Data
    .RD1D(RD1D), .RD2D(RD2D), .PCD(PCD), .ImmExtD(ImmExtD), .PCPlus4D(PCPlus4D), .RDD(RDD),
    
    // Outputs
    .RegWriteE(RegWriteE), .MemWriteE(MemWriteE), .JumpE(JumpE), .BranchE(BranchE),
    .ALUSrcE(ALUSrcE), .MemSignE(MemSignE), .ResultSrcE(ResultSrcE), .MemTypeE(MemTypeE),
    .ALUCtrlE(ALUCtrlE),
    .RD1E(RD1E), .RD2E(RD2E), .PCE(PCE), .ImmExtE(ImmExtE), .PCPlus4E(PCPlus4E), .RDE(RDE)
);

////////////////////// Exectute Stage ////////////////////
logic [DATA_WIDTH-1:0] pcplus4_dummy_e;

execute execute(
    .RD1E_i(RD1E),
    .RD2E_i(RD2E),
    .PCE_i(PCE),
    .ImmExtE_i(ImmExtE),
    .PCPlus4E_i(PCPlus4E),
    .ALUCtrl_i(ALUCtrlE),
    .ALUSrc_i(ALUSrcE),
    .JumpCtrl_i(JumpE),

    .ALUResultE_o(ALUResultE),
    .WriteDataE_o(WriteDataE),
    .PCPlus4E_o(pcplus4_dummy_e),
    .PCTargetE_o(PCTargetE),
    .Zero_o(ZeroE)
);

assign PCSrcE = (BranchE & ZeroE) | JumpE;

// E/M Pipeline Register Module
pipereg_EM_1 #(DATA_WIDTH) em_reg (
    .clk(clk), .rst(rst), .en(1'b1), .clr(1'b0),
    
    // Control
    .RegWriteE(RegWriteE), .MemWriteE(MemWriteE), .MemSignE(MemSignE), 
    .ResultSrcE(ResultSrcE), .MemTypeE(MemTypeE),
    
    // Data
    .ALUResultE(ALUResultE), .WriteDataE(WriteDataE), .PCPlus4E(PCPlus4E), .RDE(RDE),
    
    // Outputs
    .RegWriteM(RegWriteM), .MemWriteM(MemWriteM), .MemSignM(MemSignM),
    .ResultSrcM(ResultSrcM), .MemTypeM(MemTypeM),
    .ALUResultM(ALUResultM), .WriteDataM(WriteDataM), .PCPlus4M(PCPlus4M), .RDM(RDM)
);

/////////////////// Memory Stage ////////////////////
logic [DATA_WIDTH-1:0] ALUResultW_internal, PCPlus4W_internal;

memoryblock memory(
    .ALUResultM_i(ALUResultM),
    .WriteDataM_i(WriteDataM),
    .PCPlus4M_i(PCPlus4M),
    .MemWrite_i(MemWriteM),
    .clk(clk),
    .MemSign_i(MemSignM),
    .MemType_i(MemTypeM),

    .ALUResultM_o(ALUResultW_internal), 
    .RD_o(ReadDataM),
    .PCPlus4M_o(PCPlus4W_internal)
);

// M/W Pipeline Register Module
pipereg_MW_1 #(DATA_WIDTH) mw_reg (
    .clk(clk), .rst(rst), .en(1'b1), .clr(1'b0),
    
    // Control
    .RegWriteM(RegWriteM), .ResultSrcM(ResultSrcM),
    
    // Data
    .ALUResultM(ALUResultW_internal), .ReadDataM(ReadDataM), .PCPlus4M(PCPlus4W_internal), .RDM(RDM),
    
    // Outputs
    .RegWriteW(RegWriteW), .ResultSrcW(ResultSrcW),
    .ALUResultW(ALUResultW), .ReadDataW(ReadDataW), .PCPlus4W(PCPlus4W), .RDW(RDW)
);

////////////////////// Writeback Stage ////////////////////
writeback writeback(
    .ALUResultM_i(ALUResultW),
    .ReadDataW_i(ReadDataW),
    .PCPlus4W_i(PCPlus4W),
    .ResultSrc_i(ResultSrcW),

    .ResultW_o(ResultW)
);

endmodule
