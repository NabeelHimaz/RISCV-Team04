module data_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                    clk_i,
    input  logic                    rst_i,
    input  logic                    write_en_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [DATA_WIDTH-1:0]   write_data_i,
    input  logic [DATA_WIDTH-1:0]   mem_read_data_i, //Data from Main Memory
    
    output logic [DATA_WIDTH-1:0]   read_data_o,     //Data to CPU
    output logic                    mem_write_en_o,  //Pass-through write enable
    output logic [DATA_WIDTH-1:0]   mem_write_data_o, //Pass-through write data
    output logic                    hit_o            //For performance monitoring
);

    //512 Sets, 2 Ways
    localparam NUM_SETS = 512;
    localparam TAG_WIDTH = 21; 

    // Way 0
    logic [DATA_WIDTH-1:0]  data_array_0 [0:NUM_SETS-1];
    logic [TAG_WIDTH-1:0]   tag_array_0  [0:NUM_SETS-1];
    logic                   valid_array_0[0:NUM_SETS-1];

    // Way 1
    logic [DATA_WIDTH-1:0]  data_array_1 [0:NUM_SETS-1];
    logic [TAG_WIDTH-1:0]   tag_array_1  [0:NUM_SETS-1];
    logic                   valid_array_1[0:NUM_SETS-1];

    // LRU Bit (0 = Replace Way 0, 1 = Replace Way 1)
    logic                   lru_array    [0:NUM_SETS-1];

    logic [8:0]             set_index;
    logic [TAG_WIDTH-1:0]   tag;

    assign set_index = addr_i[10:2];
    assign tag       = addr_i[31:11];

    logic hit0, hit1;

    assign hit0 = (valid_array_0[set_index] && (tag_array_0[set_index] == tag));
    assign hit1 = (valid_array_1[set_index] && (tag_array_1[set_index] == tag));
    
    assign hit_o = hit0 || hit1;

    //Read Logic 
    //If Hit: return cache data. If Miss: return Main Memory data (Bypass).
    always_comb begin
        if (hit0)      read_data_o = data_array_0[set_index];
        else if (hit1) read_data_o = data_array_1[set_index];
        else           read_data_o = mem_read_data_i;
    end

    
    assign mem_write_en_o   = write_en_i;
    assign mem_write_data_o = write_data_i;

   
    integer i;
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                // check if it should be <= or =
                valid_array_0[i] = 1'b0;   // Use = not <=
                valid_array_1[i] = 1'b0;   // Use = not <=
                lru_array[i]     = 1'b0;   // Use = not <=
end
        end else begin
            
            // Handle Writes (Write-Through)
            if (write_en_i) begin
                if (hit0) data_array_0[set_index] <= write_data_i;
                if (hit1) data_array_1[set_index] <= write_data_i;
               
            end

            // Handle Read Misses (Allocation)
            if (!write_en_i && !hit_o) begin
                if (lru_array[set_index] == 1'b0) begin
                    valid_array_0[set_index] <= 1'b1;
                    tag_array_0[set_index]   <= tag;
                    data_array_0[set_index]  <= mem_read_data_i;
                    lru_array[set_index]     <= 1'b1; // Next time replace Way 1
                end else begin
                    valid_array_1[set_index] <= 1'b1;
                    tag_array_1[set_index]   <= tag;
                    data_array_1[set_index]  <= mem_read_data_i;
                    lru_array[set_index]     <= 1'b0; // Next time replace Way 0
                end
            end
            
            //Update LRU on Hit
            if (!write_en_i && hit0) lru_array[set_index] <= 1'b1;
            if (!write_en_i && hit1) lru_array[set_index] <= 1'b0;
        end
    end

endmodule
