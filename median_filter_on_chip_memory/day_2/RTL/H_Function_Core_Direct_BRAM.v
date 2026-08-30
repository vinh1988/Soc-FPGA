`timescale 1ns/1ps

// ============================================================================
// Module: H_Function_Core_Direct_BRAM
// Description: Top-level H_Function Core connecting BRAM memory modules and 
//              routing memory outputs DIRECTLY to the datapath.
// ============================================================================
module H_Function_Core_Direct_BRAM #(
    parameter W_ADDR_BITS = 4,
    parameter R_ADDR_BITS = 1
)(
    input  wire                   CLK,
    input  wire                   RST,

    // Write channel
    input  wire                   w_addr_valid_i,
    input  wire [31:0]            w_data_i,
    input  wire [W_ADDR_BITS-1:0] w_addr_i,

    // Read channel
    input  wire                   r_addr_valid_i,
    input  wire [R_ADDR_BITS-1:0] r_addr_i,
    output wire [31:0]            r_data_o
);

    // Arbiter <-> Input Memory
    wire [31:0] input_mem_w_data_w;
    wire        wr_a_w, wr_b_w, wr_c_w, wr_d_w, wr_e_w, wr_f_w;

    // DIRECT Connection: Input Memory -> Datapath
    wire [31:0] datapath_a_w;
    wire [31:0] datapath_b_w;
    wire [31:0] datapath_c_w;
    wire [31:0] datapath_d_w;
    wire [31:0] datapath_e_w;
    wire [31:0] datapath_f_w;
    wire        input_mem_all_valid_w;

    // Arbiter -> FSM controller command signals
    wire arbiter_load_w;
    wire arbiter_start_w;
    wire arbiter_stop_w;
    wire all_inputs_valid_w;

    // FSM controller signals
    wire datapath_start_w;
    wire clear_input_valid_w;
    wire write_output_w;
    wire READ_ready_w;

    // Datapath -> Output Memory -> Arbiter
    wire [31:0] datapath_h_w;
    wire        datapath_done_w;
    wire [31:0] output_mem_h_in_w;
    wire        output_mem_read_enable_w;
    wire [31:0] output_mem_r_data_w;

    // Direct Arbiter Module
    H_Arbiter_Direct #(
        .W_ADDR_BITS(W_ADDR_BITS),
        .R_ADDR_BITS(R_ADDR_BITS)
    ) u_H_Arbiter (
        .CLK                      (CLK),
        .RST                      (RST),
        .w_addr_valid_i           (w_addr_valid_i),
        .w_data_i                 (w_data_i),
        .w_addr_i                 (w_addr_i),
        .r_addr_valid_i           (r_addr_valid_i),
        .r_addr_i                 (r_addr_i),
        .r_data_o                 (r_data_o),

        .input_mem_w_data_o       (input_mem_w_data_w),
        .wr_a_o                   (wr_a_w),
        .wr_b_o                   (wr_b_w),
        .wr_c_o                   (wr_c_w),
        .wr_d_o                   (wr_d_w),
        .wr_e_o                   (wr_e_w),
        .wr_f_o                   (wr_f_w),

        .input_mem_all_valid_i    (input_mem_all_valid_w),
        .all_inputs_valid_o       (all_inputs_valid_w),

        .arbiter_load_o           (arbiter_load_w),
        .arbiter_start_o          (arbiter_start_w),
        .arbiter_stop_o           (arbiter_stop_w),
        .READ_ready_i             (READ_ready_w),

        .datapath_h_i             (datapath_h_w),
        .output_mem_h_o           (output_mem_h_in_w),
        .output_mem_read_enable_o (output_mem_read_enable_w),
        .output_mem_r_data_i      (output_mem_r_data_w)
    );

    // Input Memory using Xilinx BRAM inference pattern
    H_Input_Memory_BRAM u_H_Input_Memory (
        .CLK                (CLK),
        .RST                (RST),
        .clear_valid_i      (clear_input_valid_w),
        .w_data_i           (input_mem_w_data_w),
        .wr_a_i             (wr_a_w),
        .wr_b_i             (wr_b_w),
        .wr_c_i             (wr_c_w),
        .wr_d_i             (wr_d_w),
        .wr_e_i             (wr_e_w),
        .wr_f_i             (wr_f_w),
        .a_o                (datapath_a_w), // DIRECT to Datapath
        .b_o                (datapath_b_w), // DIRECT to Datapath
        .c_o                (datapath_c_w), // DIRECT to Datapath
        .d_o                (datapath_d_w), // DIRECT to Datapath
        .e_o                (datapath_e_w), // DIRECT to Datapath
        .f_o                (datapath_f_w), // DIRECT to Datapath
        .all_inputs_valid_o (input_mem_all_valid_w)
    );

    // Control FSM
    H_FSM_CTRL u_H_FSM_CTRL (
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

    // Compute Datapath
    H_Datapath u_H_Datapath (
        .CLK     (CLK),
        .RST     (RST),
        .a_i     (datapath_a_w), // Direct input connection
        .b_i     (datapath_b_w), // Direct input connection
        .c_i     (datapath_c_w), // Direct input connection
        .d_i     (datapath_d_w), // Direct input connection
        .e_i     (datapath_e_w), // Direct input connection
        .f_i     (datapath_f_w), // Direct input connection
        .start_i (datapath_start_w),
        .h_o     (datapath_h_w),
        .done_o  (datapath_done_w)
    );

    // Output Memory using Xilinx BRAM inference pattern
    H_Output_Memory_BRAM u_H_Output_Memory (
        .CLK            (CLK),
        .RST            (RST),
        .write_enable_i (write_output_w),
        .h_i            (output_mem_h_in_w),
        .h_o            (output_mem_r_data_w)
    );

endmodule
