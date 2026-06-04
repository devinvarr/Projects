module rv32i_regs(
    input clk,
    input reset,
    // inputs
    input [4:0] rs1_reg,
    input [4:0] rs2_reg,
    input wb_enable,
    input [4:0] wb_reg,
    input [31:0] wb_data,
    // outputs
    output [31:0] rs1_data,
    output [31:0] rs2_data
 );
 
 reg [31:0] register [0:31];
 logic [31:0] rs1_data_hold, rs2_data_hold;
 assign register [0] = 0;
 
 always_ff@(posedge clk)
 begin
     if(reset)
     begin
        for(int i = 0; i < 32; i++)
            register [i] <= 0;
     end
      else if(wb_enable) 
      begin
        if(wb_reg > 0)
            register [wb_reg] <= wb_data;
      end
 end
 always_comb
 begin
 rs1_data_hold = register [rs1_reg] ;
 rs2_data_hold = register [rs2_reg] ;
 end
 
 assign rs1_data = rs1_data_hold;
 assign rs2_data = rs2_data_hold;
 
 
 reg [31:0] reg4,reg5,reg6,reg7;
 logic [10:0] count;

 always_ff @ (posedge clk)
 begin
  reg4 <= register [4];
  reg5 <= register [5];
  reg6 <= register [6];
  reg7 <= register [7];
  count <= count + 1;
 end
 
 
// ila_0 your_instance_name (
//	.clk(clk), // input wire clk


//	.probe0(reg4), // input wire [31:0]  probe0  
//	.probe1(reg5), // input wire [31:0]  probe1 
//	.probe2(reg6), // input wire [31:0]  probe2 
//	.probe3(reg7), // input wire [31:0]  probe3 
//	.probe4(wb_enable), // input wire [0:0]  probe4 
//	.probe5(wb_reg), // input wire [4:0]  probe5 
//	.probe6(wb_data) // input wire [31:0]  probe6
//);


ila_0 your_instance_name (
	.clk(clk), // input wire clk

	.probe0(reg4), // input wire [31:0]  probe0  
	.probe1(reg5), // input wire [31:0]  probe1 
	.probe2(reg6), // input wire [31:0]  probe2 
	.probe3(df_wb_from_mem_ex), // input wire [31:0]  probe3 
	.probe4(count), // input wire [10:0]  probe4 
	.probe5(wb_enable), // input wire [0:0]  probe5 
	.probe6(wb_reg), // input wire [4:0]  probe6 
	.probe7(wb_data) // input wire [31:0]  probe7
);

 endmodule