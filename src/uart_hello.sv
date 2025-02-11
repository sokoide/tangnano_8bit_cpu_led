module uart_hello_example (
        input  logic        clk,         // Clock input
        input  logic        rst_n,       // Reset input (active low)
        output logic        uart_tx      // UART transmit pin
    );

    // Internal signal definitions
    logic        tx_en;
    logic [2:0]  waddr;
    logic [7:0]  wdata;
    logic        tx_rdy;
    logic        TxRDYn;
    logic [31:0] wait_cnt;
    logic [3:0]  send_idx;
    logic        send_start;
    logic        tx_en_pulse;

    // UART_MASTER_Top instance
    UART_MASTER_Top uart_inst (
                        .I_CLK(clk),
                        .I_RESETN(rst_n),
                        .I_TX_EN(tx_en_pulse),   // Pulse-triggered transmission enable
                        .I_WADDR(waddr),
                        .I_WDATA(wdata),
                        .I_RX_EN(1'b0),
                        .I_RADDR(3'b000),
                        .O_RDATA(),
                        .SIN(1'b1),
                        .RxRDYn(),
                        .SOUT(uart_tx),
                        .TxRDYn(TxRDYn),
                        .DDIS(),
                        .INTR(),
                        .DCDn(1'b1),
                        .CTSn(1'b1),
                        .DSRn(1'b1),
                        .RIn(1'b1),
                        .DTRn(),
                        .RTSn()
                    );

    // Set tx_rdy based on the inverted state of TxRDYn if active low
    assign tx_rdy = ~TxRDYn;

    // Transmission data "Hello\r\n"
    logic [7:0] send_data [0:6];
    assign send_data[0] = 8'h48;  // 'H'
    assign send_data[1] = 8'h65;  // 'e'
    assign send_data[2] = 8'h6C;  // 'l'
    assign send_data[3] = 8'h6C;  // 'l'
    assign send_data[4] = 8'h6F;  // 'o'
    assign send_data[5] = 8'h0D;  // '\r'
    assign send_data[6] = 8'h0A;  // '\n'

    // UART transmission control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wait_cnt <= 32'd0;
            send_idx <= 4'd0;
            tx_en <= 1'b0;
            send_start <= 1'b0;
        end
        else begin
            if (!send_start) begin
                // Wait for 1 second (wait_cnt reaches clock cycles for 1 second)
                wait_cnt <= wait_cnt + 32'd1;
                if (wait_cnt >= 27_000_000) begin  // 1 second delay
                    wait_cnt <= 32'd0;
                    send_start <= 1'b1;
                end
            end
            else if (tx_rdy && !tx_en) begin
                // Set data and start transmission when ready
                waddr <= 3'b000;            // Write address (TX buffer)
                wdata <= send_data[send_idx];  // Set current data
                tx_en <= 1'b1;              // Set transmission enable flag
            end
            else if (tx_en) begin
                // Move to the next data after transmission
                tx_en <= 1'b0;
                if (send_idx < 4'd6) begin
                    send_idx <= send_idx + 4'd1;
                end
                else begin
                    send_idx <= 4'd0;       // Reset after all data sent
                    send_start <= 1'b0;     // Wait for the next 1 second
                end
            end
        end
    end

    // Generate a pulse for tx_en (1 clock cycle pulse for tx_en_pulse)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_en_pulse <= 1'b0;
        end
        else begin
            tx_en_pulse <= tx_en;
        end
    end

endmodule
