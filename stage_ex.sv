typedef struct packed {
  logic is_valid;
  ex_mode_t mode;
  logic is_branch_established;
  logic [5:0] speculative_tag;
  logic [31:0] result, jumped_to;
  tag_t tag;
} ex_result_t;

module ex(
  input is_tag_flooded,
  input ex_content_t ex_contents[2],
  input logic [31:0] load_data[2],
  output ldst_mode_t load_mode[2],
  output logic [31:0] load_addr[2], jumped_to,
  output logic is_branch_established,
  output ex_result_t results[2]
);

logic _is_branch_established[2];
logic [31:0] alu_result[2], mul_result[2], div_result[2];

genvar i;
generate
  for (i = 0; i < 2; i++) begin: execute
    assign load_mode[i] = ex_contents[i].rm;
    assign load_addr[i] = ex_contents[i].A;

    assign results[i].is_valid        = ex_contents[i].is_valid;
    assign results[i].mode            = ex_contents[i].mode;
    assign results[i].speculative_tag = ex_contents[i].speculative_tag;
    assign results[i].jumped_to       = ex_contents[i].A;

    always_comb
      if (is_tag_flooded) begin
        results[i].tag = { 1'b1, ex_contents[i].tag[BUF_SIZE_LOG-1:0] };
      end
      else begin
        results[i].tag = ex_contents[i].tag;
      end

    alu alu(.Vj(ex_contents[i].Vj), .Vk(ex_contents[i].Vk), .Op(ex_contents[i].Op), .y(alu_result[i]));
    mul mul(.Vj(ex_contents[i].Vj), .Vk(ex_contents[i].Vk), .Op(ex_contents[i].Op), .y(mul_result[i]));
    div div(.Vj(ex_contents[i].Vj), .Vk(ex_contents[i].Vk), .Op(ex_contents[i].Op), .y(div_result[i]));
    branch br(.Vj(ex_contents[i].Vj), .Vk(ex_contents[i].Vk), .Op(ex_contents[i].Op), .y(_is_branch_established[i]));

    result_switcher switch(.Unit(ex_contents[i].Unit),
      .alu_result(alu_result[i]),
      .mul_result(mul_result[i]),
      .div_result(div_result[i]),
      .pc_plus4(ex_contents[i].pc + 4),
      .rdm(load_data[i]),
      .result(results[i].result)
    );

    assign results[i].is_branch_established = (ex_contents[i].Unit == BRANCH) & (ex_contents[i].mode == EX_NORMAL) & _is_branch_established[i];
  end
endgenerate

always_comb
  if (results[1].is_branch_established) begin
    is_branch_established = 1;
    jumped_to = results[1].jumped_to;
  end
  else if (results[0].is_branch_established) begin
    is_branch_established = 1;
    jumped_to = results[0].jumped_to;
  end
  else begin
    is_branch_established = 0;
    jumped_to = 32'b0;
  end

endmodule


module result_switcher(
  input unit_t Unit,
  input logic [31:0] alu_result, mul_result, div_result, pc_plus4, rdm,
  output logic [31:0] result
);

always_comb
  case (Unit)
    ALU:     result = alu_result;
    BRANCH:  result = pc_plus4;
    MUL:     result = mul_result;
    DIV:     result = div_result;
    LOAD:    result = rdm;
    default: result = 32'b0;
  endcase

endmodule
