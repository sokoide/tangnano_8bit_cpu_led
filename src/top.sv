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
  logic [7:0]  w_data;
  logic [7:0]  r_data;
  logic [3:0]  adr;
  logic [3:0]  led;
  logic [3:0]  btn;
  logic [23:0] counter;

  assign w_data = 8'd0;
  assign btn = {4'b00, S2, S1};

  // output port leds are negatives of internal signal led
  assign leds = ~led;

  // RAM instance
  ram ram1 (
    .clk       (counter[23]),
    .we        (1'b0),
    .r_addr    ({4'b0000, adr}),
    .r_data    (r_data),
    .w_addr    ({4'b0000, adr}),
    .w_data    (w_data)
  );

  // CPU instance
  cpu cpu1 (
    .reset   (rst),
    .clk     (counter[23]),
    .btn     (btn),
    .counter (counter),
    .led     (led),
    .adr     (adr),
    .col     (col),
    .row     (row),
    .dout    (r_data)
`ifdef DEBUG_MODE
    , .debug_regs()
`endif
  );

  // update counter
  always_ff @(posedge clk or negedge rst) begin
    if (!rst)
      counter <= 24'd0;
    else
      counter <= counter + 1;
  end

endmodule
