module controlunit #(
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0]   InstrA_i,
    input  logic [DATA_WIDTH-1:0]   InstrB_i,
    output logic                    RegWriteA_o,
    output logic [3:0]              ALUCtrlA_o,
    output logic                    ALUSrcBA_o,
    output logic [2:0]              ImmSrcA_o,
    output logic                    RegWriteB_o,
    output logic [3:0]              ALUCtrlB_o,
    output logic                    ALUSrcBB_o,
    output logic [2:0]              ImmSrcB_o
);

    logic [6:0]     opA;
    logic           funct7_5A;
    logic [2:0]     funct3A;

    assign opA =        InstrA_i[6:0];
    assign funct3A =    InstrA_i[14:12];
    assign funct7_5A =  InstrA_i[30];

    logic [6:0]     opB;
    logic           funct7_5B;
    logic [2:0]     funct3B;

    assign opB =        InstrB_i[6:0];
    assign funct3B =    InstrB_i[14:12];
    assign funct7_5B =  InstrB_i[30];

    always_comb begin 
        ImmSrcA_o = 3'b000;
        
        case(opA)
            7'd19, 7'd51: begin                                                //Arithmetic I-type and R-type                   
                case(funct3A)
                    3'b000: ALUCtrlA_o = (funct7_5A && (opA != 7'd19)) ? 4'b0001 : 4'b0000;     //sub, add
                    3'b001: ALUCtrlA_o = 4'b1000;                                                //logical shift left                      
                    3'b010: ALUCtrlA_o = 4'b0101;                                                //set less than signed                  
                    3'b011: ALUCtrlA_o = 4'b0110;                                                //set less than unsigned   
                    3'b100: ALUCtrlA_o = 4'b0100;                                                //xor
                    3'b101: ALUCtrlA_o = (funct7_5A) ? 4'b1001 : 4'b0111;                       //arithmetic shift right, logical shift right
                    3'b110: ALUCtrlA_o = 4'b0011;                                                //or
                    3'b111: ALUCtrlA_o = 4'b0010;                                                //and
                endcase 
            end
            
            default: ;
        endcase 
    end

    always_comb begin
        RegWriteA_o = (opA == 7'd19 || opA == 7'd51) ? 1'b1 : 1'b0; 
        ALUSrcBA_o = (opA == 7'd51) ? 1'b0 : 1'b1;
    end

    always_comb begin 
        ImmSrcB_o = 3'b000;
        
        case(opB)
            7'd19, 7'd51: begin                                                //Arithmetic I-type and R-type                   
                case(funct3B)
                    3'b000: ALUCtrlB_o = (funct7_5B && (opB != 7'd19)) ? 4'b0001 : 4'b0000;     //sub, add
                    3'b001: ALUCtrlB_o = 4'b1000;                                                //logical shift left                      
                    3'b010: ALUCtrlB_o = 4'b0101;                                                //set less than signed                  
                    3'b011: ALUCtrlB_o = 4'b0110;                                                //set less than unsigned   
                    3'b100: ALUCtrlB_o = 4'b0100;                                                //xor
                    3'b101: ALUCtrlB_o = (funct7_5B) ? 4'b1001 : 4'b0111;                       //arithmetic shift right, logical shift right
                    3'b110: ALUCtrlB_o = 4'b0011;                                                //or
                    3'b111: ALUCtrlB_o = 4'b0010;                                                //and
                endcase 
            end
            
            default: ;
        endcase 
    end

    always_comb begin
        RegWriteB_o = (opB == 7'd19 || opB == 7'd51) ? 1'b1 : 1'b0; 
        ALUSrcBB_o = (opB == 7'd51) ? 1'b0 : 1'b1;
    end

endmodule
