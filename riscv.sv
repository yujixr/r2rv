module riscv(
  input logic clk, reset,

  // Memory Bus
  // R: Read, W: Write
  // D: Data, A: Address, M: Mode, E: Enable
  input logic [31:0] rd[4],
  output logic we,
  output logic [31:0] ra[4], wa, wd, outputs[10],
  output ldst_mode rm[4], wm
);

entry tmp1, tmp2, tmp3;
decode_result tmp4;
assign tmp1 = entries[14];
assign tmp2 = entries[15];
assign tmp3 = DI_entries_new[0];
assign tmp4 = DI_decoded[0];
assign outputs[0] = pc[0];
assign outputs[1] = tmp1.e_state;
assign outputs[2] = tmp2.e_state;
assign outputs[3] = allocation_indexes[0];
assign outputs[4] = allocation_indexes[1];
assign outputs[5] = is_valid_allocation[0];
assign outputs[6] = is_valid_allocation[1];
assign outputs[7] = tmp4.is_valid;
assign outputs[8] = tmp3.tag;
assign outputs[9] = tmp3.speculative_tag;

// Data Storage
entry entries[BUF_SIZE];

regfile rf(
  .clk, .reset, .ra(reg_read_addr),
  .wa(reg_write_addr), .wd(reg_write_data), .rd(reg_read_data)
);

buffer bf(
  .clk, .reset, .is_valid_allocation, .is_tag_flooded,
  .allocation_indexes, .entries_new(DI_entries_new), .ex_contents(WU_ex_contents), .results(BF_results),
  .is_really_commited, .is_commited_store(is_store), .commited_tags(CM_tags), .entries
);

// Instruction Fetch
logic [31:0] pc[2], instr[2], pc_next;

fetch STAGE_IF(
  .clk, .reset, .can_proceed(is_valid_allocation),
  .is_branch_established, .jumped_to, .pc, .pc_next
);

assign ra[0] = pc[0];
assign ra[1] = pc[1];
assign rm[0] = WORD;
assign rm[1] = WORD;
assign instr[0] = rd[0];
assign instr[1] = rd[1];

// IF -> ID
logic ID_is_valid[2];
logic [31:0] ID_instr[2], ID_pc[2];
twinflop #(1) IFID_is_valid(.clk, .reset(flash), .can_proceed, .in(can_proceed), .out(ID_is_valid));
twinflop #(32) IFID_instr(.clk, .reset(flash), .can_proceed, .in(instr), .out(ID_instr));
twinflop #(32) IFID_pc(.clk, .reset(flash), .can_proceed, .in(pc), .out(ID_pc));

// Instruction Decode
decode_result decoded[2];

id STAGE_ID(.is_valid(ID_is_valid), .instr(ID_instr), .pc(ID_pc), .decoded);

// ID -> DI
decode_result DI_decoded[2];
twinflop #($bits(decode_result)) IDDI_decoded(.clk, .reset(flash), .can_proceed, .in(decoded), .out(DI_decoded));

// Dispatch
logic is_valid_allocation[2], can_proceed[2], is_tag_flooded;
logic [4:0] reg_read_addr[4];
logic [31:0] reg_read_data[4];
logic [BUF_SIZE_LOG-1:0] allocation_indexes[2];
entry DI_entries_new[2];

dispatch STAGE_DI(
  .entries_all(entries), .reg_data(reg_read_data), .decoded(DI_decoded),
  .is_valid(is_valid_allocation), .is_allocatable(can_proceed), .is_tag_flooded, .reg_addr(reg_read_addr), 
  .entries_new(DI_entries_new), .indexes(allocation_indexes)
);

// Wakeup
ex_content WU_ex_contents[2];

wakeup STAGE_WU(.is_tag_flooded, .entries, .ex_contents(WU_ex_contents));

// WU -> EX
ex_content EX_ex_contents[2];
flopr #($bits(ex_content)) WUEX_ex_contents_1(.clk, .reset(flash), .d(WU_ex_contents[0]), .q(EX_ex_contents[0]));
flopr #($bits(ex_content)) WUEX_ex_contents_2(.clk, .reset(flash), .d(WU_ex_contents[1]), .q(EX_ex_contents[1]));

// Execute
logic is_branch_established, flash;
logic [31:0] load_addr[2], load_data[2], jumped_to;
ldst_mode load_mode[2];
ex_result results[2];

ex STAGE_EX(
  .is_tag_flooded, .ex_contents(EX_ex_contents), .load_data,
  .load_mode, .load_addr, .is_branch_established, .jumped_to, .results
);

assign ra[2] = load_addr[0];
assign ra[3] = load_addr[1];
assign rm[2] = load_mode[0];
assign rm[3] = load_mode[1];
assign load_data[0] = rd[2];
assign load_data[1] = rd[3];
assign flash = reset | is_branch_established;

// EX -> BF
ex_result BF_results[2];
flopr #($bits(ex_result)) EXBF_results_1(.clk, .reset, .d(results[0]), .q(BF_results[0]));
flopr #($bits(ex_result)) EXBF_results_2(.clk, .reset, .d(results[1]), .q(BF_results[1]));

// Commit
logic is_really_commited[2], is_store[2], store_enable;
logic [4:0] reg_write_addr[2];
logic [31:0] store_addr, store_data, reg_write_data[2];
logic [BUF_SIZE_LOG:0] CM_tags[2];
ldst_mode store_mode;

commit STAGE_CM(
  .is_tag_flooded, .entries, .is_valid(is_really_commited), .is_store, .tags(CM_tags),
  .store_enable, .store_mode, .reg_addr(reg_write_addr), .store_addr,
  .store_data, .reg_data(reg_write_data)
);

assign we = store_enable;
assign wm = store_mode;
assign wa = store_addr;
assign wd = store_data;

endmodule
