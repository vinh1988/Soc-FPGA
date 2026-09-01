`timescale 1ns/1ps

// ============================================================================
// Module: xilinx_single_port_bram
// Description: Inferable Single-Port Block RAM (BRAM) following Xilinx HDL synthesis guidelines.
// ============================================================================
module xilinx_single_port_bram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter RAM_DEPTH  = (1 << ADDR_WIDTH)
)(
    input  wire                  clk,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

    integer k;
    initial begin
        for (k = 0; k < RAM_DEPTH; k = k + 1) begin
            ram[k] = {DATA_WIDTH{1'b0}};
        end
        dout = {DATA_WIDTH{1'b0}};
    end

    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
        dout <= ram[addr];
    end

endmodule
