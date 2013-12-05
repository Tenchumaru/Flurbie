// I modified this file so ini.adjustment_operation is %b instead of %x.

`include "../../registers.sv"
`include "../../execute.sv"

module execute_tb();

parameter enforce_dont_cares= 1;

// inputs
logic reset_n;
logic clock;
regfile_t registers;

// outputs

// interfaces
i_read_to_execute ini(), expected_ini();
i_execute_to_write outi(), expected_outi();

execute DUT(
	.reset_n,
	.clock,
	.registers,
	.ini(ini.execute_in),
	.outi(outi.execute_out)
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
	fin= $fopen("../../execute_tb.txt", "r");
	err= $fgets(s, fin);
	$display(s);
	test_vector_index= 0;
	errors= 0;
end

always@(posedge test_setup_clock) begin
	err = $fgets(s, fin);
	err= $sscanf(s, "%b %s %x %x %x %x %x %x %b %x %x %x %x %s %x %x %x %x %x %b %x %x %x", reset_n, sin, ini.pc, ini.adjustment, ini.left_value, ini.right_value, ini.destination, ini.operation, ini.adjustment_operation, ini.destination_is_memory, ini.has_flushed, ini.is_valid, outi.hold, s, expected_ini.hold, expected_outi.pc, expected_outi.adjustment, expected_outi.destination_value, expected_outi.destination, expected_outi.flags, expected_outi.destination_is_memory, expected_outi.has_flushed, expected_outi.is_valid);
	if(err < 23) begin
		$display("%d tests completed with %d errors", test_vector_index, errors);
		$stop;
	end
	$display("line %2d: (%1d) %b %s %x %x %x %x %x %x %b %x %x %x %x %s %x %x %x %x %x %b %x %x %x", test_vector_index + 2, err, reset_n, sin, ini.pc, ini.adjustment, ini.left_value, ini.right_value, ini.destination, ini.operation, ini.adjustment_operation, ini.destination_is_memory, ini.has_flushed, ini.is_valid, outi.hold, s, expected_ini.hold, expected_outi.pc, expected_outi.adjustment, expected_outi.destination_value, expected_outi.destination, expected_outi.flags, expected_outi.destination_is_memory, expected_outi.has_flushed, expected_outi.is_valid);
	registers[0]= 0;
	err= $sscanf(sin, "%x,%x,%x", registers[1], registers[2], registers[3]);
	for(i= err + 1; i < NR; ++i)
		registers[i]= registers[err];
end

always@(negedge test_setup_clock) begin
	if(ini.hold !== expected_ini.hold && (enforce_dont_cares || expected_ini.hold !== 'X)
			|| outi.pc !== expected_outi.pc && (enforce_dont_cares || expected_outi.pc !== 'X)
			|| outi.adjustment !== expected_outi.adjustment && (enforce_dont_cares || expected_outi.adjustment !== 'X)
			|| outi.destination_value !== expected_outi.destination_value && (enforce_dont_cares || expected_outi.destination_value !== 'X)
			|| outi.destination !== expected_outi.destination && (enforce_dont_cares || expected_outi.destination !== 'X)
			|| outi.flags !== expected_outi.flags && (enforce_dont_cares || expected_outi.flags !== 'X)
			|| outi.destination_is_memory !== expected_outi.destination_is_memory && (enforce_dont_cares || expected_outi.destination_is_memory !== 'X)
			|| outi.has_flushed !== expected_outi.has_flushed && (enforce_dont_cares || expected_outi.has_flushed !== 'X)
			|| outi.is_valid !== expected_outi.is_valid && (enforce_dont_cares || expected_outi.is_valid !== 'X)
			) begin
		$display("Error: inputs: reset_n=%b, registers=%s, ini.pc=%x, ini.adjustment=%x, ini.left_value=%x, ini.right_value=%x, ini.destination=%x, ini.operation=%x, ini.adjustment_operation=%b, ini.destination_is_memory=%x, ini.has_flushed=%x, ini.is_valid=%x, outi.hold=%x", reset_n, sin, ini.pc, ini.adjustment, ini.left_value, ini.right_value, ini.destination, ini.operation, ini.adjustment_operation, ini.destination_is_memory, ini.has_flushed, ini.is_valid, outi.hold);
		errors += 1;
		if(ini.hold !== expected_ini.hold && (enforce_dont_cares || expected_ini.hold !== 'X))
			$display("output: ini.hold=%x (%x expected)", ini.hold, expected_ini.hold);
		if(outi.pc !== expected_outi.pc && (enforce_dont_cares || expected_outi.pc !== 'X))
			$display("output: outi.pc=%x (%x expected)", outi.pc, expected_outi.pc);
		if(outi.adjustment !== expected_outi.adjustment && (enforce_dont_cares || expected_outi.adjustment !== 'X))
			$display("output: outi.adjustment=%x (%x expected)", outi.adjustment, expected_outi.adjustment);
		if(outi.destination_value !== expected_outi.destination_value && (enforce_dont_cares || expected_outi.destination_value !== 'X))
			$display("output: outi.destination_value=%x (%x expected)", outi.destination_value, expected_outi.destination_value);
		if(outi.destination !== expected_outi.destination && (enforce_dont_cares || expected_outi.destination !== 'X))
			$display("output: outi.destination=%x (%x expected)", outi.destination, expected_outi.destination);
		if(outi.flags !== expected_outi.flags && (enforce_dont_cares || expected_outi.flags !== 'X))
			$display("output: outi.flags=%x (%x expected)", outi.flags, expected_outi.flags);
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

// reset_n registers ini.pc ini.adjustment ini.left_value ini.right_value ini.destination ini.operation ini.adjustment_operation ini.destination_is_memory ini.has_flushed ini.is_valid outi.hold  :  expected_ini.hold expected_outi.pc expected_outi.adjustment expected_outi.destination_value expected_outi.destination expected_outi.flags expected_outi.destination_is_memory expected_outi.has_flushed expected_outi.is_valid
