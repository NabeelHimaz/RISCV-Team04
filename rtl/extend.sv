module extend #(
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0]   instr_i,  // instruction 
    input  logic [2:0]              ImmSrc_i, // immediate control signals 
    output logic [DATA_WIDTH-1:0]   immop_o   // output 
);

    always_comb begin
        case(ImmSrc_i)
            
            3'b000: immop_o = {{20{instr_i[31]}}, instr_i[31:20]}; // I type 
            
            3'b001: immop_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]}; //S type 
            
            3'b010: immop_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0}; //B type
            
            3'b011: immop_o = {instr_i[31:12], 12'b0}; //U type 
            
            3'b100: immop_o = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0}; // J type
            
            default: immop_o = {DATA_WIDTH{1'b0}};
            
        endcase
    end

endmodule