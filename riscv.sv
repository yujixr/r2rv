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

logic [31:0] ID_instr, ID_pc_plus4;

flopr #(32) IFID_instr(clk, reset_or_flash, instr, ID_instr);
flopr #(32) IFID_pc_plus4(clk, reset_or_flash, pc_plus4, ID_pc_plus4);

// ID Instruction Decode and register fetch

logic src1_selector, src2_selector, wd3_selector, we3, ID_wem, is_branch_op;
logic [2:0] funct3;
logic [6:0] funct7;
logic [4:0] wa3;
logic [31:0] imm, rd1, rd2;

id id(.clk, .reset, .instr(ID_instr),
  .we3_in(WB_we3), .wa3_in(WB_wa3), .wd3_in(wd3),
  .src1_selector, .src2_selector, .wd3_selector, .we3_out(we3), .wem(ID_wem),
  .is_branch_op, .funct3, .funct7, .wa3_out(wa3), .imm, .rd1, .rd2);

// BATON ZONE: ID -> EX

logic EX_src1_selector, EX_src2_selector, EX_wd3_selector,
      EX_we3, EX_wem, EX_is_branch_op;
logic [2:0] EX_funct3;
logic [6:0] EX_funct7;
logic [4:0] EX_wa3;
logic [31:0] EX_imm, EX_rd1, EX_rd2, EX_pc_plus4;

flopr #(1) IDEX_src1_selector(clk, reset_or_flash, src1_selector, EX_src1_selector);
flopr #(1) IDEX_src2_selector(clk, reset_or_flash, src2_selector, EX_src2_selector);
flopr #(1) IDEX_wd3_selector(clk, reset_or_flash, wd3_selector, EX_wd3_selector);
flopr #(1) IDEX_we3(clk, reset_or_flash, we3, EX_we3);
flopr #(1) IDEX_is_branch_op(clk, reset_or_flash, is_branch_op, EX_is_branch_op);
flopr #(1) IDEX_wem(clk, reset_or_flash, ID_wem, EX_wem);
flopr #(3) IDEX_funct3(clk, reset_or_flash, funct3, EX_funct3);
flopr #(7) IDEX_funct7(clk, reset_or_flash, funct7, EX_funct7);
flopr #(5) IDEX_wa3(clk, reset_or_flash, wa3, EX_wa3);
flopr #(32) IDEX_imm(clk, reset_or_flash, imm, EX_imm);
flopr #(32) IDEX_rd1(clk, reset_or_flash, rd1, EX_rd1);
flopr #(32) IDEX_rd2(clk, reset_or_flash, rd2, EX_rd2);
flopr #(32) IDEX_pc_plus4(clk, reset_or_flash, ID_pc_plus4, EX_pc_plus4);

// EX EXecute

logic is_branched, reset_or_flash;
logic [31:0] ex_result, pc_next;

ex ex(.pc_plus4(EX_pc_plus4),
  .src1_selector(EX_src1_selector), .src2_selector(EX_src2_selector),
  .is_branch_op(EX_is_branch_op), .funct3(EX_funct3), .funct7(EX_funct7),
  .imm(EX_imm), .rd1(EX_rd1), .rd2(EX_rd2), .ex_result, .is_branched);

assign reset_or_flash = reset | is_branched;
mux2 #(32) select_pc_next(pc_plus4, ex_result, is_branched, pc_next);

// BATON ZONE: EX -> MA

logic MA_we3, MA_wem, MA_wd3_selector;
logic [2:0] MA_funct3;
logic [4:0] MA_wa3;
logic [31:0] MA_ex_result, MA_rd2;

flopr #(1) EXMA_we3(clk, reset, EX_we3, MA_we3);
flopr #(1) EXMA_wem(clk, reset, EX_wem, MA_wem);
flopr #(1) EXMA_wd3_selector(clk, reset, EX_wd3_selector, MA_wd3_selector);
flopr #(3) EXMA_funct3(clk, reset, EX_funct3, MA_funct3);
flopr #(5) EXMA_wa3(clk, reset, EX_wa3, MA_wa3);
flopr #(32) EXMA_ex_result(clk, reset, ex_result, MA_ex_result);
flopr #(32) EXMA_rd2(clk, reset, EX_rd2, MA_rd2);

// MA Memory Access

assign wem = MA_wem;
assign rwmm = MA_funct3;
assign rwam = MA_ex_result;
assign wdm = MA_rd2;

// BATON ZONE: MA -> WB

logic WB_we3, WB_wd3_selector;
logic [4:0] WB_wa3;
logic [31:0] WB_ex_result, WB_rdm;

flopr #(1) MAWB_we3(clk, reset, MA_we3, WB_we3);
flopr #(1) MAWB_wd3_selector(clk, reset, MA_wd3_selector, WB_wd3_selector);
flopr #(5) MAWB_wa3(clk, reset, MA_wa3, WB_wa3);
flopr #(32) MAWB_ex_result(clk, reset, MA_ex_result, WB_ex_result);
flopr #(32) MAWB_rdm(clk, reset, rdm, WB_rdm);

// WB Write-Back

logic [31:0] wd3;

mux2 #(32) select_wd3(WB_ex_result, WB_rdm, WB_wd3_selector, wd3);

endmodule
