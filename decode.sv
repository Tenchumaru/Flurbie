module decode(
	input logic reset_n, clock,
	input regfile_t registers,
	i_fetch_to_decode.decode_in ini,
	i_decode_to_read.decode_out outi
);

// Declare all of the possible signals in the instruction.
logic is_non_zero_active;
logic[3:0] cnvz_mask;
logic[3:0] op_code;
regind_t dr;
logic is_register;
regval_t immediate_value;
regind_t sr1;
logic is_indirect;
regind_t sr2;
logic[1:0] shift_operation;
logic[3:0] shift_adjustment;
logic is_to_memory;
regval_t indirect_adjustment;

// Extract all of the possible signals from the instruction.
assign is_non_zero_active= ini.instruction[31];
assign cnvz_mask= ini.instruction[30:27];
assign op_code= ini.instruction[26:23];
assign dr= ini.instruction[22:18];
assign is_register= ini.instruction[17];
assign immediate_value= $signed(ini.instruction[16:0]);
assign sr1= ini.instruction[16:12];
assign is_indirect= ini.instruction[11];
assign sr2= ini.instruction[10:6];
assign shift_operation= ini.instruction[5:4];
assign shift_adjustment= ini.instruction[3:0];
assign is_to_memory= ini.instruction[10];
assign indirect_adjustment= $signed(ini.instruction[9:0]);

// Declare the derived signals.
logic masked_flags;
logic next_is_valid, destination_is_memory, right_is_memory;
regind_t left_register, right_register;
regval_t adjustment;
logic[2:0] adjustment_operation;

// Set derived signals.
always_comb begin
	masked_flags= |(cnvz_mask & registers[Flags][30:27]);
	next_is_valid= is_non_zero_active == masked_flags;
	destination_is_memory= is_register && is_indirect && is_to_memory;
	right_is_memory= is_register && is_indirect && !is_to_memory;
	if(is_register) begin
		if(is_indirect) begin
			left_register= is_to_memory ? 5'd0 : dr;
			right_register= sr1;
			adjustment= indirect_adjustment;
			adjustment_operation= Add;
		end else begin
			left_register= sr1;
			right_register= sr2;
			adjustment= shift_adjustment;
			adjustment_operation= shift_operation;
		end
	end else begin
		left_register= 0;
		right_register= 0;
		adjustment= immediate_value;
		adjustment_operation= Add;
	end
end

always_ff@(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		outi.is_valid <= 0;
		outi.has_flushed <= 0;
	end else if(outi.hold) begin
		// Don't do anything.
	end else begin
		outi.is_valid <= next_is_valid;
		outi.pc <= registers[PC];
		outi.operation <= op_code;
		outi.destination <= dr;
		outi.destination_is_memory <= destination_is_memory;
		outi.right_is_memory <= right_is_memory;
		outi.left_register <= left_register;
		outi.right_register <= right_register;
		outi.adjustment <= adjustment;
		outi.adjustment_operation <= adjustment_operation;
		outi.has_flushed <= ini.is_pc_changing;
	end
end

assign ini.hold= reset_n && outi.hold;
assign ini.is_pc_changing= next_is_valid && !destination_is_memory && dr == PC;

endmodule
