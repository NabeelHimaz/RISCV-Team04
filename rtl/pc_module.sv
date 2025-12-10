module pc_module #(
    parameter DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,     // Enable signal (active high) - Used for stalling
    input  logic                  PCsrc,
    input  logic [DATA_WIDTH-1:0] PCTargetE_i, 

    output logic [DATA_WIDTH-1:0] PC,
    output logic [DATA_WIDTH-1:0] PC_Plus4 
);
    
    logic [DATA_WIDTH-1:0] next_PC;
    logic [DATA_WIDTH-1:0] inc_PC;

    assign inc_PC = PC + 32'd4;
    assign PC_Plus4 = inc_PC;

    mux #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_mux (
        .in0(inc_PC),
        .in1(PCTargetE_i),
        .sel(PCsrc),
        .out(next_PC)
    );

    always_ff @(posedge clk) begin
        if (rst)
            PC <= 32'hBFC00000;
        else if (en)             // Only update if enabled
            PC <= next_PC;
    end
endmodule