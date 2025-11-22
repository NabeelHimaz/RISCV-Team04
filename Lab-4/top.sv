module top #(
    parameter DATA_WIDTH = 32 //add keyword parameter
) (
    input   logic clk,
    input   logic rst,
    output  logic [DATA_WIDTH-1:0] a0    
);
    //dont need next line
    //assign a0 = 32'd5;
    //a0 is already driven by the regfile you dont need to initialise it like this

    //pc module
    logic [DATA_WIDTH-1:0]  PC;

    pc_module pc(
        .clk(clk),
        .rst(rst),
        .PCsrc(PCsrc),
        .immOp(immOp),

        .PC(PC)
    );

    //instrmem
    logic [DATA_WIDTH-1:0] instr;

    instrmem instrmem(
        .A(PC),

        .RD(instr)
    );

    //sign extension    
    logic [DATA_WIDTH-1:0]  immOp;

    extend extend(
        .instr(instr),
        .ImmSrc(ImmSrc),

        //immOp in this file and immop in the extend block
        //kind of just patched it for now but might want to get camelcase updated in every file for consistency
        .immop(immOp)
    );

    //control unit
    logic RegWrite;
    logic ALUctrl;
    logic ALUsrc;
    logic ImmSrc;
    logic PCsrc;

    controlunit controlunit(
        .instr(instr),
        .EQ(EQ),

        .RegWrite(RegWrite),
        .ALUctrl(ALUctrl),
        .ALUsrc(ALUsrc),
        .ImmSrc(ImmSrc),
        .PCsrc(PCsrc)
    );

    //reg file
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [DATA_WIDTH-1:0] ALUop1;
    logic [DATA_WIDTH-1:0] regOp2;


    always_comb begin

        ///default values
        rs1 = instr[19:15];
        rs2 = 5'b0;
        rd = 5'b0;

        case(instr[6:0])
            7'b0000011: begin
                rd = instr[11:7];
            end
            7'b0100011: begin
                rs2 = instr[24:20];
            end
            7'b1100011: begin
                rs2 = instr[24:20];
            end
            default: ;
        endcase
    end

    //need to define this
    logic [DATA_WIDTH-1:0] ALUout;

    regfile regfile(
        .clk(clk),
        .AD1(rs1),
        .AD2(rs2),
        .AD3(rd),
        .WE3(RegWrite),
        .WD3(ALUout),

        .RD1(ALUop1),
        .RD2(regOp2),
        .a0(a0)
    );


    logic [DATA_WIDTH-1:0] ALUop2;

    mux mux (
        .in0(regOp2),
        .in1(immOp),
        .sel(ALUsrc),

        .out(ALUop2)
    );

    //dont need this here anymore
    //logic [DATA_WIDTH-1:0] ALUout;
    
    logic EQ;

    ALU alu(
        .ALUop1(ALUop1),
        .ALUop2(ALUop2),
        .ALUctrl(ALUctrl),
        
        .SUM(ALUout),
        .EQ(EQ)
    );
   

endmodule
