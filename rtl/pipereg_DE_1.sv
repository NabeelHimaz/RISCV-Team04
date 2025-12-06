module pipereg_DE_1 #(
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,
    input  logic                  clr, // Sync clear for flushing (Branches)

    //  Control Inputs (from Decode)
    input  logic       RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD, MemSignD,
    input  logic [1:0] ResultSrcD, MemTypeD,
    input  logic [3:0] ALUCtrlD,

    //  Data Inputs (from Decode)
    input  logic [DATA_WIDTH-1:0] RD1D, RD2D, PCD, ImmExtD, PCPlus4D,
    input  logic [4:0]            RDD,

    //  Control Outputs (to Execute)
    output logic       RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, MemSignE,
    output logic [1:0] ResultSrcE, MemTypeE,
    output logic [3:0] ALUCtrlE,

    //  Data Outputs (to Execute)
    output logic [DATA_WIDTH-1:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E,
    output logic [4:0]            RDE
);

    always_ff @(posedge clk) begin
        if (rst || clr) begin
            // Control
            RegWriteE  <= 1'b0; MemWriteE <= 1'b0; JumpE    <= 1'b0;
            BranchE    <= 1'b0; ALUSrcE   <= 1'b0; MemSignE <= 1'b0;
            ResultSrcE <= 2'b0; MemTypeE  <= 2'b0; ALUCtrlE <= 4'b0;
            
            // Data
            RD1E       <= {DATA_WIDTH{1'b0}};
            RD2E       <= {DATA_WIDTH{1'b0}};
            PCE        <= {DATA_WIDTH{1'b0}};
            ImmExtE    <= {DATA_WIDTH{1'b0}};
            PCPlus4E   <= {DATA_WIDTH{1'b0}};
            RDE        <= 5'b0;
        end
        else if (en) begin
            // Control
            RegWriteE  <= RegWriteD; MemWriteE <= MemWriteD; JumpE    <= JumpD;
            BranchE    <= BranchD;   ALUSrcE   <= ALUSrcD;   MemSignE <= MemSignD;
            ResultSrcE <= ResultSrcD;MemTypeE  <= MemTypeD;  ALUCtrlE <= ALUCtrlD;
            
            // Data
            RD1E       <= RD1D;
            RD2E       <= RD2D;
            PCE        <= PCD;
            ImmExtE    <= ImmExtD;
            PCPlus4E   <= PCPlus4D;
            RDE        <= RDD;
        end
    end

endmodule
