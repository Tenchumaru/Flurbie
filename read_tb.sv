`include "../../registers.sv"
`include "../../read.sv"

module read_tb();

parameter enforce_dont_cares= 1;

// inputs
logic reset_n;
logic clock;
logic data_valid;
regval_t data;
regfile_t registers;

// outputs
logic address_enable, expected_address_enable;
regval_t address, expected_address;

// interfaces
i_decode_to_read ini(), expected_ini();
i_read_to_execute outi(), expected_outi();

read DUT(
	.reset_n,
	.clock,
	.data_valid,
	.data,
	.registers,
	.address_enable,
	.address,
	.ini(ini.read_in),
	.outi(outi.read_out)
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
	fin= $fopen("../../read_tb.txt", "r");
	err= $fgets(s, fin);
	$display(s);
	test_vector_index= 0;
	errors= 0;
end

always@(posedge test_setup_clock) begin
	err = $fgets(s, fin);
	err= $sscanf(s, "%b %b %x %s %x %x %x %x %x %x %x %x %x %x %x %x %s %b %x %x %x %x %x %x %x %x %x %x %x %x", reset_n, data_valid, data, sin, ini.pc, ini.adjustment, ini.destination, ini.left_register, ini.right_register, ini.operation, ini.adjustment_operation, ini.destination_is_memory, ini.right_is_memory, ini.has_flushed, ini.is_valid, outi.hold, s, expected_address_enable, expected_address, expected_ini.hold, expected_outi.pc, expected_outi.adjustment, expected_outi.left_value, expected_outi.right_value, expected_outi.destination, expected_outi.operation, expected_outi.adjustment_operation, expected_outi.destination_is_memory, expected_outi.has_flushed, expected_outi.is_valid);
	if(err < 30) begin
		$display("%d tests completed with %d errors", test_vector_index, errors);
		$stop;
	end
	$display("line %2d: (%1d) %b %b %x %s %x %x %x %x %x %x %x %x %x %x %x %x %s %b %x %x %x %x %x %x %x %x %x %x %x %x", test_vector_index + 2, err, reset_n, data_valid, data, sin, ini.pc, ini.adjustment, ini.destination, ini.left_register, ini.right_register, ini.operation, ini.adjustment_operation, ini.destination_is_memory, ini.right_is_memory, ini.has_flushed, ini.is_valid, outi.hold, s, expected_address_enable, expected_address, expected_ini.hold, expected_outi.pc, expected_outi.adjustment, expected_outi.left_value, expected_outi.right_value, expected_outi.destination, expected_outi.operation, expected_outi.adjustment_operation, expected_outi.destination_is_memory, expected_outi.has_flushed, expected_outi.is_valid);
	registers[0]= 0;
	err= $sscanf(sin, "%x,%x,%x", registers[1], registers[2], registers[3]);
	for(i= err + 1; i < NR; ++i)
		registers[i]= registers[err];
end

always@(negedge test_setup_clock) begin
	if(address_enable !== expected_address_enable && (enforce_dont_cares || expected_address_enable !== 'X)
			|| address !== expected_address && (enforce_dont_cares || expected_address !== 'X)
			|| ini.hold !== expected_ini.hold && (enforce_dont_cares || expected_ini.hold !== 'X)
			|| outi.pc !== expected_outi.pc && (enforce_dont_cares || expected_outi.pc !== 'X)
			|| outi.adjustment !== expected_outi.adjustment && (enforce_dont_cares || expected_outi.adjustment !== 'X)
			|| outi.left_value !== expected_outi.left_value && (enforce_dont_cares || expected_outi.left_value !== 'X)
			|| outi.right_value !== expected_outi.right_value && (enforce_dont_cares || expected_outi.right_value !== 'X)
			|| outi.destination !== expected_outi.destination && (enforce_dont_cares || expected_outi.destination !== 'X)
			|| outi.operation !== expected_outi.operation && (enforce_dont_cares || expected_outi.operation !== 'X)
			|| outi.adjustment_operation !== expected_outi.adjustment_operation && (enforce_dont_cares || expected_outi.adjustment_operation !== 'X)
			|| outi.destination_is_memory !== expected_outi.destination_is_memory && (enforce_dont_cares || expected_outi.destination_is_memory !== 'X)
			|| outi.has_flushed !== expected_outi.has_flushed && (enforce_dont_cares || expected_outi.has_flushed !== 'X)
			|| outi.is_valid !== expected_outi.is_valid && (enforce_dont_cares || expected_outi.is_valid !== 'X)
			) begin
		$display("Error: inputs: reset_n=%b, data_valid=%b, data=%x, registers=%s, ini.pc=%x, ini.adjustment=%x, ini.destination=%x, ini.left_register=%x, ini.right_register=%x, ini.operation=%x, ini.adjustment_operation=%x, ini.destination_is_memory=%x, ini.right_is_memory=%x, ini.has_flushed=%x, ini.is_valid=%x, outi.hold=%x", reset_n, data_valid, data, sin, ini.pc, ini.adjustment, ini.destination, ini.left_register, ini.right_register, ini.operation, ini.adjustment_operation, ini.destination_is_memory, ini.right_is_memory, ini.has_flushed, ini.is_valid, outi.hold);
		errors += 1;
		if(address_enable !== expected_address_enable && (enforce_dont_cares || expected_address_enable !== 'X))
			$display("output: address_enable=%b (%b expected)", address_enable, expected_address_enable);
		if(address !== expected_address && (enforce_dont_cares || expected_address !== 'X))
			$display("output: address=%x (%x expected)", address, expected_address);
		if(ini.hold !== expected_ini.hold && (enforce_dont_cares || expected_ini.hold !== 'X))
			$display("output: ini.hold=%x (%x expected)", ini.hold, expected_ini.hold);
		if(outi.pc !== expected_outi.pc && (enforce_dont_cares || expected_outi.pc !== 'X))
			$display("output: outi.pc=%x (%x expected)", outi.pc, expected_outi.pc);
		if(outi.adjustment !== expected_outi.adjustment && (enforce_dont_cares || expected_outi.adjustment !== 'X))
			$display("output: outi.adjustment=%x (%x expected)", outi.adjustment, expected_outi.adjustment);
		if(outi.left_value !== expected_outi.left_value && (enforce_dont_cares || expected_outi.left_value !== 'X))
			$display("output: outi.left_value=%x (%x expected)", outi.left_value, expected_outi.left_value);
		if(outi.right_value !== expected_outi.right_value && (enforce_dont_cares || expected_outi.right_value !== 'X))
			$display("output: outi.right_value=%x (%x expected)", outi.right_value, expected_outi.right_value);
		if(outi.destination !== expected_outi.destination && (enforce_dont_cares || expected_outi.destination !== 'X))
			$display("output: outi.destination=%x (%x expected)", outi.destination, expected_outi.destination);
		if(outi.operation !== expected_outi.operation && (enforce_dont_cares || expected_outi.operation !== 'X))
			$display("output: outi.operation=%x (%x expected)", outi.operation, expected_outi.operation);
		if(outi.adjustment_operation !== expected_outi.adjustment_operation && (enforce_dont_cares || expected_outi.adjustment_operation !== 'X))
			$display("output: outi.adjustment_operation=%x (%x expected)", outi.adjustment_operation, expected_outi.adjustment_operation);
		if(outi.destination_is_memory !== expected_outi.destination_is_memory && (enforce_dont_cares || expected_outi.destination_is_memory !== 'X))
			$display("output: outi.destination_is_memory=%x (%x expected)", outi.destination_is_memory, expected_outi.destination_is_memory);
		if(outi.has_flushed !== expected_outi.has_flushed && (enforce_dont_cares || expected_outi.has_flushed !== 'X))
			$display("output: outi.has_flushed=%x (%x expected)", outi.has_flushed, expected_outi.has_flushed);
		if(outi.is_valid !== expected_outi.is_valid && (enforce_dont_cares || expected_outi.is_valid !== 'X))
			$display("output: outi.is_valid=%x (%x expected)", outi.is_valid, expected_outi.is_valid);
	end else
		$display("okay");
	test_vector_index += 1;
end

endmodule

// reset_n data_valid data registers ini.pc ini.adjustment ini.destination ini.left_register ini.right_register ini.operation ini.adjustment_operation ini.destination_is_memory ini.right_is_memory ini.has_flushed ini.is_valid outi.hold  :  expected_address_enable expected_address expected_ini.hold expected_outi.pc expected_outi.adjustment expected_outi.left_value expected_outi.right_value expected_outi.destination expected_outi.operation expected_outi.adjustment_operation expected_outi.destination_is_memory expected_outi.has_flushed expected_outi.is_valid
