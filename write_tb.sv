`include "../../registers.sv"
`include "../../write.sv"

module write_tb();

parameter enforce_dont_cares= 1;

// inputs
logic reset_n;
logic clock;
logic data_valid;
regfile_t input_registers;
regval_t next_pc;

// outputs
regval_t address, expected_address;
regval_t data, expected_data;
logic has_flushed, expected_has_flushed;
logic address_enable, expected_address_enable;
regfile_t output_registers, expected_output_registers;

// interfaces
i_execute_to_write ini(), expected_ini();

write DUT(
	.reset_n,
	.clock,
	.data_valid,
	.input_registers,
	.next_pc,
	.address,
	.data,
	.has_flushed,
	.address_enable,
	.output_registers,
	.ini(ini.write_in)
);

logic test_setup_clock;

always begin
	test_setup_clock= 1; #25; test_setup_clock= 0; #50; test_setup_clock= 1; #25;
end

always begin
	clock= 1; #50; clock= 0; #50;
end

int fin, err, test_vector_index, errors, i;
string s, sin, sout;

initial begin
	fin= $fopen("../../write_tb.txt", "r");
	err= $fgets(s, fin);
	$display(s);
	test_vector_index= 0;
	errors= 0;
end

always@(posedge test_setup_clock) begin
	err = $fgets(s, fin);
	err= $sscanf(s, "%b %b %s %x %x %x %x %x %b %x %x %x %s %x %x %b %b %s %x", reset_n, data_valid, sin, next_pc, ini.pc, ini.adjustment, ini.destination_value, ini.destination, ini.flags, ini.destination_is_memory, ini.has_flushed, ini.is_valid, s, expected_address, expected_data, expected_has_flushed, expected_address_enable, sout, expected_ini.hold);
	if(err < 19) begin
		$display("%d tests completed with %d errors", test_vector_index, errors);
		$stop;
	end
	$display("line %2d: (%1d) %b %b %s %x %x %x %x %x %b %x %x %x %s %x %x %b %b %s %x", test_vector_index + 2, err, reset_n, data_valid, sin, next_pc, ini.pc, ini.adjustment, ini.destination_value, ini.destination, ini.flags, ini.destination_is_memory, ini.has_flushed, ini.is_valid, s, expected_address, expected_data, expected_has_flushed, expected_address_enable, sout, expected_ini.hold);
	input_registers[0]= 0;
	err= $sscanf(sin, "%x,%x,%x", input_registers[1], input_registers[2], input_registers[3]);
	for(i= err + 1; i < NR; ++i)
		input_registers[i]= input_registers[err];
	expected_output_registers[0]= 0;
	err= $sscanf(sout, "%x,%x,%x", expected_output_registers[1], expected_output_registers[2], expected_output_registers[3]);
	for(i= err + 1; i < NR; ++i)
		expected_output_registers[i]= expected_output_registers[err];
end

always@(negedge test_setup_clock) begin
	if(address !== expected_address && (enforce_dont_cares || expected_address !== 'X)
			|| data !== expected_data && (enforce_dont_cares || expected_data !== 'X)
			|| has_flushed !== expected_has_flushed && (enforce_dont_cares || expected_has_flushed !== 'X)
			|| address_enable !== expected_address_enable && (enforce_dont_cares || expected_address_enable !== 'X)
			|| output_registers != expected_output_registers && (enforce_dont_cares || expected_output_registers != 'X)
			|| ini.hold !== expected_ini.hold && (enforce_dont_cares || expected_ini.hold !== 'X)
			) begin
		$display("Error: inputs: reset_n=%b, data_valid=%b, input_registers=%s, next_pc=%x, ini.pc=%x, ini.adjustment=%x, ini.destination_value=%x, ini.destination=%x, ini.flags=%b, ini.destination_is_memory=%x, ini.has_flushed=%x, ini.is_valid=%x", reset_n, data_valid, sin, next_pc, ini.pc, ini.adjustment, ini.destination_value, ini.destination, ini.flags, ini.destination_is_memory, ini.has_flushed, ini.is_valid);
		errors += 1;
		if(address !== expected_address && (enforce_dont_cares || expected_address !== 'X))
			$display("output: address=%x (%x expected)", address, expected_address);
		if(data !== expected_data && (enforce_dont_cares || expected_data !== 'X))
			$display("output: data=%x (%x expected)", data, expected_data);
		if(has_flushed !== expected_has_flushed && (enforce_dont_cares || expected_has_flushed !== 'X))
			$display("output: has_flushed=%b (%b expected)", has_flushed, expected_has_flushed);
		if(address_enable !== expected_address_enable && (enforce_dont_cares || expected_address_enable !== 'X))
			$display("output: address_enable=%b (%b expected)", address_enable, expected_address_enable);
		if(output_registers != expected_output_registers && (enforce_dont_cares || expected_output_registers != 'X))
			$display("output: output_registers=%x,%x,%x (%x,%x,%x expected)", output_registers[1], output_registers[2], output_registers[3], expected_output_registers[1], expected_output_registers[2], expected_output_registers[3]);
		if(ini.hold !== expected_ini.hold && (enforce_dont_cares || expected_ini.hold !== 'X))
			$display("output: ini.hold=%x (%x expected)", ini.hold, expected_ini.hold);
	end else
		$display("okay");
	test_vector_index += 1;
end

endmodule

// reset_n data_valid input_registers next_pc ini.pc ini.adjustment ini.destination_value ini.destination ini.flags ini.destination_is_memory ini.has_flushed ini.is_valid  :  expected_address expected_data expected_has_flushed expected_address_enable expected_output_registers expected_ini.hold
