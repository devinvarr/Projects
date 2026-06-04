module rv32_id_top(
input clk,
input reset,
// from if
input [31:0] pc_in,
input [31:0] iw_in,
//to IF
output jump_enable_out,
output [31:0] jump_addr_out,
// register interface
output [4:0] regif_rs1_reg,
output [4:0] regif_rs2_reg,
input [31:0] regif_rs1_data,
input [31:0] regif_rs2_data,
// to ex
output reg [31:0] pc_out,
output reg [31:0] iw_out,
output reg [4:0] wb_reg_out,
output reg wb_enable_out,
output reg [31:0] rs1_data_out,
output reg [31:0] rs2_data_out,
output reg write_enable_out,
output reg wb_sel,
output reg [4:0] rs1_reg_out,
output reg [4:0] rs2_reg_out,
//to IF
output ebreak,
// data hazard: df from ex
input df_ex_enable,
input [4:0] df_ex_reg,
input [31:0] df_ex_data,
// data hazard: df from mem
input df_mem_enable,
input [4:0] df_mem_reg,
input [31:0] df_mem_data,
// data hazard: df from wb
input df_wb_enable,
input [4:0] df_wb_reg,
input [31:0] df_wb_data,
// register df from ex
input df_wb_from_mem_ex,
// register df from mem
input df_wb_from_mem_mem,
//notify IF of stall 
output stall_out
);

logic [31:0] regif_rs1_data_df, regif_rs2_data_df;
logic [4:0] rs1, rs2,rd;
logic [6:0] op,op_branch;
logic check_ebreak,flush;

