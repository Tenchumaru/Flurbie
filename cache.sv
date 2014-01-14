interface i_cache();
	logic address_enable;
	regval_t address;
	logic data_valid;
	regval_t data;

	modport impl(input address_enable, address, output data_valid, data);
	modport client(output address_enable, address, input data_valid, data);
endinterface

module cache#(parameter N)(input clock, reset_n,
	output logic address_enable,
	output regval_t address,
	input logic data_valid,
	input regval_t data,
	i_cache.impl a,
	i_cache.impl b
);

	logic is_loaded[1 << N];
	logic[N - 1:0] address_a, address_b;
	logic wren_a, wren_b;
	regval_t q_a, q_b;
	ram2#(N) lines(
		.aclr(!reset_n),
		.clock(!clock),
		.address_a,
		.address_b,
		.data_a(data),
		.data_b(data),
		.wren_a,
		.wren_b,
		.q_a,
		.q_b
	);

	// next state logic
	always_comb begin : next_state_logic
		address_a= N'(a.address >> 2);
		address_b= N'(b.address >> 2);
		wren_a= a.address_enable && data_valid;
		wren_b= 0;
	end : next_state_logic

	// state register
	always_ff@(posedge clock, negedge reset_n) begin : state_register
		if(!reset_n) begin
			is_loaded <= '{(1 << N){0}};
		end else if(wren_a) begin
			is_loaded[address_a] <= 1;
		end else if(wren_b) begin
			is_loaded[address_b] <= 1;
		end
	end : state_register

	// output logic
	logic is_available_a, is_available_b;
	always_comb begin : output_logic
		is_available_a= is_loaded[address_a];
		is_available_b= is_loaded[address_a];
		address_enable= a.address_enable && !is_available_a;
		address= a.address;
		a.data_valid= a.address_enable && (is_available_a || data_valid);
		a.data= is_available_a ? q_a : data;
		b.data_valid= b.address_enable && (is_available_b || data_valid);
		b.data= is_available_b ? q_b : data;
	end : output_logic
endmodule
