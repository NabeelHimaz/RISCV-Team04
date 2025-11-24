module ram_i #(
    parameter ADDR_WIDTH = 32,
)(
    input logic [1:0]               mem_type_i, // 00: byte, 01: halfword, 10: word
    input logic [ADDR_WIDTH-1:0]    read_data_i,
    input logic [ADDR_WIDTH-1:0]    write_data_i,
    input logic [ADDR_WIDTH-1:0]    addr_i,
    output logic [ADDR_WIDTH-1:0]   write_data_o,
);

logic [1:0] byte_offset;

assign byte_offset = addr_i[1:0];

always_comb begin
    case (mem_type_i)
        2'b01:
            case (byte_offset)
                2'b00: write_data_o ={read_data_i[31:8], write_data_i[7:0]};
                2'b01: write_data_o ={read_data_i[31:16], write_data_i[7:0], read_data_i[7:0]};
                2'b10: write_data_o ={read_data_i[31:24], write_data_i[7:0], read_data_i[15:0]};
                2'b11: write_data_o ={write_data_i[7:0], read_data_i[23:0]};
            endcase

        2'b10:  
            write_data_o = byte_offset[1] ? {write_data_i[15:0], read_data_i[15:0]} : {read_data_i[31:16], write_data_i[15:0]};
        default: write_data_o = write_data_i;

    endcase
end

endmodule