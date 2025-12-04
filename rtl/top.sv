module top #(
    parameter DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    output logic [DATA_WIDTH-1:0]   a0
);

//wires for outputs are declared before each module
logic           RegWrite;
logic [3:0]     ALUCtrl;
logic           ALUSrcB;
logic           ALUSrcA;
logic [2:0]     ImmSrc;
logic           PCSrc;
logic           MemWrite;
logic [1:0]     ResultSrc;
logic [1:0]     MemType;
logic           MemSign;
logic           JumpSrc;
logic [2:0]     Branch;

controlunit controlunit (
    .Instr_i(Instr),
    .branchTaken_i(branchTaken),         

    .RegWrite_o(RegWrite),
    .ALUCtrl_o(ALUCtrl),     
    .ALUSrcB_o(ALUSrcB),
    .ALUSrcA_o(ALUSrcA),
    .ImmSrc_o(ImmSrc),       
    .PCSrc_o(PCSrc),
    .MemWrite_o(MemWrite),    
    .ResultSrc_o(ResultSrc),
    .MemSign_o(MemSign),
    .MemType_o(MemType),
    .JumpSrc_o(JumpSrc),
    .Branch_o(Branch)
);

logic [4:0] A1;
logic [4:0] A2;
logic [4:0] A3;
logic [DATA_WIDTH-1:0] PCPlus4F;
logic [DATA_WIDTH-1:0] PCF;
logic [DATA_WIDTH-1:0] Instr;

fetch fetch(
    .PCSrc_i(PCSrc),
    .clk(clk),
    .rst(rst),
    .PCTargetE_i(PCTargetE),

    .PC_Plus4_F(PCPlus4F),
    .PC_F(PCF),
    .Instr_o(Instr),
    .A1_o(A1),
    .A2_o(A2),
    .A3_o(A3)
);

logic [DATA_WIDTH-1:0] PCPlus4D;
logic [DATA_WIDTH-1:0] PCD;
logic [DATA_WIDTH-1:0] RD1;
logic [DATA_WIDTH-1:0] RD2;
logic [DATA_WIDTH-1:0] ImmExt;
logic [4:0]           RdD;

decode decode(
    .ImmSrc_i(ImmSrc),
    .PC_Plus4_F_i(PCPlus4F),
    .PC_F_i(PCF),
    .clk(clk),
    .A1_i(A1),
    .A2_i(A2),
    .RdF_i(A3),
    .instr_i(Instr),
    .WD3_i(ResultW),
    .WE3_i(RegWrite),
    .RdW_i(RdW),

    .RD1_o(RD1),
    .RD2_o(RD2),
    .ImmExtD_o(ImmExt),
    .PC_Plus4D_o(PCPlus4D),
    .PCD_o(PCD), 
    .a0_o(a0),
    .RdD_o(RdD)
);

logic [DATA_WIDTH-1:0] PCPlus4E;
logic [DATA_WIDTH-1:0] ALUResult;
logic [DATA_WIDTH-1:0] WriteData;
logic [DATA_WIDTH-1:0] PCTargetE;
logic [4:0]           RdE;
logic                 branchTaken;

execute execute(
    .RD1E_i(RD1),
    .RD2E_i(RD2),
    .PCE_i(PCD),
    .ImmExtE_i(ImmExt),
    .PCPlus4E_i(PCPlus4D),
    .ALUCtrl_i(ALUCtrl),
    .ALUSrcB_i(ALUSrcB),
    .ALUSrcA_i(ALUSrcA),
    .JumpCtrl_i(JumpSrc),
    .BranchSrc_i(Branch),
    .RdD_i(RdD),

    .ALUResultE_o(ALUResult),
    .WriteDataE_o(WriteData),
    .PCPlus4E_o(PCPlus4E),
    .PCTargetE_o(PCTargetE),
    .RdE_o(RdE),
    .branchTaken_o(branchTaken)
);

logic [DATA_WIDTH-1:0] PCPlus4M;
logic [DATA_WIDTH-1:0] ALUResultM;
logic [DATA_WIDTH-1:0] RDM;
logic [4:0]           RdM;


memoryblock memory(
    .ALUResultM_i(ALUResult),
    .WriteDataM_i(WriteData),
    .PCPlus4M_i(PCPlus4E),
    .MemWrite_i(MemWrite),
    .clk(clk),
    .MemSign_i(MemSign),
    .MemType_i(MemType),
    .RdE_i(RdE),

    .ALUResultM_o(ALUResultM),
    .RD_o(RDM),
    .PCPlus4M_o(PCPlus4M),
    .RdM_o(RdM)
);

logic [DATA_WIDTH-1:0] ResultW;
logic [4:0]           RdW;

writeback writeback(
    .ALUResultM_i(ALUResultM),
    .ReadDataW_i(RDM),
    .PCPlus4W_i(PCPlus4M),
    .ResultSrc_i(ResultSrc),
    .RdM_i(RdM),

    .ResultW_o(ResultW),
    .RdW_o(RdW)
);

endmodule
