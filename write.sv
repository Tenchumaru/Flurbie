module write(
	input logic reset_n, clock, data_valid,
	input regfile_t input_registers,
	input regval_t next_pc,
	i_execute_to_write.write_in ini,
	output regval_t address, data,
	output logic has_flushed, address_enable,
	output regfile_t output_registers
);

	regfile_t registers;

	genvar i;
	generate
		for(i= 0; i < NR; ++i) begin : assign_registers
			if(i == Flags) begin
				assign registers[i]= i == ini.destination_register && !ini.is_writing_memory
					? ini.destination_value
					: ini.has_upper_value && i == ini.destination_register + 1 && !ini.is_writing_memory
					? ini.upper_value
					: {input_registers[i][31], ini.flags, input_registers[i][26:0]};
			end else if(i == PC) begin
				assign registers[i]= i == ini.destination_register && !ini.is_writing_memory
					? ini.destination_value
					: ini.has_upper_value && i == ini.destination_register + 1 && !ini.is_writing_memory
					? ini.upper_value
					: ini.pc;
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

	regval_t pc;

	// If appropriate, clock next_pc instead of ini.pc into the output registers.
	assign pc= ini.is_valid && ini.destination_register == PC && !ini.is_writing_memory ? ini.destination_value : next_pc;

	always_ff@(posedge clock, negedge reset_n) begin : state_register
		if(!reset_n) begin
			has_flushed <= 0;
			output_registers <= ZeroRegFile;
		end else begin
			has_flushed <= ini.has_flushed;
			if(ini.is_valid) begin
				output_registers <= subst_in(pc, registers);
			end else begin
				output_registers[PC] <= pc;
			end
		end
	end : state_register

	assign ini.hold= reset_n && address_enable && !data_valid;
	assign address_enable= reset_n && ini.is_valid && ini.is_writing_memory;
	assign address= registers[ini.destination_register] + ini.adjustment_value;
	assign data= ini.destination_value;

endmodule
