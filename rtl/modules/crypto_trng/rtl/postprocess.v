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

module postprocess
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
input  wire          clk,
input  wire          rstn,
input  wire          trng_drng_sel,
input  wire          trng_drng_sel_chg,
input  wire          rngcore_en,
input  wire          rngcore_rddone,
input  wire          buf_write,
input  wire [2:0]    buf_addr,
input  wire [255:0]  buf_data,
input  wire          buf_ready,
input  wire [1:0]    generate_interval,
input  wire [1:0]    reseed_interval,
input  wire [1:0]    postprocess_opt,
input  wire          postprocess_opt_chg,
input  wire          additional_input_gen_en,
input  wire [255:0]  additional_input_generate,
input  wire [255:0]  additional_input_reseed,
input  wire [255:0]  personalization_string,
input  wire          digi_data_out,
input  wire          digi_data_vld,
output wire          post_read,
output reg           drng_reseed_req,
output wire [127:0]  rngcore_dataout,
output wire          rngcore_dataout_vld
);

wire            aes_start;
wire            aes_sel;
wire   [127:0]  aes_key;
wire   [127:0]  aes_text_in;
wire   [127:0]  lfsr_dataout;
wire   [127:0]  ctr_dataout;
wire   [255:0]  aes_text_out;
wire   [127:0]  aes_key_sel;
wire   [127:0]  aes_key_ctr;
wire   [127:0]  aes_text_in_sel;
wire   [127:0]  aes_text_in_ctr;
wire            aes_start_sel;
wire            aes_done_vld_pre;
wire            rngcore_en_pos;
wire            aes_flag_pre;
wire            post_read_lfsr;
wire            post_read_ctr;
wire            drng_reseed_req_lfsr;
wire            drng_reseed_req_ctr;
wire            lfsr_dataout_vld;
wire            ctr_dataout_vld;
wire            aes_done;
wire            aes_start_ctr;
wire            aes_sel_ctr;
wire            drng_reseed_req_pre;

reg             rngcore_en_dly;
reg             aes_done_vld;
reg             aes_flag;

lfsr129 #(.GENERATE_0(GENERATE_0),
	  .GENERATE_1(GENERATE_1),
	  .GENERATE_2(GENERATE_2),
	  .GENERATE_3(GENERATE_3),
          .RESEED_1  (RESEED_1  ),
          .RESEED_2  (RESEED_2  ),
          .RESEED_3  (RESEED_3  ))
u_lfsr129(
 	.clk                 	   (clk                	     ),
 	.rstn                	   (rstn               	     ), 
 	.trng_drng_sel   	   (trng_drng_sel  	     ),
 	.trng_drng_sel_chg   	   (trng_drng_sel_chg  	     ),
        .postprocess_opt           (postprocess_opt          ),
	.rngcore_en                (rngcore_en               ),
 	.digi_data_out     	   (digi_data_out            ),
 	.digi_data_vld     	   (digi_data_vld            ),	
        .rngcore_rddone            (rngcore_rddone           ),
        .buf_data                  (buf_data                 ),
 	.buf_ready           	   (buf_ready          	     ),
 	.generate_interval   	   (generate_interval        ),
 	.reseed_interval     	   (reseed_interval    	     ),
        .post_read_lfsr            (post_read_lfsr           ),
        .drng_reseed_req           (drng_reseed_req_lfsr     ),
        .lfsr_dataout              (lfsr_dataout             ),
 	.lfsr_dataout_vld    	   (lfsr_dataout_vld   	     )
); 	
        
ctr_aes #(.GENERATE_0(GENERATE_0),
	  .GENERATE_1(GENERATE_1),
	  .GENERATE_2(GENERATE_2),
	  .GENERATE_3(GENERATE_3),
          .RESEED_1  (RESEED_1  ),
          .RESEED_2  (RESEED_2  ),
          .RESEED_3  (RESEED_3  ))
