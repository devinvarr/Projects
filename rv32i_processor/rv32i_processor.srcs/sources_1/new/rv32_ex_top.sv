`timescale 1ns / 1ps


module rv32_ex_top(
// system clock and synchronous reset
input clk,
input reset,
// from id
input [31:0] pc_in,
input [31:0] iw_in,
input [31:0] rs1_data_in,
input [31:0] rs2_data_in,
input [4:0] wb_reg_in,
input wb_enable_in,
input write_enable_in,
input wb_sel_in,
input [4:0] rs1_reg_in,
input [4:0] rs2_reg_in,
// to mem
output reg [31:0] pc_out,
output reg [31:0] iw_out,
output reg [31:0] alu_out,
output reg [4:0] wb_reg_out,
output reg wb_enable_out,
output reg [31:0] rs2_data_out,
output reg write_enable_out,
output reg wb_sel_out,
//DF Outputs 
output df_ex_enable,
output [4:0] df_ex_reg,
output [31:0] df_ex_data,
// register df from wb (from mem_read)
input df_wb_from_mem_wb,
input [4:0] df_wb_reg,
input [31:0] df_wb_data,
//df to ID 
output df_wb_from_mem_ex
);

 logic [31:0] alu_out_hold;
 assign df_ex_enable = wb_enable_in;
 assign df_ex_reg = wb_reg_in;
 assign df_ex_data = alu_out_hold;
 assign df_wb_from_mem_ex = wb_sel_in;
 
 always_ff@(posedge (clk))
 begin
 if(reset) 
    alu_out <= 0;
 else 
    alu_out <= alu_out_hold;
 end
 
 logic [31:0] rs1_data_df, rs2_data_df;
 logic rs1_hazard, rs2_hazard;

//Detect rs1/rs2 hazard if wb stage = load and reg match in wb. 
 assign rs1_hazard = (df_wb_from_mem_wb && (rs1_reg_in == df_wb_reg));
 assign rs2_hazard = (df_wb_from_mem_wb && (rs2_reg_in == df_wb_reg));

 assign rs1_data_df = (rs1_hazard) ? df_wb_data : rs1_data_in;
 assign rs2_data_df = (rs2_hazard) ? df_wb_data : rs2_data_in;


 alu alu_inst
 (
    .pc_in(pc_in),
    . iw_in(iw_in),
    .rs1_data_in(rs1_data_df),
    .rs2_data_in(rs2_data_df),
    .alu_out(alu_out_hold)
 );
 
 always_ff @(posedge clk)
 begin 
 pc_out <= pc_in;
 iw_out <= iw_in;
 wb_reg_out <= wb_reg_in;
 wb_enable_out <= wb_enable_in;
 rs2_data_out <= rs2_data_df;
 write_enable_out <= write_enable_in;
 wb_sel_out <= wb_sel_in;
 end
endmodule
