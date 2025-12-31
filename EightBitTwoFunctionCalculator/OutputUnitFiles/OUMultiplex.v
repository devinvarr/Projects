module OUMultiplex
(
input [3:0] A, B, //declare data inputs
input S, //declare select input
output [3:0] Z //declare output
);
assign Z = S==0 ? A : B; //select input
endmodule
