module fetch #(
    parameter DATA_WIDTH = 32
) (
    input logic PCSrc_i,
    input logic clk,
    input logic rst,
    input logic [DATA_WIDTH-1:0] PCTargetE_i, //this is the jump PC value coming after Execute

    output logic [DATA_WIDTH-1:0] PC_Plus4_F, //this is the next instruction 
    output logic [DATA_WIDTH-1:0] PC_F, //this goes to execute where it is added to the Immediate for JMP
    output logic [DATA_WIDTH-1:0] Instr_o, //this goes into control unit and EXT

    //this goes into REGFILE
    output logic [4:0] A1_o,
    output logic [4:0] A2_o,
    output logic [4:0] A3_o
);

logic [DATA_WIDTH-1:0]  PC;

pc_module #(
        .DATA_WIDTH(DATA_WIDTH)
    ) pc (
        .clk(clk),
        .rst(rst),
        .PCsrc(PCSrc_i),
        .PCTargetE_i(PCTargetE_i),

        .PC(PC),
        .PC_Plus4(PC_Plus4_F)
    );

instrmem instruction_memory (
    .addr_i(PC),
    
    .read_data_o(Instr_o)
);

assign A1_o = Instr_o[19:15];
assign A2_o = Instr_o [24:20];
assign A3_o = Instr_o [11:7];

assign PC_F = PC; //this PC value is passed to the decode and then execute 



endmodule
