module regfile #( 
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input  logic                     clk,        
    input  logic                     reset,      
    input  logic [1:0]               we_i,
    input  logic [ADDR_WIDTH-1:0]    ad1A_i, 
    input  logic [ADDR_WIDTH-1:0]    ad2A_i, 
    input  logic [ADDR_WIDTH-1:0]    ad3A_i, 
    input  logic [DATA_WIDTH-1:0]    wd3A_i, 
    input  logic [ADDR_WIDTH-1:0]    ad1B_i, 
    input  logic [ADDR_WIDTH-1:0]    ad2B_i, 
    input  logic [ADDR_WIDTH-1:0]    ad3B_i, 
    input  logic [DATA_WIDTH-1:0]    wd3B_i, 
    output logic [DATA_WIDTH-1:0]    rd1A_o, 
    output logic [DATA_WIDTH-1:0]    rd2A_o, 
    output logic [DATA_WIDTH-1:0]    rd1B_o, 
    output logic [DATA_WIDTH-1:0]    rd2B_o, 
    output logic [DATA_WIDTH-1:0]    a0_o
);

    logic [DATA_WIDTH-1:0] register_array [2**ADDR_WIDTH-1:0];

    always_comb begin
        rd1A_o = register_array[ad1A_i];
        rd2A_o = register_array[ad2A_i];
        rd1B_o = register_array[ad1B_i];
        rd2B_o = register_array[ad2B_i];
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
                register_array[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            if (we_i[1] && ad3A_i != 5'b0) 
                register_array[ad3A_i] <= wd3A_i;
            
            if (we_i[0] && ad3B_i != 5'b0) 
                register_array[ad3B_i] <= wd3B_i;
        end
    end

    always_comb begin
        a0_o = register_array[10];
    end

endmodule
