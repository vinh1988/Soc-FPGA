`timescale 1ns/1ps

module H_Output_Memory (
    input  wire        CLK,
    input  wire        RST,
    input  wire        write_enable_i,
    input  wire [31:0] h_i,
    output wire [31:0] h_o
);

    reg [31:0] h_r;

    always @(posedge CLK or negedge RST) begin
        if (!RST)
            h_r <= 32'b0;
        else if (write_enable_i)
            h_r <= h_i;
    end

    // Output memory never drives the Core directly.
    // Its data always returns to H_Arbiter.
    assign h_o = h_r;

endmodule
