module uart_register_example (
        input  logic        clk,         // Clock input
        input  logic        rst_n,       // Reset input (active low)
        output logic        uart_tx,     // UART transmit pin
        input  logic [15:0] regs[7:0]   // CPU module register array input
    );

    // Internal signal definitions
    logic        tx_en;
    logic [2:0]  waddr;
    logic [7:0]  wdata;
    logic        TxRDYn;
    logic        tx_rdy;
    logic [4:0]  send_idx;
    logic        send_start;
    logic        tx_en_pulse;
    logic [15:0] reg_data;
    logic [15:0] reg_data_prev;
    logic [7:0]  send_data [0:15];

    // UART_MASTER_Top instance
    UART_MASTER_Top uart_inst (
                        .I_CLK(clk),
                        .I_RESETN(rst_n),
                        .I_TX_EN(tx_en_pulse),
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

    // Initialize send_data once at the start of transmission
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_idx <= 5'd0;
            tx_en <= 1'b0;
            send_start <= 1'b0;
            reg_data <= 16'd0;
            reg_data_prev <= 16'd0;
            send_data[0]  <= 8'h72;  // 'r'
            send_data[1]  <= 8'h65;  // 'e'
            send_data[2]  <= 8'h67;  // 'g'
            send_data[3]  <= 8'h73;  // 's'
            send_data[4]  <= 8'h5b;  // '['
            send_data[5]  <= 8'h37;  // '7'
            send_data[6]  <= 8'h5d;  // ']'
            send_data[7]  <= 8'h3d;  // '='
            send_data[8]  <= 8'h30;  // '0'
            send_data[9]  <= 8'h78;  // 'x'
            send_data[10] <= 8'h30;  // '0'
            send_data[11] <= 8'h30;  // '0'
            send_data[12] <= 8'h30;  // '0'
            send_data[13] <= 8'h30;  // '0'
            send_data[14] <= 8'h0D;  // '\r'
            send_data[15] <= 8'h0A;  // '\n'
        end
        else begin
            reg_data <= regs[7];  // Fetch register data at the start of transmission

            if (reg_data != reg_data_prev) begin
                reg_data_prev <= reg_data;

                // Prepare the dynamic bits "XXXXXXXX"
                send_data[10]  <= (reg_data[15:12] > 9) ? (8'h41 + reg_data[15:12] - 10) : (8'h30 + reg_data[15:12]);
                send_data[11]  <= (reg_data[11:8]  > 9) ? (8'h41 + reg_data[11:8]  - 10) : (8'h30 + reg_data[11:8]);
                send_data[12] <= (reg_data[7:4]   > 9) ? (8'h41 + reg_data[7:4]   - 10) : (8'h30 + reg_data[7:4]);
                send_data[13] <= (reg_data[3:0]   > 9) ? (8'h41 + reg_data[3:0]   - 10) : (8'h30 + reg_data[3:0]);
                send_data[14] <= 8'h0A;  // Newline or other end-of-line marker
                send_data[15] <= 8'h0D;  // Carriage return or other end-of-line marker

                send_start <= 1'b1;
            end

            if (send_start && tx_rdy && !tx_en) begin
                // Send each character from the prepared string
                waddr <= 3'b000;            // Write address (TX buffer)
                wdata <= send_data[send_idx];  // Set current data
                tx_en <= 1'b1;              // Set transmission enable flag
                send_idx <= send_idx + 5'd1;
                // only send 16 characters
                if (send_idx == 5'd15) begin
                    send_idx <= 5'd0;       // Reset after all data sent
                    send_start <= 1'b0;     // Send completed
                end
            end
            else if (tx_en) begin
                // Clear transmission enable after sending
                tx_en <= 1'b0;
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
