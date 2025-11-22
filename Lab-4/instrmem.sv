module instrmem #(
    parameter ADDRESS_WIDTH = 5,
    parameter DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0]     A,
    output logic [DATA_WIDTH-1:0]     RD
);

    logic [DATA_WIDTH-1:0] rom_array [2**ADDRESS_WIDTH-1:0];

    initial begin
        $display("Loading rom.");
        $readmemh("instruction.mem", rom_array);
    end;

    assign RD = rom_array[A];

endmodule
