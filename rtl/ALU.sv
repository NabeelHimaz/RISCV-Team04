module ALU #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_WIDTH = 5
)(
    input  logic [DATA_WIDTH-1:0]   srcA_i,
    input  logic [DATA_WIDTH-1:0]   srcB_i,
    input  logic [3:0]              ALUCtrl_i,

    output logic [DATA_WIDTH-1:0]   ALUResult_o,
    output logic Zero_o  
);

    always_comb begin
        case (ALUCtrl_i) 
            // ADD
            4'b0000: ALUResult_o = srcA_i + srcB_i;
            
            // SUB
            4'b0001: ALUResult_o = srcA_i - srcB_i;

            // AND
            4'b0010: ALUResult_o = srcA_i & srcB_i;

            // OR
            4'b0011: ALUResult_o = srcA_i | srcB_i;

            // XOR
            4'b0100: ALUResult_o = srcA_i ^ srcB_i;

            // SLT (Set less than signed)
            4'b0101: ALUResult_o = ($signed(srcA_i) < $signed(srcB_i)) ? 32'd1 : 32'd0; 

            // SLTU (Set less than unsigned)
            4'b0110: ALUResult_o = (srcA_i < srcB_i) ? 32'd1 : 32'd0;

            // SRL (Shift Right Logical)
            4'b0111: ALUResult_o = srcA_i >> srcB_i[SHIFT_WIDTH-1:0];

            // SLL (Shift Left Logical)
            4'b1000: ALUResult_o = srcA_i << srcB_i[SHIFT_WIDTH-1:0];

            // SRA (Shift Right Arithmetic)
            4'b1001: ALUResult_o = $signed(srcA_i) >>> srcB_i[SHIFT_WIDTH-1:0];
        
            default: ALUResult_o = 32'd0;
        endcase
        Zero_o = (ALUResult_o == 0) ? 1'b1 : 1'b0; 
    end

endmodule

