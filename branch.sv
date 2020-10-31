module branch(
  input logic [31:0] a, b,
  input logic [2:0] funct3,
  output logic result
);

always_comb
  case(funct3)
    3'b000: result = (a == b);                  // BEQ
    3'b001: result = (a != b);                  // BNE
    3'b100: result = $signed(a) < $signed(b);   // BLT
    3'b101: result = $signed(a) >= $signed(b);  // BGE
    3'b110: result = a < b;                     // BLTU
    3'b111: result = a >= b;                    // BGEU
    default: result = 0;
  endcase

endmodule
