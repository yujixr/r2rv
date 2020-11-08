module id(
  input logic clk, reset, we3_in,
  input logic [4:0] wa3_in,
  input logic [31:0] instr, pc, wd3_in,
  output logic we3_out, is_branch_op, is_load_op, is_store_op,
  output logic [2:0] rwmm,
  output logic [4:0] wa3_out,
  output logic [9:0] Op,
  output logic [31:0] Vj, Vk, A
);

logic A_rdy;
logic [4:0] Qj, Qk;
logic [31:0] rd1, rd2, _Vj, _Vk, _A;

decoder decode(.instr, .pc,
  .is_load_op, .we3(we3_out), .is_store_op, .is_branch_op, .A_rdy,
  .rwmm, .Op, .Qj, .Qk, .wa3(wa3_out),
  .Vj(_Vj), .Vk(_Vk), .A(_A));

regfile rf(.clk, .reset, .we3(we3_in),
  .ra1(Qj), .ra2(Qk), .wa3(wa3_in), .rd1, .rd2, .wd3(wd3_in));

assign Vj = (Qj==5'b0) ? _Vj : rd1;
assign Vk = (Qk==5'b0) ? _Vk : rd2;
assign A = A_rdy ? _A : _A + rd1;

endmodule
