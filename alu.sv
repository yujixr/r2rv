module alu(
  input logic [31:0] Vj, Vk,
  input logic [9:0] Op,
  output logic [31:0] y
);

logic [4:0] shamt;
assign shamt = Vk[4:0];

always_comb
  case(Op[9:6])
    4'b0000: y = $signed(Vj) + $signed(Vk);      // ADD
    4'b0001: y = $signed(Vj) + $signed(~Vk + 1); // SUB
    4'b0010: y = Vj << shamt;                    // SLL
    4'b0100: y = $signed(Vj) < $signed(Vk);      // SLT
    4'b0110: y = Vj < Vk;                        // SLTU
    4'b1000: y = Vj ^ Vk;                        // XOR
    4'b1010: y = Vj >> shamt;                    // SRL
    4'b1011: y = Vj >>> shamt;                   // SRA
    4'b1100: y = Vj | Vk;                        // OR
    4'b1110: y = Vj & Vk;                        // AND
    default: y = 32'b0;
  endcase

endmodule
