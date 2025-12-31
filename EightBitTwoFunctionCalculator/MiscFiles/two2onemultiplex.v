module two2onemultiplex
(
input [7:0] A, B, //declare data inputs
input S, //declare select input
output [7:0] Z //declare output
);
assign Z = S==0 ? A : B; //select input
endmodule