u_ctr_aes( 
 	.clk                       (clk                      ),
 	.rstn                      (rstn                     ),
 	.trng_drng_sel             (trng_drng_sel            ),
        .trng_drng_sel_chg         (trng_drng_sel_chg        ),
        .rngcore_en                (rngcore_en               ),
        .rngcore_rddone            (rngcore_rddone           ),
 	.buf_data                  (buf_data                 ),
 	.buf_ready                 (buf_ready                ),
 	.generate_interval         (generate_interval        ),
        .reseed_interval           (reseed_interval          ),
	.postprocess_opt           (postprocess_opt          ),
        .aes_done                  (aes_done                 ),
        .additional_input_gen_en   (additional_input_gen_en  ),
 	.additional_input_generate (additional_input_generate),
 	.additional_input_reseed   (additional_input_reseed  ),
 	.personalization_string    (personalization_string   ),
        .post_read_ctr             (post_read_ctr            ),
        .drng_reseed_req           (drng_reseed_req_ctr      ),
        .aes_start                 (aes_start_ctr            ),
        .aes_sel                   (aes_sel_ctr              ),
 	.aes_key                   (aes_key_ctr              ),
 	.aes_text_in               (aes_text_in_ctr          ),
 	.aes_text_out              (aes_text_out             ),
        .ctr_dataout               (ctr_dataout              ),
        .ctr_dataout_vld           (ctr_dataout_vld          ) 
);                      

aes_update u_aes_update(
 	.clk           	           (clk                      ), 
 	.rstn           	   (rstn                     ),
 	.ld            	   	   (aes_start_sel            ),
        .sel                       (aes_sel                  ),
        .done                      (aes_done                 ),
	.key          	           (aes_key_sel              ),
	.text_in      	           (aes_text_in_sel          ),
	.text_out     	           (aes_text_out             )
);              	
    
assign rngcore_dataout    =(postprocess_opt==2'd0)? lfsr_dataout[127:0]  :
               	           (postprocess_opt==2'd1) & (~aes_flag) ? aes_text_out[255:128]:
               	           (postprocess_opt==2'd1) &   aes_flag  ? aes_text_out[127:0]  :
		                                                             ctr_dataout[127:0]   ;

assign rngcore_dataout_vld=(postprocess_opt==2'd0)? lfsr_dataout_vld     :
               	           (postprocess_opt==2'd1)? aes_done_vld         :
			                                           ctr_dataout_vld      ;

assign post_read          =(postprocess_opt==2'd0)? post_read_lfsr       :
               	           (postprocess_opt==2'd1)? rngcore_en_pos       :
			                                           post_read_ctr        ;
					    
assign drng_reseed_req_pre=(postprocess_opt_chg | (~trng_drng_sel) | (trng_drng_sel&buf_write& (|buf_addr)))? 1'b0:
                         (((postprocess_opt==2'd0)& drng_reseed_req_lfsr)|
               	          ((postprocess_opt==2'd2)& drng_reseed_req_ctr))? 1'b1:drng_reseed_req;
					    
assign aes_start_sel      =(postprocess_opt==2'd1)? rngcore_en_pos       :
			                            aes_start_ctr        ;

assign aes_sel            =(postprocess_opt==2'd1)? 1'b1                 :
	                   (postprocess_opt==2'd2)& aes_sel_ctr          ;
					 
assign aes_key_sel        =(postprocess_opt==2'd1)? buf_data[255:128]    :
	                                            aes_key_ctr          ;

assign aes_text_in_sel    =(postprocess_opt==2'd1)? buf_data[127:0]      :
      	                                            aes_text_in_ctr      ;

assign aes_done_vld_pre   =(postprocess_opt!=2'd1)|(aes_done_vld&rngcore_rddone&aes_flag) ? 1'b0: 
  	                   (postprocess_opt==2'd1)& aes_done                              ? 1'b1: aes_done_vld;

assign aes_flag_pre       =(postprocess_opt!=2'd1)|(rngcore_rddone&   aes_flag)|((postprocess_opt==2'd1)&aes_done)? 1'b0: 
  	                   (postprocess_opt==2'd1)& rngcore_rddone& (~aes_flag)                                   ? 1'b1: aes_flag;

assign rngcore_en_pos     = rngcore_en &  (~rngcore_en_dly);

always @(posedge clk  or negedge rstn)begin
    if(!rstn)begin	
	rngcore_en_dly      <= 1'b0;
        aes_done_vld        <= 1'b0;
	aes_flag            <= 1'b0;
	drng_reseed_req     <= 1'b0;
    end
    else begin
	rngcore_en_dly      <= rngcore_en;
        aes_done_vld        <= aes_done_vld_pre;
        aes_flag            <= aes_flag_pre;
	drng_reseed_req     <= drng_reseed_req_pre;
    end
end
					    
endmodule     
