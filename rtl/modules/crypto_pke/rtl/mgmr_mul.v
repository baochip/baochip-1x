// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// This documentation and source code is licensed under the CERN Open Hardware
// License Version 2 – Weakly Reciprocal (http://ohwr.org/cernohl; the
// “License”). Your use of any source code herein is governed by the License.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

module mgmr_mul(
input  wire                         clk,
input  wire                         resetn,
input  wire                         mgmr_mul_start,
input  wire     [63:0]              param_J0,
input  wire     [7:0]               N_word_num,
input  wire     [63:0]              ram_mul_dat0,
input  wire     [63:0]              ram_mul_dat1,
output wire                         mgmr_mul_end,
output wire                         mgmr_mul_ram0_rdA,
output wire                         mgmr_mul_ram1_rdB,
output wire                         mgmr_mul_ram0_rdN,
output wire                         mgmr_mul_ram1_rdM,
output wire                         mgmr_mul_ram0_wr,
output wire                         mgmr_mul_ram1_wr,
output reg      [7:0]               mgmr_mul_ram0_addr,
output reg      [7:0]               mgmr_mul_ram1_addr,
output wire     [63:0]              mgmr_mul_ram0_dat,
output wire     [63:0]              mgmr_mul_ram1_dat,
output wire                         mgmr_mul_comalg_start,
input  wire                         comalg_end,
output wire     [5:0]               mgmr_mul_comalg_mode,
output wire     [7:0]               mgmr_mul_comalg_src0_addr,
output wire     [7:0]               mgmr_mul_comalg_src1_addr,
output wire     [7:0]               mgmr_mul_comalg_dst_addr
);

parameter UINT_AB_ADD_A      = 6'b000000;
parameter UINT_AB_ADD_B      = 6'b011000;
parameter UINT_AB_SUB_A      = 6'b000001;
parameter UINT_BA_SUB_B      = 6'b011001;
parameter UINT_BA_SUB_A      = 6'b001001;
parameter UINT_A_LFT_A       = 6'b000010;
parameter UINT_B_LFT_B       = 6'b011010;
parameter UINT_A_RHT_A       = 6'b000011;
parameter UINT_B_RHT_B       = 6'b011011;
parameter INT_A_RHT_A        = 6'b100011;
parameter INT_B_RHT_B        = 6'b111011;
parameter UINT_A_MOV_A       = 6'b000100;
parameter UINT_A_MOV_B       = 6'b010100;
parameter UINT_B_MOV_A       = 6'b001100;
parameter UINT_CMP           = 6'b000101;
parameter UINT_A_SET0        = 6'b000110; 
parameter UINT_B_SET0        = 6'b011110; 
parameter UINT_A_SET1        = 6'b000111;
parameter UINT_B_SET1        = 6'b011111;

parameter MGMR_RAM0_A_ADDR  = 0;
parameter MGMRL_RAM0_N_ADDR = 0;
parameter MGMRL_RAM1_B_ADDR = 0;
parameter MGMRL_RAM1_M_ADDR = 0;

parameter MGMR_STATE0   = 3'h0;
parameter MGMR_STATE1   = 3'h1;
parameter MGMR_STATE2   = 3'h2;
parameter MGMR_STATE3   = 3'h3;
parameter MGMR_STATE4   = 3'h4;

parameter LOOPA_STATE0    = 4'h0;
parameter LOOPA_STATE1    = 4'h1;
parameter LOOPA_STATE2    = 4'h2;
parameter LOOPA_STATE3    = 4'h3;
parameter LOOPA_STATE4    = 4'h4;
parameter LOOPA_STATE5    = 4'h5;
parameter LOOPA_STATE6    = 4'h6;
parameter LOOPA_STATE7    = 4'h7;
parameter LOOPA_STATE8    = 4'h8;

parameter LOOPB_STATE0    = 3'h0;
parameter LOOPB_STATE1    = 3'h1;
parameter LOOPB_STATE2    = 3'h2;
parameter LOOPB_STATE3    = 3'h3;
parameter LOOPB_STATE4    = 3'h4;
parameter LOOPB_STATE5    = 3'h5;
parameter LOOPB_STATE6    = 3'h6;

