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

	i_flow_control flow_ftd(.clock, .reset_n);
	i_flow_control flow_dtr(.clock, .reset_n);
	i_flow_control flow_rte(.clock, .reset_n);
	i_flow_control flow_etw(.clock, .reset_n);
	i_fetch_to_decode the_ftd();
	i_decode_to_read the_dtr();
	i_read_to_execute the_rte();
	i_execute_to_write the_etw();
	i_write_to_fetch the_wtf();
	i_feedback feedback_etr();

	fetch the_fetch(
		.registers,
		.address(ia),
		.address_enable(ia_enable),
		.data(iv),
		.data_valid(iv_valid),
		.flow_out(flow_ftd.out),
		.ini(the_wtf.fetch_in),
		.outi(the_ftd.fetch_out)
	);

	decode the_decode(
		.registers,
		.flow_in(flow_ftd.in),
		.flow_out(flow_dtr.out),
		.ini(the_ftd.decode_in),
		.outi(the_dtr.decode_out)
	);

	read the_read(
		.registers,
		.address(da_in),
		.address_enable(da_in_enable),
		.data(dv_in),
		.data_valid(dv_in_valid),
		.flow_in(flow_dtr.in),
		.flow_out(flow_rte.out),
		.ini(the_dtr.read_in),
		.outi(the_rte.read_out),
		.feed_in(feedback_etr.in)
	);

	execute the_execute(
		.registers,
		.flow_in(flow_rte.in),
		.flow_out(flow_etw.out),
		.ini(the_rte.execute_in),
		.outi(the_etw.execute_out),
		.feed_out(feedback_etr.out)
	);

	write the_write(
		.input_registers(registers),
		.output_registers(registers),
		.address(da_out),
		.address_enable(da_out_enable),
		.data(dv_out),
		.data_valid(dv_out_valid),
		.flow_in(flow_etw.in),
		.ini(the_etw.write_in),
		.outi(the_wtf.write_out)
	);

endmodule
