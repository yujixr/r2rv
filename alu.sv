module alu(
  input logic [31:0] Vj, Vk,
  input logic [9:0] Op,
  output logic [31:0] y
);

logic [4:0] shamt;
assign shamt = Vk[4:0];

always_comb
  case(Op[9:5])
    5'b00000: y = $signed(Vj) + $signed(Vk);      // ADD
    5'b00001: y = $signed(Vj) + $signed(~Vk + 1); // SUB
    5'b00100: y = Vj << shamt;                    // SLL
    5'b01000: y = $signed(Vj) < $signed(Vk);      // SLT
    5'b01100: y = Vj < Vk;                        // SLTU
    5'b10000: y = Vj ^ Vk;                        // XOR
    5'b10100: y = Vj >> shamt;                    // SRL
    5'b10101: y = Vj >>> shamt;                   // SRA
    5'b11000: y = Vj | Vk;                        // OR
    5'b11100: y = Vj & Vk;                        // AND
    default: y = 32'b0;
  endcase

endmodule
