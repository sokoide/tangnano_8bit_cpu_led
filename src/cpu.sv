module cpu(
  input  logic         reset,
  input  logic         clk,
  input  logic [3:0]   btn,
  input  logic [23:0]  counter,
  output logic [3:0]   led,
  output logic [3:0]   adr,
  output logic [7:0]   col,
  output logic [7:0]   row,
  input  logic [7:0]   dout

`ifdef DEBUG_MODE
  , output logic [3:0] debug_regs [7:0]  // Debug output (only in debug mode)
`endif
);

  // Decode the instruction fields from dout.
  logic [4:0] op;
  logic [2:0] sss;
  assign op  = dout[7:3];
  assign sss = dout[2:0];

  wire [2:0]i = counter[15:13];


  // Internal registers.
  logic        c_flag;
  logic [3:0]  regs [7:0];

`ifdef DEBUG_MODE
  // Assign debug output for testing
  assign debug_regs = regs;
`endif

  // Output assignments.
  assign led = regs[6];
  assign adr = regs[7];

  // anode
  assign row = { regs[i][0], regs[i][1], regs[i][2], regs[i][3], 4'b0000};
  // cathode
  assign col ={i!=0,i!=1,i!=2,i!=3,i!=4,i!=5,i!=6,i!=7};

  // Sequential logic: use an asynchronous active-low reset.
  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      // Reset: clear selected registers and the flag.
      {regs[0], regs[1], regs[2], regs[3], regs[4], regs[6], regs[7], c_flag} <= '0;
    end else begin
      // Update register 5 with the button input.
      regs[5] <= btn;

      // Instruction decoding and execution.
      casez (op)
        // MOV: Move the contents of regs[sss] to regs[op[2:0]].
        5'b00zzz: regs[op[2:0]] <= regs[sss];

        // ADD: Add regs[sss] to regs[0] and set the carry flag if the sum exceeds 15.
        5'b01000: begin
          regs[0] <= regs[0] + regs[sss];
          /* verilator lint_off CMPCONST */
          c_flag  <= ((regs[0] + regs[sss]) > 4'd15) ? 1'b1 : 1'b0;
          /* verilator lint_on CMPCONST */
        end

        // OR: Logical OR between regs[0] and regs[sss].
        5'b01001: regs[0] <= regs[0] | regs[sss];

        // AND: Logical AND between regs[0] and regs[sss].
        5'b01010: regs[0] <= regs[0] & regs[sss];

        // XOR: Logical XOR between regs[0] and regs[sss].
        5'b01011: regs[0] <= regs[0] ^ regs[sss];

        // INC: Increment regs[sss] and update carry flag if overflow.
        5'b01100: begin
          regs[sss] <= regs[sss] + 1;
          c_flag    <= ((regs[sss] + 1) > 4'd15) ? 1'b1 : 1'b0;
        end

        // NOT: Bitwise NOT of regs[sss].
        5'b01101: regs[sss] <= ~regs[sss];

        // RROTATE: Right rotate regs[sss].
        5'b01110: regs[sss] <= (regs[sss] >> 1) | ((regs[sss] << 3) & 4'b1000);

        // LROTATE: Left rotate regs[sss].
        5'b01111: regs[sss] <= (regs[sss] << 1) | ((regs[sss] >> 3) & 4'b0001);

        // JNC: Jump if no carry; otherwise, increment PC.
        5'b1000z: begin
          regs[7] <= (c_flag) ? (regs[7] + 1) : {op[0], sss};
          c_flag  <= 1'b0;
        end

        // JMP: Unconditional jump.
        5'b1001z: regs[7] <= {op[0], sss};

        // MVI: Move immediate value into regs[0].
        5'b1010z: regs[0] <= {op[0], sss};

        // Optionally, you can add a default case.
        default: ; // No operation.
      endcase

      // PC Increment: If the opcode is not a jump instruction, increment the program counter.
      if (op[4:1] != 4'b1000 && op[4:1] != 4'b1001) begin
        regs[7] <= regs[7] + 1;
      end
    end
  end

endmodule
