module branch_predictor #(
    parameter DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    
    //Fetch Stage: Predict
    input  logic [DATA_WIDTH-1:0]   PCF,
    output logic [DATA_WIDTH-1:0]   PredictedTargetF,
    output logic                    PredictTakenF,

    //Execute Stage: Update
    input  logic [DATA_WIDTH-1:0]   PCE,
    input  logic [DATA_WIDTH-1:0]   PCTargetE,
    input  logic                    BranchTakenE,
    input  logic                    BranchE
);
    //Simple Direct Mapped BTB with 64 Entries
    localparam ENTRIES = 64;
    localparam INDEX_BITS = 6; 

    logic [DATA_WIDTH-1:0]  btb_target [0:ENTRIES-1];
    logic [DATA_WIDTH-1:0]  btb_tag    [0:ENTRIES-1];
    logic                   btb_valid  [0:ENTRIES-1];
    logic [1:0]             bht        [0:ENTRIES-1]; // 2-bit counter

    logic [INDEX_BITS-1:0]  indexF, indexE;
    logic [DATA_WIDTH-1:0]  tagF;

    assign indexF = PCF[INDEX_BITS+1:2];
    assign tagF   = PCF;
    assign indexE = PCE[INDEX_BITS+1:2];

    //Read / Predict Logic
    always_comb begin
        if (btb_valid[indexF] && (btb_tag[indexF] == tagF) && bht[indexF][1]) begin
            PredictTakenF = 1'b1;
            PredictedTargetF = btb_target[indexF];
        end else begin
            PredictTakenF = 1'b0;
            PredictedTargetF = PCF + 4; // Default not taken
        end
    end

    //Update Logic
    integer i;
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i=0; i<ENTRIES; i++) begin
                btb_valid[i] <= 1'b0;
                bht[i]       <= 2'b01; // Weakly Not Taken
            end
        end 
        else if (BranchE) begin
            //Update Tag and Target
            btb_valid[indexE] <= 1'b1;
            btb_tag[indexE]   <= PCE;
            btb_target[indexE] <= PCTargetE;

            //Update 2-bit Counter (Saturating)
            case (bht[indexE])
                2'b00: bht[indexE] <= (BranchTakenE) ? 2'b01 : 2'b00;
                2'b01: bht[indexE] <= (BranchTakenE) ? 2'b10 : 2'b00;
                2'b10: bht[indexE] <= (BranchTakenE) ? 2'b11 : 2'b01;
                2'b11: bht[indexE] <= (BranchTakenE) ? 2'b11 : 2'b10;
            endcase
        end
    end

endmodule
