module top #(
    parameter DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    output logic [DATA_WIDTH-1:0]   a0
);

    // Program counter and instruction
    logic [DATA_WIDTH-1:0] PC;
    logic [DATA_WIDTH-1:0] instr;

    // Immediate after sign/zero extension
    logic [DATA_WIDTH-1:0] ImmExt;

    // Register file signals
    logic [4:0] rs1, rs2, rd;
    logic [DATA_WIDTH-1:0] rdData;     // data written to regfile (from ALU / memory)
    logic [DATA_WIDTH-1:0] reg_rdata1; // RD1_o
    logic [DATA_WIDTH-1:0] reg_rdata2; // RD2_o

    // ALU signals
    logic [DATA_WIDTH-1:0] ALUop1;
    logic [DATA_WIDTH-1:0] ALUop2;
    logic [DATA_WIDTH-1:0] ALUout;

    // Control signals (sizes match controlunit.sv)
    logic                    RegWrite;
    logic [3:0]              ALUCtrl;
    logic                    ALUSrc;
    logic [2:0]              ImmSrc;
    logic                    PCSrc;
    logic                    MemWrite;
    logic [1:0]              ResultSrc;

    // Zero flag for branches (controlunit expects Zero_i)
    logic Zero;

    // pc module
    pc_module #(
        .DATA_WIDTH(DATA_WIDTH)
    ) pc (
        .clk(clk),
        .rst(rst),
        .PCsrc(PCSrc),
        .ImmExt_o(ImmExt),

        .PC(PC)
    );

    // instruction memory (assumed interface: A -> address, RD -> instruction)
    instrmem instrmem (
        .A(PC),
        .RD(instr)
    );

    // sign/zero extender
    extend extend_u (
        .instr_i(instr),
        .ImmSrc_i(ImmSrc),
        .immop_o(immOp)
    );

    // control unit
    controlunit control_u (
        .Instr_i(instr),
        .Zero_i(Zero),

        .RegWrite_o(RegWrite),
        .ALUCtrl_o(ALUCtrl),
        .ALUSrc_o(ALUSrc),
        .ImmSrc_o(ImmSrc),
        .PCSrc_o(PCSrc),
        .MemWrite_o(MemWrite),
        .ResultSrc_o(ResultSrc)
    );

    // register address extraction (common R/I/S/B formats)
    always_comb begin
        rs1 = instr[19:15];
        rs2 = instr[24:20];
        rd  = instr[11:7];
    end

    // regfile instantiation (ports from regfile.sv)
    regfile regfile_u (
        .clk(clk),
        .AD1_i(rs1),
        .AD2_i(rs2),
        .AD3_i(rd),
        .WE3_i(RegWrite),
        .WD3_i(ALUout),

        .RD1_o(ALUop1),
        .RD2_o(reg_rdata2),
        .a0_o(a0)
    );

    // choose between register second operand and immediate
    mux #(
        .DATA_WIDTH(DATA_WIDTH)
    ) mux_alu_src (
        .in0(reg_rdata2),
        .in1(immOp),
        .sel(ALUSrc),
        .out(ALUop2)
    );

    // ALU (ports from ALU.sv)
    ALU alu_u (
        .srcA_i(ALUop1),
        .srcB_i(ALUop2),
        .ALUCtrl_i(ALUCtrl),

        .ALUResult_o(ALUout)
    );

    // Zero flag used by control unit (BEQ uses equality check)
    always_comb begin
        Zero = (ALUout == {DATA_WIDTH{1'b0}});
    end

endmodule
