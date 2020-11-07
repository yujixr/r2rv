module ex(
  input logic is_branch_op,
  input logic [9:0] Op,
  input logic [31:0] pc_plus4, rd1, rd2, Vj, Vk,
  output logic is_branched,
  output logic [31:0] wdx, addr
);

logic is_branch_established;
logic [31:0] alu_result, mul_result, div_result, muldiv_result, ex_result;

alu alu(.Vj, .Vk, .Op, .y(alu_result));
mul mul(.Vj, .Vk, .Op, .y(mul_result));
div div(.Vj, .Vk, .Op, .y(div_result));
branch br(.Vj(rd1), .Vk(rd2), .Op, .y(is_branch_established));

mux2 #(32) select_muldiv_result(mul_result, div_result, Op[9], muldiv_result);
mux2 #(32) select_ex_result(alu_result, muldiv_result, Op[0], ex_result);
mux2 #(32) select_wdx(ex_result, pc_plus4, is_branch_op, wdx);

assign is_branched = is_branch_op & is_branch_established;
assign addr = { ex_result[31:1], 1'b0 };

endmodule
