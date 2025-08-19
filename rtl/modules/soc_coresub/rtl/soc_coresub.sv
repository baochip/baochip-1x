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
//`include "io_interface_def_v0.1.sv"

import daric_cfg::*;
import rrc_pkg::*;
//import cms_pkg::*;

module soc_coresub #(
    parameter BRC  = daric_cfg::BRC,
    parameter BRCW = daric_cfg::BRCW,
    parameter BRDW = daric_cfg::BRDW,
    parameter IRQCNT = daric_cfg::IRQCNT-16
)(

    input wire        ana_rng_0p1u,

//    input   logic   clktop,

    input   logic   fclk,
    input   logic   aclk,
    input   logic   hclk,
    input   logic   iclk,
//    input   logic   pclk,
    input   logic   clktop,
    input   logic   clktopen,
    input   logic   fclken,
//    input   logic   pclken,

    input   logic   clksys,
    input   logic   ref1M,
    input   logic   clkocc_rrc,


//    input   logic   clkcore,
    input   logic   clkdma,
    input   logic   clksce,
    input   logic   clkqfc,
    input   logic   clkvex,
    input   logic   clksceen,
    input   logic   clkpke,
    input   logic   clkmboxgate,

    input   logic   aximclken,
    input   logic   ahbpclken,
    input   logic   ahbsclken,

    input   logic   sysresetn,
    input   logic   coreresetn,

`ifdef FPGA
    input   logic   coresel_cm7,
`endif
    output  logic   cm7sleep,
    output  logic   cm7resetreq,
    input   logic [IRQCNT-1:0]  cm7_irq,
    input   logic   cm7_nmi,
    input   logic   cm7_rxev,
    output  logic [31:0]    coresubevo,
    output  logic           coresuberro,
    output  logic [31:0]    sceevo,
    output  logic           sceerro,

    input   logic           rramsleep,
    input   logic [15:0]    rrc_ev,
// cms
//    output cmsdata_e            cmsdata,
//    output logic                cmsdatavld,

    input  logic [3:0]          brready,
    output logic                brvld,
    output logic [BRCW-1:0]     bridx,
    output logic [BRDW-1:0]     brdat,
    output logic                brdone,

    input   cms_pkg::cmscode_e   cmscode,
    input   logic       cmsatpg,
    input   logic       cmsbist,

    rbif.slave rbif_ram32kx72      [0:3]  ,
    rbif.slave rbif_ram8kx72       [0:15] ,

    rbif.slave rbif_rf1kx72        [0:1]  ,
    rbif.slave rbif_rf256x27       [0:1]  ,
    rbif.slave rbif_rf512x39       [0:7]  ,
    rbif.slave rbif_rf128x31       [0:3]  ,
    rbif.slave rbif_dtcm8kx36      [0:1]  ,
    rbif.slave rbif_itcm32kx18     [0:3]  ,

    rbif.slave   rbif_sce_sceram_10k [0:0]  ,
    rbif.slave   rbif_sce_hashram_3k [0:0]  ,
    rbif.slave   rbif_sce_aesram_1k  [0:0]  ,
    rbif.slave   rbif_sce_pkeram_4k  [0:1]  ,
    rbif.slave   rbif_sce_aluram_3k  [0:1]  ,
    rbif.slavedp rbif_sce_mimmdpram  [0:0]  ,

    rbif.slavedp rbif_rdram1kx32     [0:5]  ,
    rbif.slavedp rbif_rdram512x64    [0:3]  ,
    rbif.slavedp rbif_rdram128x22    [0:7]  ,
    rbif.slavedp rbif_rdram32x16     [0:1]  ,

    rbif.slavedp rbif_tx_fifo128x32  [0:0]  ,
    rbif.slavedp rbif_rx_fifo128x32  [0:0]  ,
    rbif.slavedp rbif_fifo32x19      [0:0]  ,

    rbif.slave rbif_acram2kx64     [0:0]  ,
    output logic aorameven, iframeven,

//    rbif.slave rbif_ifram32kx36    [0:1]  ,
//    rbif.slave rbif_udcmem_share   [0:0]  ,
//    rbif.slave rbif_udcmem_odb     [0:0]  ,
//    rbif.slave rbif_udcmem_256x64  [0:0]  ,
//    rbif.slave rbif_bioram1kx32    [0:3]  ,
//    rbif.slave rbif_aoram1kx36     [0:1]  ,

    input   nvrcfg_pkg::nvrcfg_t nvrcfgdata,

// qfc
    output padcfg_arm_t  padcfg_qfc_sck,
    output padcfg_arm_t  padcfg_qfc_qds,
    output padcfg_arm_t  padcfg_qfc_ss,
    output padcfg_arm_t  padcfg_qfc_sio,
//    output padcfg_arm_t  padcfg_qfc_rwds,
    output padcfg_arm_t  padcfg_qfc_int,
    output padcfg_arm_t  padcfg_qfc_rst,

    ioif.drive qfc_sck,
    ioif.drive qfc_sckn,
    ioif.drive qfc_dqs,
    ioif.drive qfc_ss[1:0],
    ioif.drive qfc_sio[7:0],
//    ioif.drive qfc_rwds,
    ioif.drive qfc_rstm[1:0],
    ioif.drive qfc_rsts[1:0],
    ioif.drive qfc_int,

//
    jtagif.slave        jtagvex,
    jtagif.slave        jtagrrc[0:1],

// bus
    ahbif.master        bmxif_ahb32,
    ahbif.master        coreahb_sys,
    ahbif.master        coreahb_sec,
    ahbif.master        coreahb_ao,

    ahbif.slave         bdma_ahb32,
    axiif.slave         bdma_axi32,

    input   logic       clkswd,
    ioif.drive          swdio,
    output logic iptorndlf, iptorndhf,
    input   logic [6:0] ipt_rngcfg,

// analog interfaces

    inout   wire [0:1]  ana_reramtest,
    input   wire [0:1]  ana_rrpoc


);

    typedef axi_pkg::xbar_rule_32_t       rule32_t; // Has to be the same width as axi addr

    logic [3:0] clkcm7stenregs;
    logic clkcm7sten_1M;
    logic cm7cfg_dev, vexcfg_dev, cm7cfg_en, vexcfg_en ;
    logic [31:0] cm7cfg_iv, vexcfg_iv;
    logic [3:0]  srambankerr;
    logic [1:0] vexcfg_def_user;
    logic       vexcfg_def_mm;
    logic tcmeven, srameven;
