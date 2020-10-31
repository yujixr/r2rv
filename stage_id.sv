module id(
  input logic clk, reset,
  input logic [31:0] instr,
  input logic we3_in,
  input logic [4:0] wa3_in,
  input logic [31:0] wd3_in,
  output logic src1_selector, src2_selector, wd3_selector, we3_out, wem,
  output logic [2:0] funct3,
  output logic [6:0] funct7,
  output logic [4:0] wa3_out,
  output logic [31:0] imm, rd1, rd2
);

logic [4:0] ra1, ra2;

decoder decode(.instr, .src1_selector, .src2_selector,
  .wd3_selector, .we3(we3_out), .wem, .funct3, .funct7,
  .ra1, .ra2, .wa3(wa3_out), .imm);

regfile rf(.clk, .reset, .we3(we3_in),
  .ra1, .ra2, .wa3(wa3_in), .rd1, .rd2, .wd3(wd3_in));

endmodule
