module pipereg_MW_1 #(
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,
    input  logic                  clr,

    // Control Inputs (from Memory) 
    input  logic       RegWriteM,
    input  logic [1:0] ResultSrcM,

    // Data Inputs (from Memory) 
    input  logic [DATA_WIDTH-1:0] ALUResultM, ReadDataM, PCPlus4M,
    input  logic [4:0]            RDM,

    // Control Outputs (to Writeback) 
    output logic       RegWriteW,
    output logic [1:0] ResultSrcW,

    // Data Outputs (to Writeback) 
    output logic [DATA_WIDTH-1:0] ALUResultW, ReadDataW, PCPlus4W,
    output logic [4:0]            RDW
);

    always_ff @(posedge clk) begin
        if (rst || clr) begin
            RegWriteW  <= 1'b0; 
            ResultSrcW <= 2'b0;
            
            ALUResultW <= {DATA_WIDTH{1'b0}};
            ReadDataW  <= {DATA_WIDTH{1'b0}};
            PCPlus4W   <= {DATA_WIDTH{1'b0}};
            RDW        <= 5'b0;
        end
        else if (en) begin
            RegWriteW  <= RegWriteM; 
            ResultSrcW <= ResultSrcM;
            
            ALUResultW <= ALUResultM;
            ReadDataW  <= ReadDataM;
            PCPlus4W   <= PCPlus4M;
            RDW        <= RDM;
        end
    end

endmodule