//    logic cmsatpg, cmsbist;
//    logic [IRQCNT-1:0]  cm7_irq;
//    logic cm7_nmi, cm7_rxev;
//    logic aximclken, ahbpclken, ahbsclken;
    axiif #(.AW(32),.DW(32),.IDW(5),.LENW(8),.UW(8)) sce_axi32[0:1]();
    axiif #(.AW(32),.DW(64),.IDW(8),.LENW(8),.UW(8)) cm7_axim();
    axiif #(.AW(32),.DW(64),.IDW(8),.LENW(8),.UW(8)) vex_iaxi();
    axiif #(.AW(32),.DW(32),.IDW(8),.LENW(8),.UW(8)) vex_daxi();
    axiif #(.AW(32),.DW(64),.IDW(9),.LENW(8),.UW(8)) rrc_axi64(), sram_axi64[0:1](), qfc_axi64();

    ahbif #(.AW(32),.DW(32),.IDW(4),.UW(4))
        cm7_ahbp(), cm7_ahbs(), mdma_ahb32(), core_ahb32(), coreahbmux[0:6]();

    ramif #(.RAW(20-3), .DW(64)//, .BW(8)
        ) sramc_uncut[0:1](), sramc[0:1]();

    apbif #(.PAW(16)) coresubapb();
    apbif #(.PAW(12)) coresubapbs[0:15]();

    ahbif #(.AW(32),.DW(32),.IDW(4),.UW(4))
        vex_ahbp();

// parameters


// clk/resetn
    logic clkaxi, clkahb, clkif, resetn;
    logic rrcint;
    logic pclk, pclken;

    assign pclk = hclk;
    assign pclken = 1'b1; // coresub apb has same freq

//    assign clkcore = fclk;
    assign clkaxi = aclk;
    assign clkahb = hclk;
