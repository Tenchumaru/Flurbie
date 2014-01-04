module cpu(
	//////////// CLOCK //////////
	input logic CLOCK_50

	//////////// LED //////////
	, output logic[7:0] LED

	//////////// KEY //////////
	, input logic[1:0] KEY

	//////////// SW //////////
	, input logic[3:0] SW

	//////////// SDRAM //////////
	, output logic[12:0] DRAM_ADDR
	, output logic[1:0] DRAM_BA
	, output logic DRAM_CAS_N
	, output logic DRAM_CKE
	, output logic DRAM_CLK
	, output logic DRAM_CS_N
	, inout logic[15:0] DRAM_DQ
	, output logic[1:0] DRAM_DQM
	, output logic DRAM_RAS_N
	, output logic DRAM_WE_N
//
////////////// EEPROM //////////
//, output logic I2C_SCLK
//, inout logic I2C_SDAT
);

	logic clock, reset_n;

	assign clock= CLOCK_50;
	assign reset_n= KEY[0] & KEY[1];
	assign LED= ia[7:0];

	logic[24:0] instruction_read_address;
	logic[31:0] instruction_read_data;
	logic instruction_read_n, instruction_data_ready_n;
	logic[24:0] read_data_read_address;
	logic[31:0] read_data_read_data;
	logic read_data_read_n, read_data_data_ready_n;
	logic[24:0] write_data_write_address;
	logic[31:0] write_data_write_data;
	logic write_data_write_n, write_data_data_written_n;

	system the_system(
		.clk_clk                   (clock),                     //         clk.clk
		.reset_reset_n             (reset_n),                   //       reset.reset_n
		.sdram_addr                (DRAM_ADDR),                 //       sdram.addr
		.sdram_ba                  (DRAM_BA),                   //            .ba
		.sdram_cas_n               (DRAM_CAS_N),                //            .cas_n
		.sdram_cke                 (DRAM_CKE),                  //            .cke
		.sdram_cs_n                (DRAM_CS_N),                 //            .cs_n
		.sdram_dq                  (DRAM_DQ),                   //            .dq
		.sdram_dqm                 (DRAM_DQM),                  //            .dqm
		.sdram_ras_n               (DRAM_RAS_N),                //            .ras_n
		.sdram_we_n                (DRAM_WE_N),                 //            .we_n
		.instruction_read_address  (instruction_read_address),  // instruction.read_address
		.instruction_read_n        (instruction_read_n),        //            .read_n
		.instruction_read_data     (instruction_read_data),     //            .read_data
		.instruction_data_ready_n  (instruction_data_ready_n),  //            .data_ready_n
		.read_data_read_address    (read_data_read_address),    //   read_data.read_address
		.read_data_read_n          (read_data_read_n),          //            .read_n
		.read_data_read_data       (read_data_read_data),       //            .read_data
		.read_data_data_ready_n    (read_data_data_ready_n),    //            .data_ready_n
		.write_data_write_data     (write_data_write_data),     //  write_data.write_data
		.write_data_data_written_n (write_data_data_written_n), //            .data_written_n
		.write_data_write_n        (write_data_write_n),        //            .write_n
		.write_data_write_address  (write_data_write_address)   //            .write_address
	);
	assign DRAM_CLK= clock;

	logic cache_address_enable;
	regval_t cache_address;
	logic cache_data_valid;
	regval_t cache_data;
	cache#(6) the_cache(.clock, .reset_n,
		.input_address_enable(ia_enable),
		.input_address(ia),
		.output_address_enable(cache_address_enable),
		.output_address(cache_address),
		.input_data_valid(!instruction_data_ready_n),
		.input_data(instruction_read_data),
		.output_data_valid(cache_data_valid),
		.output_data(cache_data)
	);
	assign instruction_read_n= !cache_address_enable;
	assign instruction_read_address= {cache_address[24:2], 2'h0};

	logic ia_enable, iv_valid, da_in_enable, dv_in_valid, da_out_enable, dv_out_valid;
	regval_t ia, iv, da_in, dv_in, da_out, dv_out;

	core the_core(
		.reset_n, .clock,
		.ia, .ia_enable, .iv_valid, .iv,
		.da_in, .da_in_enable, .dv_in, .dv_in_valid,
		.da_out, .da_out_enable, .dv_out, .dv_out_valid
	);

	// instruction
	assign iv= cache_data;
	assign iv_valid= cache_data_valid;

	// data read
	always_comb begin
		read_data_read_address= {da_in[24:2], 2'h0};
		if(SW[3] & SW[2]) begin
			dv_in= read_data_read_data;
			read_data_read_n= !da_in_enable;
			dv_in_valid= !read_data_data_ready_n;
		end else begin
			dv_in= 0;
			read_data_read_n= 1;
			dv_in_valid= 1;
		end
	end

	// data write
	always_comb begin
		write_data_write_address= {da_out[24:2], 2'h0};
		write_data_write_data= dv_out;
		if(SW[1] & SW[0]) begin
			write_data_write_n= !da_out_enable;
			dv_out_valid= !write_data_data_written_n;
		end else begin
			write_data_write_n= 1;
			dv_out_valid= 1;
		end
	end

endmodule
