`timescale 1 ns / 1 ns
`include "../../registers.sv"
`include "../../fetch.sv"
`include "../../decode.sv"

module fd_tb();

parameter enforce_dont_cares= 1;

logic reset_n;
logic clock;

// fetch inputs
regfile_t registers;
logic has_flushed, data_valid;
regval_t data;

// decode to fetch
logic wait_n, is_pc_changing;

// fetch outputs
logic address_enable, expected_address_enable;
regval_t address, expected_address;
regval_t instruction, expected_instruction;
regval_t next_pc, expected_next_pc;

fetch the_fetch(
	.reset_n, .clock, .hold_n(wait_n), .is_pc_changing, .has_flushed, .data_valid,
	.pc(registers[PC]), .data, .address_enable,
	.address, .instruction, .next_pc
);

// decode inputs
logic hold_n;
logic read_ready, decode_valid;

// decode outputs
logic expected_wait_n;
logic output_valid, expected_output_valid;
logic expected_is_pc_changing;

// decode interfaces
i_decode_to_read outi(), expected_outi();

decode the_decode(
	.reset_n, .clock, .hold_n,
	.registers, .instruction,
	.wait_n, .output_valid, .is_pc_changing,
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
	fin= $fopen("../../fd_tb.txt", "r");
	err= $fgets(s, fin);
	$display(s);
	test_vector_index= 0;
	errors= 0;
end

always@(posedge test_setup_clock) begin
	err= $fscanf(fin, "%b %b %s %b %b %x %s %b %x %x %x %b %b %b %x %x %x %x %x %x %x %x %b %x", reset_n, hold_n, sin, has_flushed, data_valid, data, s, expected_address_enable, expected_address, expected_instruction, expected_next_pc, expected_wait_n, expected_output_valid, expected_is_pc_changing, expected_outi.pc, expected_outi.adjustment, expected_outi.operation, expected_outi.destination, expected_outi.left_register, expected_outi.right_register, expected_outi.destination_is_memory, expected_outi.right_is_memory, expected_outi.adjustment_operation, expected_outi.has_flushed);
	if(err < 23) begin
		$display("%d tests completed with %d errors", test_vector_index, errors);
		$stop;
	end
	$display("line %2d: (%1d) %b %b %s %b %b %x %s %b %x %x %x %b %b %b %x %x %x %x %x %x %x %x %b %x", test_vector_index + 2, err, reset_n, hold_n, sin, has_flushed, data_valid, data, s, expected_address_enable, expected_address, expected_instruction, expected_next_pc, expected_wait_n, expected_output_valid, expected_is_pc_changing, expected_outi.pc, expected_outi.adjustment, expected_outi.operation, expected_outi.destination, expected_outi.left_register, expected_outi.right_register, expected_outi.destination_is_memory, expected_outi.right_is_memory, expected_outi.adjustment_operation, expected_outi.has_flushed);
	registers[0]= 0;
	err= $sscanf(sin, "%x,%x,%x", registers[1], registers[2], registers[3]);
	for(i= err + 1; i < NR; ++i)
		registers[i]= registers[err];
end

always@(negedge test_setup_clock) begin
	if(address_enable !== expected_address_enable && (enforce_dont_cares || expected_address_enable !== 'X)
			|| address !== expected_address && (enforce_dont_cares || expected_address !== 'X)
			|| instruction !== expected_instruction && (enforce_dont_cares || expected_instruction !== 'X)
			|| next_pc !== expected_next_pc && (enforce_dont_cares || expected_next_pc !== 'X)
			|| wait_n !== expected_wait_n && (enforce_dont_cares || expected_wait_n !== 'X)
			|| output_valid !== expected_output_valid && (enforce_dont_cares || expected_output_valid !== 'X)
			|| is_pc_changing !== expected_is_pc_changing && (enforce_dont_cares || expected_is_pc_changing !== 'X)
			|| outi.pc !== expected_outi.pc && (enforce_dont_cares || expected_outi.pc !== 'X)
			|| outi.adjustment !== expected_outi.adjustment && (enforce_dont_cares || expected_outi.adjustment !== 'X)
			|| outi.operation !== expected_outi.operation && (enforce_dont_cares || expected_outi.operation !== 'X)
			|| outi.destination !== expected_outi.destination && (enforce_dont_cares || expected_outi.destination !== 'X)
			|| outi.left_register !== expected_outi.left_register && (enforce_dont_cares || expected_outi.left_register !== 'X)
			|| outi.right_register !== expected_outi.right_register && (enforce_dont_cares || expected_outi.right_register !== 'X)
			|| outi.destination_is_memory !== expected_outi.destination_is_memory && (enforce_dont_cares || expected_outi.destination_is_memory !== 'X)
			|| outi.right_is_memory !== expected_outi.right_is_memory && (enforce_dont_cares || expected_outi.right_is_memory !== 'X)
			|| outi.adjustment_operation !== expected_outi.adjustment_operation && (enforce_dont_cares || expected_outi.adjustment_operation !== 'X)
			|| outi.has_flushed !== expected_outi.has_flushed && (enforce_dont_cares || expected_outi.has_flushed !== 'X)) begin
		$display("Error: inputs: reset_n=%b, registers=%s, has_flushed=%b, data_valid=%b, data=%x, hold_n=%b, instruction=%x", reset_n, sin, has_flushed, data_valid, data, hold_n, instruction);
		errors += 1;
		if(address_enable !== expected_address_enable && (enforce_dont_cares || expected_address_enable !== 'X))
			$display("output: address_enable=%b (%b expected)", address_enable, expected_address_enable);
		if(address !== expected_address && (enforce_dont_cares || expected_address !== 'X))
			$display("output: address=%x (%x expected)", address, expected_address);
		if(instruction !== expected_instruction && (enforce_dont_cares || expected_instruction !== 'X))
			$display("output: instruction=%x (%x expected)", instruction, expected_instruction);
		if(next_pc !== expected_next_pc && (enforce_dont_cares || expected_next_pc !== 'X))
			$display("output: next_pc=%x (%x expected)", next_pc, expected_next_pc);
		if(wait_n !== expected_wait_n && (enforce_dont_cares || expected_wait_n !== 'X))
			$display("output: wait_n=%b (%b expected)", wait_n, expected_wait_n);
		if(output_valid !== expected_output_valid && (enforce_dont_cares || expected_output_valid !== 'X))
			$display("output: output_valid=%b (%b expected)", output_valid, expected_output_valid);
		if(is_pc_changing !== expected_is_pc_changing && (enforce_dont_cares || expected_is_pc_changing !== 'X))
			$display("output: is_pc_changing=%b (%b expected)", is_pc_changing, expected_is_pc_changing);
		if(outi.pc !== expected_outi.pc && (enforce_dont_cares || expected_outi.pc !== 'X))
			$display("output: outi.pc=%x (%x expected)", outi.pc, expected_outi.pc);
		if(outi.adjustment !== expected_outi.adjustment && (enforce_dont_cares || expected_outi.adjustment !== 'X))
			$display("output: outi.adjustment=%x (%x expected)", outi.adjustment, expected_outi.adjustment);
		if(outi.operation !== expected_outi.operation && (enforce_dont_cares || expected_outi.operation !== 'X))
			$display("output: outi.operation=%x (%x expected)", outi.operation, expected_outi.operation);
		if(outi.destination !== expected_outi.destination && (enforce_dont_cares || expected_outi.destination !== 'X))
			$display("output: outi.destination=%x (%x expected)", outi.destination, expected_outi.destination);
		if(outi.left_register !== expected_outi.left_register && (enforce_dont_cares || expected_outi.left_register !== 'X))
			$display("output: outi.left_register=%x (%x expected)", outi.left_register, expected_outi.left_register);
		if(outi.right_register !== expected_outi.right_register && (enforce_dont_cares || expected_outi.right_register !== 'X))
			$display("output: outi.right_register=%x (%x expected)", outi.right_register, expected_outi.right_register);
		if(outi.destination_is_memory !== expected_outi.destination_is_memory && (enforce_dont_cares || expected_outi.destination_is_memory !== 'X))
			$display("output: outi.destination_is_memory=%x (%x expected)", outi.destination_is_memory, expected_outi.destination_is_memory);
		if(outi.right_is_memory !== expected_outi.right_is_memory && (enforce_dont_cares || expected_outi.right_is_memory !== 'X))
			$display("output: outi.right_is_memory=%x (%x expected)", outi.right_is_memory, expected_outi.right_is_memory);
		if(outi.adjustment_operation !== expected_outi.adjustment_operation && (enforce_dont_cares || expected_outi.adjustment_operation !== 'X))
			$display("output: outi.adjustment_operation=%b (%b expected)", outi.adjustment_operation, expected_outi.adjustment_operation);
		if(outi.has_flushed !== expected_outi.has_flushed && (enforce_dont_cares || expected_outi.has_flushed !== 'X))
			$display("output: outi.has_flushed=%x (%x expected)", outi.has_flushed, expected_outi.has_flushed);
	end else
		$display("okay");
	test_vector_index += 1;
end

endmodule

// reset_n registers has_flushed data_valid data  :  expected_address_enable expected_address expected_instruction expected_next_pc expected_wait_n expected_output_valid expected_is_pc_changing expected_outi.pc expected_outi.adjustment expected_outi.operation expected_outi.destination expected_outi.left_register expected_outi.right_register expected_outi.destination_is_memory expected_outi.right_is_memory expected_outi.adjustment_operation expected_outi.has_flushed
