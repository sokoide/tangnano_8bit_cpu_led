module uart_tx #(
        parameter int CLK_FRE = 50_000_000,   // Clock frequency (Hz)
        parameter int BAUD_RATE = 57600       // UART baud rate
    ) (
        input logic clk,                      // Clock input
        input logic rst_n,                    // Asynchronous reset input, active low
        input logic [7:0] tx_data,            // Data to send
        input logic tx_data_valid,            // Data valid signal
        output logic tx_data_ready,           // Ready to send
        output logic tx_pin                   // Serial data output
    );

    // Calculate the clock cycles per baud rate
    localparam int CYCLE = CLK_FRE / BAUD_RATE;

    // State machine states
    typedef enum logic [2:0] {
                S_IDLE = 3'd0,
                S_START = 3'd1,
                S_SEND_BYTE = 3'd2,
                S_STOP = 3'd3
            } state_t;

    state_t state, next_state;
    logic [15:0] cycle_cnt;             // Baud counter
    logic [2:0] bit_cnt;                // Bit counter
    logic [7:0] tx_data_latch;          // Latched data to send
    logic tx_reg;                       // Serial data output register

    assign tx_pin = tx_reg;

    // State transition logic
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
                if (tx_data_valid)
                    next_state = S_START;
                else
                    next_state = S_IDLE;
            end
            S_START: begin
                if (cycle_cnt == CYCLE - 1)
                    next_state = S_SEND_BYTE;
                else
                    next_state = S_START;
            end
            S_SEND_BYTE: begin
                if (cycle_cnt == CYCLE - 1 && bit_cnt == 3'd7)
                    next_state = S_STOP;
                else
                    next_state = S_SEND_BYTE;
            end
            S_STOP: begin
                if (cycle_cnt == CYCLE - 1)
                    next_state = S_IDLE;
                else
                    next_state = S_STOP;
            end
            default:
                next_state = S_IDLE;
        endcase
    end

    // Data ready logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_data_ready <= 1'b0;
        else if (state == S_IDLE) begin
            if (tx_data_valid)
                tx_data_ready <= 1'b0;
            else
                tx_data_ready <= 1'b1;
        end
        else if (state == S_STOP && cycle_cnt == CYCLE - 1)
            tx_data_ready <= 1'b1;
    end

    // Data latch logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_data_latch <= 8'd0;
        else if (state == S_IDLE && tx_data_valid)
            tx_data_latch <= tx_data;
    end

    // Bit counter logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 3'd0;
        else if (state == S_SEND_BYTE) begin
            if (cycle_cnt == CYCLE - 1)
                bit_cnt <= bit_cnt + 3'd1;
        end
        else
            bit_cnt <= 3'd0;
    end

    // Cycle counter logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_cnt <= 16'd0;
        else if ((state == S_SEND_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
            cycle_cnt <= 16'd0;
        else
            cycle_cnt <= cycle_cnt + 16'd1;
    end

    // Serial output logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_reg <= 1'b1;
        else begin
            case (state)
                S_IDLE, S_STOP:
                    tx_reg <= 1'b1;
                S_START:
                    tx_reg <= 1'b0;
                S_SEND_BYTE:
                    tx_reg <= tx_data_latch[bit_cnt];
                default:
                    tx_reg <= 1'b1;
            endcase
        end
    end

endmodule
