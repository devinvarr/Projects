//Top level, combining Keypad, Display, and main Logic Unit. 
module floatingPointAdderSubtactor	( 
input LoadA, LoadB, LoadR, 
input Clock, Reset, operation,
input [3:0] Row,
output [3:0] Col,
output [0:6] SEG, 
output [3:0] CAT
);

logic [31:0] SlowedClock;
logic [15:0] KeypadOut;
reg [15:0] reg_A, reg_B;
logic [15:0] R;
logic ShowResult;


always_ff@(negedge LoadA, negedge LoadB, negedge LoadR, negedge Reset) //Loading in of results on respective button press
if(~LoadA) reg_A <= KeypadOut;
else if (~LoadB) reg_B <= KeypadOut;
else if(~LoadR) ShowResult <= 1; //Control signal for input ternary to show result 
else if(~Reset) //Reset all registers 
begin 
	reg_A <= 0;
	reg_B <= 0;
	ShowResult <= 0;
end

keypad_input keypad_input_inst //Keypad Input capture.
(
	.clk(Clock) ,	// input  clk_sig
	.reset(Reset) ,	// input  reset_sig
	.row(Row) ,	// input [3:0] row_sig
	.col(Col) ,	// output [3:0] col_sig
	.out(KeypadOut) // output [((DIGITS*4)-1):0] out_sig
);

ClockLadder DisplayClockLadder //Clock Ladder for Mux Display. 
(
	.clock(Clock) ,	// input  clock_sig
	.clear(Reset) ,	// input  clear_sig
	.Y(SlowedClock) 	// output [(N-1):0] Y_sig
);
halfprecisionFPAS halfprecisionFPAS_inst //Instantiation of main logic unit (With debug outputs unlisted)
(
	.A(reg_A) ,	// input [15:0] A_sig
	.B(reg_B) ,	// input [15:0] B_sig
	.R(R) , 	// output [15:0] R_sig
	.operation (operation)
);


mux7seg mux7seg_inst //Multiplexed 7 Segment Display 
(
	.Clock(Clock) ,	// input  Clock_sig
	.Reset(Reset) ,	// input  Reset_sig
	.Load(SlowedClock[22]) ,	// input  Load_sig
	.HexIN((ShowResult) ? R : KeypadOut) ,	// input [15:0] HexIN_sig
	.SEG(SEG) ,	// output [0:6] SEG_sig
	.CAT(CAT) 	// output [3:0] CAT_sig
);

endmodule 