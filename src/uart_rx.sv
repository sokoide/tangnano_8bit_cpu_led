module uart_rx #(
        parameter int CLK_FRE = 50_000_000,  // Clock frequency in Hz (50 MHz)
        parameter int BAUD_RATE = 57600      // Serial baud rate
    ) (
        input logic clk,                     // Clock input
        input logic rst_n,                   // Asynchronous reset input, active low
        input logic rx_data_ready,           // Data receiver module ready
        input logic rx_pin,                  // Serial data input
        output logic [7:0] rx_data,          // Received serial data
        output logic rx_data_valid           // Received serial data is valid
    );

    // Calculate the clock cycle for the baud rate
    localparam int CYCLE = CLK_FRE / BAUD_RATE;

    // State machine states
    typedef enum logic [2:0] {
                S_IDLE      = 3'd0,
                S_START     = 3'd1,  // Start bit
                S_REC_BYTE  = 3'd2,  // Data bits
                S_STOP      = 3'd3,  // Stop bit
                S_DATA      = 3'd4   // Data ready
            } state_t;

    state_t state, next_state;
    logic rx_d0, rx_d1;              // Delayed signals for edge detection
    logic [7:0] rx_bits;             // Temporary storage of received data
    logic [15:0] cycle_cnt;          // Baud counter
    logic [2:0] bit_cnt;             // Bit counter

    // Detect falling edge on rx_pin
    wire rx_negedge = rx_d0 && ~rx_d1;
    // assign rx_negedge = rx_d1 && ~rx_d0;

    // Synchronize and delay rx_pin
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_d0 <= 1'b0;
            rx_d1 <= 1'b0;
        end
        else begin
            rx_d0 <= rx_pin;
            rx_d1 <= rx_d0;
        end
    end

    // State transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always_comb begin
        case (state)
            S_IDLE: begin
                if (rx_negedge)
                    next_state = S_START;
                else
                    next_state = S_IDLE;
            end

            S_START: begin
                if (cycle_cnt == CYCLE - 1)
                    next_state = S_REC_BYTE;
                else
                    next_state = S_START;
            end

            S_REC_BYTE: begin
                if (cycle_cnt == CYCLE - 1 && bit_cnt == 3'd7)
                    next_state = S_STOP;
                else
                    next_state = S_REC_BYTE;
            end

            S_STOP: begin
                if (cycle_cnt == CYCLE / 2 - 1)
                    next_state = S_DATA;
                else
                    next_state = S_STOP;
            end

            S_DATA: begin
                if (rx_data_ready)
                    next_state = S_IDLE;
                else
                    next_state = S_DATA;
            end

            default:
                next_state = S_IDLE;
        endcase
    end

    // rx_data_valid logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_data_valid <= 1'b0;
        else if (state == S_STOP && next_state != state)
            rx_data_valid <= 1'b1;
        else if (state == S_DATA && rx_data_ready)
            rx_data_valid <= 1'b0;
    end

    // rx_data latch logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_data <= 8'd0;
        else if (state == S_STOP && next_state != state)
            rx_data <= rx_bits;
    end

    // Bit counter logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 3'd0;
        else if (state == S_REC_BYTE && cycle_cnt == CYCLE - 1)
            bit_cnt <= bit_cnt + 3'd1;
        else if (state != S_REC_BYTE)
            bit_cnt <= 3'd0;
    end

    // Cycle counter logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_cnt <= 16'd0;
        else if ((state == S_REC_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
            cycle_cnt <= 16'd0;
        else
            cycle_cnt <= cycle_cnt + 16'd1;
    end

    // Receive serial data bits
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_bits <= 8'd0;
        else if (state == S_REC_BYTE && cycle_cnt == CYCLE / 2 - 1)
            rx_bits[bit_cnt] <= rx_pin;
    end

endmodule
