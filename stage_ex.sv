module ex(
  input logic [31:0] pc_plus4,
  input logic src1_selector, src2_selector,
  input logic [2:0] funct3,
  input logic [6:0] funct7,
  input logic [31:0] imm, rd1, rd2,
  output logic [31:0] ex_result,
  output logic is_branched
);

logic [31:0] src1, src2, alu_result, mul_result, div_result, muldiv_result;

mux2 #(32) select_src1(rd1, pc_plus4, src1_selector, src1);
mux2 #(32) select_src2(rd2, imm, src2_selector, src2);

alu alu(src1, src2, { funct7[5], funct3 }, alu_result);
mul mul(src1, src2, funct3[1:0], mul_result);
div div(src1, src2, funct3[1:0], div_result);
branch br(rd1, rd2, funct3, is_branched);

mux2 #(32) select_muldiv_result(mul_result, div_result, funct3[2], muldiv_result);
mux2 #(32) select_ex_result(alu_result, muldiv_result, funct7[0], ex_result);

endmodule
