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

`default_nettype none
`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_global_rtl_define.vh"
`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_user_rtl_define.vh"
`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_rtl_define.vh"

module trbcx1r32_daric_wrapper (
bist_enable
,bist_rst_n
,jtag_trst_n
,clk
,bist_clk
//,inv_clk
`ifdef OPT_PIPELINE_READ
  `ifdef OPT_ASYNC_READ
,async_clk
//,async_rst_n
  `endif
`endif
,tck
,inv_tck
,tms
,tdi
,tdo

,scan_test
//,scan_en
//,scan_rst_n

//,rram_htol_i
//,rram_rst_i
//,rram_pd_i

//user mode
,rst_n  //to TRC
,ip_user_cmd_i
,ip_user_info_i
,ip_user_ifren1_i
,ip_user_reden_i
//,ip_user_lven_i
,ip_user_xadr_i
,ip_user_yadr_i
,ip_user_udin_i
,ip_user_tdin_i
,ip_user_nap_i
,ip_user_pd_i
,ip_user_trc_data_i
//,ip_user_write_abort_i

`ifdef  OPT_ECC_INPUT_OVERRIDE
,ip_user_override_ecc_i
,ip_user_ecc_i
`endif

`ifdef OPT_CODEWORD_EXPOSE
                ,to_decoder_codeword
`endif

,trc_dout_o
,trc_dout_ready_o
,ecc_err_o
,trc_regif_dout_o
,trc_busy_o
,trc_err_o
`ifdef OPT_IFR1_LOCK
,trc_ifr1_lock_err_o
`endif
`ifdef OPT_ASYNC_READ
// ---- input from async read I/F ----
,async_rst_n
,async_access_i
,async_ifren_i
,async_ifren1_i
,async_reden_i
,async_read_i
,async_pch_ext_i
,async_xadr_i
,async_yadr_i

//,async_rram_dout_o
,async_rram_rdone_o
`endif

,trc_write_suspend_i
,trc_write_resume_i
,trc_write_abort_i
,trc_write_suspend_o


`ifdef TRC_EXT_ECC
// ---- external ECC I/F ----
,to_encoder_message
,to_encoder_mode
,to_decoder_codeword
//,to_decoder_en_delay

,from_encoder_codeword
,from_decoder_message
`endif

`ifdef TRC_WRITE_MON
,to_dio_trc_xe
,to_dio_trc_set
,to_dio_trc_reset
,to_dio_trc_accum_bit_count
,to_dio_trc_shot_number
,to_dio_trc_xadr
,to_dio_trc_yadr
`endif

`ifdef BIST_REGIF_PAR_MODE
,ip_user_bist_regif_write_en_i
,ip_user_bist_regif_adr_i
,ip_user_bist_regif_wdata_i
,ip_user_bist_regif_par_mode_i
,bist_regif_dout_o
,bist_busy
`endif

`ifdef TC
,rram_xadr_o
,rram_yadr_o
,rram_full_din_o
,rram_set_o
,rram_reset_o
,rram_xe_o
,rram_ye_o
,rram_read_o
,rram_ae_o
,rram_info_o
,rram_ifren1_o
,rram_reden_o
,rram_pch_ext_o
,rram_nap_o
//,rram_pd_o
//,rram_rst_n_o
//,rram_lven_o
,rram_cfg_o
,rram_rst_o
,rram_ce_o
,rram_ck_ext_o
,rram_htol_en_o
,rram_recall_o

,rram_rdone_i
,rram_dout_i

,bist_status
,bist_busy

,numbank_is_2 //BANK2
,numbank_is_4 //BANK4
,numbank_is_6 //BANK6
,numbank_is_8 //BANK8

,numbankaddrx_is_1 //BANK2
,numbankaddrx_is_2 //BANK4
,numbankaddrx_is_3 //BANK6 and BANK8

,numwl_addrx_is_7  //WL128
,numwl_addrx_is_8  //WL256
,numwl_addrx_is_9  //WL512
,numwl_addrx_is_10 //WL1024

,numinfowl_addrx_is_3 //INFO8
,numinfowl_addrx_is_4 //INFO16
,numinfowl_addrx_is_5 //INFO32
,numinfowl_addrx_is_6 //INFO64

,trc_no_init_in_dma_mode
`endif

`ifdef TRC_WRITE_STATUS
// ---- monitored FBC
  `ifdef TRC_WRITE_STATUS_4TH_READ_ONLY
,trc_fourth_read_failure_status
  `else
,trc_set_failure_status
,trc_reset_failure_status
,trc_fourth_read_failure_status
  `endif //TRC_WRITE_STATUS_4TH_READ_ONLY
`endif //TRC_WRITE_STATUS

`ifdef OPT_CFG_OVERRIDE
,ip_user_override_cfg_enable_i
,ip_user_override_cfg_i
`endif

,sw_r_cfg_status

,rri
,rro

//,POC_IO
//,ANALOG_0

,ifr_index
,ifr_read_dis_test
,ifr_write_dis_test
,boot0_write_dis_test
,boot0_read_dis_test
,boot1_write_dis_test
,boot1_read_dis_test
,fw0_write_dis_test
,fw0_read_dis_test
,fw1_write_dis_test
,fw1_read_dis_test
,rrsub_size_test

);

`ifdef TC
parameter    numAddrX =  13                     ;
`else
parameter    numAddrX = `numBankAddrX + `numWLAddrX ;
`endif
parameter    numAddrY =   5                     ;
parameter    numADR   =  numAddrX + numAddrY    ;
parameter    numUData =  128                    ;
parameter    numCR    =  2       ;
parameter    numPData =  16                     ;
parameter    numTData =  numPData + numCR       ;
parameter    numData  =  numUData + numTData    ;
parameter    numIO    =  numUData + numPData    ;
parameter    numSZ    =   0                     ;

parameter    numCFG  = 210       ;

`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_user_rtl_parameter.vh"

defparam u_trc_top.numROW           = numROW ;
defparam u_trc_top.BLM_only         = BLM_only ;
defparam u_bist_top_mux.power_of_buf  = numROW ;
//defparam u_trc_top.u_trc_regif.u_trc_regif_auto.TCYC_UNIT = 4'b1111 ;


parameter numData_trcreg=64;

output rrc_pkg::rri_t rri;
input  rrc_pkg::rro_t rro;

input bist_enable;
input bist_rst_n,jtag_trst_n;
input rst_n;
input clk/*,inv_clk*/;
input bist_clk ;
`ifdef OPT_PIPELINE_READ
  `ifdef OPT_ASYNC_READ
input async_clk;
//input async_rst_n;
  `endif
`endif
input tck,inv_tck;
input tms;
input tdi;
output tdo;

input scan_test;
//input scan_rst_n;
//input scan_en;
//input rram_htol_i ;
//input rram_rst_i  ;
//input rram_pd_i   ;
input [3:0]ip_user_cmd_i;
input ip_user_info_i;
input ip_user_ifren1_i;
input ip_user_reden_i;
//input ip_user_lven_i;
input [numAddrX-1:0]ip_user_xadr_i;
input [numAddrY-1:0]ip_user_yadr_i;
input [numUData-1:0]ip_user_udin_i;
input [numTData-1:0]ip_user_tdin_i;
input ip_user_nap_i;
input ip_user_pd_i;
input [numData_trcreg-1:0]ip_user_trc_data_i;
//input ip_user_write_abort_i;

`ifdef  OPT_ECC_INPUT_OVERRIDE
input       ip_user_override_ecc_i;
input [1:0] ip_user_ecc_i;

wire        ip_user_override_ecc_i;
wire  [1:0] ip_user_ecc_i;
wire        ip_mux_override_ecc;
wire  [1:0] ip_mux_ecc;
`endif

`ifdef OPT_CODEWORD_EXPOSE
output [143:0] to_decoder_codeword                       ;
wire   [143:0] to_decoder_codeword                       ;
`endif

output [numData-1:0] trc_dout_o;
output               trc_dout_ready_o;
output [ 2:0]        ecc_err_o;
output [63:0]        trc_regif_dout_o;
output               trc_busy_o;
output               trc_err_o;
`ifdef OPT_IFR1_LOCK
output               trc_ifr1_lock_err_o;
`endif

`ifdef OPT_ASYNC_READ
input                 async_rst_n                        ;
input                 async_access_i                     ;
input                 async_ifren_i                      ;
input                 async_ifren1_i                     ;
input                 async_reden_i                      ;
input                 async_read_i                       ;
input                 async_pch_ext_i                    ;
input [numAddrX-1:0]  async_xadr_i                       ;
input [numAddrY-1:0]  async_yadr_i                       ;

//output [numData-1:0]  async_rram_dout_o                  ;
output                async_rram_rdone_o                 ;
`endif

input                 trc_write_suspend_i                ;
input                 trc_write_resume_i                 ;
input                 trc_write_abort_i                  ;
output                trc_write_suspend_o                ;


`ifdef TRC_EXT_ECC
// ---- external ECC I/F ----
output [127:0] to_encoder_message                        ;
output         to_encoder_mode                           ;
output [143:0] to_decoder_codeword                       ;
//output         to_decoder_en_delay                       ;
input  [143:0] from_encoder_codeword                     ;
input  [127:0] from_decoder_message                      ;
`endif

`ifdef TRC_WRITE_MON
output        to_dio_trc_xe               ;
output        to_dio_trc_set              ;
output        to_dio_trc_reset            ;
output [8:0]  to_dio_trc_accum_bit_count  ;
output [5:0]  to_dio_trc_shot_number      ;
output [numAddrX-1:0] to_dio_trc_xadr     ;
output [numAddrY-1:0] to_dio_trc_yadr     ;
`endif

`ifdef TC
output [numAddrX-1:0] rram_xadr_o ;
output [numAddrY-1:0] rram_yadr_o                  ;
output [numData-1:0] rram_full_din_o               ;
output  rram_set_o                                 ;
output  rram_reset_o                               ;
output  rram_xe_o                                  ;
output  rram_ye_o                                  ;
output  rram_read_o                                ;
output  rram_ae_o                                  ;
output  rram_info_o                                ;
output  rram_ifren1_o                              ;
output  rram_reden_o                               ;
output  rram_pch_ext_o                             ;
output  rram_nap_o                                 ;
//,rram_pd_o                                       ;
//,rram_rst_n_o                                    ;
//,rram_lven_o                                     ;
output [numCFG-1:0] rram_cfg_o                     ;
output  rram_rst_o                                 ;
output  rram_ce_o                                  ;
output  rram_ck_ext_o                              ;
output  rram_htol_en_o                             ;
output  rram_recall_o                              ;

input   rram_rdone_i                               ;
input  [numData-1 : 0] rram_dout_i                 ;

output  bist_status                                ;
output  bist_busy                                  ;

input   numbank_is_2 ;//BANK2
input   numbank_is_4 ;//BANK4
input   numbank_is_6 ;//BANK6
input   numbank_is_8 ;//BANK8
input   numbankaddrx_is_1 ;//BANK2
input   numbankaddrx_is_2 ;//BANK4
input   numbankaddrx_is_3 ;//BANK6 and BANK8
input   numwl_addrx_is_7  ;//WL128
input   numwl_addrx_is_8  ;//WL256
input   numwl_addrx_is_9  ;//WL512
input   numwl_addrx_is_10 ;//WL1024
input   numinfowl_addrx_is_3 ;//INFO8
input   numinfowl_addrx_is_4 ;//INFO16
input   numinfowl_addrx_is_5 ;//INFO32
input   numinfowl_addrx_is_6 ;//INFO64

input   trc_no_init_in_dma_mode                    ;
`endif

`ifdef TRC_WRITE_STATUS
// ---- monitored FBC
  `ifdef TRC_WRITE_STATUS_4TH_READ_ONLY
output [numBuf*2-1:0] trc_fourth_read_failure_status ;
  `else
output [numBuf*2-1:0] trc_set_failure_status         ;
output [numBuf*2-1:0] trc_reset_failure_status       ;
output [numBuf*2-1:0] trc_fourth_read_failure_status ;
  `endif //TRC_WRITE_STATUS_4TH_READ_ONLY
`endif //TRC_WRITE_STATUS

`ifdef OPT_CFG_OVERRIDE
input ip_user_override_cfg_enable_i ;
input [numCFG-1 : 0] ip_user_override_cfg_i ;
wire ip_user_override_cfg_enable_i ;
wire [numCFG-1 : 0] ip_user_override_cfg_i ;
`endif

output sw_r_cfg_status ;

//input POC_IO ;

//inout ANALOG_0  ;

//input POC_H;
//connect bist to trc

output wire [4:0]   ifr_index;
input  wire         ifr_read_dis_test;
input  wire         ifr_write_dis_test;
input  wire         boot0_write_dis_test;
input  wire         boot0_read_dis_test;
input  wire         boot1_write_dis_test;
input  wire         boot1_read_dis_test;
input  wire         fw0_write_dis_test;
input  wire         fw0_read_dis_test;
input  wire         fw1_write_dis_test;
input  wire         fw1_read_dis_test;
input  wire [39:0]  rrsub_size_test;
     

wire bist_enable;
wire bist_rst_n,jtag_trst_n;
wire rst_n;
wire clk;
wire bist_clk;
//wire inv_clk;
`ifdef OPT_PIPELINE_READ
  `ifdef OPT_ASYNC_READ
wire async_clk;
//wire async_rst_n;
  `endif
`endif
wire tck;
wire inv_tck;
wire tms;
wire tdi;
wire scan_test;
//wire scan_rst_n;
//wire scan_en;
wire [3:0]ip_user_cmd_i;
wire ip_user_info_i;
wire ip_user_ifren1_i;
wire ip_user_reden_i;
//wire ip_user_lven_i;
wire [numAddrX-1:0]ip_user_xadr_i;
wire [numAddrY-1:0]ip_user_yadr_i;
wire [numUData-1:0]ip_user_udin_i;
wire [numTData-1:0]ip_user_tdin_i;
wire ip_user_nap_i;
wire ip_user_pd_i;
wire [numData_trcreg-1:0]ip_user_trc_data_i;
//wire tdo_temp;
wire tdo;

wire [numData-1:0] trc_dout_o;
wire [63:0]        trc_regif_dout_o;
wire               trc_busy_o;
wire               trc_err_o;
`ifdef OPT_IFR1_LOCK
wire               trc_ifr1_lock_err_o;
`endif

wire ip_mux_reden;
wire ip_mux_ifren1;
//wire ip_mux_lven;
wire ip_mux_info;
wire ip_mux_nap;
wire ip_mux_pd ;
wire [3:0] ip_mux_cmd;
wire [numAddrX-1 :0]ip_mux_xadr;
wire [numAddrY-1 :0]ip_mux_yadr;
wire [numUData-1 : 0] ip_mux_udin;
wire [numTData-1 : 0] ip_mux_tdin;

wire [63 : 0]ip_mux_trc_data;

wire [numData-1:0]ip_trc_dout;
wire [numData-1:0] trc_to_bist_dout;
wire [63:0]ip_trc_regif_dout;
wire ip_trc_busy;
//wire tdo_temp;
//assign tdo = bist_enable? tdo_temp : trc_busy_o;
wire ip_trc_err ;
wire [19:0]ip_trc_write_status;


`ifdef TC
wire [numAddrX-1:0] rram_xadr_o ;
wire [numAddrY-1:0] rram_yadr_o                  ;
wire [numData-1:0] rram_full_din_o               ;
wire  rram_set_o                                 ;
wire  rram_reset_o                               ;
wire  rram_xe_o                                  ;
wire  rram_ye_o                                  ;
wire  rram_read_o                                ;
wire  rram_ae_o                                  ;
wire  rram_info_o                                ;
wire  rram_ifren1_o                              ;
wire  rram_reden_o                               ;
wire  rram_pch_ext_o                             ;
wire  rram_nap_o                                 ;
//,rram_pd_o                                       ;
//,rram_rst_n_o                                    ;
//,rram_lven_o                                     ;
wire [numCFG-1:0] rram_cfg_o                     ;
wire  rram_rst_o                                 ;
wire  rram_ce_o                                  ;
wire  rram_ck_ext_o                              ;
wire  rram_htol_en_o                             ;
wire  rram_recall_o                              ;

wire   rram_rdone_i                               ;
wire  [numData-1 : 0] rram_dout_i                 ;

wire   bist_status                                ;
wire   bist_busy                                  ;

wire   numbank_is_2 ;//BANK2
wire   numbank_is_4 ;//BANK4
wire   numbank_is_6 ;//BANK6
wire   numbank_is_8 ;//BANK8
wire   numbankaddrx_is_1 ;//BANK2
wire   numbankaddrx_is_2 ;//BANK4
wire   numbankaddrx_is_3 ;//BANK6 and BANK8
wire   numwl_addrx_is_7  ;//WL128
wire   numwl_addrx_is_8  ;//WL256
wire   numwl_addrx_is_9  ;//WL512
wire   numwl_addrx_is_10 ;//WL1024
wire   numinfowl_addrx_is_3 ;//INFO8
wire   numinfowl_addrx_is_4 ;//INFO16
wire   numinfowl_addrx_is_5 ;//INFO32
wire   numinfowl_addrx_is_6 ;//INFO64

wire   trc_no_init_in_dma_mode                    ;
`else

wire rram_rdone;
wire rram_set;
wire rram_reset;
//wire [numAddrX-1:0] rram_xadr;
wire [`numBankAddrX+`numWLAddrX-1:0] rram_xadr;
wire [numAddrY-1:0] rram_yadr;
wire [numData-1:0]rram_full_din;
wire [numCFG-1:0] rram_cfg;
//wire rram_recall;
//wire rram_ck_ext;
wire rram_rst;
wire rram_ce ;
wire rram_nap;
//wire rram_pd;
//wire rram_rst_n;
//wire rram_htol_en;
//wire rram_poc_h;
wire rram_info;
wire rram_ifren1;
wire rram_reden;
wire rram_xe;
wire rram_ye;
wire rram_read;
//wire rram_lven;
wire rram_pch_ext;
wire rram_ae;

wire [numCR-1:0] dout_cr;

wire [numData-1 : 0]  ip_dout                 ;
wire [numIO-1   : 0]  ip_dout_ori             ;
`endif //`ifdef TC

wire [numUData-1:0]   trc_udout_o             ;
wire [numTData-1:0]   trc_tdout_o             ;

wire [numCFG-1  :0]  trc_to_bist_trim_default              ;
wire [numCFG-1  :0]  trc_to_bist_trim_default_loc          ;
wire [128-1     :0]  trc_to_bist_trim_global_set           ;
wire [128-1     :0]  trc_to_bist_trim_global_set_loc       ;
wire [128-1     :0]  trc_to_bist_trim_global_reset         ;
wire [128-1     :0]  trc_to_bist_trim_global_reset_loc     ;
//wire [7:0]           trc_to_bist_read_cycle                ;
wire                 trc_dout_ready_o                      ;
wire [2:0]           ecc_err_o                             ;
//wire                 ip_user_write_abort_i ;

`ifdef OPT_ASYNC_READ
wire                 async_rst_n                        ;
wire                 async_access_i                     ;
wire                 async_ifren_i                      ;
wire                 async_ifren1_i                     ;
wire                 async_reden_i                      ;
wire                 async_read_i                       ;
wire                 async_pch_ext_i                    ;
wire [numAddrX-1:0]  async_xadr_i                       ;
wire [numAddrY-1:0]  async_yadr_i                       ;
//wire [numData-1:0]   async_rram_dout_o                  ;
wire                 async_rram_rdone_o                 ;
`endif

wire                 trc_write_suspend_i                ;
wire                 trc_write_resume_i                 ;
wire                 trc_write_abort_i                  ;
wire                 trc_write_suspend_o                ;

//assign rram_rst         = ~rst_n            ;



`ifdef TRC_EXT_ECC
wire [127:0] to_encoder_message                        ;
wire         to_encoder_mode                           ;
wire [143:0] to_decoder_codeword                       ;
//wire         to_decoder_en_delay                       ;
wire [143:0] from_encoder_codeword                     ;
wire [127:0] from_decoder_message                      ;
`endif

`ifdef TRC_WRITE_MON
wire        to_dio_trc_xe               ;
wire        to_dio_trc_set              ;
wire        to_dio_trc_reset            ;
wire [8:0]  to_dio_trc_accum_bit_count  ;
wire [5:0]  to_dio_trc_shot_number      ;
wire [numAddrX-1:0] to_dio_trc_xadr     ;
wire [numAddrY-1:0] to_dio_trc_yadr     ;
`endif


`ifdef BIST_REGIF_PAR_MODE
input wire ip_user_bist_regif_write_en_i;
input wire [5:0] ip_user_bist_regif_adr_i;
input wire [40-1:0] ip_user_bist_regif_wdata_i;
input wire ip_user_bist_regif_par_mode_i;
output wire [40-1:0] bist_regif_dout_o;
output wire bist_busy;
`endif

`ifdef TRC_WRITE_STATUS
// ---- monitored FBC
  `ifdef TRC_WRITE_STATUS_4TH_READ_ONLY
wire [numBuf*2-1:0] trc_fourth_read_failure_status ;
  `else
wire [numBuf*2-1:0] trc_set_failure_status         ;
wire [numBuf*2-1:0] trc_reset_failure_status       ;
wire [numBuf*2-1:0] trc_fourth_read_failure_status ;
  `endif //TRC_WRITE_STATUS_4TH_READ_ONLY
`endif //TRC_WRITE_STATUS

wire sw_r_cfg_status ;
wire  [(numUData+numPData-1):0] trc_to_bist_misr_data_reg_o ;
wire POC_IO ;

wire ANALOG_0  ;

//assign ip_user_pd_i = 1'b0 ;
//assign ip_user_lven_i = 1'b0 ;
//assign ip_user_write_abort_i = 1'b0 ;

assign ip_trc_dout      = {trc_tdout_o, trc_udout_o} ;
assign trc_to_bist_dout = ip_trc_dout       ;
assign trc_dout_o       = ip_trc_dout       ;
assign trc_regif_dout_o = ip_trc_regif_dout ;
assign trc_busy_o       = ip_trc_busy       ;
assign trc_err_o        = ip_trc_err        ;

trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_top_mux u_bist_top_mux(
                // ---- system and reset ----
    .bist_enable            (bist_enable    ),
    .clk      (bist_clk   ),
    //.rst_n      (rst_n      ),
    .jtag_rst_n   (jtag_trst_n  ),
    .bist_rst_n   (bist_rst_n   ),
    // ---- scan test ----
        //.scan_test      ( scan_test    ),
        //.scan_en        ( scan_en      ),
        //.scan_rst_n     ( scan_rst_n   ),
    // ---- JTAG interface ----
    .tck      (tck      ),
    .inv_tck    (inv_tck    ),
    .tms      (tms      ),
    .tdi      (tdi      ),
    .tdo      (tdo      ),
`ifdef BIST_MON_RD
        .debug_bist_bus_to_pad        (debug_bist_bus_to_pad),
        .debug_bist_intrupt_ps_to_pad (debug_bist_intrupt_ps_to_pad),
`endif
`ifdef TC
        .bist_status (bist_status),
        .bist_busy   (bist_busy),
`endif

`ifdef BIST_REGIF_PAR_MODE
       .ip_user_bist_regif_write_en_i(ip_user_bist_regif_write_en_i),
       .ip_user_bist_regif_adr_i(ip_user_bist_regif_adr_i),
       .ip_user_bist_regif_wdata_i(ip_user_bist_regif_wdata_i),
       .ip_user_bist_regif_par_mode_i(ip_user_bist_regif_par_mode_i),
       .bist_regif_dout_o(bist_regif_dout_o),
       .bist_busy(bist_busy),
`endif
    // ---- input from user mode ----
    .ip_user_cmd_i      ( ip_user_cmd_i       ),
        .ip_user_ifren1_i   ( ip_user_ifren1_i    ),
        .ip_user_reden_i    ( ip_user_reden_i     ),
    .ip_user_info_i   ( ip_user_info_i    ),
    .ip_user_xadr_i   ( ip_user_xadr_i    ),
    .ip_user_yadr_i   ( ip_user_yadr_i    ),
    .ip_user_udin_i   ( ip_user_udin_i    ),
    .ip_user_tdin_i   ( ip_user_tdin_i    ),
    .ip_user_nap_i    ( ip_user_nap_i       ),
        .ip_user_pd_i       ( ip_user_pd_i        ),
    .ip_user_trc_data_i ( ip_user_trc_data_i  ),
    .ip_trc_dout_i          (trc_to_bist_dout),
    .ip_trc_regif_dout_i  (ip_trc_regif_dout),
    .ip_trc_busy_i    (ip_trc_busy    ),
        .ip_trc_dout_ready_i (trc_dout_ready_o),
    //.ip_trc_err_i   (ip_trc_err   ),
    .ip_trc_write_status_i  (ip_trc_write_status  ),
    .ip_mux_reden_o     (ip_mux_reden   ),
    .ip_mux_ifren1_o  (ip_mux_ifren1    ),
//.ip_mux_lven_o    (ip_mux_lven    ),
    .ip_mux_info_o    (ip_mux_info    ),
    .ip_mux_cmd_o   (ip_mux_cmd   ),
    .ip_mux_xadr_o    (ip_mux_xadr    ),
    .ip_mux_yadr_o    (ip_mux_yadr    ),
    .ip_mux_udin_o    (ip_mux_udin    ),
    .ip_mux_tdin_o    (ip_mux_tdin    ),
    .ip_mux_trc_data_o  (ip_mux_trc_data  ),
    .ip_mux_nap_o   (ip_mux_nap   ),
        .ip_mux_pd_o        (ip_mux_pd      ),
       // ---- trim verify ----
                .trc_to_bist_trim_default           (trc_to_bist_trim_default) ,
                .trc_to_bist_trim_default_loc       (trc_to_bist_trim_default_loc) ,
                //.trc_to_bist_read_cycle             (trc_to_bist_read_cycle) ,
                .trc_to_bist_trim_global_set        (trc_to_bist_trim_global_set) ,
                .trc_to_bist_trim_global_set_loc    (trc_to_bist_trim_global_set_loc) ,
                .trc_to_bist_trim_global_reset      (trc_to_bist_trim_global_reset) ,
                .trc_to_bist_trim_global_reset_loc  (trc_to_bist_trim_global_reset_loc),
                .trc_to_bist_misr_data              (trc_to_bist_misr_data_reg_o),

        .ifr_index                          (ifr_index),
        .ifr_read_dis_test                       (ifr_read_dis_test),
        .ifr_write_dis_test                      (ifr_write_dis_test),
        .boot0_write_dis_test               (boot0_write_dis_test),
        .boot0_read_dis_test                (boot0_read_dis_test),
        .boot1_write_dis_test               (boot1_write_dis_test),
        .boot1_read_dis_test                (boot1_read_dis_test),
        .fw0_write_dis_test                 (fw0_write_dis_test),
        .fw0_read_dis_test                  (fw0_read_dis_test),
        .fw1_write_dis_test                 (fw1_write_dis_test),
        .fw1_read_dis_test                  (fw1_read_dis_test),
        .rrsub_size_test                    (rrsub_size_test)

       `ifdef  OPT_ECC_INPUT_OVERRIDE
                ,.ip_user_override_ecc_i  ( ip_user_override_ecc_i  )
                ,.ip_user_ecc_i           ( ip_user_ecc_i           )
                ,.ip_mux_override_ecc_o   ( ip_mux_override_ecc     )
                ,.ip_mux_ecc_o            ( ip_mux_ecc              )
       `endif

);

trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_top u_trc_top(


`ifdef TC
.numbank_is_2         ( numbank_is_2         ),//BANK2
.numbank_is_4         ( numbank_is_4         ),//BANK4
.numbank_is_6         ( numbank_is_6         ),//BANK6
.numbank_is_8         ( numbank_is_8         ),//BANK8
.numbankaddrx_is_1    ( numbankaddrx_is_1    ),//BANK2
.numbankaddrx_is_2    ( numbankaddrx_is_2    ),//BANK4
.numbankaddrx_is_3    ( numbankaddrx_is_3    ),//BANK6 and BANK8
.numwl_addrx_is_7     ( numwl_addrx_is_7     ),//WL128
.numwl_addrx_is_8     ( numwl_addrx_is_8     ),//WL256
.numwl_addrx_is_9     ( numwl_addrx_is_9     ),//WL512
.numwl_addrx_is_10    ( numwl_addrx_is_10    ),//WL1024
.numinfowl_addrx_is_3 ( numinfowl_addrx_is_3 ),//INFO8
.numinfowl_addrx_is_4 ( numinfowl_addrx_is_4 ),//INFO16
.numinfowl_addrx_is_5 ( numinfowl_addrx_is_5 ),//INFO32
.numinfowl_addrx_is_6 ( numinfowl_addrx_is_6 ),//INFO64
`endif

    // ---- system and reset ----
    .clk      (clk      ),
    .rst_n      (rst_n    ),
        //.inv_clk        (inv_clk  ),
`ifdef OPT_PIPELINE_READ
  `ifdef OPT_ASYNC_READ
        .async_clk      (async_clk)                    ,
        //.async_rst_n    (async_rst_n)                    ,
  `endif
`endif
          // ---- scan test ----
          .scan_test      ( scan_test    ),
          //.scan_en        ( scan_en      ),
          //.scan_rst_n     ( scan_rst_n   ),
    // ---- input from bist (user mode)----
    .trc_nap_i    (ip_mux_nap   ),
    .trc_pd_i   (ip_mux_pd    ),
    .trc_cmd_i    (ip_mux_cmd   ),
    .trc_info_i   (ip_mux_info    ),
        .trc_ifren1_i   (ip_mux_ifren1  ),
        .trc_reden_i    (ip_mux_reden),

    //.trc_lven_i   (1'b0   ),
    .trc_xadr_i   (ip_mux_xadr    ),
    .trc_yadr_i   (ip_mux_yadr    ),
    .trc_udin_i   (ip_mux_udin    ),
    .trc_tdin_i   (ip_mux_tdin    ),

    .trc_regif_wdata_i  (ip_mux_trc_data  ),
    // ---- output to bist ----
        .trc_udout_o    (trc_udout_o        ),
        .trc_tdout_o    (trc_tdout_o        ),
    .trc_regif_dout_o (ip_trc_regif_dout  ),
    .trc_busy_o   (ip_trc_busy    ),
    .trc_err_o    (ip_trc_err   ),
`ifdef OPT_IFR1_LOCK
        .trc_ifr1_lock_err_o (trc_ifr1_lock_err_o),
`endif
    // ---- rram macro interface ----
`ifdef TC
    .rram_xadr_o    (rram_xadr_o    ),
    .rram_yadr_o    (rram_yadr_o    ),
    .rram_full_din_o  (rram_full_din_o),
    .rram_set_o       (rram_set_o   ),
    .rram_reset_o   (rram_reset_o ),
    .rram_xe_o        (rram_xe_o    ),
    .rram_ye_o        (rram_ye_o    ),
    .rram_read_o        (rram_read_o  ),
    .rram_ae_o        (rram_ae_o    ),
    .rram_info_o    (rram_info_o  ),
    .rram_ifren1_o    (rram_ifren1_o  ),
        .rram_reden_o       (rram_reden_o   ),
    .rram_pch_ext_o   (rram_pch_ext_o ),
    .rram_nap_o       (rram_nap_o   ),
    //.rram_pd_o        (rram_pd    ),
    //.rram_rst_n_o   (rram_rst_n   ),
    //.rram_lven_o    (rram_lven    ),
    .rram_cfg_o       (rram_cfg_o   ),
    .rram_rst_o       (rram_rst_o   ),
        .rram_ce_o          (rram_ce_o      ),
    .rram_ck_ext_o    (rram_ck_ext_o  ),
    .rram_htol_en_o   (rram_htol_en_o ),
    .rram_recall_o    (rram_recall_o  ),
    .rram_rdone_i   (rram_rdone_i ),
    .rram_dout_i    (rram_dout_i  ),
`else
    .rram_xadr_o    (rram_xadr    ),
    .rram_yadr_o    (rram_yadr    ),
    .rram_full_din_o  (rram_full_din    ),
    .rram_set_o       (rram_set   ),
    .rram_reset_o   (rram_reset   ),
    .rram_xe_o        (rram_xe    ),
    .rram_ye_o        (rram_ye    ),
    .rram_read_o      (rram_read    ),
    .rram_ae_o        (rram_ae    ),
    .rram_info_o    (rram_info    ),
    .rram_ifren1_o    (rram_ifren1    ),
        .rram_reden_o       (rram_reden         ),
    //.rram_ck_ext_o    (rram_ck_ext    ),
    .rram_pch_ext_o   (rram_pch_ext   ),
    //.rram_htol_en_o   (rram_htol_en   ),
    .rram_nap_o   (rram_nap   ),
    //.rram_recall_o    (rram_recall    ),
    //.rram_pd_o          (rram_pd        ),
    //.rram_rst_n_o   (rram_rst_n       ),
    //.rram_lven_o    (rram_lven    ),
    .rram_cfg_o   (rram_cfg   ),
    .rram_rst_o   (rram_rst   ),
        .rram_ce_o      (rram_ce        ),
    .rram_rdone_i   (rram_rdone   ),
    .rram_dout_i    (ip_dout    ),
`endif


    //.rram_cr_en_l_i   (  rram_cr_en_l   ),
    //.rram_cr_en_r_i   (  rram_cr_en_r   ),
    //.rram_t_cr_l_0_i  (  rram_t_cr_l_0  ),
    //.rram_t_cr_r_0_i  (  rram_t_cr_r_0  ),
    //.rram_t_cr_l_1_i  (  rram_t_cr_l_1  ),
    //.rram_t_cr_r_1_i  (  rram_t_cr_r_1  ),

    // ---- input from bist ----
    //.bist_trc_reden_test_i(ip_mux_reden   ),
    //.bist_trc_info_test_i (ip_mux_info    ),
    //.bist_trc_ifren1_test_i (ip_mux_ifren1    ),
    //.bist_trc_lven_test_i (ip_mux_lven    ),
    // ---- output to bist ----
    .trc_bist_write_status_o  (ip_trc_write_status),

        //.bist_overwrite_cfg_enable  ( bist_overwrite_cfg_enable ),
        //.bist_overwrite_cfg         ( bist_overwrite_cfg        ),

        //.bist_overwrite_cfg_enable  (1'b0 ),
        //.bist_overwrite_cfg         ( 210'b0        ),

       // ---- trim verify ----
        .trc_to_bist_trim_default           (trc_to_bist_trim_default) ,
        .trc_to_bist_trim_default_loc       (trc_to_bist_trim_default_loc) ,
        .trc_to_bist_trim_global_set        (trc_to_bist_trim_global_set) ,
        .trc_to_bist_trim_global_set_loc    (trc_to_bist_trim_global_set_loc) ,
        .trc_to_bist_trim_global_reset      (trc_to_bist_trim_global_reset) ,
        .trc_to_bist_trim_global_reset_loc  (trc_to_bist_trim_global_reset_loc) ,

        //.trc_to_bist_read_cycle             (trc_to_bist_read_cycle),
        .trc_dout_ready_o                   (trc_dout_ready_o),
        .ecc_err_o                          (ecc_err_o)

        // ---- user abort ----
        //.user_write_abort ( ip_user_write_abort_i )

`ifdef OPT_ASYNC_READ
        ,.async_rst_n     ( async_rst_n      )
        ,.async_access_i  ( async_access_i   )
        ,.async_ifren_i   ( async_ifren_i    )
        ,.async_ifren1_i  ( async_ifren1_i   )
        ,.async_reden_i   ( async_reden_i    )
        ,.async_read_i    ( async_read_i     )
        ,.async_pch_ext_i ( async_pch_ext_i  )
        ,.async_xadr_i    ( async_xadr_i     )
        ,.async_yadr_i    ( async_yadr_i     )

        //,.async_rram_dout_o     ( async_rram_dout_o )
        ,.async_rram_rdone_o    ( async_rram_rdone_o )
`endif

        ,.trc_write_suspend_i   ( trc_write_suspend_i  )
        ,.trc_write_resume_i    ( trc_write_resume_i   )
        ,.trc_write_abort_i     ( trc_write_abort_i    )
        ,.trc_write_suspend_o   ( trc_write_suspend_o  )

`ifdef TRC_EXT_ECC
                // ---- external ECC I/F ----
                ,.to_encoder_message         ( to_encoder_message    )
                ,.to_encoder_mode            ( to_encoder_mode       )
                ,.to_decoder_codeword        ( to_decoder_codeword   )
                //,.to_decoder_en_delay        ( to_decoder_en_delay   )

                ,.from_encoder_codeword      ( from_encoder_codeword )
                ,.from_decoder_message       ( from_decoder_message  )
`endif



                // ---- tv used only ----
`ifdef TC
                ,.trc_no_init_in_dma_mode    ( trc_no_init_in_dma_mode )
                //,.trc_recall_cy_tv_only      (      )
`endif

`ifdef TRC_WRITE_MON
                ,.to_dio_trc_xe              ( to_dio_trc_xe                   )
                ,.to_dio_trc_set             ( to_dio_trc_set                  )
                ,.to_dio_trc_reset           ( to_dio_trc_reset                )
                ,.to_dio_trc_accum_bit_count ( to_dio_trc_accum_bit_count      )
                ,.to_dio_trc_shot_number     ( to_dio_trc_shot_number          )
                ,.to_dio_trc_xadr            ( to_dio_trc_xadr                 )
                ,.to_dio_trc_yadr            ( to_dio_trc_yadr                 )
`endif

`ifdef TRC_WRITE_STATUS
    // ---- monitored FBC
  `ifdef TRC_WRITE_STATUS_4TH_READ_ONLY
    ,.trc_fourth_read_failure_status    (trc_fourth_read_failure_status)
  `else
    ,.trc_set_failure_status            (trc_set_failure_status)
    ,.trc_reset_failure_status          (trc_reset_failure_status)
    ,.trc_fourth_read_failure_status    (trc_fourth_read_failure_status)
  `endif //TRC_WRITE_STATUS_4TH_READ_ONLY
`endif //TRC_WRITE_STATUS

                ,.sw_r_cfg_status                ( sw_r_cfg_status )

                ,.misr_data_reg_o                (trc_to_bist_misr_data_reg_o)

`ifdef  OPT_ECC_INPUT_OVERRIDE
    ,.trc_override_ecc_i   ( ip_mux_override_ecc     )
    ,.trc_ecc_i            ( ip_mux_ecc              )
`endif

`ifdef OPT_CODEWORD_EXPOSE
                ,.to_decoder_codeword        ( to_decoder_codeword   )
`endif

`ifdef OPT_CFG_OVERRIDE
    ,.override_cfg_enable (ip_user_override_cfg_enable_i)
    ,.override_cfg        (ip_user_override_cfg_i)
`endif

);


`ifdef TC
`else

    assign rri.XADR         = rram_xadr                                     ;
    assign rri.YADR         = rram_yadr                                     ;
    assign rri.DIN          = rram_full_din[numIO-1:0]                      ;
    assign rri.CFG_MACRO    = rram_cfg                                      ;
    assign rri.SET          = rram_set                                      ;
    assign rri.RESET        = rram_reset                                    ;
    assign rri.RST          = rram_rst                                      ;
    assign rri.NAP          = rram_nap                                      ;
    assign rri.REDEN        = rram_reden                                    ;
    assign rri.IFREN1       = rram_ifren1                                   ;
    assign rri.IFREN        = rram_info                                     ;
    assign rri.XE           = rram_xe                                       ;
    assign rri.YE           = rram_ye                                       ;
    assign rri.READ         = rram_read                                     ;
    assign rri.PCH_EXT      = rram_pch_ext                                  ;
    assign rri.AE           = rram_ae                                       ;
    assign rri.CE           = rram_ce                                       ;
//  assign rri.POC_IO       = POC_IO                                        ;
    assign rri.DIN_CR       = rram_full_din[numData-1:numData-1-(numCR-1)]  ;

    assign rram_rdone  = rro.RDONE     ;
    assign ip_dout_ori = rro.DOUT      ;
    assign dout_cr     = rro.DOUT_CR   ;

assign ip_dout = {dout_cr, ip_dout_ori};
`endif //`ifdef TC

endmodule

`default_nettype wire
