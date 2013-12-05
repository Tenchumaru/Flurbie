module read(
	input logic reset_n, clock, data_valid,
	input regval_t data,
	input regfile_t registers,
	i_decode_to_read.read_in ini,
	output logic address_enable,
	output regval_t address,
	i_read_to_execute.read_out outi
);

regfile_t input_registers;

assign input_registers= subst_in(ini.pc, registers);

always_ff@(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		outi.is_valid <= 0;
		outi.has_flushed <= 0;
	end else if(outi.hold) begin
		// TODO:  I can still fetch data from memory and hold it in a local
		// register, thus freeing the memory bus.
	end else if(ini.is_valid) begin
		outi.is_valid <= !ini.right_is_memory || data_valid;
		outi.pc <= ini.pc;
		outi.destination <= ini.destination;
		outi.destination_is_memory <= ini.destination_is_memory;
		outi.left_value <= input_registers[ini.left_register];
		outi.right_value <= ini.right_is_memory
			? data
			: input_registers[ini.right_register];
		outi.operation <= ini.operation;
		outi.adjustment <= ini.adjustment;
		outi.adjustment_operation <= ini.adjustment_operation;
		outi.has_flushed <= ini.has_flushed;
	end else begin
		outi.is_valid <= 0;
		outi.has_flushed <= ini.has_flushed;
	end
end

assign ini.hold= reset_n && (outi.hold || (address_enable && !data_valid));
assign address_enable= reset_n && ini.right_is_memory;
assign address= input_registers[ini.right_register] + ini.adjustment;

endmodule
