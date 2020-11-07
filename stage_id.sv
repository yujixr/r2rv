module id(
  input logic clk, reset, we3_in,
  input logic [4:0] wa3_in,
  input logic [31:0] instr, pc, wd3_in,
  output logic is_load_op, we3_out, wem, is_branch_op,
  output logic [2:0] rwmm,
  output logic [4:0] wa3_out,
  output logic [9:0] Op,
  output logic [31:0] Vj, Vk, rd1, rd2
);

logic [4:0] Qj, Qk;
logic [31:0] _Vj, _Vk;

decoder decode(.instr, .pc,
  .is_load_op, .we3(we3_out), .wem, .is_branch_op,
  .rwmm, .Op, .Qj, .Qk, .wa3(wa3_out),
  .Vj(_Vj), .Vk(_Vk));

regfile rf(.clk, .reset, .we3(we3_in),
  .ra1(Qj), .ra2(Qk), .wa3(wa3_in), .rd1, .rd2, .wd3(wd3_in));

assign Vj = (Qj==5'b0) ? _Vj : rd1;
assign Vk = (Qk==5'b0) ? _Vk : rd2;

endmodule
