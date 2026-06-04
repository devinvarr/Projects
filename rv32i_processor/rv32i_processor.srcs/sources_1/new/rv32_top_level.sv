`timescale 1ns / 1ps



module rv32_top_level(
input CLK100,           // 100 MHz clock input
    output [9:0] LED,       // RGB1, RGB0, LED 9..0 placed from left to right
    output [2:0] RGB0,      
    output [2:0] RGB1,
    output [3:0] SS_ANODE,   // Anodes 3..0 placed from left to right
    output [7:0] SS_CATHODE, // Bit order: DP, G, F, E, D, C, B, A
    input [11:0] SW,         // SWs 11..0 placed from left to right
    input [3:0] PB,          // PBs 3..0 placed from left to right
    inout [23:0] GPIO,       // PMODA-C 1P, 1N, ... 3P, 3N order
    output [3:0] SERVO,      // Servo outputs
    output PDM_SPEAKER,      // PDM signals for mic and speaker
    input PDM_MIC_DATA,      
    output PDM_MIC_CLK,
    output ESP32_UART1_TXD,  // WiFi/Bluetooth serial interface 1
    input ESP32_UART1_RXD,
    output IMU_SCLK,         // IMU spi clk
    output IMU_SDI,          // IMU spi data input
    input IMU_SDO_AG,        // IMU spi data output (accel/gyro)
    input IMU_SDO_M,         // IMU spi data output (mag)
    output IMU_CS_AG,        // IMU cs (accel/gyro) 
    output IMU_CS_M,         // IMU cs (mag)
    input IMU_DRDY_M,        // IMU data ready (mag)
    input IMU_INT1_AG,       // IMU interrupt (accel/gyro)
    input IMU_INT_M,         // IMU interrupt (mag)
    output IMU_DEN_AG        // IMU data enable (accel/gyro)
    );
     
    // Terminate all of the unused outputs or i/o's
    // assign LED = 10'b0000000000;
    assign RGB0 = 3'b000;
    assign RGB1 = 3'b000;
    // assign SS_ANODE = 4'b0000;
    // assign SS_CATHODE = 8'b11111111;
    // assign GPIO = 24'bzzzzzzzzzzzzzzzzzzzzzzzz;
    assign GPIO[15:0] = 16'bzzzzzzzzzzzzzzzz;
    assign GPIO[23:20] = 4'bzzzz;
    assign GPIO[18] = 1'bz;
    assign SERVO = 4'b0000;
    assign PDM_SPEAKER = 1'b0;
    assign PDM_MIC_CLK = 1'b0;
    assign ESP32_UART1_TXD = 1'b0;
    assign IMU_SCLK = 1'b0;
    assign IMU_SDI = 1'b0;
    assign IMU_CS_AG = 1'b1;
    assign IMU_CS_M = 1'b1;
    assign IMU_DEN_AG = 1'b0;


    // red and green leds
    reg red_led;
    reg green_led;
    assign red_led = GPIO[17];
    assign green_led = GPIO[19];
    
    // use a simpler clock name
    wire clk = CLK100;
    
    // handle input metastability safely
    reg reset;
    reg pre_reset;
    always_ff @ (posedge(clk))
    begin
        pre_reset <= PB[0];
        reset <= pre_reset;
    end

    //RAM -> IF Interface 
    logic [31:2] if_addr;
    logic [31:0] if_data;
    
    //MEM -> RAM ->MEM Interface 
    logic [31:2] d_addr;
    logic [31:0] d_rdata, d_wdata;
    logic d_we;
    logic [3:0] d_be;
    
    dual_port_ram ram_inst
    (
    .clk(clk),
    // Instruction port (RO)
    .i_addr(if_addr),  //input [31:2] 
    .i_rdata(if_data),//output reg [31:0] 
    //Data port (RW)
    .d_addr(d_addr), //input [31:2] 
    .d_rdata(d_rdata),//output reg [31:0] 
    .d_we(d_we),   //input 
    .d_be(d_be),   //input [3:0] 
    .d_wdata(d_wdata) //input [31:0] 
    );
    
    //IF -> ID Interface 
    logic [31:0] if_id_pc, if_id_iw;
    
    logic ebreak, stop;
    
    always_ff @ (posedge clk)
    begin
    if(reset)
        stop <= 0;
    else if(ebreak)
        stop <= 1;
    end
    //ID -> IF interface (Branch handling)
    logic jump_enable;
    logic [31:0] jump_addr;
    logic stall;
    
     rv32_if_top if_inst(
    .clk(clk),// system clock
    .reset(reset), // and synchronous reset
    .memif_addr(if_addr), //output [31:2]
    .memif_data(if_data), // input [31:0]
    .pc_out(if_id_pc), //output  reg [31:0]
    .iw_out(if_id_iw), //output  [31:0]
    .stop(stop),//input for EBREAK, to stop PC
    .jump_enable_in(jump_enable), //input from ID
    .jump_addr_in(jump_addr), //input [31:0] from ID
    .stall_in(stall)
    );
    
    //Register -> ID interface 
    logic [4:0] rs1_reg, rs2_reg;
    logic [31:0] rs1_data, rs2_data;
    //ID -> EX Interface
    logic [31:0] id_ex_pc, id_ex_iw;
    logic [4:0] id_ex_wb_reg, rs1_reg_out, rs2_reg_out;
    logic  id_ex_wb_enable, id_ex_write_enable, id_ex_wb_sel;
    logic [31:0] id_ex_rs1_data, id_ex_rs2_data;
    
    
    //Data Forwarding Interfacing
    logic  df_ex_enable, df_mem_enable, df_wb_enable; //df enable 
    logic [4:0] df_ex_reg, df_mem_reg, df_wb_reg;//df register 
    logic [31:0] df_ex_data, df_mem_data, df_wb_data;// df data
    logic df_wb_from_mem_ex, df_wb_from_mem_mem, df_wb_from_mem_wb;
    
    rv32_id_top id_inst(
    .clk(clk),
    .reset(reset),
    //from IF
    .pc_in(if_id_pc), //input [31:0] 
    .iw_in(if_id_iw), //input  [31:0] 
    //to IF
    .jump_enable_out(jump_enable), //output to IF
    .jump_addr_out(jump_addr), //ouput [31:0] to IF
    //to register interface
    .regif_rs1_reg(rs1_reg), //ouput  [4:0] 
    .regif_rs2_reg(rs2_reg), //output [4:0] 
    .regif_rs1_data(rs1_data), //input  [31:0] 
    .regif_rs2_data(rs2_data), //input  [31:0] 
    //to EX
    .pc_out(id_ex_pc), //output reg [31:0]
    .iw_out(id_ex_iw), //output reg [31:0]
    .wb_reg_out(id_ex_wb_reg), //output reg [4:0]
    .wb_enable_out(id_ex_wb_enable), //output reg 
    .rs1_data_out(id_ex_rs1_data), //output reg [31:0] 
    .rs2_data_out(id_ex_rs2_data), //output reg [31:0]
    .write_enable_out(id_ex_write_enable), //Output reg
    .wb_sel(id_ex_wb_sel), //output reg
    .rs1_reg_out(rs1_reg_out), //output reg [4:0]
    .rs2_reg_out(rs2_reg_out), //output reg [4:0]
    //to IF
    .ebreak(ebreak), //output for EBREAK DETECT 
    //DF / Hazard Detection 
    .df_ex_enable(df_ex_enable), //input 
    .df_ex_reg(df_ex_reg), //input [4:0] 
    .df_ex_data(df_ex_data),// input [31:0] 
    // data hazard: df from mem
    .df_mem_enable(df_mem_enable), //input
    .df_mem_reg(df_mem_reg), // input [4:0]
    .df_mem_data(df_mem_data), //input [31:0]
    // data hazard: df from wb
    .df_wb_enable(df_wb_enable), //input
    .df_wb_reg(df_wb_reg), //input [4:0]
    .df_wb_data(df_wb_data), //input [31:0]
    // register df from ex
    .df_wb_from_mem_ex(df_wb_from_mem_ex), //input 
    // register df from mem
    .df_wb_from_mem_mem(df_wb_from_mem_mem), //input
    //notify IF of stall
    .stall_out(stall)//output 
    );
    
    //EX -> MEM Interface 
    logic [31:0] ex_mem_pc, ex_mem_iw, ex_mem_alu, ex_mem_rs2_data;
    logic [4:0] ex_mem_wb_reg;
    logic  ex_mem_wb_enable, ex_mem_write_enable, ex_mem_wb_sel;
  
    
    rv32_ex_top ex_inst(
    .clk(clk),
    .reset(reset),
    //from ID
    .pc_in(id_ex_pc), //input [31:0]
    .iw_in(id_ex_iw), //input [31:0]
    .rs1_data_in(id_ex_rs1_data),//input [31:0]
    .rs2_data_in(id_ex_rs2_data),//input [31:0]
    .wb_reg_in(id_ex_wb_reg),//input [4:0]
    .wb_enable_in(id_ex_wb_enable), //input 
    .write_enable_in(id_ex_write_enable), //input
    .wb_sel_in(id_ex_wb_sel), //input
    .rs1_reg_in(rs1_reg_out), //input [4:0]
    .rs2_reg_in(rs2_reg_out), //input [4:0]
    //to MEM
    .pc_out(ex_mem_pc), //output reg [31:0]
    .iw_out(ex_mem_iw),//output reg [31:0]
    .alu_out(ex_mem_alu),//output reg [31:0]
    .wb_reg_out(ex_mem_wb_reg),//output reg [4:0]
    .wb_enable_out(ex_mem_wb_enable),//output reg 
    .rs2_data_out(ex_mem_rs2_data), //output reg [31:0]
    .write_enable_out(ex_mem_write_enable), //output reg
    .wb_sel_out(ex_mem_wb_sel), //output reg
    //DF / Hazard detection 
    .df_ex_enable(df_ex_enable), //output
    .df_ex_reg(df_ex_reg), //output [4:0] 
    .df_ex_data(df_ex_data), //output [31:0] 
    // register df from wb (from mem_read)
    .df_wb_from_mem_wb(df_wb_from_mem_wb), //input 
    .df_wb_reg(df_wb_reg), //input [4:0] 
    .df_wb_data(df_wb_data), //input [31:0] 
    .df_wb_from_mem_ex(df_wb_from_mem_ex) //output
    );
    
    //MEM -> WB Interface 
    logic [31:0] mem_wb_pc, mem_wb_iw, mem_wb_alu, mem_wb_mem_rdata, mem_wb_io_rdata;
    logic [4:0] mem_wb_wb_reg;
    logic  mem_wb_wb_enable, mem_wb_wb_sel;
    
    //MEM -> IO -> MEM Interface 
    logic [31:2] io_addr;
    logic [31:0] io_rdata, io_wdata;
    logic [3:0] io_be;
    logic io_we;
    
     rv32_mem_top mem_inst(
    // system clock and synchronous reset
    .clk(clk),
    .reset(reset),
    //from EX
    .pc_in(ex_mem_pc), //input [31:0]
    .wb_reg_in(ex_mem_wb_reg),//input [4:0]
    .wb_enable_in(ex_mem_wb_enable),//input 
    .iw_in(ex_mem_iw), //input [31:0] 
    .alu_in(ex_mem_alu), //input [31:0] 
    .write_enable(ex_mem_write_enable), //input
    .wb_sel_in(ex_mem_wb_sel),
    .rs2_data_in(ex_mem_rs2_data), //input [31:0]
    //to WB
    .pc_out(mem_wb_pc), //ouput reg [31:0] 
    .iw_out(mem_wb_iw),//ouput reg [31:0] 
    .alu_out(mem_wb_alu),//ouput reg [31:0] 
    .wb_reg_out(mem_wb_wb_reg),//ouput reg [4:0] 
    .wb_enable_out(mem_wb_wb_enable), //ouput reg 
    .wb_sel_out(mem_wb_wb_sel), //output reg
    //DF 
    .df_mem_enable(df_mem_enable), // output
    .df_mem_reg(df_mem_reg), //output [4:0]
    .df_mem_data(df_mem_data), //output [31:0]
    // memory interface
    .memif_addr(d_addr), // output [31:2] 
    .memif_rdata(d_rdata), //input [31:0]
    .memif_rdata_out(mem_wb_mem_rdata), //output [31:0] TO WB 
    .memif_we(d_we), // output 
    .memif_be(d_be), // output [3:0]
    .memif_wdata(d_wdata), //output [31:0] 
    // io interface
    .io_addr(io_addr), //output [31:2] 
    .io_rdata(io_rdata), //input [31:0]
    .io_rdata_out(mem_wb_io_rdata), //output [31:0] TO WB 
    .io_we(io_we), //output 
    .io_be(io_be), //output [3:0]
    .io_wdata(io_wdata), //output [31:0] 
    .df_wb_from_mem_mem(df_wb_from_mem_mem) //output

    );
    
    io_module io_module_inst
    (
    .clk(clk),
    //Data port (RW)
    .io_addr(io_addr), //input [31:2] 
    .io_rdata(io_rdata),//output reg [31:0] 
    .io_we(io_we),   //input 
    .io_be(io_be),   //input [3:0] 
    .io_wdata(io_wdata), //input [31:0] 
    //I/O Inputs / Outputs 
    .SW(SW), // input [11:0] 
    .PB(PB), //input [3:0] 
    .LED(LED) //output [9:0] 
    );
    
    //WB -> REG Interface 
    logic wb_reg_wb_enable;
    logic [4:0] wb_reg_wb_reg;
    logic [31:0] wb_reg_wb_data;
    
    rv32_wb_top wb_inst(
    .clk(clk),
    .reset(reset),
    //from mem
    .pc_in(mem_wb_pc), //input [31:0]
    .iw_in(mem_wb_iw),//input [31:0]
    .alu_in(mem_wb_alu),//input [31:0]
    .wb_reg_in(mem_wb_wb_reg),//input [4:0]
    .wb_enable_in(mem_wb_wb_enable),//input 
    .wb_sel_in(mem_wb_wb_sel), //input
    .io_rdata_in(mem_wb_io_rdata), //input [31:0] 
    .mem_rdata_in(mem_wb_mem_rdata), //input [31:0] 
    //TO register interface
    .regif_wb_enable(wb_reg_wb_enable),//output 
    .regif_wb_reg(wb_reg_wb_reg), //output [4:0] 
    .regif_wb_data(wb_reg_wb_data), //output [31:0] 
    //DF + Hazard Detection
    .df_wb_enable(df_wb_enable), //output
    .df_wb_reg(df_wb_reg), //output [4:0]
    .df_wb_data(df_wb_data),// output [31:0]
    //DF to MEM Stage 
    .df_wb_from_mem_wb(df_wb_from_mem_wb) //output 
    );
    
    
    rv32i_regs regs_inst(
    .clk(clk),// system clock
    .reset(reset), // and synchronous reset
    .rs1_reg(rs1_reg), //input [4:0] 
    .rs2_reg(rs2_reg), //input [4:0] 
    .wb_enable(wb_reg_wb_enable), //input 
    .wb_reg(wb_reg_wb_reg), //input [4:0] 
    .wb_data(wb_reg_wb_data), //input [31:0] 
    .rs1_data(rs1_data), //output [31:0] 
    .rs2_data(rs2_data) //    output [31:0]
     );
     
     
//     ila_0 your_instance_name (
//	.clk(clk), // input wire clk

//	.probe0(if_id_iw), // input wire [31:0]  probe0  
//	.probe1(id_ex_iw), // input wire [31:0]  probe1 
//	.probe2(ex_mem_iw), // input wire [31:0]  probe2 
//	.probe3(id_ex_rs1_data), // input wire [31:0]  probe3 
//	.probe4(id_ex_rs2_data), // input wire [10:0]  probe4 
//	.probe5(stall), // input wire [0:0]  probe5 
//	.probe6(reset), // input wire [4:0]  probe6 
//	.probe7(ex_mem_alu) // input wire [31:0]  probe7
//);
     
endmodule
