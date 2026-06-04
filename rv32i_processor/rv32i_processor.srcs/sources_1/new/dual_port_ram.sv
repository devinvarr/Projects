`timescale 1ns / 1ps

module dual_port_ram #(parameter ADDR_WIDTH=15)
(
    // Clock
    input clk,
    
    // Instruction port (RO)
    input [31:2] i_addr,
    output reg [31:0] i_rdata,
    
    // Data port (RW)
    input [31:2] d_addr, 
    output reg [31:0] d_rdata, 
    input d_we,
    input [3:0] d_be,
    input [31:0] d_wdata
);
// Multi-dimensional packed array initialized by bit stream from "ram.hex"
//(* ram init_file & "ram.hex" *) logic [3:0][7:0] ram[ (2**ADDR_WIDTH) -1:0];
reg [31:0] ram [(2**ADDR_WIDTH)-1:0];
initial begin
$readmemh("ram.mem", ram, 0);
end
// Instruction fetch
always @ (posedge clk)
begin
    i_rdata <= ram[i_addr];
end

// Data r/w
always @(posedge clk)
begin
    if (d_we)
    begin
        if (d_be[0]) ram[d_addr][7:0]   <= d_wdata[7:0];
        if (d_be[1]) ram[d_addr][15:8]  <= d_wdata[15:8];
        if (d_be[2]) ram[d_addr][23:16] <= d_wdata[23:16];
        if (d_be[3]) ram[d_addr][31:24] <= d_wdata[31:24];
    end
    d_rdata <= ram[d_addr];
end
endmodule