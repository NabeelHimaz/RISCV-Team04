module hazardunit (
    input logic [4:0]   Rs1D_i,
    input logic [4:0]   Rs2D_i,
    input logic [4:0]   Rs1E_i,
    input logic [4:0]   Rs2E_i,
    input logic [4:0]   RdE_i,
    input logic         PCSrcE_i,
    input logic         ResultSrcE_i,   // ResultSrcE[0] (1 for Load)
    input logic [4:0]   RdM_i,
    input logic         RegWriteM_i,
    input logic [4:0]   RdW_i,
    input logic         RegWriteW_i,
    input logic [31:0]  Instr_i,        // dummy input to match top.sv connection

    output logic        StallF_o,
    output logic        StallD_o,
    output logic        FlushD_o,
    output logic        FlushE_o,
    output logic [1:0]  ForwardAE_o,
    output logic [1:0]  ForwardBE_o
);

    // Data Hazard Forwarding Logic
    always_comb begin
        // Forward to SrcA
        if ((Rs1E_i == RdM_i) && RegWriteM_i && (Rs1E_i != 0))
            ForwardAE_o = 2'b10;  // Forward from Memory Stage
        else if ((Rs1E_i == RdW_i) && RegWriteW_i && (Rs1E_i != 0))
            ForwardAE_o = 2'b01;  // Forward from Writeback Stage
        else
            ForwardAE_o = 2'b00;

        // Forward to SrcB
        if ((Rs2E_i == RdM_i) && RegWriteM_i && (Rs2E_i != 0))
            ForwardBE_o = 2'b10;
        else if ((Rs2E_i == RdW_i) && RegWriteW_i && (Rs2E_i != 0))
            ForwardBE_o = 2'b01;
        else
            ForwardBE_o = 2'b00;
    end

    // Load-Use Hazard Detection & Control Hazard (Branching)
    logic lwStall;

    always_comb begin
        lwStall = ResultSrcE_i && ((Rs1D_i == RdE_i) || (Rs2D_i == RdE_i));
        // Stall Fetch and Decode stages to hold the instruction
        StallF_o = lwStall;
        StallD_o = lwStall;
        FlushD_o = PCSrcE_i; 
        FlushE_o = lwStall || PCSrcE_i; 
    end

endmodule
