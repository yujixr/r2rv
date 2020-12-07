module clk_divider(
  input logic clk,
  output logic divided_clk
);

logic cntend;
logic [25:0] cnt;

assign cntend = (cnt==26'd24_999_999);

always_ff @(posedge clk)
  if(cntend)
    cnt <= 26'd0;
  else
    cnt <= cnt + 26'd1;

always_ff @(posedge clk)
  if(cntend)
    divided_clk <= ~(divided_clk);
  else
    divided_clk <= divided_clk;

endmodule
