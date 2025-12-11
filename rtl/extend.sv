module extend #(
    parameter DATA_WIDTH = 32
) (
    input   logic [DATA_WIDTH-1:0]  instrA,
    input   logic [DATA_WIDTH-1:0]  instrB,
    input   logic [5:0]             ImmSrc,    
    output  logic [DATA_WIDTH-1:0]  ImmOpA,
    output  logic [DATA_WIDTH-1:0]  ImmOpB 
);

    always_comb begin
        case(ImmSrc_i)
            
            3'b000: ImmExt_o = {{20{instr_i[31]}}, instr_i[31:20]}; // I type 
            
            default: ImmExt_o = {DATA_WIDTH{1'b0}};
            
        endcase
    end

endmodule
