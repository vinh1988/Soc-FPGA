`timescale 1ns/1ps

// ============================================================================
// Module: H_Input_Memory_BRAM
// Description: Input Memory storing variables A, B, C, D, E, F using Xilinx BRAM inference.
//              Directly outputs stored inputs to the Datapath.
// ============================================================================
module H_Input_Memory_BRAM (
    input  wire        CLK,
    input  wire        RST,

    input  wire        clear_valid_i,
    input  wire [31:0] w_data_i,
    input  wire        wr_a_i,
    input  wire        wr_b_i,
    input  wire        wr_c_i,
    input  wire        wr_d_i,
    input  wire        wr_e_i,
    input  wire        wr_f_i,

    output wire [31:0] a_o,
    output wire [31:0] b_o,
    output wire [31:0] c_o,
    output wire [31:0] d_o,
    output wire [31:0] e_o,
    output wire [31:0] f_o,
    output wire        all_inputs_valid_o
);

    // Write Enable calculation
    wire we = wr_a_i | wr_b_i | wr_c_i | wr_d_i | wr_e_i | wr_f_i;

    // Address decoder for BRAM (0=A, 1=B, 2=C, 3=D, 4=E, 5=F)
    reg [2:0] write_addr;
    always @(*) begin
        case (1'b1)
            wr_a_i: write_addr = 3'd0;
            wr_b_i: write_addr = 3'd1;
            wr_c_i: write_addr = 3'd2;
            wr_d_i: write_addr = 3'd3;
            wr_e_i: write_addr = 3'd4;
            wr_f_i: write_addr = 3'd5;
            default: write_addr = 3'd0;
        endcase
    end

    // Xilinx BRAM storage for 6 input words (A to F)
    // To allow concurrent read access of A..F directly into Datapath,
    // we use 6 BRAM registers / slots with synchronous write.
    // Each input slot is backed by a Xilinx single-port BRAM primitive/pattern.

    wire [31:0] bram_a_out, bram_b_out, bram_c_out, bram_d_out, bram_e_out, bram_f_out;

    xilinx_single_port_bram #(.DATA_WIDTH(32), .ADDR_WIDTH(1), .RAM_DEPTH(2)) bram_a (
        .clk(CLK), .we(wr_a_i), .addr(1'b0), .din(w_data_i), .dout(bram_a_out)
    );
    xilinx_single_port_bram #(.DATA_WIDTH(32), .ADDR_WIDTH(1), .RAM_DEPTH(2)) bram_b (
        .clk(CLK), .we(wr_b_i), .addr(1'b0), .din(w_data_i), .dout(bram_b_out)
    );
    xilinx_single_port_bram #(.DATA_WIDTH(32), .ADDR_WIDTH(1), .RAM_DEPTH(2)) bram_c (
        .clk(CLK), .we(wr_c_i), .addr(1'b0), .din(w_data_i), .dout(bram_c_out)
    );
    xilinx_single_port_bram #(.DATA_WIDTH(32), .ADDR_WIDTH(1), .RAM_DEPTH(2)) bram_d (
        .clk(CLK), .we(wr_d_i), .addr(1'b0), .din(w_data_i), .dout(bram_d_out)
    );
    xilinx_single_port_bram #(.DATA_WIDTH(32), .ADDR_WIDTH(1), .RAM_DEPTH(2)) bram_e (
        .clk(CLK), .we(wr_e_i), .addr(1'b0), .din(w_data_i), .dout(bram_e_out)
    );
    xilinx_single_port_bram #(.DATA_WIDTH(32), .ADDR_WIDTH(1), .RAM_DEPTH(2)) bram_f (
        .clk(CLK), .we(wr_f_i), .addr(1'b0), .din(w_data_i), .dout(bram_f_out)
    );

    // Valid tracking flags
    reg valid_a_r, valid_b_r, valid_c_r, valid_d_r, valid_e_r, valid_f_r;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            valid_a_r <= 1'b0;
            valid_b_r <= 1'b0;
            valid_c_r <= 1'b0;
            valid_d_r <= 1'b0;
            valid_e_r <= 1'b0;
            valid_f_r <= 1'b0;
        end else begin
            if (clear_valid_i) begin
                valid_a_r <= 1'b0;
                valid_b_r <= 1'b0;
                valid_c_r <= 1'b0;
                valid_d_r <= 1'b0;
                valid_e_r <= 1'b0;
                valid_f_r <= 1'b0;
            end

            if (wr_a_i) valid_a_r <= 1'b1;
            if (wr_b_i) valid_b_r <= 1'b1;
            if (wr_c_i) valid_c_r <= 1'b1;
            if (wr_d_i) valid_d_r <= 1'b1;
            if (wr_e_i) valid_e_r <= 1'b1;
            if (wr_f_i) valid_f_r <= 1'b1;
        end
    end

    // Data outputs direct to datapath
    assign a_o = bram_a_out;
    assign b_o = bram_b_out;
    assign c_o = bram_c_out;
    assign d_o = bram_d_out;
    assign e_o = bram_e_out;
    assign f_o = bram_f_out;

    assign all_inputs_valid_o = valid_a_r && valid_b_r && valid_c_r &&
                                valid_d_r && valid_e_r && valid_f_r;

endmodule
