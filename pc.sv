module pc(input logic reset_n, clock, stall_n, output logic[31:0] ia);

logic[31:2] next_ia, offset;

always_comb begin
	if(stall_n)
		offset= 30'b1;
	else
		offset= 30'b0;
end

always_ff@(posedge clock, negedge reset_n) begin
	if(!reset_n)
		next_ia <= 0;
	else
		next_ia <= ia[31:2] + offset;
end

assign ia= {next_ia[31:2], 2'b0};

endmodule
