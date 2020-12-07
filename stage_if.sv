module fetch(
  input logic clk, reset,
  input logic can_proceed[2], is_branch_established,
  input logic [31:0] jumped_to,
  output logic [31:0] pc[2], pc_next
);

logic [31:0] pc_cur, pc_plus;

flopr #(32) pc_reg(.clk, .reset, .d(pc_next), .q(pc_cur));
assign pc[0] = pc_cur;
assign pc[1] = pc_cur + 4;

always_comb
  if (!can_proceed[0]) begin
    pc_plus = pc_cur;
  end
  else if (!can_proceed[1]) begin
    pc_plus = pc_cur + 4;
  end
  else begin
    pc_plus = pc_cur + 8;
  end

assign pc_next = is_branch_established ? jumped_to : pc_plus;

endmodule
