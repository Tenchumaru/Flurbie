/*
http://www.alteraforum.com/forum/showthread.php?t=28501&p=114547#post114547

"The read data valid and wait request can actually be 1 at the same time, if
you are doing pipelined transfers. Then the wait request is used to control the
read command flow, while the read data valid controls the read result flow. The
two processes in a pipeline transfer are almost independent and can happen any time.

You can simplify your interface by removing the readdatavalid signal, disabling
the pipelining. Or alternatively, to do a pipeline read:

    put the read signal at 1 and wait a clock cycle
    put it back at 0 as soon as waitrequest is 0
    wait for the readdatavalid signal to be 1
    read the data"

http://www.alteraforum.com/forum/showthread.php?t=32178&p=131292#post131292

This post says "a slave cannot deassert wait and assert readdatavalid in the
same clock cycle" but I am seeing that behavior from the SDRAM controller.

http://www.alteraforum.com/forum/showthread.php?t=26957

This thread discusses the aforementioned violation and provides a test case of
a parameterized slave.
*/

// First, I'll try disabling pipelining by removing readdatavalid.

module sdram_reader(
	output logic[24:0] avm_m0_address,       //    m0.address
	output logic       avm_m0_read_n,        //      .read_n
	input  logic[31:0] avm_m0_readdata,      //      .readdata
	input  logic       avm_m0_waitrequest,   //      .waitrequest
//	input  logic       avm_m0_readdatavalid, //      .readdatavalid
	input  logic       clk,                  // clock.clk
	input  logic       reset_n,              // reset.reset_n
	input  logic       read_n,
	input  logic[24:0] read_address,
	output logic[31:0] read_data,
	output logic       data_ready_n
);

assign avm_m0_address= read_address;
assign avm_m0_read_n= read_n;
assign read_data= avm_m0_readdata;
assign data_ready_n= avm_m0_waitrequest | read_n;

endmodule
