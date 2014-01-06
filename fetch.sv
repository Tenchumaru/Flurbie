module fetch(
	input regfile_t registers,
	output logic address_enable,
	output regval_t address,
	input logic data_valid,
	input regval_t data,
	i_flow_control.out flow_out,
	i_write_to_fetch.fetch_in ini,
	i_fetch_to_decode.fetch_out outi
);

	// next state logic
	logic is_flushing, next_is_flushing, is_valid;
	regval_t pc;
	always_comb begin : next_state_logic
		next_is_flushing= outi.is_pc_changing || (is_flushing && !(outi.early_flush || ini.has_flushed));
		// Fetch needs to wait for memory to respond.
		is_valid= data_valid;
		pc= registers[PC];
	end : next_state_logic

	// state register
	always_ff@(posedge flow_out.clock, negedge flow_out.reset_n) begin : state_register
		if(!flow_out.reset_n) begin
			is_flushing <= 0;
			flow_out.is_valid <= 0;
			outi.instruction <= Nop;
			outi.pc <= 0;
		end else begin
			is_flushing <= next_is_flushing;
			if(!flow_out.hold) begin
				flow_out.is_valid <= is_valid;
				outi.instruction <= data;
				outi.pc <= pc;
			end
		end
	end : state_register

	// output logic
	always_comb begin : output_logic
		if(!flow_out.reset_n) begin
			address_enable= 1;
			address= 0;
			ini.next_pc= 0;
		end else begin
			address_enable= !next_is_flushing && !flow_out.hold;
			address= pc;
			if(data_valid && !next_is_flushing && !flow_out.hold ? 4 : 0)
				ini.next_pc= pc + 4;
			else
				ini.next_pc= pc;
		end
	end : output_logic

endmodule
