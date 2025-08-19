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

module cm7sys
  #(

    // ref doc-iim 4.17

    parameter PM_CFGITCMSZ = 4'h7,  // 64KB
    parameter PM_CFGDTCMSZ = 4'h7,  // 64KB
    parameter PM_CFGAHBPSZ = 3'h4,  // 512MB
    parameter PM_CFGSTCALIB_10MS = 24'd9_999, // @1MHz
    parameter PM_INITRETRYEN = 2'h0,    // [0] itcm, [1] dtcm
    parameter PM_INITRMWEN = 2'h0,      // [0] itcm, [1] dtcm
    parameter PM_COREUSERCNT = 4,

    parameter PM_AXIM_IDW = 8,
    parameter PM_AXIM_LENW = 8,
    parameter PM_AXIM_UW = 8,
    parameter PM_AHBP_IDW = 8,
    parameter PM_AHBP_UW = 8,
    parameter PM_AHBS_IDW = 8,
    parameter PM_AHBS_UW = 8,

    // ------------------------------------------------------------------------
    // Cortex-M7 Processor Parameterization
    // ------------------------------------------------------------------------
    `include "cm7sys_cfg.svh"
    ,
    // ------------------------------------------------------------------------
    parameter SWMD      = 0,     // Serial Wire Multi Drop support
                                 //   0 = no support
                                 //   1 = spported
    // ------------------------------------------------------------------------
    // The following parameters are for the DAP
    // ------------------------------------------------------------------------
    parameter BASEADDR =  32'hE00FD003,
                                // Allows configuration of the ROM table
                                // base address which is read from the
                                // AP during debug sessions. This is pointing
                                // to the system level (MCU) ROM table by
                                // default (address 0xE00FD000).
                                // If additional level of ROM table are added,
                                // this should be overridden to point to the
                                // highest level ROM table.
                                // If the system level (MCU) ROM table address
                                // is changed (specific by SYSROMTABLEBASE, a
                                // localparam in this file), this value also
                                // need to be updated.
    // ------------------------------------------------------------------------
    parameter TARGETID   = 32'h00000000,
                                // 31:28=TREVISION 27:12=TPARTNO
                                // 11:1=TDESIGNER 0=1
    // ------------------------------------------------------------------------
    // The following parameters are for the main ROM table
    // ------------------------------------------------------------------------
    parameter JEPID      = 7'h00,  // JEP106 identification code
    // ------------------------------------------------------------------------
    parameter JEPCONT    = 4'h0,   // JEP106 continuation code
    // ------------------------------------------------------------------------
//    parameter PARTNUM    = 12'h000, // Part number (for MCU)
    parameter PARTNUM    = 12'hCB0, // Part number (for MCU)
                                   // Reflected in PIDR0 and PIDR1
    // ------------------------------------------------------------------------
    parameter dtcmrc = 1,
    parameter sram_pkg::sramcfg_t dtcmcfg = {
        AW: 13,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 2**13,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '0,
        isPRT:  '1,
        EVITVL: 15
    },

    parameter itcmrc = 4,
    parameter sram_pkg::sramcfg_t itcmcfg = {
        AW: 15,
        DW: 64,
        KW: 64,
        PW: 8,
        WCNT: 2**15,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '0,
        isPRT:  '1,
        EVITVL: 15
    },
    parameter bit[3:0] AXIMID4 = 4'h2,
    parameter bit[3:0] AHBPID4 = 4'h8

)(

// system ctrl
    input   logic               clk,            // Free running clock
    input   logic               clktop,
    input   logic               fclken,
    input   logic               hclk,
    input   logic               resetn,
    input   logic               coreresetn,

    output  logic               cm7_resetreq,
    output  logic               cm7_sleep,
    input   logic               clkcm7sten_1M,

// cfg
    input   logic               cm7cfg_dev,
    input   logic [31:0]        cm7cfg_iv,// = 32'h6000_0000;
    input   logic [1:0]         cm7cfg_itcmwaitcyc,
    input   logic [1:0]         cm7cfg_dtcmwaitcyc,
    input   logic [2:0]         cm7cfg_itcmsramtrm,
    input   logic [2:0]         cm7cfg_dtcmsramtrm,
    input   logic [2:0]         cm7cfg_cachesramtrm,
    input   logic               tcmeven,

// test mode
    input   logic               cmsatpg,
    input   logic               cmsbist,
    rbif.slave rbif_rf1kx72        [0:1]  ,
    rbif.slave rbif_rf256x27       [0:1]  ,
    rbif.slave rbif_rf512x39       [0:7]  ,
    rbif.slave rbif_rf128x31       [0:3]  ,
    rbif.slave rbif_dtcm8kx36      [0:1]  ,
    rbif.slave rbif_itcm32kx18     [0:3]  ,
//    mbist.master                mbistif,

// interrupt, nmi, events
    input   logic [IRQNUM-1:0]  cm7_irq,
    input   logic               cm7_nmi,
    input   logic               cm7_rxev,

// amba
    input   logic               aximclken,       // axi clk enable
    input   logic               ahbpclken,
    input   logic               ahbsclken,
    axiif.master                axim,
    ahbif.master                ahbp,
    ahbif.slave                 ahbs,

// coreuser
    input   logic [7:0]         coreuser_filtercyc,
    input   axi_pkg::xbar_rule_32_t [0:PM_COREUSERCNT-1]       coreusermap,
    output  logic                   [PM_COREUSERCNT-1:0]       coreuser,

// debug
    input   logic               swclk,
    ioif.drive                  swdio

);

// axim cfg:
//
//  .AW     (32),
//  .DW     (64),
//  .IDW    (8),
//  .LENW   (8),
//  .UW     (8)

// ahbp/ahbs cfg:
//
//  .AW     (32),
//  .DW     (32),
//  .IDW    (8),
//  .UW     (8)


// bit

  bit [63:0]  TSVALUEB;
  bit                      sys_itcmcs;
  bit [23:3]               sys_itcmaddr;
  bit [ 7:0]               sys_itcmbytewr;
  bit [63:0]               sys_itcmwdata;
  bit [63:0]               sys_itcmrdata;
  bit [63:0]               sys_itcmrdata0;
  bit                      sys_itwait;
  bit                      sys_iterr;
  bit                      sys_itretry;
  bit                      sys_d0tcmcs;
  bit [23:3]               sys_d0tcmaddr;
  bit [ 3:0]               sys_d0tcmbytewr;
  bit [31:0]               sys_d0tcmwdata;
  bit [31:0]               sys_d0tcmrdata;
  bit                      sys_d0wait;
  bit                      sys_d0err;
  bit                      sys_d0retry;
  bit                      sys_d1tcmcs;
  bit [23:3]               sys_d1tcmaddr;
  bit [ 3:0]               sys_d1tcmbytewr;
  bit [31:0]               sys_d1tcmwdata;
  bit [31:0]               sys_d1tcmrdata;
  bit                      sys_d1wait;
  bit                      sys_d1err;
  bit                      sys_d1retry;


  bit          ahbd_hready;
  bit          ahbd_hresp;
  bit [31:0]   ahbd_hrdata;
  bit [ 1:0]   ahbd_htrans;
  bit          ahbd_hwrite;
  bit [ 1:0]   ahbd_hsize;
  bit [ 2:0]   ahbd_hburst;
  bit [ 3:0]   ahbd_hprot;
  bit [31:0]   ahbd_haddr;
  bit [31:0]   ahbd_hwdata;

  localparam SYSROMTABLEBASE = 32'hE00FD000;
  localparam CM7ROMTABLEBASE = 32'hE00FE000;
  localparam TPIUBASE        = 32'hE0040000;

// --------------------------------------------------------------------------
// ECOREVNUM Mapping Tie Offs
// --------------------------------------------------------------------------
//
// MCU level (input ECOREVNUM[51:0])
//  ECOREVNUM[51:48] - MCU ROM Table
//  ECOREVNUM[47:44] - TPIU
//  ECOREVNUM[43:36] - DAP
//  ECOREVNUM[35: 0] - CS level
//
// CS level (input ECOREVNUM[35:0])
//  ECOREVNUM[35:32] - ETM
//  ECOREVNUM[31:28] - CTI
//  ECOREVNUM[27:24] - CS ROM Table
//  ECOREVNUM[23: 0] - CORTEXM7
//
// CORTEXM7 level  (input ECOREVNUM[23:0])
//  ECOREVNUM[23:20] - ITM
//  ECOREVNUM[19:16] - CPU ROM Table
//  ECOREVNUM[15:12] - SCS
//  ECOREVNUM[11: 8] - DWT
//  ECOREVNUM[ 7: 4] - FPB
//  ECOREVNUM[ 3: 0] - CPUID Revision[3:0]
  wire [51:0]               ECOREVNUM;

  assign ECOREVNUM[ 0] = 1'b0 ; // buf keep_tie_cell_00 (ECOREVNUM[ 0],1'b0);
  assign ECOREVNUM[ 1] = 1'b0 ; // buf keep_tie_cell_01 (ECOREVNUM[ 1],1'b0);
  assign ECOREVNUM[ 2] = 1'b0 ; // buf keep_tie_cell_02 (ECOREVNUM[ 2],1'b0);
  assign ECOREVNUM[ 3] = 1'b0 ; // buf keep_tie_cell_03 (ECOREVNUM[ 3],1'b0);
  assign ECOREVNUM[ 4] = 1'b0 ; // buf keep_tie_cell_04 (ECOREVNUM[ 4],1'b0);
  assign ECOREVNUM[ 5] = 1'b0 ; // buf keep_tie_cell_05 (ECOREVNUM[ 5],1'b0);
  assign ECOREVNUM[ 6] = 1'b0 ; // buf keep_tie_cell_06 (ECOREVNUM[ 6],1'b0);
  assign ECOREVNUM[ 7] = 1'b0 ; // buf keep_tie_cell_07 (ECOREVNUM[ 7],1'b0);
  assign ECOREVNUM[ 8] = 1'b0 ; // buf keep_tie_cell_08 (ECOREVNUM[ 8],1'b0);
  assign ECOREVNUM[ 9] = 1'b0 ; // buf keep_tie_cell_09 (ECOREVNUM[ 9],1'b0);
  assign ECOREVNUM[10] = 1'b0 ; // buf keep_tie_cell_10 (ECOREVNUM[10],1'b0);
  assign ECOREVNUM[11] = 1'b0 ; // buf keep_tie_cell_11 (ECOREVNUM[11],1'b0);
  assign ECOREVNUM[12] = 1'b0 ; // buf keep_tie_cell_12 (ECOREVNUM[12],1'b0);
  assign ECOREVNUM[13] = 1'b0 ; // buf keep_tie_cell_13 (ECOREVNUM[13],1'b0);
  assign ECOREVNUM[14] = 1'b0 ; // buf keep_tie_cell_14 (ECOREVNUM[14],1'b0);
  assign ECOREVNUM[15] = 1'b0 ; // buf keep_tie_cell_15 (ECOREVNUM[15],1'b0);
  assign ECOREVNUM[16] = 1'b0 ; // buf keep_tie_cell_16 (ECOREVNUM[16],1'b0);
  assign ECOREVNUM[17] = 1'b0 ; // buf keep_tie_cell_17 (ECOREVNUM[17],1'b0);
  assign ECOREVNUM[18] = 1'b0 ; // buf keep_tie_cell_18 (ECOREVNUM[18],1'b0);
  assign ECOREVNUM[19] = 1'b0 ; // buf keep_tie_cell_19 (ECOREVNUM[19],1'b0);
  assign ECOREVNUM[20] = 1'b0 ; // buf keep_tie_cell_20 (ECOREVNUM[20],1'b0);
  assign ECOREVNUM[21] = 1'b0 ; // buf keep_tie_cell_21 (ECOREVNUM[21],1'b0);
  assign ECOREVNUM[22] = 1'b0 ; // buf keep_tie_cell_22 (ECOREVNUM[22],1'b0);
  assign ECOREVNUM[23] = 1'b0 ; // buf keep_tie_cell_23 (ECOREVNUM[23],1'b0);
  assign ECOREVNUM[24] = 1'b0 ; // buf keep_tie_cell_24 (ECOREVNUM[24],1'b0);
  assign ECOREVNUM[25] = 1'b0 ; // buf keep_tie_cell_25 (ECOREVNUM[25],1'b0);
  assign ECOREVNUM[26] = 1'b0 ; // buf keep_tie_cell_26 (ECOREVNUM[26],1'b0);
  assign ECOREVNUM[27] = 1'b0 ; // buf keep_tie_cell_27 (ECOREVNUM[27],1'b0);
  assign ECOREVNUM[28] = 1'b0 ; // buf keep_tie_cell_28 (ECOREVNUM[28],1'b0);
  assign ECOREVNUM[29] = 1'b0 ; // buf keep_tie_cell_29 (ECOREVNUM[29],1'b0);
  assign ECOREVNUM[30] = 1'b0 ; // buf keep_tie_cell_30 (ECOREVNUM[30],1'b0);
  assign ECOREVNUM[31] = 1'b0 ; // buf keep_tie_cell_31 (ECOREVNUM[31],1'b0);
  assign ECOREVNUM[32] = 1'b0 ; // buf keep_tie_cell_32 (ECOREVNUM[32],1'b0);
  assign ECOREVNUM[33] = 1'b0 ; // buf keep_tie_cell_33 (ECOREVNUM[33],1'b0);
  assign ECOREVNUM[34] = 1'b0 ; // buf keep_tie_cell_34 (ECOREVNUM[34],1'b0);
  assign ECOREVNUM[35] = 1'b0 ; // buf keep_tie_cell_35 (ECOREVNUM[35],1'b0);
  assign ECOREVNUM[36] = 1'b0 ; // buf keep_tie_cell_36 (ECOREVNUM[36],1'b0);
  assign ECOREVNUM[37] = 1'b0 ; // buf keep_tie_cell_37 (ECOREVNUM[37],1'b0);
  assign ECOREVNUM[38] = 1'b0 ; // buf keep_tie_cell_38 (ECOREVNUM[38],1'b0);
  assign ECOREVNUM[39] = 1'b0 ; // buf keep_tie_cell_39 (ECOREVNUM[39],1'b0);
  assign ECOREVNUM[40] = 1'b0 ; // buf keep_tie_cell_40 (ECOREVNUM[40],1'b0);
  assign ECOREVNUM[41] = 1'b0 ; // buf keep_tie_cell_41 (ECOREVNUM[41],1'b0);
  assign ECOREVNUM[42] = 1'b0 ; // buf keep_tie_cell_42 (ECOREVNUM[42],1'b0);
  assign ECOREVNUM[43] = 1'b0 ; // buf keep_tie_cell_43 (ECOREVNUM[43],1'b0);
  assign ECOREVNUM[44] = 1'b0 ; // buf keep_tie_cell_44 (ECOREVNUM[44],1'b0);
  assign ECOREVNUM[45] = 1'b0 ; // buf keep_tie_cell_45 (ECOREVNUM[45],1'b0);
  assign ECOREVNUM[46] = 1'b0 ; // buf keep_tie_cell_46 (ECOREVNUM[46],1'b0);
  assign ECOREVNUM[47] = 1'b0 ; // buf keep_tie_cell_47 (ECOREVNUM[47],1'b0);
  assign ECOREVNUM[48] = 1'b0 ; // buf keep_tie_cell_48 (ECOREVNUM[48],1'b0);
  assign ECOREVNUM[49] = 1'b0 ; // buf keep_tie_cell_49 (ECOREVNUM[49],1'b0);
  assign ECOREVNUM[50] = 1'b0 ; // buf keep_tie_cell_50 (ECOREVNUM[50],1'b0);
  assign ECOREVNUM[51] = 1'b0 ; // buf keep_tie_cell_51 (ECOREVNUM[51],1'b0);

//
  logic [31:0]  prdata_mcu_rom_table;
  logic         psel_mcu_rom_table, psel_tpiu, psel_cm7;
  logic [19:2]  paddr;
  logic [31:0]  prdata_cm7;
  logic         pready_cm7, pslverr_cm7;
  logic cm7sleep_sim, cm7wkup_sim;

    ahbif ahbp0(),ahbpsim();
    ahbif ahbs0();

    logic                   dbghalt;

    logic clkcm7in, clkcm7en, clkcm7fen, clkcm7hen;
    logic cm7_sleeping, cm7_sleepdeep, cm7_gatehclk;
    logic nPORESET, nSYSRESET;

    assign clkcm7in = clk;

//    assign clkcm7en = ~cm7_sleep;
    assign clkcm7en = ~cm7_sleeping;
    assign clkcm7fen = 1'b1;
    assign clkcm7hen = clkcm7en | ~cm7_gatehclk;

    assign cm7_sleep = cm7_sleeping & cm7_sleepdeep | cm7sleep_sim;
    assign nPORESET = resetn;
    assign nSYSRESET = coreresetn;

    logic [IRQNUM-1:0]  cm7_irqreg;
    logic               cm7_nmireg;
    logic               cm7_rxevreg;
    logic [2:0] axim_AWLEN, axim_ARLEN;
    logic [31:3] cm7top_IADDR;


    `theregrn( cm7_irqreg  ) <= cm7_sleep ? cm7_irqreg  | cm7_irq  : cm7_irq;
    `theregrn( cm7_nmireg  ) <= cm7_sleep ? cm7_nmireg  | cm7_nmi  : cm7_nmi;
    `theregrn( cm7_rxevreg ) <= cm7_sleep ? cm7_rxevreg | cm7_rxev : cm7_rxev;


