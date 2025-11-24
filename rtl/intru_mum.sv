module rom#(    
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 8,
)(
    input logic  [ADDR_WIDTH-1:0] addr_i,
    output logic [DATA_WIDTH-1:0] data_o,
);

logic [DATA_WIDTH-1:0] rom_mem [32'hBFC00FFF : 32'hBFC00000];

initial begin
    $readmemh("rom.mem", rom_mem); // Load ROM contents from external file yet to be defined
end

always_comb begin
    data_o = {rom_mem[(addr_i+3)- 32'hBFC00000], rom_mem[(addr_i+2)- 32'hBFC00000], rom_mem[(addr_i+1)- 32'hBFC00000], rom_mem[(addr_i)- 32'hBFC00000]};
end

endmodule