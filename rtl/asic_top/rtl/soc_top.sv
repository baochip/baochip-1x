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

module soc_top #(

    parameter DFT_AOTRM_BW = daric_cfg::DFT_AOTRM_BW,
    parameter DFT_AOTRM_IV = daric_cfg::DFT_AOTRM_IV
)(
        input   wire        ana_rng_0p1u,
        inout   wire [0:1]  ana_reramtest,
        input   wire [0:1]  ana_rrpoc,
        input   wire [3:0]  ana_adcsrc,

        input logic         clkxtl,
        input logic [0:2]   cmspad,
        input logic         padresetn,
        input logic         socresetn,
        input logic         socresetn_undft,
        output logic        clksys,
        output logic        coreresetn,
        output logic        cmsatpg,
        output logic        cmstest,
        output logic        cmsbist,
        output logic        cmsuser,
        output logic        cmsdone,
        input logic         aocmsuser,

        output logic        dbgtxd,
        input logic         clkswd,
        output logic [0:5]  clkocc,
        ioif.drive          swdio,
        jtagif.slave        jtagvex,
        jtagif.slave        jtagrrc[0:1],
        jtagif.slave        jtagipt,
        jtagif.slave        jtagrb,
`ifdef FPGA
    input   logic   coresel_cm7,
`endif

        output bit xtalsleep,

        ioif.drive          iopad_A[0: 7],
        ioif.drive          iopad_B[0:15],
        ioif.drive          iopad_C[0:15],
        ioif.drive          iopad_D[0:15],
        ioif.drive          iopad_E[0:15],

        output padcfg_arm_t  iocfg_A[0: 7],
        output padcfg_arm_t  iocfg_B[0:15],
        output padcfg_arm_t  iocfg_C[0:15],
        output padcfg_arm_t  iocfg_D[0:15],
        output padcfg_arm_t  iocfg_E[0:15],
        output padcfg_arm_t  iocfg_F[0: 9],

    `UTMI_IF_DEF
//    ioif.drive                  sddc_clk,
//    ioif.drive                  sddc_cmd,
////    ioif.drive                  sddc_dat[3:0],
//    ioif.drive                  sddc_dat0,
//    ioif.drive                  sddc_dat1,
//    ioif.drive                  sddc_dat2,
//    ioif.drive                  sddc_dat3,

        output padcfg_arm_t  padcfg_qfc_sck,
        output padcfg_arm_t  padcfg_qfc_qds,
        output padcfg_arm_t  padcfg_qfc_ss,
        output padcfg_arm_t  padcfg_qfc_sio,
    ////    output padcfg_arm_t  padcfg_qfc_rwds,
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

        output  wire  soc_pmu_IBIASENA,
        output  wire [1:0] vd_VD09_CFG,
        output  wire  VD09ENA             ,
        output  wire  VD25ENA             ,
        output  wire  VD33ENA             ,
        output  wire  VD09TL              ,
        output  wire  VD09TH              ,
        output  wire  VD25TL              ,
        output  wire  VD25TH              ,
        output  wire  VD33TL              ,
        output  wire  VD33TH              ,
        input   wire  VD09L               ,
        input   wire  VD09H               ,
        input   wire  VD25L               ,
        input   wire  VD25H               ,
        input   wire  VD33L               ,
        input   wire  VD33H               ,

        output wire pad_reton,
        output wire pad_retoff,

        output logic [0:5]  iptpo,
        apbif.master        apbudp,
        output logic        pclkudp,

        // ao domain
        output logic        clksysao,
        output logic        clksysao_undft,
        output logic        clkao,
        apbif.master        apbao,
        output logic        pmusleep,
        ioif.drive          iopad_F[0: 9],
        input logic         aowkupvld,
        input  logic        aowkupint,
        input  logic        aoint,
        input  logic [0:5]  ao_iptpo,

        output logic [1:0]   aoram_clkb,
        output logic [1:0]   aoram_bcen,
        output logic [1:0]   aoram_bwen,
        output logic [35:0]   aoram_bd,
        output logic [9:0]   aoram_ba,
        input  logic [1:0][35:0]   aoram_bq,

        output logic aoatpgrst, aoatpgse,

    // dft
        input logic clkatpg, atpgrst, atpgse,
        output logic        aojtagipt_set, aoipflow_set, aoipnvr_set,
        output bit [DFT_AOTRM_BW-1:0] ipt_aoreg,
        output logic [63:0] ipt_padoe, ipt_padpo,
        input logic [63:0] ipt_padpi
/*
        output logic jtagipt_tck,
        output logic jtagipt_resetn,
        output logic ipttap_shiftdr,
        output logic ipttap_updatedr,
        output logic ipttap_capturedr,
        output logic aotap_sel,
        output logic tap_tdo,
        input  logic aotap_tdi
*/
);

//    apbif apbao();
//    dummyio_pu swdiopad(swdio);
    logic [6:0] osc_osc32m_nvr;
    logic [63:0]       aopmutrmdata, soctrmdata;
    logic [63:0] ipt_socreg;
//    logic [0:5] clkocc;
    logic [0:5] clkbist;
    logic aorameven, iframeven;

    parameter ACKCNT = 8;
    parameter HCKCNT = 8;
    parameter ICKCNT = 8;
    parameter PCKCNT = 8;

    parameter BRC  = daric_cfg::BRC;
    parameter BRCW = daric_cfg::BRCW;
    parameter BRDW = daric_cfg::BRDW;
    parameter BRNUM_CMS = daric_cfg::BRNUM_CMS;
    parameter BRNUM_IPM = daric_cfg::BRNUM_IPM;
    parameter BRNUM_CFG = daric_cfg::BRNUM_CFG;
    parameter BRNUM_ACV = daric_cfg::BRNUM_ACV;
    parameter CW = 32;
    parameter SCFGWC = BRDW/CW;
    parameter IPMDC = BRNUM_IPM * BRDW / CW;
    parameter CFGDC = BRNUM_CFG * BRDW / CW;

//    logic               clksys;
    logic               clktop;
    logic               clkper;
    logic               fclk;
    logic               aclk;
    logic               hclk;
    logic               iclk;
    logic               pclk;
    logic               aoclk;
    logic               fclken;
    logic               aclken;
    logic               hclken;
    logic               iclken;
    logic               pclken;
    logic               aoclken;
    logic               fclken2;
    logic               aclken2;
    logic               hclken2;
    logic               iclken2;
    logic               pclken2;
    logic               aoclken2;
    logic               clkpke  ;
    logic [ACKCNT-1:0]  aclksub, aclksubgate;
    logic [HCKCNT-1:0]  hclksub, hclksubgate;
    logic [ICKCNT-1:0]  iclksub, iclksubgate;
    logic [PCKCNT-1:0]  pclksub, pclksubgate;
    logic               ref1M, ref32k;
//    logic               socresetn;
    logic               secresetn;
    logic               wdtresetn;
    logic               vdresetn;
    logic               sysresetn;
//    logic               coreresetn;
    logic               sfrlock;
    logic [3:0]          brready;
    logic                brvld;
    logic [BRCW-1:0]     bridx;
    logic [BRDW-1:0]     brdat;
    logic               brdone;
    cms_pkg::cmsdata_e  cmsdata;
    logic               cmsdatavld;
    logic               cmsvrgn;
    logic               cmsscde;
//    logic               cmsdone;
    logic               cmserror;
    cms_pkg::cmscode_e  cmscode;
    logic apb_pclken;
    logic   cm7sleep;
    logic   cm7resetreq;
    logic aximclken;
    logic ahbpclken;
    logic ahbsclken;
    logic wdgintr, wdtreset, txd, duartintr, lclk;
    logic [1:0] tmintr;
    logic [IPMDC-1:0][31:0] iptrim32       ;
    logic                   iptrimdatavld,iptrimdataset  ;
    logic                   iptrimready    ;
    logic [CFGDC-1:0][31:0] syscfg32       ;
    logic wkupvld, ifsubwkupvld_async ;
    logic [6:0]             ipsleep;
    logic atpg_ascapen;
    logic ipflowfsm_setipcr;

    ahbif #(.AW(32),.DW(32),.IDW(4),.UW(4))
        ahbifsub(), ahbifsub0(), coreahb_sys(), coreahb_sec(), coreahb_ao(), coreahb_aolf(), bdma_ahb32();
    axiif #(.AW(32), .DW(32), .IDW(6)) bdma_axi32();

    apbif #(.PAW(16),.DW(32)) apbsysbdg(), apbsecbdg(), apbaobdg();
    apbif #(.PAW(12),.DW(32)) apbsys[0:15]();//, apbsec[0:15]();
    nvrcfg_pkg::nvrcms_t     nvrcmsdata;
    nvrcfg_pkg::nvripm_t     nvripmdata;
    nvrcfg_pkg::nvrcfg_t     nvrcfgdata;
    ahbif #(.AW(13))  ahbaoram(),ahbaoramlf();
    bit iptpopll, iptporng, iptpoosc;
    bit ipt_socset;
    logic iptorndlf, iptorndhf;
    logic clksys_undft, sysresetn_undft, coreresetn_undft;
    logic clkaoram;

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
    rbif #(.AW(15   ),      .DW(36))    rbif_ifram32kx36    [0:1]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_share   [0:0]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_odb     [0:0]   ();
    rbif #(.AW(8    ),      .DW(64))    rbif_udcmem_256x64  [0:0]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_acram2kx64     [0:0]   ();
    rbif #(.AW(10   ),      .DW(36))    rbif_aoram1kx36     [0:1]   ();

// ■■■■■■■■■■■
// system: sysctrl, cms, brc
// ■■■■■■■■■■■

    sysctrl #(
            .ACKCNT( ACKCNT ),
            .HCKCNT( HCKCNT ),
            .ICKCNT( ICKCNT ),
            .PCKCNT( PCKCNT ),
            .IPMDC ( IPMDC )
        )sysctrl(
    /*        input logic      */   .clkxtl      (clkxtl      ),
    /*        output logic     */   .clksys      (clksys      ),
    /*        output logic     */   .clksys1m    (clksysao    ),
    /*        output logic     */   .clksys1m_undft    (clksysao_undft    ),
    /*        output logic     */   .clktop      (clktop      ),
    /*        output logic     */   .clkper      (clkper      ),
    /*        output logic     */   .fclk        (fclk        ),
    /*        output logic     */   .aclk        (aclk        ),
    /*        output logic     */   .hclk        (hclk        ),
    /*        output logic     */   .iclk        (iclk        ),
    /*        output logic     */   .pclk        (pclk        ),
    /*        output logic     */   .aoclk       (aoclk       ),
    /*        output logic     */   .clkaoram    (clkaoram       ),
    /*        output logic     */   .fclken      (fclken      ),
    /*        output logic     */   .aclken      (aclken      ),
    /*        output logic     */   .hclken      (hclken      ),
    /*        output logic     */   .iclken      (iclken      ),
    /*        output logic     */   .pclken      (pclken      ),
    /*        output logic     */   .aoclken     (aoclken     ),
    /*        output logic     */   .fclken2     (fclken2     ),
    /*        output logic     */   .aclken2     (aclken2     ),
    /*        output logic     */   .hclken2     (hclken2     ),
    /*        output logic     */   .iclken2     (iclken2     ),
    /*        output logic     */   .pclken2     (pclken2     ),
    /*        output logic     */   .aoclken2    (aoclken2    ),
    /*        output logic     */   .clkpke      (clkpke      ),
    /*        output logic     */   .aclksub     (aclksub     ),
    /*        output logic     */   .hclksub     (hclksub     ),
    /*        output logic     */   .iclksub     (iclksub     ),
    /*        output logic     */   .pclksub     (pclksub     ),
    /*        output logic     */   .aclksubgate (aclksubgate ),
    /*        output logic     */   .hclksubgate (hclksubgate ),
    /*        output logic     */   .iclksubgate (iclksubgate ),
    /*        output logic     */   .pclksubgate (pclksubgate ),
    /*        output logic     */   .ref1M       (ref1M       ),
    /*        output logic     */   .ref32k      (ref32k      ),
    /*        input   logic    */   .cmsatpg     (cmsatpg     ),
    /*        input   cms_pkg: */   .cmscode     (cmscode     ),
                                    .brdone      (brdone      ),
    /*        input logic      */   .socresetn   (socresetn & ~cmserror ),
    /*        input logic      */   .secresetn   (secresetn   ),
    /*        input logic      */   .padresetn   (padresetn   ),
    /*        input logic      */   .wdtresetn   (wdtresetn   ),
    /*        input logic      */   .vdresetn    (vdresetn    ),
    /*        output logic     */   .sysresetn   (sysresetn   ),
    /*        output logic     */   .coreresetn  (coreresetn  ),
                                    .wkupvld_async(aowkupvld | ifsubwkupvld_async),
//    /*    output logic [IPMDC-1:0][31:0] */.iptrim32        ('0),
    /*    output logic                   */.iptrimdatavld   (iptrimdatavld),
    /*    input  logic                   */.iptrimready     (iptrimready),
                                    .coresleep   (cm7sleep    ),
                                    .ipsleep     (ipsleep     ),

                                    .pad_reton,
                                    .pad_retoff,
                                    .osc_osc32m_nvr(osc_osc32m_nvr),
                                    .ipt_socset    (ipt_socset),
                                    .ipt_socreg    (ipt_socreg),
    /*        input logic      */   .sfrlock     (sfrlock|'0     ),
    /*        apbif.slave      */   .apbs         (apbsys[0]   ),
    /*        apbif.slave      */   .apbx         (apbsys[0]   ),
                                    .iptpopll, .iptpoosc,
                                    .xtalsleep,
                                    .atpg_ascapen,
                                    .ipflowfsm_setipcr,
                                    .*
        );

//        assign secresetn = 1'b1;
    //    assign wdtresetn = 1'b1;
        assign vdresetn  = 1'b1;
        assign pmusleep = ipsleep[3];

//        ##wkupvld
        assign pclkudp = pclk;

    cms cms(
        .clk    (clksys_undft),
        .resetn (sysresetn_undft),
        .chipresetn (socresetn_undft),
        .aocmsuser (aocmsuser),
    /*    input logic [0:2] */  .cmspad      ( cmspad      ),
    /*    input cmsdata_e   */  .cmsdata     ( cmsdata     ),
    /*    input logic       */  .cmsdatavld  ( cmsdatavld  ),
    /*    output logic      */  .cmsatpg     ( cmsatpg     ),
    /*    output logic      */  .cmstest     ( cmstest     ),
    /*    output logic      */  .cmsuser     ( cmsuser     ),
    /*    output logic      */  .cmsvrgn     ( cmsvrgn     ),
    /*    output logic      */  .cmsscde     ( cmsscde     ),
    /*    output logic      */  .cmsdone     ( cmsdone     ),
    /*    output logic      */  .cmserror    ( cmserror    ),
    /*    output cmscode_e  */  .cmscode     ( cmscode     )
    );

    assign cmsbist = cmstest;

    brc#(
        .BRC  (BRC),
        .BRCW (BRCW),
        .BRDW (BRDW),
        .BRNUM_CMS (BRNUM_CMS),
        .BRNUM_IPM (BRNUM_IPM),
        .BRNUM_CFG (BRNUM_CFG),
        .CW (CW),
        .SCFGWC (SCFGWC),
        .IPMDC (IPMDC),
        .CFGDC (CFGDC),
        .CMSD_t (cms_pkg::cmsdata_e)
    )brc(
             .clk    ( clksys ),
             .resetn ( sysresetn ),
    /*    input  logic                   */.brvld           (brvld),
    /*    input  logic [BRCW-1:0]        */.bridx           (bridx),
    /*    input  logic [BRDW-1:0]        */.brdat           (brdat),
    /*    input  logic                   */.brdone          (brdone),
    /*    output logic [3:0]             */.brready         (brready),
    /*    output logic [BRDW-1:0]        */.nvrcmsdata      (nvrcmsdata),
    /*    output logic                   */.cmsdatavld      (cmsdatavld),
    /*    input  logic                   */.cmsdone         (cmsdone&&(cmsuser|cmstest)),
    /*    output logic [IPMDC-1:0][31:0] */.nvripmdata,
    /*    output logic                   */.iptrimdatavld   (iptrimdatavld),
                                           .iptrimdataset   (iptrimdataset),

    /*    input  logic                   */.iptrimready     (iptrimready),
    /*    output logic [CFGDC-1:0][31:0] */.nvrcfgdata
    );
    //    assign cmsdatavld = bridx[0] & brvld;
    assign cmsdata = nvrcmsdata.cmsdata0;

    assign aopmutrmdata[63:0] = nvripmdata.ipm0[63:0];
    assign soctrmdata[63:0] =   nvripmdata.ipm0[127:64];

    assign osc_osc32m_nvr = soctrmdata[7:0];

// ░▒▓██▓▒░ ■■■■■■■■■■■
// ░▒▓██▓▒░  apbsys: evc, wdt, duart, tmr
// ░▒▓██▓▒░ ■■■■■■■■■■■

    parameter EVCNT  = daric_cfg::IRQCNT;
    parameter IRQCNT = daric_cfg::IRQCNT;
    parameter ERRCNT = daric_cfg::ERRCNT;

    bit [EVCNT-1:0]  ev;
    bit [ERRCNT-1:0] err;
    bit [IRQCNT-1:0] cm7irq;
    bit              cm7ev;
    bit              cm7nmi;
    bit              ifev_vld;
    bit [7:0]        ifev_dat;
    bit              ifev_rdy;
    bit [1:0]        tmr_ev;
    bit [15:0]       rrc_ev;
    bit              ifev_err;
    bit              coresuberr;
    bit              sceerr;
    bit              ifsuberr;
    bit              secsubrr;
    bit [7:0]        secirq;

    bit [31:0]       coresubev;
    bit [31:0]       sceev;
    bit [127:0]      ifsubev;
    bit [1:0] aoramerr;

// valid event for M7 is 240b

    assign ev[31 :0  ] = {aowkupint, aoint, wdgintr,tmintr[1:0], coresubev[26:0]};
    assign ev[63 :32 ] = sceev;
    assign ev[191:64 ] = ifsubev;
    assign ev[223:192] = err;
    assign ev[239:224] = '0 | secirq[7:0];
    assign ev[255:240] = '0;


    assign err[0] = |coresuberr;
    assign err[1] = |sceerr;
    assign err[2] = |ifsuberr;
    assign err[3] = |secirq;
    assign err[4] = |aoramerr;
    assign err[ERRCNT-1:5] = '0;

    evc#(
        .EVCNT  (EVCNT),
        .ERRCNT (ERRCNT),
        .IRQCNT (IRQCNT)
    )evc(
        .hclk       (hclk),
        .pclk       (pclk),
        .resetn     (coreresetn),
        .apbs       (apbsys[4]),
        .apbx       (apbsys[4]),
        .evin       (ev|256'h0),
        .errin      (err|16'h0),
        // m7
        .cm7irq,
        .cm7ev,
        .cm7nmi,
        // ifsub
        .ifev_vld,
        .ifev_dat,
        .ifev_rdy,
        .ifev_err,
        // timer
        .tmr_ev,
        .rrc_ev
    );

    wdg_intf wdt(
            .clk    (pclk),
            .resetn (coreresetn),
            .wdgclk (pclk),
            .apbs   (apbsys[1]),
            .wdgintr(wdgintr),
            .wdgrst (wdtreset)
        );
//    assign wdtresetn = ~wdtreset;
    `theregfull( pclk, sysresetn, wdtresetn, '1) <= ~wdtreset;

    duart duart(
            .clk    (pclk),
            .sclk   (clksys),
            .resetn (coreresetn),
            .apbs   (apbsys[2]),
            .apbx   (apbsys[2]),
            .txd    (dbgtxd)
        );

    timer_intf tmr(
            .clk    (pclk),
            .resetn (coreresetn),
            .apbs   (apbsys[3]),
            .lclk   (ref32k),
            .evin   (tmr_ev),
            .tmintr (tmintr)
        );

    `ifdef SIM
    sim_mon mon(.clk (pclk),.apbs   (apbsys[15]),.apbx   (apbsys[15]));
    `else
    apbs_null as7(apbsys[15]);
    `endif

    apbs_nulls #(.SLVCNT(9)) as0(apbsys[6:14]);

// ░▒▓██▓▒░ ■■■■■■■■■■■
// ░▒▓██▓▒░  coresub
// ░▒▓██▓▒░ ■■■■■■■■■■■

    assign aximclken = aclken2;
    assign ahbpclken = aclken2 & hclken2;
    assign ahbsclken = aclken2 & hclken2;

    soc_coresub #(
        //parameter
    )soc_coresub(
                               .ana_rng_0p1u  (ana_rng_0p1u),
                               .ana_reramtest,
                               .clkocc_rrc  ( clkocc[3] ),
    /*    input   logic     */ .fclk        ( fclk        ),
    /*    input   logic     */ .aclk        ( aclk        ),
    /*    input   logic     */ .hclk        ( hclk        ),
    /*    input   logic     */ .iclk        ( iclk        ),
//                               .pclk        ( pclk        ),
                               .fclken      ( fclken      ),
//                               .pclken      ( apb_pclken  ),
    /*    input   logic     */ .clktop      ( clktop      ),
    /*    input   logic     */ .clktopen    ( fclken      ),
    /*    input   logic     */ .clksys      ( clksys      ),
    /*    input   logic     */ .ref1M       ( ref1M       ),
    /*    input   logic     */ .clkdma      ( hclksub[4]  ),
    /*    input   logic     */ .clksce      ( hclksub[1]  ),
    /*    input   logic     */ .clksceen    ( hclken      ),
    /*    input   logic     */ .clkpke      ( clkpke      ),
                               .clkmboxgate ( aclksubgate[5] ),
                               .clkvex      ( aclk        ),
                               .clkqfc      ( aclksub[4]  ),
    /*    input   logic     */ .aximclken   ( aximclken   ),
    /*    input   logic     */ .ahbpclken   ( ahbpclken   ),
    /*    input   logic     */ .ahbsclken   ( ahbsclken   ),
    /*    input   logic     */ .sysresetn   ( sysresetn   ),
    /*    input   logic     */ .coreresetn  ( coreresetn  ),
`ifdef FPGA
            .coresel_cm7,
`endif
    ///*    output cmsdata_e  */  .cmsdata     ( cmsdata     ),
    ///*    output logic      */  .cmsdatavld  ( cmsdatavld  ),
    /*   input  logic [3:0]      */.brready,
    /*   output logic            */.brvld,
    /*   output logic [BRCW-1:0] */.bridx,
    /*   output logic [BRDW-1:0] */.brdat,
    /*    output logic      */ .brdone      ( brdone      ),
    /*    output  logic     */ .cm7sleep    ( cm7sleep    ),
    /*    output  logic     */ .cm7resetreq ( cm7resetreq ),
    /*    input   cmscode_e */ .cmscode     ( cmscode     ),
                               .cmsatpg     (cmsatpg),
                               .cmsbist     (cmsbist),
                               .cm7_irq     ( cm7irq[IRQCNT-1-16:0] ),
                               .nvrcfgdata,
                               .cm7_nmi     ( cm7nmi      ),
                               .cm7_rxev    ( cm7ev       ),
                               .coresubevo  ( coresubev   ),
                               .coresuberro ( coresuberr  ),
                               .sceevo      ( sceev   ),
                               .sceerro     ( sceerr  ),
                               .rramsleep   ( ipsleep[2] ),
// qfc
                                .padcfg_qfc_sck,
                                .padcfg_qfc_qds,
                                .padcfg_qfc_ss,
                                .padcfg_qfc_sio,
//                                .padcfg_qfc_rwds,
                                .padcfg_qfc_int,
                                .padcfg_qfc_rst,

                                .qfc_sck,
                                .qfc_sckn,
                                .qfc_dqs,
                                .qfc_ss,
                                .qfc_sio,
//                                .qfc_rwds,
                                .qfc_rstm,
                                .qfc_rsts,
                                .qfc_int,


// vex
                                .jtagvex,
                                .jtagrrc,

    .iptorndlf, .iptorndhf,

    /*    ahbif.master      */ .bmxif_ahb32 ( ahbifsub0   ),
    /*    ahbif.master      */ .coreahb_sys ( coreahb_sys ),
    /*    ahbif.master      */ .coreahb_sec ( coreahb_sec ),
    /*    ahbif.master      */ .coreahb_ao  ( coreahb_ao  ),
    /*    ahbif.slave       */ .bdma_ahb32  ( bdma_ahb32  ),
    /*    axiif.slave       */ .bdma_axi32  ( bdma_axi32  ),
    /*    input   logic     */ .clkswd      ( clkswd      ),
    /*    ioif.drive        */ .swdio       ( swdio       ),
                               .ana_rrpoc   ( ana_rrpoc   ),
                               .rrc_ev,
                               .iframeven          (iframeven),
                               .aorameven          (aorameven),
                               .ipt_rngcfg         (ipt_socreg[51:45]),
                               .*
        );

       //apb_bdg

        assign apb_pclken = iclken2 & pclken2;
        apb_bdg uapbsysbdg(
    /*        input        */   .hclk     ( hclk            ),
    /*        input        */   .resetn   ( coreresetn      ),
    /*        input        */   .pclken   ( apb_pclken      ),
    /*        ahbif.slave  */   .ahbslave ( coreahb_sys     ),
    /*        apbif.master */   .apbmaster( apbsysbdg       )
        );

        apb_bdg uapbsecbdg(
    /*        input        */   .hclk     ( hclk            ),
    /*        input        */   .resetn   ( coreresetn      ),
    /*        input        */   .pclken   ( apb_pclken      ),
    /*        ahbif.slave  */   .ahbslave ( coreahb_sec     ),
    /*        apbif.master */   .apbmaster( apbsecbdg       )
        );



    apb_mux  #(.DECAW(4)) apbsysmux(.apbslave (apbsysbdg), .apbmaster(apbsys));
//    apb_mux  #(.DECAW(4)) apbsecmux(.apbslave (apbsecbdg), .apbmaster(apbsec));

//    apbs_nulls #(.SLVCNT(16)) asec0(apbsec);

// ░▒▓██▓▒░  ■■■■■■■■■■
// ░▒▓██▓▒░    secsub
// ░▒▓██▓▒░  ■■■■■■■■■■

    logic [daric_cfg::SENSORVDC-1:0] sensor_vd;
    logic [2+daric_cfg::SENSORVDC/2-1:0] sensor_vdena;
    logic [daric_cfg::SENSORVDC-1:0] sensor_vdtst;

    logic [daric_cfg::SENSORLDC-1:0] sensor_ld, t_sensor_ld;
    logic [daric_cfg::SENSORLDC-1:0] sensor_ldtst, t_sensor_ldtst;
    logic sensor_ldclk, t_sensor_ldclk;

    assign  { vd_VD09_CFG[1:0],VD09ENA,VD25ENA,VD33ENA } = sensor_vdena;
    assign  { VD09TL,VD09TH,VD25TL,VD25TH,VD33TL,VD33TH } = sensor_vdtst ;
    assign  sensor_vd = { VD09L,VD09H,VD25L,VD25H,VD33L,VD33H };

    secsub #(
        .MESHLC    ( daric_cfg::MESHLC ),
        .MESHPC    ( daric_cfg::MESHPC ),
        .SENSORVDC ( daric_cfg::SENSORVDC),
        .SENSORLDC ( daric_cfg::SENSORLDC),
        .GLCX      ( daric_cfg::GLCX ),
        .GLCY      ( daric_cfg::GLCY )
    )secsub(
/*        input logic  */  .clksys, // clksys
/*        input logic  */  .pclk,
                           .pclkmesh (pclksub[7]),
/*        input logic  */  .porresetn   ( socresetn ),
/*        input logic  */  .resetn      ( coreresetn ),
                           .cmsatpg,
/*        input logic  */  .vd          ( sensor_vd ),
/*        input logic  */  .ld          ( sensor_ld ),
                            .vdena      (sensor_vdena),
                            .vdtst      (sensor_vdtst),
                            .ldtst      (sensor_ldtst),
                            .ldclk      (sensor_ldclk),
/*        output logic  */ .vdresetn    ( secresetn ),
/*        output logic  */ .irq8        ( secirq ),
/*        apbif.slave  */  .apbs        ( apbsecbdg )
    );

    assign t_sensor_ldclk = ~cmsatpg & sensor_ldclk;
    assign t_sensor_ldtst = cmsatpg ? '0 : sensor_ldtst;

generate
    for (genvar i = 0; i < daric_cfg::SENSORLDC; i++) begin : gLD
    assign sensor_ld[i] = cmsatpg ? ^{sensor_ldtst[i]} : t_sensor_ld[i];
        ip_lightdet ldsensor(
//                .analog_test_only(),
                .d2a_clk  ( t_sensor_ldclk ),
                .d2a_self_test_en ( t_sensor_ldtst[i] ),
                .light_out ( t_sensor_ld[i] )
        );
    end
endgenerate


// ░▒▓██▓▒░  ■■■■■■■■■■
// ░▒▓██▓▒░    ifsub
// ░▒▓██▓▒░  ■■■■■■■■■■

    ahb_sync#(
            .SYNCDOWN (1),
            .SYNCUP   (0)
        ) ahbifsub_syncdown (
            .hclk       (hclk        ),
            .resetn     (coreresetn  ),
            .hclken     (iclken2     ),
            .ahbslave   (ahbifsub0   ),
            .ahbmaster  (ahbifsub    )
        );

    ioif            iopad[0:16*6-1]();
    padcfg_arm_t    iocfg[0:16*6-1];

    soc_ifsub #(
    //    .IOC   (16*6),
    //    .EVCNT (32*4),
    //    .ERRCNT (1)
    )soc_ifsub(
    /*    input logic               */  .clk       ( iclk       ),
                                        .pclk         (pclk),
                                        .pclken       (pclken),

    /*    input logic               */  .clk48m    ( clksys     ),
//                                        .clkao25m     (clksys),
                                        .fclk      ( fclk       ),
                                        .hclk      ( hclk       ),
                                        .clkudc    ( iclksub[4] ),
                                        .clkbiogate ( iclksubgate[7] ),

    /*    input logic               */  .resetn    ( coreresetn ),
    /*    input logic               */  .perclk    ( clkper     ),
    /*    input logic               */  .cmsbist   ( cmsbist    ),
    /*    input logic               */  .cmsatpg   ( cmsatpg    ),
    /*    input logic               */  .clksys    ( clksys     ),
                                        .ioxlock   ( '0    ),
    /*    input  logic              */  .ifev_vld  ( ifev_vld   ),
    /*    input  logic [7:0]        */  .ifev_dat  ( ifev_dat   ),
    /*    output logic              */  .ifev_rdy  ( ifev_rdy   ),
    /*    output logic              */  .wkupvld   ( wkupvld    ),
    /*    output logic              */  .wkupvld_async   ( ifsubwkupvld_async    ),
    /*    ahbif.slave               */  .ahbs      ( ahbifsub   ),
    /*    output logic [EVCNT-1:0]  */  .ifsubevo  ( ifsubev    ),
    /*    output logic [ERRCNT-1:0] */  .ifsuberro ( ifsuberr   ),
    /*    input logic [IRQCNT-1:0]  */  .cm7_irq   ( cm7irq[IRQCNT-1-16:0] ),
//                                       .sddc_clk     (sddc_clk),
//                                       .sddc_cmd     (sddc_cmd),
//                                       .sddc_dat0     (sddc_dat0),
//                                       .sddc_dat1     (sddc_dat1),
//                                       .sddc_dat2     (sddc_dat2),
//                                       .sddc_dat3     (sddc_dat3),
                                        .ana_adcsrc,
                                        `UTMI_IF_INST
                                        .apbudp       (apbudp),
                                        .ahbaoram     (ahbaoram),
                                        .bdma_ahb32   (bdma_ahb32),
                                        .bdma_axi32   (bdma_axi32),
//    /*    input   logic     */          .clkdma      ( hclksub[0]  ),
    /*    ioif.drive                */  .iopad     ( iopad      ),
                                        .iocfg,
                                        .iframeven,
                                        .*
    );

    iothrus #( 8)uiopadA(.iodrv(iopad_A[0: 7]), .ioload(iopad[ 0: 7])); // [ 0:15]
    iothrus #(16)uiopadB(.iodrv(iopad_B[0:15]), .ioload(iopad[16:31])); // [16:31]
    iothrus #(16)uiopadC(.iodrv(iopad_C[0:15]), .ioload(iopad[32:47])); // [32:47]
    iothrus #(16)uiopadD(.iodrv(iopad_D[0:15]), .ioload(iopad[48:63])); // [48:63]
    iothrus #(16)uiopadE(.iodrv(iopad_E[0:15]), .ioload(iopad[64:79])); // [64:79]
    iothrus #(10)uiopadF(.iodrv(iopad_F[0: 9]), .ioload(iopad[80:89])); // [80:95]

    assign iocfg_A[0: 7] = iocfg[ 0: 7];
    assign iocfg_B[0:15] = iocfg[16:31];
    assign iocfg_C[0:15] = iocfg[32:47];
    assign iocfg_D[0:15] = iocfg[48:63];
    assign iocfg_E[0:15] = iocfg[64:79];
    assign iocfg_F[0: 9] = iocfg[80:89];


    ioifld_nulls #( 8)uiopadAnulls(.ioifld(iopad[ 8:15]));
//    ioifld_nulls #( 2)uiopadCnulls(.ioifld(iopad[46:47]));
    ioifld_nulls #( 6)uiopadFnulls(.ioifld(iopad[90:95]));

// ░▒▓██▓▒░  ■■■■■■■■■■
// ░▒▓██▓▒░    always on
// ░▒▓██▓▒░  ■■■■■■■■■■

    ramif #(.RAW(11),.DW(32),.BW(8)) aoramif();

    assign clkao = aoclk;
//    assign clkaoram = aoclk;


    ahbasync uahbaolf(.clks(hclk), .clkm(clkao), .resetn(coreresetn), .ahbs (coreahb_ao), .ahbm(coreahb_aolf));
        apb_bdg uapbaobdg(
    /*        input        */   .hclk     ( clkao           ),
    /*        input        */   .resetn   ( coreresetn      ),
    /*        input        */   .pclken   ( 1'b1 ),
    /*        ahbif.slave  */   .ahbslave ( coreahb_aolf    ),
    /*        apbif.master */   .apbmaster( apbaobdg        )
        );
    apb_thru uapbao(.apbslave (apbaobdg), .apbmaster(apbao));


    ahbasync uahbaoramlf(.clks(iclk), .clkm(clkaoram), .resetn(coreresetn), .ahbs (ahbaoram), .ahbm(ahbaoramlf));

// 8KB AORAM
     ahbsramc32 #(.HAW(13),.RAW(11)) aoramc (
        .clk(clkaoram),
        .resetn( coreresetn      ),
        .ahbslave       (ahbaoramlf),
        .rammaster      (aoramif)
        );

//#RAM

`ifdef FPGA

    uram_none aoram (
      .clk(clkaoram),
      .resetn( coreresetn      ),
      .waitcyc      ('0),
      .rams         (aoramif)
    );

`else

    aoram uaoramc(
        .clk(clkaoram),
        .resetn( coreresetn      ),
        .cmsatpg,
        .cmsbist,
        .rbs(rbif_aoram1kx36),
        .scmbkey                ('0),
        .even                   (aorameven),
        .prerr                  (aoramerr[0]),
        .verifyerr              (aoramerr[1]),
        .rams                   (aoramif ),
        .aoram_clkb,
        .aoram_bcen,
        .aoram_bwen,
        .aoram_bd,
        .aoram_ba,
        .aoram_bq
    );

`endif

// ░▒▓██▓▒░  ■■■■■■■■■■
// ░▒▓██▓▒░    always on / DFT
// ░▒▓██▓▒░  ■■■■■■■■■■

        assign aoatpgrst = atpgrst;
        assign aoatpgse = atpgse;


// 0 : soc: PLL,32m,rng,tv??
// 1 : ao:  PMU,32k
// 2 : ram cfg
// 3 : io
// 4 : IPTPOSEL, atpgsetup

    bit [4:0][63:0] iptregin;
    bit [4:0][63:0] iptregout;
    bit [4:0] iptregset;
    logic [3:0] iptposel;
    logic iptap_en;
    logic atpg_stuckat, atpg_atspeed, atpg_compress_en, atpg_spc_en, atpg_pll_bypass, atpg_occ_reset;

    assign atpg_ascapen = cmsatpg & atpg_atspeed & ~atpgse;
    assign iptap_en = cmstest | cmsbist | cmsatpg;

    jtagtap #(
        .SETCNT ( 5 ),
        .REGW ( {64, 64, 64, 64, 64 } ),
        .REGWMAX ( 64 ),
        .REGIV ( { 64'h0, 64'h0, 64'h0, 64'h0, 64'h0 } )
    )iptdap(
        .resetn(sysresetn_undft),
        .jtags(jtagipt),
        .enable(iptap_en),
        .regin(iptregin),
        .regout(iptregout),
        .regset(iptregset)
    );

    assign iptregin[4] = 0;
    assign iptregin[3] = ipt_padpi[63:0];
    assign iptregin[1] = 0;
    assign iptregin[0] = 0;
    assign ipt_socreg = iptregout[0];
    assign ipt_aoreg  = cmsuser ? aopmutrmdata : iptregout[1];
    assign ipt_padpo[63:0] = {4{iptregout[3][15: 0]}}|64'h0;
    assign ipt_padoe[63:0] = {4{iptregout[3][31:16]}}|64'h0;

    assign iptposel = iptregout[4][11:8];
    DATACELL_BUF u_stuckatmode_buf  (.A(iptregout[4][5]),.Z(atpg_stuckat));
    DATACELL_BUF u_atspeedmode_buf  (.A(iptregout[4][4]),.Z(atpg_atspeed));
    DATACELL_BUF u_compress_en_buf  (.A(iptregout[4][3]),.Z(atpg_compress_en));
    DATACELL_BUF u_spc_en_buf       (.A(iptregout[4][2]),.Z(atpg_spc_en));
    DATACELL_BUF u_pll_bypass_buf   (.A(iptregout[4][1]),.Z(atpg_pll_bypass));
    DATACELL_BUF u_occ_reset_buf    (.A(iptregout[4][0]),.Z(atpg_occ_reset));

  assign iptpo[0:5] =
        iptposel == 0 ? 'h2a :
        iptposel == 1 ? ao_iptpo[0:5] :
        iptposel == 2 ? { VD09L, VD09H, VD25L, VD25H, VD33L, VD33H } :
        iptposel == 3 ? { iptorndlf, iptorndhf, iptpopll, iptporng, iptpoosc } :
                        'h15;

    sync_pulse su0 ( .clka(jtagipt.tck), .resetn(sysresetn), .clkb(clksysao), .pulsea (iptregset[1]), .pulseb( aojtagipt_set ) );
    sync_pulse su1 ( .clka(clksys),      .resetn(sysresetn), .clkb(clksysao), .pulsea (ipflowfsm_setipcr),           .pulseb( aoipflow_set  ) );
    sync_pulse su2 ( .clka(clksys),      .resetn(sysresetn), .clkb(clksysao), .pulsea (iptrimdataset),.pulseb( aoipnvr_set   ) );

    sync_pulse su3 ( .clka(jtagipt.tck), .resetn(sysresetn_undft), .clkb(clksys_undft), .pulsea (iptregset[0]), .pulseb( ipt_socset ) );

    assign soc_pmu_IBIASENA = cmsatpg ? 1'b1 : ipsleep[4] ? '0 : '1;
//    assign vd_VD09_CFG  = 0;
    assign iptporng = '0;

// ░▒▓██▓▒░  ■■■■■■■■■■
// ░▒▓██▓▒░    rbist
// ░▒▓██▓▒░  ■■■■■■■■■■

rbist_wrp #(
    .RAMC (28)
)rbist(
    .jtagrb,
    .atpgrst,
    .atpgse,
    .cmsatpg,
    .apbs(apbsys[5]),
    .apbx(apbsys[5]),
    .pclk, .clksys,
    .sysresetn,
    .clkbist,

    .iptregset(iptregset[2]),
    .iptregout(iptregout[2]),
    .iptregin(iptregin[2]),
    .nvrtrmset(iptrimdataset),
    .nvrtrmvld(nvripmdata.ipm2[240-32+28-1:240-32]),
    .nvrtrmdat({nvripmdata.ipm2[13*16-1:0],nvripmdata.ipm1[15*16-1:0]}),

    .rbif_ram32kx72          ,       //  sram            ram32kx72           4       sp
    .rbif_ram8kx72           ,       //  sram            ram8kx72            16      sp
    .rbif_rf1kx72            ,       //  cache           rf1kx72             2       sp
    .rbif_rf256x27           ,       //  cache           rf256x27            2       sp
    .rbif_rf512x39           ,       //  cache           rf512x39            8       sp
    .rbif_rf128x31           ,       //  cache           rf128x31            4       sp
    .rbif_dtcm8kx36          ,       //  dtcm            dtcm8kx36           2       sp
    .rbif_itcm32kx18         ,       //  itcm            itcm32kx18          4       sp
    .rbif_ifram32kx36        ,       //  ifram           ifram32kx36         2       sp
    .rbif_sce_sceram_10k     ,       //  sceram          sce_sceram_10k      1       sp
    .rbif_sce_hashram_3k     ,       //  hashram         sce_hashram_3k      1       sp
    .rbif_sce_aesram_1k      ,       //  aesram          sce_aesram_1k       1       sp
    .rbif_sce_pkeram_4k      ,       //  pkeram          sce_pkeram_4k       2       sp
    .rbif_sce_aluram_3k      ,       //  aluram          sce_aluram_3k       2       sp
    .rbif_sce_mimmdpram      ,       //  pkeramdp        sce_mimmdpram       1       dp
    .rbif_rdram1kx32         ,       //  RAM_DP_1024_32  rdram1kx32          6       dp
    .rbif_rdram512x64        ,       //  RAM_DP_512_64   rdram512x64         4       dp
    .rbif_rdram128x22        ,       //  RAM_DP_128_22   rdram128x22         8       dp
    .rbif_rdram32x16         ,       //  RAM_DP_512_1    rdram32x16          2       dp
    .rbif_bioram1kx32        ,       //  RAM_SP_1024_32  bioram1kx32         4       sp
    .rbif_tx_fifo128x32      ,       //  csr.U_tx_fifo   fifo128x32          1       dp
    .rbif_rx_fifo128x32      ,       //  csr.U_rx_fifo   fifo128x32          1       dp
    .rbif_fifo32x19          ,       //  csr.U_cmd_fifo  fifo32x19           1       dp
    .rbif_udcmem_share       ,       //  share_mem       udcmem_1088x64      1       dp
    .rbif_udcmem_odb         ,       //  odb_mem         udcmem_1088x64      1       dp
    .rbif_udcmem_256x64      ,       //  idb_mem         udcmem_256x64       1       dp
    .rbif_acram2kx64         ,       //  acram           acram2kx64          1       sp
    .rbif_aoram1kx36                 //  aoram           aoram1kx36          2       sp
);

    sparecell #(200) spcell();

endmodule

/*
module dummyio_pu( ioif.load pad );
    assign pad.pi=1'b1;
endmodule
*/
