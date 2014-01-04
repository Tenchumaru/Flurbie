module write(
	output logic address_enable,
	output regval_t address, data,
	input logic data_valid,
	input regfile_t input_registers,
	output regfile_t output_registers,
	i_flow_control.in flow_in,
	i_execute_to_write.write_in ini,
	i_write_to_fetch.write_out outi
);

	// Ready the new values of the registers.
	regfile_t registers;
	genvar i;
	generate
		for(i= 0; i < NR; ++i) begin : assign_registers
			if(i == Flags) begin
				assign registers[i]= i == ini.destination_register && !ini.is_writing_memory
					? ini.destination_value
					: {input_registers[i][31], ini.flags, input_registers[i][26:0]};
			end else if(i == PC) begin
				// Since the output PC register gets the PC computed in the
				// next state logic because of the subst_in invocation, assign
				// the PC that was active at the time the current instruction
				// was fetched for purposes of computing a write address, used
				// in the output logic below.
				assign registers[i]= ini.pc;
			end else if(i == 0) begin
				assign registers[i]= 0;
			end else begin
				assign registers[i]= i == ini.destination_register && !ini.is_writing_memory
					? ini.destination_value
					: ini.has_upper_value && i == ini.destination_register + 1 && !ini.is_writing_memory
					? ini.upper_value
					: input_registers[i];
			end
		end
	endgenerate

	// next state logic
	regval_t pc;
	logic is_writing_memory, is_delaying;
	always_comb begin : next_state_logic
		pc= flow_in.is_valid && ini.destination_register == PC && !ini.is_writing_memory
			? ini.destination_value
			: outi.next_pc;
		is_writing_memory= flow_in.is_valid && ini.is_writing_memory;
		// Write needs to wait for memory to respond.
		is_delaying= is_writing_memory && !data_valid;
	end : next_state_logic

	// state register
	always_ff@(negedge flow_in.reset_n, posedge flow_in.clock) begin : state_register
		if(!flow_in.reset_n) begin
			outi.has_flushed <= 0;
			output_registers <= ZeroRegFile;
		end else begin
			if(flow_in.is_valid) begin
				outi.has_flushed <= ini.has_flushed;
				output_registers <= registers;
			end
			output_registers[PC] <= pc;
		end
	end : state_register

	// output logic
	always_comb begin : output_logic
		flow_in.hold= flow_in.reset_n && is_delaying && flow_in.is_valid;
		address_enable= is_writing_memory;
		address= registers[ini.destination_register] + ini.adjustment_value;
		data= ini.destination_value;
	end : output_logic

endmodule
