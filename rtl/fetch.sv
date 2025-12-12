module fetch #(
    parameter DATA_WIDTH = 32
) (
    input logic PCSrc_i, // This is now Mispredict correction signal
    input logic clk,
    input logic rst,
    input logic StallF,
    input logic [DATA_WIDTH-1:0] PCTargetE_i, // Correct Target from Execute

    // Inputs for Predictor Update
    input logic [DATA_WIDTH-1:0] PCE_i,
    input logic                  BranchTakenE_i,
    input logic                  BranchE_i,

    output logic [DATA_WIDTH-1:0] PC_Plus4_F, 
    output logic [DATA_WIDTH-1:0] PC_F, 
    output logic [DATA_WIDTH-1:0] Instr_o, 
    
    // Prediction Output
    output logic                  PredictTakenF_o,

    output logic [4:0] A1_o,
    output logic [4:0] A2_o,
    output logic [4:0] A3_o
);
    logic [DATA_WIDTH-1:0]  PC, NextPC, PredictedTargetF;
    logic [DATA_WIDTH-1:0]  PC_Plus4;
    logic                   PredictTakenF;

    assign PC_Plus4 = PC + 32'd4;
    assign PC_Plus4_F = PC_Plus4;
    assign PC_F = PC;



        
    branch_predictor bp (
        .clk(clk), .rst(rst),
        .PCF(PC),
        .PredictTakenF(PredictTakenF),
        .PredictedTargetF(PredictedTargetF),
        
        // Update ports
        .PCE(PCE_i),
        .PCTargetE(PCTargetE_i),
        .BranchE(BranchE_i),
        .BranchTakenE(BranchTakenE_i)
    );

    assign PredictTakenF_o = PredictTakenF;

    // Next PC Logic
    // Priority: 1. Mispredict (PCSrc_i from Exec), 2. Stall, 3. Prediction, 4. PC+4
    always_comb begin
        if (PCSrc_i)       NextPC = PCTargetE_i; // Correction
        else if (PredictTakenF) NextPC = PredictedTargetF;
        else               NextPC = PC_Plus4;
    end

    // PC Register
    always_ff @(posedge clk) begin
        if (rst) PC <= 32'hBFC00000;
        else if (!StallF) PC <= NextPC;
    end

    instrmem instruction_memory (
        .addr_i(PC),
        .read_data_o(Instr_o)
    );

    assign A1_o = Instr_o[19:15];
    assign A2_o = Instr_o[24:20];
    assign A3_o = Instr_o[11:7];

endmodule
