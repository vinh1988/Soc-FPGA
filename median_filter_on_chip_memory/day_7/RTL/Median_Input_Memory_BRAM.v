`timescale 1ns/1ps

// ============================================================================
// Module: Median_Input_Memory_BRAM
// Description: Memory storing 9 pixel inputs (3x3 window) using Xilinx BRAM inference.
//              Outputs pixel values DIRECTLY to the Median_Datapath.
// ============================================================================
module Median_Input_Memory_BRAM (
    input  wire        CLK,
    input  wire        RST,

    input  wire        clear_valid_i,
    input  wire [31:0] w_data_i,
    input  wire [3:0]  wr_pixel_sel_i, // Select pixel index 0..8
    input  wire        wr_en_i,

    output wire [7:0]  p0_o, p1_o, p2_o,
    output wire [7:0]  p3_o, p4_o, p5_o,
    output wire [7:0]  p6_o, p7_o, p8_o,
    output wire        all_inputs_valid_o
);

    wire [7:0] p_out [0:8];
    reg  [8:0] valid_r;
    genvar k;

    generate
        for (k = 0; k < 9; k = k + 1) begin : gen_bram_pixel
            wire wr_en_k = wr_en_i && (wr_pixel_sel_i == k);
            xilinx_single_port_bram #(
                .DATA_WIDTH(8),
                .ADDR_WIDTH(1),
                .RAM_DEPTH(2)
            ) bram_inst (
                .clk (CLK),
                .we  (wr_en_k),
                .addr(1'b0),
                .din (w_data_i[7:0]),
                .dout(p_out[k])
            );
        end
    endgenerate

    integer i;
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            valid_r <= 9'b0;
        end else begin
            if (clear_valid_i) begin
                valid_r <= 9'b0;
            end else if (wr_en_i && wr_pixel_sel_i < 4'd9) begin
                valid_r[wr_pixel_sel_i] <= 1'b1;
            end
        end
    end

    // Direct routing to Datapath
    assign p0_o = p_out[0]; assign p1_o = p_out[1]; assign p2_o = p_out[2];
    assign p3_o = p_out[3]; assign p4_o = p_out[4]; assign p5_o = p_out[5];
    assign p6_o = p_out[6]; assign p7_o = p_out[7]; assign p8_o = p_out[8];

    assign all_inputs_valid_o = &valid_r;

endmodule
