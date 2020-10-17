module mem(
  input logic clk, we,
  input logic [6:0] ra1, ra2, wa3,
  input logic [31:0] wd3,
  output logic [31:0] rd1, rd2,
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

logic [31:0] RAM[127:0];

initial
  $readmemh("memfile.dat",RAM);

assign rd1 = RAM[ra1];
assign rd2 = RAM[ra2];

always_ff @(posedge clk)
  if (we) RAM[wa3] <= wd3;

hex_display hex5(RAM[127][23:20], HEX5);
hex_display hex4(RAM[127][19:16], HEX4);
hex_display hex3(RAM[127][15:12], HEX3);
hex_display hex2(RAM[127][11:8], HEX2);
hex_display hex1(RAM[127][7:4], HEX1);
hex_display hex0(RAM[127][3:0], HEX0);

endmodule
