module pipereg_FD_1 #(
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,
    input  logic                  clr, // Sync clear for flushing (Branches)
    
    // Inputs from Fetch
    input  logic [DATA_WIDTH-1:0] InstrF,
    input  logic [DATA_WIDTH-1:0] PCF,
    input  logic [DATA_WIDTH-1:0] PCPlus4F,

    // Outputs to Decode
    output logic [DATA_WIDTH-1:0] InstrD,
    output logic [DATA_WIDTH-1:0] PCD,
    output logic [DATA_WIDTH-1:0] PCPlus4D
);

    always_ff @(posedge clk) begin
        if (rst) begin
            InstrD   <= {DATA_WIDTH{1'b0}};
            PCD      <= {DATA_WIDTH{1'b0}};
            PCPlus4D <= {DATA_WIDTH{1'b0}};
        end
        else if (clr) begin
            InstrD   <= {DATA_WIDTH{1'b0}};
            PCD      <= {DATA_WIDTH{1'b0}};
            PCPlus4D <= {DATA_WIDTH{1'b0}};
        end
        else if (en) begin
            InstrD   <= InstrF;
            PCD      <= PCF;
            PCPlus4D <= PCPlus4F;
        end
    end

endmodule
