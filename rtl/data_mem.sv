module data_mem #(
    parameter 
              ADDR_WIDTH = 32, 
              DATA_WIDTH = 8
) (
    input  logic                     clk_i,
    input  logic                     write_en_i,
    input  logic [ADDR_WIDTH-1:0]    addr_i,
    input  logic [ADDR_WIDTH-1:0]    write_data_i,
    output logic [ADDR_WIDTH-1:0]    read_data_o
);

    logic [DATA_WIDTH-1:0] ram_array [17'h1FFFF : 17'h0]; 

    initial begin 
        $readmemh("data_mem.mem", ram_array, 17'h10000);
        $display ("Loaded data_mem.");
    end;

    assign read_data_o = {ram_array[addr_i[16:0] + 3],ram_array[addr_i[16:0] + 2],ram_array[addr_i[16:0] + 1],ram_array[addr_i[16:0]]};
    
    always_ff @(negedge clk_i) begin
        if (write_en_i) begin
            ram_array[addr_i[16:0]] <= write_data_i[7:0];
            ram_array[addr_i[16:0] + 1] <= write_data_i[15:8];
            ram_array[addr_i[16:0] + 2] <= write_data_i[23:16];
            ram_array[addr_i[16:0] + 3] <= write_data_i[31:24];
        end
    end 

endmodule