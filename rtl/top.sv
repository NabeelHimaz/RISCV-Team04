decode decode(
module top #(
    parameter DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    output logic [DATA_WIDTH-1:0]   a0
);

    // --- control signals ---
    logic           RegWrite;
    logic [3:0]     ALUCtrl;
    logic           ALUSrc;
    logic [2:0]     ImmSrc;
    logic           PCSrc;
    logic           MemWrite;
    logic [1:0]     ResultSrc;

    // --- fetch outputs ---
    logic [DATA_WIDTH-1:0] PCPlus4F;
    logic [DATA_WIDTH-1:0] PCF;
    logic [DATA_WIDTH-1:0] Instr;
    logic [4:0]           A1;
    logic [4:0]           A2;
    logic [4:0]           A3_from_fetch; // kept for visibility but not driven into decode

    // control unit
    controlunit controlunit (
        .Instr_i(Instr),
        .Zero_i(Zero),

        .RegWrite_o(RegWrite),
        .ALUCtrl_o(ALUCtrl),
        .ALUSrc_o(ALUSrc),
        .ImmSrc_o(ImmSrc),
        .PCSrc_o(PCSrc),
        .MemWrite_o(MemWrite),
        .ResultSrc_o(ResultSrc)
    );

    // fetch
    fetch #(
        .DATA_WIDTH(DATA_WIDTH)
    ) fetch_u (
        .PCSrc_i(PCSrc),
        .clk(clk),
        .rst(rst),
        .PCTargetE_i(PCTargetE),

        .PC_Plus4_F(PCPlus4F),
        .PC_F(PCF),
        .Instr_o(Instr),
        .A1_o(A1),
        .A2_o(A2),
        .A3_o(A3_from_fetch)
    );

    // --- decode stage ---
    logic [DATA_WIDTH-1:0] PCPlus4D;
    logic [DATA_WIDTH-1:0] PCD;
    logic [DATA_WIDTH-1:0] RD1;
    logic [DATA_WIDTH-1:0] RD2;
    logic [DATA_WIDTH-1:0] ImmExt;
    logic [4:0]           RdD;

    // ResultW comes from writeback stage (driven later)
    logic [DATA_WIDTH-1:0] ResultW;

    // RdW from writeback (destination register number) that will drive decode.A3_i
    logic [4:0] RdW;

    decode decode_u (
        .ImmSrc_i(ImmSrc),
        .PC_Plus4_F_i(PCPlus4F),
        .PC_F_i(PCF),
        .clk(clk),
        .A1_i(A1),
        .A2_i(A2),
        .A3_i(RdW),              // <- drive decode.A3_i from writeback.RdW
        .instr_i(Instr),
        .WD3_i(ResultW),
        .WE3_i(RegWrite),

        .RD1_o(RD1),
        .RD2_o(RD2),
        .ImmExtD_o(ImmExt),
        .PC_Plus4D_o(PCPlus4D),
        .PCD_o(PCD),
        .a0_o(a0),
        .RdD_o(RdD)
    );

    // --- execute stage ---
    logic [DATA_WIDTH-1:0] PCPlus4E;
    logic [DATA_WIDTH-1:0] ALUResultE;
    logic [DATA_WIDTH-1:0] WriteDataE;
    logic [DATA_WIDTH-1:0] PCTargetE;
    logic [4:0]           RdE;
    logic                 Zero;
    logic                 JumpCtrl;

    execute execute_u (
        .RD1E_i(RD1),
        .RD2E_i(RD2),
        .PCE_i(PCD),
        .ImmExtE_i(ImmExt),
        .PCPlus4E_i(PCPlus4D),
        .ALUCtrl_i(ALUCtrl),
        .ALUSrc_i(ALUSrc),
        .JumpCtrl_i(JumpCtrl),
        .RdD_i(RdD),

        .ALUResultE_o(ALUResultE),
        .WriteDataE_o(WriteDataE),
        .PCPlus4E_o(PCPlus4E),
        .PCTargetE_o(PCTargetE),
        .RdE_o(RdE),
        .Zero_o(Zero)
    );

    // --- memory stage ---
    logic [DATA_WIDTH-1:0] PCPlus4M;
    logic [DATA_WIDTH-1:0] ALUResultM;
    logic [DATA_WIDTH-1:0] RDfromMem;
    logic [4:0]           RdM;
    logic [1:0]           MemType;
    logic                 MemSign;

    memoryblock memory_u (
        .ALUResultM_i(ALUResultE),
        .WriteDataM_i(WriteDataE),
        .PCPlus4M_i(PCPlus4E),
        .MemWrite_i(MemWrite),
        .clk(clk),
        .MemType_i(MemType),
        .MemSign_i(MemSign),
        .RdE_i(RdE),

        .ALUResultM_o(ALUResultM),
        .RD_o(RDfromMem),
        .PCPlus4M_o(PCPlus4M),
        .RdM_o(RdM)
    );

    // --- writeback stage ---
    writeback writeback_u (
        .ALUResultM_i(ALUResultM),
        .ReadDataW_i(RDfromMem),
        .PCPlus4W_i(PCPlus4M),
        .ResultSrc_i(ResultSrc),
        .RdW_i(RdM),

        .ResultW_o(ResultW),
        .RdW_o(RdW)
    );

endmodule
