module rv32_if_top(
// system clock and synchronous reset
input clk,
input reset,
// memory interface
output [31:2] memif_addr,
input [31:0] memif_data,

// to id
output reg [31:0] pc_out,
output [31:0] iw_out,
input stop,
// from id
input jump_enable_in,
input [31:0] jump_addr_in,
input stall_in
);

reg [31:0] PC;
parameter [31:0] PC_RESET = 32'h00000000;

//PC generation. Either RESET, PC + 4, or Halt PC incrementation
always_ff @(posedge clk)
begin 
if(reset) 
    PC <= PC_RESET;
else if(!stall_in && !stop)
begin
    PC <= (jump_enable_in) ? jump_addr_in : (PC + 4);
end
end

//PC drives memif_addr directly
assign memif_addr = PC [31:2];

//PC is registered to drive pc_out
always_ff@(posedge clk)
begin
pc_out <= PC;
end

//memif_data directly drives iw_out.
assign iw_out = memif_data;

endmodule 