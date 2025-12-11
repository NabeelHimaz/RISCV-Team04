module ALU #(
    parameter DATA_WIDTH = 32
) (
    input  logic [3:0]              ALUCtrl_i,
    input  logic [DATA_WIDTH-1:0]   ALUop1_i,
    input  logic [DATA_WIDTH-1:0]   ALUop2_i,
    output logic [DATA_WIDTH-1:0]   ALUout_o
);

    always_comb begin
        case (ALUCtrl_i)
            4'b0000: ALUout_o = ALUop1_i + ALUop2_i;                                                        //ADD
            4'b0001: ALUout_o = ALUop1_i - ALUop2_i;                                                        //SUB
            4'b0010: ALUout_o = ALUop1_i & ALUop2_i;                                                        //AND
            4'b0011: ALUout_o = ALUop1_i | ALUop2_i;                                                        //OR
            4'b0100: ALUout_o = ALUop1_i ^ ALUop2_i;                                                        //XOR
            4'b0101: ALUout_o = ALUop1_i << ALUop2_i[4:0];                                                  //SLL (shift left logical)
            4'b0110: ALUout_o = ALUop1_i >>> ALUop2_i[4:0];                                                 //SRA (shift right arithmetic)
            4'b0111: ALUout_o = ALUop1_i >> ALUop2_i[4:0];                                                  //SRL (shift right logical)
            4'b1000: ALUout_o = ($signed(ALUop1_i) < $signed(ALUop2_i)) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : {DATA_WIDTH{1'b0}};    //SLT (set less than signed)
            4'b1001: ALUout_o = (ALUop1_i < ALUop2_i) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : {DATA_WIDTH{1'b0}};                       //SLTU (set less than unsigned)
            default: ALUout_o = {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule
