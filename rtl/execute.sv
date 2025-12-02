module execute #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0]    RD1E_i,
    input logic [DATA_WIDTH-1:0]    RD2E_i,
    input logic [DATA_WIDTH-1:0]    PCE_i,
    input logic [DATA_WIDTH-1:0]    ImmExtE_i,
    input logic [DATA_WIDTH-1:0]    PCPlus4E_i,
    input logic [3:0]               ALUCtrl_i,
    input logic                     ALUSrcB_i,
    input logic                     ALUSrcA_i,
    input logic                     JumpCtrl_i  //This deals with the jump instruction 
    input logic [4:0]               RdD_i;
    input logic [2:0]               BranchSrc_i, //controls branching MUX

    output logic [DATA_WIDTH-1:0]   ALUResultE_o,
    output logic [DATA_WIDTH-1:0]   WriteDataE_o,
    output logic [DATA_WIDTH-1:0]   PCPlus4E_o,
    output logic [DATA_WIDTH-1:0]   PCTargetE_o,
    output logic [4:0]              RdE_o;
    output logic                    Zero_o
);

logic [DATA_WIDTH-1:0]  SrcBE;
logic [DATA_WIDTH-1:0]  PC_TargetE; //PC_TargetE before it goes into mux with JUMP instruction 
logic                   branchTaken;

assign SrcBE = (ALUSrc_i) ? ImmExtE_i : RD2E_i; //MUX for the second input into the ALU



ALU ALU(
    .srcA_i(RD1E_i),
    .srcB_i(SrcBE),
    .ALUCtrl_i(ALUCtrl_i),
    .branch_i(BranchSrc_i),

    .ALUResult_o(ALUResultE_o),
    .branchTaken_o(branchTaken),
    .Zero_o(Zero_o)
);

//output logic
always_comb begin
    PCPlus4E_o = PCPlus4E_i;
    PCTargetE = ImmExtE_i + PCE_i;
    WriteDataE_o = RD2E_i;
end

assign PCTargetE_o = (JumpCtrl_i) ? PC_TargetE : ALUResult_o; //mux for jump instruction 
assign RdE_o = RdD_i;

endmodule
