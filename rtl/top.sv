module top #(
    parameter DATA_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst,
    output logic [DATA_WIDTH-1:0]   a0_o
);

    logic                    PCSrc;
    logic [DATA_WIDTH-1:0]   InstrA;
    logic [DATA_WIDTH-1:0]   InstrB;
    logic                    RegWriteA;
    logic [3:0]              ALUCtrlA;
    logic                    ALUSrcBA;
    logic [2:0]              ImmSrcA;
    logic                    RegWriteB;
    logic [3:0]              ALUCtrlB;
    logic                    ALUSrcBB;
    logic [2:0]              ImmSrcB;
    logic [DATA_WIDTH-1:0]   ResultA;
    logic [DATA_WIDTH-1:0]   ResultB;
    logic [DATA_WIDTH-1:0]   RD1A;
    logic [DATA_WIDTH-1:0]   RD2A;
    logic [DATA_WIDTH-1:0]   RD1B;
    logic [DATA_WIDTH-1:0]   RD2B;
    logic [DATA_WIDTH-1:0]   ImmExtA;
    logic [DATA_WIDTH-1:0]   ImmExtB;
    logic [DATA_WIDTH-1:0]   ALUResultA;
    logic [DATA_WIDTH-1:0]   ALUResultB;

    fetch fetch(
        .clk(clk),
        .rst(rst),
        .PCSrc_i(PCSrc),
        .InstrA_o(InstrA),
        .InstrB_o(InstrB)
    );

    decode decode(
        .rst(rst),
        .clk(clk),
        .InstrA_i(InstrA),
        .InstrB_i(InstrB),
        .ResultA_i(ResultA),
        .ResultB_i(ResultB),
        .RegWriteA_o(RegWriteA),
        .ALUCtrlA_o(ALUCtrlA),
        .ALUSrcBA_o(ALUSrcBA),
        .ImmSrcA_o(ImmSrcA),
        .RegWriteB_o(RegWriteB),
        .ALUCtrlB_o(ALUCtrlB),
        .ALUSrcBB_o(ALUSrcBB),
        .ImmSrcB_o(ImmSrcB),
        .RD1A_o(RD1A),
        .RD2A_o(RD2A),
        .RD1B_o(RD1B),
        .RD2B_o(RD2B),
        .ImmExtA_o(ImmExtA),
        .ImmExtB_o(ImmExtB),
        .a0_o(a0_o)
    );

    execute execute(
        .ALUCtrlA_i(ALUCtrlA),
        .ALUCtrlB_i(ALUCtrlB),
        .ALUSrcBA_i(ALUSrcBA),
        .ALUSrcBB_i(ALUSrcBB),
        .RD1A_i(RD1A),
        .RD2A_i(RD2A),
        .RD1B_i(RD1B),
        .RD2B_i(RD2B),
        .ImmExtA_i(ImmExtA),
        .ImmExtB_i(ImmExtB),
        .ALUResultA_o(ALUResultA),
        .ALUResultB_o(ALUResultB)
    );

    always_comb begin
        ResultA = ALUResultA;
        ResultB = ALUResultB;
        PCSrc = 1'b0;
    end

endmodule
