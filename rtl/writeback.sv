module writeback #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0] ALUResultM_i,
    input logic [DATA_WIDTH-1:0] ReadDataW_i,
    input logic [DATA_WIDTH-1:0] PCPlus4W_i,
    input logic [1:0] ResultSrc_i,
    input logic [4:0] RdM_i,

    output logic [DATA_WIDTH-1:0] ResultW_o,
    output logic [4:0] RdW_o

);

//this is equivalent to a mux
always_comb begin
    case(ResultSrc_i)
        2'b00: ResultW_o = ALUResultM_i;
        2'b01: ResultW_o = ReadDataW_i;
        2'b10: ResultW_o = PCPlus4W_i;
        default: ResultW_o = {DATA_WIDTH{1'b0}};
    endcase
end

assign RdW_o = RdM_i; //this is the blue line that we added


endmodule
