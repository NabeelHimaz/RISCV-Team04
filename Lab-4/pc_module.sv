module pc_module #(
    parameter DATA_WIDTH = 32
) (
    input  logic clk,
    input  logic rst,
    input  logic PCsrc,
    input  logic [DATA_WIDTH-1:0] immOp,
    output logic [DATA_WIDTH-1:0] PC
);

    logic [DATA_WIDTH-1:0] branch_PC;
    logic [DATA_WIDTH-1:0] next_PC;
    logic [DATA_WIDTH-1:0] inc_PC;

    assign inc_PC = PC + 32'd4;
    
    assign branch_PC = PC + immOp;

    mux #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_mux (
        .in0(inc_PC),
        .in1(branch_PC),
        .sel(PCsrc),
        .out(next_PC)
    );

    

    // Program Counter Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            PC <= {DATA_WIDTH{1'b0}};
        else
            PC <= next_PC;
    end
    
endmodule
