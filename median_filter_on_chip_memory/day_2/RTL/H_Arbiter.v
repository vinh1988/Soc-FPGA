`timescale 1ns/1ps

module H_Arbiter #(
    parameter W_ADDR_BITS = 4,
    parameter R_ADDR_BITS = 1
)(
    input  wire                   CLK,
    input  wire                   RST,

    // Core write channel
    input  wire                   w_addr_valid_i,
    input  wire [31:0]            w_data_i,
    input  wire [W_ADDR_BITS-1:0] w_addr_i,

    // Core read channel
    input  wire                   r_addr_valid_i,
    input  wire [R_ADDR_BITS-1:0] r_addr_i,
    output reg  [31:0]            r_data_o,

    // Toward H_Input_Memory
    output wire [31:0]            input_mem_w_data_o,
    output wire                   wr_a_o,
    output wire                   wr_b_o,
    output wire                   wr_c_o,
    output wire                   wr_d_o,
    output wire                   wr_e_o,
    output wire                   wr_f_o,

    // From H_Input_Memory
    input  wire [31:0]            input_mem_a_i,
    input  wire [31:0]            input_mem_b_i,
    input  wire [31:0]            input_mem_c_i,
    input  wire [31:0]            input_mem_d_i,
    input  wire [31:0]            input_mem_e_i,
    input  wire [31:0]            input_mem_f_i,
    input  wire                   input_mem_all_valid_i,

    // Toward H_Datapath
    output wire [31:0]            datapath_a_o,
    output wire [31:0]            datapath_b_o,
    output wire [31:0]            datapath_c_o,
    output wire [31:0]            datapath_d_o,
    output wire [31:0]            datapath_e_o,
    output wire [31:0]            datapath_f_o,
    output wire                   all_inputs_valid_o,

    // Toward H_FSM_CTRL
    output wire                   arbiter_load_o,
    output wire                   arbiter_start_o,
    output wire                   arbiter_stop_o,

    // From H_FSM_CTRL
    input  wire                   READ_ready_i,

    // From H_Datapath / toward H_Output_Memory
    input  wire [31:0]            datapath_h_i,
    output wire [31:0]            output_mem_h_o,
    output wire                   output_mem_read_enable_o,

    // From H_Output_Memory
    input  wire [31:0]            output_mem_r_data_i
);

    // ================================================================
    // Write address map
    // ================================================================
    localparam [W_ADDR_BITS-1:0] A_BASE_ADDR     = 4'h0;
    localparam [W_ADDR_BITS-1:0] B_BASE_ADDR     = 4'h1;
    localparam [W_ADDR_BITS-1:0] C_BASE_ADDR     = 4'h2;
    localparam [W_ADDR_BITS-1:0] D_BASE_ADDR     = 4'h3;
    localparam [W_ADDR_BITS-1:0] E_BASE_ADDR     = 4'h4;
    localparam [W_ADDR_BITS-1:0] F_BASE_ADDR     = 4'h5;

    // Controller command registers
    localparam [W_ADDR_BITS-1:0] LOAD_BASE_ADDR  = 4'h6;
    localparam [W_ADDR_BITS-1:0] START_BASE_ADDR = 4'h7;
    localparam [W_ADDR_BITS-1:0] STOP_BASE_ADDR  = 4'h8;

    // ================================================================
    // Read address map
    // ================================================================
    localparam [R_ADDR_BITS-1:0] H_BASE_ADDR          = 1'b0;
    localparam [R_ADDR_BITS-1:0] READ_READY_BASE_ADDR = 1'b1;

    // ================================================================
    // Read pipeline registers
    // ================================================================
    reg                          r_addr_valid_r;
    reg [R_ADDR_BITS-1:0]        r_addr_r;

    // ================================================================
    // Write arbitration / address decode
    // ================================================================
    assign input_mem_w_data_o = w_data_i;

    assign wr_a_o = w_addr_valid_i &&
                    (w_addr_i == A_BASE_ADDR);

    assign wr_b_o = w_addr_valid_i &&
                    (w_addr_i == B_BASE_ADDR);

    assign wr_c_o = w_addr_valid_i &&
                    (w_addr_i == C_BASE_ADDR);

    assign wr_d_o = w_addr_valid_i &&
                    (w_addr_i == D_BASE_ADDR);

    assign wr_e_o = w_addr_valid_i &&
                    (w_addr_i == E_BASE_ADDR);

    assign wr_f_o = w_addr_valid_i &&
                    (w_addr_i == F_BASE_ADDR);

    // ================================================================
    // Controller command decode
    // ================================================================
    assign arbiter_load_o =
                    w_addr_valid_i &&
                    (w_addr_i == LOAD_BASE_ADDR) &&
                    w_data_i[0];

    assign arbiter_start_o =
                    w_addr_valid_i &&
                    (w_addr_i == START_BASE_ADDR) &&
                    w_data_i[0];

    assign arbiter_stop_o =
                    w_addr_valid_i &&
                    (w_addr_i == STOP_BASE_ADDR) &&
                    w_data_i[0];

    // ================================================================
    // Input Memory -> Arbiter -> Datapath
    // ================================================================
    assign datapath_a_o = input_mem_a_i;
    assign datapath_b_o = input_mem_b_i;
    assign datapath_c_o = input_mem_c_i;
    assign datapath_d_o = input_mem_d_i;
    assign datapath_e_o = input_mem_e_i;
    assign datapath_f_o = input_mem_f_i;

    assign all_inputs_valid_o = input_mem_all_valid_i;

    // ================================================================
    // Datapath -> Arbiter -> Output Memory
    // ================================================================
    assign output_mem_h_o = datapath_h_i;

    // ================================================================
    // Output Memory read request
    //
    // Request is generated in cycle N directly from Core read channel.
    // Data is returned to Core through r_data_o in cycle N+1.
    // ================================================================
    assign output_mem_read_enable_o =
                    r_addr_valid_i &&
                    (r_addr_i == H_BASE_ADDR);

    // ================================================================
    // Read request pipeline
    //
    // Cycle N:
    //     r_addr_valid_i = 1
    //     r_addr_i       = requested address
    //
    // Cycle N+1:
    //     r_addr_valid_r = 1
    //     r_addr_r       = requested address
    //     r_data_o       = requested data
    // ================================================================
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            r_addr_valid_r <= 1'b0;
            r_addr_r       <= {R_ADDR_BITS{1'b0}};
        end
        else begin
            r_addr_valid_r <= r_addr_valid_i;
            r_addr_r       <= r_addr_i;
        end
    end

    // ================================================================
    // Registered read data output
    // ================================================================
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            r_data_o <= 32'b0;
        end
        else begin
            if (r_addr_valid_r) begin
                case (r_addr_r)

                    H_BASE_ADDR: begin
                        r_data_o <= output_mem_r_data_i;
                    end

                    READ_READY_BASE_ADDR: begin
                        r_data_o <= {31'b0, READ_ready_i};
                    end

                    default: begin
                        r_data_o <= 32'b0;
                    end

                endcase
            end
            else begin
                r_data_o <= 32'b0;
            end
        end
    end

endmodule