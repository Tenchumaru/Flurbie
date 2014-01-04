module cache#(parameter N)(input clock, reset_n,
	input logic input_address_enable,
	input regval_t input_address,
	output logic output_address_enable,
	output regval_t output_address,
	input logic input_data_valid,
	input regval_t input_data,
	output logic output_data_valid,
	output regval_t output_data
);

	logic is_loaded[1 << N];
	regval_t lines[1 << N];

	// next state logic
	logic[N - 1:0] line_address;
	logic can_store;
	always_comb begin : next_state_logic
		line_address= N'(input_address >> 2);
		can_store= input_address_enable && input_data_valid;
	end : next_state_logic

	// state register
	always_ff@(posedge clock, negedge reset_n) begin : state_register
		if(!reset_n) begin
			is_loaded <= '{(1 << N){0}};
			lines <= '{(1 << N){0}};
		end else begin
			if(can_store) begin
				is_loaded[line_address] <= 1;
				lines[line_address] <= input_data;
			end
		end
	end : state_register

	// output logic
	logic is_available;
	always_comb begin : output_logic
		is_available= is_loaded[line_address];
		output_address_enable= input_address_enable && !is_available;
		output_address= input_address;
		output_data_valid= is_available || input_data_valid;
		output_data= is_available ? lines[line_address] : input_data;
	end : output_logic

endmodule
