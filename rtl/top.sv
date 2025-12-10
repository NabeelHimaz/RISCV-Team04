module top #(
    parameter DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    trigger, 
    output logic [DATA_WIDTH-1:0]   a0
);

// Fetch Stage Signals
logic [DATA_WIDTH-1:0] PCPlus4F, PCF, InstrF;
logic                  PCSrcE; 

// Decode Stage Signals
logic [DATA_WIDTH-1:0] InstrD, PCD, PCPlus4D;
logic [DATA_WIDTH-1:0] RD1D, RD2D, ImmExtD;
logic [4:0]            A1D, A2D, RDD, RdD;
logic [DATA_WIDTH-1:0] a0_internal;

// Control Signals (Decode)
logic       RegWriteD, MemWriteD, ALUSrcD, MemSignD, JumpD, BranchD;
logic       JumpSrcD; 
logic [2:0] BranchCtrlD; 
logic [1:0] ResultSrcD, MemTypeD;
logic [3:0] ALUCtrlD;
logic [2:0] ImmSrcD;
logic [1:0] Op1SrcD; 

// Execute Stage Signals
logic [DATA_WIDTH-1:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
logic [4:0]            RDE, RdE_out, Rs1E_out, Rs2E_out;
logic [4:0]            Rs1E, Rs2E;
logic [DATA_WIDTH-1:0] ALUResultE, WriteDataE, PCTargetE;
logic                  BranchTakenE;

// Control Signals (Execute)
logic       RegWriteE, MemWriteE, ALUSrcE, MemSignE, JumpE, BranchE;
logic [1:0] ResultSrcE, MemTypeE;
logic [3:0] ALUCtrlE;
logic [2:0] BranchCtrlE; 
logic [1:0] Op1SrcE; 

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

// Hazard Unit Signals
logic       StallF, StallD, FlushD, FlushE;
logic [1:0] ForwardAE, ForwardBE;

// Dummy signals
logic [4:0]            unused_RdM_o, unused_RdW_o;
logic [DATA_WIDTH-1:0] unused_pcplus4_d, unused_pc_d, unused_pcplus4_e;
logic [4:0]            unused_A1, unused_A2, unused_A3;
logic                  unused_JumpSrcD;
logic                  unused_BranchTakenE;
logic                  unused_trigger;

assign unused_JumpSrcD = JumpSrcD;
assign unused_BranchTakenE = BranchTakenE;
assign unused_trigger = trigger;

/////////////////// Fetch Stage //////////////////////

fetch fetch(
    .PCSrc_i(PCSrcE),
    .clk(clk),
    .rst(rst),
    .StallF(StallF),
    .trigger(trigger),
    .PCTargetE_i(PCTargetE),
    .PC_Plus4_F(PCPlus4F),
    .PC_F(PCF),
    .Instr_o(InstrF),
    .A1_o(unused_A1), .A2_o(unused_A2), .A3_o(unused_A3)
);

// F/D Pipeline Register Module
pipereg_FD_1 #(DATA_WIDTH) fd_reg (
    .clk(clk), .rst(rst), .en(~StallF), .clr(FlushD),
    .InstrF(InstrF), .PCF(PCF), .PCPlus4F(PCPlus4F),
    .InstrD(InstrD), .PCD(PCD), .PCPlus4D(PCPlus4D)
);

///////////////// Decode Stage /////////////////

controlunit controlunit (
    .Instr_i(InstrD),
    .RegWrite_o(RegWriteD),
    .ALUCtrl_o(ALUCtrlD),     
    .ALUSrc_o(ALUSrcD),
    .ImmSrc_o(ImmSrcD),       
    .MemWrite_o(MemWriteD),    
    .ResultSrc_o(ResultSrcD),
    .MemSign_o(MemSignD),
    .MemType_o(MemTypeD),
    .JumpSrc_o(JumpSrcD),
    .Branch_o(BranchCtrlD),
    .BranchInstr_o(BranchD),
    .Op1Src_o(Op1SrcD) 
);

// Local Decode Logic
assign JumpD   = (InstrD[6:0] == 7'd111 || InstrD[6:0] == 7'd103);
assign A1D     = InstrD[19:15];
assign A2D     = InstrD[24:20];
assign RDD     = InstrD[11:7];

decode decode(
    .ImmSrc_i(ImmSrcD),
    .PC_Plus4_F_i(PCPlus4D),
    .PC_F_i(PCD),
    .clk(clk),
    .A1_i(A1D),
    .A2_i(A2D),
    .RdF_i(RDD),
    .RdW_i(RDW),
    .instr_i(InstrD),
    .WD3_i(ResultW),
    .WE3_i(RegWriteW),
    .RD1_o(RD1D),
    .RD2_o(RD2D),
    .ImmExtD_o(ImmExtD),
    // CHECK -> Connected to dummy wires
    .PC_Plus4D_o(unused_pcplus4_d),
    .PCD_o(unused_pc_d), 
    .a0_o(a0_internal),
    .RdD_o(RdD)
);

