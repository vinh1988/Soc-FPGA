`timescale 1ns/1ps

module H_Input_Memory (
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

    reg [31:0] a_r;
    reg [31:0] b_r;
    reg [31:0] c_r;
    reg [31:0] d_r;
    reg [31:0] e_r;
    reg [31:0] f_r;

    reg valid_a_r;
    reg valid_b_r;
    reg valid_c_r;
    reg valid_d_r;
    reg valid_e_r;
    reg valid_f_r;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            a_r       <= 32'b0;
            b_r       <= 32'b0;
            c_r       <= 32'b0;
            d_r       <= 32'b0;
            e_r       <= 32'b0;
            f_r       <= 32'b0;
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

            if (wr_a_i) begin
                a_r       <= w_data_i;
                valid_a_r <= 1'b1;
            end
            if (wr_b_i) begin
                b_r       <= w_data_i;
                valid_b_r <= 1'b1;
            end
            if (wr_c_i) begin
                c_r       <= w_data_i;
                valid_c_r <= 1'b1;
            end
            if (wr_d_i) begin
                d_r       <= w_data_i;
                valid_d_r <= 1'b1;
            end
            if (wr_e_i) begin
                e_r       <= w_data_i;
                valid_e_r <= 1'b1;
            end
            if (wr_f_i) begin
                f_r       <= w_data_i;
                valid_f_r <= 1'b1;
            end
        end
    end

    assign a_o = a_r;
    assign b_o = b_r;
    assign c_o = c_r;
    assign d_o = d_r;
    assign e_o = e_r;
    assign f_o = f_r;

    assign all_inputs_valid_o = valid_a_r && valid_b_r && valid_c_r &&
                                valid_d_r && valid_e_r && valid_f_r;

endmodule
