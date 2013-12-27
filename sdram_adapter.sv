/*
http://www.alteraforum.com/forum/showthread.php?t=28501&p=114547#post114547

The read data valid and wait request can actually be 1 at the same time, if you
are doing pipelined transfers. Then the wait request is used to control the
read command flow, while the read data valid controls the read result flow. The
two processes in a pipeline transfer are almost independent and can happen any time.

You can simplify your interface by removing the readdatavalid signal, disabling
the pipelining. Or alternatively, to do a pipeline read:

    put the read signal at 1 and wait a clock cycle
    put it back at 0 as soon as waitrequest is 0
    wait for the readdatavalid signal to be 1
    read the data

http://www.alteraforum.com/forum/showthread.php?t=32178&p=131292#post131292

This post says "a slave cannot deassert wait and assert readdatavalid in the
same clock cycle" but I am seeing that behavior from the SDRAM controller.

http://www.alteraforum.com/forum/showthread.php?t=26957

This thread discusses the aforementioned violation and provides a test case of
a parameterized slave.
*/

// First, I'll try disabling pipelining by removing readdatavalid.

`timescale 1 ps / 1 ps
module sdram_adapter (
	output logic [24:0] avm_m0_address,       //    m0.address
	input  logic        avm_m0_waitrequest,   //      .waitrequest
	output logic        avm_m0_read_n,        //      .read_n
	input  logic [31:0] avm_m0_readdata,      //      .readdata
//	input  logic        avm_m0_readdatavalid, //      .readdatavalid
	output logic        avm_m0_write_n,       //      .write_n
	output logic [31:0] avm_m0_writedata,     //      .writedata
	input  logic        clk,                  // clock.clk
	input  logic        reset_n,              // reset.reset_n
	input  logic [31:0] read1_address,
	input  logic        read1_address_valid,
	output logic [31:0] read1_data,
	output logic        read1_data_ready,
	input  logic [31:0] read2_address,
	input  logic        read2_address_valid,
	output logic [31:0] read2_data,
	output logic        read2_data_ready,
	input  logic [31:0] write_address,
	input  logic        write_address_valid,
	input  logic [31:0] write_data,
	output logic        write_data_ready,
	output logic  [7:0] internal_status
);

	typedef enum logic[1:0] {Idle, Writing, Reading2, Reading1} statetype;
	statetype state, next_state;
	logic data_written, read_data_ready;

	// Fake it since I removed it as a signal.
	logic avm_m0_readdatavalid;
	assign avm_m0_readdatavalid= 1;

	assign data_written= !avm_m0_waitrequest;
	assign read_data_ready= !avm_m0_waitrequest && avm_m0_readdatavalid;

	// state register
	always_ff@(posedge clk, negedge reset_n) begin
		if(!reset_n)
			state <= Idle;
		else
			state <= next_state;
	end

	// next state logic
	always_comb begin
		case(state)
			Idle:
				if(write_address_valid)
					next_state= Writing;
				else if(read2_address_valid)
					next_state= Reading2;
				else if(read1_address_valid)
					next_state= Reading1;
				else
					next_state= Idle;
			Writing:
				if(data_written)
					next_state= Idle;
				else
					next_state= Writing;
			Reading2:
				if(read_data_ready)
					next_state= Idle;
				else
					next_state= Reading2;
			Reading1:
				if(read_data_ready)
					next_state= Idle;
				else
					next_state= Reading1;
			default:
				next_state= Idle;
		endcase
	end

	// For now, use only state.
	assign avm_m0_address= state == Writing ? write_address : state == Reading2 ? read2_address : read1_address;
	assign avm_m0_write_n= state != Writing && state != Writing;
	assign avm_m0_read_n= state != Reading2 && state != Reading1;
	assign internal_status= {reset_n, 5'b0, state};

	// output logic
	//assign avm_m0_address= next_state == Writing ? write_address : next_state == Reading2 ? read2_address : read1_address;
	//assign avm_m0_write_n= state != Writing && next_state != Writing;
	//assign avm_m0_read_n= state != Reading2 && state != Reading1 && next_state != Reading2 && next_state != Reading1;
	//assign internal_status= {reset_n, 5'b0, next_state};
	assign read1_data= avm_m0_readdata;
	assign read2_data= avm_m0_readdata;
	assign avm_m0_writedata= write_data;
	assign read1_data_ready= state == Reading1 && read_data_ready;
	assign read2_data_ready= state == Reading2 && read_data_ready;
	assign write_data_ready= state == Writing && data_written;

endmodule
