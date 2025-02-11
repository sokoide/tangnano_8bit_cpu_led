module uart(
        input  logic       clk,
        input  logic       rst_n,
input  logic       uart_rx,

        output logic       uart_tx
    );

    parameter int CLK_FRE = 50_000_000;
    parameter int UART_FRE = 57600;

    localparam int IDLE = 0;
    localparam int SEND = 1;
    localparam int WAIT = 2;

    logic [7:0] tx_data;
    logic [7:0] tx_str;
    logic tx_data_valid;
    logic [7:0] tx_cnt;
    logic [7:0] rx_data;
    logic [7:0] lower_case_rx_data; // 追加: 小文字変換後のデータ
    logic tx_data_ready;
    logic rx_data_valid;
    logic rx_data_ready;
    logic [31:0] wait_cnt;
    logic [3:0] state;

    assign rx_data_ready = 1'b1;  // ready to receive data

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wait_cnt <= 32'd0;
            tx_data <= 8'd0;
            state <= IDLE;
            tx_cnt <= 8'd0;
            tx_data_valid <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    state <= SEND;
                end

                SEND: begin
                    wait_cnt <= 32'd0;
                    tx_data <= tx_str;

                    if (tx_data_valid && tx_data_ready && tx_cnt < DATA_NUM - 1) begin
                        tx_cnt <= tx_cnt + 8'd1;  // send counter
                    end
                    else if (tx_data_valid && tx_data_ready) begin
                        tx_cnt <= 8'd0;
                        tx_data_valid <= 1'b0;
                        state <= WAIT;
                    end
                    else if (!tx_data_valid) begin
                        tx_data_valid <= 1'b1;
                    end
                end

                WAIT: begin
                    wait_cnt <= wait_cnt + 32'd1;

                    if (rx_data_valid) begin
                        tx_data_valid <= 1'b1;
                        tx_data <= lower_case_rx_data;  // 修正: 小文字に変換されたデータを送信
                    end
                    else if (tx_data_valid && tx_data_ready) begin
                        tx_data_valid <= 1'b0;
                    end
                    else if (wait_cnt >= CLK_FRE) begin  // wait for a second
                        state <= SEND;
                    end
                end

                default:
                    state <= IDLE;
            endcase
        end
    end

    // combination logic
    parameter int DATA_NUM = 15;
    logic [DATA_NUM * 8 - 1:0] send_data = {"Tang Nano 20K", 16'h0d0a};

    always_comb begin
        tx_str = send_data[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
    end

    uart_rx #(
                .CLK_FRE(CLK_FRE),
                .BAUD_RATE(UART_FRE)
            ) uart_rx_inst (
                .clk(clk),
                .rst_n(rst_n),
                .rx_data(rx_data),
                .rx_data_valid(rx_data_valid),
                .rx_data_ready(rx_data_ready),
                .rx_pin(uart_rx)
            );

    to_lower to_lower_inst (  // 追加: 小文字変換モジュールのインスタンス化
                 .in_char(rx_data),
                 .out_char(lower_case_rx_data)
             );

    uart_tx #(
                .CLK_FRE(CLK_FRE),
                .BAUD_RATE(UART_FRE)
            ) uart_tx_inst (
                .clk(clk),
                .rst_n(rst_n),
                .tx_data(tx_data),
                .tx_data_valid(tx_data_valid),
                .tx_data_ready(tx_data_ready),
                .tx_pin(uart_tx)
            );

endmodule