assign a0 = a0_internal;

// D/E Pipeline Register Module
pipereg_DE_1 #(DATA_WIDTH) de_reg (
    .clk(clk), .rst(rst), .en(~StallD), .clr(FlushE),
    
    // Control
    .RegWriteD(RegWriteD), .MemWriteD(MemWriteD), .JumpD(JumpD), .BranchD(BranchD),
    .ALUSrcD(ALUSrcD), .MemSignD(MemSignD), .ResultSrcD(ResultSrcD), .MemTypeD(MemTypeD),
    .ALUCtrlD(ALUCtrlD),
    .BranchCtrlD(BranchCtrlD),
    .Op1SrcD(Op1SrcD), 
    
    // Data
    .RD1D(RD1D), .RD2D(RD2D), .PCD(PCD), .ImmExtD(ImmExtD), .PCPlus4D(PCPlus4D), 
    .RDD(RdD), 
    .Rs1D(A1D), .Rs2D(A2D),
    
    // Outputs
    .RegWriteE(RegWriteE), .MemWriteE(MemWriteE), .JumpE(JumpE), .BranchE(BranchE),
    .ALUSrcE(ALUSrcE), .MemSignE(MemSignE), .ResultSrcE(ResultSrcE), .MemTypeE(MemTypeE),
    .ALUCtrlE(ALUCtrlE),
    .BranchCtrlE(BranchCtrlE),
    .Op1SrcE(Op1SrcE), 
    .RD1E(RD1E), .RD2E(RD2E), .PCE(PCE), .ImmExtE(ImmExtE), .PCPlus4E(PCPlus4E), .RDE(RDE),
    .Rs1E(Rs1E), .Rs2E(Rs2E)
);

////////////////////// Hazard Unit ////////////////////
hazardunit hazard_unit (
    // From Decode
    .Rs1D_i(A1D),
    .Rs2D_i(A2D),
    .Instr_i(InstrD),
    // From Execute
    .Rs1E_i(Rs1E_out),
    .Rs2E_i(Rs2E_out),
    .RdE_i(RdE_out),
    .PCSrcE_i(PCSrcE),
    .ResultSrcE_i(ResultSrcE[0]),
    
    // From Memory
    .RdM_i(RDM),
    .RegWriteM_i(RegWriteM),
    
    // From Writeback
    .RdW_i(RDW),
    .RegWriteW_i(RegWriteW),
    
    // Outputs
    .StallF_o(StallF),
    .StallD_o(StallD),
    .FlushD_o(FlushD),
    .FlushE_o(FlushE),
    .ForwardAE_o(ForwardAE),
    .ForwardBE_o(ForwardBE)
);

////////////////////// Execute Stage ////////////////////

execute execute(
    .RD1E_i(RD1E),
    .RD2E_i(RD2E),
    .PCE_i(PCE),
    .ImmExtE_i(ImmExtE),
    .PCPlus4E_i(PCPlus4E),
    .RdD_i(RDE),
    .Rs1E_i(Rs1E),
    .Rs2E_i(Rs2E),
    .BranchSrc_i(BranchCtrlE),
    
    .ResultW_i(ResultW),
    .ALUResultM_i(ALUResultM),
    
    // Control inputs
    .RegWriteE_i(RegWriteE),
    .ResultSrcE_i(ResultSrcE),
    .MemWriteE_i(MemWriteE),
    .JumpE_i(JumpE),
    .BranchE_i(BranchE),
    .ALUCtrlE_i(ALUCtrlE),
    .ALUSrcE_i(ALUSrcE),
    .Op1SrcE_i(Op1SrcE), 
    
    // From hazard unit
    .ForwardAEctrl_i(ForwardAE),
    .ForwardBEctrl_i(ForwardBE),

    // Outputs
    .Rs1E_o(Rs1E_out),
    .Rs2E_o(Rs2E_out),
    .ALUResultE_o(ALUResultE),
    .WriteDataE_o(WriteDataE),
    // Connected dummy
    .PCPlus4E_o(unused_pcplus4_e),
    .RdE_o(RdE_out),
    .branchTaken_o(BranchTakenE),
    .PCTargetE_o(PCTargetE),
    .PCSrcE_o(PCSrcE)
);

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
    .RdE_i(RDM), 
    .RdM_o(unused_RdM_o),        
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
    .RdM_i(RDW),
    // Connected Dummy
    .RdW_o(unused_RdW_o),
    .ResultW_o(ResultW)
);

endmodule
