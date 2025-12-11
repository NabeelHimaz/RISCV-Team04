module execute #(
    parameter DATA_WIDTH = 32
) (
    input  logic [3:0]              ALUCtrlA_i,
    input  logic [3:0]              ALUCtrlB_i,
    input  logic                    ALUSrcBA_i,
    input  logic                    ALUSrcBB_i,
    input  logic [DATA_WIDTH-1:0]   RD1A_i,
    input  logic [DATA_WIDTH-1:0]   RD2A_i,
    input  logic [DATA_WIDTH-1:0]   RD1B_i,
    input  logic [DATA_WIDTH-1:0]   RD2B_i,
    input  logic [DATA_WIDTH-1:0]   ImmExtA_i,
    input  logic [DATA_WIDTH-1:0]   ImmExtB_i,
    output logic [DATA_WIDTH-1:0]   ALUResultA_o,
    output logic [DATA_WIDTH-1:0]   ALUResultB_o
);

    logic [DATA_WIDTH-1:0] SrcBA;
    logic [DATA_WIDTH-1:0] SrcBB;

    ALU aluA(
        .ALUCtrl_i(ALUCtrlA_i),
        .ALUop1_i(RD1A_i),
        .ALUop2_i(SrcBA),
        .ALUout_o(ALUResultA_o)
    );

    ALU aluB(
        .ALUCtrl_i(ALUCtrlB_i),
        .ALUop1_i(RD1B_i),
        .ALUop2_i(SrcBB),
        .ALUout_o(ALUResultB_o)
    );

    assign SrcBA = ALUSrcBA_i ? ImmExtA_i : RD2A_i;
    assign SrcBB = ALUSrcBB_i ? ImmExtB_i : RD2B_i;

endmodule
