parameter NR= 4;

typedef logic[4:0] regind_t;
typedef integer unsigned regval_t;
typedef regval_t regfile_t[NR];
parameter regfile_t ZeroRegFile= '{NR{0}};
parameter Flags= NR - 1;
parameter PC= Flags - 1;

function regfile_t subst_in(input regval_t pc, input regfile_t registers);
	return '{0, registers[1], pc, registers[Flags]};
endfunction

// shift operation
parameter logic[1:0] Add= 0;
parameter logic[1:0] Left= 1;
parameter logic[1:0] LogicalRight= 2;
parameter logic[1:0] ArithmeticRight= 3;

parameter regval_t Nop= 32'h80000000;

interface i_flow_control(input logic clock, reset_n);
	logic is_valid, hold;

	modport in(input clock, reset_n, is_valid, output hold);
	modport out(input clock, reset_n, hold, output is_valid);
endinterface

interface i_feedback();
	regval_t value, upper_value;
	regind_t index;
	logic is_valid, has_upper_value;

	modport in(input value, upper_value, index, is_valid, has_upper_value,
		import get_d_value, import get_r_value);
	modport out(output value, upper_value, index, is_valid, has_upper_value);

	function regval_t get_d_value(regind_t desired_register, regval_t default_value);
		return is_valid && desired_register == index ?
			value :
			is_valid && has_upper_value && desired_register == index + 1 ?
			upper_value :
			default_value;
	endfunction

	function regval_t get_r_value(regind_t desired_register, regfile_t registers);
		return is_valid && desired_register == index ?
			value :
			is_valid && has_upper_value && desired_register == index + 1 ?
			upper_value :
			registers[desired_register];
	endfunction
endinterface

interface i_fetch_to_decode();
	logic is_pc_changing;
	regval_t pc, instruction;

	modport fetch_out(
		input is_pc_changing,
		output pc, instruction
	);

	modport decode_in(
		input pc, instruction,
		output is_pc_changing
	);
endinterface

interface i_decode_to_read();
	regval_t pc, adjustment_value;
	regind_t destination_register, left_register, right_register, address_register;
	logic[3:0] operation;
	logic[1:0] adjustment_operation;
	logic has_flushed, is_reading_memory, is_writing_memory;

	modport decode_out(
		output pc, adjustment_value,
		output destination_register, left_register, right_register, address_register,
		output operation,
		output adjustment_operation,
		output has_flushed, is_reading_memory, is_writing_memory
	);

	modport read_in(
		input pc, adjustment_value,
		input destination_register, left_register, right_register, address_register,
		input operation,
		input adjustment_operation,
		input has_flushed, is_reading_memory, is_writing_memory
	);
endinterface

interface i_read_to_execute();
	regval_t pc, adjustment_value, left_value, right_value;
	regind_t destination_register, address_register;
	logic[3:0] operation;
	logic[1:0] adjustment_operation;
	logic has_flushed, is_writing_memory;

	modport read_out(
		output pc, adjustment_value, left_value, right_value,
		output destination_register, address_register,
		output operation,
		output adjustment_operation,
		output has_flushed, is_writing_memory
	);

	modport execute_in(
		input pc, adjustment_value, left_value, right_value,
		input destination_register, address_register,
		input operation,
		input adjustment_operation,
		input has_flushed, is_writing_memory
	);
endinterface

interface i_execute_to_write();
	regval_t pc, adjustment_value, destination_value, upper_value;
	regind_t destination_register;
	logic[3:0] flags;
	logic has_flushed, is_writing_memory, has_upper_value;

	modport execute_out(
		output pc, adjustment_value, destination_value, upper_value,
		output destination_register,
		output flags,
		output has_flushed, is_writing_memory, has_upper_value
	);
	modport write_in(
		input pc, adjustment_value, destination_value, upper_value,
		input destination_register,
		input flags,
		input has_flushed, is_writing_memory, has_upper_value
	);
endinterface

interface i_write_to_fetch();
	regval_t next_pc;
	logic has_flushed;

	modport write_out(input next_pc, output has_flushed);
	modport fetch_in(input has_flushed, output next_pc);
endinterface
