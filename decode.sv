module decode(
	input regfile_t registers,
	i_flow_control.in flow_in,
	i_flow_control.out flow_out,
	i_fetch_to_decode.decode_in ini,
	i_decode_to_read.decode_out outi
);

	// Declare all of the possible signals in the instruction.
	logic is_non_zero_active; // 31
	logic[3:0] cnvz_mask; // 30-27
	logic[3:0] operation; // 26-23
	regind_t target_register;  // 22-18
	logic is_not_immediate; // 17
	regind_t left_register; // 16-12
	logic[11:0] immediate_operand; // 11-0
	regind_t right_register; // 11-7
	logic[1:0] adjustment_operation; // 6-5
	regval_t adjustment_value; // 4-0
	logic is_xorih; // 16
	logic[15:0] immediate_value; // 15-0
	logic is_store; // 11
	logic[10:0] address_offset; // 10-0
	regind_t compare_register; // 6-2

	// Declare the derived signals.
	logic is_reading_memory, is_writing_memory;

	// Extract all of the possible signals from the instruction and set the
	// derived signals.
	always_comb begin
		is_non_zero_active= ini.instruction[31];
		cnvz_mask= ini.instruction[30:27];
		operation= ini.instruction[26:23];
		target_register= ini.instruction[22:18];
		is_not_immediate= ini.instruction[17];
		left_register= ini.instruction[16:12];
		immediate_operand= ini.instruction[11:0];
		right_register= ini.instruction[11:7];
		adjustment_operation= ini.instruction[6:5];
		adjustment_value= ini.instruction[4:0];
		is_xorih= ini.instruction[16];
		immediate_value= ini.instruction[15:0];
		is_store= ini.instruction[11];
		address_offset= ini.instruction[10:0];
		compare_register= ini.instruction[6:2];
		is_reading_memory= 0;
		is_writing_memory= 0;
		case(operation)
			14: begin
				right_register= 0;
				operation= 10; // OR
				adjustment_operation= Add;
				if(is_not_immediate) begin
					adjustment_operation= Left;
					adjustment_value= $signed(address_offset);
					if(is_store) begin
						// st
						is_writing_memory= 1;
					end else begin
						// ld
						is_reading_memory= 1;
					end
				end else begin
					if(is_xorih) begin
						// xorih
						operation= 12; // XOR
						left_register= target_register;
						adjustment_value= {immediate_value[15:0], 16'h0};
					end else begin
						// ldi
						left_register= 0;
						adjustment_value= $signed(immediate_value);
					end
				end
			end
			15: begin
				// cx
				is_reading_memory= 1;
				is_writing_memory= 1;
				adjustment_value= compare_register;
			end
			default:
				if(is_not_immediate) begin
					// When shifting, execute only uses the lower five bits.
					adjustment_value= $signed(adjustment_value);
				end else begin
					right_register= 0;
					adjustment_operation= Add;
					adjustment_value= $signed(immediate_operand);
				end
		endcase
	end

	// next state logic
	logic is_delaying, is_valid, is_pc_changing;
	always_comb begin : next_state_logic
		// Decode always completes in one cycle.
		is_delaying= 0;
		is_valid= !is_delaying && flow_in.is_valid;
		is_pc_changing= is_valid && (!is_writing_memory || is_reading_memory) && target_register == PC;
	end : next_state_logic

	// state register
	always_ff@(negedge flow_in.reset_n, posedge flow_in.clock) begin : state_register
		if(!flow_in.reset_n) begin
			flow_out.is_valid <= 0;
			outi.has_flushed <= 0;
		end else if(!flow_out.hold) begin
			flow_out.is_valid <= is_valid;
			outi.has_flushed <= is_pc_changing;
			outi.pc <= ini.pc;
			outi.is_non_zero_active <= is_non_zero_active;
			outi.cnvz_mask <= cnvz_mask;
			outi.operation <= operation;
			outi.target_register <= target_register;
			outi.left_register <= left_register;
			outi.right_register <= right_register;
			outi.adjustment_operation <= adjustment_operation;
			outi.adjustment_value <= adjustment_value;
			outi.is_reading_memory <= is_reading_memory;
			outi.is_writing_memory <= is_writing_memory;
		end
	end : state_register

	// output logic
	always_comb begin : output_logic
		flow_in.hold= (flow_out.hold || is_delaying) && flow_in.is_valid;
		ini.is_pc_changing= is_pc_changing;
		ini.early_flush= outi.early_flush;
	end : output_logic

endmodule
