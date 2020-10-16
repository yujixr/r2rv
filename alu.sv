module alu(
  input logic [31:0] src1, src2,
  input logic [4:0] shamt,
  input logic [3:0] funct,
  output logic [31:0] result,
  output logic zero
);

assign src2_inv = funct[3] ? (~src2 + 1) : src2;

always_comb
  case(funct[2:0])
    3'b000: result = src1 + src2_inv; // ADD, SUB
    3'b001: result = src1 << shamt;   // SLL
    3'b010: result = src1 < src2;     // SLT
    3'b011: result = src1 < src2;     // SLTU
    3'b100: result = src1 ^ src2;     // XOR
    3'b101: result = funct[3] ? (src1 >>> shamt) : (src1 >> shamt); // SRL, SRA
    3'b110: result = src1 | src2;     // OR
    3'b111: result = src1 & src2;     // AND
  endcase

assign zero = (result == 32'b0);

endmodule
