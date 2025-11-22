module regfile #(
    parameter ADDRESS_WIDTH = 5,
    parameter DATA_WIDTH    = 32
) (
    input  logic                         clk,
    input  logic [ADDRESS_WIDTH-1:0]     AD1,  
    input  logic [ADDRESS_WIDTH-1:0]     AD2, 
    input  logic [ADDRESS_WIDTH-1:0]     AD3, 
    input  logic                         WE3,  
    input  logic [DATA_WIDTH-1:0]        WD3,  
    output logic [DATA_WIDTH-1:0]        RD1,  
    output logic [DATA_WIDTH-1:0]        RD2,  
    output logic [DATA_WIDTH-1:0]        a0    
);

    localparam NUM_REGS = (1 << ADDRESS_WIDTH);

    // register file: NUM_REGS entries of DATA_WIDTH bits
    logic [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];

    always_ff @(posedge clk) begin
        if (WE3) begin
            regs[AD3] <= WD3;
        end
    end


    assign RD1 = regs[AD1];
    assign RD2 = regs[AD2];

    assign a0 = regs[10];
endmodule
