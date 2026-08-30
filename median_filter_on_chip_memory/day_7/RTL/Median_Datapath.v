`timescale 1ns/1ps

// ============================================================================
// Module: Median_Datapath
// Description: Datapath for 3x3 Median Filter using a 9-element sorting network.
//              Sorting network takes 9 8-bit inputs and outputs the median (middle element).
// ============================================================================
module Median_Datapath (
    input  wire       CLK,
    input  wire       RST,

    input  wire [7:0] p0_i, p1_i, p2_i,
    input  wire [7:0] p3_i, p4_i, p5_i,
    input  wire [7:0] p6_i, p7_i, p8_i,

    input  wire       start_i,

    output wire [7:0] median_o,
    output wire       done_o
);

    reg [7:0] p [0:8];
    reg [2:0] state_r;
    reg       done_r;

    localparam IDLE = 3'd0;
    localparam SORT = 3'd1;
    localparam DONE = 3'd2;

    reg [3:0] i, j;
    reg [7:0] temp;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            state_r  <= IDLE;
            done_r   <= 1'b0;
            p[0] <= 8'd0; p[1] <= 8'd0; p[2] <= 8'd0;
            p[3] <= 8'd0; p[4] <= 8'd0; p[5] <= 8'd0;
            p[6] <= 8'd0; p[7] <= 8'd0; p[8] <= 8'd0;
        end else begin
            case (state_r)
                IDLE: begin
                    done_r <= 1'b0;
                    if (start_i) begin
                        p[0] <= p0_i; p[1] <= p1_i; p[2] <= p2_i;
                        p[3] <= p3_i; p[4] <= p4_i; p[5] <= p5_i;
                        p[6] <= p6_i; p[7] <= p7_i; p[8] <= p8_i;
                        state_r <= SORT;
                    end
                end

                SORT: begin
                    // Sorting network logic on 9 elements (bubble sort pass across 9 elements)
                    // Pipeline or multi-cycle sorting
                    for (i = 0; i < 8; i = i + 1) begin
                        for (j = 0; j < 8 - i; j = j + 1) begin
                            if (p[j] > p[j+1]) begin
                                temp = p[j];
                                p[j] = p[j+1];
                                p[j+1] = temp;
                            end
                        end
                    end
                    done_r  <= 1'b1;
                    state_r <= DONE;
                end

                DONE: begin
                    done_r  <= 1'b0;
                    state_r <= IDLE;
                end

                default: state_r <= IDLE;
            endcase
        end
    end

    assign median_o = p[4]; // Middle element after sorting is the median
    assign done_o   = done_r;

endmodule
