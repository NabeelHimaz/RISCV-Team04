module controlunit #(
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0]   instr,
    input  logic                    EQ,         //only needed for beq instructions
    output logic                    RegWrite,
    output logic [2:0]              ALUctrl,
    output logic                    ALUsrc,
    output logic [1:0]              ImmSrc,
    output logic                    PCsrc
);

    logic [6:0]     op;
    logic [1:0]     ALUOp;

    assign op =     instr[6:0];

    always_comb begin

        //default case
        ALUOp = 2'b00;
        RegWrite = 1'b0;
        ImmSrc = 2'b00;
        ALUsrc = 1'b0;
        PCsrc = 1'b0;

        case(op)
            7'b0000011: begin
                ALUOp = 2'b00;
                RegWrite = 1'b1;
                ImmSrc = 2'b00;
                ALUsrc = 1'b1;
                PCsrc = 1'b0;       //equivalent to 1'b0 & EQ
            end
            7'b0100011: begin
                ALUOp = 2'b00;
                RegWrite = 1'b0;
                ImmSrc = 2'b01;
                ALUsrc = 1'b1;
                PCsrc = 1'b0;
            end
            7'b1100011: begin
                ALUOp = 2'b01;
                RegWrite = 1'b0;
                ImmSrc = 2'b10;
                ALUsrc = 1'b0;
                PCsrc = EQ;         //1'b1 & EQ
            end
            default: ;
        endcase
    end

    always_comb begin
        case (ALUOp)
            2'b00: begin
                ALUctrl = 3'b000; 
            end
            2'b01: begin
                ALUctrl = 3'b001; 
            end
            default: ALUctrl = 3'b000;
        endcase
    end

endmodule
