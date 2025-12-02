module decode #(
    parameter DATA_WIDTH = 32
) (
    
    input logic [2:0] ImmSrc_i,
    
    //PC related inputs
    input logic [DATA_WIDTH-1:0] PC_Plus4_F_i,
    input logic [DATA_WIDTH-1:0] PC_F_i,

    input logic clk,

    //Register File inputs 
    input logic [4:0] A1_i,
    input logic [4:0] A2_i,
    input logic [4:0] RdW_o,
    input logic [DATA_WIDTH-1:0] instr_i,
    input logic [DATA_WIDTH-1:0] WD3_i,
    input logic WE3_i,

    //RF outputs
    output logic [DATA_WIDTH-1:0] RD1_o,
    output logic [DATA_WIDTH-1:0] RD2_o,

    //Extend output
    output logic [DATA_WIDTH-1:0] ImmExtD_o,

    //PC related outputs 
    output logic [DATA_WIDTH-1:0] PC_Plus4D_o, //this is the next instruction 
    output logic [DATA_WIDTH-1:0] PCD_o, //this goes to execute where it is added to the Immediate for JMP
    
    //test output 
    output logic [DATA_WIDTH-1:0] a0_o,
    output logic [4:0] RdD_o; //new output we need

);
    


    extend extend_u(
        .instr_i(instr_i),
        .ImmSrc_i(ImmSrc_i),

        .immop_o(ImmExtD_o)
    );


    regfile regfile(
        .clk(clk),
        .AD1_i(A1_i),
        .AD2_i(A2_i),
        .AD3_i(RdW_o),

        .WE3_i(WE3_i),
        .WD3_i(WD3_i),

        .RD1_o(RD1_o),
        .RD2_o(RD2_o),
        .a0_o(a0_o)
    );

    assign PCD_o = PC_F_i;
    assign PC_Plus4D_o = PC_Plus4_F_i;
    assign RdD_o = instr_i[11:7];
    
endmodule
