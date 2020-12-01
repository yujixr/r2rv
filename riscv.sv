// R: Read, W: Write, RW: Read-Write
// D: Data, A: Address, M: access Mode, E: Enabler-signal
// 1...3: regfile1...3, M: Memory

module riscv(
  input logic clk, reset,
  output logic [31:0] pc,
  input logic [31:0] instr,
  output logic wem,
  output ldst_mode rwmm,
  output logic [31:0] rwam, wdm,
  input logic [31:0] rdm
);

// BATON ZONE: EX -> IF

flopr #(32) pc_reg(clk, reset, pc_next, pc);

// IF Instruction Fetch

logic [31:0] pc_plus4;
assign pc_plus4 = pc + 4;

// BATON ZONE: IF -> ID

logic [31:0] ID_instr, ID_pc;

flopr #(32) IFID_instr(clk, reset_or_flash, instr, ID_instr);
flopr #(32) IFID_pc(clk, reset_or_flash, pc, ID_pc);

// ID Instruction Decode and register fetch

unit Unit;
ldst_mode ID_rwmm;
logic [4:0] Dest;
logic [9:0] Op;
logic [31:0] Vj, Vk, A;

id id(.clk, .reset, .wa3, .instr(ID_instr), .pc(ID_pc), .wd3,
  .Unit, .rwmm(ID_rwmm), .Dest, .Op, .Vj, .Vk, .A);

// BATON ZONE: ID -> EX

unit EX_Unit;
ldst_mode EX_rwmm;
logic [4:0] EX_Dest;
logic [9:0] EX_Op;
logic [31:0] EX_Vj, EX_Vk, EX_A, EX_pc;

flopr #(3) IDEX_Unit(clk, reset_or_flash, Unit, EX_Unit);
flopr #(3) IDEX_rwmm(clk, reset_or_flash, ID_rwmm, EX_rwmm);
flopr #(5) IDEX_Dest(clk, reset_or_flash, Dest, EX_Dest);
flopr #(10) IDEX_Op(clk, reset_or_flash, Op, EX_Op);
flopr #(32) IDEX_Vj(clk, reset_or_flash, Vj, EX_Vj);
flopr #(32) IDEX_Vk(clk, reset_or_flash, Vk, EX_Vk);
flopr #(32) IDEX_A(clk, reset_or_flash, A, EX_A);
flopr #(32) IDEX_pc(clk, reset_or_flash, ID_pc, EX_pc);

// EX EXecute & memory access

logic is_branched, reset_or_flash;
logic [31:0] pc_next, result;

ex ex(.Unit(EX_Unit), .Op(EX_Op), .pc(EX_pc),
  .rdm, .Vj(EX_Vj), .Vk(EX_Vk), .is_branched, .result);

assign wem = (EX_Unit==STORE);
assign rwmm = EX_rwmm;
assign rwam = EX_A;
assign wdm = EX_Vk;

assign reset_or_flash = reset | is_branched;
mux2 #(32) select_pc_next(pc_plus4, { EX_A[31:1], 1'b0 }, is_branched, pc_next);

// BATON ZONE: EX -> WB

logic [4:0] WB_Dest;
logic [31:0] WB_result;

flopr #(5) EXWB_Dest(clk, reset, EX_Dest, WB_Dest);
flopr #(32) EXWB_result(clk, reset, result, WB_result);

// WB Write-Back

logic [4:0] wa3;
logic [31:0] wd3;

assign wa3 = WB_Dest;
assign wd3 = WB_result;

endmodule