//    assign clksce = hclk;
    assign clkif  = iclk;
    assign resetn = sysresetn;

    `theregfull(fclk, resetn, clkcm7stenregs, '0) <= { clkcm7stenregs, ref1M };
    `theregfull(fclk, resetn, clkcm7sten_1M, '0) <= clkcm7stenregs[3] & ~clkcm7stenregs[2];

// ■■■■■■■■■■■
// corecfg
// ■■■■■■■■■■■

    localparam RERAMUSERCNT = 4;
    localparam PM_COREUSERCNT = daric_cfg::CODEMEMCNT + RERAMUSERCNT;
    localparam rule32_t [daric_cfg::CODEMEMCNT-1:0] code_mem_map = daric_cfg::code_mem_map;
    localparam rule32_t [6:0] coreahb_demux_map = daric_cfg::coreahb_demux_map;

    rule32_t    [PM_COREUSERCNT-1:0] coreusermap_cm7, coreusermap_vex;
    bit         [PM_COREUSERCNT-1:0] coreuser, coreuser_vex, sceuser;
    bit vex_mm;
    bit corecfg_devreg, cm7cfg_enreg, vexcfg_enreg;
    logic [7:0] cm7cfg_iv_8b, vexcfg_iv_8b;
    logic [7:0] coreuser_filtercyc;
    logic qfc_en;

    assign coreusermap_cm7[PM_COREUSERCNT-1:daric_cfg::CODEMEMCNT] = '{
        '{idx: 32'd7 , start_addr: `ambarrb(nvrcfgdata.cfgrrsub.m7_fw1_start),   end_addr: `ambarrb(nvrcfgdata.cfgrrsub.m7_fw1_end)    }, // fw1
        '{idx: 32'd6 , start_addr: `ambarrb(nvrcfgdata.cfgrrsub.m7_fw0_start),   end_addr: `ambarrb(nvrcfgdata.cfgrrsub.m7_fw1_start)  }, // fw0
        '{idx: 32'd5 , start_addr: `ambarrb(nvrcfgdata.cfgrrsub.m7_boot1_start), end_addr: `ambarrb(nvrcfgdata.cfgrrsub.m7_fw0_start)  }, // boot1
        '{idx: 32'd4 , start_addr: `ambarrb(nvrcfgdata.cfgrrsub.m7_boot0_start), end_addr: `ambarrb(nvrcfgdata.cfgrrsub.m7_boot1_start)}  // boot0
    };
    assign coreusermap_cm7[daric_cfg::CODEMEMCNT-1:0] = code_mem_map;

    assign coreusermap_vex[PM_COREUSERCNT-1:daric_cfg::CODEMEMCNT] = '{
        '{idx: 32'd7 , start_addr: `ambarrb(nvrcfgdata.cfgrrsub.rv_fw1_start),   end_addr: `ambarrb(nvrcfgdata.cfgrrsub.rv_fw1_end)    }, // fw1
        '{idx: 32'd6 , start_addr: `ambarrb(nvrcfgdata.cfgrrsub.rv_fw0_start),   end_addr: `ambarrb(nvrcfgdata.cfgrrsub.rv_fw1_start)  }, // fw0
        '{idx: 32'd5 , start_addr: `ambarrb(nvrcfgdata.cfgrrsub.rv_boot1_start), end_addr: `ambarrb(nvrcfgdata.cfgrrsub.rv_fw0_start)  }, // boot1
        '{idx: 32'd4 , start_addr: `ambarrb(nvrcfgdata.cfgrrsub.rv_boot0_start), end_addr: `ambarrb(nvrcfgdata.cfgrrsub.rv_boot1_start)}  // boot0
    };
    assign coreusermap_vex[daric_cfg::CODEMEMCNT-1:0] = code_mem_map;

    assign cm7cfg_iv_8b    = nvrcfgdata.cfgrrsub.m7_init;
    assign vexcfg_iv_8b    = nvrcfgdata.cfgrrsub.rv_init;
    assign cm7cfg_iv    = `ambarrb(cm7cfg_iv_8b);//{ 10'b0110_0000_00, cm7cfg_iv_8b, 14'h0 };
    assign vexcfg_iv    = `ambarrb(vexcfg_iv_8b);//{ 10'b0110_0000_00, vexcfg_iv_8b, 14'h0 };

    assign cm7cfg_dev   = corecfg_devreg & cm7cfg_en;
    assign vexcfg_dev   = corecfg_devreg & vexcfg_en;

    `theregfull( hclk, resetn, corecfg_devreg , '0 ) <= ( nvrcfgdata.cfgcore.devena     == nvrcfg_pkg::cpudevmode );
    `theregfull( hclk, resetn, cm7cfg_enreg   , '0 ) <= ( nvrcfgdata.cfgcore.coreselcm7 == nvrcfg_pkg::coreselcm7_code );
    `theregfull( hclk, resetn, vexcfg_enreg   , '0 ) <= ( nvrcfgdata.cfgcore.coreselvex == nvrcfg_pkg::coreselvex_code );
    `theregfull( hclk, resetn, coreuser_filtercyc   , '0 ) <= nvrcfgdata.cfgcore.coreuser_filtercyc;

    assign vexcfg_def_mm = nvrcfgdata.cfgrrsub.rv_def_mm;
    assign vexcfg_def_user = nvrcfgdata.cfgrrsub.rv_def_user;

`ifdef FPGA
    assign cm7cfg_en =  coresel_cm7;
    assign vexcfg_en = ~coresel_cm7;
`else
    assign cm7cfg_en = ~vexcfg_enreg | cm7cfg_enreg;
    assign vexcfg_en =  vexcfg_enreg;
`endif

    `theregfull( pclk, resetn, qfc_en, '1 ) <= ( nvrcfgdata.cfgcore.qfc_disable == 'h0 );

// ■■■■■■■■■■■
// cm7sys/vexsys
// ■■■■■■■■■■■


    logic fclk_cm7, clktop_cm7, clkswd_cm7, sysresetn_cm7, coreresetn_cm7;
    logic resetn_vex;
    logic   [0:3]  mbox_irq;

    logic [2:0] cm7cfg_itcmsramtrm, cm7cfg_dtcmsramtrm, cm7cfg_cachesramtrm, sram0sramtrm, sram1sramtrm, vexsramtrm;
    logic [1:0] cm7cfg_itcmwaitcyc, cm7cfg_dtcmwaitcyc, sram0waitcyc, sram1waitcyc;

generate
    if(1) begin: __coresys

    ICG cm7en_icg0 (.CK (fclk),   .EN (cm7cfg_en),.SE(cmsatpg),.CKG(fclk_cm7));
    ICG cm7en_icg1 (.CK (clktop), .EN (cm7cfg_en),.SE(cmsatpg),.CKG(clktop_cm7));
    ICG cm7en_icg2 (.CK (clkswd), .EN (cm7cfg_en),.SE(cmsatpg),.CKG(clkswd_cm7));
    assign sysresetn_cm7  = cmsatpg ? 1'b1 : sysresetn  & cm7cfg_en;
    assign coreresetn_cm7 = cmsatpg ? 1'b1 : coreresetn & cm7cfg_en;

//    ICG vexen_icg0 (.CK (clkvex),   .EN ( vexcfg_en),.SE(cmsatpg),.CKG(clk_vex0));
    assign resetn_vex  = cmsatpg ? 1'b1 : coreresetn  & vexcfg_en;

    cm7sys #(
        .PM_COREUSERCNT    (PM_COREUSERCNT),
        .PM_CFGITCMSZ      (daric_cfg::CFGITCMSZ),
        .PM_CFGDTCMSZ      (daric_cfg::CFGDTCMSZ),
        .FPU        (daric_cfg::CM7CFG.FPU        ),
        .ICACHE     (daric_cfg::CM7CFG.ICACHE     ),
        .DCACHE     (daric_cfg::CM7CFG.DCACHE     ),
        .CACHEECC   (daric_cfg::CM7CFG.CACHEECC   ),
        .MPU        (daric_cfg::CM7CFG.MPU        ),
        .IRQNUM     (daric_cfg::CM7CFG.IRQNUM     ),
        .IRQLVL     (daric_cfg::CM7CFG.IRQLVL     ),
        .ICACHESIZE (daric_cfg::CM7CFG.ICACHESIZE ),
        .DCACHESIZE (daric_cfg::CM7CFG.DCACHESIZE ),
        .dtcmrc     (daric_cfg::dtcmrc            ),
        .dtcmcfg    (daric_cfg::dtcmcfg           ),
        .itcmrc     (daric_cfg::itcmrc            ),
        .itcmcfg    (daric_cfg::itcmcfg           ),
        .AXIMID4    (daric_cfg::AMBAID4_CM7A),
        .AHBPID4    (daric_cfg::AMBAID4_CM7P)
    )
    cm7sys
    (
    // system ctrl
        .clk            (fclk_cm7       ),
        .clktop         (clktop_cm7     ),
        .fclken,.hclk,

        .resetn         (sysresetn_cm7  ),
        .coreresetn     (coreresetn_cm7 ),
        .cm7_resetreq   (cm7resetreq    ),
        .cm7_sleep      (cm7sleep       ),
        .clkcm7sten_1M  (clkcm7sten_1M  ),
    // cfg
        .cm7cfg_dev     (cm7cfg_dev),
        .cm7cfg_iv      (cm7cfg_iv),// = 32'h6000_0000;
        .cm7cfg_itcmwaitcyc(cm7cfg_itcmwaitcyc),
        .cm7cfg_dtcmwaitcyc(cm7cfg_dtcmwaitcyc),
        .cm7cfg_itcmsramtrm (cm7cfg_itcmsramtrm),
        .cm7cfg_dtcmsramtrm (cm7cfg_dtcmsramtrm),
        .cm7cfg_cachesramtrm(cm7cfg_cachesramtrm),
        .tcmeven,
    // test mode
        .cmsatpg,
        .cmsbist,
        .rbif_rf1kx72    ,
        .rbif_rf256x27   ,
        .rbif_rf512x39   ,
        .rbif_rf128x31   ,
        .rbif_dtcm8kx36  ,
        .rbif_itcm32kx18 ,
    //    mbist.master                mbistif,
    // interrupt, nmi, events
        .cm7_irq,
        .cm7_nmi,
        .cm7_rxev,
    // amba
        .aximclken      ,       // axi clk enable
        .ahbpclken      ,
        .ahbsclken      ,
        .axim           (cm7_axim       ),
        .ahbp           (cm7_ahbp       ),
        .ahbs           (cm7_ahbs       ),
    // coreuser
        .coreusermap    (coreusermap_cm7    ),
        .coreuser       (coreuser       ),
        .coreuser_filtercyc (coreuser_filtercyc),
    // debug
        .swclk          (clkswd_cm7     ),
        .swdio          (swdio          )
    );

// vexsys
    logic   [31:0] mbox_w_dat;
    logic          mbox_w_valid;
    logic          mbox_w_ready;
    logic          mbox_w_done;
    logic   [31:0] mbox_r_dat;
    logic          mbox_r_valid;
    logic          mbox_r_ready;
    logic          mbox_r_done;
    logic          mbox_w_abort;
    logic          mbox_r_abort;

    vexsys #(
        .PM_COREUSERCNT    (PM_COREUSERCNT),
//        .PM_COREUSERCNT(1),
        .IRQNUM        (IRQCNT+16),
        .AXIIID4       (daric_cfg::AMBAID4_VEXI),
        .AXIDID4       (daric_cfg::AMBAID4_VEXD),
        .AHBPID4       (daric_cfg::AMBAID4_VEXP)
        )vexsys(
        /*input   logic             */  .clk            (aclk),            // Free running clock
        /*input   logic             */  .resetn         (resetn_vex),
        /*input   logic             */  .ahbpclken      ,
        /*input   logic             */  .cmsatpg        ,
        /*input   logic             */  .cmsbist        ,
                                        .rbif_rdram1kx32   ,
                                        .rbif_rdram512x64  ,
                                        .rbif_rdram128x22  ,
                                        .rbif_rdram32x16   ,
                                        .vexsramtrm,
                                        .vexcfg_en      (vexcfg_en),
        /*input   logic             */  .vexcfg_dev     ,
        /*input   logic [31:0]      */  .vexcfg_iv      ,// = 32'h6000_0000;
        /*input   logic [IRQNUM-1:0]*/  .vex_irq        ({cm7_irq,16'h0}),
        /*axiif.master              */  .iaxim          (vex_iaxi),
        /*axiif.master              */  .daxim          (vex_daxi),
        /*ahbif.master              */  .ahbp           (vex_ahbp),
        /*output  logic             */  .coreuser       (coreuser_vex),//##
        /*output  logic             */  .machinemode    (vex_mm),//##
                                        .default_user   (vexcfg_def_user),
                                        .default_mm     (vexcfg_def_mm),
        .mbox_w_dat,
        .mbox_w_valid,
        .mbox_w_ready,
        .mbox_w_done,
        .mbox_r_dat,
        .mbox_r_valid,
        .mbox_r_ready,
        .mbox_r_done,
        .mbox_w_abort,
        .mbox_r_abort,
        .jtags (jtagvex)
    );

    logic aclkmbox; ICG icg_mbox_aclk ( .CK (aclk), .EN ( clkmboxgate ), .SE(cmsatpg), .CKG ( aclkmbox ));
    logic hclkmbox; ICG icg_mbox_hclk ( .CK (hclk), .EN ( clkmboxgate ), .SE(cmsatpg), .CKG ( hclkmbox ));

    logic resetnmbox;
    assign resetnmbox = cmsatpg ? 1'b1 : resetn;

    mbox_apb #() mbox_apb(
        .aclk    (aclkmbox),
        .pclk    (hclkmbox),
        .resetn  (resetnmbox),
        .cmatpg  (cmsatpg),
        .cmbist  (cmsbist),
        .sramtrm (vexsramtrm),

        .mbox_w_dat,
        .mbox_w_valid,
        .mbox_w_ready,
        .mbox_w_done,
        .mbox_r_dat,
        .mbox_r_valid,
        .mbox_r_ready,
        .mbox_r_done,
        .mbox_w_abort,
        .mbox_r_abort,
        .irq_available (mbox_irq[0]),
        .irq_abort_init (mbox_irq[1]),
        .irq_abort_done (mbox_irq[2]),
        .irq_error (mbox_irq[3]),

        .apbs    (coresubapbs[3]),
        .apbx    (coresubapbs[3])
    );

    logic [3:0] ramsec;
    assign { aorameven, iframeven, tcmeven, srameven } = ramsec;

    coresub_sramtrm usramtrm(
        .clk (hclk),
        .resetn,
        .apbs    (coresubapbs[4]),
        .apbx    (coresubapbs[4]),
        .srambankerr (srambankerr),
        .itcmwaitcyc(cm7cfg_itcmwaitcyc),
        .dtcmwaitcyc(cm7cfg_dtcmwaitcyc),
        .itcmsramtrm (cm7cfg_itcmsramtrm),
        .dtcmsramtrm (cm7cfg_dtcmsramtrm),
        .cachesramtrm(cm7cfg_cachesramtrm),
        .sram0waitcyc,
        .sram1waitcyc,
        .sram0sramtrm,
        .sram1sramtrm,
        .vexsramtrm,
        .ramsec
        );

    end
endgenerate

// security crypto engine

//    axim_null usce_axis_null(.aximaster(sce_axi32));
//    ahbs_null usce_ahbs_null(.ahbslave(coreahbmux[2]));

    logic [7:0] sceintr, sceerrs;
    logic secmode;
    logic [255:0] truststate;
    logic scedevmode;

    assign sceevo[31:8] = '0;
    assign sceevo[7:0]  = sceintr;
    assign sceerro = |sceerrs;
    assign scedevmode = cm7cfg_dev|vexcfg_dev;

    sce #(
        .AXID ( daric_cfg::AMBAID4_SCEA ),
        .COREUSERCNT ( PM_COREUSERCNT ),
    //    parameter type coreuser_t = bit[0:COREUSERCNT-1],
        .INTC ( 8 ),
        .ERRC ( 8 ),
        .TSC(256)
    )sce(
        .ana_rng_0p1u(ana_rng_0p1u),
        .clk        (clksce),
`ifdef FPGA
        .clktop     (clksce),
        .clksceen   ('1),
//        .clkpke     (clksce),
        .clkpke   ('1),
`else
        .clktop     (clktop),
        .clksceen   (clksceen),
//        .clkpke     (clkpke),
        .clkpke   (clkpke),
`endif
        .resetn, .sysresetn,
        .cmsatpg, .cmsbist,
        .devmode             (scedevmode),
        .rbif_sce_sceram     (rbif_sce_sceram_10k[0] ),
        .rbif_sce_hashram    (rbif_sce_hashram_3k[0] ),
        .rbif_sce_aesram     (rbif_sce_aesram_1k[0]  ),
        .rbif_sce_pkeram     (rbif_sce_pkeram_4k  ),
        .rbif_sce_aluram     (rbif_sce_aluram_3k  ),
        .rbif_sce_mimmdpram  (rbif_sce_mimmdpram[0]  ),
        .coreuser_cm7   ( coreuser     ),
        .coreuser_vex   ( coreuser_vex ),
        .sceuser    ( sceuser  ),
        .secmode    ( secmode  ),
        .nvrcfg     ( nvrcfgdata.cfgsce ),
        .truststate ( truststate ),
        .iptorndlf, .iptorndhf,
        .ipt_rngcfg ( ipt_rngcfg ),
        .ahbs       ( coreahbmux[2] ),
        .axim       ( sce_axi32 ),

        .intr       ( sceintr ),
        .err        ( sceerrs )
    );

// main dma

//    ahbm_null mdma_ahb32_null(.ahbmaster(mdma_ahb32));
//    apbs_null mdma_apbs_null(.apbslave(coresubapbs[1]));

    logic mdmairq, mdmaerr;

    mdma #(
        .CHNLC      ( 8 ),
        .AHBMID4    ( daric_cfg::AMBAID4_MDMA ),
        .EVC        ( IRQCNT + 16 )
    )mdma(
        .clk        (clkdma),
        .resetn,

        .evin       ({cm7_irq,16'h0}),
        .irq        (mdmairq),
        .err        (mdmaerr),

        .ahbm       (mdma_ahb32),
        .apbs_dma   (coresubapbs[1]),
        .apbs       (coresubapbs[2]),
        .apbx       (coresubapbs[2])
    );

// bus matrix

generate
    if(1) begin: __bmx

    ahbif #(.AW(32),.DW(32),.IDW(4),.UW(4))
        core_ahbp3[0:2](), core_ahbp();

     bmxcore bmxcore
    (
/*    input bit           */.aclk           (aclk        ),
/*    input bit           */.hclk           (hclk        ),
/*    input bit           */.resetn         (resetn      ),
                            .cmsatpg        (cmsatpg     ),
/*    axiif.slave         */.cm7_axim       (cm7_axim    ),
                            .vex_iaxi,
                            .vex_daxi,
/*    ahbif.slave         */.cm7_ahbp       (core_ahbp   ),
/*    axiif.slave         */.sce_axi32      (sce_axi32  ),
/*    ahbif.slave         */.mdma_ahb32     (mdma_ahb32  ),
/*    ahbif.slave         */.bdma_ahb32     (bdma_ahb32  ),
/*    axiif.slave         */.bdma_axi32     (bdma_axi32  ),
/*    axiif.master        */.rrc_axi64      (rrc_axi64   ),
/*    axiif.master        */.sram0_axi64    (sram_axi64[0] ),
/*    axiif.master        */.sram1_axi64    (sram_axi64[1] ),
/*    axiif.master        */.qfc_axi64      (qfc_axi64   ),
/*    ahbif.master        */.cm7_ahbs       (cm7_ahbs    ),
/*    ahbif.master        */.core_ahb32     (core_ahb32  ),
/*    ahbif.master        */.bmxif_ahb32    (bmxif_ahb32 )
    );

    ahb_thru  _ahbp0( .ahbslave( cm7_ahbp ), .ahbmaster( core_ahbp3[0] ) );
    ahb_thru  _ahbp1( .ahbslave( vex_ahbp ), .ahbmaster( core_ahbp3[1] ) );
    ahbm_null _ahbp2( .ahbmaster( core_ahbp3[2] ) );

    ahb_mux3 #(
          .AW(32),
          .DW(32)
    )coreahbpmux(
          .hclk,
          .resetn,
          .ahbslave     (core_ahbp3),
          .ahbmaster    (core_ahbp)
    );

    ahb_demux_map #(
        .SLVCNT                 ( 7  ),
        .DW                     ( 32 ),
        .AW                     ( 32 ),
        .UW                     ( 4 ),
        .ADDRMAP                ( coreahb_demux_map )
    ) coreahb_mux (
        .hclk                   ( hclk    ),
        .resetn                 ( resetn  ),
        .ahbslave               ( core_ahb32 ),
        .ahbmaster              ( coreahbmux )
    );


    ahbs_null coreahbmux3_null(.ahbslave(coreahbmux[3]));

//    ahbs_null uapb_ahb_null(.ahbslave(coreahbmux[7]));
    apb_bdg #(.PAW(16)) u1(.ahbslave(coreahbmux[1]),.apbmaster(coresubapb),.hclk(hclk),.resetn(resetn),.pclken(pclken));

    ahb_thru coreahb4(.ahbslave(coreahbmux[4]), .ahbmaster(coreahb_sys));
    ahb_thru coreahb5(.ahbslave(coreahbmux[5]), .ahbmaster(coreahb_sec));
    ahb_thru coreahb6(.ahbslave(coreahbmux[6]), .ahbmaster(coreahb_ao));

    apb_mux #(.PAW(16),.DECAW(4)) coresubapbmux(
        .apbslave (coresubapb),
        .apbmaster(coresubapbs)
    );

    apbs_nulls #(.SLVCNT(16-5)) coresubapbs_null(.apbslave(coresubapbs[5:15]));

    end
endgenerate

generate
    if(1) begin: __sram
//
//sram0_axi64

    logic [1:0] sramcuten;
    logic [1:0][17:0] sramcut;

    axisramc64 #(.WCW(1))sramc0 (
        .clk                    ( aclk     ),
        .resetn                 ( resetn  ),
        .axislave               ( sram_axi64[0] ),
        .rammaster              ( sramc_uncut[0] )
    );

    axisramc64 #(.WCW(0))sramc1 (
        .clk                    ( aclk     ),
        .resetn                 ( resetn  ),
        .axislave               ( sram_axi64[1] ),
        .rammaster              ( sramc_uncut[1] )
    );

    ramcut #(.AW(20-3)) sramcut0(.ramaddrcut(sramcut[0]),.cuten(sramcuten[0]),.rams(sramc_uncut[0]),.ramm(sramc[0]));
    ramcut #(.AW(20-3)) sramcut1(.ramaddrcut(sramcut[1]),.cuten(sramcuten[1]),.rams(sramc_uncut[1]),.ramm(sramc[1]));

`ifdef FPGA

    assign sramcuten = '0;
    assign sramcut = '0;

    uram_cas #( .XX (4), .YY (8)) sram0 (
      .clk          (aclk),
      .resetn,
      .waitcyc      ('0),
      .rams         (sramc[0])
    );

    uram_cas #( .XX (4), .YY (8)) sram1 (
      .clk          (aclk),
      .resetn,
      .waitcyc      ('0),
      .rams         (sramc[1])
    );

`else

    assign sramcuten[0] = nvrcfgdata.cfgrrsub.sramcut[3];
    assign sramcuten[1] = nvrcfgdata.cfgrrsub.sramcut[7];
    assign sramcut[0] = {nvrcfgdata.cfgrrsub.sramcut[2:0],15'h0};
    assign sramcut[1] = {nvrcfgdata.cfgrrsub.sramcut[6:4],15'h0};

    core_srambank #(
        .RC     (daric_cfg::coresrammacrocnt0),
        .thecfg (daric_cfg::coresramcfg0)
    )sram0(
        .clk                    ( aclk ),
        .resetn,
        .cmsatpg,
        .cmsbist,
        .rbs      (rbif_ram32kx72),
        .sramtrm                (sram0sramtrm),
        .waitcyc                (sram0waitcyc),
        .scmbkey                ('0),
        .even                   (srameven),
        .prerr                  (srambankerr[0]),
        .verifyerr              (srambankerr[1]),
        .rams                   ( sramc[0] )
    );

    core_srambank #(
        .RC     (daric_cfg::coresrammacrocnt1),
        .thecfg (daric_cfg::coresramcfg1)
    )sram1(
        .clk                    ( aclk ),
        .resetn,
        .cmsatpg,
        .cmsbist,
        .rbs      (rbif_ram8kx72),
        .sramtrm                (sram1sramtrm),
        .waitcyc                (sram1waitcyc),
        .scmbkey                ('0),
        .even                   (srameven),
        .prerr                  (srambankerr[2]),
        .verifyerr              (srambankerr[3]),
        .rams                   ( sramc[1] )
    );
`endif

    end
endgenerate

// reram
/*
    bit [3:0]   cmsdatavldregs;
    assign cmsdatavld = cmsdatavldregs[3];
    assign cmsdata = CMSDAT_USERMODE;
    `theregfull(clksys, sysresetn, cmsdatavldregs, 4'h1 ) <= cmsdatavldregs * 2;
    axis_null urcc_axis_null(.axislave(rrc_axi64));
    ahbs_null urcc_ahbs_null(.ahbslave(coreahbmux[0]));
*/

//    logic [3:0]          brready;
//    logic                brvld;
//    logic [BRCW-1:0]     bridx;
//    logic [BRDW-1:0]     brdat;
////    logic                brdone;

//    jtagif jtagrrc[0:1]();

`ifdef FPGA

    logic rrcnmi = 0;

rrc #(
        .BRC  (BRC ),
        .BRCW (BRCW),
        .BRDW (BRDW)
    )rrc(
/*    input logic              */   .clk            (aclk           ),
/*    input logic              */   .clktop         (clktop         ),
/*    input logic              */   .clksys         (clksys         ),
/*    input logic              */   .clktopen       (clktopen       ),
/*    input logic              */   .sysresetn      (sysresetn      ),
/*    input logic              */   .coreresetn     (coreresetn     ),
/*    axiif.slave              */   .axis           (rrc_axi64      ),
/*    ahbif.slave              */   .ahbs           (coreahbmux[0]  ),
/*    input  logic [3:0]       */   .brready        (brready        ),
/*    output logic             */   .brvld          (brvld          ),
/*    output logic [BRCW-1:0]  */   .bridx          (bridx          ),
/*    output logic [BRDW-1:0]  */   .brdat          (brdat          ),
/*    output logic             */   .brdone         (brdone         ),
/*    output logic             */   .rrcint         (rrcint         )

);

`else

// reram x2
    rrc_pkg::rri_t [1:0] rri;
    rrc_pkg::rro_t [1:0] rro;

    logic clktop_rrc;
    logic [127:0] nvrcfgrrsub;
    logic rrcnmi;
    assign nvrcfgrrsub = nvrcfgdata.cfgrrsub;

logic clktop_unbuf;
CLKCELL_MUX2 mux_clktop_rrc (.A(clktop),.B(clktop),.S(cmsatpg),.Z(clktop_unbuf));//eco7 but eco back
CLKCELL_BUF buf_clktop_rrc(.A(clktop_unbuf),.Z(clktop_rrc));

rrc #(
        .BRC  (BRC ),
        .BRCW (BRCW),
        .BRDW (BRDW)
    )rrc(
/*    input logic              */   .clk            (aclk           ),
/*    input logic              */   .clktop         (clktop_rrc     ),
/*    input logic              */   .clksys         (clksys         ),
/*    input logic              */   .clken          (aximclken&fclken),
/*    input logic              */   .hclk           (hclk           ),
                                    .clkocc         (clkocc_rrc     ),
/*    input logic              */   .sysresetn      (sysresetn      ),
/*    input logic              */   .coreresetn     (coreresetn     ),
/*    axiif.slave              */   .axis           (rrc_axi64      ),
/*    ahbif.slavein            */   .ahbs           (coreahbmux[0]  ),  //ahb -acram, ->apb sfr
/*    ahbif.slave              */   .ahbx           (coreahbmux[0]  ),  //ahb -acram, ->apb sfr
/*    input  logic [3:0]       */   .brready        (brready        ),
/*    output logic             */   .brvld          (brvld          ),
/*    output logic [BRCW-1:0]  */   .bridx          (bridx          ),
/*    output logic [BRDW-1:0]  */   .brdat          (brdat          ),
/*    output logic             */   .brdone         (brdone         ),
/*    output logic             */   .rrcint         (rrcint         ),
                                    .rri                             ,
                                    .rro                             ,
                                    .rrcnmi(rrcnmi),
                                    .cm7cfg_en,
                                    .nvrcfgdata(nvrcfgdata),
                                    .trustkey       (truststate     ),  //tbd
                                    .sceuser        (sceuser        ),  //tbd
                                    .coreuser_cm7   (coreuser       ),
                                    .coreuser_vex   (coreuser_vex   ),
                                    .rramsleep      (rramsleep      ),  //tbd
                                    .vex_mm         (vex_mm         ),
				                    .evin           (rrc_ev         ),  //tbd
                                    .mode_sec       (secmode ),
                                    .cmscode        (cmscode        ),
                                    .rbs            (rbif_acram2kx64[0]),
                                    .jtag           (jtagrrc        ),
                                    .*       // need add new jtagrrc.
);

    generate
        for (genvar i = 0; i < 2; i++) begin:greram
             rerammacro reram(.rri(rri[i]),.rro(rro[i]),.ANALOG_0(ana_reramtest[i]), .POC_IO(ana_rrpoc[i]));
        end
    endgenerate

