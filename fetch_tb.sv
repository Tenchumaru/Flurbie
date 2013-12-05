`include "../../registers.sv"
`include "../../fetch.sv"

module fetch_tb();

parameter enforce_dont_cares= 1;

// inputs
logic reset_n;
logic clock;
logic has_flushed;
logic data_valid;
regval_t pc;
regval_t data;

// outputs
logic address_enable, expected_address_enable;
regval_t address, expected_address;
regval_t next_pc, expected_next_pc;

// interfaces
i_fetch_to_decode outi(), expected_outi();

fetch DUT(
	.reset_n,
	.clock,
	.has_flushed,
	.data_valid,
	.pc,
	.data,
	.address_enable,
	.address,
	.next_pc,
	.outi(outi.fetch_out)
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
	fin= $fopen("../../fetch_tb.txt", "r");
	err= $fgets(s, fin);
	$display(s);
	test_vector_index= 0;
	errors= 0;
end

always@(posedge test_setup_clock) begin
	err = $fgets(s, fin);
	err= $sscanf(s, "%b %b %b %x %x %x %x %s %b %x %x %x", reset_n, has_flushed, data_valid, pc, data, outi.hold, outi.is_pc_changing, s, expected_address_enable, expected_address, expected_next_pc, expected_outi.instruction);
	if(err < 12) begin
		$display("%d tests completed with %d errors", test_vector_index, errors);
		$stop;
	end
	$display("line %2d: (%1d) %b %b %b %x %x %x %x %s %b %x %x %x", test_vector_index + 2, err, reset_n, has_flushed, data_valid, pc, data, outi.hold, outi.is_pc_changing, s, expected_address_enable, expected_address, expected_next_pc, expected_outi.instruction);
end

always@(negedge test_setup_clock) begin
	if(address_enable !== expected_address_enable && (enforce_dont_cares || expected_address_enable !== 'X)
			|| address !== expected_address && (enforce_dont_cares || expected_address !== 'X)
			|| next_pc !== expected_next_pc && (enforce_dont_cares || expected_next_pc !== 'X)
			|| outi.instruction !== expected_outi.instruction && (enforce_dont_cares || expected_outi.instruction !== 'X)
			) begin
		$display("Error: inputs: reset_n=%b, has_flushed=%b, data_valid=%b, pc=%x, data=%x, outi.hold=%x, outi.is_pc_changing=%x", reset_n, has_flushed, data_valid, pc, data, outi.hold, outi.is_pc_changing);
		errors += 1;
		if(address_enable !== expected_address_enable && (enforce_dont_cares || expected_address_enable !== 'X))
			$display("output: address_enable=%b (%b expected)", address_enable, expected_address_enable);
		if(address !== expected_address && (enforce_dont_cares || expected_address !== 'X))
			$display("output: address=%x (%x expected)", address, expected_address);
		if(next_pc !== expected_next_pc && (enforce_dont_cares || expected_next_pc !== 'X))
			$display("output: next_pc=%x (%x expected)", next_pc, expected_next_pc);
		if(outi.instruction !== expected_outi.instruction && (enforce_dont_cares || expected_outi.instruction !== 'X))
			$display("output: outi.instruction=%x (%x expected)", outi.instruction, expected_outi.instruction);
	end else
		$display("okay");
	test_vector_index += 1;
end

endmodule

// reset_n has_flushed data_valid pc data outi.hold outi.is_pc_changing  :  expected_address_enable expected_address expected_next_pc expected_outi.instruction