reg     [2:0]           mgmr_mul_state;
reg     [2:0]           next_mgmr_mul_state;
reg     [3:0]           loopA_state;
reg     [3:0]           next_loopA_state;
reg     [2:0]           loopB_state;
reg     [2:0]           next_loopB_state;
wire                    loopA_start;
reg     [7:0]           loop_cnt_j;
reg     [7:0]           loop_cnt_i;
reg     [2:0]           loopA_state_dly1;
reg     [2:0]           loopA_state_dly2;
reg     [2:0]           loopB_state_dly1;
reg     [2:0]           loopB_state_dly2;
wire                    is_loopA_rd_AiB0;
wire                    is_loopA_rd_AjBij;
wire                    is_loopA_rd_MjNij;
wire                    is_loopA_ld_MjNij;
wire                    is_loopA_mul_T0Pa;
wire                    is_loopA_mul_MiN0;
wire                    is_loopA_wr_Mi;
wire                    is_loopA_end;
wire                    is_loopA_rd_AiB01;
wire                    is_loopA_rd_AjBij1;
wire                    is_loopA_rd_MjNij1;
wire                    is_loopA_rd_AiB02;
wire                    is_loopA_rd_AjBij2;
wire                    is_loopA_rd_MjNij2;
wire                    is_LoopB_idle;
wire                    is_loopB_rd_AjBij;
wire                    is_loopB_rd_MjNij;
wire                    is_loopB_rd_Nis;
wire                    is_loopB_ld_Nis;
wire                    is_loopB_cmp_MN;
wire                    is_loopB_end;
wire                    is_loopB_rd_AjBij1;
wire                    is_loopB_rd_MjNij1;
wire                    is_loopB_rd_AjBij2;
wire                    is_loopB_rd_MjNij2;
wire                    is_cntij_equal;
reg     [63:0]          temp_X;
reg     [63:0]          temp_Y;
reg     [191:0]         temp_T;
reg                     carry_bit;
wire    [127:0]         mul_XY;
wire    [191:0]         T_Add_XY;
wire    [64:0]          MN_sub_result;
wire                    is_M_bigeer_N;

/*---------------------------------------------------------
* state machine
*----------------------------------------------------------*/
assign mgmr_mul_end = (mgmr_mul_state == MGMR_STATE4);

always @(posedge clk or negedge resetn) begin
    if(!resetn) 
        mgmr_mul_state <= MGMR_STATE0;
    else 
		mgmr_mul_state <= next_mgmr_mul_state; 
end

always @(*) begin
    case (mgmr_mul_state)
        MGMR_STATE0:begin
            if(mgmr_mul_start)
                next_mgmr_mul_state = MGMR_STATE1;
            else 
                next_mgmr_mul_state = mgmr_mul_state;
        end 
        MGMR_STATE1:begin
            if(is_loopA_end)
                next_mgmr_mul_state = MGMR_STATE2;
            else 
                next_mgmr_mul_state = mgmr_mul_state;
        end 
        MGMR_STATE2:begin
            if(is_loopB_end)
                next_mgmr_mul_state = MGMR_STATE3;
            else 
                next_mgmr_mul_state = mgmr_mul_state;
        end 
        MGMR_STATE3:begin
            if(comalg_end)
                next_mgmr_mul_state = MGMR_STATE4;
            else 
                next_mgmr_mul_state = mgmr_mul_state;
        end 
        MGMR_STATE4:
           	next_mgmr_mul_state = MGMR_STATE0;                                
        default:
            next_mgmr_mul_state = MGMR_STATE0;
    endcase
end


assign loopA_start = mgmr_mul_start;

always @(posedge clk or negedge resetn ) begin
    if (!resetn) 
        loopA_state <= LOOPA_STATE0;
     else 
       loopA_state <= next_loopA_state; 
end

