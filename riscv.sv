// R: Read, W: Write, RW: Read-Write
// D: Data, A: Address, E: Enabler-signal
// 1...3: regfile1...3, M: Memory

module riscv(
  input logic clk, reset,
  output logic [31:0] pc,
  input logic [31:0] instr,
  output logic wem,
  output logic [31:0] rwam, wdm,
  input logic [31:0] rdm
);

// IF Instruction Fetch

logic [31:0] pc_next, pc_plus4;
assign pc_plus4 = pc + 4;

flopr #(32) pc_reg(clk, reset, pc_next, pc);

// ID Instruction Decode

logic src1_selector, src2_selector, wd3_selector, we3, funct7;
logic [2:0] funct3;
logic [4:0] ra1, ra2, wa3;
logic [31:0] imm, rd1, rd2, wd3;

decoder decode(instr, src1_selector, src2_selector, wd3_selector, we3, wem, funct7, funct3, ra1, ra2, wa3, imm);

regfile rf(clk, we3, ra1, ra2, wa3, rd1, rd2, wd3);

// EX EXecute

logic pc_selector;
logic [31:0] src1, src2, alu_result;

mux2 #(32) select_src1(rd1, pc_plus4, src1_selector, src1);
mux2 #(32) select_src2(rd2, imm, src2_selector, src2);

alu alu(src1, src2, { funct7, funct3 }, alu_result);
branch br(rd1, rd2, funct3, pc_selector);

// MA Memory Access

assign rwam = alu_result;
assign wdm = rd2;

mux2 #(32) select_pc_next(pc_plus4, alu_result, pc_selector, pc_next);

// WB Write-Back

mux2 #(32) select_wd3(alu_result, rdm, wd3_selector, wd3);

endmodule
