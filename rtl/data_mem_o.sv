module data_mem_o #(
    parameter 
              ADDR_WIDTH = 32 
             

)(
    input  logic    [ADDR_WIDTH-1:0]     read_data_i,
    input  logic    [ADDR_WIDTH-1:0]     addr_i,
    input  logic    [1:0]                mem_type_i,
    input  logic                         mem_sign_i,
    output logic    [ADDR_WIDTH-1:0]     read_data_o
);

logic [1:0] logic_byte_i;

assign logic_byte_i = addr_i[1:0];

always_comb begin
    case (mem_type_i)
        2'b01:
            case (mem_sign_i)
                1'b0: 
                    case(logic_byte_i)
                        2'b00: read_data_o ={{24{read_data_i[7]}},  {read_data_i[7:0]}};
                        2'b01: read_data_o ={{24{read_data_i[15]}}, {read_data_i[15:8]}};
                        2'b10: read_data_o ={{24{read_data_i[23]}}, {read_data_i[23:16]}};
                        2'b11: read_data_o ={{24{read_data_i[31]}}, {read_data_i[31:24]}};
                    endcase
                1'b1:
                    case(logic_byte_i)
                        2'b00: read_data_o ={{24{1'b0}}, {read_data_i[7:0]}};
                        2'b01: read_data_o ={{24{1'b0}}, {read_data_i[15:8]}};
                        2'b10: read_data_o ={{24{1'b0}}, {read_data_i[23:16]}};
                        2'b11: read_data_o ={{24{1'b0}}, {read_data_i[31:24]}};
                    endcase
            endcase
                        
        2'b10:
            case (mem_sign_i)
                1'b0: 
                    read_data_o = logic_byte_i[1] ? {{16{read_data_i[31]}}, read_data_i[31:16]} : {{16{read_data_i[15]}}, read_data_i[15:0]};
                1'b1:
                    read_data_o = logic_byte_i[1] ? {{16{1'b0}}, read_data_i[31:16]} : {{16{1'b0}}, read_data_i[15:0]};
            endcase
    
        
        default: read_data_o = read_data_i;
        endcase 
end

endmodule