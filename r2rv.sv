module r2rv(
  input logic clk, reset, 
  input logic [9:0] sw,
  input logic [2:0] key,
  output logic [9:0] led
);

  assign led = sw & ~key[0] & ~key[1] & ~key[2];

  logic [31:0] pc, instr;
  logic enabler_write;
  logic [31:0] address, data_write, data_read;

  riscv riscv(clk, reset, pc, instr, enabler_write, address, data_write, data_read);
  imem imem(pc[7:2], instr);
  dmem dmem(clk, enabler_write, address, data_write, data_read);

endmodule
