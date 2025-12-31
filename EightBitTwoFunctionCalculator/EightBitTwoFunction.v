module EightBitTwoFunction (
	input [7:0] A,											//declare data inputs							
	input InA, InB, Out, Clear, Add_Subtract, 	//declare control inputs
	output [7:0] Rout, 									//declare result output							
	output [3:0] Ccout,
	output OverF, Empty
);	//declare condition code output			
	//output [0:6] HEX2, HEX1, HEX0); 					//declare seven-segment outputs
//Declare internal nodes
	wire [7:0] Aout, Bout, R; 							//declare register outputs
	wire Cout, OV, ZERO, NEG; 							//declare condition codes	
	wire Over;												//FA second to last Cout for OV detection

//Make internal node assignments

//Instantiate registers A/B
	
	
	NBitRegister #(4'd8) regA  //Register A 
	(
		.D(A) ,	// data Input
		.CLK(InA) ,	// CLK input signal 
		.CLR(Clear) ,	// CLEAR input signal 
		.Q(Aout) 	// output [N-1:0] Q_sig
	);

	
	NBitRegister #(4'd8) regB	//Register B
	(
		.D(A) ,	// data Input																	
		.CLK(InB) ,	// CLK input signal 
		.CLR(Clear) ,	// CLEAR input signal 
		.Q(Bout) 	// output [N-1:0] Q_sig
	);


//Instantiate full adders

	RippleCarryAddSub RippleCarryAddSub
(
	.A(Aout) ,	// input [7:0] A_sig
	.B(Bout) ,	// input [7:0] B_sig
	.AddSub(Add_Subtract) ,	// input  AddSub_sig
	.R(R) ,	// output [7:0] R_sig
	.Over(Over) ,	// output  Over_sig
	.Cout(Cout) 	// output  Cout_sig
);


	//	assign Cout = C[8]; 																					
	   assign OverF = Over ^ Cout;
		assign NEG = R[7];
		assign Empty = ~(R[7]|R[6]|R[5]|R[4]|R[3]|R[2]|R[1]|R[0]);
		assign Rout = R;
//Instantiate Output Registers

	//Register CC
//	NBitRegister #(3'd4) regCC //4-bit register
//	(
//		.D({OV, Cout, NEG, ZERO}) , // Register CC input
//		.CLK(Out) , // Register CC load
//		.CLR(Clear) , // Register CC clear
//		.Q(Ccout) // Register CC output
//	);

	//Register R
//	NBitRegister #(4'd8) regR
//	(
//		.D(R) ,	// data Input
//		.CLK(Out) ,	// CLK input signal 
//		.CLR(Clear) ,	// CLEAR input signal 
//		.Q(Rout) 	// output [N-1:0] Q_sig
//	);
			
			
//Instantiate bin2sev decoders
//
//	bin2sevHEX Flags //Ccout Hex 
//	(
//		.I(Ccout) ,	// input [3:0] I_sig
//		.O(HEX2) 	// output [6:0] O_sig
//	);
//
//	bin2sevHEX leftfour //Left 4 bits of Rout
//	(
//		.I(Rout[7:4]) ,	// input [3:0] I_sig
//		.O(HEX1) 	// output [6:0] O_sig
//	);
//
//	bin2sevHEX rightfour //Right 4 bits of Rout
//	(
//		.I(Rout[3:0]) ,	// input [3:0] I_sig
//		.O(HEX0) 	// output [6:0] O_sig
//	);




endmodule
