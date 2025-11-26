module pc_module #(
    parameter DATA_WIDTH = 32
) (
    input  logic clk,
    input  logic rst,
    input  logic PCsrc,
    input logic [DATA_WIDTH-1:0] PCTargetE_i, //this is the jump PC value coming after Execute
    //input  logic [DATA_WIDTH-1:0] ImmExt_i,

    output logic [DATA_WIDTH-1:0] PC,
    output logic [DATA_WIDTH-1:0] PC_Plus4 //this ouptut goes all the way to WriteBack
);

    //logic [DATA_WIDTH-1:0] branch_PC;
    
    logic [DATA_WIDTH-1:0] next_PC;
    logic [DATA_WIDTH-1:0] inc_PC;

    assign inc_PC = PC + 32'd4;
    
    assign PC_Plus4 = inc_PC;
    //assign branch_PC = PC + ImmExt_i;

    mux #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_mux (
        .in0(inc_PC),
        .in1(PCTargetE_i),
        .sel(PCsrc),
        .out(next_PC)
    );

    

    // Program Counter Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            PC <= 32'hBFC00000; // reset address
        else
            PC <= next_PC;
    end
    
    
endmodule


