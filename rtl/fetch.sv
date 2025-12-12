module fetch #(
    parameter DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    PCSrc_i,
    output logic [DATA_WIDTH-1:0]   InstrA_o,
    output logic [DATA_WIDTH-1:0]   InstrB_o
);

    logic [DATA_WIDTH-1:0] PCNext;
    logic [DATA_WIDTH-1:0] PC;
    logic [DATA_WIDTH-1:0] P8;

    assign P8 = PC + 8;
    assign PCNext = PCSrc_i ? PC : P8;

    pc_module pc(
        .clk(clk),
        .rst(rst),
        .PCNext_i(PCNext),
        .PC_o(PC)
    );

    instrmem instrmem(
        .addr_i(PC),
        .instrA_o(InstrA_o), 
        .instrB_o(InstrB_o)   
    );

endmodule
