module extend #(
    parameter DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0]   InstrA_i,
    input  logic [DATA_WIDTH-1:0]   InstrB_i,
    input  logic [2:0]              ImmSrcA_i,
    input  logic [2:0]              ImmSrcB_i,
    output logic [DATA_WIDTH-1:0]   ImmExtA_o,
    output logic [DATA_WIDTH-1:0]   ImmExtB_o
);

    always_comb begin
        case(ImmSrcA_i)
            3'b000: ImmExtA_o = {{20{InstrA_i[31]}}, InstrA_i[31:20]};                              // I-type
            3'b001: ImmExtA_o = {{20{InstrA_i[31]}}, InstrA_i[31:25], InstrA_i[11:7]};             // S-type
            3'b010: ImmExtA_o = {{20{InstrA_i[31]}}, InstrA_i[7], InstrA_i[30:25], InstrA_i[11:8], 1'b0}; // B-type
            3'b011: ImmExtA_o = {InstrA_i[31:12], 12'b0};                                           // U-type
            3'b100: ImmExtA_o = {{12{InstrA_i[31]}}, InstrA_i[19:12], InstrA_i[20], InstrA_i[30:21], 1'b0}; // J-type
            default: ImmExtA_o = {DATA_WIDTH{1'b0}};
        endcase
    end

    always_comb begin
        case(ImmSrcB_i)
            3'b000: ImmExtB_o = {{20{InstrB_i[31]}}, InstrB_i[31:20]};                              // I-type
            3'b001: ImmExtB_o = {{20{InstrB_i[31]}}, InstrB_i[31:25], InstrB_i[11:7]};             // S-type
            3'b010: ImmExtB_o = {{20{InstrB_i[31]}}, InstrB_i[7], InstrB_i[30:25], InstrB_i[11:8], 1'b0}; // B-type
            3'b011: ImmExtB_o = {InstrB_i[31:12], 12'b0};                                           // U-type
            3'b100: ImmExtB_o = {{12{InstrB_i[31]}}, InstrB_i[19:12], InstrB_i[20], InstrB_i[30:21], 1'b0}; // J-type
            default: ImmExtB_o = {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule
