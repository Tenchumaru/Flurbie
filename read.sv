module read(
	input regfile_t registers,
	output logic address_enable,
	output regval_t address,
	input logic data_valid,
	input regval_t data,
	i_flow_control.in flow_in,
	i_flow_control.out flow_out,
	i_decode_to_read.read_in ini,
	i_read_to_execute.read_out outi,
	i_feedback.in execute_feedback,
	i_feedback.in write_feedback
);

	// next state logic
	regfile_t input_registers;
	regval_t left_register_value, left_value, right_value, adjustment_value;
	logic masked_flags, is_active, is_inactive, is_reading_memory, is_delaying, is_valid, has_flushed;
	always_comb begin : next_state_logic
		input_registers= registers;
		input_registers[PC]= ini.pc;
		masked_flags= |(ini.cnvz_mask & outi.flags);
		is_active= flow_in.is_valid && ini.is_non_zero_active == masked_flags;
		is_inactive= flow_in.is_valid && ini.is_non_zero_active != masked_flags;
		left_register_value= write_feedback.get_r_value(ini.left_register, input_registers);
		left_register_value= execute_feedback.get_d_value(ini.left_register, left_register_value);
		// TODO:  if the memory this stage wants to read is the target of an
		// instruction currently in the execute or write stages, I want to use
		// one of those values instead of reading memory.
		left_value= ini.is_reading_memory ? data : left_register_value;
		right_value= write_feedback.get_r_value(ini.right_register, input_registers);
		right_value= execute_feedback.get_d_value(ini.right_register, right_value);
		if(is_special(ini.operation)) begin
			// TODO:  this works fine in a single-core implementation.
			// However, with multiple cores, I need a mechanism to prevent two
			// cores from executing this code at exactly the same time.
			// Consider using a priority mechanism that allows core 0 to
			// execute this before core 1, which executes before core 2, etc.
			adjustment_value= write_feedback.get_r_value(ini.adjustment_value, input_registers);
			adjustment_value= execute_feedback.get_d_value(ini.adjustment_value, adjustment_value);
		end else begin
			adjustment_value= ini.adjustment_value;
		end
		is_reading_memory= is_active && ini.is_reading_memory;
		// Read needs to wait for memory to respond.
		is_delaying= is_reading_memory && !data_valid;
		is_valid= !is_delaying && is_active;
		has_flushed= ini.has_flushed && is_active;
	end : next_state_logic

	// state register
	always_ff@(posedge flow_out.clock, negedge flow_out.reset_n) begin : state_register
		if(!flow_out.reset_n) begin
			flow_out.is_valid <= 0;
			outi.has_flushed <= 0;
		end else if(!flow_out.hold) begin
			flow_out.is_valid <= is_valid;
			outi.pc <= ini.pc;
			outi.operation <= ini.operation;
			outi.target_register <= ini.target_register;
			outi.left_value <= left_value;
			outi.right_value <= right_value;
			outi.address_register <= ini.left_register;
			outi.adjustment_operation <= ini.adjustment_operation;
			outi.adjustment_value <= adjustment_value;
			outi.is_writing_memory <= ini.is_writing_memory;
			outi.has_flushed <= has_flushed;
		end
	end : state_register

	// output logic
	regval_t address_adjustment;
	always_comb begin : output_logic
		address_adjustment= is_special(ini.operation) ? 0 : ini.adjustment_value;
		flow_in.hold= (flow_out.hold || is_delaying) && flow_in.is_valid;
		address_enable= is_reading_memory;
		address= write_feedback.get_r_value(ini.left_register, input_registers);
		address= execute_feedback.get_d_value(ini.left_register, address) + address_adjustment;
		ini.early_flush= ini.has_flushed && is_inactive;
	end : output_logic

endmodule
