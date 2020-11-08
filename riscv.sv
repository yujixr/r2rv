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

logic is_branch_op, is_load_op, is_store_op;
logic [2:0] ID_rwmm;
logic [4:0] Dest;
logic [9:0] Op;
logic [31:0] Vj, Vk, A;

id id(.clk, .reset, .wa3, .instr(ID_instr), .pc(ID_pc), .wd3,
  .is_branch_op, .is_load_op, .is_store_op, .rwmm(ID_rwmm),
  .Dest, .Op, .Vj, .Vk, .A);

// BATON ZONE: ID -> EX

logic EX_is_load_op, EX_is_store_op, EX_is_branch_op;
logic [2:0] EX_rwmm;
logic [4:0] EX_Dest;
logic [9:0] EX_Op;
logic [31:0] EX_Vj, EX_Vk, EX_A, EX_pc_plus4;

flopr #(1) IDEX_is_branch_op(clk, reset_or_flash, is_branch_op, EX_is_branch_op);
flopr #(1) IDEX_is_load_op(clk, reset_or_flash, is_load_op, EX_is_load_op);
flopr #(1) IDEX_is_store_op(clk, reset_or_flash, is_store_op, EX_is_store_op);
flopr #(3) IDEX_rwmm(clk, reset_or_flash, ID_rwmm, EX_rwmm);
flopr #(5) IDEX_Dest(clk, reset_or_flash, Dest, EX_Dest);
flopr #(10) IDEX_Op(clk, reset_or_flash, Op, EX_Op);
flopr #(32) IDEX_Vj(clk, reset_or_flash, Vj, EX_Vj);
flopr #(32) IDEX_Vk(clk, reset_or_flash, Vk, EX_Vk);
flopr #(32) IDEX_A(clk, reset_or_flash, A, EX_A);
flopr #(32) IDEX_pc_plus4(clk, reset_or_flash, ID_pc_plus4, EX_pc_plus4);

// EX EXecute

logic is_branched, reset_or_flash;
logic [31:0] pc_next, wdx;

ex ex(.is_branch_op(EX_is_branch_op), .Op(EX_Op), .pc_plus4(EX_pc_plus4),
  .Vj(EX_Vj), .Vk(EX_Vk), .is_branched, .wdx);

assign reset_or_flash = reset | is_branched;
mux2 #(32) select_pc_next(pc_plus4, { EX_A[31:1], 1'b0 }, is_branched, pc_next);

// BATON ZONE: EX -> MA

logic MA_is_load_op, MA_is_store_op;
logic [2:0] MA_rwmm;
logic [4:0] MA_Dest;
logic [31:0] MA_wdx, MA_Vk, MA_A;

flopr #(1) EXMA_is_load_op(clk, reset, EX_is_load_op, MA_is_load_op);
flopr #(1) EXMA_is_store_op(clk, reset, EX_is_store_op, MA_is_store_op);
flopr #(3) EXMA_rwmm(clk, reset, EX_rwmm, MA_rwmm);
flopr #(5) EXMA_Dest(clk, reset, EX_Dest, MA_Dest);
flopr #(32) EXMA_wdx(clk, reset, wdx, MA_wdx);
flopr #(32) EXMA_Vk(clk, reset_or_flash, EX_Vk, MA_Vk);
flopr #(32) EXMA_A(clk, reset_or_flash, EX_A, MA_A);

// MA Memory Access

assign wem = MA_is_store_op;
assign rwmm = MA_rwmm;
assign rwam = MA_A;
assign wdm = MA_Vk;

// BATON ZONE: MA -> WB

logic WB_is_load_op;
logic [4:0] WB_Dest;
logic [31:0] WB_wdx, WB_rdm;

flopr #(1) MAWB_is_load_op(clk, reset, MA_is_load_op, WB_is_load_op);
flopr #(5) MAWB_Dest(clk, reset, MA_Dest, WB_Dest);
flopr #(32) MAWB_wdx(clk, reset, MA_wdx, WB_wdx);
flopr #(32) MAWB_rdm(clk, reset, rdm, WB_rdm);

// WB Write-Back

logic [4:0] wa3;
logic [31:0] wd3;

assign wa3 = WB_Dest;

mux2 #(32) select_wd3(WB_wdx, WB_rdm, WB_is_load_op, wd3);

endmodule
