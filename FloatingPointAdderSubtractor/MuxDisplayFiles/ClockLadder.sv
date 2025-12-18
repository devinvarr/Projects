//This is a N-bit clock divider or clock ladder.
module ClockLadder #(parameter N = 32)
(
	input clock, clear,
	output logic [N-1:0] Y
);
always_ff @ (posedge clock, negedge clear)
	if (~clear) Y <= 1'b0;
	else Y <= Y + 1'b1;
endmodule
