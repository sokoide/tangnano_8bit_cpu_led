module to_lower (
  input  logic [7:0] in_char,
  output logic [7:0] out_char
);

  always_comb begin
    if (in_char >= 8'h41 && in_char <= 8'h5A) begin  // 'A' = 65 = 8'h41, 'Z' = 90 = 8'h5A
      out_char = in_char + 8'h20;  // 32 = 8'h20
    end else begin
      out_char = in_char;
    end
  end

endmodule
