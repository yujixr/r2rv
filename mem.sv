module dmem(
  input logic clk, we,
  input logic [31:0] a, wd,
  output logic [31:0] rd,
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

logic [31:0] RAM[63:0];

assign rd = RAM[a[31:2]];

always_ff @(posedge clk)
  if (we) RAM[a[31:2]] <= wd;

hex_display hex5(RAM[0][23:20], HEX5);
hex_display hex4(RAM[0][19:16], HEX4);
hex_display hex3(RAM[0][15:12], HEX3);
hex_display hex2(RAM[0][11:8], HEX2);
hex_display hex1(RAM[0][7:4], HEX1);
hex_display hex0(RAM[0][3:0], HEX0);

endmodule

module imem(
  input logic [5:0] a,
  output logic [31:0] rd
);

logic [31:0] RAM[63:0];

initial
  $readmemh("memfile.dat",RAM);

assign rd = RAM[a];

endmodule