//decode iw to extract rs1/rs2 reg 
assign rs2 = iw_in [24:20];
assign rs1 = iw_in [19:15];
assign rd  = iw_in [11:7];
assign op  = iw_in [6:0];
assign check_ebreak = (iw_in == 32'h00100073);
assign ebreak = check_ebreak;


assign regif_rs1_reg = rs1;
assign regif_rs2_reg = rs2;
//Handling data forwarding for rs1_data_out 
always_comb
begin
if((rs1 == df_ex_reg) && df_ex_enable)
    regif_rs1_data_df = df_ex_data;
else if ((rs1 == df_mem_reg) && df_mem_enable)
    regif_rs1_data_df = df_mem_data;
else if ((rs1 == df_wb_reg) && df_wb_enable)
    regif_rs1_data_df = df_wb_data;
else
    regif_rs1_data_df = regif_rs1_data;//send usual data 
end

//handling data forwarding for rs2_data_out 
always_comb 
begin
if((rs2 == df_ex_reg) && df_ex_enable)
    regif_rs2_data_df = df_ex_data;
else if ((rs2 == df_mem_reg) && df_mem_enable)
    regif_rs2_data_df = df_mem_data;
else if ((rs2 == df_wb_reg) && df_wb_enable)
    regif_rs2_data_df = df_wb_data;
else
    regif_rs2_data_df = regif_rs2_data;//send usual data 
end

//register rs1/rs2 data values for use in EX stage
always_ff @(posedge clk)
if(reset)
begin
  rs1_data_out <= 0;
  rs2_data_out <= 0;
end
else
begin 
rs1_data_out <= regif_rs1_data_df;
rs2_data_out <= regif_rs2_data_df;
flush <= check_ebreak;
end     

//generate WB signal based on opcode 

logic is_rtype, is_jalr, is_load, is_itype, is_lui, is_auipc, is_jal, is_store, is_branch;
assign is_rtype = (op == 7'b0110011);
assign is_jalr  = (op == 7'b1100111);
assign is_load  = (op == 7'b0000011);
assign is_itype = (op == 7'b0010011);
assign is_lui   = (op == 7'b0110111);
assign is_auipc = (op == 7'b0010111);
assign is_jal   = (op == 7'b1101111);
assign is_store = (op == 7'b0100011);
assign is_branch =(op == 7'b1100011);

//logic wb;
//assign wb = (is_rtype || is_jalr || is_load || is_itype || is_lui || is_auipc || is_jal);

//Generate WE/wb_sel signal based on opcode 
logic we_hold;
assign we_hold = (op == 7'b0100011); //Check for store, if so enable we

logic wb_sel_hold;
assign wb_sel_hold = is_load;

//generate jump_enable based on OP (check for JAL, JALR, BRANCH)
logic jump_enable_out_hold;

//Add signed version of df values for signed Branch commands
logic signed [31:0] rs1_df_signed, rs2_df_signed;
logic [31:0] branch_rs1_data, branch_rs2_data;

assign branch_rs1_data = regif_rs1_data_df;
assign branch_rs2_data = regif_rs2_data_df;
assign rs1_df_signed = branch_rs1_data;
assign rs2_df_signed = branch_rs2_data;

logic [2:0] funct3;

assign funct3 = chosen_iw [14:12];
assign op_branch = chosen_iw [6:0];


always_comb 
begin 
case (op_branch)
7'b1101111: jump_enable_out_hold = 1; //JAL instruction
7'b1100111: jump_enable_out_hold = 1; //JALR instruction 
7'b1100011: begin                     //Branch Instructions
            case (funct3)
                //BEQ
                3'b000: jump_enable_out_hold = (rs1_df_signed == rs2_df_signed);//? 1 : 0;
                //BNE
                3'b001: jump_enable_out_hold = (rs1_df_signed != rs2_df_signed);//? 1 : 0;
                //BLT
                3'b100: jump_enable_out_hold = (rs1_df_signed < rs2_df_signed);//? 1:0;
                //BGE
                3'b101: jump_enable_out_hold = (rs1_df_signed >= rs2_df_signed);//? 1:0;
                //BLTU - UNSIGNED!!
                3'b110: jump_enable_out_hold = (branch_rs1_data < branch_rs2_data);//? 1:0;
                //BGEU - UNSIGNED!!
                3'b111: jump_enable_out_hold = (branch_rs1_data >= branch_rs2_data);//? 1:0;
                default: jump_enable_out_hold = 0;
            endcase
            end    
default: jump_enable_out_hold = 0;
endcase
end
//assign unlatched for use in IF
assign jump_enable_out = jump_enable_out_hold;

//assigned REGISTERED for use in ID (NOP/IW_OUT MUX)
logic jump_enable_reg;
always_ff @(posedge clk)
begin
if(reset)
    jump_enable_reg <= 0;
else
    jump_enable_reg <= jump_enable_out_hold;
end

logic [31:0] mux_iw; //Logic for mux output(iw/nop)
//NOP / IW Mux (feeds above block + iw_out)
assign mux_iw = (jump_enable_reg || stall) ? 32'h00000013 : iw_in;


//Generate jump_addr_out signals.
logic [31:0] jump_addr_out_hold;
logic [31:0] add_branch, add_jal, add_jalr;
logic [12:1] branch_imm;
logic [20:1] jal_imm;
logic [11:0] jalr_imm;

logic [31:0] chosen_iw, chosen_pc;

assign chosen_pc = (!stall && prev_cycle) ? store_pc : pc_in;
assign chosen_iw = (!stall && prev_cycle) ? store_iw : mux_iw;

//decode the immediate fields
assign branch_imm = {chosen_iw[31], chosen_iw[7], chosen_iw[30:25], chosen_iw [11:8]};
assign jal_imm    = {chosen_iw[31], chosen_iw [19:12], chosen_iw [20], chosen_iw [30:21]};
assign jalr_imm   = chosen_iw[31:20];

//put together with sign extension + 2* if applicable (add zero at end)
assign add_branch = {{19{chosen_iw[31]}},branch_imm, 1'b0};
assign add_jal    = {{11{chosen_iw[31]}},jal_imm,    1'b0};
assign add_jalr   = {{20{chosen_iw[31]}},jalr_imm};


always_comb
begin
case(op_branch)
7'b1101111: jump_addr_out_hold = chosen_pc + add_jal;                //JAL instruction
7'b1100111: jump_addr_out_hold = regif_rs1_data_df + add_jalr;   //JALR instruction 
7'b1100011: jump_addr_out_hold = chosen_pc + add_branch; //Branch Instructions
default: jump_addr_out_hold = 0;
endcase
end

assign jump_addr_out = jump_addr_out_hold;

//Stall generation for arithmetic after LD (Step 6 - L9)
logic rs1_ops, rs2_ops;
logic rs1_hazard, rs2_hazard;
logic reg_stall_needed;

//breakdown operations with rs1 / rs2
assign rs1_ops = (is_rtype || is_jalr || is_load || is_itype || is_store || is_branch);
assign rs2_ops = (is_rtype || is_store || is_branch );

//check if load pending, and it uses the same register as register about to be read from
assign rs1_hazard = (df_wb_from_mem_ex && rs1_ops && (rs1 == df_ex_reg));
assign rs2_hazard = (df_wb_from_mem_ex && rs2_ops && (rs2 == df_ex_reg));
assign reg_stall_needed = rs1_hazard || rs2_hazard;

//Stall generation for branch after LD (Step 7 - L9)
logic rs1_hazard_branch, rs2_hazard_branch;
logic branch_stall_needed;

//check if pending load, and if branch is using same registers 
assign rs1_hazard_branch = (df_wb_from_mem_mem && is_branch && (rs1 == df_mem_reg));
assign rs2_hazard_branch = (df_wb_from_mem_mem && is_branch && (rs2 == df_mem_reg));
assign branch_stall_needed = rs1_hazard_branch || rs2_hazard_branch;

logic stall;
assign stall = reg_stall_needed || branch_stall_needed;
assign stall_out = stall;

//Temporarily store PC/IW 
logic [31:0] store_pc, store_iw;

logic prev_cycle;

//keep tracker of stalls
always_ff@(posedge clk)
begin
if(reset)
    prev_cycle <= 0;
else
    prev_cycle <= stall;
end 

always_ff@ (posedge clk)
begin
if(reset)
begin
    store_pc <= 0;
    store_iw <= 0;
end
else if(!prev_cycle && stall) //On the first cycle of stall (prev not stall, now in stall)
begin
    store_pc <= pc_in;  //store the pc
    store_iw <= iw_in;  //store the iw
end
end

logic [4:0] rd_stored;
assign rd_stored  = chosen_iw [11:7];

logic [6:0] op_stored;
assign op_stored = chosen_iw [6:0];

logic wb_stored;
logic is_rtype_store, is_jalr_store, is_load_store, is_itype_store, is_lui_store, is_auipc_store, is_jal_store, is_store_store, is_branch_store;
assign is_rtype_store = (op_stored == 7'b0110011);
assign is_jalr_store  = (op_stored == 7'b1100111);
assign is_load_store  = (op_stored == 7'b0000011);
assign is_itype_store = (op_stored == 7'b0010011);
assign is_lui_store   = (op_stored == 7'b0110111);
assign is_auipc_store = (op_stored == 7'b0010111);
assign is_jal_store   = (op_stored == 7'b1101111);
assign is_store_store = (op_stored == 7'b0100011);
assign is_branch_store =(op_stored == 7'b1100011);

assign wb_stored = (is_rtype_store || is_jalr_store || is_load_store || is_itype_store || is_lui_store || is_auipc_store || is_jal_store);

//Generate WE/wb_sel signal based on opcode 
logic we_stored;
assign we_stored = (op_stored == 7'b0100011); //Check for store, if so enable we

logic wb_sel_stored;
assign wb_sel_stored = is_load_store;



//Signals -> EX 
always_ff @(posedge clk)
begin 
if(reset || flush)
begin
    iw_out <= 32'h00000013;
    pc_out <= 0;
    wb_enable_out <= 0;
    wb_reg_out <= 0;
    write_enable_out <= 0;
    rs1_reg_out <= 0;
    rs2_reg_out <= 0;   
    wb_sel <= 0;
end
//else if(flush)
//begin
//    iw_out <= 32'h00000013;
//    wb_enable_out <= 0;
//    wb_reg_out <= 0;
//    write_enable_out <= 0;
//    rs1_reg_out <= 0;
//    rs2_reg_out <= 0;
//end
else //send either stored values, NOP, or iw_in (with appropriate decoded values)
begin
    iw_out <= chosen_iw;
    pc_out <= chosen_pc;
    wb_reg_out <= rd_stored;
    wb_enable_out <= wb_stored;
    write_enable_out <= we_stored;
    wb_sel <= wb_sel_stored;
    rs1_reg_out <= chosen_iw [19:15];
    rs2_reg_out <= chosen_iw [24:20];
end
//else 
//begin
//    pc_out <= pc_in;
//    iw_out <= mux_iw; //will either be IW_IN or a NOP based on if stall or jump is enabled
    
//    wb_reg_out <= rd; 
//    wb_enable_out <= wb;
//    write_enable_out <= we_hold;
//    wb_sel <= wb_sel_hold;
//    rs1_reg_out <= iw_in [19:15];
//    rs2_reg_out <= iw_in [24:20];
//end
end

endmodule 


/*Experimental changes to fix timing
1. Comment out the "wb" signal related signals. Lines 117-118
2. Comment out "else if (flush) block. Lines 321-329





*/