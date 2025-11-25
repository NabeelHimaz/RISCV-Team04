module memoryblock #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0] ALUResultM_i,
    input logic [DATA_WIDTH-1:0] WriteDataM_i,
    input logic [DATA_WIDTH-1:0] PCPlus4M_i,
    input logic MemWrite_i,
    input logic clk,

    output logic [DATA_WIDTH-1:0] ALUResultM_o,
    output logic [DATA_WIDTH-1:0] RD_o,
    output logic [DATA_WIDTH-1:0] PCPlus4M_o
);



endmodule
