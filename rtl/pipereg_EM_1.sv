module pipereg_EM_1 #(
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,
    input  logic                  clr,

    // Control Inputs (from Execute)
    input  logic       RegWriteE, MemWriteE, MemSignE,
    input  logic [1:0] ResultSrcE, MemTypeE,

    // Data Inputs (from Execute)
    input  logic [DATA_WIDTH-1:0] ALUResultE, WriteDataE, PCPlus4E,
    input  logic [4:0]            RDE,

    // Control Outputs (to Memory)
    output logic       RegWriteM, MemWriteM, MemSignM,
    output logic [1:0] ResultSrcM, MemTypeM,

    // Data Outputs (to Memory)
    output logic [DATA_WIDTH-1:0] ALUResultM, WriteDataM, PCPlus4M,
    output logic [4:0]            RDM
);

    always_ff @(posedge clk) begin
        if (rst || clr) begin
            RegWriteM  <= 1'b0; MemWriteM <= 1'b0; MemSignM <= 1'b0;
            ResultSrcM <= 2'b0; MemTypeM  <= 2'b0;
            
            ALUResultM <= {DATA_WIDTH{1'b0}};
            WriteDataM <= {DATA_WIDTH{1'b0}};
            PCPlus4M   <= {DATA_WIDTH{1'b0}};
            RDM        <= 5'b0;
        end
        else if (en) begin
            RegWriteM  <= RegWriteE; MemWriteM <= MemWriteE; MemSignM <= MemSignE;
            ResultSrcM <= ResultSrcE; MemTypeM  <= MemTypeE;
            
            ALUResultM <= ALUResultE;
            WriteDataM <= WriteDataE;
            PCPlus4M   <= PCPlus4E;
            RDM        <= RDE;
        end
    end

endmodule