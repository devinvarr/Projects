`timescale 1ns / 1ps

module io_module #(parameter ADDR_WIDTH=12)
(
    // Clock
    input clk,
    
    // Data port (RW)
    input [31:2] io_addr, 
    output reg [31:0] io_rdata, 
    input io_we,
    input [3:0] io_be,
    input [31:0] io_wdata,
    //I/O Inputs / Outputs
    input [11:0] SW,
    input [3:0] PB, 
    output [9:0] LED
);
// Multi-dimensional packed array initialized by bit stream from "ram.hex"
//(* ram init_file & "ram.hex" *) logic [3:0][7:0] ram[ (2**ADDR_WIDTH) -1:0];
reg [31:0] IO_reg;

// Data r/w
always @(posedge clk)
begin
    if (io_we && io_addr[31] == 1)
    begin
        if (io_be[0]) IO_reg[7:0]   <= io_wdata[7:0];
        if (io_be[1]) IO_reg[15:8]  <= io_wdata[15:8];
        if (io_be[2]) IO_reg[23:16] <= io_wdata[23:16];
        if (io_be[3]) IO_reg[31:24] <= io_wdata[31:24];
    end
    io_rdata <= {PB,SW,IO_reg[15:0]};
end

assign LED = IO_reg[9:0]; //LED = io_wdata 

endmodule