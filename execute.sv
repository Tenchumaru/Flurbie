module execute(
	input regfile_t registers,
	i_flow_control.in flow_in,
	i_flow_control.out flow_out,
	i_read_to_execute.execute_in ini,
	i_execute_to_write.execute_out outi
);

	// Declare derived signals.
	regfile_t input_registers;
	logic has_carry, is_negative, has_overflow, is_zero, has_upper_value;
	regval_t adjusted_value, output_value, upper_value;
	logic[31:0] quotient, remainder;
	logic[31:0] uquotient, uremainder;

	// Assign derived signals.
	assign input_registers= subst_in(ini.pc, registers);
	assign adjusted_value= adjust(ini.right_value, ini.adjustment_operation, ini.adjustment_value);

	div the_div(.numer(ini.left_value), .denom(adjusted_value), .quotient, .remain(remainder));
	udiv the_udiv(.numer(ini.left_value), .denom(adjusted_value), .quotient(uquotient), .remain(uremainder));

	always_comb begin
		has_carry= 0;
		has_upper_value= 0;
		upper_value= 0;
		case(ini.operation)
			0: {has_carry, output_value}= ini.left_value + adjusted_value;
			1: {has_carry, output_value}= ini.left_value + adjusted_value + input_registers[Flags][30];
			2: {has_carry, output_value}= ini.left_value - adjusted_value;
			3: {has_carry, output_value}= ini.left_value - adjusted_value - input_registers[Flags][30];
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
				{upper_value, output_value}= {remainder, quotient};
			end
			7: begin
				has_upper_value= 1;
				{upper_value, output_value}= {uremainder, uquotient};
			end
			8: output_value= ini.left_value & adjusted_value;
			9: output_value= ~(ini.left_value & adjusted_value);
			10: output_value= ini.left_value | adjusted_value;
			11: output_value= ~(ini.left_value | adjusted_value);
			12: output_value= ini.left_value ^ adjusted_value;
			13: output_value= ~(ini.left_value ^ adjusted_value);
			14: output_value= ini.left_value;
			15: output_value= ini.adjustment_value;
		endcase
		is_negative= output_value[31];
		case(ini.operation)
			0, 1:
				has_overflow= (!ini.left_value[31] && !adjusted_value[31] && output_value[31])
					|| (ini.left_value[31] && adjusted_value[31] && !output_value[31]);
			2, 3:
				has_overflow= (ini.left_value[31] && !adjusted_value[31] && !output_value[31])
					|| (!ini.left_value[31] && adjusted_value[31] && output_value[31]);
			6, 7:
				has_overflow= adjusted_value == 0;
			default:
				has_overflow= 0;
		endcase
		is_zero= ini.operation == 15 ? ini.left_value == ini.right_value : output_value == 0;
	end

	// next state logic
	logic[1:0] delay, next_delay;
	logic is_delaying, next_is_valid;
	always_comb begin : next_state_logic
		// Delay if performing a divide or modulo operation.
		if(flow_in.is_valid && ini.operation[3:1] == 3) begin
			next_delay= delay ? delay << 1 : 2'b1;
		end else begin
			next_delay= 0;
		end
		is_delaying= |next_delay;
		next_is_valid= !is_delaying && flow_in.is_valid;
	end : next_state_logic

	// state register
	always_ff@(negedge flow_in.reset_n, posedge flow_in.clock) begin : state_register
		if(!flow_in.reset_n) begin
			flow_out.is_valid <= 0;
			outi.has_flushed <= 0;
		end else begin
			delay <= next_delay;
			if(!flow_out.hold) begin
				flow_out.is_valid <= next_is_valid;
				outi.pc <= ini.pc;
				if(ini.is_writing_memory) begin
					if(ini.operation == 15 && !is_zero) begin
						outi.destination_register <= 0;
						outi.is_writing_memory <= 0;
					end else begin
						outi.destination_register <= ini.address_register;
						outi.is_writing_memory <= 1;
					end
				end else begin
					outi.destination_register <= ini.destination_register;
					outi.is_writing_memory <= 0;
				end
				outi.flags <= {has_carry, is_negative, has_overflow, is_zero};
				outi.destination_value <= output_value;
				outi.has_upper_value <= has_upper_value;
				outi.upper_value <= upper_value;
				outi.adjustment_value <= ini.operation != 15 ? ini.adjustment_value : 0;
				outi.has_flushed <= ini.has_flushed;
			end
		end
	end : state_register

	// output logic
	always_comb begin : output_logic
		flow_in.hold= (flow_out.hold || is_delaying) && flow_in.is_valid;
	end : output_logic

endmodule

function regval_t adjust(regval_t value, logic[1:0] op, regval_t adjustment_value);
	case(op)
		Add:
			return value + adjustment_value;
		Left:
			return value << adjustment_value[4:0];
		LogicalRight:
			return value >> adjustment_value[4:0];
		ArithmeticRight:
			return $signed(value) >>> adjustment_value[4:0];
	endcase
endfunction