`endif


//bistrd ##

// qspi flash controller
    logic qfcirq;

    logic pclkqfc, clkqfc0, resetnqfc;

    ICG icg_clkqfc  (.CK (clkqfc), .EN (qfc_en),.SE(cmsatpg),.CKG(clkqfc0));
    ICG icg_pclkqfc (.CK (pclk),   .EN (qfc_en),.SE(cmsatpg),.CKG(pclkqfc));
    assign resetnqfc = cmsatpg ? resetn : qfc_en & resetn;

    qfc qfc(
            .qfc_en (qfc_en),
    /*    input bit*/   .clk(clkqfc0),
    /*    input bit*/   .pclk(pclkqfc),
    /*    input bit*/   .resetn(resetnqfc),
    /*    input bit*/   .cmsatpg,
    /*    input bit*/   .cmsbist,
                        .rbif_tx_fifo128x32 (rbif_tx_fifo128x32 [0]),
                        .rbif_rx_fifo128x32 (rbif_rx_fifo128x32 [0]),
                        .rbif_fifo32x19     (rbif_fifo32x19     [0]),

        .axis ( qfc_axi64 ),
        .apbs ( coresubapbs[0] ),
        .apbx ( coresubapbs[0] ),

        .qfc_sck,
        .qfc_sckn,
        .qfc_dqs,
        .qfc_ss,
        .qfc_sio,
//        .qfc_rwds,
        .qfc_rstm,
        .qfc_rsts,
        .qfc_int,

        .padcfg_qfc_sck,
        .padcfg_qfc_qds,
        .padcfg_qfc_ss,
        .padcfg_qfc_sio,
//        .padcfg_qfc_rwds,
        .padcfg_qfc_int,
        .padcfg_qfc_rst,

        .irq ( qfcirq )
    );


// apb system


//cm7resetreq

// ev/err
    assign coresubevo[15:0] = '0; // first 16 are internal.
    assign coresubevo[16] = qfcirq;
    assign coresubevo[17] = mdmairq;
    assign coresubevo[18] = mbox_irq[0];
    assign coresubevo[19] = mbox_irq[1];
    assign coresubevo[20] = mbox_irq[2];
    assign coresubevo[21] = mbox_irq[3];
    assign coresubevo[22] = rrcint;
    assign coresubevo[31:23] = '0;
    assign coresuberro = | { rrcnmi, mdmaerr, srambankerr };

// system ctrl

//    assign coreusermap = { code_mem_map, };//{};
//    assign cmsatpg = cmscode == CMS_ATPG;
//    assign cmsbist = cmscode == CMS_TEST;

// apb security


endmodule : soc_coresub


module dummytb_soc_coresub();
    ioif swdio();
//    ahbif bmxif_ahb32();
//    bit clk,resetn;
    parameter BRC  = daric_cfg::BRC;
    parameter BRCW = daric_cfg::BRCW;
    parameter BRDW = daric_cfg::BRDW;
    parameter IRQCNT = daric_cfg::IRQCNT;

    logic   clktop, clktopen;
    logic   clksys;
    logic   ref1M;
    logic   fclk;
    logic   aclk;
    logic   hclk;
    logic   iclk;
//    logic   clkcore;
    logic   clkdma;
    logic   clksce;
    logic   clkqfc;
    logic   clkvex;
    logic   clkmboxgate;
    logic   clkocc_rrc;
    logic   aximclken;
    logic   ahbpclken;
    logic   ahbsclken;
    logic   sysresetn;
    logic   coreresetn;
    logic   cm7sleep;
    logic   cm7resetreq;
    cms_pkg::cmscode_e   cmscode;
    logic       cmsatpg, cmsbist;
    logic       clkswd;
    logic [3:0]          brready;
    logic                brvld;
    logic [BRCW-1:0]     bridx;
    logic [BRDW-1:0]     brdat;
    logic                brdone;
    //logic   clktop;
    logic   fclken;
    logic [IRQCNT-1-16:0]  cm7_irq;
    logic cm7_nmi;
    logic cm7_rxev;
    logic [31:0]    coresubevo;
    logic           coresuberro;
    logic [31:0]    sceevo;
    logic           sceerro;
    logic   coresel_cm7;
    wire [0:1] ana_reramtest;
    nvrcfg_pkg::nvrcfg_t nvrcfgdata;
    logic clksceen, clkpke;
    logic           rramsleep;
    logic[15:0]     rrc_ev;
    wire [0:1] ana_rrpoc;

// qfc
    padcfg_arm_t  padcfg_qfc_sck;
    padcfg_arm_t  padcfg_qfc_qds;
    padcfg_arm_t  padcfg_qfc_ss;
    padcfg_arm_t  padcfg_qfc_sio;
    padcfg_arm_t  padcfg_qfc_rwds;
    padcfg_arm_t  padcfg_qfc_int;
    padcfg_arm_t  padcfg_qfc_rst;
    ioif qfc_sck();
    ioif qfc_sckn();
    ioif qfc_dqs();
    ioif qfc_ss[1:0]();
    ioif qfc_sio[7:0]();
    ioif qfc_rwds();
    ioif qfc_rstm[1:0]();
    ioif qfc_rsts[1:0]();
    ioif qfc_int();
    wire        ana_rng_0p1u;
    logic [6:0] ipt_rngcfg;
    rbif #(.AW(15   ),      .DW(72))    rbif_ram32kx72      [0:3]   ();
    rbif #(.AW(13   ),      .DW(72))    rbif_ram8kx72       [0:15]  ();
    rbif #(.AW(10   ),      .DW(72))    rbif_rf1kx72        [0:1]   ();
    rbif #(.AW(8    ),      .DW(27))    rbif_rf256x27       [0:1]   ();
    rbif #(.AW(9    ),      .DW(39))    rbif_rf512x39       [0:7]   ();
    rbif #(.AW(7    ),      .DW(31))    rbif_rf128x31       [0:3]   ();
    rbif #(.AW(13   ),      .DW(36))    rbif_dtcm8kx36      [0:1]   ();
    rbif #(.AW(15   ),      .DW(18))    rbif_itcm32kx18     [0:3]   ();
    rbif #(.AW(12   ),      .DW(36))    rbif_sce_sceram_10k [0:0]   ();
    rbif #(.AW(10   ),      .DW(36))    rbif_sce_hashram_3k [0:0]   ();
    rbif #(.AW(8    ),      .DW(36))    rbif_sce_aesram_1k  [0:0]   ();
    rbif #(.AW(9    ),      .DW(72))    rbif_sce_pkeram_4k  [0:1]   ();
    rbif #(.AW(10   ),      .DW(36))    rbif_sce_aluram_3k  [0:1]   ();
    rbif #(.AW(8    ),      .DW(72))    rbif_sce_mimmdpram  [0:0]   ();
    rbif #(.AW(10   ),      .DW(32))    rbif_rdram1kx32     [0:5]   ();
    rbif #(.AW(9    ),      .DW(64))    rbif_rdram512x64    [0:3]   ();
    rbif #(.AW(7    ),      .DW(22))    rbif_rdram128x22    [0:7]   ();
    rbif #(.AW(5    ),      .DW(16))    rbif_rdram32x16     [0:1]   ();
    rbif #(.AW(10   ),      .DW(32))    rbif_bioram1kx32    [0:3]   ();
    rbif #(.AW(7    ),      .DW(32))    rbif_tx_fifo128x32  [0:0]   ();
    rbif #(.AW(7    ),      .DW(32))    rbif_rx_fifo128x32  [0:0]   ();
    rbif #(.AW(5    ),      .DW(19))    rbif_fifo32x19      [0:0]   ();
//    rbif #(.AW(15   ),      .DW(36))    rbif_ifram32kx36    [0:1]   ();
//    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_share   [0:0]   ();
//    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_odb     [0:0]   ();
//    rbif #(.AW(8    ),      .DW(64))    rbif_udcmem_256x64  [0:0]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_acram2kx64     [0:0]   ();
//    rbif #(.AW(10   ),      .DW(36))    rbif_aoram1kx36     [0:1]   ();

//
    jtagif  jtagvex();
    jtagif  jtagrrc[0:1]();
    logic iptorndlf, iptorndhf;
    logic aorameven, iframeven;

    ahbif #(.AW(32),.DW(32),.IDW(4),.UW(4))
        bmxif_ahb32(), coreahb_sys(), coreahb_sec(), coreahb_ao(), bdma_ahb32();
    axiif #(.AW(32),.DW(32),.IDW(8),.LENW(8),.UW(8)) bdma_axi32();

    soc_coresub u1(.bmxif_ahb32(bmxif_ahb32),.swdio      (swdio),.*);
endmodule
