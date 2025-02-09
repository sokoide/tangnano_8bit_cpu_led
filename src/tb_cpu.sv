module tb_cpu(
  input  logic         clk
);

  // signals for test
  logic rst;
  logic [3:0]  led;
  logic [3:0]  btn;
  logic [10:0] adr;
  logic [15:0] dout;
  logic [15:0] regs [7:0];
  logic [7:0] col;
  logic [7:0] row;
  logic [23:0] counter;


  // Wire CPU - BSRAM
  // The CPU’s PC is output on "adr" (here 16 bits, but only the lower bits are used for addressing)
  logic [10:0] cpu_pc;              // CPU program counter
  logic [15:0] cpu_instruction;     // registered instruction to feed the CPU
  logic [15:0] mem_din;             // memory write data (unused during normal read)
  logic [15:0] mem_dout;            // memory read data

  // BSRAM control signals
  logic mem_ce;   // chip enable
  logic mem_wre;  // write enable
  logic mem_oce;  // output enable

  // Create a register for the bootloader address and a signal to indicate boot mode.
  logic [10:0] boot_addr;
  logic        boot_mode;  // 1 during boot, 0 after boot is done

  // Bootloader state machine signals
  typedef enum logic [1:0] {IDLE, WRITE, DONE} state_t;
  state_t state;
  logic [3:0]  write_index;  // used as address for boot writes
  logic [15:0] init_data [0:2];

  // Predefined initialization data.
  initial begin
    init_data[0] = 16'b0000_0000_1010_0001; // mvi r0, 1
    init_data[1] = 16'b0000_0000_01111_000; // lrotate r0
    init_data[2] = 16'b0000_0000_1001_0001; // jmp 1
  end

  // Bootloader state machine.
  // This block drives the boot_addr, and sets the proper control signals while in boot mode.
  // Note: use rst consistently (here we assume rst is active low).
  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      state       <= WRITE;
      write_index <= 0;
      boot_mode   <= 1;    // during boot
    end else begin
      case (state)
        WRITE: begin
          // During boot, drive the address from the write_index
          boot_addr <= write_index;
          // Set up for a write:
          mem_ce  <= 1;
          mem_wre <= 1;
          mem_din <= init_data[write_index];
          // Increment the bootloader address:
          if (write_index == 2) begin
            state     <= DONE;
            boot_mode <= 0;  // finished booting
          end else begin
            write_index <= write_index + 1;
          end
        end
        DONE: begin
          // In normal operation: disable write
          mem_ce  <= 1;
          mem_wre <= 0;
          mem_din <= 16'd0;
        end
        default: state <= WRITE;
      endcase
    end
  end

  // Multiplexer for the memory address.
  // When boot_mode is active, use boot_addr; otherwise, use cpu_pc.
  // (Assuming cpu_pc’s lower 11 bits are valid for addressing.)
  logic [10:0] mem_ad;
  assign mem_ad = boot_mode ? boot_addr : cpu_pc[10:0];

  // Set the constant for output enable.
  assign mem_oce = 1;
  // Chip enable is already driven by the state machine (mem_ce).

  // BSRAM instance.
  // (Note: Make sure the reset signal here is connected properly.
  //  If your top module input is rst, you may want to pass rst or its synchronized version.)
  Gowin_SP bsr_inst (
    .clk   (clk),
    .oce   (mem_oce),
    .ce    (mem_ce),
    .reset (rst),       // using rst here for consistency
    .wre   (mem_wre),
    .ad    (mem_ad),
    .din   (mem_din),
    .dout  (mem_dout)
  );

  // --- Instruction Register ---
  // Because BSRAM’s output appears one clock cycle after the address is set,
  // latch mem_dout into cpu_instruction.
  always_ff @(posedge clk or negedge rst) begin
    if (!rst)
      cpu_instruction <= 16'd0;
    else
      cpu_instruction <= mem_dout;
  end

  // DUT (Device Under Test)
  cpu dut (
    .reset   (rst),
    .clk     (counter[21]),
    .btn     ({4'b0000}),
    .counter (counter),
    .led     (led),
    .adr     (cpu_pc),          // CPU’s program counter output drives the BSRAM in normal mode.
    .col     (col),
    .row     (row),
    .dout    (cpu_instruction)
  );

  // Test
  initial begin
    btn = 4'b0000;

    rst = 0; // active
    repeat (10) @(posedge clk);  // wait for 10 clock cycles
    rst = 1; // release

    // after 10 cycles (reset)
    $display("10 cycles");
    // test led
    if (led !== 4'b0000) begin
      $display("ERROR: Unexpected led value: %b", led);
      $stop;
    end

    // get traces some more in the vcd
    repeat (100) @(posedge clk);

    $display("All Test Passed");
    $finish;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, cpu_tb);
  end

endmodule
