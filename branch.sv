module branch(
  input logic [31:0] src1, src2,
  input logic [2:0] funct,
  output logic result
);

function cmp_signed(input [31:0] src1, src2);
begin
  if(src1[31])
  begin
    if(src2[31])
    cmp_signed = src1 > src2;
    else
    cmp_signed = 1;
  end
  else
  begin
    if(src2[31])
    cmp_signed = 1;
    else
    cmp_signed = src1 < src2;
  end
end
endfunction

always_comb
  case(funct)
    3'b000: result = (src1 == src2);            // BEQ
    3'b001: result = (src1 != src2);            // BNE
    3'b100: result = cmp_signed(src1, src2);    // BLT
    3'b101: result = ~cmp_signed(src1, src2);   // BGE
    3'b110: result = src1 < src2;               // BLTU
    3'b111: result = src1 >= src2;              // BGEU
    default: result = 0;
  endcase

endmodule
