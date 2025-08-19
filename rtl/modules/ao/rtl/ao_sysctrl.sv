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


module  ao_sysctrl #(
    parameter IOC=10,
    parameter PMUDFTW  = 6,
    parameter PMUCRW   = 8,
    parameter PMUTRMW  = 34,
    parameter OSCCRW   = 1,
    parameter OSCTRMW  = 7,
    parameter bit [PMUDFTW-1:0] IV_PMUDFT = { 3'h0, 3'h2},
    parameter bit [PMUCRW -1:0] IV_PMUCR  = 7'b1111100,
    parameter bit [PMUTRMW-1:0] IV_PMUTRM = { 6'h20,5'h10,5'h10,5'h10,5'h10,5'h10,3'h0},
    parameter bit [OSCCRW -1:0] IV_OSC32KCR =    1'b1,
    parameter bit [OSCTRMW-1:0] IV_OSC32KTRM =    7'b0100110,
    parameter IPTBW = 64
 )(

//pbus
    input logic     clksysao,
    input logic     clksysao_undft,
    input logic     clkocc,
    input logic     pclk, //1M by default
    input logic     aopclk, //1M by default
    output logic pclkenreg,
    output logic pclk32kenreg,
    apbif.slavein   apbs,
    apbif.slave     apbx,

//    input  logic    clkocc6_32m,
    input  logic    clkxtl32k,
    ioif.load       socpad[0:IOC-1],
    ioif.load       kpio[7:0],
    ioif.drive      aopad[0:IOC-1],

    input logic socjtagipt_set,
    input logic socipflow_set,
    input logic socipnvr_set,
    input logic [64-1:0]     socip_nvript,

    input logic     ipsleep,
    output logic    aowkupvld,
    output logic    aowkupint,
    output logic [0:5] ao_iptpo,
    input logic cmsatpg,
    input logic cmsuser,
    input logic cmstest,

    input logic [7:0] wkupintsrc,
    output logic aoint,
// pmu
    output  wire  pmu_TRM_LATCH_b         ,    // pmu

    input   wire  pmu_POR                 ,    // pmu
    input   wire  pmu_BGRDY               ,    // pmu
    input   wire  pmu_VR25RDY             ,    // pmu
    input   wire  pmu_VR85ARDY            ,    // pmu
    input   wire  pmu_VR85DRDY            ,    // pmu

    output wire [PMUDFTW-1:0]   pmu_dft,
    output wire [PMUCRW-1:0]    pmu_ctrl,
    output wire [PMUTRMW-1:0]   pmu_trm,
    output wire                 osc_ctrl,
    output wire [OSCTRMW-1:0]   osc_trm,
    output logic clk1hz, clk32k,

/*
    output  wire  pmu_IOUTEN              ,    // pmu
//    output  wire  pmu_IBIASEN             ,    // pmu
    output  wire  pmu_POCENA              ,    // pmu
    output  wire  pmu_VR25EN              ,    // pmu
    output  wire  pmu_VR85AEN             ,    // pmu
    output  wire  pmu_VR85DEN             ,    // pmu
    output  wire  pmu_VR85A95ENA          ,    // pmu
    output  wire  pmu_VR85D95ENA          ,    // pmu
//    output  wire  pmu_VR85AOSENA          ,    // pmu
//    output  wire  pmu_VR85DOSENA          ,    // pmu
    output  wire [6-1:0] pmu_TRM_CUR      ,    // pmu
    output  wire [5-1:0] pmu_TRM_CTAT     ,    // pmu
    output  wire [5-1:0] pmu_TRM_PTAT     ,    // pmu
    output  wire [5-1:0] pmu_TRM_D1P2     ,    // pmu
    output  wire [5-1:0] pmu_TRM_DP60_VDD85A     ,    // pmu
    output  wire [5-1:0] pmu_TRM_DP60_VDD85D     ,    // pmu
    output  wire         pmu_VDDAO_CURCFG  ,
    output  wire [2:0]   pmu_VDDAO_VOLCFG  ,

    output  wire [3-1:0] pmu_PMU_TEST_SEL ,    // pmu
    output  wire [3-1:0] pmu_PMU_TEST_EN  ,    // pmu
*/
// reset ctrl
    input  logic    padresetn, atpgrst,  // from aopad
    output logic    porresetn, porresetn_undft,
    output logic    socresetn, socresetn_undft,   // to   soc
    output logic    ao_iso_enable

);

    logic [  6:0] pmu_osc32k_cfg   ;
//    localparam bit [TAPBW-1:0] IV_TAP = { 5'h0, IV_PMUCR[9:0], IV_PMUTRM[IPTBW-1:0], IV_PMUDFT[5:0] };

// vddao pin

