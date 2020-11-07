module branch(
  input logic [31:0] Vj, Vk,
  input logic [9:0] Op,
  output logic y
);

always_comb
  case(Op[9:7])
    3'b000: y = (Vj == Vk);                  // BEQ
    3'b001: y = (Vj != Vk);                  // BNE
    3'b100: y = $signed(Vj) < $signed(Vk);   // BLT
    3'b101: y = $signed(Vj) >= $signed(Vk);  // BGE
    3'b110: y = Vj < Vk;                     // BLTU
    3'b111: y = Vj >= Vk;                    // BGEU
    default: y = 0;
  endcase

endmodule
