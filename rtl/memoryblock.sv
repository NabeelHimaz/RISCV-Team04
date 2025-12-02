module memoryblock #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0]    ALUResultM_i,
    input logic [DATA_WIDTH-1:0]    WriteDataM_i,
    input logic [DATA_WIDTH-1:0]    PCPlus4M_i,
    input logic                     MemWrite_i,
    input logic                     clk,
    input logic [1:0]               MemType_i,
    input logic                     MemSign_i,
    input logic [4:0]               RdE_i,

    output logic [DATA_WIDTH-1:0] ALUResultM_o,
    output logic [DATA_WIDTH-1:0] RD_o,
    output logic [DATA_WIDTH-1:0] PCPlus4M_o,
    output logic [4:0]            RdM_o;
);

data_mem_top datamem(
    .write_en_i(MemWrite_i),
    .clk_i(clk),
    .mem_type_i(MemType_i), //need to implement these control signals
    .mem_sign_i(MemSign_i), //control signal?
    .write_data_i(WriteDataM_i),
    .addr_i(ALUResultM_i),

    .read_data_o(RD_o)

)

assign ALUResultM_o = ALUResultM_i; 
assign PCPlus4M_o = PCPlus4M_i;
assign RdM_o = RdE_i;


endmodule
