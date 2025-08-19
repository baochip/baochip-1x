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

module ctr_aes
#(
  parameter GENERATE_0=4'd1,
  parameter GENERATE_1=4'd2,
  parameter GENERATE_2=4'd4,
  parameter GENERATE_3=4'd8,
  parameter RESEED_1  =11'd1,
  parameter RESEED_2  =11'd128,
  parameter RESEED_3  =11'd1024 
)
(
input  wire           clk,
input  wire           rstn,
input  wire           trng_drng_sel,
input  wire           trng_drng_sel_chg,
input  wire           rngcore_en,
input  wire           rngcore_rddone,
input  wire  [255:0]  buf_data,
input  wire           buf_ready,
input  wire  [1:0]    generate_interval,
input  wire  [1:0]    reseed_interval,
input  wire  [1:0]    postprocess_opt,
input  wire	      aes_done,
input  wire           additional_input_gen_en,
input  wire  [255:0]  additional_input_generate,
input  wire  [255:0]  additional_input_reseed,
input  wire  [255:0]  personalization_string,
input  wire  [255:0]  aes_text_out,
output wire           post_read_ctr,
output wire           drng_reseed_req,
output reg	      aes_start,
output wire	      aes_sel,
output reg   [127:0]  aes_key,
output reg   [127:0]  aes_text_in,
output reg   [127:0]  ctr_dataout,
output reg            ctr_dataout_vld
);

parameter IDLE  =3'd0;
parameter RESEED=3'd4;
parameter GEN1  =3'd1;
parameter GEN2  =3'd2;
parameter GEN3  =3'd3;
parameter K0    =128'h58e2fccefa7e3061367f1d57a4e7455a;
parameter M0    =128'h0388dace60b6a392f328c2b971b2fe78;

reg   [2:0]	    ctr_state_nxt;
reg   [2:0]	    ctr_state;    
reg   [3:0]	    generate_cnt;
reg   [11:0]    reseed_cnt; 
reg   [3:0]     generate_value;
reg   [10:0]    reseed_value;
reg             gen3_done_reseed;

wire  	       aes_start_pre;  
wire  [127:0]   aes_key_pre;     
wire  [127:0]   aes_text_in_pre; 
wire  [3:0]	    generate_cnt_pre;
wire  [11:0]    reseed_cnt_pre;  
wire  [127:0]   ctr_dataout_pre;
wire     	    ctr_dataout_vld_pre;
wire            gen3_done_reseed_pre;
wire            gen3_done_reseed_neg;
wire            rngcore_en_ctr;
wire            reseed_done;
wire            gen1_done;
wire            gen2_done;
wire            gen3_done_gen1;
wire            gen3_done_reseed_set;

