`timescale 1ns/1ps

module H_FSM_CTRL (
    input  wire CLK,
    input  wire RST,

    // Command signals from H_Arbiter
    input  wire arbiter_load_i,
    input  wire arbiter_start_i,
    input  wire arbiter_stop_i,

    // Status from Input Memory / Datapath
    input  wire all_inputs_valid_i,
    input  wire datapath_done_i,

    // Toward Datapath / memories
    output wire datapath_start_o,
    output wire clear_input_valid_o,
    output wire write_output_o,

    // Read-ready status. High only in READ state.
    output wire READ_ready_o
);

    localparam [1:0] IDLE = 2'd0;
    localparam [1:0] LOAD = 2'd1;
    localparam [1:0] EXEC = 2'd2;
    localparam [1:0] READ = 2'd3;

    reg [1:0] state_r;
    reg [1:0] next_state_r;

    reg datapath_start_r;
    reg clear_input_valid_r;
    reg write_output_r;
    reg READ_ready_r;

    always @(posedge CLK or negedge RST) begin
        if (!RST)
            state_r <= IDLE;
        else
            state_r <= next_state_r;
    end

    always @(*) begin
        next_state_r         = state_r;
        datapath_start_r     = 1'b0;
        clear_input_valid_r  = 1'b0;
        write_output_r       = 1'b0;
        READ_ready_r         = 1'b0;

        case (state_r)
            IDLE: begin
                if (arbiter_load_i)
                    next_state_r = LOAD;
            end

            LOAD: begin
                if (arbiter_start_i && all_inputs_valid_i) begin
                    datapath_start_r    = 1'b1;
                    clear_input_valid_r = 1'b1;
                    next_state_r        = EXEC;
                end
            end

            EXEC: begin
                if (datapath_done_i) begin
                    write_output_r = 1'b1;
                    next_state_r   = READ;
                end
            end

            READ: begin
                // Requested behavior:
                // READ_ready_r = 1 only while FSM is in READ state.
                READ_ready_r = 1'b1;

                if (arbiter_stop_i)
                    next_state_r = IDLE;
            end

            default: begin
                next_state_r = IDLE;
            end
        endcase
    end

    assign datapath_start_o    = datapath_start_r;
    assign clear_input_valid_o = clear_input_valid_r;
    assign write_output_o      = write_output_r;
    assign READ_ready_o        = READ_ready_r;

endmodule