always @(*) begin
    case (loopA_state)
        LOOPA_STATE0:begin
            if(loopA_start)
               next_loopA_state = LOOPA_STATE1; 
            else 
                next_loopA_state = loopA_state;
        end
        LOOPA_STATE1:begin
            if(is_cntij_equal)
               next_loopA_state = LOOPA_STATE4; 
            else 
               next_loopA_state = LOOPA_STATE2; 
        end
        LOOPA_STATE2:begin
           next_loopA_state = LOOPA_STATE3; 
        end
        LOOPA_STATE3:begin
            if(loop_cnt_i != (loop_cnt_j+1))
                next_loopA_state = LOOPA_STATE2;
            else 
                next_loopA_state = LOOPA_STATE4;
        end
        LOOPA_STATE4:begin
           next_loopA_state = LOOPA_STATE5; 
        end
        LOOPA_STATE5:begin
           next_loopA_state = LOOPA_STATE6; 
        end
        LOOPA_STATE6:begin
            next_loopA_state = LOOPA_STATE7;
        end
        LOOPA_STATE7:begin
            if(loop_cnt_i == (N_word_num-1))
                next_loopA_state = LOOPA_STATE8;
            else 
                next_loopA_state = LOOPA_STATE1;
        end 
        LOOPA_STATE8:begin
            next_loopA_state = LOOPA_STATE0;
        end
        default: begin
            next_loopA_state = LOOPA_STATE0;
        end
    endcase
end

assign is_loopA_rd_AiB0  = (loopA_state == LOOPA_STATE1);
assign is_loopA_rd_AjBij = (loopA_state == LOOPA_STATE2);
assign is_loopA_rd_MjNij = (loopA_state == LOOPA_STATE3);
assign is_loopA_ld_MjNij = (loopA_state == LOOPA_STATE4);
assign is_loopA_mul_T0Pa = (loopA_state == LOOPA_STATE5);
assign is_loopA_mul_MiN0 = (loopA_state == LOOPA_STATE6);
assign is_loopA_wr_Mi    = (loopA_state == LOOPA_STATE7);
assign is_loopA_end      = (loopA_state == LOOPA_STATE8);

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        loopA_state_dly1 <= LOOPA_STATE0;
        loopA_state_dly2 <= LOOPA_STATE0;
    end else begin
        loopA_state_dly1 <= loopA_state;
        loopA_state_dly2 <= loopA_state_dly1;
    end
end

assign is_loopA_rd_AiB01  = loopA_state_dly1 == LOOPA_STATE1;
assign is_loopA_rd_AjBij1 = loopA_state_dly1 == LOOPA_STATE2;
assign is_loopA_rd_MjNij1 = loopA_state_dly1 == LOOPA_STATE3;
assign is_loopA_rd_AiB02  = loopA_state_dly2 == LOOPA_STATE1;
assign is_loopA_rd_AjBij2 = loopA_state_dly2 == LOOPA_STATE2;
assign is_loopA_rd_MjNij2 = loopA_state_dly2 == LOOPA_STATE3;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        loopB_state <= LOOPB_STATE0;
    end else begin
        loopB_state <= next_loopB_state;
    end
end

