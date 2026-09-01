`timescale 1ns/1ps

module tb_Median_Filter_Core;

    parameter W_ADDR_BITS = 4;
    parameter R_ADDR_BITS = 1;
    parameter CLK_PERIOD  = 10;
    parameter WIDTH       = 128;
    parameter HEIGHT      = 128;

    reg                   CLK;
    reg                   RST;

    reg                   w_addr_valid_i;
    reg [31:0]            w_data_i;
    reg [W_ADDR_BITS-1:0] w_addr_i;

    reg                   r_addr_valid_i;
    reg [R_ADDR_BITS-1:0] r_addr_i;
    wire [31:0]            r_data_o;

    // 128x128 byte memory buffers
    reg [7:0] noisy_mem [0:16383];
    reg [7:0] expected_mem [0:16383];

    integer r, c, kr, kc;
    integer mismatch_count;
    integer total_tests;

    // Instantiate Median Filter Hardware IP Core
    Median_Filter_Core_Direct_BRAM #(
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

    // Write & Read helper tasks
    task write_reg(input [W_ADDR_BITS-1:0] addr, input [31:0] data);
        begin
            @(posedge CLK);
            #1;
            w_addr_valid_i = 1'b1;
            w_addr_i       = addr;
            w_data_i       = data;
            @(posedge CLK);
            #1;
            w_addr_valid_i = 1'b0;
            w_addr_i       = 'b0;
            w_data_i       = 'b0;
        end
    endtask

    task read_reg(input [R_ADDR_BITS-1:0] addr, output [31:0] data);
        begin
            @(posedge CLK);
            #1;
            r_addr_valid_i = 1'b1;
            r_addr_i       = addr;
            @(posedge CLK);
            #1;
            r_addr_valid_i = 1'b0;
            @(posedge CLK);
            #1;
            data = r_data_o;
        end
    endtask

    localparam LOAD_ADDR  = 4'h9;
    localparam START_ADDR = 4'hA;
    localparam STOP_ADDR  = 4'hB;
    localparam MEDIAN_R_ADDR = 1'b0;
    localparam READY_R_ADDR  = 1'b1;

    reg [7:0] win [0:8];
    reg [31:0] actual_median, expected_median;
    reg [31:0] read_status;
    integer idx;

    initial begin
        mismatch_count  = 0;
        total_tests     = 0;
        w_addr_valid_i  = 1'b0;
        w_data_i        = 32'b0;
        w_addr_i        = 'b0;
        r_addr_valid_i  = 1'b0;
        r_addr_i        = 'b0;
        RST             = 1'b0;
        actual_median   = 32'b0;
        expected_median = 32'b0;
        read_status     = 32'b0;
        for (idx = 0; idx < 9; idx = idx + 1) begin
            win[idx] = 8'h00;
        end

        $display("=================================================");
        $display("   3x3 Median Filter Hardware IP Verification TB ");
        $display("=================================================");

        // Load image hex data generated in Day 6
        $readmemh("/home/vinh/Documents/code/Soc-FPGA/median_filter_on_chip_memory/day_6/Modeling/data/noisy_image.hex", noisy_mem);
        $readmemh("/home/vinh/Documents/code/Soc-FPGA/median_filter_on_chip_memory/day_6/Modeling/data/denoised_image.hex", expected_mem);

        #(CLK_PERIOD * 2);
        RST = 1'b1;
        #(CLK_PERIOD * 2);

        // Run verification across internal image pixels (avoiding 1-pixel border for 3x3 window)
        for (r = 1; r < 10; r = r + 1) begin
            for (c = 1; c < 10; c = c + 1) begin
                // Extract 3x3 pixel window centered at (r, c)
                idx = 0;
                for (kr = -1; kr <= 1; kr = kr + 1) begin
                    for (kc = -1; kc <= 1; kc = kc + 1) begin
                        win[idx] = noisy_mem[(r + kr) * WIDTH + (c + kc)];
                        idx = idx + 1;
                    end
                end

                expected_median = {24'b0, expected_mem[r * WIDTH + c]};

                // 1. Issue LOAD
                write_reg(LOAD_ADDR, 32'h0000_0001);

                // 2. Load 9 window pixels into Input BRAM
                for (idx = 0; idx < 9; idx = idx + 1) begin
                    write_reg(idx[W_ADDR_BITS-1:0], {24'b0, win[idx]});
                end

                // 3. Issue START
                write_reg(START_ADDR, 32'h0000_0001);

                // 4. Poll READ_ready
                read_status = 0;
                while (read_status[0] == 1'b0) begin
                    read_reg(READY_R_ADDR, read_status);
                end

                // 5. Read output median pixel
                read_reg(MEDIAN_R_ADDR, actual_median);

                // 6. Issue STOP
                write_reg(STOP_ADDR, 32'h0000_0001);

                total_tests = total_tests + 1;

                if (actual_median !== expected_median) begin
                    $display("[MISMATCH] Pixel Row %0d, Col %0d (Flat Index: %0d)", r, c, r * WIDTH + c);
                    $display("           Expected: 0x%02X | Actual: 0x%02X", expected_median[7:0], actual_median[7:0]);
                    mismatch_count = mismatch_count + 1;
                end
            end
        end

        $display("=================================================");
        $display("               SIMULATION REPORT                 ");
        $display("=================================================");
        $display(" Total Pixels Verified : %0d", total_tests);
        $display(" Mismatches            : %0d", mismatch_count);

        if (mismatch_count == 0) begin
            $display(" RESULT: PASS");
        end else begin
            $display(" RESULT: FAIL");
        end
        $display("=================================================");

        $finish;
    end

endmodule
