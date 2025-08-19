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


module com_alg(
input  wire                     clk,
input  wire                     resetn,
input  wire 	[7:0]		comalg_wlen,
input  wire     [5:0]           comalg_mode,
input  wire                     comalg_start,
output wire                     comalg_end,
output reg      [2:0]           comalg_status,
input  wire     [63:0]          ram0_comalg_rdata,
output wire                     comalg_ram0_wr,
output wire                     comalg_ram0_rd,
output wire     [7:0]           comalg_ram0_addr,
output wire     [63:0]          comalg_ram0_wdata,
input  wire     [63:0]          ram1_comalg_rdata,
output wire                     comalg_ram1_wr,
output wire                     comalg_ram1_rd,
output wire     [7:0]           comalg_ram1_addr,
output wire     [63:0]          comalg_ram1_wdata
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

parameter OPRADD      = 3'b000;
parameter OPRSUB      = 3'b001;
parameter OPRLFT      = 3'b010;
parameter OPRRHT      = 3'b011;
parameter OPRMOV      = 3'b100;
parameter OPRCMP      = 3'b101;
parameter OPRSET0     = 3'b110; 
parameter OPRSET1     = 3'b111;

parameter CMALG_STATE0  = 3'b000;
parameter CMALG_STATE1  = 3'b001;
parameter CMALG_STATE3  = 3'b011;
parameter CMALG_STATE2  = 3'b010;
parameter CMALG_STATE6  = 3'b110;
parameter CMALG_STATE4  = 3'b100;
parameter CMALG_STATE5  = 3'b101;
parameter CMALG_STATE7 = 3'b111;

parameter COMALG_A_ADDR  = 8'h0;
parameter CMALG_B_ADDR  = 8'h0;

reg     [2:0]       comalg_state;
reg     [63:0]      ram_data_temp0;
reg     [63:0]      ram_data_temp1;
reg     [63:0]      alg_data;
reg                 carry_bit;
reg     [7:0]       read_counter_reg;
reg     [7:0]       read_counter;
reg     [7:0]       write_counter;

wire                is_mode_add;
wire                is_mode_sub;
wire                is_mode_left;
wire                is_mode_right;
wire                is_mode_mov;
wire                is_mode_comp;
wire                is_mode_set0;
wire                is_mode_set1;
wire                is_sign_opr;
wire                is_alg_state;
wire                alg_start;
reg     [2:0]       next_alg_state;
wire                is_read_state0;
wire                is_read_state1;
wire                is_read_state2;
wire                is_write_state0;
wire                is_write_state1;
wire                is_write_state2;
wire                is_state_end;
wire                is_data0_load_fromA;
wire                enable_data_load;
wire                enable_check_zero;
wire                load_carry_bit;
wire                load_odd_event_bit;
wire                read_counter_inc;
wire                write_counter_inc;
wire                is_read_begin_high;

assign is_mode_add      = (comalg_mode[2:0] == OPRADD);
assign is_mode_sub      = (comalg_mode[2:0] == OPRSUB);
assign is_mode_left     = (comalg_mode[2:0] == OPRLFT);
assign is_mode_right    = (comalg_mode[2:0] == OPRRHT);
assign is_mode_mov      = (comalg_mode[2:0] == OPRMOV);
assign is_mode_comp     = (comalg_mode[2:0] == OPRCMP);
assign is_mode_set0     = (comalg_mode[2:0] == OPRSET0);
assign is_mode_set1     = (comalg_mode[2:0] == OPRSET1);
assign is_sign_opr      = (comalg_mode[5]);
assign  alg_start = comalg_start;

always@(posedge clk or negedge resetn)
begin
    if(!resetn)
        comalg_state <= CMALG_STATE0;
    else 
        comalg_state <= next_alg_state;
end


always@(*)begin
    case (comalg_state)
        CMALG_STATE0:begin
            if (alg_start) 
                next_alg_state = CMALG_STATE1;
             else 
                next_alg_state = comalg_state;            
        end
        CMALG_STATE1:begin
            next_alg_state = CMALG_STATE3;
        end
        CMALG_STATE3:begin
            next_alg_state = CMALG_STATE2;
        end
        CMALG_STATE2:begin
            next_alg_state = CMALG_STATE6;
        end
        CMALG_STATE6:begin
			if(write_counter == comalg_wlen -1)
				next_alg_state = CMALG_STATE7;			
			else 
          		next_alg_state = CMALG_STATE4;			
        end
        CMALG_STATE4:begin
            if (write_counter == comalg_wlen -1) 
                next_alg_state = CMALG_STATE7;
             else 
                next_alg_state = CMALG_STATE5;         
        end
        CMALG_STATE5: begin
            if (write_counter == comalg_wlen -1) 
                next_alg_state = CMALG_STATE7;
             else 
            	next_alg_state = CMALG_STATE1;			
        end
        CMALG_STATE7:begin
			if(comalg_start)
				next_alg_state = CMALG_STATE1;			
			else 
            	next_alg_state = CMALG_STATE0;
        end
        default: begin
            next_alg_state = CMALG_STATE0;
        end
    endcase
end

assign is_read_state0  = comalg_state == CMALG_STATE1;
assign is_read_state1  = comalg_state == CMALG_STATE3;
assign is_read_state2  = comalg_state == CMALG_STATE2;
assign is_write_state0 = comalg_state == CMALG_STATE6;
assign is_write_state1 = comalg_state == CMALG_STATE4;
assign is_write_state2 = comalg_state == CMALG_STATE5;
assign is_state_end    = comalg_state == CMALG_STATE7;

assign comalg_end = is_state_end;


always@(posedge clk or negedge resetn)begin
    if(!resetn)begin
        ram_data_temp0 <= 64'h0;
        ram_data_temp1 <= 64'h0;
    end
    else begin
        if(enable_data_load)begin
            if(is_data0_load_fromA)begin
                if(is_mode_set1 && (read_counter_reg == 0))begin 
                    ram_data_temp0 <= 64'h1;
                end
                else if(is_mode_set0 || (is_mode_set1 && (read_counter_reg !=0)))begin 
                    ram_data_temp0 <= 64'h0;
                end
                else begin
                    ram_data_temp0 <= ram0_comalg_rdata;
                end
                ram_data_temp1 <= ram1_comalg_rdata;
            end
            else begin
                ram_data_temp0 <= ram1_comalg_rdata;
                ram_data_temp1 <= ram0_comalg_rdata;
            end
        end        
        else begin
            ram_data_temp0 <= 64'h0;
            ram_data_temp1 <= 64'h0;
        end
    end
end

assign is_data0_load_fromA = comalg_mode[3] == 1'b0;

assign enable_data_load = (is_read_state1 || is_read_state2 || is_write_state0);

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        alg_data <= 64'h0;
        carry_bit <= 1'b0;
    end else begin
        if(alg_start)begin
           carry_bit <= 1'b0; 
        end
        else if(is_alg_state)begin
            if (is_mode_add)     
                {carry_bit,alg_data} <= {1'b0,ram_data_temp0} + {1'b0,ram_data_temp1} + carry_bit;
             
            else if(is_mode_sub || is_mode_comp) 
                {carry_bit,alg_data} <= {1'b0,ram_data_temp0} - {1'b0,ram_data_temp1} - carry_bit;
            
            else if (is_mode_left) 
               {carry_bit,alg_data} <=  {ram_data_temp0[63:0],carry_bit};
            
            else if (is_mode_right) begin
                if (is_sign_opr && write_counter ==0 && is_read_state2)
                    {carry_bit,alg_data} <=  {ram_data_temp0[0],ram_data_temp0[63],ram_data_temp0[63:1]};
                else
                    {carry_bit,alg_data} <=  {ram_data_temp0[0],carry_bit,ram_data_temp0[63:1]};
            end 
            else if(is_mode_mov || is_mode_set0 || is_mode_set1)
                {carry_bit,alg_data} <= {carry_bit,ram_data_temp0};           
            else  
                {carry_bit,alg_data} <= {carry_bit,alg_data};           
        end
        else begin
            alg_data <= 64'h0;
            carry_bit <= carry_bit;  
        end
    end
end

assign is_alg_state = (is_read_state2 || is_write_state0 || is_write_state1);

assign enable_check_zero = is_write_state0|| is_write_state1 || is_write_state2;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        comalg_status[0] <= 1'b0;
    end
    else begin
        if(alg_start)begin
            comalg_status[0] <= 1'b1;
        end
        else if (enable_check_zero) begin
            if( (alg_data !=64'h0) && ( comalg_status[0] == 1))begin
                comalg_status[0] <= 1'b0;
            end
            else begin
                comalg_status[0] <= comalg_status[0];
            end
        end else begin
            comalg_status[0] <= comalg_status[0];
        end
    end
end

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        comalg_status[1] <= 1'b0;
    end
    else begin
        if(alg_start)begin
            comalg_status[1] <= 1'b0;
        end
        else if (load_carry_bit) begin
                comalg_status[1] <= alg_data[63];
        end else begin
            comalg_status[1] <= comalg_status[1];
        end
    end
end
assign load_carry_bit =  ( (is_mode_add || is_mode_sub || is_mode_right) && 
                           (is_write_state0 || is_write_state1 || is_write_state2) && 
                           (write_counter == comalg_wlen -1) ) ||
                         ( (is_mode_left )&& is_write_state0 && (write_counter == 0));
                         
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        comalg_status[2] <= 1'b0;
    end
    else begin
        if(alg_start)begin
            comalg_status[2] <= 1'b0;
        end
        else if (load_odd_event_bit) begin
                comalg_status[2] <= alg_data[0];
        end else begin
            comalg_status[2] <= comalg_status[2];
        end
    end
end
assign load_odd_event_bit = ( (is_mode_right) && 
                              (is_write_state0 || is_write_state1 || is_write_state2) && 
                              (write_counter == comalg_wlen -1) ) ||
                            ( (!is_mode_right) && is_write_state0 && ( write_counter == 0));
 

always @(posedge clk or negedge resetn) begin
    if(!resetn)
       read_counter_reg <= 8'h0;
    else
       read_counter_reg <= read_counter;
end

always @(posedge clk or negedge resetn) begin
    if(!resetn)
       read_counter <= 8'h0;
    else begin
        if(alg_start)
            read_counter <= 8'h0;
        else if(read_counter_inc)
            read_counter <= read_counter + 8'h1;
        else 
            read_counter <= read_counter;
    end
end
assign  read_counter_inc = (is_read_state0 || is_read_state1 || is_read_state2) && 
                           (read_counter < comalg_wlen);


always @(posedge clk or negedge resetn) begin
    if(!resetn)begin
       write_counter<= 8'h0;
    end
    else begin
        if(alg_start)
            write_counter<= 8'h0;
        
        else if(write_counter_inc)
            write_counter <= write_counter + 8'h1;       
        else 
            write_counter <= write_counter;
    end
end
assign write_counter_inc = (is_write_state0 || is_write_state1 || is_write_state2) && 
                            (write_counter < comalg_wlen); 


assign is_read_begin_high = is_mode_right;

assign comalg_ram0_wdata = alg_data;
assign comalg_ram1_wdata = alg_data;

assign comalg_ram0_rd = read_counter_inc;

assign comalg_ram0_addr = comalg_ram0_rd ? COMALG_A_ADDR + (is_read_begin_high ? (comalg_wlen - 1 - read_counter) : read_counter):
                                           COMALG_A_ADDR + (is_read_begin_high ? (comalg_wlen - 1 - write_counter) : write_counter);
                                
assign comalg_ram1_rd = read_counter_inc;

assign comalg_ram1_addr = comalg_ram1_rd ?  CMALG_B_ADDR + (is_read_begin_high ? (comalg_wlen - 1 - read_counter) : read_counter):
                                            CMALG_B_ADDR + (is_read_begin_high ? (comalg_wlen - 1 - write_counter) : write_counter);

assign comalg_ram0_wr = (is_write_state0 || is_write_state1 || is_write_state2) && 
                        (!comalg_mode[4]) && (~is_mode_comp);

assign comalg_ram1_wr = (is_write_state0 || is_write_state1 || is_write_state2) && 
                        (comalg_mode[4]) && (~is_mode_comp);
 
endmodule 