assign rngcore_en_ctr = rngcore_en & (postprocess_opt==2'd2);
always@(*)begin
    if((~rngcore_en_ctr)|trng_drng_sel_chg)
       ctr_state_nxt = IDLE;
    else begin
        case(ctr_state)
   	    IDLE  : if (rngcore_en_ctr & buf_ready)
		        ctr_state_nxt = RESEED;
		    else
			ctr_state_nxt = IDLE;
            RESEED: if(reseed_done)
			if(additional_input_gen_en)
			    ctr_state_nxt = GEN1;
		        else
			    ctr_state_nxt = GEN2;
		        else
                            ctr_state_nxt = RESEED;
	    GEN1  : if(gen1_done)
		        ctr_state_nxt = GEN2;
		    else
	                ctr_state_nxt = GEN1;
	    GEN2  : if(gen2_done)
		        ctr_state_nxt = GEN3;
		    else
			ctr_state_nxt = GEN2;
           GEN3  : if(gen3_done_reseed_neg)
		       ctr_state_nxt = RESEED;
		   else if(gen3_done_gen1)begin
	                   if(additional_input_gen_en)
			       ctr_state_nxt = GEN1;
		           else
			       ctr_state_nxt = GEN2;
	           end
                   else
			       ctr_state_nxt = GEN3;
	   default: ctr_state_nxt = IDLE;
        endcase
    end
end

always @(posedge clk or negedge rstn)begin
    if(!rstn)begin
	ctr_state        <= 3'd0;
	aes_start        <= 1'b0;
        aes_key          <= 128'd0;
        aes_text_in      <= 128'd0;
	generate_cnt     <= 4'd0;
        reseed_cnt       <= 11'd0; 
	ctr_dataout      <= 128'h0;
	ctr_dataout_vld  <= 1'h0;
	gen3_done_reseed <= 1'h0;
    end
    else begin
	ctr_state        <= ctr_state_nxt;
	aes_start        <= aes_start_pre;
        aes_key          <= aes_key_pre;
        aes_text_in      <= aes_text_in_pre;
        generate_cnt     <= generate_cnt_pre;
        reseed_cnt       <= reseed_cnt_pre;
        ctr_dataout      <= ctr_dataout_pre;
	ctr_dataout_vld  <= ctr_dataout_vld_pre;
	gen3_done_reseed <= gen3_done_reseed_pre;
    end
end

assign post_read_ctr  =((ctr_state==IDLE)|gen3_done_reseed_neg)&rngcore_en_ctr & buf_ready;
assign aes_sel        = (ctr_state!=GEN2);
assign aes_start_pre  =((ctr_state==IDLE  )&(ctr_state_nxt==RESEED))|
	               ((ctr_state==RESEED)&(ctr_state_nxt==GEN1  ))|
	               ((ctr_state==RESEED)&(ctr_state_nxt==GEN2  ))|
	               ((ctr_state==GEN1  )&(ctr_state_nxt==GEN2  ))|
	               ((ctr_state==GEN2  )&(ctr_state_nxt==GEN3  ))|
	               ((ctr_state==GEN3  )&(ctr_state_nxt==RESEED))|
	               ((ctr_state==GEN3  )&(ctr_state_nxt==GEN1  ))|
	               ((ctr_state==GEN3  )&(ctr_state_nxt==GEN2  ))|
		       ((ctr_state==GEN2  )& rngcore_rddone & ctr_dataout_vld);

assign aes_key_pre    =((ctr_state==IDLE  )&(ctr_state_nxt==RESEED)) ? K0                   ^buf_data[255:128]^personalization_string[255:128]:
	              (((ctr_state==RESEED)&(ctr_state_nxt==GEN1  ))|
	               ((ctr_state==RESEED)&(ctr_state_nxt==GEN2  )))? aes_text_out[255:128]^buf_data[255:128]^additional_input_reseed[255:128]:
	               ((ctr_state==GEN1  )&(ctr_state_nxt==GEN2  )) ? aes_text_out[255:128]:
	              (((ctr_state==GEN3  )&(ctr_state_nxt==RESEED))|
	               ((ctr_state==GEN3  )&(ctr_state_nxt==GEN1  ))|
	               ((ctr_state==GEN3  )&(ctr_state_nxt==GEN2  )))? aes_text_out[255:128]                  ^additional_input_generate[255:128]:
		                   aes_key;
assign aes_text_in_pre=((ctr_state==IDLE  )&(ctr_state_nxt==RESEED)) ?(M0                   ^buf_data[127:0]  ^personalization_string[127:0])+1'b1:
	              (((ctr_state==RESEED)&(ctr_state_nxt==GEN1  ))|
	               ((ctr_state==RESEED)&(ctr_state_nxt==GEN2  )))?(aes_text_out[127:0]  ^buf_data[127:0]  ^additional_input_reseed[127:0])+1'b1:
	               ((ctr_state==GEN1  )&(ctr_state_nxt==GEN2  )) ?(aes_text_out[127:0]+1'b1):
	              (((ctr_state==GEN3  )&(ctr_state_nxt==RESEED))|
	               ((ctr_state==GEN3  )&(ctr_state_nxt==GEN1  ))|
	               ((ctr_state==GEN3  )&(ctr_state_nxt==GEN2  )))?(aes_text_out[127:0]                    ^additional_input_generate[127:0])+1'b1:
		       (ctr_state==GEN2  )& aes_done                ?(aes_text_in[127:0]+1'b1):
		       aes_text_in;

assign reseed_done     = (ctr_state==RESEED) & aes_done;
assign gen1_done       = (ctr_state==GEN1  ) & aes_done;
assign gen2_done       = (ctr_state==GEN2  ) & aes_done & (generate_cnt==(generate_value-1'b1));
assign gen3_done_reseed_set= (ctr_state==GEN3  ) & aes_done & (reseed_cnt  ==(reseed_value-1'b1)) & (reseed_interval!=2'h0);
assign gen3_done_reseed_pre= gen3_done_reseed_set ? 1'b1 :(gen3_done_reseed & buf_ready)? 1'b0: gen3_done_reseed;
assign gen3_done_reseed_neg= (~gen3_done_reseed_pre)& gen3_done_reseed;
assign gen3_done_gen1  = (ctr_state==GEN3  ) & aes_done &((reseed_cnt  !=(reseed_value-1'b1)) | (reseed_interval==2'h0));
assign drng_reseed_req = gen3_done_reseed_set;

assign generate_cnt_pre= (~rngcore_en_ctr )| (ctr_state!=GEN2)  ? 4'h0  :
                         (ctr_state==GEN2) & aes_done       ? (generate_cnt +1'b1):generate_cnt;
assign reseed_cnt_pre  = (~rngcore_en_ctr)| (ctr_state==RESEED) | (ctr_state==IDLE)? 11'd0 : 
                         (ctr_state==GEN3) & aes_done       ? (reseed_cnt +1'b1):reseed_cnt;

assign ctr_dataout_pre    = (ctr_state==GEN2  ) & aes_done ? aes_text_out[127:0] : ctr_dataout;
assign ctr_dataout_vld_pre= (ctr_state==GEN2  ) & aes_done ? 1'b1: rngcore_rddone ? 1'b0:ctr_dataout_vld;

always@(*)begin
    case(generate_interval)
        2'd0   : generate_value = GENERATE_0;     
	2'd1   : generate_value = GENERATE_1;     
	2'd2   : generate_value = GENERATE_2;     
	2'd3   : generate_value = GENERATE_3;
	default: generate_value = GENERATE_3;
    endcase
end     

always@(*)begin
    case(reseed_interval)
	2'd1   : reseed_value = RESEED_1;     
	2'd2   : reseed_value = RESEED_2;     
	2'd3   : reseed_value = RESEED_3;
	default: reseed_value = RESEED_3;
    endcase
end 

endmodule
