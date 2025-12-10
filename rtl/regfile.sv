module regfile #(
    parameter ADDRESS_WIDTH = 5,
    parameter DATA_WIDTH    = 32
) (
    input  logic                         clk,

    input  logic [ADDRESS_WIDTH-1:0]     AD1_i,  
    input  logic [ADDRESS_WIDTH-1:0]     AD2_i, 
    input  logic [ADDRESS_WIDTH-1:0]     AD3_i,

    input  logic                         WE3_i,  //RegWrite 
    input  logic [DATA_WIDTH-1:0]        WD3_i,


    output logic [DATA_WIDTH-1:0]        RD1_o,  
    output logic [DATA_WIDTH-1:0]        RD2_o,  
    output logic [DATA_WIDTH-1:0]        a0_o    
);


    // register file: 32 entries of DATA_WIDTH bits
    logic [DATA_WIDTH-1:0] regs [2**ADDRESS_WIDTH-1:0];


    //write logic with x0 protection
    //Test if this is 100% correct
    always_ff @(negedge clk) begin
        if (WE3_i & (AD3_i != 5'b0)) begin
            regs[AD3_i] <= WD3_i;
        end
    end

    //read logic with x0 protection 
    always_comb begin 
        RD1_o = (AD1_i == 5'b0) ? {DATA_WIDTH{1'b0}} : regs[AD1_i];
        RD2_o = (AD2_i == 5'b0) ? {DATA_WIDTH{1'b0}} : regs[AD2_i];
    end
    
    //output of regfile for testing purposes
    assign a0_o = regs[10];

endmodule