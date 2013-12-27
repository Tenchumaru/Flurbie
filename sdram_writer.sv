module sdram_writer(
	output logic[24:0] avm_m0_address,     //    m0.address
	output logic       avm_m0_write_n,     //      .write_n
	output logic[31:0] avm_m0_writedata,   //      .writedata
	input  logic       avm_m0_waitrequest, //      .waitrequest
	input  logic       clk,                // clock.clk
	input  logic       reset_n,            // reset.reset_n
	input  logic       write_n,
	input  logic[24:0] write_address,
	input  logic[31:0] write_data,
	output logic       data_written_n
);

	assign avm_m0_address= write_address;
	assign avm_m0_write_n= write_n;
	assign avm_m0_writedata= write_data;
	assign data_written_n= avm_m0_waitrequest | write_n;

endmodule
