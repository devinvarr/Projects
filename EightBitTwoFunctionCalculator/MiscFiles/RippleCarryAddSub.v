//Ripple Carry Adder Structural Model. Top module.
module RippleCarryAddSub ( //name the module
	input [7:0] A, B, //declare input ports
	input AddSub,
	output [7:0] R,
	output Over,//declare output ports for Result
	output Cout); 	//declare carry-out port
	wire [8:0] C; 	//declare internal nets
		assign C[0] = AddSub; //assign 0 to least significant carry-in
		assign Cout = C[8]; //rename carry-out port
	//instantiate the full adder module for each stage of the ripple carry adder
	FAbehav s0 (A[0], B[0]^C[0], C[0], R[0], C[1]); //stage 0
	FAbehav s1 (A[1], B[1]^C[0], C[1], R[1], C[2]); //stage 1
	FAbehav s2 (A[2], B[2]^C[0], C[2], R[2], C[3]); //stage 2
	FAbehav s3 (A[3], B[3]^C[0], C[3], R[3], C[4]); //stage 3
	FAbehav s4 (A[4], B[4]^C[0], C[4], R[4], C[5]); //stage 0
	FAbehav s5 (A[5], B[5]^C[0], C[5], R[5], C[6]); //stage 1
	FAbehav s6 (A[6], B[6]^C[0], C[6], R[6], C[7]); //stage 2
	FAbehav s7 (A[7], B[7]^C[0], C[7], R[7], C[8]); //stage 3
	assign Over = C[7];
endmodule



//TODO:: Modify each instance of the B inputs to be B XOR C0 instead of each B.  -COMPLETE
//C[0] should be equal to AddSub instead of Fixed value.									-COMPLETE
//change the results to R instead of S															-COMPLETE
//need an addsub input? 																			-COMPLETE

//look at recording and diagram for further changes if needed
//do pin assignments, input testing, print diagrams for notebook. 