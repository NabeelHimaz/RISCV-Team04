module controlunit #(
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0]   Instr_i,
    input  logic                    Zero_i,         //only needed for beq instructions

    output logic                    RegWrite_o,
    output logic [3:0]              ALUCtrl_o,      //determined using func3 and the 5th bits of op and funct7
    output logic                    ALUSrc_o,
    //output logic [1:0]              ALUSrcA_o,
    //output logic [1:0]              ALUSrcB_o,
    output logic [1:0]              ImmSrc_o,       //decides which instruction bits to use as the immediate
    output logic                    PCSrc_o,
    output logic                    MemWrite_o,    
    output logic [1:0]              ResultSrc_o
    //output logic                    JumpD_o
    //output logic                    BranchD
    //output logic                    PCWrite_o,
    //output logic                    AdrSrc_o,
    //output logic                    IRWrite_o,
);

    logic [6:0]     op;
    logic           funct7_5;
    logic [2:0]     funct3;

    assign op =     Instr[6:0];
    assign func3 =  Instr[14:12];
    assign funct7 = Instr[30];

    always_comb begin 
        case(op)
        7'd19, 7'd3: begin  //I-type 
            case(funct3) 
                3'b000, 3'b001:begin
                    ImmSrc_o = 2'b10; //sign extend Instr[31:20] 
                end
                3'b100, 3'b101: begin
                    ImmSrc_o = 2'b00; //zero extend Instr[31:20]
                end
            ImmSrc_o    =
            ALUCtrl_o   =
        end

        7'd23, 7'd55: begin //U-type
            ImmSrc_o    =
            ALUCtrl_o   =
        end

        7'd35: begin        //S-type
            ImmSrc_o    =
            ALUCtrl_o   =
        end

        7'd51: begin        //R-type
            ImmSrc_o    =
            ALUCtrl_o   =
        end

        7'd99: begin        //B-type
            ImmSrc_o    =
            ALUCtrl_o   =
        end
    end

    always_comb begin
        MemWrite_o      = (op == 7'd35) ? 1'b1 : 1'b0;
        RegWrite_o      = (op == 7'd35 || 7'd99 || 7'd103 || 7'd111) ? 1'b0 : 1'b1;
        ALUSrc_o        = (op == 7'd51) ? 1'b0 : 1'b1;
        ResultSrc_o     = (op == 7'd3) ? 1'b1 : 1'b0;
        PCSrc_o         = (op == 7'd103 || 7'd111) ? 1'b0 : 1'b1;
    end

endmodule
