module ex(
  input logic [2:0] Unit,
  input logic [9:0] Op,
  input logic [31:0] pc, rdm, Vj, Vk,
  output logic is_branched,
  output logic [31:0] result
);

logic is_branch_established;
logic [31:0] alu_result, mul_result, div_result, muldiv_result, ex_result;

alu alu(.Vj, .Vk, .Op, .y(alu_result));
mul mul(.Vj, .Vk, .Op, .y(mul_result));
div div(.Vj, .Vk, .Op, .y(div_result));
branch br(.Vj, .Vk, .Op, .y(is_branch_established));

always_comb
  case (Unit)
    ALU:     result = alu_result;
    BRANCH:  result = pc + 4;
    MUL:     result = mul_result;
    DIV:     result = div_result;
    LOAD:    result = rdm;
    default: result = 32'b0;
  endcase

assign is_branched = (Unit==BRANCH) & is_branch_established;

endmodule
