`timescale 1ns / 1ps

module alu(
// from id
input [31:0] pc_in,
input [31:0] iw_in,
input [31:0] rs1_data_in,
input [31:0] rs2_data_in,
 // to mem
output logic [31:0] alu_out
);

 logic [6:0] opcode; //,funct7
 logic [2:0] funct3;
 logic [4:0] rs1, rs2, rd, shamt;
 logic [31:0] imm12;
 logic [19:0] imm20;
 logic signed [31:0] Simm12;
 logic signed [31:0] Srs1_data_in,Srs2_data_in;
 logic [31:0] StoreImm,JalImm;
 
 assign opcode = iw_in [6:0];
 assign rd     = iw_in [11:7];
 assign funct3 = iw_in [14:12];

 assign rs1 =    iw_in [19:15];
 assign rs2 =    iw_in [24:20];
 assign shamt =  iw_in [24:20];
 //assign funct7 = iw_in [31:25];
 
 assign imm12  = {{20{iw_in[31]}},iw_in[31:20]};
 assign Simm12 = {{20{iw_in[31]}},iw_in[31:20]};
 
 assign imm20  = iw_in [31:12];
 
 assign Srs1_data_in = rs1_data_in;
 assign Srs2_data_in = rs2_data_in;
 assign StoreImm = {{20{iw_in[31]}},iw_in[31:25], iw_in[11:7]};
 assign JalImm = {{12{iw_in[31]}},iw_in[31], iw_in[19:12], iw_in[20], iw_in [30:21]};
 
 
 //Load condition precompute
 logic [31:0] rs1_imm12;
 assign rs1_imm12 = rs1_data_in + imm12;
 
 //Store condiiton precompute
 logic [31:0] rs1_store;
 assign rs1_store = rs1_data_in + StoreImm;
 logic [31:0] pc_4;
 assign pc_4 = pc_in + 32'd4;
 
   always_comb
  begin 
      case(opcode)
      //R Instructions (Orange)
      7'b0110011: begin
                 case(funct3)
                 //Add/Sub 
                 3'b000: begin if(!iw_in[30]) alu_out = rs1_data_in + rs2_data_in;
                               else           alu_out = rs1_data_in - rs2_data_in;
                               end 
                 //SLL
                 3'b001: alu_out = rs1_data_in << rs2_data_in [4:0];
                 //SLT
                 3'b010: begin 
                               if(Srs1_data_in < Srs2_data_in) alu_out = 1;
                               else alu_out = 0;
                         end
                 //SLTU
                 3'b011: begin 
                               if(rs1_data_in < rs2_data_in) alu_out = 1;
                               else alu_out = 0;
                         end
                 //XOR
                 3'b100: alu_out = rs1_data_in ^ rs2_data_in;
                 //SRL/SRA
                 3'b101: begin 
                               if(!iw_in[30]) alu_out = rs1_data_in >> rs2_data_in [4:0];
                               else           alu_out = Srs1_data_in >>> rs2_data_in [4:0];
                          end
                 //OR
                 3'b110: alu_out = rs1_data_in | rs2_data_in;
                 //AND
                 3'b111: alu_out = rs1_data_in & rs2_data_in;
                 default: alu_out = 0;
                endcase
                 end
      //I Instructions (Pink)
      7'b0000011: alu_out = rs1_imm12; //begin 
//                 case(funct3)
//                 //LB
//                 3'b000: alu_out = rs1_data_in + imm12;
//                 //LH
//                 3'b001: alu_out = rs1_data_in + imm12;
//                 //LW
//                 3'b010: alu_out = rs1_data_in + imm12;
//                 //LBU
//                 3'b100: alu_out = rs1_data_in + imm12;
//                 //LHU
//                 3'b101: alu_out = rs1_data_in + imm12;
//                 default: alu_out = 0;
//                 endcase
//                 end 
                 
      //I Instructions (Yellow)
      7'b0010011:begin
                 case(funct3)
                 //ADDI
                 3'b000: alu_out = rs1_imm12;
                 //SLTI
                 3'b010: begin 
                               if(Srs1_data_in < Simm12) alu_out = 1;
                               else alu_out = 0;
                         end 
                 //SLTIU
                 3'b011: begin 
                               if(rs1_data_in < imm12) alu_out = 1;
                               else alu_out = 0;
                         end
                 //XORI
                 3'b100: alu_out = rs1_data_in ^ imm12;
                 //ORI
                 3'b110: alu_out = rs1_data_in | imm12;
                 //ANDI
                 3'b111: alu_out = rs1_data_in & imm12;
                 //SLLI
                 3'b001: alu_out = rs1_data_in << shamt;
                 //SRLI/SRAI
                 3'b101: begin if(!iw_in[30]) alu_out = rs1_data_in >> shamt;
                               else           alu_out = Srs1_data_in >>> shamt;
                         end
                 default: alu_out = 0;
                 endcase
                 end
      //S Instructions (Purple)
      7'b0100011: alu_out = rs1_store;//begin 
//                 case(funct3)
//                 //SB
//                 3'b000: alu_out = rs1_data_in + StoreImm;
//                 //SH
//                 3'b001: alu_out = rs1_data_in + StoreImm;
//                 //SW
//                 3'b010: alu_out = rs1_data_in + StoreImm;
//                 default: alu_out = 0;
//                 endcase
//                 end 
                 
      //U Instrction (LUI - Light Blue)
      7'b0110111: alu_out = {imm20,12'b0};
      //U Instruction (AUIPC - Dark Green)
      7'b0010111: alu_out = {imm20,12'b0} + pc_in;
      //JALR Instruction (Dark Blue)
      7'b1100111: alu_out = pc_in + 4; //rs1 + Simm12;
      //JAL Instruction (Light Green)
      7'b1101111: alu_out = pc_in + 4;      //pc_in + (JalImm << 1)
      
      default: alu_out = 0;
      
  endcase
  end
  
endmodule
