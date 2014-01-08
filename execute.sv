module execute(
	input regfile_t registers,
	i_flow_control.in flow_in,
	i_flow_control.out flow_out,
	i_read_to_execute.execute_in ini,
	i_execute_to_write.execute_out outi,
	i_feedback.out feedback
);

	// Compute the right operand.
	regval_t adjusted_value;
	always_comb begin
		case(ini.adjustment_operation)
			Add:
				adjusted_value= ini.right_value + ini.adjustment_value;
			Left:
				adjusted_value= ini.right_value << ini.adjustment_value[4:0];
			LogicalRight:
				adjusted_value= ini.right_value >> ini.adjustment_value[4:0];
			ArithmeticRight:
				adjusted_value= $signed(ini.right_value) >>> ini.adjustment_value[4:0];
		endcase
	end

	// Compute the signed and unsigned quotients and remainders.
	logic[31:0] quotient, remainder;
	logic[31:0] uquotient, uremainder;
	div the_div(.numer(ini.left_value), .denom(adjusted_value), .quotient, .remain(remainder));
	udiv the_udiv(.numer(ini.left_value), .denom(adjusted_value), .quotient(uquotient), .remain(uremainder));

	// Compute and select the operation results.
	logic input_carry, has_carry, is_negative, has_overflow, is_zero, has_upper_value, is_special_match;
	regval_t output_value, upper_value;
	always_comb begin
		input_carry= registers[Flags][30];
		has_carry= 0;
		has_upper_value= 0;
		upper_value= 0;
		is_special_match= ini.left_value == ini.adjustment_value;
		case(ini.operation)
			0: {has_carry, output_value}= ini.left_value + adjusted_value;
			1: {has_carry, output_value}= ini.left_value + adjusted_value + input_carry;
			2: {has_carry, output_value}= ini.left_value - adjusted_value;
			3: {has_carry, output_value}= ini.left_value - adjusted_value - input_carry;
			4: begin
				has_upper_value= 1;
				{upper_value, output_value}= $signed(ini.left_value) * $signed(adjusted_value);
			end
			5: begin
				has_upper_value= 1;
				{upper_value, output_value}= ini.left_value * adjusted_value;
			end
			6: begin
				has_upper_value= 1;
				output_value= quotient;
				upper_value= remainder;
			end
			7: begin
				has_upper_value= 1;
				output_value= uquotient;
				upper_value= uremainder;
			end
			8: output_value= ini.left_value & adjusted_value;
			9: output_value= ~(ini.left_value & adjusted_value);
			10: output_value= ini.left_value | adjusted_value;
			11: output_value= ~(ini.left_value | adjusted_value);
			12: output_value= ini.left_value ^ adjusted_value;
			13: output_value= ~(ini.left_value ^ adjusted_value);
			14: output_value= ini.left_value;
			15: if(is_special_match) begin
					has_upper_value= 1;
					output_value= ini.right_value;
					upper_value= ini.left_value;
				end else begin
					output_value= ini.left_value;
				end
		endcase
		is_negative= output_value[31];
		case(ini.operation)
			0, 1:
				has_overflow= (!ini.left_value[31] && !adjusted_value[31] && output_value[31])
					|| (ini.left_value[31] && adjusted_value[31] && !output_value[31]);
			2, 3:
				has_overflow= (ini.left_value[31] && !adjusted_value[31] && !output_value[31])
					|| (!ini.left_value[31] && adjusted_value[31] && output_value[31]);
			4:
				has_overflow= (ini.left_value[31] && adjusted_value[31] && output_value[31])
					|| (ini.left_value != 0 && adjusted_value != 0 && output_value == 0);
			6, 7:
				has_overflow= adjusted_value == 0;
			default:
				has_overflow= 0;
		endcase
		is_zero= is_special(ini.operation) ? is_special_match : output_value == 0;
	end

	// next state logic
	logic[3:0] flags;
	regind_t target_register, address_register;
	regval_t adjustment_value;
	logic[2:0] delay, next_delay;
	logic is_writing_memory, is_delaying, is_valid;
	always_comb begin : next_state_logic
		flags= {has_carry, is_negative, has_overflow, is_zero};
		target_register= ini.target_register;
		address_register= ini.address_register;
		adjustment_value= ini.adjustment_value;
		is_writing_memory= ini.is_writing_memory;
		if(is_special(ini.operation)) begin
			adjustment_value= 0;
			is_writing_memory= is_special_match;
		end else if(ini.is_writing_memory) begin
			address_register= ini.target_register;
		end
		// Delay if performing a divide operation.
		if(flow_in.is_valid && ini.operation[3:1] == 3) begin
			next_delay= delay ? delay << 1 : 2'b1;
		end else begin
			next_delay= 0;
		end
		is_delaying= |next_delay;
		is_valid= !is_delaying && flow_in.is_valid;
	end : next_state_logic

	// state register
	always_ff@(negedge flow_in.reset_n, posedge flow_in.clock) begin : state_register
		if(!flow_in.reset_n) begin
			flow_out.is_valid <= 0;
			outi.has_flushed <= 0;
		end else begin
			delay <= next_delay;
			if(!flow_out.hold) begin
				flow_out.is_valid <= is_valid;
				outi.pc <= ini.pc;
				outi.target_register <= target_register;
				outi.address_register <= address_register;
				outi.is_writing_memory <= is_writing_memory;
				outi.flags <= flags;
				outi.target_value <= output_value;
				outi.has_upper_value <= has_upper_value;
				outi.upper_value <= upper_value;
				outi.adjustment_value <= adjustment_value;
				outi.has_flushed <= ini.has_flushed;
			end
		end
	end : state_register

	// output logic
	always_comb begin : output_logic
		flow_in.hold= (flow_out.hold || is_delaying) && flow_in.is_valid;
		ini.flags= flags;
		feedback.value= output_value;
		feedback.upper_value= upper_value;
		feedback.index= target_register;
		feedback.is_valid= is_valid && !is_writing_memory;
		feedback.has_upper_value= has_upper_value;
	end : output_logic

endmodule