/*
    logic     soc_IOUTEN              ;
    logic     soc_IBIASEN             ;
    logic     soc_POCENA              ;
    logic     soc_VR25EN              ;
    logic     soc_VR85AEN             ;
    logic     soc_VR85DEN             ;
    logic     soc_VR85A95ENA          ;
    logic     soc_VR85D95ENA          ;
    logic     soc_VR85AOSENA          ;
    logic     soc_VR85DOSENA          ;

    logic [6-1:0]   soc_TRM_CUR      , pmutrmlp_CUR      , pmutrmreg_CUR      ;
    logic [5-1:0]   soc_TRM_CTAT     , pmutrmlp_CTAT     , pmutrmreg_CTAT     ;
    logic [5-1:0]   soc_TRM_PTAT     , pmutrmlp_PTAT     , pmutrmreg_PTAT     ;
    logic [5-1:0]   soc_TRM_D1P2     , pmutrmlp_D1P2     , pmutrmreg_D1P2     ;
    logic [5-1:0]   soc_TRM_DP60_VDD85A     , pmutrmlp_DP60_VDD85A     , pmutrmreg_DP60_VDD85A     ;
    logic [5-1:0]   soc_TRM_DP60_VDD85D     , pmutrmlp_DP60_VDD85D     , pmutrmreg_DP60_VDD85D     ;
    logic           soc_VDDAO_CURCFG    , pmutrmlp_VDDAO_CURCFG    , pmutrmreg_VDDAO_CURCFG    ;
    logic [2:0]     soc_VDDAO_VOLCFG    , pmutrmlp_VDDAO_VOLCFG    , pmutrmreg_VDDAO_VOLCFG    ;

    logic [6:0]     soc_osc32k_cfg,    osc32kcfglp,        osc32kcfgreg,           osc_osc32k_cfg ;
    logic [6:0]     soc_osc32m_cfg,    osc32mcfglp,        osc32mcfgreg           ;//osc_osc32m_cfg ;
    logic [3-1:0]   soc_PMU_TEST_SEL , pmudft_testsel;
    logic [3-1:0]   soc_PMU_TEST_EN  , pmudft_testen ;
*/
    bit [9:0] wkupmask;
    bit [7:0] inten;
    bit pmupdresetn;
    bit clkosc32k;// clk32k;
/*
    jtagreg #(
        .JTAGREGSIZE(TAPBW),
        .IV(IV_TAP),
        .SYNC(0)
    ) i_jtagreg1 (
        .clk_i           (jtag_tck),
        .rst_ni          (jtag_resetn),
        .enable_i        (tap_sel),
        .capture_dr_i    (tap_capturedr),
        .shift_dr_i      (tap_shiftdr),
        .update_dr_i     (tap_updatedr),
        .jtagreg_in_i    (tap_regin),
        .mode_i          (tap_en),
        .scan_in_i       (tap_tdi),
        .scan_out_o      (tap_tdo),
        .jtagreg_out_o   (tap_regout)
    );
    assign tap_regin =
    {
        pmu_BGRDY               ,
        pmu_VR25RDY             ,
        pmu_VR85ARDY            ,
        pmu_VR85DRDY            ,
        pmu_POR                 ,
        s_IOUTEN              ,
        s_IBIASEN             ,
        s_POCENA              ,
        s_VR25EN              ,
        s_VR85AEN             ,
        s_VR85DEN             ,
        s_VR85A95ENA          ,
        s_VR85D95ENA          ,
        s_VR85AOSENA          ,
        s_VR85DOSENA          ,
//        s_TRM_LATCH_b         ,
        s_osc32m_cfg[6:0]     ,
        s_osc32k_cfg[6:0]     ,
        s_TRM_CUR [6-1:0]     ,
        s_TRM_CTAT[5-1:0]     ,
        s_TRM_PTAT[5-1:0]     ,
        s_TRM_D1P2[5-1:0]     ,
        s_TRM_DP60[5-1:0]     ,
        s_PMU_TEST_SEL[3-1:0] ,
        s_PMU_TEST_EN [3-1:0]
    };
*/
/*
    assign {
        soc_osc32k_cfg[6:0]     ,
        soc_VR25EN              ,
        soc_VR85AEN             ,
        soc_VR85DEN             ,
        soc_IOUTEN              ,
//        soc_IBIASEN             ,
        soc_POCENA              ,
        soc_VR85A95ENA          ,
        soc_VR85D95ENA          ,
//        soc_VR85AOSENA          ,
//        soc_VR85DOSENA          ,
        soc_TRM_CUR [6-1:0]     ,
        soc_TRM_CTAT[5-1:0]     ,
        soc_TRM_PTAT[5-1:0]     ,
        soc_TRM_D1P2[5-1:0]     ,
        soc_TRM_DP60_VDD85A[5-1:0]     ,
        soc_TRM_DP60_VDD85D[5-1:0]     ,
        soc_VDDAO_CURCFG ,
        soc_VDDAO_VOLCFG[2:0] ,
        soc_PMU_TEST_SEL[3-1:0] ,
        soc_PMU_TEST_EN [3-1:0]
    } = socip_nvript;
*/
    assign ao_iptpo =     {
        clkosc32k ,
        pmu_BGRDY               ,
        pmu_VR25RDY             ,
        pmu_VR85ARDY            ,
        pmu_VR85DRDY            ,
        pmu_POR
        };

