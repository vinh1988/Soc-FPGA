`timescale 1ns/1ps

// ============================================================================
// Module: Median_Filter_Core_Direct_BRAM
// Description: Top-level 3x3 Median Filter Hardware IP Core.
//              Integrates Xilinx BRAM memory, direct datapath routing,
//              and 9-element median sorting engine.
// ============================================================================
module Median_Filter_Core_Direct_BRAM #(
    parameter W_ADDR_BITS = 4,
    parameter R_ADDR_BITS = 1
)(
    input  wire                   CLK,
    input  wire                   RST,

    // Write Channel
    input  wire                   w_addr_valid_i,
    input  wire [31:0]            w_data_i,
    input  wire [W_ADDR_BITS-1:0] w_addr_i,

    // Read Channel
    input  wire                   r_addr_valid_i,
    input  wire [R_ADDR_BITS-1:0] r_addr_i,
    output wire [31:0]            r_data_o
);

    wire [31:0] input_mem_w_data_w;
    wire [3:0]  wr_pixel_sel_w;
    wire        wr_en_w;

    wire [7:0]  p0_w, p1_w, p2_w, p3_w, p4_w, p5_w, p6_w, p7_w, p8_w;
    wire        input_mem_all_valid_w;

    wire        arbiter_load_w, arbiter_start_w, arbiter_stop_w, all_inputs_valid_w;
    wire        datapath_start_w, clear_input_valid_w, write_output_w, READ_ready_w;

    wire [7:0]  datapath_median_w;
    wire        datapath_done_w;
    wire [7:0]  output_mem_median_in_w;
    wire        output_mem_read_enable_w;
    wire [31:0] output_mem_r_data_w;

    // Arbiter Module
    Median_Arbiter_Direct #(
        .W_ADDR_BITS(W_ADDR_BITS),
        .R_ADDR_BITS(R_ADDR_BITS)
    ) u_Arbiter (
        .CLK                      (CLK),
        .RST                      (RST),
        .w_addr_valid_i           (w_addr_valid_i),
        .w_data_i                 (w_data_i),
        .w_addr_i                 (w_addr_i),
        .r_addr_valid_i           (r_addr_valid_i),
        .r_addr_i                 (r_addr_i),
        .r_data_o                 (r_data_o),
        .input_mem_w_data_o       (input_mem_w_data_w),
        .wr_pixel_sel_o           (wr_pixel_sel_w),
        .wr_en_o                  (wr_en_w),
        .input_mem_all_valid_i    (input_mem_all_valid_w),
        .all_inputs_valid_o       (all_inputs_valid_w),
        .arbiter_load_o           (arbiter_load_w),
        .arbiter_start_o          (arbiter_start_w),
        .arbiter_stop_o           (arbiter_stop_w),
        .READ_ready_i             (READ_ready_w),
        .datapath_median_i        (datapath_median_w),
        .output_mem_median_o      (output_mem_median_in_w),
        .output_mem_read_enable_o (output_mem_read_enable_w),
        .output_mem_r_data_i      (output_mem_r_data_w)
    );

    // Input BRAM Memory (Direct connections to Datapath)
    Median_Input_Memory_BRAM u_Input_Memory (
        .CLK                (CLK),
        .RST                (RST),
        .clear_valid_i      (clear_input_valid_w),
        .w_data_i           (input_mem_w_data_w),
        .wr_pixel_sel_i     (wr_pixel_sel_w),
        .wr_en_i            (wr_en_w),
        .p0_o                (p0_w),
        .p1_o                (p1_w),
        .p2_o                (p2_w),
        .p3_o                (p3_w),
        .p4_o                (p4_w),
        .p5_o                (p5_w),
        .p6_o                (p6_w),
        .p7_o                (p7_w),
        .p8_o                (p8_w),
        .all_inputs_valid_o (input_mem_all_valid_w)
    );

    // FSM Control Unit
    Median_FSM_CTRL u_FSM_CTRL (
        .CLK                 (CLK),
        .RST                 (RST),
        .arbiter_load_i      (arbiter_load_w),
        .arbiter_start_i     (arbiter_start_w),
        .arbiter_stop_i      (arbiter_stop_w),
        .all_inputs_valid_i  (all_inputs_valid_w),
        .datapath_done_i     (datapath_done_w),
        .datapath_start_o    (datapath_start_w),
        .clear_input_valid_o (clear_input_valid_w),
        .write_output_o      (write_output_w),
        .READ_ready_o        (READ_ready_w)
    );

    // Median Filter Datapath (Sorting Unit)
    Median_Datapath u_Datapath (
        .CLK      (CLK),
        .RST      (RST),
        .p0_i     (p0_w), .p1_i (p1_w), .p2_i (p2_w),
        .p3_i     (p3_w), .p4_i (p4_w), .p5_i (p5_w),
        .p6_i     (p6_w), .p7_i (p7_w), .p8_i (p8_w),
        .start_i  (datapath_start_w),
        .median_o (datapath_median_w),
        .done_o   (datapath_done_w)
    );

    // Output BRAM Memory
    Median_Output_Memory_BRAM u_Output_Memory (
        .CLK            (CLK),
        .RST            (RST),
        .write_enable_i (write_output_w),
        .median_i       (output_mem_median_in_w),
        .median_o       (output_mem_r_data_w)
    );

endmodule
