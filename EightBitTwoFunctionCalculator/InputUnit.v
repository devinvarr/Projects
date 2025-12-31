module InputUnit(
input clk,reset,
input [3:0] row, 
output [3:0] col,
output trig,
output [3:0] value,
output [7:0] IUOut,
output ValidDetector
);

wire [15:0] KeypadOut;
wire [7:0] BinarySMOut;



keypad_input keypad_input
(
	.clk(clk) ,	// input  clk_sig
	.reset(reset) ,	// input  reset_sig
	.row(row) ,	// input [3:0] row_sig
	.col(col) ,	// output [3:0] col_sig
	.out(KeypadOut) ,	// output [DIGITS*4-1:0] out_sig
	.value(value) ,	// output [3:0] value_sig
	.trig(trig) 	// output  trig_sig
);

BCD2BinarySM BCD2BinarySM
(
	.BCD(KeypadOut) ,	// input [15:0] BCD_sig
	.binarySM(BinarySMOut) 	// output [N-1:0] binarySM_sig
);

BinarySMToTwosComp BinarySMToTwosComp_inst
(
	.A(BinarySMOut[7:0]) ,	// input [N-1:0] A_sig
	.B(IUOut[6:0]) 	// output [N-1:0] B_sig
);
assign IUOut [7] = BinarySMOut[7];
assign ValidDetector = (IUOut<= 7'b01111111 && IUOut >= 7'b1000001) ? 1:0;
endmodule