`ifdef SIM
    `theregrn( cm7sleep_sim ) <= ( cm7wkup_sim ) ? '0 : cm7sleep_sim;
    `theregrn( cm7wkup_sim ) <= 0;
`else
    `theregrn( cm7sleep_sim ) <= 0;
    `theregrn( cm7wkup_sim ) <= 0;
`endif
// #daric mod
    wire [31:0] pcptr;


  CORTEXM7INTEGRATIONCS
    #(
      .FPU                           (FPU),
      .ICACHE                        (ICACHE),
      .DCACHE                        (DCACHE),
      .CACHEECC                      (CACHEECC),
      .MPU                           (MPU),
      .IRQNUM                        (IRQNUM),
      .IRQLVL                        (IRQLVL),
      .DBGLVL                        (DBGLVL),
      .TRC                           (TRC),
      .LOCKSTEP                      (LOCKSTEP),
      .RAR                           (RAR),
      .DW                            (DW),
      .ETM                           (ETM),
      .CTI                           (CTI),
      .WIC                           (WIC),
      .WICLINES                      (WICLINES),
      .ICACHESIZE                    (ICACHESIZE),
      .DCACHESIZE                    (DCACHESIZE)
     )
  cm7top
    (
      .pcptr        (pcptr),

      // ---------------------------------------------------------------------
      // ATB-D interface: unused
      // ---------------------bbb------------------------------------------------
      .ATREADYMD                      (1'b1),
      .AFVALIDMD                      (1'b0),
      .ATVALIDMD                      (),
      .AFREADYMD                      (),
      .ATDATAMD                       (),
      .ATBYTESMD                      (),
      .ATIDMD                         (),


      .CLKIN                          (clkcm7in),
      .CLKEN                          (clkcm7en),
      .FCLKEN                         (clkcm7fen),
      .HCLKEN                         (clkcm7hen),
      .CLK1EN                         (1'b0),
      .FCLK1EN                        (1'b0),
      .HCLK1EN                        (1'b0),
      .ETMCLKEN                       (1'b0),       // ref from IK's sim
      .STCLKEN                        (clkcm7sten_1M),
      .nSYSRESET                      (coreresetn),
      .SYSRESETREQ                    (cm7_resetreq),
      .nPORESET                       (resetn),
      .nDBGETMRESET                   (1'b0),
      .CPUWAIT                        (1'b0),

      .CFGBIGEND                      (1'b0),
      .CFGITCMSZ                      (PM_CFGITCMSZ),
      .CFGDTCMSZ                      (PM_CFGDTCMSZ),
      .CFGAHBPSZ                      (PM_CFGAHBPSZ),
      .CFGSTCALIB                     (PM_CFGSTCALIB_10MS|26'h0),
      .cachesramtrm                   (cm7cfg_cachesramtrm),

      .INITTCMEN                      (2'b11),
      .INITRMWEN                      (2'b00),
      .INITRETRYEN                    (2'b00),
      .INITAHBPEN                     (1'b1),
      .INITVTOR                       (cm7cfg_iv[31:7]),

      .ITCMCS                         (sys_itcmcs),
      .ITCMADDR                       (sys_itcmaddr[23:3]),
      .ITCMWR                         (),
      .ITCMBYTEWR                     (sys_itcmbytewr[7:0]),
      .ITCMPRIV                       (),
      .ITCMMASTER                     (),
      .ITCMWDATA                      (sys_itcmwdata[63:0]),
      .ITCMMBISTIN                    (),
      .ITCMWAIT                       (sys_itwait),
      .ITCMERR                        (sys_iterr),
      .ITCMRDATA                      (sys_itcmrdata[63:0]),
      .ITCMRETRY                      (sys_itretry),
      .ITCMMBISTOUT                   ({8{1'b0}}),

      .D0TCMCS                        (sys_d0tcmcs),
      .D0TCMADDR                      (sys_d0tcmaddr[23:3]),
      .D0TCMWR                        (),
      .D0TCMBYTEWR                    (sys_d0tcmbytewr[3:0]),
      .D0TCMPRIV                      (),
      .D0TCMMASTER                    (),
      .D0TCMWDATA                     (sys_d0tcmwdata[31:0]),
      .D0TCMMBISTIN                   (),
      .D0TCMWAIT                      (sys_d0wait),
      .D0TCMERR                       (sys_d0err),
      .D0TCMRDATA                     (sys_d0tcmrdata[31:0]),
      .D0TCMRETRY                     (sys_d0retry),
      .D0TCMMBISTOUT                  ({7{1'b0}}),
      .D1TCMCS                        (sys_d1tcmcs),
      .D1TCMADDR                      (sys_d1tcmaddr[23:3]),
      .D1TCMWR                        (),
      .D1TCMBYTEWR                    (sys_d1tcmbytewr[3:0]),
      .D1TCMPRIV                      (),
      .D1TCMMASTER                    (),
      .D1TCMWDATA                     (sys_d1tcmwdata[31:0]),
      .D1TCMMBISTIN                   (),
      .D1TCMWAIT                      (sys_d1wait),
      .D1TCMERR                       (sys_d1err),
      .D1TCMRDATA                     (sys_d1tcmrdata[31:0]),
      .D1TCMRETRY                     (sys_d1retry),
      .D1TCMMBISTOUT                  ({7{1'b0}}),

      .ACLKEN                         (aximclken),

      .ARVALID                        (axim.arvalid),
      .ARADDR                         (axim.araddr),
      .ARID                           (axim.arid[2:0]),
      .ARBURST                        (axim.arburst),
//      .ARLEN                          (axim.arlen[2:0]),
      .ARLEN                          (axim_ARLEN),
      .ARSIZE                         (axim.arsize[1:0]),
      .ARLOCK                         (axim.arlock),
      .ARCACHE                        (axim.arcache),
      .ARPROT                         (axim.arprot),
      .ARMASTER                       (axim.armaster),
      .ARINNER                        (axim.arinner),
      .ARSHARE                        (axim.arshare),
      .ARREADY                        (axim.arready),

      .AWVALID                        (axim.awvalid),
      .AWADDR                         (axim.awaddr),
      .AWID                           (axim.awid[1:0]),
      .AWBURST                        (axim.awburst),
      .AWLEN                          (axim_AWLEN),
      .AWSIZE                         (axim.awsize[1:0]),
      .AWLOCK                         (axim.awlock),
      .AWCACHE                        (axim.awcache),
      .AWPROT                         (axim.awprot),
      .AWMASTER                       (axim.awmaster),
      .AWINNER                        (axim.awinner),
      .AWSHARE                        (axim.awshare),
      .AWSPARSE                       (axim.awsparse),
      .AWREADY                        (axim.awready),
      .RREADY                         (axim.rready),
      .RVALID                         (axim.rvalid),
      .RID                            (axim.rid[2:0]),
      .RLAST                          (axim.rlast),
      .RDATA                          (axim.rdata),
      .RRESP                          (axim.rresp),
      .WVALID                         (axim.wvalid),
      .WID                            (),
      .WDATA                          (axim.wdata),
      .WSTRB                          (axim.wstrb),
      .WLAST                          (axim.wlast),
      .WREADY                         (axim.wready),
      .BREADY                         (axim.bready),
      .BVALID                         (axim.bvalid),
      .BID                            (axim.bid[1:0]),
      .BRESP                          (axim.bresp),

      .HTRANSP                        (ahbp0.htrans),
      .HWRITEP                        (ahbp0.hwrite),
      .HSIZEP                         (ahbp0.hsize),
      .HBURSTP                        (ahbp0.hburst),
      .HPROTP                         (ahbp0.hprot),
      .HMASTERP                       (ahbp0.hmaster[0]),
      .HADDRP                         (ahbp0.haddr),
      .HWDATAP                        (ahbp0.hwdata),
      .HREADYP                        (ahbp0.hready),
      .HRESPP                         (ahbp0.hresp),
      .HRDATAP                        (ahbp0.hrdata),
      .EXREQP                         (),
      .EXRESPP                        (1'b0),

      .HREADYOUTS                     (ahbs0.hready),
      .HRESPS                         (ahbs0.hresp),
      .HRDATAS                        (ahbs0.hrdata),
      .AHBSRDY                        (),
      .AHBSPRI                        (1'b0),
      .WABORTS                        (),
      .HREADYS                        (ahbs0.hreadym),
      .HSELS                          (ahbs0.hsel),
      .HTRANSS                        (ahbs0.htrans),
      .HWRITES                        (ahbs0.hwrite),
      .HSIZES                         (ahbs0.hsize),
      .HBURSTS                        (ahbs0.hburst),
      .HPROTS                         (ahbs0.hprot),
      .HADDRS                         (ahbs0.haddr),
      .HWDATAS                        (ahbs0.hwdata),

      .HREADYD                        (ahbd_hready),
      .HRESPD                         (ahbd_hresp),
      .HRDATAD                        (ahbd_hrdata),
      .HTRANSD                        (ahbd_htrans),
      .HWRITED                        (ahbd_hwrite),
      .HSIZED                         (ahbd_hsize|3'h0),
      .HBURSTD                        (ahbd_hburst),
      .HPROTD                         (ahbd_hprot),
      .HADDRD                         (ahbd_haddr),
      .HWDATAD                        (ahbd_hwdata),

      .PENABLE                        (),
      .PSEL                           (psel_cm7),
      .PADDR                          (paddr),
      .PADDR31                        (),
      .PWRITE                         (),
      .PWDATA                         (),
      .PREADY                         (pready_cm7),
      .PSLVERR                        (pslverr_cm7),
      .PRDATA                         (prdata_cm7[31:0]),

      .TRCENA                         (),
      .ATVALID                        (),
      .ATID                           (),
      .ATDATA                         (),
      .AFREADY                        (),     /* flush not supported by TPIU */
      .ATREADY                        (1'b1),
      .AFVALID                        (1'b0), /* flush not supported by TPIU */

      .ATREADYMI                      (1'b1),
      .AFVALIDMI                      (1'b0),
      .ATVALIDMI                      (),
      .AFREADYMI                      (),
      .ATDATAMI                       (),
      .ATIDMI                         (),

      .SYNCREQI                       (1'b0), /* not supported by TPIU */
      .SYNCREQD                       (1'b0), /* not supported by TPIU */

      .TRIGGER                        (),
      .DSYNC                          (),

      .TSVALUEB                       (TSVALUEB),
      .TSCLKCHANGE                    (1'b0),

      .HALTED                         (dbghalt),
      .DBGRESTARTED                   (),
      .DBGEN                          (cm7cfg_dev),
      .NIDEN                          (cm7cfg_dev),
      .EDBGRQ                         (1'b0),
      .DBGRESTART                     (1'b0),
      .IADDR                          (cm7top_IADDR[31:3]),  // this is not real pc
      .IADBGPROT                      (1'b0),

      .IRQ                            (cm7_irqreg|240'h0),
      .NMI                            (cm7_nmireg),

      .SLEEPING                       (cm7_sleeping),
      .SLEEPDEEP                      (cm7_sleepdeep),
      .GATEHCLK                       (cm7_gatehclk),
      .SLEEPHOLDACKn                  (),
      .SLEEPHOLDREQn                  (1'b1),
      .WAKEUP                         (),
      .WICSENSE                       (),
      .WICENREQ                       (1'b0),
      .WICENACK                       (),
      .ETMPWRUPREQ                    (),

      .LOCKUP                         (),
      .TXEV                           (),
      .ICERR                          (),
      .DCERR                          (),
      .ICDET                          (),
      .DCDET                          (),
      .RXEV                           (cm7_rxevreg),

      .FPIXC                          (),
      .FPIDC                          (),
      .FPOFC                          (),
      .FPUFC                          (),
      .FPDZC                          (),
      .FPIOC                          (),

      .CTICHIN                        ({4{1'b0}}),
      .CTICHOUT                       (),
      .CTIIRQ                         (),

      .MBISTACK                       (),
      .MBISTOUTDATA                   (),
      .MBISTIMPERR                    (),
      .nMBISTRESET                    (1'b1),
      .MBISTREQ                       (1'b0),
      .MBISTADDR                      ({21{1'b0}}),
      .MBISTINDATA                    ({78{1'b0}}),
      .MBISTWRITEEN                   (1'b0),
      .MBISTREADEN                    (1'b0),
      .MBISTARRAY                     ({5{1'b0}}),
      .MBISTBE                        ({10{1'b0}}),
      .MBISTCFG                       ({4{1'b0}}),

      .ECOREVNUM                      (ECOREVNUM[35:0]),

      .DCCMINP                        (8'h00),
      .DCCMOUT                        (),
      .DCCMINP2                       (8'h00),
      .DCCMOUT2                       (),

      .DFTSE                          (cmsatpg),
      .DFTRSTDISABLE                  (cmsatpg),
      .DFTRAMHOLD                     (cmsatpg),
      .CTLPPBLOCK                     (4'h0),

        .rbif_icache (rbif_rf1kx72        )  ,
        .rbif_itag   (rbif_rf256x27       )  ,
        .rbif_dcache (rbif_rf512x39       )  ,
        .rbif_dtag   (rbif_rf128x31       )  ,
        .cmsatpg, .cmsbist
    );

//  `theregrn(TSVALUEB) <= ~coreresetn ? 0 : ( TSVALUEB + 1 );
    bit TSVALUEBcarry;

    `theregrn(TSVALUEB[31:0]) <= ~coreresetn ? 0 : ( TSVALUEB[31:0] + 1 );
    `theregrn(TSVALUEBcarry) <= ~coreresetn ? 0 : ( TSVALUEB[31:0] == '1-1 );
    `theregrn(TSVALUEB[63:32]) <= ~coreresetn ? 0 : ( TSVALUEB[63:32] + TSVALUEBcarry );

    assign axim.arid[PM_AXIM_IDW-1:3] = '0;
    assign axim.awid[PM_AXIM_IDW-1:2] = '0;
    assign axim.aruser = AXIMID4 | '0;
    assign axim.awuser = AXIMID4 | '0;
    assign axim.arsize[2] = '0;
    assign axim.awsize[2] = '0;
    assign axim.wid = '0;
    assign axim.wuser = '0;

    assign axim.awlen = '0 | axim_AWLEN[2:0];
    assign axim.arlen = '0 | axim_ARLEN[2:0];

//    assign ahbp.hsel = 1'b1;
//    assign ahbp.hreadym = ahbp.hready ;
//    assign ahbp.hmasterlock = 1'b0;
//    assign ahbp.hauser = '0;
//    assign ahbp.hwuser = '0;
//    assign ahbs.hwuser = '0;

  // --------------------------------------------------------------------------
  // Cortex-M7 core user
  // --------------------------------------------------------------------------

  assign ahbp0.hreadym = ahbp0.hready ;
  assign ahbp0.hmasterlock = 1'b0;
  assign ahbp0.hsel = 1'b1;
  assign ahbp0.hmaster[3:1] = AHBPID4/2;
  assign ahbp0.hauser = AHBPID4;
  assign ahbs0.hruser = '0;

    ahb_sync#(
            .SYNCDOWN (1),
            .SYNCUP   (0),
            .MW       (4)
        ) ahbp_syncdown (
            .hclk       (clk        ),
            .resetn     (resetn     ),
            .hclken     (ahbpclken  ),
            .ahbslave   (ahbp0      ),
            .ahbmaster  (ahbpsim       )
        );

    ahb_sync#(
            .SYNCDOWN (0),
            .SYNCUP   (1),
            .MW       (4)
        )ahbs_syncup (
            .hclk       (clk        ),
            .resetn     (resetn     ),
            .hclken     (ahbsclken  ),
            .ahbslave   (ahbs       ),
            .ahbmaster  (ahbs0      )
        );

    ahbsim #(.AW (32),.DW (32),.IDW(4),.UW (4)) ahbsim(.hclk(hclk),.resetn(resetn),.ahbs(ahbpsim),.ahbm(ahbp));


  // --------------------------------------------------------------------------
  // Cortex-M7 core user
  // --------------------------------------------------------------------------

    logic [31:0] corecm7pc;
    logic [PM_COREUSERCNT-1:0] coreuserreg0, coreuserreg1;
    logic coreuser_keep, coreuser_change, coreuser_unchange, coreuser_keepcnthit;
    logic [7:0] coreuser_keepcnt;

//    assign corecm7pc[31:0]  = {cm7top_IADDR[31:3],3'h0};//cm7top.u_cortexm7.u_top_sys.u_core.u_cm7_dpu.u_dpu_prog_flow.pc_r_ex1[31:1] * 2;
    assign corecm7pc[31:0]  = pcptr;

    genvar gvi;
    generate
        for( gvi = 0; gvi < PM_COREUSERCNT; gvi++ ) begin: GENCOREUSER
            `theregrn( coreuserreg0[PM_COREUSERCNT-gvi-1] ) <= ( corecm7pc >= coreusermap[gvi].start_addr) & ( corecm7pc < coreusermap[gvi].end_addr);
        end
    endgenerate

    `theregrn( coreuserreg1 ) <= coreuserreg0;
    assign coreuser_change = ~(coreuserreg1==coreuserreg0);
    assign coreuser_unchange = (coreuserreg1==coreuserreg0);
    `theregrn( coreuser_keepcnt ) <= coreuser_change ? '0 : ~coreuser_keep ? coreuser_keepcnt + 1 : coreuser_keepcnt;
    `theregrn( coreuser_keep ) <= coreuser_change ? '0 : coreuser_keepcnthit ? '1 : coreuser_keep;
    assign coreuser_keepcnthit = (coreuser_keepcnt == coreuser_filtercyc);

    `theregrn(coreuser) <= coreuser_keepcnthit ? coreuserreg0 : coreuser;

  // --------------------------------------------------------------------------
  // Cortex-M7 Debug Access Port
  // --------------------------------------------------------------------------

  //DAP Tie-offs
  wire [31:0] dap_baseaddr    = BASEADDR;
  wire [31:0] dap_targetid    = TARGETID;
  wire [ 7:0] dap_ecorevnum   = ECOREVNUM[43:36];

  //Synchronise the DAP resets

  wire apreset_n;
  wire dpreset_n;
  wire pre_mux_apreset_n;
  wire pre_mux_dpreset_n;

  cm7cell_sync
  u_cm7cell_sync_apreset
    (
      .clk_i                          (clkcm7in),
      .inp_i                          (nPORESET),
      .resetn_i                       (nPORESET),
      .out_o                          (pre_mux_apreset_n)
    );

  cm7cell_sync
  u_cm7cell_sync_dpreset
    (
      .clk_i                          (swclk),
      .inp_i                          (nPORESET),
      .resetn_i                       (nPORESET),
      .out_o                          (pre_mux_dpreset_n)
    );

  assign apreset_n = cmsatpg | pre_mux_apreset_n;
  assign dpreset_n = cmsatpg | pre_mux_dpreset_n;

  bit swdio_oen, swdio_pi, swdio_po;

   wire cdbgpwrupreq_s;
   wire CDBGPWRUPACK, CDBGPWRUPREQ;
   wire   nxt_cdbgpwrupack  = cdbgpwrupreq_s ;
   wire   up_cdbgpwrupack   = ((cdbgpwrupreq_s   ^ CDBGPWRUPACK) &
                              (nxt_cdbgpwrupack ^ CDBGPWRUPACK));

   cm7_pmu_cdc_send_reset
     u_cdbgpwrupack
       (.REGCLK     (clk),
        .REGRESETn  (nPORESET),
        .REGEN      (up_cdbgpwrupack),
        .REGDI      (nxt_cdbgpwrupack),
        .REGDO      (CDBGPWRUPACK));

   cm7_pmu_sync_reset
     u_dbg_pupreq_sync
       (.SYNCRSTn (nPORESET),
        .SYNCCLK  (clk),
        .SYNCDI   (CDBGPWRUPREQ),
        .SYNCDO   (cdbgpwrupreq_s));

  CM7DAP
    #(
      .SWMD                           (SWMD),
      .RAR                            (RAR)
    )
  u_cm7dap
    (
      .SWCLKTCK                       (swclk),
      .DPRESETn                       (dpreset_n),
      .DCLK                           (clkcm7in),
      .APRESETn                       (apreset_n),

      .nTRST                          (1'b0),
      .TDI                            (1'b0),
      .TDO                            (),
      .nTDOEN                         (),

      .SWDITMS                        (swdio_pi & cm7cfg_dev),
      .SWDO                           (swdio_po),
      .SWDOEN                         (swdio_oen),
      .SWDETECT                       (), /*deliberately unconnected*/

      .HALTED                         (dbghalt),

      .CDBGPWRUPREQ                   (CDBGPWRUPREQ),
      .CDBGPWRUPACK                   (CDBGPWRUPACK),

      .DEVICEEN                       (cm7cfg_dev),

      .SLVADDR                        (ahbd_haddr),
      .SLVWDATA                       (ahbd_hwdata),
      .SLVTRANS                       (ahbd_htrans),
      .SLVPROT                        (ahbd_hprot),
      .SLVWRITE                       (ahbd_hwrite),
      .SLVSIZE                        (ahbd_hsize),
      .SLVRDATA                       (ahbd_hrdata),
      .SLVREADY                       (ahbd_hready),
      .SLVRESP                        (ahbd_hresp),

      .CFGJTAGnSW                     (1'b0),
      .BASEADDR                       (dap_baseaddr),
      .TARGETID                       (dap_targetid),
      .INSTANCEID                     (4'h0),
      .ECOREVNUM                      (dap_ecorevnum),

      .DFTSE                          (cmsatpg)
    );


  //Cortex-M7 DAP does not generate bursts
  assign ahbd_hburst = 3'b000;
  assign swdio.oe = swdio_oen;
  assign swdio.po = swdio_po;
  assign swdio_pi = swdio.pi;
  assign swdio.pu = 1'b1;

  // --------------------------------------------------------------------------
  // ROM Table for the MCU Integration Level
  // --------------------------------------------------------------------------

  cm7_cs_apb_rom_table
    #(
      // --------------------------------------------------------------------------
      // Modify below 4 parameters to set the System ROM Table
      // Manufacturer, Part Number and Revision
      // --------------------------------------------------------------------------
      .JEPID                         (JEPID),
      .JEPCONTINUATION               (JEPCONT),
      .PARTNUMBER                    (PARTNUM),
      .REVISION                      (4'h0),
      // --------------------------------------------------------------------------
      // ROM BASE
      .BASE                          (SYSROMTABLEBASE),
      // Entry 0 = Cortex-M7 Processor ROM Table
      .ENTRY0BASEADDR                (CM7ROMTABLEBASE),
      .ENTRY0PRESENT                 (1'b1),
      // Entry 1 = TPIU
      .ENTRY1BASEADDR                (TPIUBASE),
      .ENTRY1PRESENT                 (1'b1)
      )
  u_mcu_rom_table
    (// OUTPUTS
     .PRDATADBG                      (prdata_mcu_rom_table[31:0]),
     // INPUTS
     .PSELDBG                        (psel_mcu_rom_table),
     .PADDRDBG                       (paddr[11:2]),
     .ECOREVNUM                      (ECOREVNUM[51:48])
    );

  // --------------------------------------------------------------------------
  // APB Component Slave Port Decoding and MUXing
  // --------------------------------------------------------------------------

  cm7_mcu_apb_interconnect
    #(
      .SYSROMTABLEBASE                (SYSROMTABLEBASE),
      .TPIUBASE                       (TPIUBASE)
     )
  u_interconnect
    (// OUTPUTS
      .psel0                          (psel_mcu_rom_table),
      .psel1                          (psel_tpiu),
      .psel2                          (),
      .pready                         (pready_cm7),
      .prdata                         (prdata_cm7[31:0]),
      .pslverr                        (pslverr_cm7),
      // INPUTS
      .paddr                          (paddr[19:12]),
      .psel                           (psel_cm7),
      .pready0                        (1'b1),
      .prdata0                        (prdata_mcu_rom_table[31:0]),
      .pslverr0                       (1'b0),
      .pready1                        ('1),
      .prdata1                        ('0),
      .pslverr1                       ('0),
      .pready2                        ('1),
      .prdata2                        ('0),
      .pslverr2                       ('0)
    );


//    assign pready_cm7 = 1'b1;
//    assign prdata_cm7 = '0;
//    assign pslverr_cm7 = '0;

//-----------------------------------------------------------------------------
// TCMs
//-----------------------------------------------------------------------------

// ITCM

/*
// fake long jump
    bit         fakelongen;
    bit [63:0]  fakelonginstr;
    assign fakelonginstr = ###;cfg_initvtor
    `theregsn( fakelongen ) <= ~( axim.ar_valid & axim.ar_ready );
     assign sys_itcmrdata = fakelongen ? fakelonginstr : sys_itcmrdata0;
*/
     assign sys_itcmrdata = sys_itcmrdata0;

  cm7sys_tcm
   #(
      .itcm   ('1),
      .thecfg (itcmcfg),
      .RC     (itcmrc)
    )
  u_itcm_ram
    (.clk        (clkcm7in),
     .clktop     (clktop),
     .clken      (fclken),
     .cmsatpg    (cmsatpg),
     .cmsbist    (cmsbist),
     .rbs        (rbif_itcm32kx18),
     .waitcyc    (cm7cfg_itcmwaitcyc),
     .sramtrm    (cm7cfg_itcmsramtrm),
     .even       (tcmeven),
     .resetn     (resetn),

     .addr_i     (sys_itcmaddr[itcmcfg.AW+3-1:3]),
     .wd_i       (sys_itcmwdata[63:0]),
     .cs_i       (sys_itcmcs),
     .we_i       (sys_itcmbytewr[7:0]),
     .rd_o       (sys_itcmrdata0[63:0]),
     .wait_o     (sys_itwait),
     .err_o      (sys_iterr),
     .retry_o    (sys_itretry)
     );

// D0TCM

  cm7sys_tcm
   #(
      .itcm   ('0),
      .thecfg (dtcmcfg),
      .RC     (dtcmrc)
    )
  u_d0tcm_ram
    (.clk        (clkcm7in),
     .clktop     (clktop),
     .clken      (fclken),
     .cmsatpg    (cmsatpg),
     .cmsbist    (cmsbist),
     .rbs        (rbif_dtcm8kx36[0:0]),
     .waitcyc    (cm7cfg_dtcmwaitcyc),
     .sramtrm    (cm7cfg_dtcmsramtrm),
     .even       (tcmeven),
     .resetn     (resetn),

     .addr_i     (sys_d0tcmaddr[dtcmcfg.AW+3-1:3]),
     .wd_i       (sys_d0tcmwdata[31:0]),
     .cs_i       (sys_d0tcmcs),
     .we_i       (sys_d0tcmbytewr[3:0]),
     .rd_o       (sys_d0tcmrdata[31:0]),
     .wait_o     (sys_d0wait),
     .err_o      (sys_d0err),
     .retry_o    (sys_d0retry)
     );

// D1TCM

  cm7sys_tcm
   #(
      .itcm   ('0),
      .thecfg (dtcmcfg),
      .RC     (dtcmrc)
    )
  u_d1tcm_ram
    (.clk        (clkcm7in),
     .clktop     (clktop),
     .clken      (fclken),
     .cmsatpg    (cmsatpg),
     .cmsbist    (cmsbist),
     .rbs        (rbif_dtcm8kx36[1:1]),
     .waitcyc    (cm7cfg_dtcmwaitcyc),
     .sramtrm    (cm7cfg_dtcmsramtrm),
     .even       (tcmeven),
     .resetn     (resetn),

     .addr_i     (sys_d1tcmaddr[dtcmcfg.AW+3-1:3]),
     .wd_i       (sys_d1tcmwdata[31:0]),
     .cs_i       (sys_d1tcmcs),
     .we_i       (sys_d1tcmbytewr[3:0]),
     .rd_o       (sys_d1tcmrdata[31:0]),
     .wait_o     (sys_d1wait),
     .err_o      (sys_d1err),
     .retry_o    (sys_d1retry)
     );

endmodule : cm7sys

/*


module __dummy_tb_cm7sys_ ();

ioif swdio();
axiif axim();
ahbif ahbp(), ahbs();
    rbif #(.AW(10   ),      .DW(72))    rbif_rf1kx72        [0:1]   ();
    rbif #(.AW(8    ),      .DW(27))    rbif_rf256x27       [0:1]   ();
    rbif #(.AW(9    ),      .DW(39))    rbif_rf512x39       [0:7]   ();
    rbif #(.AW(7    ),      .DW(31))    rbif_rf128x31       [0:3]   ();
    rbif #(.AW(13   ),      .DW(36))    rbif_dtcm8kx36      [0:1]   ();
    rbif #(.AW(15   ),      .DW(18))    rbif_itcm32kx18     [0:3]   ();

cm7sys u1
(

// system ctrl
    .clk('0),            // Free running clock
    .clktop('0),
    .fclken('0),
    .resetn('0),
    .coreresetn('0),

    .cm7_resetreq(),
    .cm7_sleep(),
    .clkcm7sten_1M('0),

// cfg
    .cm7cfg_dev('0),
    .cm7cfg_iv('0),// = 32'h6000_0000;
    .cm7cfg_itcmwaitcyc('0),
    .cm7cfg_dtcmwaitcyc('0),
    .cm7cfg_itcmsramtrm('0),
    .cm7cfg_dtcmsramtrm('0),
    .cm7cfg_cachesramtrm('0),

// test mode
    .cmsatpg('0),
    .cmsbist('0),
//    mbist.master                mbistif,
    .rbif_rf1kx72    ,
    .rbif_rf256x27   ,
    .rbif_rf512x39   ,
    .rbif_rf128x31   ,
    .rbif_dtcm8kx36  ,
    .rbif_itcm32kx18 ,

// interrupt, nmi, events
    .cm7_irq('0),
    .cm7_nmi('0),
    .cm7_rxev('0),

// amba
    .aximclken('0),       // axi clk enable
    .ahbpclken('0),
    .ahbsclken('0),
    .axim(axim),
    .ahbp(ahbp),
    .ahbs(ahbs),

// coreuser
    .coreusermap('0),
    .coreuser(),

// debug
    .swclk('0),
    .swdio(swdio)

);

axis_null u0(axim);
ahbs_null u2(ahbp);
ahbm_null u3(ahbs);


endmodule


*/
