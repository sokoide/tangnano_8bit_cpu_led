module tb_cpu;
    // signals for test
    logic clk;
    logic rst_n;
    logic [3:0]  led;
    logic [23:0] counter;
    logic [10:0] adr;
    logic [7:0] regs [7:0];
    logic [7:0] col;
    logic [7:0] row;

    wire rst = !rst_n;

    // individual register assignments
    logic [7:0] reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7;


    // Wire CPU - BSRAM
    // The CPU’s PC is output on "adr" (here 16 bits, but only the lower bits are used for addressing)
    logic [10:0] cpu_pc;              // CPU program counter
    logic [15:0] cpu_instruction;     // registered instruction to feed the CPU
    logic [15:0] din;             // memory write data (unused during normal read)
    logic [15:0] dout;            // memory read data

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
        boot_data[11] = 16'b0000_0000_00_101100; // mov r5, r4
        boot_data[12] = 16'b0000_0000_00_111101; // mov r7, r5
        boot_data[13] = 16'b0000_0000_1001_0010; // jmp 2
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

    // DUT (Device Under Test)
    cpu dut (
            .rst_n   (rst_n),
            .clk     (clk),
            .btn     ({8'b0000000}),
            .counter (counter),
            .led     (led),
            .col     (col),
            .row     (row),
            .dout    (dout),
            .pc_out  (cpu_pc)
`ifdef DEBUG_MODE
            , .debug_regs(regs)
`endif
        );

    // update counter (for CPU timing)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 24'd0;
        end
        else begin
            counter <= counter + 1;
        end
    end

    // For display: drive LEDs (inverted internal led signal)
    assign leds = ~led;

    // assign individual registers for waveform
    always_comb begin
        {reg7, reg6, reg5, reg4, reg3, reg2, reg1, reg0} = {regs[7], regs[6], regs[5], regs[4], regs[3], regs[2], regs[1], regs[0]};
    end

    // 10ns clock (#5 means 5ns)
    always #5 clk = ~clk;

    // test
    initial begin
        clk = 0;
        @(posedge clk); // wait for 1 clock cycle before starting the test

        $display("=== Test Start ===");

        rst_n = 0; // active
        @(posedge clk);  // wait for 1 clock cycle
        rst_n = 1; // release
        repeat (1) @(posedge clk); // add delta cycle for reg check

        // Test sequence
        repeat (1) @(posedge clk);
        check_state(1, 8'd0);

        repeat (1) @(posedge clk);
        check_state(2, 8'd1);

        repeat (1) @(posedge clk);
        check_state(3, 8'd1);

        repeat (1) @(posedge clk);
        check_state(4, 8'd2);

        repeat (1) @(posedge clk);
        check_state(5, 8'd4);

        // get traces some more in the vcd
        repeat (40) @(posedge clk);

        $display("=== Test End ===");
        $finish;
    end

    task check_state(input int expected_counter, input [7:0] expected_reg0);
        $display("[%04d]", counter);
        if (counter !== expected_counter) begin
            $display("ERROR: Unexpected counter value: %d", counter);
        end
        if (reg0 !== expected_reg0) begin
            $display("ERROR: Unexpected reg0 value: %d", reg0);
        end
    endtask

endmodule
