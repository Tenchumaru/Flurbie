// I modified this file so adjustment_operation is %b instead of %x.

`include "../../registers.sv"
`include "../../decode.sv"

module decode_tb();

parameter enforce_dont_cares= 1;

// inputs
logic reset_n;
logic clock;
regfile_t registers;

// outputs

// interfaces
i_fetch_to_decode ini(), expected_ini();
i_decode_to_read outi(), expected_outi();

decode DUT(
	.reset_n,
	.clock,
	.registers,
	.ini(ini.decode_in),
	.outi(outi.decode_out)
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
	fin= $fopen("../../decode_tb.txt", "r");
	err= $fgets(s, fin);
	$display(s);
	test_vector_index= 0;
	errors= 0;
end

always@(posedge test_setup_clock) begin
	err = $fgets(s, fin);
	err= $sscanf(s, "%b %s %x %x %s %x %x %x %x %x %x %x %x %b %x %x %x %x", reset_n, sin, ini.instruction, outi.hold, s, expected_ini.hold, expected_ini.is_pc_changing, expected_outi.pc, expected_outi.adjustment, expected_outi.destination, expected_outi.left_register, expected_outi.right_register, expected_outi.operation, expected_outi.adjustment_operation, expected_outi.destination_is_memory, expected_outi.right_is_memory, expected_outi.has_flushed, expected_outi.is_valid);
	if(err < 18) begin
		$display("%d tests completed with %d errors", test_vector_index, errors);
		$stop;
	end
	$display("line %2d: (%1d) %b %s %x %x %s %x %x %x %x %x %x %x %x %b %x %x %x %x", test_vector_index + 2, err, reset_n, sin, ini.instruction, outi.hold, s, expected_ini.hold, expected_ini.is_pc_changing, expected_outi.pc, expected_outi.adjustment, expected_outi.destination, expected_outi.left_register, expected_outi.right_register, expected_outi.operation, expected_outi.adjustment_operation, expected_outi.destination_is_memory, expected_outi.right_is_memory, expected_outi.has_flushed, expected_outi.is_valid);
	registers[0]= 0;
	err= $sscanf(sin, "%x,%x,%x", registers[1], registers[2], registers[3]);
	for(i= err + 1; i < NR; ++i)
		registers[i]= registers[err];
end

always@(negedge test_setup_clock) begin
	if(ini.hold !== expected_ini.hold && (enforce_dont_cares || expected_ini.hold !== 'X)
			|| ini.is_pc_changing !== expected_ini.is_pc_changing && (enforce_dont_cares || expected_ini.is_pc_changing !== 'X)
			|| outi.pc !== expected_outi.pc && (enforce_dont_cares || expected_outi.pc !== 'X)
			|| outi.adjustment !== expected_outi.adjustment && (enforce_dont_cares || expected_outi.adjustment !== 'X)
			|| outi.destination !== expected_outi.destination && (enforce_dont_cares || expected_outi.destination !== 'X)
			|| outi.left_register !== expected_outi.left_register && (enforce_dont_cares || expected_outi.left_register !== 'X)
			|| outi.right_register !== expected_outi.right_register && (enforce_dont_cares || expected_outi.right_register !== 'X)
			|| outi.operation !== expected_outi.operation && (enforce_dont_cares || expected_outi.operation !== 'X)
			|| outi.adjustment_operation !== expected_outi.adjustment_operation && (enforce_dont_cares || expected_outi.adjustment_operation !== 'X)
			|| outi.destination_is_memory !== expected_outi.destination_is_memory && (enforce_dont_cares || expected_outi.destination_is_memory !== 'X)
			|| outi.right_is_memory !== expected_outi.right_is_memory && (enforce_dont_cares || expected_outi.right_is_memory !== 'X)
			|| outi.has_flushed !== expected_outi.has_flushed && (enforce_dont_cares || expected_outi.has_flushed !== 'X)
			|| outi.is_valid !== expected_outi.is_valid && (enforce_dont_cares || expected_outi.is_valid !== 'X)
			) begin
		$display("Error: inputs: reset_n=%b, registers=%s, ini.instruction=%x, outi.hold=%x", reset_n, sin, ini.instruction, outi.hold);
		errors += 1;
		if(ini.hold !== expected_ini.hold && (enforce_dont_cares || expected_ini.hold !== 'X))
			$display("output: ini.hold=%x (%x expected)", ini.hold, expected_ini.hold);
		if(ini.is_pc_changing !== expected_ini.is_pc_changing && (enforce_dont_cares || expected_ini.is_pc_changing !== 'X))
			$display("output: ini.is_pc_changing=%x (%x expected)", ini.is_pc_changing, expected_ini.is_pc_changing);
		if(outi.pc !== expected_outi.pc && (enforce_dont_cares || expected_outi.pc !== 'X))
			$display("output: outi.pc=%x (%x expected)", outi.pc, expected_outi.pc);
		if(outi.adjustment !== expected_outi.adjustment && (enforce_dont_cares || expected_outi.adjustment !== 'X))
			$display("output: outi.adjustment=%x (%x expected)", outi.adjustment, expected_outi.adjustment);
		if(outi.destination !== expected_outi.destination && (enforce_dont_cares || expected_outi.destination !== 'X))
			$display("output: outi.destination=%x (%x expected)", outi.destination, expected_outi.destination);
		if(outi.left_register !== expected_outi.left_register && (enforce_dont_cares || expected_outi.left_register !== 'X))
			$display("output: outi.left_register=%x (%x expected)", outi.left_register, expected_outi.left_register);
		if(outi.right_register !== expected_outi.right_register && (enforce_dont_cares || expected_outi.right_register !== 'X))
			$display("output: outi.right_register=%x (%x expected)", outi.right_register, expected_outi.right_register);
		if(outi.operation !== expected_outi.operation && (enforce_dont_cares || expected_outi.operation !== 'X))
			$display("output: outi.operation=%x (%x expected)", outi.operation, expected_outi.operation);
		if(outi.adjustment_operation !== expected_outi.adjustment_operation && (enforce_dont_cares || expected_outi.adjustment_operation !== 'X))
			$display("output: outi.adjustment_operation=%b (%b expected)", outi.adjustment_operation, expected_outi.adjustment_operation);
		if(outi.destination_is_memory !== expected_outi.destination_is_memory && (enforce_dont_cares || expected_outi.destination_is_memory !== 'X))
			$display("output: outi.destination_is_memory=%x (%x expected)", outi.destination_is_memory, expected_outi.destination_is_memory);
		if(outi.right_is_memory !== expected_outi.right_is_memory && (enforce_dont_cares || expected_outi.right_is_memory !== 'X))
			$display("output: outi.right_is_memory=%x (%x expected)", outi.right_is_memory, expected_outi.right_is_memory);
		if(outi.has_flushed !== expected_outi.has_flushed && (enforce_dont_cares || expected_outi.has_flushed !== 'X))
			$display("output: outi.has_flushed=%x (%x expected)", outi.has_flushed, expected_outi.has_flushed);
		if(outi.is_valid !== expected_outi.is_valid && (enforce_dont_cares || expected_outi.is_valid !== 'X))
			$display("output: outi.is_valid=%x (%x expected)", outi.is_valid, expected_outi.is_valid);
	end else
		$display("okay");
	test_vector_index += 1;
end

endmodule

// reset_n registers ini.instruction outi.hold  :  expected_ini.hold expected_ini.is_pc_changing expected_outi.pc expected_outi.adjustment expected_outi.destination expected_outi.left_register expected_outi.right_register expected_outi.operation expected_outi.adjustment_operation expected_outi.destination_is_memory expected_outi.right_is_memory expected_outi.has_flushed expected_outi.is_valid
