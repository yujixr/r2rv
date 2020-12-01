module id(
  input logic clk, reset,
  input logic [4:0] wa3,
  input logic [31:0] instr, pc, wd3,
  output unit Unit,
  output ldst_mode rwmm,
  output logic [4:0] Dest,
  output logic [9:0] Op,
  output logic [31:0] Vj, Vk, A
);

logic A_rdy;
logic [4:0] Qj, Qk;
logic [31:0] rd1, rd2, _Vj, _Vk, _A;

decoder decode(.instr, .pc,
  .A_rdy, .Unit, .rwmm, .Op, .Qj, .Qk, .Dest,
  .Vj(_Vj), .Vk(_Vk), .A(_A));

regfile rf(.clk, .reset, .ra1(Qj), .ra2(Qk),
  .wa3, .rd1, .rd2, .wd3);

assign Vj = (Qj==5'b0) ? _Vj : rd1;
assign Vk = (Qk==5'b0) ? _Vk : rd2;
assign A = A_rdy ? _A : _A + rd1;

endmodule
