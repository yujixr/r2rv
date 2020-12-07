module display(
  input logic clk,
  input logic [9:0] SW,
  input logic [31:0] outputs[10],
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

logic [31:0] stdout;

always_comb
  if (SW[0]) stdout = outputs[0];
  else if (SW[1]) stdout = outputs[1];
  else if (SW[2]) stdout = outputs[2];
  else if (SW[3]) stdout = outputs[3];
  else if (SW[4]) stdout = outputs[4];
  else if (SW[5]) stdout = outputs[5];
  else if (SW[6]) stdout = outputs[6];
  else if (SW[7]) stdout = outputs[7];
  else if (SW[8]) stdout = outputs[8];
  else if (SW[9]) stdout = outputs[9];
  else stdout = clk;

hex_display hex2023(.src(stdout[23:20]), .segment(HEX5));
hex_display hex1619(.src(stdout[19:16]), .segment(HEX4));
hex_display hex1215(.src(stdout[15:12]), .segment(HEX3));
hex_display hex0811(.src(stdout[11:8]), .segment(HEX2));
hex_display hex0407(.src(stdout[7:4]), .segment(HEX1));
hex_display hex0003(.src(stdout[3:0]), .segment(HEX0));

endmodule
