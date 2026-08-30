`timescale 1ns/1ps

module tb_H_Function_Core;

    // Parameters
    parameter W_ADDR_BITS = 4;
    parameter R_ADDR_BITS = 1;
    parameter CLK_PERIOD  = 10; // 100MHz clock

    // Testbench signals
    reg                   CLK;
    reg                   RST;

    reg                   w_addr_valid_i;
    reg [31:0]            w_data_i;
    reg [W_ADDR_BITS-1:0] w_addr_i;

    reg                   r_addr_valid_i;
    reg [R_ADDR_BITS-1:0] r_addr_i;
    wire [31:0]            r_data_o;

    // Memory array to hold loaded hex input data
    // noisy_image.hex contains 16384 (128x128) hex bytes
    reg [7:0] noisy_mem [0:16383];
    reg [7:0] expected_mem [0:16383];

    integer i;
    integer mismatch_count;
    integer total_tests;

    // DUT Instance using Direct BRAM Architecture
    H_Function_Core_Direct_BRAM #(
        .W_ADDR_BITS(W_ADDR_BITS),
        .R_ADDR_BITS(R_ADDR_BITS)
    ) dut (
        .CLK            (CLK),
        .RST            (RST),
        .w_addr_valid_i (w_addr_valid_i),
        .w_data_i       (w_data_i),
        .w_addr_i       (w_addr_i),
        .r_addr_valid_i (r_addr_valid_i),
        .r_addr_i       (r_addr_i),
        .r_data_o       (r_data_o)
    );

    // Clock Generation
    initial begin
        CLK = 1'b0;
        forever #(CLK_PERIOD / 2) CLK = ~CLK;
    end

    // Address map definition matching H_Arbiter
    localparam A_ADDR     = 4'h0;
    localparam B_ADDR     = 4'h1;
    localparam C_ADDR     = 4'h2;
    localparam D_ADDR     = 4'h3;
    localparam E_ADDR     = 4'h4;
    localparam F_ADDR     = 4'h5;
    localparam LOAD_ADDR  = 4'h6;
    localparam START_ADDR = 4'h7;
    localparam STOP_ADDR  = 4'h8;

    localparam H_R_ADDR     = 1'b0;
    localparam READY_R_ADDR = 1'b1;

    // Helper Task: Write to IP Core Register
    task write_reg(input [W_ADDR_BITS-1:0] addr, input [31:0] data);
        begin
            @(posedge CLK);
            w_addr_valid_i <= 1'b1;
            w_addr_i       <= addr;
            w_data_i       <= data;
            @(posedge CLK);
            w_addr_valid_i <= 1'b0;
            w_addr_i       <= 'b0;
            w_data_i       <= 'b0;
        end
    endtask

    // Helper Task: Read from IP Core Register
    task read_reg(input [R_ADDR_BITS-1:0] addr, output [31:0] data);
        begin
            @(posedge CLK);
            r_addr_valid_i <= 1'b1;
            r_addr_i       <= addr;
            @(posedge CLK);
            r_addr_valid_i <= 1'b0;
            @(posedge CLK); // Registered output delay cycle
            data = r_data_o;
        end
    endtask

    // Expected software/golden formula calculation for H_Function Datapath:
    // sum = a + b + c; xor = sum ^ d; sub = xor - e; h = sub | f;
    function [31:0] calc_expected_h(input [31:0] a, b, c, d, e, f);
        reg [31:0] sum, xor_val, sub;
        begin
            sum     = a + b + c;
            xor_val = sum ^ d;
            sub     = xor_val - e;
            calc_expected_h = sub | f;
        end
    endfunction

    initial begin
        // Initialize signals
        mismatch_count = 0;
        total_tests    = 0;
        w_addr_valid_i = 1'b0;
        w_data_i       = 32'b0;
        w_addr_i       = 'b0;
        r_addr_valid_i = 1'b0;
        r_addr_i       = 'b0;
        RST            = 1'b0;

        $display("=================================================");
        $display("  H_Function_Acceleration IP Verification TB");
        $display("=================================================");

        // Load input and expected data from .hex files
        $readmemh("/home/vinh/Documents/code/Soc-FPGA/Day_6/Modeling/data/noisy_image.hex", noisy_mem);
        $readmemh("/home/vinh/Documents/code/Soc-FPGA/Day_6/Modeling/data/denoised_image.hex", expected_mem);

        // Reset DUT
        #(CLK_PERIOD * 2);
        RST = 1'b1;
        #(CLK_PERIOD * 2);

        // Run verification test vectors loaded from .hex data
        // Each test uses 6 hex pixel samples (A..F) from noisy_mem
        for (i = 0; i < 100; i = i + 1) begin
            reg [31:0] val_a, val_b, val_c, val_d, val_e, val_f;
            reg [31:0] actual_h, expected_h;
            reg [31:0] read_status;

            val_a = {24'b0, noisy_mem[i*6 + 0]};
            val_b = {24'b0, noisy_mem[i*6 + 1]};
            val_c = {24'b0, noisy_mem[i*6 + 2]};
            val_d = {24'b0, noisy_mem[i*6 + 3]};
            val_e = {24'b0, noisy_mem[i*6 + 4]};
            val_f = {24'b0, noisy_mem[i*6 + 5]};

            expected_h = calc_expected_h(val_a, val_b, val_c, val_d, val_e, val_f);

            // 1. Issue LOAD command
            write_reg(LOAD_ADDR, 32'h0000_0001);

            // 2. Load inputs A to F into Input BRAM
            write_reg(A_ADDR, val_a);
            write_reg(B_ADDR, val_b);
            write_reg(C_ADDR, val_c);
            write_reg(D_ADDR, val_d);
            write_reg(E_ADDR, val_e);
            write_reg(F_ADDR, val_f);

            // 3. Issue START command
            write_reg(START_ADDR, 32'h0000_0001);

            // 4. Poll for READ_ready status
            read_status = 0;
            while (read_status[0] == 1'b0) begin
                read_reg(READY_R_ADDR, read_status);
            end

            // 5. Read computed result H
            read_reg(H_R_ADDR, actual_h);

            // 6. Issue STOP command to return FSM to IDLE
            write_reg(STOP_ADDR, 32'h0000_0001);

            // Compare result
            total_tests = total_tests + 1;
            if (actual_h !== expected_h) begin
                $display("[MISMATCH] Test #%0d | Index: %0d", total_tests, i);
                $display("           Inputs  : A=0x%08X, B=0x%08X, C=0x%08X, D=0x%08X, E=0x%08X, F=0x%08X",
                         val_a, val_b, val_c, val_d, val_e, val_f);
                $display("           Expected: 0x%08X | Actual: 0x%08X", expected_h, actual_h);
                mismatch_count = mismatch_count + 1;
            end
        end

        // Final Report
        $display("=================================================");
        $display("               SIMULATION REPORT                 ");
        $display("=================================================");
        $display(" Total Tests Run : %0d", total_tests);
        $display(" Mismatches      : %0d", mismatch_count);

        if (mismatch_count == 0) begin
            $display(" RESULT: PASS");
        end else begin
            $display(" RESULT: FAIL");
        end
        $display("=================================================");

        $finish;
    end

endmodule