always @(*) begin
    case (loopB_state)
        LOOPB_STATE0:begin
            if(is_loopA_end)begin
                next_loopB_state = LOOPB_STATE1;
            end
            else begin
                next_loopB_state = loopB_state;
            end
        end
        LOOPB_STATE1:begin
            next_loopB_state = LOOPB_STATE2;
        end 
        LOOPB_STATE2:begin
            if(loop_cnt_j != N_word_num-1)begin
                next_loopB_state = LOOPB_STATE1;
            end
            else begin
                next_loopB_state = LOOPB_STATE3;    
            end
        end
        LOOPB_STATE3:begin
            next_loopB_state = LOOPB_STATE4;
        end
        LOOPB_STATE4:begin
            next_loopB_state = LOOPB_STATE5;
        end
        LOOPB_STATE5:begin
            if(loop_cnt_i == ({N_word_num,1'b0}-2))begin
                next_loopB_state = LOOPB_STATE3;
            end
            else if(loop_cnt_i == ({N_word_num,1'b0}-1))begin
                next_loopB_state = LOOPB_STATE6;
            end
			else begin
				next_loopB_state = LOOPB_STATE1;
			end
        end
        LOOPB_STATE6:begin
            next_loopB_state = LOOPB_STATE0;
        end
        default: begin
            next_loopB_state = LOOPB_STATE0;
        end
    endcase
end

assign is_LoopB_idle        = (loopB_state == LOOPB_STATE0);
assign is_loopB_rd_AjBij    = (loopB_state == LOOPB_STATE1);
assign is_loopB_rd_MjNij    = (loopB_state == LOOPB_STATE2);
assign is_loopB_rd_Nis      = (loopB_state == LOOPB_STATE3);
assign is_loopB_ld_Nis      = (loopB_state == LOOPB_STATE4);
assign is_loopB_cmp_MN      = (loopB_state == LOOPB_STATE5);
assign is_loopB_end         = (loopB_state == LOOPB_STATE6);

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        loopB_state_dly1 <= LOOPB_STATE0;
        loopB_state_dly2 <= LOOPB_STATE0;
    end else begin
        loopB_state_dly1 <= loopB_state;
        loopB_state_dly2 <= loopB_state_dly1;
    end
end

assign is_loopB_rd_AjBij1 = loopB_state_dly1 == LOOPB_STATE1;
assign is_loopB_rd_MjNij1 = loopB_state_dly1 == LOOPB_STATE2;
assign is_loopB_rd_AjBij2 = loopB_state_dly2 == LOOPB_STATE1;
assign is_loopB_rd_MjNij2 = loopB_state_dly2 == LOOPB_STATE2;
assign  is_cntij_equal = (loop_cnt_i == loop_cnt_j);
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        loop_cnt_i <= 8'h0;
    end else begin
        if(mgmr_mul_start)begin
            loop_cnt_i <= 8'h0;
        end
        else if (is_loopA_wr_Mi || is_loopB_cmp_MN) begin
            loop_cnt_i <= loop_cnt_i + 8'h1;
        end
        else begin
            loop_cnt_i <= loop_cnt_i;
        end
    end
end

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        loop_cnt_j <= 8'h0;
    end else begin
        if(mgmr_mul_start || is_loopA_wr_Mi)begin
            loop_cnt_j <= 8'h0;
        end 
        else if(is_loopA_rd_MjNij || is_loopB_rd_MjNij) begin
            loop_cnt_j <= loop_cnt_j + 8'h1;
        end
        else if(is_loopA_end)begin
            loop_cnt_j <= 8'h1;
        end
        else if (is_loopB_cmp_MN)begin
            loop_cnt_j <= loop_cnt_i - N_word_num +2;
        end
        else begin
            loop_cnt_j <= loop_cnt_j;
        end
    end
end

always @(posedge clk or negedge resetn) begin
    if(!resetn)begin
        temp_X <= 64'h0;
    end else begin
        if(is_loopA_rd_AiB01 || is_loopA_rd_AjBij1 || 
           is_loopA_rd_MjNij1 || is_loopB_rd_AjBij1|| 
           is_loopB_rd_MjNij1 || is_loopA_mul_MiN0 || is_loopB_ld_Nis)begin
            temp_X <= ram_mul_dat0;
        end
        else if(is_loopA_mul_T0Pa)begin
            temp_X <= T_Add_XY[63:0];
        end
        else begin
            temp_X <= temp_X;
        end
    end
end

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        temp_Y <= 64'h0;
    end else begin
        if(is_loopA_rd_AiB01 || is_loopA_rd_AjBij1 || is_loopA_rd_MjNij1 ||
           is_loopB_rd_AjBij1 || is_loopB_rd_MjNij1 )begin
            temp_Y <= ram_mul_dat1;
        end 
        else if (is_loopA_mul_T0Pa) begin
            temp_Y <= param_J0;
        end
		else if(is_loopA_mul_MiN0)begin
            temp_Y <= mul_XY[63:0];
        end
        else begin
            temp_Y <= temp_Y;
        end 
    end
end

always @(posedge clk or negedge resetn) begin
    if(!resetn)begin
        temp_T <= 192'h0;
    end
    else begin
		if(mgmr_mul_start)begin
			temp_T <= 192'h0;
        end else if (is_loopA_rd_AiB02 || is_loopA_rd_AjBij2 || 
                     is_loopA_rd_MjNij2||is_loopB_rd_AjBij2 || 
                     is_loopB_rd_MjNij2) begin
            temp_T <= T_Add_XY;
        end else if (is_loopA_wr_Mi) begin
            temp_T <= {64'h0,T_Add_XY[191:64]};
        end else if (is_loopB_cmp_MN)begin
            temp_T <= {64'h0,temp_T[191:64]};
        end else begin
            temp_T <= temp_T;
        end
    end
end
assign mul_XY = temp_X * temp_Y;
assign T_Add_XY = {64'h0,mul_XY[127:0]} + temp_T[191:0]; 

always @(posedge clk or negedge resetn) begin
    if(!resetn)begin
        carry_bit <= 0;
    end
    else begin
        if(mgmr_mul_start)begin
            carry_bit <= 0;
        end
        else if(is_loopB_cmp_MN)begin
            carry_bit <= MN_sub_result[64];
        end
        else begin
            carry_bit <= carry_bit;
        end
    end
end
assign MN_sub_result = ({1'b0,temp_T[63:0]} - carry_bit) - {1'b0,temp_X};
assign is_M_bigeer_N = ((temp_T[63:0] !=0) || (!carry_bit));
assign mgmr_mul_comalg_start = is_loopB_end;
assign mgmr_mul_comalg_mode = is_M_bigeer_N ? UINT_BA_SUB_A : UINT_B_MOV_A;
assign mgmr_mul_comalg_src0_addr = MGMRL_RAM0_N_ADDR;
assign mgmr_mul_comalg_src1_addr = MGMRL_RAM1_M_ADDR;
assign mgmr_mul_comalg_dst_addr = MGMR_RAM0_A_ADDR;

assign mgmr_mul_ram0_rdA = (is_loopA_rd_AiB0 || is_loopA_rd_AjBij ||
                            is_loopB_rd_AjBij );

assign mgmr_mul_ram1_rdB = (is_loopA_rd_AiB0 || is_loopA_rd_AjBij ||
                            is_loopB_rd_AjBij);
                            
assign mgmr_mul_ram1_rdM = (is_loopA_rd_MjNij || is_loopB_rd_MjNij ); 

assign mgmr_mul_ram0_rdN = (is_loopA_rd_MjNij || is_loopA_mul_T0Pa || 
                            is_loopB_rd_MjNij ||is_loopB_rd_Nis);

assign mgmr_mul_ram0_wr = 0;

assign mgmr_mul_ram1_wr = (is_loopA_wr_Mi || is_loopB_cmp_MN);

assign mgmr_mul_ram0_dat = 64'h0;

assign mgmr_mul_ram1_dat = (mgmr_mul_state == MGMR_STATE1) ? temp_Y:
                                                                 temp_T[63:0];

always @(*) begin
    if(is_loopA_rd_AiB0)begin
        mgmr_mul_ram0_addr = MGMR_RAM0_A_ADDR + loop_cnt_i;
    end
    else if(is_loopA_rd_AjBij || is_loopB_rd_AjBij)begin
        mgmr_mul_ram0_addr = MGMR_RAM0_A_ADDR + loop_cnt_j;
    end else if(is_loopA_rd_MjNij || is_loopB_rd_MjNij)begin
        mgmr_mul_ram0_addr = MGMRL_RAM0_N_ADDR + loop_cnt_i -loop_cnt_j;
    end else if(is_loopB_rd_Nis)begin 
        mgmr_mul_ram0_addr = MGMRL_RAM0_N_ADDR + loop_cnt_i - N_word_num;  
    end else begin 
        mgmr_mul_ram0_addr = MGMRL_RAM0_N_ADDR;
    end
	
end    

always @(*) begin
    if (is_loopA_rd_AiB0) begin
        mgmr_mul_ram1_addr = MGMRL_RAM1_B_ADDR;
    end else if(is_loopA_rd_AjBij || is_loopB_rd_AjBij) begin
        mgmr_mul_ram1_addr = MGMRL_RAM1_B_ADDR + loop_cnt_i - loop_cnt_j;
    end else if(is_loopA_rd_MjNij || is_loopB_rd_MjNij)begin
        mgmr_mul_ram1_addr = MGMRL_RAM1_M_ADDR + loop_cnt_j;
	end else if(is_loopA_wr_Mi) begin 
        mgmr_mul_ram1_addr = MGMRL_RAM1_M_ADDR + loop_cnt_i;
	end else begin
		mgmr_mul_ram1_addr = MGMRL_RAM1_M_ADDR + loop_cnt_i  - loop_cnt_j;
	end
end

endmodule

