`timescale 1ns/1ps

// ============================================================================
// Module: Median_Arbiter_Direct
// Description: Arbiter module decoding memory writes for 9 pixels (P0-P8)
//              and control commands (LOAD, START, STOP).
// ============================================================================
module Median_Arbiter_Direct #(
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
    output reg  [31:0]            r_data_o,

    // Input memory write interface
    output wire [31:0]            input_mem_w_data_o,
    output wire [3:0]             wr_pixel_sel_o,
    output wire                   wr_en_o,
    input  wire                   input_mem_all_valid_i,

    // FSM Control
    output wire                   all_inputs_valid_o,
    output wire                   arbiter_load_o,
    output wire                   arbiter_start_o,
    output wire                   arbiter_stop_o,
    input  wire                   READ_ready_i,

    // Output Memory Interface
    input  wire [7:0]             datapath_median_i,
    output wire [7:0]             output_mem_median_o,
    output wire                   output_mem_read_enable_o,
    input  wire [31:0]            output_mem_r_data_i
);

    localparam LOAD_BASE_ADDR  = 4'h9;
    localparam START_BASE_ADDR = 4'hA;
    localparam STOP_BASE_ADDR  = 4'hB;

    localparam MEDIAN_R_ADDR   = 1'b0;
    localparam READY_R_ADDR    = 1'b1;

    reg                   r_addr_valid_r;
    reg [R_ADDR_BITS-1:0] r_addr_r;

    assign input_mem_w_data_o = w_data_i;
    assign wr_pixel_sel_o     = w_addr_i[3:0];
    assign wr_en_o            = w_addr_valid_i && (w_addr_i < 4'h9);

    assign arbiter_load_o  = w_addr_valid_i && (w_addr_i == LOAD_BASE_ADDR) && w_data_i[0];
    assign arbiter_start_o = w_addr_valid_i && (w_addr_i == START_BASE_ADDR) && w_data_i[0];
    assign arbiter_stop_o  = w_addr_valid_i && (w_addr_i == STOP_BASE_ADDR) && w_data_i[0];

    assign all_inputs_valid_o = input_mem_all_valid_i;
    assign output_mem_median_o = datapath_median_i;

    assign output_mem_read_enable_o = r_addr_valid_i && (r_addr_i == MEDIAN_R_ADDR);

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            r_addr_valid_r <= 1'b0;
            r_addr_r       <= {R_ADDR_BITS{1'b0}};
        end else begin
            r_addr_valid_r <= r_addr_valid_i;
            r_addr_r       <= r_addr_i;
        end
    end

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            r_data_o <= 32'b0;
        end else begin
            if (r_addr_valid_r) begin
                case (r_addr_r)
                    MEDIAN_R_ADDR: r_data_o <= output_mem_r_data_i;
                    READY_R_ADDR:  r_data_o <= {31'b0, READ_ready_i};
                    default:       r_data_o <= 32'b0;
                endcase
            end else begin
                r_data_o <= 32'b0;
            end
        end
    end

endmodule
