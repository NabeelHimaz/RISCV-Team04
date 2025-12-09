module execute #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0]    RD1E_i,
    input logic [DATA_WIDTH-1:0]    RD2E_i,
    input logic [DATA_WIDTH-1:0]    PCE_i,
    input logic [DATA_WIDTH-1:0]    ImmExtE_i,
    input logic [DATA_WIDTH-1:0]    PCPlus4E_i,
    //input logic [3:0]               ALUCtrl_i, //we don't need because it is pipelined now, see below for ALUctrl signal
    
    //input logic                     JumpCtrl_i,  //This deals with the jump instruction 
    input logic [4:0]               RdD_i,
    input logic [2:0]               BranchSrc_i, //controls branching MUX
    input logic [4:0]               Rs1D_i,      
    input logic [4:0]               Rs2D_i,      

    
    input logic [DATA_WIDTH-1:0]    ResultW_i,   //result from writeback
    input logic [DATA_WIDTH-1:0]    ALUResultM_i,

    //control inputs  
    input logic                     RegWriteE_i,
    input logic [1:0]               ResultSrcE_i,
    input logic                     MemWriteE_i,
    input logic                     JumpE_i,
    input logic                     BranchE_i,
    input logic [3:0]               ALUCtrlE_i,
    input logic                     ALUSrcE_i,
    



    //from hazard unit
    input logic [1:0]               ForwardAEctrl_i,
    input logic [1:0]               ForwardBEctrl_i,

    //to hazard unit
    output logic [4:0]              Rs1E_o,
    output logic [4:0]              Rs2E_o,

    output logic [DATA_WIDTH-1:0]   ALUResultE_o,
    output logic [DATA_WIDTH-1:0]   WriteDataE_o,
    output logic [DATA_WIDTH-1:0]   PCPlus4E_o,
    output logic [4:0]              RdE_o,
    output logic                    branchTaken_o,
    output logic [DATA_WIDTH-1:0]   PCTargetE_o,
    output logic                    PCSrcE_o
);

logic [DATA_WIDTH-1:0]  SrcAE;

//mux for SrcAE based on hazard unit 
always_comb begin
    case(ForwardAEctrl_i)

    2'b00: SrcAE = RD1E_i;
    2'b01: SrcAE = ResultW_i;
    2'b10: SrcAE = ALUResultM_i;

    default: SrcAE = RD1E_i;
    endcase 
end

logic [DATA_WIDTH-1:0]  SrcBE;

//mux for srcBE based on hazard unit 
always_comb begin
    case(ForwardBEctrl_i)

    2'b00: WriteDataE_o = RD2E_i;
    2'b01: WriteDataE_o = ResultW_i;
    2'b10: WriteDataE_o = ALUResultM_i;

    default: WriteDataE_o = RD2E_i;
    endcase 
end

assign SrcBE = (ALUSrcE_i) ? ImmExtE_i : WriteDataE_o; //MUX for the second input into the ALU



ALU ALU(
    .srcA_i(SrcAE),
    .srcB_i(SrcBE),
    .ALUCtrl_i(ALUCtrlE_i),
    .branch_i(BranchSrc_i),

    .ALUResult_o(ALUResultE_o),
    .branchTaken_o(branchTaken_o)
);

//output logic
logic [DATA_WIDTH-1:0] PCTargetE;
always_comb begin
    PCPlus4E_o = PCPlus4E_i;
    PCTargetE = ImmExtE_i + PCE_i;
end

assign PCTargetE_o = (JumpE_i) ? ALUResultE_o : PCTargetE;


assign PCSrcE_o = (BranchE_i && branchTaken_o) || JumpE_i;
assign RdE_o = RdD_i;
assign Rs1E_o = Rs1D_i;  // Pass through source register 1 from decode
assign Rs2E_o = Rs2D_i;  // Pass through source register 2 from decode

endmodule