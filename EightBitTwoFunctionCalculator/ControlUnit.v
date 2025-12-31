module ControlUnit(
	input trig, clock, ClearEntry, ClearAll,
	input [3:0] value,
	output reg LoadA, LoadB, LoadR, AddSub, IUAU,Clk, Reset,
	output reg [3:0] statedebug
);

	reg [2:0] state, nextstate;
	parameter S0_ClearIU=3'b000, S1_EnterA=3'b001, S1_LoadA=3'b010, S1_ClearIU=3'b011, S2_EnterB=3'b100,S2_LoadB= 3'b101, S3_LoadR=3'b110;
always @ (posedge clock, negedge ClearAll) //detect clock or clear
	if (ClearAll==0) state <= S0_ClearIU; 
		else state <= nextstate; //check for clear
always @ (state,trig,value) //trigger on state or input change
	case (state) //derive next state and output
		S0_ClearIU:begin  nextstate <= S1_EnterA; statedebug=S0_ClearIU; end 
				
		S1_EnterA: begin 
				if (value == 4'hA) begin AddSub =0; nextstate <=S1_LoadA ;end 
				else if (value == 4'hB) begin AddSub =1; nextstate <=S1_LoadA ;end 
				else nextstate <= S1_EnterA;
				statedebug= S1_EnterA;
				end
			
				
		S1_LoadA: begin nextstate<= S1_ClearIU; statedebug= S1_LoadA;end 
				
		S1_ClearIU: begin  nextstate<=S2_EnterB; statedebug= S1_ClearIU; end 
				
		S2_EnterB: begin if(value == 4'b1111) nextstate<=S2_LoadB;
						else nextstate <=S2_EnterB;
						statedebug = S2_EnterB;
						end
		S2_LoadB: begin nextstate<= S3_LoadR; statedebug = S2_LoadB; end
		
		S3_LoadR: begin nextstate <=S3_LoadR; statedebug = S3_LoadR; end 
		endcase
	always @ (*)
	begin
	if(ClearEntry==0) Reset=0;
	begin
		case(state)
		
		S0_ClearIU: begin
						Reset=0;
						LoadA=1;
						LoadB=1;
						LoadR=1;
						IUAU=0;
						end
				
		S1_EnterA: begin 
						Reset=1;
						LoadA=1;
						LoadB=1;
						LoadR=1;
						IUAU=0;
						end
			
				
		S1_LoadA: begin 
						Reset=1;
						LoadA=0;
						LoadB=1;
						LoadR=1;
						IUAU=0;
						end
				
		S1_ClearIU: begin 
						Reset=0;
						LoadA=1;
						LoadB=1;
						LoadR=1;
						IUAU=0;
						end
				
		S2_EnterB: begin 
						Reset=1;
						LoadA=1;
						LoadB=1;
						LoadR=1;
						IUAU=0;
						end
		
		S2_LoadB: begin 
						Reset=1;
						LoadA=1;
						LoadB=0;
						LoadR=1;
						IUAU=0;
						end
		
		S3_LoadR: begin 
						Reset=1;
						LoadA=1;
						LoadB=1;
						LoadR=0;
						IUAU=1;
						end
	
	endcase
	end
	end
endmodule