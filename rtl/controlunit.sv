module controlunit #(
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0]   Instr_i,
    input  logic                    branchTaken_i,  //input from ALU

    output logic                    RegWrite_o,
    output logic [3:0]              ALUCtrl_o,      //determined using func3 and the 5th bits of op and funct7
    output logic                    ALUSrcB_o,
    output logic [2:0]              ImmSrc_o,       //decides which instruction bits to use as the immediate
    output logic                    PCSrc_o,
    output logic                    MemWrite_o,    
    output logic [1:0]              ResultSrc_o,
    output logic [1:0]              MemType_o,
    output logic                    MemSign_o,
    output logic                    JumpSrc_o,
    output logic                    ALUSrcA_o,
    output logic [2:0]              Branch_o
);

    logic [6:0]     op;
    logic           funct7_5;
    logic [2:0]     funct3;

    assign op =     Instr_i[6:0];
    assign funct3 =  Instr_i[14:12];
    assign funct7_5 = Instr_i[30];

    always_comb begin 
        ImmSrc_o = 3'b000;
        Branch_o = 3'b010; //added otherwise latches to last branch
        case(op)
            7'd3: begin                                                     //I-type 
                ALUCtrl_o = 4'b0000;

                case(funct3)
                    3'b000: begin
                        MemType_o = 2'b01;
                        MemSign_o = 1'b0;
                    end
                    3'b001: begin
                        MemType_o = 2'b10;
                        MemSign_o = 1'b0;                 
                    end
                    3'b010: begin
                        MemType_o = 2'b00;
                        MemSign_o = 1'b0;       //doesnt matter?
                    end
                    3'b100: begin
                        MemType_o = 2'b01;
                        MemSign_o = 1'b1;            
                    end
                    3'b101: begin
                        MemType_o = 2'b10;
                        MemSign_o = 1'b1; 
                    end

                    default: begin            
                        MemType_o = 2'b00;     
                        MemSign_o = 1'b0;
                    end
                endcase 
            end

            //NH: this logic doesn't work 100%, check testbench file
            7'd19, 7'd51: begin    
                Branch_o = 3'b010;                                         //Arithmetic I-type and R-type                   

                case(funct3)
                    3'b000: ALUCtrl_o = (funct7_5 && (op != 7'd19)) ? 4'b0001 : 4'b0000;     //sub, add
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
                ALUCtrl_o   = 4'b0000;  
                Branch_o = 3'b010;
            end

            7'd35: begin                //S-type
                ImmSrc_o    = 3'b001;
                ALUCtrl_o   = 4'b0000;
                Branch_o = 3'b010;
                //NH: syntax fix on line below, make sure to pull through to latest ver of controlunit
                MemSign_o = 1'b0;
                case(funct3)
                    3'b000: MemType_o = 2'b01;
                    3'b001: MemType_o = 2'b10;
                    3'b010: MemType_o = 2'b00;
                    
                    default: MemType_o = 2'b00; //NH: i just added a random default case, double check this is fine
                endcase 
            end

            7'd99: begin                //B-type
                ImmSrc_o    = 3'b010;
                ALUCtrl_o   = 4'b0000;  
                case(funct3)
                    3'b000: Branch_o = 3'b000;
                    3'b001: Branch_o = 3'b001;
                    3'b100: Branch_o = 3'b100;
                    3'b101: Branch_o = 3'b101;
                    3'b110: Branch_o = 3'b110;
                    3'b111: Branch_o = 3'b111;

                    default: Branch_o = 3'b010;
                endcase
            end

            7'd103: begin               //jalr   
                ImmSrc_o = 3'b000;      //sign extend bits [31:20]
                ALUCtrl_o = 4'b0000;   
                PCSrc_o = 1; 
            end
            7'd111: begin               //jal
                ImmSrc_o = 3'b100;      //instruction[31], instruction[19:12], instruction[20] instruction [30:21]
                ALUCtrl_o = 4'b0000;    //add imm + pc
                                        //ALUSrcB_o = 1; defined below input the immediate into the ALU
                                        //ResultSrc =2'b10 (defined at the bottom)
                PCSrc_o = 1;
            end
            default: ;
        endcase 
    end

    always_comb begin
        MemWrite_o      = (op == 7'd35) ? 1'b1 : 1'b0;
        RegWrite_o      = (op == 7'd35 || op == 7'd99) ? 1'b0 : 1'b1; 
        ALUSrcB_o       = (op == 7'd51 || op == 7'd99) ? 1'b0 : 1'b1; //added branch 99 for Branch instructions
        PCSrc_o         = (op == 7'd103 || op == 7'd111 || (op == 7'd99 && branchTaken_i)) ? 1'b1 : 1'b0; 
        JumpSrc_o       = (op == 7'd103) ? 1'b1 : 1'b0;
        ALUSrcA_o       = (op == 7'd23) ? 1'b1 : 1'b0;

        if (op == 7'd3)                             //use data from memory
            ResultSrc_o = 2'b01;
        else if (op == 7'd103 || op == 7'd111)      //JAL/JALR: use PC+4
            ResultSrc_o = 2'b10;
        else                                        //Default: use ALU result
            ResultSrc_o = 2'b00;
    end

endmodule
