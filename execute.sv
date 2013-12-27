module execute(
	input logic reset_n, clock,
	input regfile_t registers,
	i_read_to_execute.execute_in ini,
	i_execute_to_write.execute_out outi
);

	// Declare derived signals.
	regfile_t input_registers;
	logic has_carry, is_negative, has_overflow, is_zero;
	regval_t destination_value;

	// Assign derived signals.
	assign input_registers= subst_in(ini.pc, registers);
	assign {has_carry, is_negative, has_overflow, is_zero, destination_value}= compute(input_registers,
		ini.left_value, ini.right_value, ini.adjustment_value,
		ini.operation, ini.adjustment_operation);

	always_ff@(posedge clock, negedge reset_n) begin
		if(!reset_n) begin
			outi.is_valid <= 0;
			outi.has_flushed <= 0;
		end else if(outi.hold) begin
		// Don't do anything.
		end else if(ini.is_valid) begin
			outi.is_valid <= 1;
			outi.pc <= ini.pc;
			if(ini.is_writing_memory) begin
				if(ini.operation != 15 || has_carry) begin
					outi.destination_register <= ini.address_register;
					outi.is_writing_memory <= 1;
				end else begin
					outi.destination_register <= 0;
					outi.is_writing_memory <= 0;
				end
			end else begin
				outi.destination_register <= ini.destination_register;
				outi.is_writing_memory <= 0;
			end
			outi.flags <= {has_carry, is_negative, has_overflow, is_zero};
			outi.destination_value <= destination_value;
			outi.adjustment_value <= ini.operation != 15 ? ini.adjustment_value : 0;
			outi.has_flushed <= ini.has_flushed;
		end else begin
			outi.is_valid <= 0;
			outi.has_flushed <= ini.has_flushed;
		end
	end

	assign ini.hold= reset_n && outi.hold;

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

function logic[35:0] compute(regfile_t registers, regval_t left_value, right_value, adjustment_value, logic[3:0] operation, logic[1:0] adjustment_operation);

	regval_t adjusted_value, output_value;
	logic has_carry, is_negative, has_overflow, is_zero;

	adjusted_value= adjust(right_value, adjustment_operation, adjustment_value);
	has_carry= 0;
	case(operation)
		0: {has_carry, output_value}= left_value + adjusted_value;
		1: {has_carry, output_value}= left_value + adjusted_value + registers[Flags][30];
		2: {has_carry, output_value}= left_value - adjusted_value;
		3: {has_carry, output_value}= left_value - adjusted_value - registers[Flags][30];
		// TODO:  consider targeting two registers with the low and high parts
		// of the product.
		4: output_value= $signed(left_value) * $signed(adjusted_value);
		5: output_value= left_value * adjusted_value;
		// TODO:  consider using a megafunction to get the quotient and
		// remainder at the same time.  That will require targeting two registers.
		6: output_value= adjusted_value ? $signed($signed(left_value) / $signed(adjusted_value)) : '1;
		7: output_value= adjusted_value ? left_value / adjusted_value : '1;
		8: output_value= left_value & adjusted_value;
		9: output_value= ~(left_value & adjusted_value);
		10: output_value= left_value | adjusted_value;
		11: output_value= ~(left_value | adjusted_value);
		12: output_value= left_value ^ adjusted_value;
		13: output_value= ~(left_value ^ adjusted_value);
		14: output_value= left_value;
		15: begin
			has_carry= left_value == right_value;
			output_value= adjustment_value;
		end
	endcase
	is_negative= output_value[31];
	// TODO:  overflow is incorrect for multiplication and division.
	has_overflow= (operation[1] && left_value[31] && !adjusted_value[31] && !output_value[31])
		|| (!operation[1] && !left_value[31] && !adjusted_value[31] && output_value[31])
		|| (operation[1] && !left_value[31] && adjusted_value[31] && output_value[31])
		|| (!operation[1] && left_value[31] && adjusted_value[31] && !output_value[31]);
	is_zero= !output_value;

	return {has_carry, is_negative, has_overflow, is_zero, output_value};

endfunction