//  pd / wakeup
// ■■■■■■■■■■■■■■■

    logic resetn, aopdreg;// clk;
    logic [4:0] sfrpmusr;
    logic jtagit_set, ipflow_set, socnvr_set, jtagit_set0;
    logic jtagit_setreg, ipflow_setreg, socnvr_setreg, jtagit_setreg0;
    logic soctrmvld;
    assign pmu_TRM_LATCH_b         = porresetn;

    logic [PMUCRW -1:0] pmucrreg,  socpmucr,  sfrpmucr,  sfrpmucrlp,  sfrpmucrpd ;
    logic [PMUTRMW-1:0] pmutrmreg, socpmutrm, sfrpmutrm, sfrpmutrmlp;
    logic [PMUDFTW-1:0] pmudftreg, socpmudft, sfrpmudft;
    logic [OSCCRW -1:0] osccrreg,  socosccr,  sfrosccr,  sfrosccrlp,  sfrosccrpd ;
    logic [OSCTRMW-1:0] osctrmreg, socosctrm, sfrosctrm, sfrosctrmlp;

    assign pmu_ctrl  = cmsatpg ? pmucrreg : ipsleep ? sfrpmucrlp : aopdreg ? sfrpmucrpd : pmucrreg;
    `theregfull( clksysao_undft, porresetn_undft, pmucrreg, IV_PMUCR ) <=
                                                jtagit_set0 ? socpmucr :
                                                ipflow_set ? sfrpmucr :
                                                             pmucrreg;

    assign pmu_trm  =  cmsatpg ? pmutrmreg : ipsleep | aopdreg ? sfrpmutrmlp : pmutrmreg;
    `theregfull( clksysao_undft, porresetn_undft, pmutrmreg, IV_PMUTRM    ) <=
                                                jtagit_set0 ? socpmutrm :
                                                ipflow_set ? sfrpmutrm :
                                                socnvr_set ? socpmutrm :
                                                             pmutrmreg;

    assign pmu_dft = pmudftreg;
    `theregfull( clksysao_undft, porresetn_undft, pmudftreg, IV_PMUDFT    ) <=
                                                jtagit_set0 ? socpmudft :
                                                ipflow_set ? sfrpmudft :
                                                             pmudftreg;

    assign osc_ctrl = ipsleep ? sfrosccrlp : aopdreg ? sfrosccrpd : osccrreg;
    `theregfull( clksysao, porresetn, osccrreg, OSCCRW ) <=
                                                jtagit_set ? socosccr :
                                                ipflow_set ? sfrosccr :
                                                             osccrreg;

    assign osc_trm = ipsleep | aopdreg ? sfrosctrmlp : osctrmreg;
    `theregfull( clksysao, porresetn, osctrmreg, IV_OSC32KTRM ) <=
                                                jtagit_set ? socosctrm :
                                                ipflow_set ? sfrosctrm :
                                                socnvr_set ? socosctrm :
                                                             osctrmreg;

    assign {socpmucr, socpmutrm,socpmudft,socosccr, socosctrm } = socip_nvript;
    assign soctrmvld = socip_nvript[63];

    `theregfull( clksysao_undft, porresetn_undft, jtagit_setreg0, '0 ) <= socjtagipt_set;
    `theregfull( clksysao, porresetn, jtagit_setreg, '0 ) <= socjtagipt_set;
    `theregfull( clksysao, porresetn, ipflow_setreg, '0 ) <= /*(cmsatpg | cmstest | cmsuser ) &*/ socipflow_set;
    `theregfull( clksysao, porresetn, socnvr_setreg, '0 ) <= /*(cmsatpg | cmstest | cmsuser ) &*/ socipnvr_set;

    assign jtagit_set0 = soctrmvld & jtagit_setreg0 & ( cmsatpg | cmstest );
    assign jtagit_set  = soctrmvld & jtagit_setreg  &   cmstest;
    assign ipflow_set  = ipflow_setreg  &  ~cmsatpg;
    assign socnvr_set  = soctrmvld & socnvr_setreg  &  ~cmsatpg;

/*
    assign pmutrm = pmutrmset_nvr ? soc_pmutrm :

    assign pmu_VR25EN              = cmstest | cmsatpg ? soc_VR25EN              : pmucr_vr25en  & ~( aopdreg & pmucr_vr25pd );
    assign pmu_VR85AEN             = cmstest | cmsatpg ? soc_VR85AEN             : pmucr_vr85aen & ~( aopdreg & pmucr_vr85apd );
    assign pmu_VR85DEN             = cmstest | cmsatpg ? soc_VR85DEN             : pmucr_vr85den & ~( aopdreg & pmucr_vr85dpd );
    assign pmu_IOUTEN              = cmstest | cmsatpg ? soc_IOUTEN              : ipsleep ? pmucrlp_iouten :    pmucr_iouten;
//    assign pmu_IBIASEN             = cmstest | cmsatpg ? soc_IBIASEN             : ipsleep ? pmucrlp_ibiasen :   pmucr_ibiasen;
    assign pmu_POCENA              = cmstest | cmsatpg ? soc_POCENA              : ipsleep ? pmucrlp_pocen :     pmucr_pocen;
    assign pmu_VR85A95ENA          = cmstest | cmsatpg ? soc_VR85A95ENA          : ipsleep ? pmucrlp_vr85a95en : pmucr_vr85a95en;
    assign pmu_VR85D95ENA          = cmstest | cmsatpg ? soc_VR85D95ENA          : ipsleep ? pmucrlp_vr85d95en : pmucr_vr85d95en;
//    assign pmu_VR85AOSENA          = cmstest | cmsatpg ? soc_VR85AOSENA          : ipsleep ? pmucrlp_vr85aosen : pmucr_vr85aosen;
//    assign pmu_VR85DOSENA          = cmstest | cmsatpg ? soc_VR85DOSENA          : ipsleep ? pmucrlp_vr85dosen : pmucr_vr85dosen;
    assign pmu_TRM_CUR [6-1:0]     = cmstest | cmsatpg ? soc_TRM_CUR [6-1:0]     : ipsleep ? pmutrmlp_CUR :  pmutrmreg_CUR ;
    assign pmu_TRM_CTAT[5-1:0]     = cmstest | cmsatpg ? soc_TRM_CTAT[5-1:0]     : ipsleep ? pmutrmlp_CTAT : pmutrmreg_CTAT;
    assign pmu_TRM_PTAT[5-1:0]     = cmstest | cmsatpg ? soc_TRM_PTAT[5-1:0]     : ipsleep ? pmutrmlp_PTAT : pmutrmreg_PTAT;
    assign pmu_TRM_D1P2[5-1:0]     = cmstest | cmsatpg ? soc_TRM_D1P2[5-1:0]     : ipsleep ? pmutrmlp_D1P2 : pmutrmreg_D1P2;
    assign pmu_TRM_DP60_VDD85A[5-1:0]     = cmstest | cmsatpg ? soc_TRM_DP60_VDD85A[5-1:0]     : ipsleep ? pmutrmlp_DP60_VDD85A : pmutrmreg_DP60_VDD85A;
    assign pmu_TRM_DP60_VDD85D[5-1:0]     = cmstest | cmsatpg ? soc_TRM_DP60_VDD85D[5-1:0]     : ipsleep ? pmutrmlp_DP60_VDD85D : pmutrmreg_DP60_VDD85D;
    assign pmu_VDDAO_CURCFG        = cmstest | cmsatpg ? soc_VDDAO_CURCFG        : ipsleep ? pmutrmlp_VDDAO_CURCFG : pmutrmreg_VDDAO_CURCFG;
    assign pmu_VDDAO_VOLCFG        = cmstest | cmsatpg ? soc_VDDAO_VOLCFG        : ipsleep ? pmutrmlp_VDDAO_VOLCFG : pmutrmreg_VDDAO_VOLCFG;
    assign pmu_PMU_TEST_SEL[3-1:0] = cmstest | cmsatpg ? soc_PMU_TEST_SEL[3-1:0] : pmudft_testsel[2:0];
    assign pmu_PMU_TEST_EN [3-1:0] = cmstest | cmsatpg ? soc_PMU_TEST_EN [3-1:0] : pmudft_testen[2:0];
    assign pmu_osc32k_cfg[6:0]     = cmstest | cmsatpg ? soc_osc32k_cfg[6:0]     : ipsleep ? osc32kcfglp : osc32kcfgreg;
*/
/*
    assign {
            pmucr_vr25en, pmucr_vr85aen, pmucr_vr85den,
            pmucr_iouten, pmucr_ibiasen, pmucr_pocen,
            pmucr_vr85a95en, pmucr_vr85d95en
//            pmucr_vr85aosen, pmucr_vr85dosen
        } = sfrpmucr;
    assign {
            pmucrlp_vr25en, pmucrlp_vr85aen, pmucrlp_vr85den, // no use
            pmucrlp_iouten, pmucrlp_ibiasen, pmucrlp_pocen,
            pmucrlp_vr85a95en, pmucrlp_vr85d95en,
//            pmucrlp_vr85aosen, pmucrlp_vr85dosen
        } = sfrpmucrlp;
    assign {
            oscpd, pmucr_vr25pd, pmucr_vr85apd, pmucr_vr85dpd
        } = sfrpmucrpd;

    assign {
            osc32kcfglp, pmutrmlp_CUR , pmutrmlp_CTAT, pmutrmlp_PTAT, pmutrmlp_D1P2, pmutrmlp_DP60_VDD85A, pmutrmlp_DP60_VDD85D, pmutrmlp_VDDAO_CURCFG, pmutrmlp_VDDAO_VOLCFG }
        } = sfrpmutrmlp;
    assign {
            osc32kcfgreg, pmutrmreg_CUR , pmutrmreg_CTAT, pmutrmreg_PTAT, pmutrmreg_D1P2, pmutrmreg_DP60_VDD85A, pmutrmreg_DP60_VDD85D, pmutrmreg_VDDAO_CURCFG, pmutrmreg_VDDAO_VOLCFG }
        } = pmutrmreg;
    assign {
            pmudft_testsel, pmudft_testen
        } = sfrpmudftcr;
*/

    assign sfrpmusr = { pmu_BGRDY, pmu_VR25RDY, pmu_VR85ARDY, pmu_VR85DRDY, ~pmu_POR };


//    sync_pulse sync_pmutrmset_nvr ( .clka(pclk),    .resetn, .clkb(clksysao), .pulsea (sfrpmutrmar), .pulseb( pmutrmset_sfr ) );

// apb sfr
// ■■■■■■■■■■■■■■■

    logic        sfrpmupdar, pclkicg;
    logic        clk32kselreg, pdisoen;
    logic [13:0] clk1hzfd;
    logic [4:0]  rstcrmask;
    logic [9:0]  aofr;
    logic kpiosel;
    logic apbrd, apbwr;
    logic sfrlock;
    logic aoperi_clrint;
    logic [9:0] aopadpu;

    assign sfrlock = '0;
    `apbs_common;
    assign apbx.prdata = '0
//                        | cr_apbao2_paddr.prdata32 | sr_apbao2_prdata.prdata32
                        | cr_cr.prdata32 | cr_clk1hzfd.prdata32 | cr_wkupmask .prdata32 | cr_rstcrmask.prdata32
                        | sfr_pmucsr.prdata32 | sfr_pmucrlp.prdata32 | sfr_pmucrpd.prdata32 | sfr_pmudftsr.prdata32
                        | sfr_pmutrm0csr.prdata32 | sfr_pmutrm1csr.prdata32 | sfr_pmutrmlp0.prdata32 | sfr_pmutrmlp1.prdata32
                        | sfr_osccr.prdata32
                        | sfr_pmusr.prdata32 | sfr_pmufr.prdata32 | sfr_aofr.prdata32
                        | sfr_iox.prdata32 | sfr_aopadpu.prdata32
                        ;

//    apb_cr #(.A('h00), .DW(14))                 cr_apbao2_paddr  (.cr( apbao2_paddr       ), .prdata32(),.*);
//    apb_cr #(.A('h04), .DW(32))                 cr_apbao2_pwdata (.cr( apbao2_pwdata      ), .prdata32(),.*);
//    apb_sr #(.A('h04), .DW(32))                 sr_apbao2_prdata (.sr( apbao2_prdata      ), .prdata32(),.*);
//    apb_ar #(.A('h08), .AR(32'h5a))             ar_apbao2_pwrite (.ar( apbao2_pwrite      ),.*);
//    apb_ar #(.A('h08), .AR(32'ha5))             ar_apbao2_pread  (.ar( apbao2_pread       ),.*);
    apb_cr #(.A('h0), .DW(3), .IV(3'h6))        cr_cr            (.cr( { pclkicg, pdisoen, clk32kselreg}       ), .prdata32(),.*);
    apb_cr #(.A('h4), .DW(14), .IV(14'h3fff))   cr_clk1hzfd      (.cr( clk1hzfd           ), .prdata32(),.*);
    apb_cr #(.A('h8), .DW(18))                  cr_wkupmask      (.cr( {wkupmask, inten}  ), .prdata32(),.*);
    apb_cr #(.A('hc), .DW(5),  .IV(5'h1f))      cr_rstcrmask     (.cr( rstcrmask          ), .prdata32(),.*);

    apb_cr #(.A('h10), .DW(PMUCRW),  .IV(IV_PMUCR ))  sfr_pmucr     (.cr(sfrpmucr      ), .prdata32(),.*);
    apb_cr #(.A('h14), .DW(PMUCRW),  .IV(IV_PMUCR ))  sfr_pmucrlp   (.cr(sfrpmucrlp    ), .prdata32(),.*);
    apb_cr #(.A('h18), .DW(PMUCRW),  .IV(IV_PMUCR ))  sfr_pmucrpd   (.cr(sfrpmucrpd    ), .prdata32(),.*);
    apb_cr #(.A('h1c), .DW(PMUDFTW), .IV(IV_PMUDFT))  sfr_pmudft    (.cr(sfrpmudft     ), .prdata32(),.*);
    apb_sr #(.A('h10), .DW(PMUCRW)                 )  sfr_pmucsr    (.sr(pmucrreg      ), .prdata32(),.*);
    apb_sr #(.A('h1c), .DW(PMUDFTW)                )  sfr_pmudftsr  (.sr(pmudftreg     ), .prdata32(),.*);

    apb_cr #(.A('h20), .DW(32),         .IV(IV_PMUTRM[31:0])        )   sfr_pmutrm0    (.cr(sfrpmutrm[31:0]         ), .prdata32(),.*);
    apb_cr #(.A('h24), .DW(PMUTRMW-32), .IV(IV_PMUTRM[PMUTRMW-1:32]))   sfr_pmutrm1    (.cr(sfrpmutrm[PMUTRMW-1:32] ), .prdata32(),.*);
    apb_cr #(.A('h28), .DW(32),         .IV(IV_PMUTRM[31:0])        )   sfr_pmutrmlp0  (.cr(sfrpmutrmlp[31:0]       ), .prdata32(),.*);
    apb_cr #(.A('h2c), .DW(PMUTRMW-32), .IV(IV_PMUTRM[PMUTRMW-1:32]))   sfr_pmutrmlp1  (.cr(sfrpmutrmlp[PMUTRMW-1:32] ), .prdata32(),.*);
    apb_sr #(.A('h20), .DW(32)                                      )   sfr_pmutrm0csr (.sr(pmutrmreg[31:0]         ), .prdata32(),.*);
    apb_sr #(.A('h24), .DW(PMUTRMW-32)                              )   sfr_pmutrm1csr (.sr(pmutrmreg[PMUTRMW-1:32] ), .prdata32(),.*);

    apb_cr #(.A('h34), .DW(3+OSCTRMW*2), .IV({IV_OSC32KCR,IV_OSC32KTRM,IV_OSC32KCR,IV_OSC32KTRM,IV_OSC32KCR}))   sfr_osccr
                 (.cr({  sfrosccrpd, sfrosctrmlp, sfrosccrlp, sfrosctrm, sfrosccr} ), .prdata32(),.*);
    apb_sr #(.A('h38), .DW(5))                   sfr_pmusr    (.sr(sfrpmusr      ), .prdata32(),.*);
    apb_fr #(.A('h3C), .DW(5))                   sfr_pmufr    (.fr(~sfrpmusr     ), .prdata32(),.*);

    apb_fr #(.A('h40), .DW(10))                  sfr_aofr     (.fr( aofr         ), .prdata32(),.*);
    apb_ar #(.A('h44), .AR(32'h5a))              sfr_pmupdar  (.ar(sfrpmupdar    ),             .*);

    apb_ar #(.A('h50), .AR(32'haa))             ar_aoperi_clrint (.ar( aoperi_clrint      ),.*);
//    apb_cr #(.A('h40), .DW(26), .IV(IV_PMUTRM[25:0]))   sfr_pmutrm    (.cr(sfrpmutrm[25:0]   ), .prdata32(),.*);
//    apb_cr #(.A('h44), .DW(26), .IV(IV_PMUTRM[25:0]))   sfr_pmutrmlp  (.cr(sfrpmutrmlp[25:0] ), .prdata32(),.*);
//    apb_ar #(.A('h48), .AR(32'h5a))                     sfr_pmutrmar  (.ar(sfrpmutrmar   ),             .*);
//    apb_cr #(.A('h4C), .DW(7*4), .IV({IV_PMUTRM[39:33],IV_PMUTRM[39:33],IV_PMUTRM[32:26],IV_PMUTRM[32:26]}))
//                                                        sfr_osctrm    (.cr({sfrpmutrmlp[39:33],sfrpmutrm[39:33],sfrpmutrmlp[32:26],sfrpmutrm[32:26]} ), .prdata32(),.*);

    apb_cr #(.A('h60), .DW(1))                   sfr_iox       (.cr(kpiosel   ), .prdata32(),.*);
    apb_cr #(.A('h64), .DW(10), .IV(10'h3ff))    sfr_aopadpu   (.cr(aopadpu   ), .prdata32(),.*);

//  rst
// ■■■■■■■■■■■■■■■


    logic [4:0] rstsrc;
    logic por;
    assign por = ~pmu_POR & padresetn ;

    aoresetgen #(.ICNT(1),.EXTCNT(10))genporreset(
        .clk         ( clk32k ),
        .cmsatpg     ( 1'b0 ),
        .resetn      ( por ),
        .resetnin    ( por ),
        .resetnout   ( porresetn_undft )
    );
    assign porresetn = cmsatpg ? atpgrst : porresetn_undft;

    assign rstsrc = { pmu_BGRDY, pmu_VR25RDY, pmu_VR85ARDY, pmu_VR85DRDY, ~pmu_POR } | rstcrmask;
    assign resetn = porresetn;

    `ifdef SIM
    parameter RSTEXTCNT = 10;
    `else
    parameter RSTEXTCNT = 312; //@32khz, 31.25 for 1ms.
    `endif

    logic socresetnin;
    assign socresetnin = cmsatpg ? 1'b1 : ~aopdreg & (&rstsrc) ;

    aoresetgen #(.ICNT(1),.EXTCNT(RSTEXTCNT))gensocreset(
        .clk         ( clk32k ),
        .cmsatpg     ( 1'b0 ),
        .resetn      ( porresetn_undft  ),
        .resetnin    ( padresetn & socresetnin ),
        .resetnout   ( socresetn_undft )
    );
    assign socresetn = cmsatpg ? atpgrst : socresetn_undft;

//  clk
// ■■■■■■■■■■■■■■■


//    assign clk = clksysao;
    assign pmu_osc32k_cfg = osc_trm;

`ifdef FPGA
    assign clkosc32k = clkxtl32k;
    assign clk32k = clkosc32k;
`else
    logic clk32k_unbuf;
    logic clk32k0, clk32k1;
    logic clkosc32ken, clkxtl32ken;
    logic osc32ken0, clkosc32k0;
    logic clkosc32k_dft, clkxtl32k_dft;

    assign osc32ken0 = cmsatpg ? '0 : osc_ctrl;
    assign clkosc32k_dft = cmsatpg ? clkocc : clkosc32k;
    assign clkxtl32k_dft = cmsatpg ? clkocc : clkxtl32k;
`ifdef OSC32KFAST
    OSC_32M osc32K ( .EN(osc32ken0), .CFG(pmu_osc32k_cfg),      .CKO( clkosc32k  ) );
`else
    OSC_32K osc32K ( .EN(osc32ken0), .CFG(pmu_osc32k_cfg),      .CKO( clkosc32k  ) );
`endif
    cgudyncswt uclk32ksel(
        .clk0   (clkosc32k_dft),
        .clk1   (clkxtl32k_dft),
        .resetn (porresetn),
        .clksel (clk32kselreg),
        .clk0en (clkosc32ken),
        .clk1en (clkxtl32ken)
    );
    ICG_hvt uclk32k0 ( .CK (clkosc32k), .EN ( clkosc32ken ), .SE(cmsatpg), .CKG ( clk32k0 ));
    ICG_hvt uclk32k1 ( .CK (clkxtl32k), .EN ( clkxtl32ken ), .SE(cmsatpg), .CKG ( clk32k1 ));

    CLKCELL_BUF_hvt buf_clk32k(.A(clk32k_unbuf),.Z(clk32k));
    assign clk32k_unbuf = cmsatpg ? clkocc : ( clk32k0 | clk32k1 ) ;
`endif
    logic clk1hzcnthit, clk1hz_unbuf, clk1hz_unbufreg;
    logic [13:0] clk1hzcnt;

    `theregfull( clk32k, resetn, clk1hz_unbufreg, 0 ) <= clk1hzcnthit ^ clk1hz_unbufreg ;
    `theregfull( clk32k, resetn, clk1hzcnt, 0 ) <= clk1hzcnthit ? '0 : clk1hzcnt + 1 ;
    assign clk1hzcnthit = ( clk1hzcnt == clk1hzfd );

    assign clk1hz_unbuf = cmsatpg ? clkocc : clk1hz_unbufreg;
    CLKCELL_BUF_hvt buf_clk1hz(.A(clk1hz_unbuf),.Z(clk1hz));

//  for syn
// ■■■■■■■■■■■■■■■
    logic ao_iso_enable_temp;
//    wire ao_iso_enable;
    logic pdisoreg;

    assign ao_iso_enable_temp = cmsatpg? 1'b0 : pdisoreg;

`ifdef FPGA
    assign ao_iso_enable = ao_iso_enable_temp;
`else
    //BUFFD8BWP35P140 u_iso_en_buf ( .I(ao_iso_enable_temp), .Z(ao_iso_enable) );
    //zmj 20241229
    BUFFD8BWP40P140HVT u_iso_en_buf ( .I(ao_iso_enable_temp), .Z(ao_iso_enable) );
`endif

//  apb peri
// ■■■■■■■■■■■■■■■
/*
    logic apbao2_pwrite_clk32k;
    logic wdtintr, tmrintr, rtcintr, wdtreset;

    logic apbao2_pread_clk32k;  //eco

    sync_pulse sync_apbao2_pwrite ( .clka(pclk),    .resetn, .clkb(clk32k), .pulsea (apbao2_pwrite), .pulseb( apbao2_pwrite_clk32k ) );
    sync_pulse sync_apbao2_pread ( .clka(pclk),    .resetn, .clkb(clk32k), .pulsea (apbao2_pread), .pulseb( apbao2_pread_clk32k ) ); //eco
    ao_peri aoperi(
            .pclk            (clk32k),
            .presetn         (porresetn),
            .pwrite          (apbao2_pwrite_clk32k),
            .penable         (~apbao2_pread_clk32k),    //eco
            .psel            (apbao2_paddr[13:12]),
            .paddr           (apbao2_paddr[11:2]),
            .pwdata          (apbao2_pwdata),
            .prdata          (apbao2_prdata),

            .clk32k (clk32k),
            .clk1hz (clk1hz),

            .wdtintr(wdtintr),
            .tmrintr(tmrintr),
            .rtcintr(rtcintr),
            .wdtrst (wdtreset)
    );
*/
// io ctrl
// ■■■■■■■■■■■■■■■

    generate
        for (genvar i = 0; i < 2; i++) begin:gio1
            assign aopad[i].po = socpad[i].po;
            assign aopad[i].pu = aopadpu[i];// ocpad[i].pu;
            assign aopad[i].oe = socpad[i].oe;
            assign socpad[i].pi = aopad[i].pi;
        end
        for (genvar i = 2; i < IOC; i++) begin:gio2
            assign aopad[i].po = kpiosel ? kpio[i-2].po : socpad[i].po;
            assign aopad[i].pu = aopadpu[i];//kpiosel ? kpio[i-2].pu : socpad[i].pu;
            assign aopad[i].oe = kpiosel ? kpio[i-2].oe : socpad[i].oe;
            assign socpad[i].pi = aopad[i].pi;
            assign kpio[i-2].pi = kpiosel ? socpad[i].pi : 1'b1;
        end
    endgenerate

//  pd / wakeup
// ■■■■■■■■■■■■■■■

    logic [9:0] pmupdresetsrc;
    logic aoperi_clrint_clk32k;
    logic [1:0] aowkupintregs;
    logic wkupint;
    logic kpcintr;
    logic pclkenreg0;
    logic [2:0] pdflowfsm;
    logic sfrpmupdarreg, pdar;
    logic pdflowfsmstop;
    `theregfull( pclk, pmupdresetn, pclkenreg0, '1 ) <= sfrpmupdarreg ? ~pclkicg : pclkenreg0 ;
    sync_pulse sync_pmupdar ( .clka(pclk),    .resetn, .clkb(clk32k), .pulsea (sfrpmupdarreg), .pulseb( pdar ) );
    `theregfull( pclk, resetn, sfrpmupdarreg, '0 ) <= sfrpmupdar;

    `theregfull( clk32k, resetn, pdflowfsm, '0 ) <= ( pdflowfsm != 0 ) | pdar ? (( pdflowfsm == 4 )&pdflowfsmstop ?  pdflowfsm : ( pdflowfsm == 7 ) ? '0 : pdflowfsm + 1 ) : pdflowfsm;
    `theregfull( clk32k, pmupdresetn, aopdreg, '0 ) <= ( pdflowfsm == 2 ) ? 1 : aopdreg;
    assign pdflowfsmstop = ~socresetn;
    `theregfull( clk32k, resetn, pdisoreg, '0 ) <= ( pdflowfsm == 1 ) ? pdisoen : ( pdflowfsm == 5 ) ? '0 :  pdisoreg ;

    assign pmupdresetn = cmsatpg ? atpgrst : ( ~|pmupdresetsrc ) & porresetn;

    assign aofr = {
                ~aopad[0].pi, ~aopad[1].pi, //~aopad[2].pi, ~aopad[3].pi, ~aopad[4].pi, ~aopad[5].pi,
                wkupintsrc
                };
    assign pmupdresetsrc =
                {
                ~aopad[0].pi, ~aopad[1].pi, //~aopad[2].pi, ~aopad[3].pi, ~aopad[4].pi, ~aopad[5].pi,
                wkupintsrc
                }& ~wkupmask ;

    assign aoint = |(wkupintsrc & inten);
    assign aowkupvld = ~pmupdresetn; //wakeup for socpd

    sync_pulse sync_aoperi_clrint ( .clka(pclk),    .resetn, .clkb(clk32k), .pulsea (aoperi_clrint), .pulseb( aoperi_clrint_clk32k ) );

    `theregfull( clk32k, resetn, wkupint, '0 ) <= (|pmupdresetsrc) ? '1 : aoperi_clrint_clk32k ? '0 : wkupint;
    `theregfull( pclk, resetn, aowkupintregs, '0 ) <= { aowkupintregs, wkupint };
    assign aowkupint = aowkupintregs[1];

    cgudyncswt upclksel(
        .clk0   (aopclk),
        .clk1   (clk32k),
        .resetn (porresetn),
        .clksel (~pclkenreg0),
        .clk0en (pclkenreg),
        .clk1en (pclk32kenreg)
    );

endmodule



module aoresetgen #(
        parameter ICNT = 4,
        parameter EXTCNT = 4096,
        parameter ECW = $clog2(EXTCNT)
    )(
        input   logic               clk,
        input   logic               cmsatpg,
        input   logic               resetn,
        input   logic [0:ICNT-1]    resetnin,
        output  logic               resetnout
    );

    bit [ECW-1:0] resetextcnt;
    logic resetextcnthit;
    logic resetext;
    logic resetninx;

    assign resetninx = &resetnin & resetn;

    `theregfull(clk, resetninx, resetextcnt, '0) <= resetextcnthit ? resetextcnt : resetextcnt + 1;
    `theregfull(clk, resetninx, resetext,    '0) <= resetextcnthit ;

    assign resetextcnthit = resetextcnt == EXTCNT-1;

`ifdef FPGA
    BUFG u0 (.I(resetext), .O(resetnout));
`else
    assign resetnout = cmsatpg | resetext;
`endif
endmodule

//`ifdef SIM
//module BUFFD8BWP35P140 (
//     input  wire I,
//     output wire Z
// );
//
//    assign Z = I;
//
// endmodule
//`endif
/*
module dummytb_ao_top (
);
    parameter IOC=10;
    parameter IPTBW = 26+7;
    apbif     apbs(),apbx();
    ioif       socpad[0:IOC-1]();
    ioif      aopad[0:IOC-1]();
    logic     clksysao;
    logic     pclk;
    logic    clkxtl32k;
    logic                 pmutrmset_nvr;
    logic [64-1:0]     socip_nvript;
    logic     ipsleep;
    logic    aowkupvld;
    logic  jtag_tck;
    logic  jtag_resetn;
    logic  tap_sel;
    logic  tap_capturedr;
    logic  tap_shiftdr;
    logic  tap_updatedr;
    logic  tap_en;
    logic  tap_tdi;
    logic  tap_tdo;
    wire  pmu_VR25EN;
    wire  pmu_VR85AEN;
    wire  pmu_VR85DEN;
    wire  pmu_BGRDY;
    wire  pmu_VR25RDY;
    wire  pmu_VR85ARDY;
    wire  pmu_VR85DRDY;
    wire  pmu_VR85A95ENA;
    wire  pmu_VR85D95ENA;
    wire  pmu_VR85AOSENA;
    wire  pmu_VR85DOSENA;
    wire  pmu_TRM_LATCH_b;
    wire [6-1:0] pmu_TRM_CUR;
    wire [5-1:0] pmu_TRM_CTAT;
    wire [5-1:0] pmu_TRM_PTAT;
    wire [5-1:0] pmu_TRM_D1P2;
    wire [5-1:0] pmu_TRM_DP60;
    wire  pmu_IOUTEN;
    wire  pmu_IBIASEN;
    wire  pmu_POR;
    wire [3-1:0] pmu_PMU_TEST_EN;
    wire [3-1:0] pmu_PMU_TEST_SEL;
    logic    padresetn;
    logic    socresetn;
    logic   pmu_POCENA;
    logic    aowkupint;
    logic [6:0] osc_osc32m_cfg;
    logic [0:5] ao_iptpo;

    ao_sysctrl  u(.*);

endmodule : dummytb_ao_top
*/


`ifdef SIM
module BUFFD8BWP40P140HVT (
     input  wire I,
     output wire Z
 );

    assign Z = I;

 endmodule
`endif
