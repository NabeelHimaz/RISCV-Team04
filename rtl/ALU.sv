module ALU #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_WIDTH = 5
)(
    input  logic [DATA_WIDTH-1:0]   srcA_i,
    input  logic [DATA_WIDTH-1:0]   srcB_i,
    input  logic [3:0]              ALUCtrl_i,
    input logic  [2:0]              branch_i,

    output logic [DATA_WIDTH-1:0]   ALUResult_o,
    output logic                    branchTaken_o
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

        case(branch_i)


            //BEQ 
            3'b000: branchTaken_o = (srcA_i == srcB_i);
        
            //BNE
            3'b001: branchTaken_o = (srcA_i != srcB_i);
            
            //BLT
            3'b100: branchTaken_o = ($signed(srcA_i) < $signed(srcB_i));
            
            //BGE
            3'b101: branchTaken_o = ($signed(srcA_i) >= $signed(srcB_i));
            
            //BLTU- unsigned
            3'b110: branchTaken_o = (srcA_i < srcB_i);
            
            //BGEU- unsigned
            3'b111: branchTaken_o = (srcA_i >= srcB_i);
            
            default: branchTaken_o = 1'b0;


        endcase
    end

endmodule
