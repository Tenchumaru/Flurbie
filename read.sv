module read(
	input regfile_t registers,
	output logic address_enable,
	output regval_t address,
	input logic data_valid,
	input regval_t data,
	i_flow_control.in flow_in,
	i_flow_control.out flow_out,
	i_decode_to_read.read_in ini,
	i_read_to_execute.read_out outi
);

	regfile_t input_registers;
	assign input_registers= subst_in(ini.pc, registers);

	// next state logic
	logic is_reading_memory, is_delaying, next_is_valid;
	always_comb begin : next_state_logic
		is_reading_memory= flow_in.is_valid && ini.is_reading_memory;
		// Read needs to wait for memory to respond.
		is_delaying= is_reading_memory && !data_valid;
		next_is_valid= !is_delaying && flow_in.is_valid;
	end : next_state_logic

	// state register
	always_ff@(posedge flow_out.clock, negedge flow_out.reset_n) begin : state_register
		if(!flow_out.reset_n) begin
			flow_out.is_valid <= 0;
			outi.has_flushed <= 0;
		end else if(!flow_out.hold) begin
			flow_out.is_valid <= next_is_valid;
			outi.pc <= ini.pc;
			outi.operation <= ini.operation;
			outi.destination_register <= ini.destination_register;
			// TODO:  using the left and right registers here isn't correct
			// since one of them might have been written by whatever
			// instruction happened to be in the write stage two clock cycles
			// ago.  This happens to work for the time being since that write
			// stage was for the previous instruction due to non-optimal pipelining.
			outi.left_value <= input_registers[ini.left_register];
			outi.right_value <= ini.is_reading_memory ? data : input_registers[ini.right_register];
			outi.address_register <= ini.address_register;
			outi.adjustment_operation <= ini.adjustment_operation;
			outi.adjustment_value <= ini.is_reading_memory && ini.is_writing_memory ?
				// For the CX instruction, set the adjustment value to the
				// right register value.
				// TODO:  this works fine in a single-core implementation.
				// However, with multiple cores, I need a mechanism to prevent
				// two cores from executing this code at exactly the same time.
				// Consider using a priority mechanism that allows core 0 to
				// execute this before core 1, which executes before core 2, etc.
				input_registers[ini.right_register] :
				ini.adjustment_value;
			outi.is_writing_memory <= ini.is_writing_memory;
			outi.has_flushed <= ini.has_flushed;
		end
	end : state_register

	// output logic
	always_comb begin : output_logic
		flow_in.hold= (flow_out.hold || is_delaying) && flow_in.is_valid;
		address_enable= is_reading_memory;
		address= input_registers[ini.address_register] + ini.adjustment_value;
	end : output_logic

endmodule
