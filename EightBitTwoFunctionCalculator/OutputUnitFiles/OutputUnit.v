module OutputUnit(
	input [7:0] Iput,
	output [6:0] hex3, hex2, hex1, hex0
);
	wire [7:0] MagOut;
	wire [3:0] Ones, Tens;
	wire [1:0] Hundreds;
	
	wire [3:0] HundredsNORM;
	wire [3:0] HundredsMulti;
	wire [3:0] TensMulti;
	wire [3:0] Suppress;
	assign Suppress = 4'b1111;
	assign HundredsNORM [1] = Hundreds [1];
	assign HundredsNORM [0] = Hundreds [0];
	
	
OUMultiplex OUMultiplexHUNDREDS
(
	.A(HundredsNORM) ,	// input [4:0] A_sig
	.B(Suppress) ,	// input [4:0] B_sig
	.S((Hundreds==2'b00)) ,	// input  S_sig
	.Z(HundredsMulti) 	// output [4:0] Z_sig
);

OUMultiplex OUMultiplexTENS
(
	.A(Tens) ,	// input [4:0] A_sig
	.B(Suppress) ,	// input [4:0] B_sig
	.S((Hundreds==2'b00 && Tens==4'b0000)) ,	// input  S_sig
	.Z(TensMulti) 	// output [4:0] Z_sig
);


	//Twos comp to sign mag
	TwosCompToSignMagnitude #(4'd8) twoscomp
	(
		.A(Iput) ,	// input [N-1:0] A_sig
		.B(MagOut) 	// output [N-1:0] B_sig
	);

	//Sign mag to BCD
	binary2bcd b2bcd
	(
		.A(MagOut) ,	// input [7:0] A_sig
		.ONES(Ones) ,	// output [3:0] ONES_sig
		.TENS(Tens) ,	// output [3:0] TENS_sig
		.HUNDREDS(Hundreds) 	// output [1:0] HUNDREDS_sig
	);

	//BCD to seven seg
	bcd2sevenOU bcd2sev1
	(
		.w(Ones[3]) ,	// input  w_sig
		.x(Ones[2]) ,	// input  x_sig
		.y(Ones[1]) ,	// input  y_sig
		.z(Ones[0]) ,	// input  z_sig
		.a(hex0[0]) ,	// output  a_sig
		.b(hex0[1]) ,	// output  b_sig
		.c(hex0[2]) ,	// output  c_sig
		.d(hex0[3]) ,	// output  d_sig
		.e(hex0[4]) ,	// output  e_sig
		.f(hex0[5]) ,	// output  f_sig
		.g(hex0[6]) 	// output  g_sig
	); 

	bcd2sevenOU bcd2sev2
	(
		.w(TensMulti[3]) ,	// input  w_sig
		.x(TensMulti[2]) ,	// input  x_sig
		.y(TensMulti[1]) ,	// input  y_sig
		.z(TensMulti[0]) ,	// input  z_sig
		.a(hex1[0]) ,	// output  a_sig
		.b(hex1[1]) ,	// output  b_sig
		.c(hex1[2]) ,	// output  c_sig 
		.d(hex1[3]) ,	// output  d_sig
		.e(hex1[4]) ,	// output  e_sig
		.f(hex1[5]) ,	// output  f_sig
		.g(hex1[6]) 	// output  g_sig
	); 

	bcd2sevenOU bcd2sev3
	(
		.w(HundredsMulti[3]) ,	// input  w_sig
		.x(HundredsMulti[2]) ,	// input  x_sig
		.y(HundredsMulti[1]) ,	// input  y_sig
		.z(HundredsMulti[0]) ,	// input  z_sig
		.a(hex2[0]) ,	// output  a_sig
		.b(hex2[1]) ,	// output  b_sig
		.c(hex2[2]) ,	// output  c_sig
		.d(hex2[3]) ,	// output  d_sig
		.e(hex2[4]) ,	// output  e_sig
		.f(hex2[5]) ,	// output  f_sig
		.g(hex2[6]) 	// output  g_sig
	); 
assign hex3[6:0] = (Iput[7] == 1'b1) ? 7'b0111111 : 7'b1111111;
endmodule