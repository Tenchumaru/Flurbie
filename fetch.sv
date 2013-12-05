module fetch(
	input logic reset_n, clock, has_flushed, data_valid,
	input regval_t pc, data,
	output logic address_enable,
	output regval_t address, next_pc,
	i_fetch_to_decode.fetch_out outi
);

typedef enum logic {IsActive, IsFlushing} state_t;

state_t state, next_state;
regval_t next_instruction, next_pc_increment;

// next state logic
always_comb begin : next_state_logic
	case(state)
		IsActive: next_state= outi.is_pc_changing ? IsFlushing : IsActive;
		IsFlushing: next_state= outi.is_pc_changing || !has_flushed ? IsFlushing : IsActive;
		default: next_state= IsActive;
	endcase
	next_instruction= next_state == IsActive && data_valid ? data : Nop;
end : next_state_logic

// state register
always_ff@(posedge clock, negedge reset_n) begin : state_register
	if(!reset_n) begin
		state <= IsActive;
		outi.instruction <= Nop;
	end else begin
		state <= next_state;
		if(!outi.hold)
			outi.instruction <= next_instruction;
	end
end : state_register

// output logic
always_comb begin : output_logic
	next_pc_increment= next_state == IsActive && data_valid && !outi.hold ? 4 : 0;
	if(!reset_n) begin
		address_enable= 1;
		address= 0;
		next_pc= 0;
	end else begin
		address_enable= next_state == IsActive && !outi.hold;
		address= pc;
		next_pc= pc + next_pc_increment;
	end
end : output_logic

endmodule
