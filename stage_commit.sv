module commit(
  input logic is_tag_flooded,
  input entry_t entries[BUF_SIZE],
  output bool is_valid[2], is_store[2], store_enable,
  output tag_t tags[2],
  output ldst_mode_t store_mode,
  output logic [4:0] reg_addr[2],
  output logic [31:0] store_addr, store_data, reg_data[2]
);

bool is_2nd_valid, is_2nd_store;

always_comb
  if (is_tag_flooded) begin
    tags[0] = { 1'b1, entries[0].tag[BUF_SIZE_LOG-1:0] };
    tags[1] = { 1'b1, entries[1].tag[BUF_SIZE_LOG-1:0] };
  end
  else begin
    tags[0] = entries[0].tag;
    tags[1] = entries[1].tag;
  end

always_comb
  if (entries[0].e_state == S_EXECUTED) begin
    is_valid[0] = true;
    reg_addr[0] = entries[0].Dest;
    reg_data[0] = entries[0].result;
    is_store[0] = bool'(entries[0].Unit == STORE);
  end
  else begin
    is_valid[0] = false;
    reg_addr[0] = '0;
    reg_data[0] = '0;
    is_store[0] = false;
  end

assign is_2nd_valid = bool'(entries[1].e_state == S_EXECUTED);
assign is_2nd_store = bool'(entries[1].Unit == STORE);

always_comb
  if (is_2nd_valid && (!is_store[0] || !is_2nd_store)) begin
    is_valid[1] = true;
    reg_addr[1] = entries[1].Dest;
    reg_data[1] = entries[1].result;
    is_store[1] = is_2nd_store;
  end
  else begin
    is_valid[1] = false;
    reg_addr[1] = '0;
    reg_data[1] = '0;
    is_store[1] = false;
  end

always_comb
  if (is_store[0]) begin
    store_enable = true;
    store_mode = entries[0].rwmm;
    store_addr = entries[0].A;
    store_data = entries[0].Vk;
  end
  else if (is_store[1]) begin
    store_enable = true;
    store_mode = entries[1].rwmm;
    store_addr = entries[1].A;
    store_data = entries[1].Vk;
  end
  else begin
    store_enable = false;
    store_mode = WORD;
    store_addr = 32'b0;
    store_data = 32'b0;
  end

endmodule
