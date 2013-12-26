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

interface i_fetch_to_decode();

logic hold, is_pc_changing;
regval_t instruction;

modport fetch_out(
	input hold, is_pc_changing,
	output instruction
);

modport decode_in(
	input instruction,
	output hold, is_pc_changing
);

endinterface

interface i_decode_to_read();

regval_t pc, adjustment_value;
regind_t destination_register, left_register, right_register, address_register;
logic[3:0] operation;
logic[1:0] adjustment_operation;
logic has_flushed, is_valid, is_reading_memory, is_writing_memory, hold;

modport decode_out(
	input hold,
	output pc, adjustment_value,
	output destination_register, left_register, right_register, address_register,
	output operation,
	output adjustment_operation,
	output has_flushed, is_valid, is_reading_memory, is_writing_memory
);

modport read_in(
	input pc, adjustment_value,
	input destination_register, left_register, right_register, address_register,
	input operation,
	input adjustment_operation,
	input has_flushed, is_valid, is_reading_memory, is_writing_memory,
	output hold
);

endinterface

interface i_read_to_execute();

regval_t pc, adjustment_value, left_value, right_value;
regind_t destination_register, address_register;
logic[3:0] operation;
logic[1:0] adjustment_operation;
logic hold, has_flushed, is_valid, is_writing_memory;

modport read_out(
	input hold,
	output pc, adjustment_value, left_value, right_value,
	output destination_register, address_register,
	output operation,
	output adjustment_operation,
	output has_flushed, is_valid, is_writing_memory
);

modport execute_in(
	input pc, adjustment_value, left_value, right_value,
	input destination_register, address_register,
	input operation,
	input adjustment_operation,
	input has_flushed, is_valid, is_writing_memory,
	output hold
);

endinterface

interface i_execute_to_write();

regval_t pc, adjustment_value, destination_value;
regind_t destination_register;
logic[3:0] flags;
logic hold, has_flushed, is_valid, is_writing_memory;

modport execute_out(
	input hold,
	output pc, adjustment_value, destination_value,
	output destination_register,
	output flags,
	output has_flushed, is_valid, is_writing_memory
);
modport write_in(
	input pc, adjustment_value, destination_value,
	input destination_register,
	input flags,
	input has_flushed, is_valid, is_writing_memory,
	output hold
);

endinterface
