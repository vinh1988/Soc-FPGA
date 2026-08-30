`timescale 1ns/1ps

module H_Function_Core #(
    parameter W_ADDR_BITS = 4,
    parameter R_ADDR_BITS = 1
)(
    input  wire                   CLK,
    input  wire                   RST,

    // Write channel -- Core external interface terminates at H_Arbiter
    input  wire                   w_addr_valid_i,
    input  wire [31:0]            w_data_i,
    input  wire [W_ADDR_BITS-1:0] w_addr_i,

    // Read channel -- Core external interface terminates at H_Arbiter
    input  wire                   r_addr_valid_i,
    input  wire [R_ADDR_BITS-1:0] r_addr_i,
    output wire [31:0]            r_data_o
);

    // Arbiter <-> Input Memory
    wire [31:0] input_mem_w_data_w;
    wire        wr_a_w;
    wire        wr_b_w;
    wire        wr_c_w;
    wire        wr_d_w;
    wire        wr_e_w;
    wire        wr_f_w;

    wire [31:0] input_mem_a_w;
    wire [31:0] input_mem_b_w;
    wire [31:0] input_mem_c_w;
    wire [31:0] input_mem_d_w;
    wire [31:0] input_mem_e_w;
    wire [31:0] input_mem_f_w;
    wire        input_mem_all_valid_w;

    // Arbiter -> Datapath / FSM
    wire [31:0] datapath_a_w;
    wire [31:0] datapath_b_w;
    wire [31:0] datapath_c_w;
    wire [31:0] datapath_d_w;
    wire [31:0] datapath_e_w;
    wire [31:0] datapath_f_w;
    wire        all_inputs_valid_w;

    // Arbiter -> FSM controller command signals
    wire arbiter_load_w;
    wire arbiter_start_w;
    wire arbiter_stop_w;

    // FSM controller signals
    wire datapath_start_w;
    wire clear_input_valid_w;
    wire write_output_w;
    wire READ_ready_w;

    // Datapath -> Arbiter -> Output Memory -> Arbiter
    wire [31:0] datapath_h_w;
    wire        datapath_done_w;
    wire [31:0] output_mem_h_in_w;
    wire        output_mem_read_enable_w;
    wire [31:0] output_mem_r_data_w;

    H_Arbiter #(
        .W_ADDR_BITS(W_ADDR_BITS),
        .R_ADDR_BITS(R_ADDR_BITS)
    ) u_H_Arbiter (
	    .CLK                (CLK),
        .RST                (RST),
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

        .input_mem_a_i            (input_mem_a_w),
        .input_mem_b_i            (input_mem_b_w),
        .input_mem_c_i            (input_mem_c_w),
        .input_mem_d_i            (input_mem_d_w),
        .input_mem_e_i            (input_mem_e_w),
        .input_mem_f_i            (input_mem_f_w),
        .input_mem_all_valid_i    (input_mem_all_valid_w),

        .datapath_a_o             (datapath_a_w),
        .datapath_b_o             (datapath_b_w),
        .datapath_c_o             (datapath_c_w),
        .datapath_d_o             (datapath_d_w),
        .datapath_e_o             (datapath_e_w),
        .datapath_f_o             (datapath_f_w),
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

    H_Input_Memory u_H_Input_Memory (
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
        .a_o                (input_mem_a_w),
        .b_o                (input_mem_b_w),
        .c_o                (input_mem_c_w),
        .d_o                (input_mem_d_w),
        .e_o                (input_mem_e_w),
        .f_o                (input_mem_f_w),
        .all_inputs_valid_o (input_mem_all_valid_w)
    );

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

    H_Datapath u_H_Datapath (
        .CLK     (CLK),
        .RST     (RST),
        .a_i     (datapath_a_w),
        .b_i     (datapath_b_w),
        .c_i     (datapath_c_w),
        .d_i     (datapath_d_w),
        .e_i     (datapath_e_w),
        .f_i     (datapath_f_w),
        .start_i (datapath_start_w),
        .h_o     (datapath_h_w),
        .done_o  (datapath_done_w)
    );

    H_Output_Memory u_H_Output_Memory (
        .CLK            (CLK),
        .RST            (RST),
        .write_enable_i (write_output_w),
        .h_i            (output_mem_h_in_w),
        .h_o            (output_mem_r_data_w)
    );

endmodule
