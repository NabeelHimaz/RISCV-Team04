module data_mem_top #(
    parameter ADDR_WIDTH = 32
) (
    input  logic                          write_en_i,
    input  logic                          clk_i,
    input  logic                          rst_i,
    input  logic     [1:0]                mem_type_i,
    input  logic                          mem_sign_i,
    input  logic     [ADDR_WIDTH-1:0]     write_data_i,
    input  logic     [ADDR_WIDTH-1:0]     addr_i,
    output logic     [ADDR_WIDTH-1:0]     read_data_o
);

    logic [ADDR_WIDTH-1:0] Write_Data_Formatted; // Data ready for RAM
    logic [ADDR_WIDTH-1:0] Read_Data_Raw;        // Data straight from RAM/Cache
    logic [ADDR_WIDTH-1:0] addr_aligned;
    
    // Wires to connect Cache to Main Memory
    logic                  ram_write_en;
    logic [ADDR_WIDTH-1:0] ram_write_data;
    logic [ADDR_WIDTH-1:0] ram_read_data;
    logic                  cache_hit; // Use for debugging

    assign addr_aligned = {addr_i[31:2], {2'b00}};

    // Format Write Data (Store Byte/Halfword logic)
    data_mem_i data_mem_i (
        .mem_type_i(mem_type_i),
        .addr_i(addr_i),
        .read_data_i(Read_Data_Raw), // Needed for Read-Modify-Write
        .write_data_i(write_data_i),
        .write_data_o(Write_Data_Formatted)
    );

    // THE CACHE
    data_cache cache (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_en_i(write_en_i),
        .addr_i(addr_aligned),
        .write_data_i(Write_Data_Formatted),
        
        // Interaction with Main Memory
        .mem_read_data_i(ram_read_data),
        .mem_write_en_o(ram_write_en),
        .mem_write_data_o(ram_write_data),
        
        // Output to CPU
        .read_data_o(Read_Data_Raw),
        .hit_o(cache_hit)
    );

    // MAIN MEMORY
    data_mem data_mem(
        .write_en_i(ram_write_en),  // Controlled by Cache
        .clk_i(clk_i),
        .addr_i(addr_aligned),
        .write_data_i(ram_write_data), // Controlled by Cache
        .read_data_o(ram_read_data)
    );

    // Format Read Data (Load Byte/Halfword logic)
    data_mem_o data_mem_o(
        .mem_type_i(mem_type_i),
        .mem_sign_i(mem_sign_i),
        .addr_i(addr_i),
        .read_data_i(Read_Data_Raw),
        .read_data_o(read_data_o)
    );

endmodule
