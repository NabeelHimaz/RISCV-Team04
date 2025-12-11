module execute #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0]    RD1E_i,
    input logic [DATA_WIDTH-1:0]    RD2E_i,
    input logic [DATA_WIDTH-1:0]    PCE_i,
    input logic [DATA_WIDTH-1:0]    ImmExtE_i,
    input logic [DATA_WIDTH-1:0]    PCPlus4E_i,
    
    input logic [4:0]               RdD_i,
    input logic [2:0]               BranchSrc_i, //controls branching MUX
    input logic [4:0]               Rs1E_i,  
    input logic [4:0]               Rs2E_i,      

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
    input logic [1:0]               Op1SrcE_i,

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
    logic [DATA_WIDTH-1:0]  SrcAE_Forwarded;

    // Resolve Forwarding for Register Data
    always_comb begin
        case(ForwardAEctrl_i)
        2'b00: SrcAE_Forwarded = RD1E_i;
        2'b01: SrcAE_Forwarded = ResultW_i;
        2'b10: SrcAE_Forwarded = ALUResultM_i;
        default: SrcAE_Forwarded = RD1E_i;
        endcase 
    end

    logic [DATA_WIDTH-1:0]  SrcAE_Final;

    // Resolve Op1 Source (Reg vs PC vs Zero)
    always_comb begin
        case(Op1SrcE_i)
            2'b00: SrcAE_Final = SrcAE_Forwarded; // Normal (Rs1)
            2'b01: SrcAE_Final = PCE_i;           // AUIPC, JAL
            2'b10: SrcAE_Final = 32'b0;           // LUI
            default: SrcAE_Final = SrcAE_Forwarded;
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

    logic [DATA_WIDTH-1:0] SrcB_ALU;
    assign SrcB_ALU = (ALUSrcE_i) ? ImmExtE_i : WriteDataE_o; 

    ALU ALU(
        .srcA_i(SrcAE_Final), // Use Final SrcA
        .srcB_i(SrcB_ALU),
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
    assign Rs1E_o = Rs1E_i;
    assign Rs2E_o = Rs2E_i;

endmodule
