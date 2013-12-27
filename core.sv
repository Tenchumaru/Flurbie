module core(
	input logic reset_n, clock,
	output regval_t ia,
	output logic ia_enable,
	input logic iv_valid,
	input regval_t iv,
	output regval_t da_in, da_out,
	output logic da_in_enable, da_out_enable,
	input regval_t dv_in,
	output regval_t dv_out,
	input logic dv_in_valid, dv_out_valid
);

	regfile_t registers;
	regval_t next_pc;
	logic has_flushed;

	i_fetch_to_decode the_ftd();

	fetch the_fetch(
		.reset_n, .clock, .has_flushed,
		.pc(registers[PC]), .data(iv), .data_valid(iv_valid),
		.address(ia), .address_enable(ia_enable),
		.next_pc, .outi(the_ftd.fetch_out)
	);

	i_decode_to_read the_dtr();

	decode the_decode(
		.reset_n, .clock,
		.registers, .ini(the_ftd.decode_in),
		.outi(the_dtr.decode_out)
	);

	i_read_to_execute the_rte();

	read the_read(
		.reset_n, .clock,
		.data(dv_in), .data_valid(dv_in_valid),
		.registers, .ini(the_dtr.read_in),
		.address_enable(da_in_enable), .address(da_in),
		.outi(the_rte.read_out)
	);

	i_execute_to_write the_etw();

	execute the_execute(
		.reset_n, .clock,
		.registers, .ini(the_rte.execute_in),
		.outi(the_etw.execute_out)
	);

	write the_write(
		.reset_n, .clock, .data_valid(dv_out_valid),
		.input_registers(registers), .next_pc, .ini(the_etw.write_in),
		.address(da_out), .data(dv_out),
		.has_flushed, .address_enable(da_out_enable),
		.output_registers(registers)
	);

endmodule
