module regfile(
  input logic clk, reset,
  input logic [4:0] ra[4], wa[2],
  input logic [31:0] wd[2],
  output logic [31:0] rd[4]
);

parameter REG_SIZE = 32;

// x0 is always zero.
logic [31:0] rf[REG_SIZE-1:1], d[REG_SIZE-1:1];

genvar i;
generate
  for (i = 1; i < REG_SIZE; i++) begin: Reg
    always_comb
      if (wa[0] == i) begin
        d[i] = wd[0];
      end
      else if (wa[1] == i) begin
        d[i] = wd[1];
      end
      else begin
        d[i] = rf[i];
      end

    flopr #(32) ff(.clk, .reset, .d(d[i]), .q(rf[i]));
  end
endgenerate

genvar j;
generate
  for (j = 0; j < 4; j++) begin: Read
    assign rd[j] = rf[ra[j]];
  end
endgenerate

endmodule
