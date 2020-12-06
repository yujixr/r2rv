module fetch(
  input logic clk, reset,
  input logic can_proceed[2], is_branch_established,
  input logic [31:0] jumped_to,
  output logic is_valid[2],
  output logic [31:0] pc[2]
);

logic [31:0] pc_cur, pc_plus, pc_next;

flopr #(32) pc_reg(clk, reset, pc_next, pc_cur);
assign pc[0] = pc_cur;
assign pc[1] = pc_cur + 4;

always_comb
  if (!can_proceed[0]) begin
    pc_plus = pc_cur;
    is_valid[0] = 0;
    is_valid[1] = 0;
  end
  else if (!can_proceed[1]) begin
    pc_plus = pc_cur + 4;
    is_valid[0] = 1;
    is_valid[1] = 0;
  end
  else begin
    pc_plus = pc_cur + 8;
    is_valid[0] = 1;
    is_valid[1] = 1;
  end

assign pc_next = is_branch_established ? pc_plus : jumped_to;

endmodule
