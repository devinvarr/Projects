module rv32_mem_top(
// system clock and synchronous reset
input clk,
input reset,
// from ex
input [31:0] pc_in,
input [4:0] wb_reg_in,
input wb_enable_in,
input [31:0] iw_in,
input [31:0] alu_in,
input write_enable,
input wb_sel_in,
input [31:0] rs2_data_in,
// to wb
output reg [31:0] pc_out,
output reg [31:0] iw_out,
output reg [31:0] alu_out,
output reg [4:0] wb_reg_out,
output reg wb_enable_out,
output reg wb_sel_out,
//DF Outputs 
output df_mem_enable,
output [4:0] df_mem_reg,
output [31:0] df_mem_data,
// memory interface
 output [31:2] memif_addr,
 input [31:0] memif_rdata,
 output [31:0] memif_rdata_out,
 output memif_we,
 output [3:0] memif_be,
 output [31:0] memif_wdata,
// io interface
output [31:2] io_addr,
input [31:0] io_rdata,
output [31:0] io_rdata_out,
output io_we,
output [3:0] io_be,
output [31:0] io_wdata,
//df to ID
output df_wb_from_mem_mem
);

 assign df_mem_enable = wb_enable_in;
 assign df_mem_reg = wb_reg_in;
 assign df_mem_data = alu_in;
 logic mem_io;
 assign df_wb_from_mem_mem = wb_sel_in;
 
 
//5 - Route alu_in to both addr outputs
assign memif_addr = alu_in [31:2];
assign io_addr    = alu_in [31:2];
assign mem_io     = alu_in [31];

//6 - Generate memif_we, io_we signals
assign memif_we = (write_enable && !mem_io); //memif_we is active when A31 is low
assign io_we    = (write_enable &&  mem_io); //io_we is active when A31 is high

//Generate memif_be, io_be

logic [1:0] width;
assign width = iw_in [13:12]; //Check funct3 for desired width
logic [3:0] memif_be_hold, io_be_hold;


   always_comb
   begin
   case(width)
   //2 = word ( Use BE 3-0)
   2'b10: begin memif_be_hold = 4'b1111; 
                io_be_hold    = 4'b0011;
          end
   
   //1 = halfword -breakdown further 
   2'b01:  begin
           io_be_hold    = 4'b0011;
           case(alu_in [1:0])
           2'd0: memif_be_hold = 4'b0011;
           2'd1: memif_be_hold = 4'b0110;
           2'd2: memif_be_hold = 4'b1100;
           default: memif_be_hold = 4'b0000;
           endcase
           end
   //0 = byte - breakdown further
   2'b00:  begin
           case(alu_in [1:0])
           2'd0: begin memif_be_hold = 4'b0001;    io_be_hold = 4'b0001; end
           2'd1: begin memif_be_hold = 4'b0010;    io_be_hold = 4'b0010; end
           2'd2: begin memif_be_hold = 4'b0100;    io_be_hold = 4'b0001; end 
           2'd3: begin memif_be_hold = 4'b1000;    io_be_hold = 4'b0001; end
           default: begin memif_be_hold = 4'b0000; io_be_hold = 4'b0001; end
           endcase
           end
    default:memif_be_hold = 4'b0000;
    
    endcase
    end
assign memif_be = memif_be_hold;
assign io_be = io_be_hold;

//7 - Route the rs2 data from the ID stage to both memif_wdata and io_wdata.
logic [4:0] shamt;
assign shamt = (8 * alu_in [1:0]);
assign memif_wdata = rs2_data_in << (shamt);
assign io_wdata    = rs2_data_in << (shamt);
 
//8 - Make both memif_rdata and io_rdata available for use in the WB stage
assign memif_rdata_out = memif_rdata;
assign io_rdata_out = io_rdata;


always_ff @(posedge clk)
begin 
pc_out <= pc_in;
iw_out <= iw_in;
alu_out <= alu_in;
wb_reg_out <= wb_reg_in;
wb_enable_out <= wb_enable_in;
wb_sel_out <= wb_sel_in;
end



endmodule 
