module top(
        input  logic       clk,
        input  logic       rst, // active high
        input  logic       S2,
        input  logic       uart_rx,
        output logic       uart_tx,
        output logic [5:0] leds,
        output logic [7:0] col,
        output logic [7:0] row
    );

    // internal signals
    logic [3:0]  led;
    logic [3:0]  btn;
    logic [23:0] counter;
    wire rst_n = !rst;

    // Wire CPU - BSRAM
    // The CPU’s PC is output on "adr" (here 16 bits, but only the lower bits are used for addressing)
    logic [10:0] cpu_pc;              // CPU program counter
    logic [15:0] cpu_instruction;     // registered instruction to feed the CPU
    logic [15:0] din;                 // memory write data (unused during normal read)
    logic [15:0] dout;

    // BSRAM control signals
    logic ce;   // chip enable
    logic wre;  // write enable
    logic oce;  // output enable


    // Set the constant for output enable.
    assign oce = 1'b1;

    // Create a register for the bootloader address and a signal to indicate boot mode.
    logic [10:0] boot_addr;
    logic        boot_mode;  // 1 during boot, 0 after boot is done
    logic        boot_write; // Internal signal to control when to write

    // Bootloader state machine signals
    logic [15:0] boot_data [0:15];

    // Program to load during boot
    initial begin
        boot_data[0] = 16'b0000_0000_1010_0001; // mvi 1
        boot_data[1] = 16'b0000_0000_01111_000; // lrotate r0
        boot_data[2] = 16'b0000_0000_01100_110; // inc r6
        boot_data[3] = 16'b0000_0000_00_001000; // mov r1, r0
        boot_data[4] = 16'b0000_0000_01100_001; // inc r1
        boot_data[5] = 16'b0000_0000_00_010001; // mov r2, r1
        boot_data[6] = 16'b0000_0000_01100_010; // inc r2
        boot_data[7] = 16'b0000_0000_00_011010; // mov r3, r2
        boot_data[8] = 16'b0000_0000_01100_011; // inc r3
        boot_data[9] = 16'b0000_0000_00_100011; // mov r4, r3
        boot_data[10] = 16'b0000_0000_01100_100; // inc r4
        boot_data[11] = 16'b0000_0000_1001_0001; // jmp 1
    end

    // Boot process management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            boot_addr  <= 0;
            boot_mode  <= 1;
            ce         <= 1;
            wre        <= 0;
            boot_write <= 1;
        end
        else if (boot_mode) begin
            if (boot_write) begin
                din <= boot_data[boot_addr];
                ce  <= 1;
                wre <= 1;
                boot_write <= 0;  // Prevent immediate increment in the same cycle
            end
            else begin
                wre <= 0;  // Disable write after one cycle
                if (boot_addr == 11'd15) begin
                    boot_mode <= 0;  // End boot process after writing all data
                end
                else begin
                    boot_addr <= (boot_addr + 1) & 11'h7FF;
                    boot_write <= 1;  // Enable write for the next address
                end
            end
        end
        else begin
            ce  <= 1;  // Normal operation mode
            wre <= 0;  // No write during normal operation
        end
    end

    // Multiplexer for the memory address.
    // When boot_mode is active, use boot_addr; otherwise, use cpu_pc.
    // (Assuming cpu_pc’s lower 11 bits are valid for addressing.)
    logic [10:0] mem_addr;
    assign mem_addr = boot_mode ? boot_addr : cpu_pc;

    // BSRAM instance.
    Gowin_SP bsram_inst (
                 .clk   (clk),
                 .oce   (oce),
                 .ce    (ce),
                 .reset (rst),
                 .wre   (wre),
                 .ad    (mem_addr),
                 .din   (din),
                 .dout  (dout)
             );

    // The CPU uses cpu_instruction as its fetched instruction and outputs its program counter (cpu_pc).
    cpu cpu1 (
            .rst_n   (rst_n),
            .clk     (counter[22]),
            .btn     ({7'b0000000, S2}),
            .counter (counter),
            .led     (led),
            .adr     (cpu_pc),          // CPU’s program counter output drives the BSRAM in normal mode.
            .col     (col),
            .row     (row),
            .dout    (dout)
        );

    // update counter (for CPU timing)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 24'd0;
            // dummy data
            regs[0] <= 16'd1;
            regs[1] <= 16'd2;
            regs[2] <= 16'd3;
            regs[3] <= 16'd4;
            regs[4] <= 16'd5;
            regs[5] <= 16'd6;
            regs[6] <= 16'd7;
            regs[7] <= 16'd8;
        end
        else
            counter <= counter + 1;
    end

    // For display: drive LEDs (inverted internal led signal)
    assign leds = ~led;

    // UART
    // uart_hello_example uart1(
    //                        .clk    (clk),
    //                        .rst_n  (rst_n),
    //                        .uart_tx(uart_tx)
    //                    );
    // output declaration of module uart_register_example

    logic [15:0] regs [7:0];

    uart_register_example u_uart_register_example(
                              .clk     	(clk),
                              .rst_n   	(rst_n    ),
                              .uart_tx 	(uart_tx  ),
                              .regs    	(regs     )
                          );

endmodule
