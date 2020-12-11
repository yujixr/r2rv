parameter RAM_SIZE_LOG = 8;
parameter RAM_SIZE = 2**RAM_SIZE_LOG;

module writer(
  input logic clk,
  input logic [31:0] RAM_READ[RAM_SIZE-1:0],
  output logic [31:0] RAM_WRITE[RAM_SIZE-1:0],
  input logic enabler,
  input ldst_mode_t mode,
  input logic [31:0] addr, data
);

genvar i;
generate
  for (i = 0; i < RAM_SIZE; i++) begin: Update
    always_ff @(posedge clk)
      if ((addr[RAM_SIZE_LOG+1:2]==i) & enabler)
        RAM_WRITE[i] <= data;
      else
        RAM_WRITE[i] <= RAM_READ[i];
  end
endgenerate

endmodule


module reader(
  input logic [31:0] RAM[RAM_SIZE-1:0],
  input ldst_mode_t mode,
  input logic [31:0] addr,
  output logic [31:0] data
);

assign data = RAM[addr[RAM_SIZE_LOG+1:2]];

endmodule


module mem(
  input logic clk, we,
  input logic [31:0] ra[4], wa, wd,
  input ldst_mode_t rm[4], wm,
  output logic [31:0] rd[4], stdout
);

logic [31:0] imem[RAM_SIZE-1:0], dmem[RAM_SIZE-1:0];

initial begin
  $readmemh("imem.dat", imem);
  $readmemh("dmem.dat", dmem);
end

genvar i;
generate
  for (i = 0; i < 2; i++) begin: readers
    reader iread(.RAM(imem), .mode(rm[i]), .addr(ra[i]), .data(rd[i]));
    reader dread(.RAM(dmem), .mode(rm[2+i]), .addr(ra[2+i]), .data(rd[2+i]));
  end
endgenerate

writer write(.clk, .RAM_READ(dmem), .RAM_WRITE(dmem), .enabler(we), .mode(wm), .addr(wa), .data(wd));

assign stdout = dmem['h3f];

endmodule
