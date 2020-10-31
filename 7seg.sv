module hex_display(
  input logic [3:0] src,
  output logic [6:0] segment
);

always_comb
  case(src)
    4'h0: segment = 7'b0000001;
    4'h1: segment = 7'b1001111;
    4'h2: segment = 7'b0010010;
    4'h3: segment = 7'b0000110;
    4'h4: segment = 7'b1001100;
    4'h5: segment = 7'b0100100;
    4'h6: segment = 7'b0100000;
    4'h7: segment = 7'b0001111;
    4'h8: segment = 7'b0000000;
    4'h9: segment = 7'b0000100;
    4'ha: segment = 7'b0001000;
    4'hb: segment = 7'b1100000;
    4'hc: segment = 7'b0110001;
    4'hd: segment = 7'b1000010;
    4'he: segment = 7'b0110000;
    4'hf: segment = 7'b0111000;
    default: segment = 7'b1111111;
  endcase

endmodule
