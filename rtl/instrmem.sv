module instrmem #(
    parameter ADDRESS_WIDTH = 32,
              DATA_WIDTH = 8,
              OUT_WIDTH = 32
)(
    input logic     [ADDRESS_WIDTH-1:0] addr_i,
    output logic    [OUT_WIDTH-1:0]     instrA_o,
    output logic    [OUT_WIDTH-1:0]     instrB_o
);

logic [DATA_WIDTH-1:0] rom_array [32'h00000FFF:0]; 

initial begin
    $readmemh("program.hex", rom_array); 
end;

    always_comb begin
        instrA_o = {rom_array[addr_i+3], rom_array[addr_i+2], rom_array[addr_i+1], rom_array[addr_i+0]}; 
        instrB_o = {rom_array[addr_i+7], rom_array[addr_i+6], rom_array[addr_i+5], rom_array[addr_i+4]};
    end

endmodule
