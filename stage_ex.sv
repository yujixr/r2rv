module ex(
  input logic [2:0] Unit,
  input logic [9:0] Op,
  input logic [31:0] pc_plus4, Vj, Vk,
  output logic is_branched,
  output logic [31:0] wdx
);

logic is_branch_established;
logic [31:0] alu_result, mul_result, div_result, muldiv_result, ex_result;

alu alu(.Vj, .Vk, .Op, .y(alu_result));
mul mul(.Vj, .Vk, .Op, .y(mul_result));
div div(.Vj, .Vk, .Op, .y(div_result));
branch br(.Vj, .Vk, .Op, .y(is_branch_established));

always_comb
  case (Unit)
    ALU:     wdx = alu_result;
    BRANCH:  wdx = pc_plus4;
    MUL:     wdx = mul_result;
    DIV:     wdx = div_result;
    default: wdx = 32'b0;
  endcase

assign is_branched = (Unit==BRANCH) & is_branch_established;

endmodule
