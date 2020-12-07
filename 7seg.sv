module hex_display(
  input logic [3:0] src,
  output logic [6:0] segment
);

always_comb
  case(src)
	4'h1: segment = 7'b1111001;		// ---t----
	4'h2: segment = 7'b0100100;		// |	  |
	4'h3: segment = 7'b0110000; 	// lt	 rt
	4'h4: segment = 7'b0011001; 	// |	  |
	4'h5: segment = 7'b0010010; 	// ---m----
	4'h6: segment = 7'b0000010; 	// |	  |
	4'h7: segment = 7'b1111000; 	// lb	 rb
	4'h8: segment = 7'b0000000; 	// |	  |
	4'h9: segment = 7'b0011000; 	// ---b----
	4'ha: segment = 7'b0001000;
	4'hb: segment = 7'b0000011;
	4'hc: segment = 7'b1000110;
	4'hd: segment = 7'b0100001;
	4'he: segment = 7'b0000110;
	4'hf: segment = 7'b0001110;
	4'h0: segment = 7'b1000000;
  endcase

endmodule


module display(
  input logic [31:0] stdout,
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

hex_display hex2023(.src(stdout[23:20]), .segment(HEX5));
hex_display hex1619(.src(stdout[19:16]), .segment(HEX4));
hex_display hex1215(.src(stdout[15:12]), .segment(HEX3));
hex_display hex0811(.src(stdout[11:8]), .segment(HEX2));
hex_display hex0407(.src(stdout[7:4]), .segment(HEX1));
hex_display hex0003(.src(stdout[3:0]), .segment(HEX0));

endmodule
