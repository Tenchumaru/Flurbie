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
		outi.is_valid <= !ini.is_reading_memory || data_valid;
		outi.pc <= ini.pc;
		outi.operation <= ini.operation;
		outi.destination_register <= ini.destination_register;
		outi.left_value <= input_registers[ini.left_register];
		outi.right_value <= ini.is_reading_memory ? data : input_registers[ini.right_register];
		outi.address_register <= ini.address_register;
		outi.adjustment_operation <= ini.adjustment_operation;
		outi.adjustment_value <= ini.is_reading_memory && ini.is_writing_memory ?
			input_registers[ini.right_register] :
			ini.adjustment_value;
		outi.is_writing_memory <= ini.is_writing_memory;
		outi.has_flushed <= ini.has_flushed;
		// TODO:  lock the data bus if performing a cx operation.
	end else begin
		outi.is_valid <= 0;
		outi.has_flushed <= ini.has_flushed;
	end
end

assign address_enable= reset_n && ini.is_reading_memory;
assign address= input_registers[ini.address_register] + ini.adjustment_value;
assign ini.hold= reset_n && (outi.hold || (address_enable && !data_valid));

endmodule
