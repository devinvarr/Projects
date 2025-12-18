//HEX to seven-segment decoder. Active low output.

module hex2seven ( //name the module
	input w,x,y,z, //declare inputs
	output logic a,b,c,d,e,f,g
); //declare outputs, use logic data type
always_comb //always block triggers on w, x, y, or z changing value
	case ({w,x,y,z}) //case statement describes the truth table
		4'b0000: {a,b,c,d,e,f,g} = 7'b1111110; //0
		4'b0001: {a,b,c,d,e,f,g} = 7'b0110000; //1
		4'b0010: {a,b,c,d,e,f,g} = 7'b1101101; //2
		4'b0011: {a,b,c,d,e,f,g} = 7'b1111001; //3
		4'b0100: {a,b,c,d,e,f,g} = 7'b0110011; //4
		4'b0101: {a,b,c,d,e,f,g} = 7'b1011011; //5
		4'b0110: {a,b,c,d,e,f,g} = 7'b1011111; //6
		4'b0111: {a,b,c,d,e,f,g} = 7'b1110000; //7
		4'b1000: {a,b,c,d,e,f,g} = 7'b1111111; //8
		4'b1001: {a,b,c,d,e,f,g} = 7'b1110011; //9
		4'b1010: {a,b,c,d,e,f,g} = 7'b1110111; //A
		4'b1011: {a,b,c,d,e,f,g} = 7'b0011111; //B
		4'b1100: {a,b,c,d,e,f,g} = 7'b1001110; //C
		4'b1101: {a,b,c,d,e,f,g} = 7'b0111101; //D
		4'b1110: {a,b,c,d,e,f,g} = 7'b1001111; //E
		4'b1111: {a,b,c,d,e,f,g} = 7'b1000111; //F
	endcase
endmodule
