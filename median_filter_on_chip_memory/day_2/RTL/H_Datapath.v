`timescale 1ns/1ps

module H_Datapath (
    input  wire        CLK,
    input  wire        RST,

    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [31:0] c_i,
    input  wire [31:0] d_i,
    input  wire [31:0] e_i,
    input  wire [31:0] f_i,

    input  wire        start_i,

    output wire [31:0] h_o,
    output wire        done_o
);

    localparam [2:0] DP_IDLE = 3'd0;
    localparam [2:0] DP_ADD  = 3'd1;
    localparam [2:0] DP_XOR  = 3'd2;
    localparam [2:0] DP_SUB  = 3'd3;
    localparam [2:0] DP_OR   = 3'd4;
    localparam [2:0] DP_DONE = 3'd5;

    reg [2:0] state_r;

    reg [31:0] a_r;
    reg [31:0] b_r;
    reg [31:0] c_r;
    reg [31:0] d_r;
    reg [31:0] e_r;
    reg [31:0] f_r;

    reg [31:0] sum_r;
    reg [31:0] xor_r;
    reg [31:0] sub_r;
    reg [31:0] h_r;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            state_r <= DP_IDLE;
            a_r     <= 32'b0;
            b_r     <= 32'b0;
            c_r     <= 32'b0;
            d_r     <= 32'b0;
            e_r     <= 32'b0;
            f_r     <= 32'b0;
            sum_r   <= 32'b0;
            xor_r   <= 32'b0;
            sub_r   <= 32'b0;
            h_r     <= 32'b0;
        end else begin
            case (state_r)
                DP_IDLE: begin
                    if (start_i) begin
                        a_r     <= a_i;
                        b_r     <= b_i;
                        c_r     <= c_i;
                        d_r     <= d_i;
                        e_r     <= e_i;
                        f_r     <= f_i;
                        state_r <= DP_ADD;
                    end
                end

                DP_ADD: begin
                    sum_r   <= a_r + b_r + c_r;
                    state_r <= DP_XOR;
                end

                DP_XOR: begin
                    xor_r   <= sum_r ^ d_r;
                    state_r <= DP_SUB;
                end

                DP_SUB: begin
                    sub_r   <= xor_r - e_r;
                    state_r <= DP_OR;
                end

                DP_OR: begin
                    h_r     <= sub_r | f_r;
                    state_r <= DP_DONE;
                end

                DP_DONE: begin
                    state_r <= DP_IDLE;
                end

                default: begin
                    state_r <= DP_IDLE;
                end
            endcase
        end
    end

    assign h_o    = h_r;
    assign done_o = (state_r == DP_DONE);

endmodule
