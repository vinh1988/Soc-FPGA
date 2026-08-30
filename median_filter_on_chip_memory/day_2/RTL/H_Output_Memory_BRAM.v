`timescale 1ns/1ps

// ============================================================================
// Module: H_Output_Memory_BRAM
// Description: Output Memory using Xilinx BRAM inference for storing H output.
// ============================================================================
module H_Output_Memory_BRAM (
    input  wire        CLK,
    input  wire        RST,
    input  wire        write_enable_i,
    input  wire [31:0] h_i,
    output wire [31:0] h_o
);

    wire [31:0] bram_out;

    xilinx_single_port_bram #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(1),
        .RAM_DEPTH(2)
    ) u_bram (
        .clk (CLK),
        .we  (write_enable_i),
        .addr(1'b0),
        .din (h_i),
        .dout(bram_out)
    );

    assign h_o = bram_out;

endmodule
