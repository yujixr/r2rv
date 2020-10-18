module mem(
  input logic clk, we,
  input logic [31:0] ra1, ra2, wa3, wd3,
  output logic [31:0] rd1, rd2,
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

logic [7:0] RAM[511:0];

initial
  $readmemh("memfile.dat",RAM);

assign rd1 = RAM[ra1[8:0]];
assign rd2 = RAM[ra2[8:0]];

always_ff @(posedge clk)
  if (we) RAM[wa3[8:0]] <= wd3;

hex_display hex5(RAM[511][7:4], HEX5);
hex_display hex4(RAM[511][3:0], HEX4);
hex_display hex3(RAM[510][7:4], HEX3);
hex_display hex2(RAM[510][3:0], HEX2);
hex_display hex1(RAM[509][7:4], HEX1);
hex_display hex0(RAM[509][3:0], HEX0);

endmodule
