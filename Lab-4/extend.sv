//archit's corrected code, need to get someone else to double check changes

module extend #(
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0]   instr,
    input  logic [1:0]              ImmSrc,
    output logic [DATA_WIDTH-1:0]   immop  
);

    always_comb begin
        case(ImmSrc)
            2'b00: begin
                //u dont require assign commands inside the always block
                immop = {{20{instr[31]}}, instr[31:20]};
            end
            2'b01: begin
                immop = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            2'b10: begin
                immop = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; //changed command in 11,8 to a colon
            end
            default: begin //fixed typo defualt and rewrote block logic
                immop = {{DATA_WIDTH}{1'b0}};
            end
        endcase //closed the case
    end //closed the begin

endmodule
