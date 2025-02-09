module ram(
  input  logic        clk,
  input  logic        we,
  input  logic [7:0]  r_addr,
  output logic [7:0]  r_data,
  input  logic [7:0]  w_addr,
  input  logic [7:0]  w_data
);

  // 8bit x 16 words memory space
  (* ram_style = "block" *) logic [7:0] mem [255:0];

  initial begin
    mem[0] = 8'b1010_0001;  // mvi R0,1
    mem[1] = 8'b01111_000;  // urotate R0
    mem[2] = 8'b01100_110;  // inc R6
    mem[3] = 8'b00_001000;  // mov R1, R0
    mem[4] = 8'b01100_001;  // inc R1
    mem[5] = 8'b00_010001;  // mov R2, R1
    mem[6] = 8'b01100_010;  // inc R2
    mem[7] = 8'b00_011010;  // mov R3, R2
    mem[8] = 8'b01100_011;  // inc R3
    mem[9] = 8'b00_100011;  // mov R4, R3
    mem[10] = 8'b01100_100;  // inc R4
    mem[11] = 8'b1001_0001;  // jmp 1
  end

  // write (sync clock)
  always_ff @(posedge clk) begin
    if (we) begin
      mem[w_addr] <= w_data;
    end
  end

  // read
  assign r_data = mem[r_addr];

endmodule
