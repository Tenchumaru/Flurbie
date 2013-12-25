module decode(
	input logic reset_n, clock,
	input regfile_t registers,
	i_fetch_to_decode.decode_in ini,
	i_decode_to_read.decode_out outi
);

// Declare all of the possible signals in the instruction.
logic is_non_zero_active; // 31
logic[3:0] cnvz_mask; // 30-27
logic[3:0] raw_operation; // 26-23
regind_t destination_register;  // 22-18
logic is_register; // 17
regind_t sr1; // 16-12
logic[11:0] immediate_operand; // 11-0
regind_t sr2; // 11-7
logic[1:0] raw_adjustment_operation; // 6-5
logic[4:0] raw_adjustment_value; // 4-0
logic[1:0] memory_operation; // 17-16
regind_t raw_address_register; // 15-11
logic[10:0] address_offset; // 10-0
logic[15:0] immediate_value; // 15-0
regind_t exchange_address_register; // 6-2

// Extract all of the possible signals from the instruction.
assign is_non_zero_active= ini.instruction[31];
assign cnvz_mask= ini.instruction[30:27];
assign raw_operation= ini.instruction[26:23];
assign destination_register= ini.instruction[22:18];
assign is_register= ini.instruction[17];
assign sr1= ini.instruction[16:12];
assign immediate_operand= ini.instruction[11:0];
assign sr2= ini.instruction[11:7];
assign raw_adjustment_operation= ini.instruction[6:5];
assign raw_adjustment_value= ini.instruction[4:0];
assign memory_operation= ini.instruction[17:16];
assign raw_address_register= ini.instruction[15:11];
assign address_offset= ini.instruction[10:0];
assign immediate_value= ini.instruction[15:0];
assign exchange_address_register= ini.instruction[6:2];

// Declare the derived signals.
logic masked_flags, is_valid, is_reading_memory, is_writing_memory;
logic[3:0] operation;
regind_t left_register, right_register, address_register;
logic[1:0] adjustment_operation;
regval_t adjustment_value;

// Set derived signals.
always_comb begin
	masked_flags= |(cnvz_mask & registers[Flags][30:27]);
	is_valid= is_non_zero_active == masked_flags;
	is_reading_memory= 0;
	is_writing_memory= 0;
	operation= raw_operation;
	left_register= sr1;
	right_register= sr2;
	address_register= raw_address_register;
	adjustment_operation= raw_adjustment_operation;
	// When shifting, I only use the lower five bits.
	// TODO: adjustment_value= $signed(raw_adjustment_value);
	adjustment_value= {{28{raw_adjustment_value[4]}}, raw_adjustment_value[3:0]};
	case(raw_operation)
		14: begin
			left_register= 0;
			right_register= 0;
			operation= 10; // OR
			adjustment_operation= Add;
			case(memory_operation)
				0: begin
					// ld
					is_reading_memory= 1;
					// TODO: adjustment_value= $signed(address_offset);
					adjustment_value= {{22{address_offset[10]}}, address_offset[9:0]};
				end
				1: begin
					// ldi
					// TODO: adjustment_value= $signed(immediate_value);
					adjustment_value= {{17{immediate_value[15]}}, immediate_value[14:0]};
				end
				2: begin
					// ori
					left_register= destination_register;
					// TODO: adjustment_value= $signed(immediate_value);
					adjustment_value= {{17{immediate_value[15]}}, immediate_value[14:0]};
				end
				3: begin
					// store
					is_writing_memory= 1;
					left_register= destination_register;
					adjustment_operation= Left;
					// TODO: adjustment_value= $signed(address_offset);
					adjustment_value= {{22{address_offset[10]}}, address_offset[9:0]};
				end
			endcase
		end
		15: begin
			// cx
			is_reading_memory= 1;
			is_writing_memory= 1;
			address_register= exchange_address_register;
			adjustment_operation= Add;
			adjustment_value= 0;
		end
		default: if(!is_register) begin
				right_register= 0;
				adjustment_operation= Add;
				// TODO: adjustment_value= $signed(immediate_operand);
				adjustment_value= {{21{immediate_operand[11]}}, immediate_operand[10:0]};
			end
	endcase
end

always_ff@(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		outi.is_valid <= 0;
		outi.has_flushed <= 0;
	end else if(outi.hold) begin
		// Don't do anything.
	end else begin
		outi.is_valid <= is_valid;
		outi.pc <= registers[PC];
		outi.operation <= operation;
		outi.destination_register <= destination_register;
		outi.left_register <= left_register;
		outi.right_register <= right_register;
		outi.address_register <= address_register;
		outi.adjustment_operation <= adjustment_operation;
		outi.adjustment_value <= adjustment_value;
		outi.is_reading_memory <= is_reading_memory;
		outi.is_writing_memory <= is_writing_memory;
		outi.has_flushed <= ini.is_pc_changing;
	end
end

assign ini.hold= reset_n && outi.hold;
assign ini.is_pc_changing= is_valid && (!is_writing_memory || is_reading_memory) && destination_register == PC;

endmodule
