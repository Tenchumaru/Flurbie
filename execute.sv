module execute(
	input logic reset_n, clock,
	input regfile_t registers,
	i_read_to_execute.execute_in ini,
	i_execute_to_write.execute_out outi
);

// Declare derived signals.
regfile_t input_registers;
logic[3:0] flags;
regval_t destination_value, adjustment;

// Assign derived signals.
assign input_registers= subst_in(ini.pc, registers);
assign {flags, destination_value}= compute(input_registers, ini.left_value,
	ini.right_value, ini.destination_is_memory ? 0 : ini.adjustment,
	ini.operation, ini.adjustment_operation);
assign adjustment= ini.destination_is_memory ? ini.adjustment : 0;

always_ff@(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		outi.is_valid <= 0;
		outi.has_flushed <= 0;
	end else if(outi.hold) begin
		// Don't do anything.
	end else if(ini.is_valid) begin
		outi.is_valid <= 1;
		outi.pc <= ini.pc;
		outi.destination <= ini.destination;
		outi.destination_is_memory <= ini.destination_is_memory;
		outi.flags <= flags;
		outi.destination_value <= destination_value;
		outi.adjustment <= adjustment;
		outi.has_flushed <= ini.has_flushed;
	end else begin
		outi.is_valid <= 0;
		outi.has_flushed <= ini.has_flushed;
	end
end

assign ini.hold= reset_n && outi.hold;

endmodule

function regval_t adjust(regval_t value, logic[1:0] op, logic[3:0] adjustment);
	case(op)
	None:
		return value;
	Left:
		return {value[30:0], 1'b0} << adjustment;
	LogicalRight:
		return {1'b0, value[31:1]} >> adjustment;
	ArithmeticRight:
		return $signed({value[31], value[31:1]}) >>> adjustment;
	endcase
endfunction

function logic[35:0] compute(regfile_t registers, regval_t left_value, right_value, adjustment, logic[3:0] operation, logic[2:0] adjustment_operation);

	regval_t adjusted_value, output_value;
	logic has_carry, is_negative, has_overflow, is_zero;

	adjusted_value= adjustment_operation[2]
		? right_value + adjustment
		: adjust(right_value, adjustment_operation, adjustment[3:0]);
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
		14: output_value= 0; // TODO:  compare and exchange; see below for a possible implementation.
		15: output_value= 0; // TODO:  unknown
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

/*
A Possible Implementation of Compare and Exchange

Use a single register file that lives in the FPGA and is shared by all cores.
This means putting this in cpu.sv, not core.sv.
*/

module CX#(parameter N = 8)(input logic clock, input logic[$clog2(N)-1:0] index, input regval_t comparand, replacement, output regval_t original);

regval_t memory[(2**N)-1:0];

always_ff@(posedge clock) begin
	if(memory[index] == comparand)
		memory[index] <= replacement;
	original <= memory[index];
end

endmodule
