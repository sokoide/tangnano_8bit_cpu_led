module top(
  input  logic       clk,
  input  logic       rst,
  input  logic       S1,
  input  logic       S2,
  output logic [5:0] leds,
  output logic [7:0] col,
  output logic [7:0] row
);

  // internal signals
  logic [3:0]  led;
  logic [3:0]  btn;
  logic [23:0] counter;

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
  assign ce = 1'b1;
  assign wre = 1'b0;
  assign oce = 1'b1;
  // Chip enable is already driven by the state machine (mem_ce).

// BSRAM instance.
  Gowin_SP bsram_inst (
    .clk   (clk),
    .oce   (oce),
    .ce    (ce),
    .reset (!rst),       // using rst here for consistency
    .wre   (wre),
    .ad    (cpu_pc),
    .din   (din),
    .dout  (dout)
  );

//   Gowin_pROM bsram_inst(
//     .dout(dout), //output [15:0] dout
//     .clk(clk), //input clk
//     .oce(oce), //input oce
//     .ce(ce), //input ce
//     .reset(!rst), //input reset
//     .ad(cpu_pc) //input [10:0] ad
// );

  // --- Instruction Register ---
  reg [15:0] dout_latched;

  // Latch PROM output to avoid timing issues
  always_ff @(posedge clk or negedge rst) begin
    if (!rst)
        dout_latched <= 16'd0;
    else
        dout_latched <= dout;
  end


  // The CPU uses cpu_instruction as its fetched instruction and outputs its program counter (cpu_pc).
  cpu cpu1 (
    .reset   (rst),
    .clk     (counter[23]),
    .btn     ({2'b00, S2, S1}),
    .counter (counter),
    .led     (led),
    .adr     (cpu_pc),          // CPU’s program counter output drives the BSRAM in normal mode.
    .col     (col),
    .row     (row),
    .dout    (dout_latched)
  );

  // update counter (for CPU timing)
  always_ff @(posedge clk or negedge rst) begin
    if (!rst)
      counter <= 24'd0;
    else
      counter <= counter + 1;
  end

  // For display: drive LEDs (inverted internal led signal)
  assign leds = ~led;

endmodule
