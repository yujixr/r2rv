// R: Read, W: Write, RW: Read-Write
// D: Data, A: Address, M: access Mode, E: Enabler-signal
// 1...3: regfile1...3, M: Memory

module riscv(
  input logic clk, reset,
  output logic [31:0] pc,
  input logic [31:0] instr,
  output logic wem,
  output logic [2:0] rwmm,
  output logic [31:0] rwam, wdm,
  input logic [31:0] rdm
);

// BATON ZONE: EX -> IF

flopr #(32) pc_reg(clk, reset, pc_next, pc);

// IF Instruction Fetch

logic [31:0] pc_plus4;
assign pc_plus4 = pc + 4;

// BATON ZONE: IF -> ID

logic [31:0] ID_instr, ID_pc, ID_pc_plus4;

flopr #(32) IFID_instr(clk, reset_or_flash, instr, ID_instr);
flopr #(32) IFID_pc(clk, reset_or_flash, pc, ID_pc);
flopr #(32) IFID_pc_plus4(clk, reset_or_flash, pc_plus4, ID_pc_plus4);

// ID Instruction Decode and register fetch

logic is_load_op, we3, ID_wem, is_branch_op;
logic [2:0] ID_rwmm;
logic [4:0] wa3;
logic [9:0] Op;
logic [31:0] Vj, Vk, rd1, rd2;

id id(.clk, .reset, .we3_in(WB_we3), .wa3_in(WB_wa3),
  .instr(ID_instr), .pc(ID_pc), .wd3_in(wd3),
  .is_load_op, .we3_out(we3), .wem(ID_wem), .is_branch_op, .rwmm(ID_rwmm),
  .wa3_out(wa3), .Op, .Vj, .Vk, .rd1, .rd2);

// BATON ZONE: ID -> EX

logic EX_is_load_op, EX_we3, EX_wem, EX_is_branch_op;
logic [2:0] EX_rwmm;
logic [4:0] EX_wa3;
logic [9:0] EX_Op;
logic [31:0] EX_Vj, EX_Vk, EX_rd1, EX_rd2, EX_pc_plus4;

flopr #(1) IDEX_is_load_op(clk, reset_or_flash, is_load_op, EX_is_load_op);
flopr #(1) IDEX_we3(clk, reset_or_flash, we3, EX_we3);
flopr #(1) IDEX_wem(clk, reset_or_flash, ID_wem, EX_wem);
flopr #(1) IDEX_is_branch_op(clk, reset_or_flash, is_branch_op, EX_is_branch_op);
flopr #(3) IDEX_rwmm(clk, reset_or_flash, ID_rwmm, EX_rwmm);
flopr #(5) IDEX_wa3(clk, reset_or_flash, wa3, EX_wa3);
flopr #(10) IDEX_Op(clk, reset_or_flash, Op, EX_Op);
flopr #(32) IDEX_Vj(clk, reset_or_flash, Vj, EX_Vj);
flopr #(32) IDEX_Vk(clk, reset_or_flash, Vk, EX_Vk);
flopr #(32) IDEX_rd1(clk, reset_or_flash, rd1, EX_rd1);
flopr #(32) IDEX_rd2(clk, reset_or_flash, rd2, EX_rd2);
flopr #(32) IDEX_pc_plus4(clk, reset_or_flash, ID_pc_plus4, EX_pc_plus4);

// EX EXecute

logic is_branched, reset_or_flash;
logic [31:0] pc_next, wdx, addr;

ex ex(.is_branch_op(EX_is_branch_op), .Op(EX_Op), .pc_plus4(EX_pc_plus4),
  .rd1(EX_rd1), .rd2(EX_rd2), .Vj(EX_Vj), .Vk(EX_Vk), .is_branched, .wdx, .addr);

assign reset_or_flash = reset | is_branched;
mux2 #(32) select_pc_next(pc_plus4, addr, is_branched, pc_next);

// BATON ZONE: EX -> MA

logic MA_we3, MA_wem, MA_is_load_op;
logic [2:0] MA_rwmm;
logic [4:0] MA_wa3;
logic [31:0] MA_wdx, MA_rd2;

flopr #(1) EXMA_we3(clk, reset, EX_we3, MA_we3);
flopr #(1) EXMA_wem(clk, reset, EX_wem, MA_wem);
flopr #(1) EXMA_is_load_op(clk, reset, EX_is_load_op, MA_is_load_op);
flopr #(3) EXMA_rwmm(clk, reset, EX_rwmm, MA_rwmm);
flopr #(5) EXMA_wa3(clk, reset, EX_wa3, MA_wa3);
flopr #(32) EXMA_wdx(clk, reset, wdx, MA_wdx);
flopr #(32) EXMA_rd2(clk, reset, EX_rd2, MA_rd2);

// MA Memory Access

assign wem = MA_wem;
assign rwmm = MA_rwmm;
assign rwam = MA_wdx;
assign wdm = MA_rd2;

// BATON ZONE: MA -> WB

logic WB_we3, WB_is_load_op;
logic [4:0] WB_wa3;
logic [31:0] WB_wdx, WB_rdm;

flopr #(1) MAWB_we3(clk, reset, MA_we3, WB_we3);
flopr #(1) MAWB_is_load_op(clk, reset, MA_is_load_op, WB_is_load_op);
flopr #(5) MAWB_wa3(clk, reset, MA_wa3, WB_wa3);
flopr #(32) MAWB_wdx(clk, reset, MA_wdx, WB_wdx);
flopr #(32) MAWB_rdm(clk, reset, rdm, WB_rdm);

// WB Write-Back

logic [31:0] wd3;

mux2 #(32) select_wd3(WB_wdx, WB_rdm, WB_is_load_op, wd3);

endmodule
