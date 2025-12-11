module decode #(
    parameter DATA_WIDTH = 32
)(
    input  logic                     rst,
    input  logic                     clk,
    input  logic   [DATA_WIDTH-1:0]  InstrA_i,
    input  logic   [DATA_WIDTH-1:0]  InstrB_i,
    input  logic   [DATA_WIDTH-1:0]  ResultA_i,
    input  logic   [DATA_WIDTH-1:0]  ResultB_i,
    output logic                     RegWriteA_o,
    output logic   [3:0]             ALUCtrlA_o,
    output logic                     ALUSrcBA_o,
    output logic   [2:0]             ImmSrcA_o,
    output logic                     RegWriteB_o,
    output logic   [3:0]             ALUCtrlB_o,
    output logic                     ALUSrcBB_o,
    output logic   [2:0]             ImmSrcB_o,
    output logic   [DATA_WIDTH-1:0]  RD1A_o,
    output logic   [DATA_WIDTH-1:0]  RD2A_o,
    output logic   [DATA_WIDTH-1:0]  RD1B_o,
    output logic   [DATA_WIDTH-1:0]  RD2B_o,
    output logic   [DATA_WIDTH-1:0]  ImmExtA_o, 
    output logic   [DATA_WIDTH-1:0]  ImmExtB_o, 
    output logic   [DATA_WIDTH-1:0]  a0_o  
);

    logic [1:0] RegWrite;

    controlunit controlunit(
        .InstrA_i(InstrA_i),
        .InstrB_i(InstrB_i),
        .RegWriteA_o(RegWriteA_o),
        .ALUCtrlA_o(ALUCtrlA_o),
        .ALUSrcBA_o(ALUSrcBA_o),
        .ImmSrcA_o(ImmSrcA_o),
        .RegWriteB_o(RegWriteB_o),
        .ALUCtrlB_o(ALUCtrlB_o),
        .ALUSrcBB_o(ALUSrcBB_o),
        .ImmSrcB_o(ImmSrcB_o)
    );

    regfile regfile(
        .clk(clk),
        .reset(rst),
        .we_i(RegWrite),
        .ad1A_i(InstrA_i[19:15]),
        .ad2A_i(InstrA_i[24:20]),
        .ad3A_i(InstrA_i[11:7]),
        .wd3A_i(ResultA_i),
        .ad1B_i(InstrB_i[19:15]),
        .ad2B_i(InstrB_i[24:20]),
        .ad3B_i(InstrB_i[11:7]),
        .wd3B_i(ResultB_i),
        .rd1A_o(RD1A_o),
        .rd2A_o(RD2A_o),
        .rd1B_o(RD1B_o),
        .rd2B_o(RD2B_o),
        .a0_o(a0_o)
    );

    extend extend(
        .InstrA_i(InstrA_i),
        .InstrB_i(InstrB_i),
        .ImmSrcA_i(ImmSrcA_o),
        .ImmSrcB_i(ImmSrcB_o),
        .ImmExtA_o(ImmExtA_o),
        .ImmExtB_o(ImmExtB_o)
    );

endmodule
