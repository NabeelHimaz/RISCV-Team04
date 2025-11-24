module controlunit #(
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0]   Instr_i,
    input  logic                    Zero_i,         //only needed for beq instructions

    output logic                    RegWrite_o,
    output logic [3:0]              ALUCtrl_o,      //determined using func3 and the 5th bits of op and funct7
    output logic                    ALUSrc_o,
    output logic [2:0]              ImmSrc_o,       //decides which instruction bits to use as the immediate
    output logic                    PCSrc_o,
    output logic                    MemWrite_o,    
    output logic [1:0]              ResultSrc_o
);

    logic [6:0]     op;
    logic           funct7_5;
    logic [2:0]     funct3;

    assign op =     Instr_i[6:0];
    assign funct3 =  Instr_i[14:12];
    assign funct7_5 = Instr_i[30];

    always_comb begin 
        ImmSrc_o = 3'b000;
        case(op)
            7'd3: begin                                                     //I-type 
                ALUCtrl_o = 4'b0000;
            end

            7'd19, 7'd51: begin                                             //Arithmetic I-type and R-type                                      

                case(funct3)
                    3'b000: ALUCtrl_o = (funct7_5) ? 4'b0001 : 4'b0000;     //sub, add           
                    3'b001: ALUCtrl_o = 4'b1000;                            //logical shift left                      
                    3'b010: ALUCtrl_o = 4'b0101;                            //set less than signed                  
                    3'b011: ALUCtrl_o = 4'b0110;                            //set less than unsigned   
                    3'b100: ALUCtrl_o = 4'b0100;                            //xor
                    3'b101: ALUCtrl_o = (funct7_5) ? 4'b1001 : 4'b0111;     //arithmetic shift right, logical shift right
                    3'b110: ALUCtrl_o = 4'b0011;                            //or
                    3'b111: ALUCtrl_o = 4'b0010;                            //and
                endcase 
            end

            7'd23, 7'd55: begin //U-type
                ImmSrc_o    = 3'b011;
                ALUCtrl_o   = 4'b0000;  //doesnt matter
            end

            7'd35: begin                //S-type
                ImmSrc_o    = 3'b001;
                ALUCtrl_o   = 4'b0000;
            end

            7'd99: begin                //B-type
                ImmSrc_o    = 3'b010;
                ALUCtrl_o   = 4'b0000;  //doesnt matter
            end

            7'd103: begin               //jalr
                ImmSrc_o = 3'b000;
                ALUCtrl_o = 4'b0000;    //need a new ALU instruction
            end
            7'd111: begin               //jal
                ImmSrc_o = 3'b100;
                ALUCtrl_o = 4'b0000;   
            end
            default: ;
        endcase 
    end

    always_comb begin
        MemWrite_o      = (op == 7'd35) ? 1'b1 : 1'b0;
        RegWrite_o      = (op == 7'd35 || op == 7'd99) ? 1'b0 : 1'b1; 
        ALUSrc_o        = (op == 7'd51) ? 1'b0 : 1'b1;
        PCSrc_o         = (op == 7'd103 || op == 7'd111 || op == 7'd99 && Zero_i) ? 1'b1 : 1'b0;
        
        if (op == 7'd3)                             //use data from memory
            ResultSrc_o = 2'b01;
        else if (op == 7'd103 || op == 7'd111)      //JAL/JALR: use PC+4
            ResultSrc_o = 2'b10;
        else                                        //Default: use ALU result
            ResultSrc_o = 2'b00;
    end

endmodule
