`timescale 1ns / 1ps

module rv32_wb_top(
// system clock and synchronous reset
input clk,
input reset,
// from mem
input [31:0] pc_in,
input [31:0] iw_in,
input [31:0] alu_in,
input [4:0] wb_reg_in,
input wb_enable_in,
input wb_sel_in,
input [31:0] io_rdata_in,
input [31:0] mem_rdata_in,
// register interface
output regif_wb_enable,
output [4:0] regif_wb_reg,
output [31:0] regif_wb_data,
//DF Outputs 
output df_wb_enable,
output [4:0] df_wb_reg,
output [31:0] df_wb_data,
//DF to EX Stage 
output df_wb_from_mem_wb
);

//mux1 (choose mem_rdata or io_rdata)
logic [31:0] mem_io_rdata;
assign mem_io_rdata = (alu_in[31]) ? io_rdata_in : mem_rdata_in; //alu_in[31] = 1, choose IO. !alu_in[31], choose MEM

logic [31:0] d_rdata_shifted, d_rdata_to_regs;
logic [4:0] shamt;

assign shamt = (8 * alu_in [1:0]);
logic [1:0] width;
assign width = iw_in [13:12]; //Check funct3 for desired width

logic uns;
assign uns = (iw_in[14]) ? 1 : 0; //iw_in [14] = 1 for LBU, LHU, = 0 for others. 

 always_comb 
    begin
    d_rdata_shifted = mem_io_rdata >> (shamt);
    //Handle sign extension 
    case(width)
    //Word requested (Send whole), no need for extension 
    2'b10: d_rdata_to_regs = d_rdata_shifted;
    //Halfword requested 
    2'b01: begin 
           if(!uns)
             d_rdata_to_regs = {{16{d_rdata_shifted[15]}},d_rdata_shifted[15:0]}; //Signed case 
           else
             d_rdata_to_regs = {16'b0, d_rdata_shifted [15:0]}; //unsigned case 
           end
    //byte requested 
    2'b00: begin 
           if(!uns)
             d_rdata_to_regs = {{24{d_rdata_shifted[7]}},d_rdata_shifted[7:0]}; //Signed case 
           else
             d_rdata_to_regs = {24'b0, d_rdata_shifted [7:0]}; //unsigned case 
           end
    default: d_rdata_to_regs = 0;
    endcase
    end    

//mux2 (choose alu_in or d_rdata_to_regs)
logic [31:0] data_to_regs;
assign data_to_regs = (wb_sel_in) ? d_rdata_to_regs : alu_in;

//to ID (DF)
assign df_wb_enable = wb_enable_in;
assign df_wb_reg = wb_reg_in;
assign df_wb_data = data_to_regs;

//to REGS 
assign regif_wb_enable = wb_enable_in;
assign regif_wb_reg = wb_reg_in;
assign regif_wb_data = data_to_regs;

assign df_wb_from_mem_wb = wb_sel_in;

endmodule
