module hex_display(
  input logic [3:0] src,
  output logic [6:0] segment
);

always_comb
  case(src)
    4'h0: segment = 7'b1111110;
    4'h1: segment = 7'b0110000;
    4'h2: segment = 7'b1101101;
    4'h3: segment = 7'b1111001;
    4'h4: segment = 7'b0110011;
    4'h5: segment = 7'b1011011;
    4'h6: segment = 7'b1011111;
    4'h7: segment = 7'b1110000;
    4'h8: segment = 7'b1111111;
    4'h9: segment = 7'b1111011;
    4'ha: segment = 7'b1110111;
    4'hb: segment = 7'b0011111;
    4'hc: segment = 7'b1001110;
    4'hd: segment = 7'b0111101;
    4'he: segment = 7'b1001111;
    4'hf: segment = 7'b1000111;
    default: segment = 7'b0000000;
  endcase

endmodule
