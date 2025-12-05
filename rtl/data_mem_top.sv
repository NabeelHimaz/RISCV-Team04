module data_mem_top #(
    parameter ADDR_WIDTH = 32
              
) (
    input  logic                          write_en_i,
    input  logic                          clk_i,
    input  logic     [1:0]                mem_type_i,
    input  logic                          mem_sign_i,
    input  logic     [ADDR_WIDTH-1:0]     write_data_i,
    input  logic     [ADDR_WIDTH-1:0]     addr_i,
    output logic     [ADDR_WIDTH-1:0]     read_data_o

);

logic [ADDR_WIDTH-1:0] Write_Data;
logic [ADDR_WIDTH-1:0] Read_Data;
logic [ADDR_WIDTH-1:0] addr_i_i;

assign addr_i_i = {{addr_i[31:2]}, {2'b0}};

data_mem_i data_mem_i (
    .mem_type_i(mem_type_i),
    .addr_i(addr_i),
    .read_data_i(Read_Data),
    .write_data_i(write_data_i),
    .write_data_o(Write_Data)
    
);

data_mem data_mem(
    .write_en_i(write_en_i),
    .clk_i(clk_i),
    .addr_i(addr_i_i),
    .write_data_i(Write_Data),
    .read_data_o(Read_Data)
);

data_mem_o data_mem_o(
    .mem_type_i(mem_type_i),
    .mem_sign_i(mem_sign_i),
    .addr_i(addr_i),
    .read_data_i(Read_Data),
    .read_data_o(read_data_o)
    

);

endmodule
