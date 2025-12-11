module controlunit #(
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0]   Instr_i,

    output logic                    RegWrite_o,
    output logic [3:0]              ALUCtrl_o,      // Determined using func3 and the 5th bits of op and funct7
    output logic                    ALUSrc_o,
    output logic [1:0]              Op1Src_o,       // Selects SrcA (0=Reg, 1=PC, 2=Zero)
    output logic [2:0]              ImmSrc_o,       // Decides which instruction bits to use as the immediate
    output logic                    MemWrite_o,    
    output logic [1:0]              ResultSrc_o,
    output logic [1:0]              MemType_o,
    output logic                    MemSign_o,
    output logic                    JumpSrc_o,
    output logic [2:0]              Branch_o,
    output logic                    BranchInstr_o
);

    logic [6:0]     op;
    logic           funct7_5;
    logic [2:0]     funct3;

    assign op =     Instr_i[6:0];
    assign funct3 =  Instr_i[14:12];
    assign funct7_5 = Instr_i[30];

    always_comb begin 
        // Default values
        ImmSrc_o = 3'b000;
        Branch_o = 3'b010; 
        ALUCtrl_o = 4'b0000;
        MemType_o = 2'b00;
        MemSign_o = 1'b0;
        Op1Src_o  = 2'b00; // Default: SrcA = Rs1

        case(op)
            7'd3: begin // I-type Load
                ALUCtrl_o = 4'b0000; // ADD
                case(funct3)
                    3'b000: begin // LB
                        MemType_o = 2'b01; 
                        MemSign_o = 1'b0; 
                    end
                    3'b001: begin // LH
                        MemType_o = 2'b10; 
                        MemSign_o = 1'b0; 
                    end
                    3'b010: begin // LW
                        MemType_o = 2'b00; 
                        MemSign_o = 1'b0;
                    end
                    3'b100: begin // LBU
                        MemType_o = 2'b01; 
                        MemSign_o = 1'b1;
                    end
                    3'b101: begin // LHU
                        MemType_o = 2'b10; 
                        MemSign_o = 1'b1; 
                    end

                    default: begin            
                        MemType_o = 2'b00;     
                        MemSign_o = 1'b0;
                    end
                endcase 
            end

            7'd19: begin // I-type ALU
                case(funct3)
                    3'b000: ALUCtrl_o = 4'b0000; // ADD
                    3'b001: ALUCtrl_o = 4'b1000; // SLL
                    3'b010: ALUCtrl_o = 4'b0101; // SLT
                    3'b011: ALUCtrl_o = 4'b0110; // SLTU
                    3'b100: ALUCtrl_o = 4'b0100; // XOR
                    3'b101: ALUCtrl_o = (funct7_5) ? 4'b1001 : 4'b0111; // SRA, SRL
                    3'b110: ALUCtrl_o = 4'b0011; // OR
                    3'b111: ALUCtrl_o = 4'b0010; // AND
                endcase
            end

            7'd51: begin // R-type ALU
                case(funct3)
                    3'b000: ALUCtrl_o = (funct7_5) ? 4'b0001 : 4'b0000; // SUB, ADD
                    3'b001: ALUCtrl_o = 4'b1000;                            //logical shift left
                    3'b010: ALUCtrl_o = 4'b0101;                            //set less than signed                  
                    3'b011: ALUCtrl_o = 4'b0110;                            //set less than unsigned   
                    3'b100: ALUCtrl_o = 4'b0100;                            //xor
                    3'b101: ALUCtrl_o = (funct7_5) ? 4'b1001 : 4'b0111;     //arithmetic shift right, logical shift right
                    3'b110: ALUCtrl_o = 4'b0011;                            //or
                    3'b111: ALUCtrl_o = 4'b0010;                            //and
                endcase
            end

            7'd23: begin // AUIPC
                ImmSrc_o  = 3'b011; // U-type
                ALUCtrl_o = 4'b0000; // ADD
                Op1Src_o  = 2'b01;   // SrcA = PC
            end

            7'd55: begin // LUI
                ImmSrc_o  = 3'b011; // U-type
                ALUCtrl_o = 4'b0000; // ADD
                Op1Src_o  = 2'b10;   // SrcA = Zero
            end

            7'd35: begin // S-type Store
                ImmSrc_o  = 3'b001; 
                ALUCtrl_o = 4'b0000; // ADD (Address calc)
                MemSign_o = 1'b0;
                case(funct3)
                    3'b000: MemType_o = 2'b01; // SB
                    3'b001: MemType_o = 2'b10; // SH
                    3'b010: MemType_o = 2'b00; // SW
                    default: MemType_o = 2'b00;
                endcase 
            end

            7'd99: begin // B-type Branch
                ImmSrc_o  = 3'b010;
                ALUCtrl_o = 4'b0000; 
                case(funct3)
                    3'b000: Branch_o = 3'b000; // BEQ
                    3'b001: Branch_o = 3'b001; // BNE
                    3'b100: Branch_o = 3'b100; // BLT
                    3'b101: Branch_o = 3'b101; // BGE
                    3'b110: Branch_o = 3'b110; // BLTU
                    3'b111: Branch_o = 3'b111; // BGEU
                    default: Branch_o = 3'b010;
                endcase
            end

            7'd103: begin // JALR
                ImmSrc_o  = 3'b000;
                ALUCtrl_o = 4'b0000; // ADD (Target = Rs1 + Imm)
                Op1Src_o  = 2'b00;   // SrcA = Rs1
            end

            7'd111: begin // JAL
                ImmSrc_o  = 3'b100; // J-type
                ALUCtrl_o = 4'b0000; // ADD (Target = PC + Imm)
                Op1Src_o  = 2'b01;   // SrcA = PC
            end

            default: ;
        endcase 
    end

    // Output Signals
    always_comb begin
        MemWrite_o      = (op == 7'd35) ? 1'b1 : 1'b0;
        // RegWrite: Load, R-type, I-type, U-type, JAL, JALR write to reg
        RegWrite_o      = (op == 7'd3 || op == 7'd19 || op == 7'd51 || op == 7'd23 || op == 7'd55 || op == 7'd111 || op == 7'd103) ? 1'b1 : 1'b0;
        // ALUSrc: 1 for Imm (Loads, S-type, I-type ALU, U-type, JAL, JALR). 0 for Reg (R-type, Branch)
        ALUSrc_o        = (op == 7'd51 || op == 7'd99) ? 1'b0 : 1'b1; 
        
        JumpSrc_o       = (op == 7'd103) ? 1'b1 : 1'b0; // Only used for JALR in some archs, but here handled by JumpE
        BranchInstr_o   = (op == 7'd99) ? 1'b1 : 1'b0;

        if (op == 7'd3)                             // Load: Result from Mem
            ResultSrc_o = 2'b01;
        else if (op == 7'd103 || op == 7'd111)      // JAL/JALR: Result is PC+4
            ResultSrc_o = 2'b10;
        else                                        // Default: Result from ALU
            ResultSrc_o = 2'b00;
    end

endmodule
