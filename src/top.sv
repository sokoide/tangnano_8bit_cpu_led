module top (
    input  logic       clk,
    input  logic       rst,      // active high
    input  logic       uart_rx,
    output logic       uart_tx,
    output logic [5:0] leds,
    output logic [7:0] col,
    output logic [7:0] row
);

  // internal signals
  logic [ 3:0] led;
  logic [23:0] counter;
  wire         rst_n = !rst;

  // CPU and BSRAM signals
  // CPU program counter
  logic [10:0] cpu_pc;
  // memory write data
  // unused during normal read
  logic [15:0] din;
  logic [15:0] dout;
  // chip enable
  logic        ce;
  // write enable
  logic        wre;
  // output enable
  logic        oce = 1'b1;

  // Bootloader signals
  logic [10:0] boot_addr;
  // 1 during boot, 0 after boot is done
  logic        boot_mode;
  // Internal signal to control when to write
  logic        boot_write;
  logic [15:0] boot_data    [0:17];
  localparam [15:0] boot_data_length = $bits(boot_data) / $bits(boot_data[0]);

  // Program to load during boot
  initial begin
    cpu_pc = 11'd0;
    boot_data[0] = 16'b0000_0000_1010_0001;  // mvi 1
    boot_data[1] = 16'b0000_0000_01111_000;  // lrotate r0
    boot_data[3] = 16'b0000_0000_00_001000;  // mov r1, r0
    boot_data[4] = 16'b0000_0000_01100_001;  // inc r1
    boot_data[5] = 16'b0000_0000_00_010001;  // mov r2, r1
    boot_data[6] = 16'b0000_0000_01100_010;  // inc r2
    boot_data[7] = 16'b0000_0000_00_011010;  // mov r3, r2
    boot_data[8] = 16'b0000_0000_01100_011;  // inc r3
    boot_data[9] = 16'b0000_0000_00_100011;  // mov r4, r3
    boot_data[10] = 16'b0000_0000_01100_100;  // inc r4
    boot_data[11] = 16'b0000_0000_00_101100;  // mov r5, r4
    boot_data[12] = 16'b0000_0000_01100_101;  // inc r5
    boot_data[13] = 16'b0000_0000_00_110101;  // mov r6, r5
    boot_data[14] = 16'b0000_0000_01100_110;  // inc r6
    boot_data[15] = 16'b0000_0000_00_111110;  // mov r7, r6
    boot_data[16] = 16'b0000_0000_01100_111;  // inc r7
    boot_data[17] = 16'b0000_0000_1001_0010;  // jmp 2
  end

  // Boot process management
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      boot_addr  <= 0;
      boot_mode  <= 1;
      ce         <= 1;
      wre        <= 0;
      boot_write <= 1;
    end else if (boot_mode) begin
      if (boot_write) begin
        din <= boot_data[boot_addr];
        ce <= 1;
        wre <= 1;
        boot_write <= 0;  // Prevent immediate increment in the same cycle
      end else begin
        wre <= 0;  // Disable write after one cycle
        if (boot_addr == boot_data_length) begin
          boot_mode <= 0;  // End boot process after writing all data
        end else begin
          boot_addr  <= (boot_addr + 1) & 11'h7FF;
          boot_write <= 1;  // Enable write for the next address
        end
      end
    end else begin
      ce  <= 1;  // Normal operation mode
      wre <= 0;  // No write during normal operation
    end
  end

  // Multiplexer for the memory address.
  logic [10:0] mem_addr;
  assign mem_addr = boot_mode ? boot_addr : cpu_pc / 2;

  // BSRAM instance.
  Gowin_SP bsram_inst (
      .clk  (clk),
      .oce  (oce),
      .ce   (ce),
      .reset(rst),
      .wre  (wre),
      .ad   (mem_addr),
      .din  (din),
      .dout (dout)
  );

  // CPU instance
  cpu cpu1 (
      .rst_n  (rst_n),
      .clk    (counter[22]),
      .counter(counter),
      .led    (led),
      .col    (col),
      .row    (row),
      .dout   (dout),
      .pc_out (cpu_pc)
  );

  // Update counter (for CPU timing)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 24'd0;
    end else begin
      counter <= counter + 1;
    end
  end

  // Drive LEDs (inverted internal led signal)
  assign leds = ~led;

  // UART instance
  uart_register u_uart_register_inst (
      .clk    (clk),
      .rst_n  (rst_n),
      .uart_tx(uart_tx),
      .pc     (cpu_pc)
  );

endmodule
