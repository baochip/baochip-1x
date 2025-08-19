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

`include "template.sv"
import trc_pkg::*;

module rrc #(
    parameter BRC  = 32,                        // add more ifr
    parameter BRCW = $clog2(BRC),
    parameter BRDW = 256
)(

    //  system
    //  ==============================

    input wire              clk,                // axi clk, 400MHz
    input wire              clktop,             // 800MHz
    input wire              clksys,             // 32MHz for draft sim
    input wire              clken,
    input wire              hclk,               // ahb clk 200MHz
    input wire              clkocc,
    input wire              sysresetn,
    input wire              coreresetn,
    input wire              rramsleep,          // rram sleep enter and exit
    output wire             rrcint,
    input wire  [15:0]      evin,               // event input for one-way counter trigger
    output wire             rrcnmi,             // ouptut to evc for nmi trigger

    input wire              cm7cfg_en,          // cm7 core enabled signal
    input nvrcfg_pkg::nvrcfg_t nvrcfgdata,      // reram size configuration from nvrcfg

    //  security control
    //  ==============================

    input wire  [255:0]     trustkey,           // modify from 16 to 256
    input wire  [7:0]       sceuser,
    input wire  [7:0]       coreuser_cm7,
    input wire  [7:0]       coreuser_vex,
    input wire              mode_sec,           // addd for sce security mode flag
    input wire              vex_mm,

    //  amba bus
    //  ==============================

    axiif.slave             axis,               // 64
    ahbif.slavein           ahbs,               // 32 **apb =32 reigsters.
    ahbif.slave             ahbx,               // 32 **apb =32 reigsters.

    //  bist read
    //  ==============================

    input  wire [3:0]       brready,
    output wire             brvld,
    output reg  [BRCW-1:0]  bridx,
    output wire [BRDW-1:0]  brdat,
    output reg              brdone,

    //  rram macro
    //  ==============================

    output rrc_pkg::rri_t [1:0] rri,
    input  rrc_pkg::rro_t [1:0] rro,

    //  test control
    //  ==============================

    input cms_pkg::cmscode_e    cmscode,
    input cmsatpg, cmsbist,
    rbif.slave                  rbs,
    jtagif.slave                jtag[0:1]

);


  //  bist initial read
  //  ==============================

  // bist-stage
  // 0  trc_cmd = auto RECALL
  // 1  trc_cmd = READ      virgin state, or pattern (1*256-bit pattern)     mode selection ready (virgin, test, user)
  // 1  trc_cmd = READ      for system analog   (3*256-bit)
  // 2  trc_cmd = READ      system control  (4*256-bit)
  // 3  trc_cmd = READ      access control ram  (128*256-bit)



    bit bist_enable, rramclk0, rramclk1;
    bit scan_test;
    bit rramclk_org, rramclk_tck0, rramclk_tck1;

    bit [3:0] brfsm;
    bit counten_brfsm;
    bit recallvld;
    bit trc_err;
    bit trc_info_lock_err;
    bit [145:0] trc_dout_s0;
    bit [145:0] trc_dout_s1;
    bit [4:0] fd0;
    bit [BRCW:0]  bridx_org;
    bit [8:0] bridx_acv;
    bit [BRC-1:0][BRDW-1:0] brdatreg;
    bit bridx_org_vld,bridx_acv_vld;
    bit acram_wrbusy, acram_wrbusy_reg, acram_wrdone;
    bit [3:0] brfsm_reg;
    bit brfsm_read,acram_wrdone_reg;
    bit trc_busy,trc_busy_sreg;
    bit trc_dout_ready,trc_dout_ready_sreg;
    bit trc_busy_sdone, trc_dout_ready_sdone;
    bit trc_busy_sdone_reg, trc_dout_ready_sdone_reg;

    `theregfull(clksys, sysresetn, trc_busy_sreg, '0) <= ( brfsm == 'h5 ) ? 'b0 : trc_busy;
    `theregfull(clksys, sysresetn, trc_dout_ready_sreg, '0) <= ( brfsm == 'h5 ) ? 'b0 : trc_dout_ready;
    `theregfull(clksys, sysresetn, trc_busy_sdone_reg, '0) <= trc_busy_sdone;
    `theregfull(clksys, sysresetn, trc_dout_ready_sdone_reg, '0) <= trc_dout_ready_sdone;

    assign trc_busy_sdone = !trc_busy & trc_busy_sreg;
    assign trc_dout_ready_sdone = trc_dout_ready & !trc_dout_ready_sreg;

    `theregfull(clksys, sysresetn, acram_wrdone_reg, '1) <= acram_wrdone;

    `theregfull(clksys, sysresetn, bridx_org, '0) <= bridx_org_vld & trc_dout_ready_sdone ? bridx_org + 1 : bridx_org;
    `theregfull(clksys, sysresetn, bridx_acv, '0) <= bridx_acv_vld & acram_wrdone ? bridx_acv + 1 : bridx_acv;

    `theregfull(clksys, sysresetn, brfsm, '0) <=
            ( brfsm == 0 ) & ( bridx_org == '0 ) & trc_busy_sdone ?  1 :                                // rram recall auto start
            ( brfsm == 1 ) & ( bridx_org == '0 ) & trc_dout_ready_sdone & !brready[0] ? 7 :             // wait
            ( brfsm == 7 ) & ( bridx_org == 'd1 ) & brready[0] ? 2 :                                    // cms pattern
            ( brfsm == 2 ) & ( bridx_org == 'd3 ) & trc_dout_ready_sdone & !brready[1] ? 7 :            // wait
            ( brfsm == 7 ) & ( bridx_org == 'd4 ) & brready[1] ? 3 :                                    // ip trimming
            ( brfsm == 3 ) & ( bridx_org == BRC-1 ) & trc_dout_ready_sdone & brready[2] ? 4 :           // system cfg
            ( brfsm == 4 ) & ( bridx_acv == 'd511 ) & acram_wrdone ? 5 :                                // acv
                                                                    brfsm;

    `theregfull(clksys, sysresetn, brdone, '0 ) <= brdone | ( brfsm == 'h5 );
    `theregfull(clksys, sysresetn, brfsm_reg, '0) <= brfsm;

    assign bridx_org_vld = (( brfsm == 1 ) & ( bridx_org == 'd0 )) |
                            (( brfsm == 2 ) & ( bridx_org <= 'd3 )) |
                                (( brfsm == 3 ) & ( bridx_org <= BRC-1 ));

    assign bridx_acv_vld = ( brfsm == 4 ) & ( bridx_acv <= 'd511 );

    assign brvld = trc_dout_ready_sdone_reg & (brfsm != 'h5);
    `theregfull(clksys, sysresetn, brdatreg[bridx_org], '0) <= trc_dout_ready_sdone ? {trc_dout_s1[127:0],trc_dout_s0[127:0]} : brdatreg[bridx_org];
    assign brdat = brdatreg[bridx];
    assign bridx = bridx_org-1;

    bit [3:0]   brfsm_cmd;
    bit         brfsm_info;
    bit [11:0]  brfsm_xadr;
    bit [4:0]   brfsm_yadr;
    bit [3:0]   brfsm_udin;
    bit         brfsm_desel,brfsm_acv_desel;

    assign brfsm_desel = (brfsm == 0) | (brfsm == 5) | (brfsm == 7);
    assign brfsm_acv_desel = (brfsm == 4);
    assign brfsm_read = (brfsm_reg == 0) & (brfsm == 1) |
                            (brfsm_reg == 7) & (brfsm == 2) |
                            (brfsm_reg == 7) & (brfsm == 3) |
                            (brfsm_reg == 3) & (brfsm == 4) |
                            (bridx_org > 0 ) & (brfsm != 7) & (brfsm[2] != 1) & trc_dout_ready_sdone_reg |
                            bridx_acv_vld & acram_wrdone_reg;

    assign brfsm_cmd = brfsm_read ? TRC_READ : TRC_IDLE;
    assign brfsm_udin = 'h0;                                                // din[3:0]=4'b0101, recall all CFG settings
    assign brfsm_info = brfsm_desel | brfsm_acv_desel ? 1'b0 : 1'b1;
    assign brfsm_xadr = brfsm_desel ? 'h0 :
                            brfsm_acv_desel ? {8'b11_1101_11,bridx_acv[8:5]} : 'h0;
    assign brfsm_yadr = brfsm_desel ? 'h0 :
                            brfsm_acv_desel ? bridx_acv[4:0] : bridx_org[4:0];


  //  OEM mode of test data path control
  //  =====================================
  //  use reram S1 output as the access control logic
  //  {reram_s1_data, reram_s0_data}

    localparam  PM_READ_DIS = 8'h96;
    localparam  PM_WRITE_DIS = 8'h3a;
    bit [4:0]   ifr_index_s0, ifr_index_s1;
    bit         ifr_write_dis_test_s0, ifr_write_dis_test_s1;
    bit         ifr_read_dis_test_s0, ifr_read_dis_test_s1;
    bit         boot0_read_dis_test, boot1_read_dis_test, fw0_read_dis_test, fw1_read_dis_test;
    bit         boot0_write_dis_test, boot1_write_dis_test, fw0_write_dis_test, fw1_write_dis_test;
    bit [39:0]  rrsub_size_test;

    assign ifr_write_dis_test_s0 = (brdatreg[ifr_index_s0][255:248] == PM_WRITE_DIS);
    assign ifr_read_dis_test_s0 = (brdatreg[ifr_index_s0][247:240] == PM_READ_DIS);

    assign ifr_write_dis_test_s1 = (brdatreg[ifr_index_s1][255:248] == PM_WRITE_DIS);
    assign ifr_read_dis_test_s1 = (brdatreg[ifr_index_s1][247:240] == PM_READ_DIS);

    assign boot0_write_dis_test = (brdatreg[20][127:120] == PM_WRITE_DIS);
    assign boot0_read_dis_test = (brdatreg[20][119:112] == PM_READ_DIS);

    assign boot1_write_dis_test = (brdatreg[21][127:120] == PM_WRITE_DIS);
    assign boot1_read_dis_test = (brdatreg[21][119:112] == PM_READ_DIS);

    assign fw0_write_dis_test = (brdatreg[22][127:120] == PM_WRITE_DIS);
    assign fw0_read_dis_test = (brdatreg[22][119:112] == PM_READ_DIS);

    assign fw1_write_dis_test = (brdatreg[23][127:120] == PM_WRITE_DIS);
    assign fw1_read_dis_test = (brdatreg[23][119:112] == PM_READ_DIS);

    assign rrsub_size_test = cm7cfg_en ? {nvrcfgdata.cfgrrsub.m7_boot0_start,
                                            nvrcfgdata.cfgrrsub.m7_boot1_start,
                                            nvrcfgdata.cfgrrsub.m7_fw0_start,
                                            nvrcfgdata.cfgrrsub.m7_fw1_start, nvrcfgdata.cfgrrsub.m7_fw1_end} :
                                         {nvrcfgdata.cfgrrsub.rv_boot0_start,
                                            nvrcfgdata.cfgrrsub.rv_boot1_start,
                                            nvrcfgdata.cfgrrsub.rv_fw0_start,
                                            nvrcfgdata.cfgrrsub.rv_fw1_start,
                                            nvrcfgdata.cfgrrsub.rv_fw1_end} ;   // if CM7 is enabled, then use CM7 mapping as test mode mapping.

  //  cfg_rrsub_rw_* decoder
  //  =====================================

    bit [7:0] user_code_cfg_boot0, user_code_cfg_boot1, user_code_cfg_fw0, user_code_cfg_fw1;

    assign user_code_cfg_boot0 = brdatreg[20][111:104];
    assign user_code_cfg_boot1 = brdatreg[21][111:104];
    assign user_code_cfg_fw0   = brdatreg[22][111:104];
    assign user_code_cfg_fw1   = brdatreg[23][111:104];

  //  ahb-rram sfr and interrupt
  //  ==============================

//  `ahbs_common
    assign ahbx.hready = 'b1;
    assign ahbx.hresp = 'h0;
    assign ahbx.hrdata = '0
                | sfr_rrccr.hrdata32
                | sfr_rrcfd.hrdata32
                | sfr_rrcsr.hrdata32
		        | sfr_rrcfr.hrdata32
                | sfr_rrcsr_set0.hrdata32
                | sfr_rrcsr_set1.hrdata32
                | sfr_rrcsr_rst0.hrdata32
                | sfr_rrcsr_rst1.hrdata32
                | sfr_rrcsr_rd0.hrdata32
                | sfr_rrcsr_rd1.hrdata32;


    localparam PM_RRAM_SUICIDE = 16'h2468;
    bit trc_write_suspend_s0, trc_write_suspend_s1, trc_write_suspend;
    bit [2:0] ecc_err_s0, ecc_err_s1, ecc_err;
    bit [63:0]  trc_set_failure_s0, trc_set_failure_s1, trc_set_failure;
    bit [63:0]  trc_reset_failure_s0, trc_reset_failure_s1, trc_reset_failure;
    bit [63:0]  trc_fourth_read_failure_s0, trc_fourth_read_failure_s1, trc_fourth_read_failure;
    bit code_access_error_athclk, info_access_error_athclk, data_access_error_athclk, key_access_error_athclk, cfg_access_error_athclk;
    bit [31:0] rrccr;
    bit [4:0] rrcfr;
    bit [4:0] rrcfd;
    bit [9:0] rrcsr;
    bit ip_user_nap_i;
    bit ip_user_pd_i;
    bit [3:0] ip_user_cmd_i;
    bit [63:0] trc_regif_dout_s0;
    bit [63:0] trc_regif_dout_s1;
    bit rrcar_suicide;

    ahb_cr #(.A('h00), .DW(32))                 sfr_rrccr       (.cr(rrccr), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);
    ahb_cr #(.A('h04), .DW(5), .IV('h7))        sfr_rrcfd       (.cr(rrcfd), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);
    ahb_sr #(.A('h08), .DW(10))                 sfr_rrcsr       (.sr(rrcsr), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);
    ahb_fr #(.A('h0C), .DW(5))                  sfr_rrcfr       (.fr(rrcfr), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);

    ahb_sr #(.A('h14), .DW(32))                 sfr_rrcsr_set0  (.sr(trc_set_failure[31:0]), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);
    ahb_sr #(.A('h18), .DW(32))                 sfr_rrcsr_set1  (.sr(trc_set_failure[63:32]), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);
    ahb_sr #(.A('h1C), .DW(32))                 sfr_rrcsr_rst0  (.sr(trc_reset_failure[31:0]), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);
    ahb_sr #(.A('h20), .DW(32))                 sfr_rrcsr_rst1  (.sr(trc_reset_failure[63:32]), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);
    ahb_sr #(.A('h24), .DW(32))                 sfr_rrcsr_rd0   (.sr(trc_fourth_read_failure[31:0]), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);
    ahb_sr #(.A('h28), .DW(32))                 sfr_rrcsr_rd1   (.sr(trc_fourth_read_failure[63:32]), .hrdata32(), .resetn(coreresetn), .sfrlock(1'b0), .*);

    ahb_ar #(.A('hF0), .AR(PM_RRAM_SUICIDE))    sfr_rrcar       (.ar(rrcar_suicide), .resetn(coreresetn), .sfrlock(1'b0), .*);

    assign fd0 = rrcfd[4:0];
    assign rrcsr[9:0] = {ecc_err, trc_err, trc_info_lock_err, ip_user_cmd_i, trc_busy};
    assign rrcfr = {info_access_error_athclk, cfg_access_error_athclk, code_access_error_athclk, data_access_error_athclk, key_access_error_athclk};
    assign rrcint = |rrcfr;
    assign rrcnmi = rrcint & rrccr[15];

  //  suicide flow control
  //  ==============================

    bit [2:0] rrcfsm;
    bit rramclken;
    bit trc_busy_done, trc_dout_ready_done;
    bit [21:0]  suicide_adr_main;
    bit [12:0]  suicide_adr_ifr;
    bit suicide_start, suicide_load, suicide_write, suicide_reg, suicide_info;
    bit [4:0]   suicide_yadr;
    bit [11:0]  suicide_xadr;
    bit trc_busyreg1;

    `theregfull(clktop, sysresetn, suicide_start, '0) <= ((cmscode == CMS_SCDE) | rrcar_suicide) & (!suicide_reg) & (!suicide_start) & (suicide_adr_main == 'h0) ? 1'b1 :
                                                            suicide_start ? 1'b0 : suicide_start;

    `theregfull(clktop, sysresetn, suicide_reg, '0) <= suicide_reg & suicide_load & (suicide_adr_ifr == 13'h1F) & (suicide_adr_main == 'h1F) ? 1'b0 :
                                                            suicide_start ? 1'b1 : suicide_reg;

    `theregfull(clktop, sysresetn, suicide_info, '0) <= suicide_info & suicide_load & (suicide_adr_ifr == 13'h1F) ? 1'b0 :
                                                            !suicide_info & suicide_reg & suicide_load & (suicide_adr_main == 'h1F) ? 1'b1 : suicide_info;

    `theregfull(clktop, sysresetn, suicide_adr_main, '0) <= suicide_start ? {6'h3F,16'hFFFF} :
                                                            suicide_reg & suicide_load & (suicide_adr_main != 22'h1F) ? (suicide_adr_main - 22'h20) : suicide_adr_main;

    `theregfull(clktop, sysresetn, suicide_adr_ifr, '0) <= suicide_reg & suicide_load & (suicide_adr_main == 22'h1F) & (suicide_adr_ifr == 13'h0) ? 13'h1FFF :
                                                            suicide_reg & suicide_load & (suicide_adr_main == 22'h1F) & (suicide_adr_ifr != 13'h1F) ? (suicide_adr_ifr - 13'h20) : suicide_adr_ifr;

    assign suicide_load = suicide_start | ( rrcfsm == 4 ) & !trc_busy & trc_busyreg1 & suicide_reg;
    assign suicide_write = suicide_reg & ( rrcfsm == 3 ) & rramclken;

    assign suicide_xadr = (suicide_adr_main[21:10] | {9'h0, suicide_adr_ifr[12:10]});
    assign suicide_yadr = (suicide_adr_main[9:5] | suicide_adr_ifr[9:5]);


  //  secure access sram instantiate
  //  ==============================
  //  bist read initial key/data
  //  write rrc cr bit

    bit [31:0] haddr_reg;
    bit [2:0] hsize_reg;
    bit ahb_write_flag, ahb_read_flag;
    bit keysel, datasel;
    bit [BRDW-1:0] ahb_rd_buf;
    bit [BRDW-1:0] ahb_wr_buf;
    bit [31:0] hwaddr_reg;
    bit rram_load_run, rram_write_run;
    bit acram_cs;
    bit acram_wr;
    bit acram_clk;
    bit [10:0] acram_addr;
    bit [63:0] acram_rdata;
    bit [63:0] acram_wdata;
    bit [255:0] acram_wrbuf;
    bit [1:0] acram_idx;
    bit rramcfg_vld, acram_rdbusy;
    bit acram_rdbusy_pre, acram_wrbusy_pre, acram_clk_en;
    bit keysel_ahb, datasel_ahb, ahb_read_acram;
    bit ahb_array_trans;

    localparam PM_KEY_REGION = 16'h603F;
    localparam PM_DATA_REGION = 16'h603E;

    assign rramcfg_vld = (hwaddr_reg[31:14] == {16'h603D, 2'b11});

    `theregfull(clktop, sysresetn, acram_wrbuf, '0) <= trc_dout_ready_sdone & ( brfsm == 4 ) ? {trc_dout_s1[127:0],trc_dout_s0[127:0]} :        //initial from bistread
                                                        rram_write_run & rramcfg_vld ? ahb_wr_buf : acram_wrbuf;                                //ahb write configuration rram-acram region

    `theregfull(clktop, sysresetn, acram_wrbusy, '0) <= acram_wrbusy_pre;
    assign acram_wrbusy_pre = ( acram_idx == 2'b11 ) ? 1'b0 :
                                                            trc_dout_ready_sdone & ( brfsm == 4 ) | (rram_write_run & rramcfg_vld) ? 1'b1 : acram_wrbusy;

    `theregfull(clktop, sysresetn, acram_rdbusy, '0) <= acram_rdbusy_pre;
    assign acram_rdbusy_pre = ahb_read_acram ? 1'b1 :
                                ahbarray.hready ? 1'b0 : acram_rdbusy;

    assign ahb_read_acram = ahb_array_trans & ahbarray.hsel & !ahbarray.hwrite & (keysel_ahb | datasel_ahb);
    assign keysel_ahb = ( ahbarray.haddr[31:16] == PM_KEY_REGION );
    assign datasel_ahb = ( ahbarray.haddr[31:16] == PM_DATA_REGION );

    `theregfull(clktop, sysresetn, acram_wrbusy_reg, '0) <= acram_wrbusy;
    assign acram_wrdone = acram_wrbusy_reg & !acram_wrbusy;

    `theregfull(clktop, sysresetn, acram_idx, '0) <= acram_wrbusy ? acram_idx + 1 : acram_idx;

    always@(*)
    casex(acram_idx)
        2'h1: acram_wdata = acram_wrbuf[127 : 64];
        2'h2: acram_wdata = acram_wrbuf[191 : 128];
        2'h3: acram_wdata = acram_wrbuf[255 : 192];
        default: acram_wdata = acram_wrbuf[63:0];
    endcase

    assign acram_cs = (!acram_wrbusy) & (!acram_rdbusy_pre);                    //low active
    assign acram_wr = !acram_wrbusy;
    assign acram_addr = ( brfsm == 4 ) ? {bridx_acv,acram_idx} :
                            acram_wrbusy ? {haddr_reg[13:5],acram_idx} :        //write acram, when bist read initial and amba write configure to rram.
                            ahb_read_acram ? ahbarray.haddr[16:6] :
                            acram_rdbusy ? haddr_reg[16:6] : 11'h0;             //read acram, when axi access data/key region, look-up-table for access control.
    assign acram_clk_en = acram_wrbusy | acram_rdbusy_pre;                      //fix write clock generation

    ICG acramicg ( .CK (clktop),      .EN (acram_clk_en), .SE(cmsatpg), .CKG (acram_clk));

    logic rb_clkb, rb_bcen, rb_bgwen;
    logic [10:0] rb_ba;
    logic [63:0] rb_bq, rb_bwen, rb_bd;

    rbspmux #(.AW(11),.DW(64))rbmux(
         .cmsatpg,
         .cmsbist,
         .rbs         (rbs),
         .q(acram_rdata),
         .clk(acram_clk),
         .cen(acram_cs),
         .gwen(acram_wr),
         .a(acram_addr),
         .d(acram_wdata),
         .wen         ('1),
         .rb_clk      (rb_clkb),
         .rb_q        (rb_bq),
         .rb_cen      (rb_bcen),
         .rb_gwen     (rb_bgwen),
         .rb_wen      (rb_bwen),
         .rb_a        (rb_ba),
         .rb_d        (rb_bd)
       );

    acram2kx64 acram (
         .q(rb_bq),
         .clk(rb_clkb),
         .cen(rb_bcen),
         .gwen(rb_bgwen),
         .a(rb_ba),
         .d(rb_bd),
        `sram_sp_uhde_inst_acram
         );

  //  axi-ahb-rram read/write buffer
  //  ==============================

    bit [8:0] axid_reg;
    bit [2:0] axprot_reg;
    bit [31:0] datacfg;
    bit [31:0] keycfg;
    bit cm7sel, vexsel, scesel, codesel;
    bit [7:0] coreuser_mux;
    bit [7:0] coreuser_in, userid_k, userid_d;
    bit [7:0] keytype_in, keytype_k, keytype_d;
    bit pri_op, sec_op, inst_op, data_op;
    bit cmd_user_write_dis, cmd_user_read_dis;
//  bit user_access_control_error;

    bit core_rd_dis_k, core_wr_dis_k, sce_wr_dis_k, sce_rd_dis_k;
    bit [7:0] akeyid;
    bit core_rd_dis_d, core_wr_dis_d, sce_wr_dis_d, sce_rd_dis_d;
    bit key_access_error, data_access_error,info_access_error, code_access_error, code_access_error_inst, code_access_error_data;
    bit key_access_error_pre, data_access_error_pre,info_access_error_pre, code_access_error_pre, cfg_access_error_pre;

    ahbif #(.AW(32),.DW(64),.IDW(),.UW()) ahbarray();

    axi_ahb_bdg #(.AW(32), .DW(64)) u_rrcbdg (
        .clk            ( clk                   ),
        .resetn         ( coreresetn            ),
        .axislave       ( axis                  ),
        .ahbmaster      ( ahbarray              )
    );


    localparam PM_RRAM_LOAD = 16'h5200;
    localparam PM_RRAM_WRITE = 16'h9528;

    bit ahb_array_read;
    bit ahb_array_write;
    bit haddr_match;
    bit rrcvld;

    bit [3:0] hauser_reg;
    bit [4:0] rramclkcnt;

    bit trc_busy_reg;
    bit trc_dout_ready_s1, trc_dout_ready_s0, trc_dout_ready_reg;
    bit trc_dout_ready_done_reg, ahb_array_write_reg;
    bit oneway_counter_update_ahb, oneway_counter_update_ev, oneway_counter_update, oneway_counter_write_reg;
    bit prog_only_data_write, prog_only_data_write_reg, wrmode_d;
    bit two_cycle_read, two_cycle_load, two_cycle_write;
    bit [8:0]  oneway_counter_adr_ev;

    `theregfull(clktop, sysresetn, trc_busy_reg, '1) <= clken ? trc_busy : trc_busy_reg; // faye

//#eco12
    logic trc_dout_ready_eco_undft,trc_dout_ready_eco; //#eco12
    `theregfull(clktop, sysresetn, trc_dout_ready_eco_undft, '1) <= clken ? trc_dout_ready : trc_dout_ready_eco_undft;
    `theregfull(clktop, sysresetn, trc_dout_ready_reg, '1) <= clken ? trc_dout_ready_eco : trc_dout_ready_reg;
    assign trc_dout_ready_eco = cmsatpg | trc_dout_ready_eco_undft;
    assign trc_dout_ready_done = trc_dout_ready_eco & !trc_dout_ready_reg & clken;


    assign trc_busy_done = !trc_busy & trc_busy_reg;

    assign oneway_counter_update_ahb = ahb_array_trans & ahbarray.hwrite & ahbarray.hsel
                                        & (ahbarray.haddr[23:16] == 8'h3D) & (ahbarray.haddr[15:13] == 3'b101);    // 3D_Axxx | 3D_Bxxx One-way counter region

	genvar j;
    bit [15:0] evin_reg;
    bit [15:0] evin_trigger;

	generate
    	for (j = 0; j < 16; j++) begin:g1

    		`theregfull(clktop, coreresetn, evin_reg[j],   '0) <=  oneway_counter_write_reg &  ( rrcfsm == 0 ) ? 1'b0 :
                                                                        evin[j] ? 1'b1 : evin_reg[j];
    		`theregfull(clktop, coreresetn, evin_trigger[j],  '0) <= evin_trigger[j] ? 1'b0 :
                                                                        ahbarray.hready & clken & (!(ahbarray.htrans[1] & ahbarray.hsel)) ? evin_reg[j] : evin_trigger[j];
    	end
	endgenerate

    assign oneway_counter_update_ev = |(evin_trigger[15:0] & rrccr[31:16]);
    assign oneway_counter_update = oneway_counter_update_ev | oneway_counter_update_ahb;

    `theregfull(clktop, coreresetn, oneway_counter_write_reg, '0) <= oneway_counter_update ? 1'b1 :
                                                                        ( rrcfsm == 0 ) ? 1'b0 : oneway_counter_write_reg;

    assign oneway_counter_adr_ev = evin_reg[15] ? 9'h1E0 :
                                        evin_reg[14] ? 9'h1C0 :
                                        evin_reg[13] ? 9'h1A0 :
                                        evin_reg[12] ? 9'h180 :
                                        evin_reg[11] ? 9'h160 :
                                        evin_reg[10] ? 9'h140 :
                                        evin_reg[09] ? 9'h120 :
                                        evin_reg[08] ? 9'h100 :
                                        evin_reg[07] ? 9'h0E0 :
                                        evin_reg[06] ? 9'h0C0 :
                                        evin_reg[05] ? 9'h0A0 :
                                        evin_reg[04] ? 9'h080 :
                                        evin_reg[03] ? 9'h060 :
                                        evin_reg[02] ? 9'h040 :
                                        evin_reg[01] ? 9'h020 : 9'h000;

    assign prog_only_data_write = ahb_array_trans & ahbarray.hwrite & ahbarray.hsel & (ahbarray.haddr[23:16] == 8'h3E) & wrmode_d & rrccr[1]; // 3E_xxxx Data Slots Region

    assign ahb_array_trans = clken & ahbarray.htrans[1] & brdone & ahbarray.hready;
    assign ahb_array_read  = ahb_array_trans & !ahbarray.hwrite & !haddr_match & ahbarray.hsel;
    assign ahb_array_write = ahb_array_trans & ahbarray.hwrite & ahbarray.hsel & (!oneway_counter_update_ahb) & (!prog_only_data_write);

    `theregfull(clktop, coreresetn, haddr_reg, '0) <= ahb_array_trans & ahbarray.hsel ? ahbarray.haddr :
                                                            oneway_counter_update_ev ? {20'h603D_B, 3'b111, oneway_counter_adr_ev} : haddr_reg;
    `theregfull(clktop, coreresetn, hsize_reg, '0) <= ahb_array_trans & ahbarray.hsel ? ahbarray.hsize : hsize_reg;
    `theregfull(clktop, coreresetn, hwaddr_reg, '0) <= ahb_array_trans & ahbarray.hsel & ahbarray.hwrite ? ahbarray.haddr : hwaddr_reg;
    `theregfull(clktop, coreresetn, hauser_reg, '0) <= ahb_array_trans & ahbarray.hsel ? ahbarray.hauser : hauser_reg;
    `theregfull(clktop, coreresetn, ahb_write_flag, '0) <= ahb_array_trans ? ahbarray.hsel & ahbarray.hwrite & (!oneway_counter_update_ahb) : ahb_write_flag;
    `theregfull(clktop, coreresetn, ahb_read_flag, '0) <= ahb_array_trans ? ahbarray.hsel & !ahbarray.hwrite : ahb_read_flag;
    `theregfull(clktop, coreresetn, ahb_array_write_reg, '0) <= ahb_array_write;
    `theregfull(clktop, coreresetn, prog_only_data_write_reg, '0) <= ahb_array_trans ? prog_only_data_write : prog_only_data_write_reg;

    assign haddr_match = ( ahbarray.haddr[31:5] == haddr_reg[31:5] ) & ( ahbarray.haddr[31:5] != hwaddr_reg[31:5] );        // to fix immediate read after write

    always@(*)
    casex(haddr_reg[4:3])
        2'h1: ahbarray.hrdata = cmd_user_read_dis ? 64'h0 : ahb_rd_buf[127 : 64];
        2'h2: ahbarray.hrdata = cmd_user_read_dis ? 64'h0 : ahb_rd_buf[191 : 128];
        2'h3: ahbarray.hrdata = cmd_user_read_dis ? 64'h0 : ahb_rd_buf[255 : 192];
        default: ahbarray.hrdata = cmd_user_read_dis ? 64'h0 : ahb_rd_buf[63:0];
    endcase

    `theregfull(clktop, coreresetn, ahb_rd_buf, '0) <= trc_dout_ready_done ? {trc_dout_s1[127:0],trc_dout_s0[127:0]} : ahb_rd_buf;

	genvar i;
	generate
    	for (i = 0; i < 8; i++) begin:g0
    		bit [31:0] ahb_wr_buf32;
    		assign ahb_wr_buf[i*32+31:i*32] = ahb_wr_buf32;
    		`theregfull(clktop, coreresetn, ahb_wr_buf32,   '0) <=
                	ahb_array_write_reg & !rrccr[1] & ((hwaddr_reg[4:2] == i) & (hsize_reg == 'h2) |
                  (hwaddr_reg[4:3] == i/2) & (hsize_reg == 'h3)) ? (i[0] ? ahbarray.hwdata[63:32] : ahbarray.hwdata[31:0]) :
                                                                                                ahb_wr_buf32;
    	end
	endgenerate

    assign two_cycle_read = ( rrcfsm == 0 ) & (oneway_counter_update | prog_only_data_write);
    assign two_cycle_load = ( rrcfsm == 1 ) & trc_dout_ready_done & (oneway_counter_write_reg | (prog_only_data_write_reg & (!cmd_user_write_dis)));
    assign two_cycle_write = ( rrcfsm == 3 ) & rramclken & (oneway_counter_write_reg | (prog_only_data_write_reg & (!cmd_user_write_dis)));

    assign rram_load_run = ahb_array_write_reg & rrccr[1] & (ahbarray.hwdata == PM_RRAM_LOAD);
    assign rram_write_run = ahb_array_write_reg & rrccr[1] & (ahbarray.hwdata == PM_RRAM_WRITE);

    assign ahbarray.hready = ( rrcfsm == 0 ) & (!suicide_reg);
    assign ahbarray.hresp = 2'h0;
    assign ahbarray.hruser = hauser_reg;        // no need for sce special respond, deleted.

  //  cfg_rrsub_size decoder
  //  =====================================
  //  amba address[31:0] = {10’b0110_0000_00, IP0[x+7: x], 14’h0}
  //  unit block size: 16KB
  //  IP0[127:120]:     reram start
  //  IP0[15:0]:        Reserved

    bit boot0sel_cm7, boot1sel_cm7, fw0sel_cm7, fw1sel_cm7;
    bit boot0sel_vex, boot1sel_vex, fw0sel_vex, fw1sel_vex;
    bit user_trustkey_enable_boot1, user_trustkey_enable_fw0, user_trustkey_enable_fw1;

    assign boot0sel_cm7 = ( haddr_reg[21:14] >= nvrcfgdata.cfgrrsub.m7_boot0_start) & ( haddr_reg[21:14] < nvrcfgdata.cfgrrsub.m7_boot1_start);
    assign boot1sel_cm7 = ( haddr_reg[21:14] >= nvrcfgdata.cfgrrsub.m7_boot1_start) & ( haddr_reg[21:14] < nvrcfgdata.cfgrrsub.m7_fw0_start);
    assign fw0sel_cm7 = ( haddr_reg[21:14] >= nvrcfgdata.cfgrrsub.m7_fw0_start) & ( haddr_reg[21:14] < nvrcfgdata.cfgrrsub.m7_fw1_start);
    assign fw1sel_cm7 = ( haddr_reg[21:14] >= nvrcfgdata.cfgrrsub.m7_fw1_start) & ( haddr_reg[21:14] < nvrcfgdata.cfgrrsub.m7_fw1_end);

    assign boot0sel_vex = ( haddr_reg[21:14] >= nvrcfgdata.cfgrrsub.rv_boot0_start) & ( haddr_reg[21:14] < nvrcfgdata.cfgrrsub.rv_boot1_start);
    assign boot1sel_vex = ( haddr_reg[21:14] >= nvrcfgdata.cfgrrsub.rv_boot1_start) & ( haddr_reg[21:14] < nvrcfgdata.cfgrrsub.rv_fw0_start);
    assign fw0sel_vex = ( haddr_reg[21:14] >= nvrcfgdata.cfgrrsub.rv_fw0_start) & ( haddr_reg[21:14] < nvrcfgdata.cfgrrsub.rv_fw1_start);
    assign fw1sel_vex = ( haddr_reg[21:14] >= nvrcfgdata.cfgrrsub.rv_fw1_start) & ( haddr_reg[21:14] < nvrcfgdata.cfgrrsub.rv_fw1_end);

    assign user_trustkey_enable_boot1 = nvrcfgdata.cfgrrsub.tkey_en[2];
    assign user_trustkey_enable_fw0 = nvrcfgdata.cfgrrsub.tkey_en[3];
    assign user_trustkey_enable_fw1 = nvrcfgdata.cfgrrsub.tkey_en[4];

  //  data/key_cfg_rd/wr decoder
  //  =====================================

    bit [255:0] data_cfg_rd_dis, data_cfg_wr_dis, key_cfg_rd_dis, key_cfg_wr_dis;

    assign data_cfg_rd_dis = {brdatreg[25][127:0], brdatreg[24][127:0]};
    assign data_cfg_wr_dis = {brdatreg[27][127:0], brdatreg[26][127:0]};
    assign key_cfg_rd_dis = {brdatreg[29][127:0], brdatreg[28][127:0]};
    assign key_cfg_wr_dis = {brdatreg[31][127:0], brdatreg[30][127:0]};

  //  secure memory access control
  //  ==============================

  //  Access comparison Logic
  //    slot type   master      mode(AxPROT)        slot owner          disable access
  //    keyslot     x           xN                  NO_OWNER            x       allow
  //                SCE.R/W     exclusive           =sceuser            0       allow
  //                SCE.R/W     secure              =sceuser            0       allow
  //                M7/RV.R/W   privilege/mm        =coreuser           0       allow
  //                M7/RV       x                   x                   1       deny
  //    dataslot    x           x                   NO_OWNER            x       allow
  //                M7/RV.R     x                   =coreuser           x       allow
  //                M7/RV.W     privilege/mm        =coreuser           1       allow
  //                SCE.R       exclusive/secure    =sceuser            0       allow
  //                SCE.W       exclusive/secure    =sceuser            1       allow
  //    codeslot    M7/RV.R/W                       =code_owner         0       allow
  //                M7/RV.R/W                       cfg=open            0       allow
  //    ifrslot     M7/RV.R     privilege/mm        cfg=open            0       allow
  //                M7/RV.W     privilege/mm        cfg=open            0       allow
  //    cfgslot     M7/RV.R     boot0/boot1         cfg=open            0       allow
  //                M7/RV.W     boot0/boot1         cfg=open            0       allow
  //    coreuser    [7]:fw1,    [6]:fw0,            [5]:boot1           [4]:boot0

    localparam PM_CODE_REGION_BORDER = 20'h603D_A;
    localparam PM_CFGD_REGION = {16'h603D,3'b110};
    localparam PM_CFGK_REGION = {16'h603D,3'b110};

    bit [3:0]  userid_c;
    bit vex_mm_reg;
    bit boot0_code_dis, boot1_code_dis, fw0_code_dis, fw1_code_dis, rrsub_code_dis, rrsub_code_dis_trustkey;
    bit cfg_rd_dis, cfg_wr_dis, cfg_prev_dis, cfg_access_error;
    bit sce_exc_op, sce_sec_op;

    bit [3:0]   axi_cmd;
    bit         axi_info;
    bit [11:0]  axi_xadr;
    bit [4:0]   axi_yadr;
    bit [255:0] axi_din;
    bit         trc_busy_delay;


    `theregfull(clktop, coreresetn, axid_reg, '0) <= axis.arvalid & axis.arready & clken ? axis.arid :
                                                        axis.awvalid & axis.awready & clken ? axis.awid : axid_reg;
    `theregfull(clktop, coreresetn, axprot_reg, '0) <= axis.arvalid & axis.arready & clken ? axis.arprot :
                                                        axis.awvalid & & axis.awready & clken ? axis.awprot : axprot_reg;
    `theregfull(clktop, coreresetn, vex_mm_reg, '0) <= (axis.arvalid & axis.arready & clken) | (axis.awvalid & axis.awready & clken) ? vex_mm : vex_mm_reg;

    assign cm7sel = ( hauser_reg == AMBAID4_CM7A );
    assign vexsel = ( hauser_reg == AMBAID4_VEXI ) | ( hauser_reg == AMBAID4_VEXD );
    assign scesel = ( hauser_reg == AMBAID4_SCEA ) | ( hauser_reg == AMBAID4_SCES );

    assign coreuser_mux = scesel ? sceuser :
                            vexsel ? coreuser_vex : coreuser_cm7;
    assign coreuser_in = coreuser_mux;

    assign keytype_in = {3'h0,axid_reg[6:2]};       //sce used only, axim.arid/awid [4:0]

    assign pri_op = axprot_reg[0];
    assign sec_op = !axprot_reg[1];
    assign inst_op = axprot_reg[2];
    assign data_op = !axprot_reg[2];

    assign sce_exc_op = axprot_reg[0] & (!mode_sec);        //exclusive mode for sce, unsecure(using intf from sce), priviledge
    assign sce_sec_op = axprot_reg[0] & mode_sec;           //security mode for sce, secure(using intf from sce), priviledge

    assign keysel = ( haddr_reg[31:16] == PM_KEY_REGION );
    assign datasel = ( haddr_reg[31:16] == PM_DATA_REGION );
    assign codesel = ( haddr_reg[31:12] < PM_CODE_REGION_BORDER );

    assign datacfg = haddr_reg[5] ? acram_rdata[63:32] : acram_rdata[31:0];
    assign keycfg = haddr_reg[5] ? acram_rdata[63:32] : acram_rdata[31:0];

    assign core_rd_dis_k = keycfg[0];
    assign core_wr_dis_k = keycfg[1];
    assign sce_rd_dis_k = keycfg[2];
    assign sce_wr_dis_k = keycfg[3];
    assign keytype_k = keycfg[15:8];
    assign userid_k = keycfg[23:16];
    assign akeyid = keycfg[31:24];          // index from 16 -> 256

    assign core_rd_dis_d = datacfg[0];
    assign core_wr_dis_d = datacfg[1];
    assign sce_rd_dis_d = datacfg[2];
    assign sce_wr_dis_d = datacfg[3];
    assign keytype_d = datacfg[15:8];
    assign userid_d = datacfg[23:16];
    assign wrmode_d = datacfg[24];

    assign userid_c = cm7sel ? {fw1sel_cm7, fw0sel_cm7, boot1sel_cm7, boot0sel_cm7} :
                                    {fw1sel_vex, fw0sel_vex, boot1sel_vex, boot0sel_vex} ;

    // keyslot 0 and 1 don't need trustkey protection, no authenication key link
    // haddr_reg[15:0] = 0/1 exception for keyslot0/1
    assign key_access_error_pre = (((coreuser_in[7:4] & userid_k[7:4])==0) & (ahb_write_flag | ahb_read_flag) |
                                ahb_read_flag & ((core_rd_dis_k & (cm7sel|vexsel)) | cm7sel&(!pri_op) | vexsel&(!vex_mm_reg)) |
                                ahb_write_flag & ((core_wr_dis_k & (cm7sel|vexsel)) | cm7sel&(!pri_op) | vexsel&(!vex_mm_reg)) |
                                ahb_read_flag & scesel & (sce_rd_dis_k | (!sce_sec_op) | (keytype_in != keytype_k)) |
                                ahb_write_flag & scesel & (sce_wr_dis_k | (!sce_sec_op) | (keytype_in != keytype_k)) |
                                (!trustkey[akeyid] & (haddr_reg[15:6] != 10'h0))) & data_op & keysel & (userid_k[7:4] != 4'h0);
    assign key_access_error = key_access_error_pre & rrccr[10];

    assign data_access_error_pre = (((coreuser_in[7:4] & userid_k[7:4])==0) & (ahb_write_flag | ahb_read_flag) |
                                ahb_read_flag & ((core_rd_dis_d & (cm7sel|vexsel)) | cm7sel&(!pri_op) | vexsel&(!vex_mm_reg)) |
                                ahb_write_flag & ((core_wr_dis_d & (cm7sel|vexsel)) | cm7sel&(!pri_op) | vexsel&(!vex_mm_reg)) |
                                ahb_read_flag & scesel & (sce_rd_dis_d | (!(sce_exc_op | sce_sec_op)) | (keytype_in != keytype_d)) |
                                ahb_write_flag & scesel & (sce_wr_dis_d | (!(sce_exc_op | sce_sec_op)) | (keytype_in != keytype_d)) ) & data_op & datasel & (userid_d[7:4] != 4'h0);
    assign data_access_error = data_access_error_pre & rrccr[11];

    assign boot0_code_dis = user_code_cfg_boot0[2] & ahb_read_flag & coreuser_in[5] |           //master boot1 read
                                user_code_cfg_boot0[3] & ahb_write_flag & coreuser_in[5] |      //master boot1 write
                                user_code_cfg_boot0[4] & ahb_read_flag & coreuser_in[6] |       //master fw0 read
                                user_code_cfg_boot0[5] & ahb_write_flag & coreuser_in[6] |      //master fw0 write
                                user_code_cfg_boot0[6] & ahb_read_flag & coreuser_in[7] |       //master fw1 read
                                user_code_cfg_boot0[7] & ahb_write_flag & coreuser_in[7] ;      //master fw1 write

    assign boot1_code_dis = user_code_cfg_boot1[0] & ahb_read_flag & coreuser_in[4] |           //master boot0 read
                                user_code_cfg_boot1[1] & ahb_write_flag & coreuser_in[4] |      //master boot0 write
                                user_code_cfg_boot1[4] & ahb_read_flag & coreuser_in[6] |       //master fw0 read
                                user_code_cfg_boot1[5] & ahb_write_flag & coreuser_in[6] |      //master fw0 write
                                user_code_cfg_boot1[6] & ahb_read_flag & coreuser_in[7] |       //master fw1 read
                                user_code_cfg_boot1[7] & ahb_write_flag & coreuser_in[7] ;      //master fw1 write

    assign fw0_code_dis = user_code_cfg_fw0[0] & ahb_read_flag & coreuser_in[4] |               //master boot0 read
                                user_code_cfg_fw0[1] & ahb_write_flag & coreuser_in[4] |        //master boot0 write
                                user_code_cfg_fw0[2] & ahb_read_flag & coreuser_in[5] |         //master boot1 read
                                user_code_cfg_fw0[3] & ahb_write_flag & coreuser_in[5] |        //master boot1 write
                                user_code_cfg_fw0[6] & ahb_read_flag & coreuser_in[7] |         //master fw1 read
                                user_code_cfg_fw0[7] & ahb_write_flag & coreuser_in[7] ;        //master fw1 write

    assign fw1_code_dis = user_code_cfg_fw1[0] & ahb_read_flag & coreuser_in[4] |               //master boot0 read
                                user_code_cfg_fw1[1] & ahb_write_flag & coreuser_in[4] |        //master boot0 write
                                user_code_cfg_fw1[2] & ahb_read_flag & coreuser_in[5] |         //master boot1 read
                                user_code_cfg_fw1[3] & ahb_write_flag & coreuser_in[5] |        //master boot1 write
                                user_code_cfg_fw1[4] & ahb_read_flag & coreuser_in[6] |         //master fw0 read
                                user_code_cfg_fw1[5] & ahb_write_flag & coreuser_in[6] ;        //master fw0 write

    //if enable trustkey protection, must set trustkey of boot1/fw0/fw1 to access these users region
    //otherwise all the reram operation is blocked for these users
    assign rrsub_code_dis_trustkey = userid_c[1] & user_trustkey_enable_boot1 & (!trustkey[3]) |
                                        userid_c[2] & user_trustkey_enable_fw0 & (!trustkey[5]) |
                                        userid_c[3] & user_trustkey_enable_fw1 & (!trustkey[7]);

    assign rrsub_code_dis = boot0_code_dis & userid_c[0] |
                                boot1_code_dis & userid_c[1] |
                                fw0_code_dis & userid_c[2] |
                                fw1_code_dis & userid_c[3] | rrsub_code_dis_trustkey;

    assign code_access_error_inst = rrsub_code_dis_trustkey & ahb_read_flag & (cm7sel|vexsel) & inst_op & codesel;

    assign code_access_error_data = (rrsub_code_dis & (cm7sel|vexsel) |
                                        ahb_read_flag & scesel & (sce_rd_dis_d | (!(sce_exc_op | sce_sec_op))) |
                                        ahb_write_flag & scesel & (sce_wr_dis_d | (!(sce_exc_op | sce_sec_op)))) & data_op & codesel;

    assign code_access_error_pre = (code_access_error_inst |code_access_error_data);
    assign code_access_error = code_access_error_pre & rrccr[12];

    assign info_access_error_pre = (((brdatreg[axi_yadr][255:248] == PM_WRITE_DIS) | cm7sel&(!pri_op) | vexsel&(!vex_mm_reg) | scesel) & ahb_write_flag |
                                    ((brdatreg[axi_yadr][247:240] == PM_READ_DIS) | cm7sel&(!pri_op) | vexsel&(!vex_mm_reg) | scesel) & ahb_read_flag ) & axi_info & data_op;
    assign info_access_error = info_access_error_pre & rrccr[14];

    assign cfg_rd_dis = data_cfg_rd_dis[haddr_reg[12:5]] & (haddr_reg[31:13] == PM_CFGD_REGION) |
                            key_cfg_rd_dis[haddr_reg[12:5]] & (haddr_reg[31:13] == PM_CFGK_REGION) ;

    assign cfg_wr_dis = data_cfg_wr_dis[haddr_reg[12:5]] & (haddr_reg[31:13] == PM_CFGD_REGION) |
                            key_cfg_wr_dis[haddr_reg[12:5]] & (haddr_reg[31:13] == PM_CFGK_REGION) ;

    assign cfg_prev_dis = (((!(coreuser_in[5] | coreuser_in[4])) & (cm7sel|vexsel)) | cm7sel&(!pri_op) | vexsel&(!vex_mm_reg) | scesel)
                             & ((haddr_reg[31:13] == PM_CFGD_REGION) | (haddr_reg[31:13] == PM_CFGK_REGION));

    assign cfg_access_error_pre = (((cfg_rd_dis & (cm7sel|vexsel)) | cfg_prev_dis) & ahb_read_flag |
                                    ((cfg_wr_dis  & (cm7sel|vexsel)) | cfg_prev_dis) & ahb_write_flag ) & data_op;
    assign cfg_access_error = cfg_access_error_pre & rrccr[13];

    assign cmd_user_write_dis = (key_access_error | data_access_error | info_access_error | code_access_error | cfg_access_error) & ahb_write_flag;
    assign cmd_user_read_dis = (key_access_error | data_access_error | info_access_error | code_access_error | cfg_access_error) & ahb_read_flag;

    sync_pulse sync_key_error ( .clka(clktop),    .resetn(coreresetn), .clkb(hclk), .pulsea (key_access_error), .pulseb( key_access_error_athclk ) );
    sync_pulse sync_data_error ( .clka(clktop),    .resetn(coreresetn), .clkb(hclk), .pulsea (data_access_error), .pulseb( data_access_error_athclk ) );
    sync_pulse sync_info_error ( .clka(clktop),    .resetn(coreresetn), .clkb(hclk), .pulsea (info_access_error), .pulseb( info_access_error_athclk ) );
    sync_pulse sync_code_error ( .clka(clktop),    .resetn(coreresetn), .clkb(hclk), .pulsea (code_access_error), .pulseb( code_access_error_athclk ) );
    sync_pulse sync_cfg_error ( .clka(clktop),    .resetn(coreresetn), .clkb(hclk), .pulsea (cfg_access_error), .pulseb( cfg_access_error_athclk ) );

  //  rram rd/write control
  //  ==============================

    `theregfull(rramclk_org, sysresetn, trc_busyreg1, '0 ) <= trc_busy;
    `theregfull(clktop, sysresetn, trc_dout_ready_done_reg, '1) <= trc_dout_ready_done;

    `theregfull(clktop, sysresetn, rrcfsm, '0) <=
            ( rrcfsm == 0 ) & rramsleep ? 5 :                                                                   // rram enter sleep mode
            ( rrcfsm == 5 ) & !trc_busy & trc_busyreg1 ? 0 :                                                    // rram exit sleep mode, no clock for trc_busy_done sample
            ( rrcfsm == 0 ) & ahb_array_read | two_cycle_read ? 1 :                                             // rram read operation
            ( two_cycle_load | suicide_load ) ? 3 :                                                             // special read done and load start
            ( rrcfsm == 1 ) & trc_dout_ready_done ? 0 :                                                         // normal rram read done
            ( rrcfsm == 0 ) & ahb_array_write  & !rrccr[1] ? 2 :                                                // rram wr_buf load
            ( rrcfsm == 2 ) & ahb_array_write_reg ? 0 :                                                         // rram wr_buf load done
            ( rrcfsm == 0 ) & rram_load_run & (!cmd_user_write_dis) ? 3 :                                       // rram load start
            ( two_cycle_write | suicide_write ) ? 4 :                                                           // special load done and write start
            ( rrcfsm == 3 ) & rramclken ? 0 :                                                                   // normal rram load done  (clock domian)
            ( rrcfsm == 0 ) & rram_write_run & (!cmd_user_write_dis) ? 4 :                                      // rram write start
            ( rrcfsm == 4 ) & trc_busy_done & (!suicide_reg) ? 0 :                                              // rran write done
                                                        rrcfsm;

    `theregfull(rramclk_org, coreresetn, trc_busy_delay, '0) <= trc_busy;

    always@(*)
    casex(rrcfsm)
        3'h1: axi_cmd = trc_busy | trc_busy_delay | trc_dout_ready ? TRC_IDLE : TRC_READ;
        3'h3: axi_cmd = TRC_LOAD;
        3'h4: axi_cmd = (trc_busy | trc_busyreg1) ? TRC_IDLE : TRC_WRITE;
        default: axi_cmd = TRC_IDLE;
    endcase

    assign axi_din = suicide_reg ? 256'h0 :
                        oneway_counter_write_reg ? (ahb_rd_buf + 'h1) :
                        prog_only_data_write_reg ? (ahb_rd_buf | ahb_wr_buf) : ahb_wr_buf;
    assign axi_info = suicide_reg ? suicide_info : haddr_reg[22];                                                                            // 0x6040_0000 mapping to INF0
    assign axi_xadr = suicide_reg ? suicide_xadr : haddr_reg[21:10];
    assign axi_yadr = suicide_reg ? suicide_yadr :haddr_reg[9:5];

    assign ip_user_nap_i = (rrcfsm == 5) & !rrccr[0] & rramsleep;  // =0, nap
    assign ip_user_pd_i = (rrcfsm == 5) & rrccr[0] & rramsleep;    // =1, power down

  //  rram clock generater
  //  ==============================

    bit rramclk0_unbuf, rramclk1_unbuf;
    bit rramclk0_unmux, rramclk1_unmux;
    bit rramsleepreg0, rramsleepreg1;

    assign bist_enable = ((cmscode == CMS_VRGN) | (cmscode == CMS_TEST)) & (brfsm == 3'h5);
    assign scan_test = cmsatpg;

    `theregfull( rramclk_org, coreresetn, rramsleepreg0, '0 ) <= rramsleep;
    `theregfull( rramclk_org, coreresetn, rramsleepreg1, '0 ) <= rramsleepreg0;

    `theregfull( clktop, coreresetn, rramclkcnt, '0 ) <= ( trc_dout_ready_done | ( rrcfsm == 0 ) | rramsleepreg1 & rramsleep) ? 0 :
                                                         ( rramclkcnt == fd0 ) ? 0 : rramclkcnt + 1;

    assign rramclken = (( rrcfsm == 0 ) & (ahb_array_read | ahb_array_write)) |
                        (( rramclkcnt == fd0 ) && ( rrcfsm != 0 )) |
                        (brfsm != 3'h5);

    ICG rramicg_org ( .CK (clktop   ),      .EN ( rramclken ), .SE(scan_test), .CKG ( rramclk_org ));
    ICG rramicg_tck0 ( .CK (jtag[0].tck ),   .EN ( bist_enable ), .SE('0), .CKG ( rramclk_tck0 ));
    ICG rramicg_tck1 ( .CK (jtag[1].tck ),   .EN ( bist_enable ), .SE('0), .CKG ( rramclk_tck1 ));

    assign rramclk0_unmux = rramclk_org | rramclk_tck0;
    assign rramclk1_unmux = rramclk_org | rramclk_tck1;

    CLKCELL_MUX2 u_scanmux_rramclk0  (.A(rramclk0_unmux),.B(clkocc),.S(cmsatpg),.Z(rramclk0_unbuf));
    CLKCELL_MUX2 u_scanmux_rramclk1  (.A(rramclk1_unmux),.B(clkocc),.S(cmsatpg),.Z(rramclk1_unbuf));

    CLKCELL_BUF buf_rramclk0(.A(rramclk0_unbuf),.Z(rramclk0));
    CLKCELL_BUF buf_rramclk1(.A(rramclk1_unbuf),.Z(rramclk1));

  //  rram intf handler
  //  ==============================

    bit [255:0] ip_user_udin_i;
    bit [35:0] ip_user_tdin_i;

    bit trc_busy_s0;
    bit trc_busy_s1;
    bit trc_err_s0;
    bit trc_err_s1;
    bit trc_info_lock_err_s0;
    bit trc_info_lock_err_s1;

    bit ip_user_info_i;
    bit [11:0] ip_user_xadr_i;
    bit [4:0] ip_user_yadr_i;
    bit ip_user_write_abort_i;
    bit [63:0] ip_user_trc_data_i;

    bit ip_user_ifren1_i;
    bit ip_user_reden_i;
    bit trc_write_suspend_i;
    bit trc_write_resume_i;
    bit trc_write_abort_i;

    assign trc_busy = trc_busy_s0 | trc_busy_s1;
    assign trc_dout_ready = trc_dout_ready_s0 & trc_dout_ready_s1;
    assign trc_err = trc_err_s0 | trc_err_s1;
    assign trc_info_lock_err = trc_info_lock_err_s0 | trc_info_lock_err_s1;
    assign ecc_err = ecc_err_s0 | ecc_err_s1;

`ifdef TRC_WRITE_STATUS
    assign trc_set_failure = trc_set_failure_s0 | trc_set_failure_s1;
    assign trc_reset_failure = trc_reset_failure_s0 | trc_reset_failure_s1;
    assign trc_fourth_read_failure = trc_fourth_read_failure_s0 | trc_fourth_read_failure_s1;
`else
    assign trc_set_failure = '0;
    assign trc_reset_failure = '0;
    assign trc_fourth_read_failure = '0;
`endif

    assign ip_user_cmd_i         = axi_cmd | brfsm_cmd ;
    assign ip_user_info_i        = axi_info | brfsm_info;
    assign ip_user_xadr_i        = axi_xadr | brfsm_xadr;
    assign ip_user_yadr_i        = axi_yadr | brfsm_yadr;
    assign ip_user_udin_i        = axi_din | {252'h0,brfsm_udin} ;
    assign ip_user_tdin_i        = 'h0;
    assign ip_user_trc_data_i    = 'h0;
    assign ip_user_write_abort_i = 'h0;
    assign ip_user_ifren1_i      = 'h0;
    assign ip_user_reden_i       = 'h0;
    assign trc_write_suspend_i   = 'h0;
    assign trc_write_resume_i    = 'h0;
    assign trc_write_abort_i     = 'h0;

  //  rram trbcx ip_s1 instantiate
  //  ==============================

    trbcx1r32_daric_wrapper u_trbcx_s0(

        //test mode
        .bist_enable                        ( bist_enable               ),
        .bist_rst_n                         ( sysresetn                 ),
        .jtag_trst_n                        ( jtag[0].trst              ),
        .clk                                ( rramclk0                  ),
        .bist_clk                           ( jtag[0].tck               ),
        .tck                                ( jtag[0].tck               ),
        .inv_tck                            ( ~jtag[0].tck              ),
        .tms                                ( jtag[0].tms               ),
        .tdi                                ( jtag[0].tdi               ),
        .tdo                                ( jtag[0].tdo               ),
        .scan_test                          ( scan_test                 ),

        //user mode
        .rst_n                              ( sysresetn                 ),
        .ip_user_cmd_i                      ( ip_user_cmd_i             ),
        .ip_user_info_i                     ( ip_user_info_i            ),
        .ip_user_ifren1_i                   ( ip_user_ifren1_i          ),
        .ip_user_reden_i                    ( ip_user_reden_i           ),

        .ip_user_xadr_i                     ( ip_user_xadr_i            ),
        .ip_user_yadr_i                     ( ip_user_yadr_i            ),
        .ip_user_udin_i                     ( ip_user_udin_i[127:0]     ),
        .ip_user_tdin_i                     ( ip_user_tdin_i[17:0]      ),
        .ip_user_nap_i                      ( ip_user_nap_i             ),
        .ip_user_pd_i                       ( ip_user_pd_i              ),
        .ip_user_trc_data_i                 ( ip_user_trc_data_i        ),
        .trc_dout_o                         ( trc_dout_s0               ),
        .trc_dout_ready_o                   ( trc_dout_ready_s0         ),
        .ecc_err_o                          ( ecc_err_s0                ),
        .trc_regif_dout_o                   ( trc_regif_dout_s0         ),
        .trc_busy_o                         ( trc_busy_s0               ),
        .trc_err_o                          ( trc_err_s0                ),

    `ifdef OPT_IFR1_LOCK
        .trc_info_lock_err_o                (                           ),
    `endif

    `ifdef OPT_ASYNC_READ
        .async_access_i                     (                           ),
        .async_ifren_i                      (                           ),
        .async_ifren1_i                     (                           ),
        .async_reden_i                      (                           ),
        .async_read_i                       (                           ),
        .async_pch_ext_i                    (                           ),
        .async_xadr_i                       (                           ),
        .async_yadr_i                       (                           ),
        .async_rram_rdone_o                 (                           ),
    `endif

        .trc_write_suspend_i                (trc_write_suspend_i        ),
        .trc_write_resume_i                 (trc_write_resume_i         ),
        .trc_write_abort_i                  (trc_write_abort_i          ),
        .trc_write_suspend_o                (trc_write_suspend_s0       ),

`ifdef TRC_WRITE_STATUS
        .trc_set_failure_status             (trc_set_failure_s0         ),
        .trc_reset_failure_status           (trc_reset_failure_s0       ),
        .trc_fourth_read_failure_status     (trc_fourth_read_failure_s0 ),
`endif
        .sw_r_cfg_status                    (                           ),

        .rri                                (rri[0]                     ),
        .rro                                (rro[0]                     ),

        .ifr_index                          (ifr_index_s0               ),
        .ifr_read_dis_test                  (ifr_read_dis_test_s0       ),
        .ifr_write_dis_test                 (ifr_write_dis_test_s0      ),
        .boot0_write_dis_test               (boot0_write_dis_test       ),
        .boot0_read_dis_test                (boot0_read_dis_test        ),
        .boot1_write_dis_test               (boot1_write_dis_test       ),
        .boot1_read_dis_test                (boot1_read_dis_test        ),
        .fw0_write_dis_test                 (fw0_write_dis_test         ),
        .fw0_read_dis_test                  (fw0_read_dis_test          ),
        .fw1_write_dis_test                 (fw1_write_dis_test         ),
        .fw1_read_dis_test                  (fw1_read_dis_test          ),
        .rrsub_size_test                    (rrsub_size_test            )

        );


  //  rram trbcx ip_s2 instantiate
  //  ==============================

   trbcx1r32_daric_wrapper u_trbcx_s1(

        //test mode
        .bist_enable                        ( bist_enable               ),
        .bist_rst_n                         ( sysresetn                 ),
        .jtag_trst_n                        ( jtag[1].trst              ),
        .clk                                ( rramclk1                  ),
        .bist_clk                           ( jtag[0].tck               ),
        .tck                                ( jtag[1].tck               ),
        .inv_tck                            ( ~jtag[1].tck              ),
        .tms                                ( jtag[1].tms               ),
        .tdi                                ( jtag[1].tdi               ),
        .tdo                                ( jtag[1].tdo               ),
        .scan_test                          ( scan_test                 ),

        //user mode
        .rst_n                              ( sysresetn                 ),
        .ip_user_cmd_i                      ( ip_user_cmd_i             ),
        .ip_user_info_i                     ( ip_user_info_i            ),
        .ip_user_ifren1_i                   ( ip_user_ifren1_i          ),
        .ip_user_reden_i                    ( ip_user_reden_i           ),

        .ip_user_xadr_i                     ( ip_user_xadr_i            ),
        .ip_user_yadr_i                     ( ip_user_yadr_i            ),
        .ip_user_udin_i                     ( ip_user_udin_i[255:128]   ),
        .ip_user_tdin_i                     ( ip_user_tdin_i[17:0]      ),
        .ip_user_nap_i                      ( ip_user_nap_i             ),
        .ip_user_pd_i                       ( ip_user_pd_i              ),
        .ip_user_trc_data_i                 ( ip_user_trc_data_i        ),
        .trc_dout_o                         ( trc_dout_s1               ),
        .trc_dout_ready_o                   ( trc_dout_ready_s1         ),
        .ecc_err_o                          ( ecc_err_s1                ),
        .trc_regif_dout_o                   ( trc_regif_dout_s1         ),
        .trc_busy_o                         ( trc_busy_s1               ),
        .trc_err_o                          ( trc_err_s1                ),

    `ifdef OPT_IFR1_LOCK
        .trc_info_lock_err_o                (                           ),
    `endif

    `ifdef OPT_ASYNC_READ
        .async_access_i                     (                           ),
        .async_ifren_i                      (                           ),
        .async_ifren1_i                     (                           ),
        .async_reden_i                      (                           ),
        .async_read_i                       (                           ),
        .async_pch_ext_i                    (                           ),
        .async_xadr_i                       (                           ),
        .async_yadr_i                       (                           ),
        .async_rram_rdone_o                 (                           ),
    `endif

        .trc_write_suspend_i                (trc_write_suspend_i        ),
        .trc_write_resume_i                 (trc_write_resume_i         ),
        .trc_write_abort_i                  (trc_write_abort_i          ),
        .trc_write_suspend_o                (trc_write_suspend_s1       ),

`ifdef TRC_WRITE_STATUS
        .trc_set_failure_status             (trc_set_failure_s1         ),
        .trc_reset_failure_status           (trc_reset_failure_s1       ),
        .trc_fourth_read_failure_status     (trc_fourth_read_failure_s1 ),
`endif

        .sw_r_cfg_status                    (                           ),

        .rri                                (rri[1]                     ),
        .rro                                (rro[1]                     ),

        .ifr_index                          (ifr_index_s1               ),
        .ifr_read_dis_test                  (ifr_read_dis_test_s1       ),
        .ifr_write_dis_test                 (ifr_write_dis_test_s1      ),
        .boot0_write_dis_test               (boot0_write_dis_test       ),
        .boot0_read_dis_test                (boot0_read_dis_test        ),
        .boot1_write_dis_test               (boot1_write_dis_test       ),
        .boot1_read_dis_test                (boot1_read_dis_test        ),
        .fw0_write_dis_test                 (fw0_write_dis_test         ),
        .fw0_read_dis_test                  (fw0_read_dis_test          ),
        .fw1_write_dis_test                 (fw1_write_dis_test         ),
        .fw1_read_dis_test                  (fw1_read_dis_test          ),
        .rrsub_size_test                    (rrsub_size_test            )

        );

endmodule : rrc
