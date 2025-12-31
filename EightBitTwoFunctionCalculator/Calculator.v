module Calculator(
input ClearEntry, ClearAll, Clock,
input [3:0] row,
output [6:0] hex3, hex2, hex1, hex0,
output ZeroSig, OverflowSig,
output [3:0] col,
output [3:0] statedebug,
output clockout,
output Valid
);
//Control Unit Output wires
wire CUResetOut, CUClockOut, CUAddSub, CULoadA, CULoadB, CULoadR, CUiuau;
//Input Unit Output wires
wire IUTrigOut;
wire [7:0] IUOut;
wire [3:0] IUValueOut;
//AU Ouput wires
wire [7:0] AUOut;
wire [3:0] AUCCout;
//MUX Out
wire [7:0] MUXOut;
//Clock div wire
wire SlowClock;

clock_div#(32, 50000) clock_div_inst
(
	.clk(Clock) ,	// input  clk_sig
	.reset(~ClearAll) ,	// input  reset_sig
	.clk_out(SlowClock) 	// output  clk_out_sig
); 

ControlUnit ControlUnit_inst
(
	.trig(IUTrigOut) ,	// input  trig_sig
	.clock(SlowClock) ,	// input  clock_sig
	.ClearEntry(ClearEntry) ,	// input  ClearEntry_sig
	.ClearAll(ClearAll) ,	// input  ClearAll_sig
	.value(IUValueOut) ,	// input [3:0] value_sig
	.LoadA(CULoadA) ,	// output  LoadA_sig
	.LoadB(CULoadB) ,	// output  LoadB_sig
	.LoadR(CULoadR) ,	// output  LoadR_sig
	.AddSub(CUAddSub) ,	// output  AddSub_sig
	.IUAU(CUiuau) ,	// output  IUAU_sig
	.Clk(CUClockOut) ,	// output  Clk_sig
	.Reset(CUResetOut),// output  Reset_sig
	.statedebug(statedebug)
);

InputUnit InputUnit_inst
(
	.clk(Clock) ,	// input  clk_sig
	.reset(CUResetOut & ClearEntry) ,	// input  reset_sig
	.row(row) ,	// input [3:0] row_sig
	.col(col) ,	// output [3:0] col_sig
	.trig(IUTrigOut) ,	// output  trig_sig
	.value(IUValueOut) ,	// output [3:0] value_sig
	.IUOut(IUOut) ,	// output [7:0] IUOut_sig
	.ValidDetector(Valid)
);


EightBitTwoFunction EightBitTwoFunction_inst
(
	.A(IUOut) ,	// input [7:0] A_sig
	.InA(CULoadA) ,	// input  InA_sig
	.InB(CULoadB) ,	// input  InB_sig
	.Out(CULoadR) ,	// input  Out_sig
	.Clear(ClearAll) ,	// input  Clear_sig
	.Add_Subtract(CUAddSub) ,	// input  Add_Subtract_sig	
	.Rout(AUOut) ,	// output [7:0] Rout_sig
	.Ccout(AUCCout),// output [3:0] Ccout_sig
	.OverF(OverflowSig),
	.Empty(ZeroSig)
);


two2onemultiplex two2onemultiplex_inst
(
	.A(IUOut) ,	// input [7:0] A_sig
	.B(AUOut) ,	// input [7:0] B_sig
	.S(CUiuau) ,	// input  S_sig
	.Z(MUXOut) 	// output [7:0] Z_sig
);

OutputUnit OutputUnit_inst
(
	.Iput(MUXOut) ,	// input [7:0] IN_sig
	.hex3(hex3) ,	// output [6:0] hex3_sig
	.hex2(hex2) ,	// output [6:0] hex2_sig
	.hex1(hex1) ,	// output [6:0] hex1_sig
	.hex0(hex0) 	// output [6:0] hex0_sig
);




endmodule 