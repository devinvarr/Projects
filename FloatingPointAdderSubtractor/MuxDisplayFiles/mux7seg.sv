module mux7seg(
	input Clock,Reset,Load,
	input [15:0] HexIN,
	output [0:6] SEG, 
	output [3:0] CAT
);
	logic [1:0] SEL;
	logic [3:0] MuxOut;
	logic [15:0] RegOut;
	logic [31:0] MuxRate;
	
	//always @(posedge MuxRate, negedge Reset)
	//begin if(Reset == 0) RegOut<=0; end //else Regout <=HexIN; end 
	
	
	ClockLadder #(32) ClockLadder_inst
	(
		.clock(Clock) ,	// input  clock_sig
		.clear(Reset) ,	// input  clear_sig
		.Y(MuxRate) 	// output [(N-1):0] Y_sig
	);
		
	FSM FSM_inst
	(
		.slow_clock(MuxRate[17]) ,	// input  slow_clock_sig
		.reset(Reset) ,	// input  reset_sig
		.SEL(SEL) ,	// output [1:0] SEL_sig
		.CAT(CAT) 	// output [3:0] CAT_sig
	);

	four2one four2one_inst
	(
		.A(SEL[0]) ,	// input  A_sig
		.B(SEL[1]) ,	// input  B_sig
		.D0(RegOut[3:0]) ,	// input [(N-1):0] D0_sig
		.D1(RegOut[7:4]) ,	// input [(N-1):0] D1_sig
		.D2(RegOut[11:8]) ,	// input [(N-1):0] D2_sig
		.D3(RegOut[15:12]) ,	// input [(N-1):0] D3_sig
		.Y(MuxOut) 	// output [(N-1):0] Y_sig
	);
		
	hex2seven hex2seven_inst
	(
		.w(MuxOut[3]) ,	// input  w_sig
		.x(MuxOut[2]) ,	// input  x_sig
		.y(MuxOut[1]) ,	// input  y_sig
		.z(MuxOut[0]) ,	// input  z_sig
		.a(SEG[0]) ,	// output  a_sig
		.b(SEG[1]) ,	// output  b_sig
		.c(SEG[2]) ,	// output  c_sig
		.d(SEG[3]) ,	// output  d_sig
		.e(SEG[4]) ,	// output  e_sig
		.f(SEG[5]) ,	// output  f_sig
		.g(SEG[6]) 	// output  g_sig
	);

	NbitRegisterSV #(16) NbitRegisterSV_inst
	(
		.D(HexIN) ,	// input [(N-1):0] D_sig
		.CLK(Load) ,	// input  CLK_sig
		.CLR(Reset) ,	// input  CLR_sig
		.Q(RegOut) 	// output [(N-1):0] Q_sig
	);
 
endmodule
	