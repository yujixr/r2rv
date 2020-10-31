module alu(
  input logic [31:0] a, b,
  input logic [2:0] funct3,
  input logic [6:0] funct7,
  output logic [31:0] result
);

logic [31:0] b_inv;
logic [4:0] shamt;

assign b_inv = funct7[5] ? (~b + 1) : b;
assign shamt = b[4:0];

always_comb
  case(funct3)
    3'b000: result = $signed(a) + $signed(b_inv); // ADD, SUB
    3'b001: result = a << shamt;                  // SLL
    3'b010: result = $signed(a) < $signed(b);     // SLT
    3'b011: result = a < b;                       // SLTU
    3'b100: result = a ^ b;                       // XOR
    3'b101: result = funct7[5] ? (a >>> shamt) : (a >> shamt); // SRL, SRA
    3'b110: result = a | b;                       // OR
    3'b111: result = a & b;                       // AND
    default: result = 0;
  endcase

endmodule
