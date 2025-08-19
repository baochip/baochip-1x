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
//`include "icg.v"

//import cms_pkg::*;

module sysctrl #(

    parameter ACKCNT = 8,
    parameter HCKCNT = 8,
    parameter ICKCNT = 8,
    parameter PCKCNT = 8,
    parameter IPMDC = 32,
    parameter bit [6:0]    IV_OSC32MTRM =    7'b0100110

    )(

        input logic clkxtl,

        output logic clksys,
        output logic clksys1m,
        output logic clksys1m_undft,
        output logic clktop,
        output logic clkper,
        output logic fclk,
        output logic aclk,
        output logic hclk,
        output logic iclk,
        output logic pclk,
        output logic aoclk,
        output logic clkaoram,

        output logic fclken,
        output logic aclken,
        output logic hclken,
        output logic iclken,
        output logic pclken,
        output logic aoclken,

        output logic fclken2,
        output logic aclken2,
        output logic hclken2,
        output logic iclken2,
        output logic pclken2,
        output logic aoclken2,

        output logic clkpke,

//        output logic fclksub,
        output logic [ACKCNT-1:0] aclksub,
        output logic [HCKCNT-1:0] hclksub,
        output logic [ICKCNT-1:0] iclksub,
        output logic [PCKCNT-1:0] pclksub,

        output logic [ACKCNT-1:0] aclksubgate,
        output logic [HCKCNT-1:0] hclksubgate,
        output logic [ICKCNT-1:0] iclksubgate,
        output logic [PCKCNT-1:0] pclksubgate,

        output logic ref1M,
        output logic ref32k,
        output logic [0:5] clkocc,
        output logic [0:5] clkbist,

        input   logic       cmsatpg,
        input   cms_pkg::cmscode_e   cmscode,
        input   logic       brdone,
        input   logic       atpg_ascapen,

        input logic socresetn,
        //input logic socresetn_undft,
        input logic secresetn, //##
        input logic padresetn,
        input logic wdtresetn,
        input logic vdresetn,

        output logic sysresetn,
        output logic coreresetn,
        input  logic wkupvld_async,

//        input  logic [IPMDC-1:0][31:0]  iptrim32,
        input  logic                    iptrimdatavld,
        output logic                    iptrimready,

        input  logic        coresleep,
        output logic [6:0]  ipsleep,
        output logic        xtalsleep,

        input  logic [6:0]  osc_osc32m_nvr,
        input  logic ipt_socset,
        input  logic [63:0] ipt_socreg,
        output wire pad_reton,
        output wire pad_retoff,
        output logic iptpopll, iptpoosc,

        output logic ipflowfsm_setipcr,

// dft
        input logic clkatpg, atpgrst, atpgse,
        output logic clksys_undft,
        output logic sysresetn_undft,
        output logic coreresetn_undft,

// apb
        input logic sfrlock,
        apbif.slavein apbs,
        apbif.slave   apbx

    );

    logic [15:0]    ipc_en;
    logic [15:0]    ipc_lpen;
    wire           resetn;
    logic           ipc_oscen;
    logic [6:0]     ipc_osc;
    logic           ipc_pllen;
    logic   clktopenin;

    logic clkosc, clkpll0, clkpll1;
    logic               cfgseltop, cfgselsys, cfgset, cfgsetar;
    bit   [0:5][7:0]    cfgfd, cfgfdlp, cfgfd0, cgufd, cgufd0, cfgfd0lp, cgufdlp;
    bit   [0:5][31:0]   cfgfdcr;
    bit [7:0]           ref1Mcnt;
    bit [9:0]           clk32kcnt;
    bit [7:0]           fsvld;
    bit [7:0][15:0]     fsfreq;
    bit [15:0]          fsintv;
    logic cmsresetn;
    logic [15:0]    rcufr;
    logic apbrd, apbwr;
    bit [15:0]  cgusec, cgulp;
    bit         cfgsel0, cfgsel0lp, cfgsel1;
    bit [1:0]   cfgsel0cr;
//    bit [7:0]   aclksubgate, hclksubgate, iclksubgate, pclksubgate;
    logic       sysreset_sw, corereset_sw;
    bit [15:0] ipccr;
    logic [16:0]  ipc_pllmn;
    logic [24:0]  ipc_pllf;
    logic [14:0]  ipc_pllq;
    bit pdreg;
    logic lp_deepen;
    logic pdresetn;
    bit [1:0] coresleepregs_clksys;
    logic clk32m;
    logic [7:0] pll_bias;
    logic clksys2;
    bit [7:0] aclksub_unmux, hclksub_unmux, iclksub_unmux, pclksub_unmux; //20240928 terrance
    logic clkosc_unmux, clkpll0_unmux, clkpll1_unmux;
    logic clk32m_unmux;
    logic [6:0]  osc_osc32m_cfg, osc_osc32m_cfgreg;
    bit cmsuser, cmstest;
    logic clk;
    logic [31:0] clkcipherseed;
    logic clkcipherseedupd;
    logic clkcipheren;

    logic [7:0] clkcipherdat;
    logic [3:0] clkcipherlevel;

    logic [11:0] ipflowfsm;
    logic       ipflowstart;
    logic       ipflow_settrim, ipflow_setar, ipflow_ipsleep, ipflow_settrim_corereset;
    logic [2:0] coreresetnregs;
    logic       ipflow_ipsleepstart;
    logic ipflowfsm_pd, ipflowfsm_fdoff, ipflowfsm_fdon;
    logic sysresetn_unbuf, coreresetn_unbuf;

    assign clk = clksys;
    localparam RCUEXTCNT = 2048;

// cgu source
// ■■■■■■■■■■■■■■■
        // depends on the IP

            parameter PLL_PREDIV_W  = 5  ;
            parameter PLL_FBDIV_W   = 12  ;
            parameter PLL_FRAC_W    = 24  ;
            parameter PLL_POSTDIV_W0 = 3  ;
            parameter PLL_POSTDIV_W1 = 3 ;

            logic ipc_setcfgpll;
            logic [ PLL_PREDIV_W-1   : 0 ] pll_m   ;
            logic [ PLL_FBDIV_W -1   : 0 ] pll_n   ;
            logic [ PLL_FRAC_W-1     : 0 ] pll_f   ;
            logic                          pll_fen ;
            logic [ PLL_POSTDIV_W0-1 : 0 ] pll_q00 ;
            logic [ PLL_POSTDIV_W1-1 : 0 ] pll_q10 ;
            logic [ PLL_POSTDIV_W0-1 : 0 ] pll_q01 ;
            logic [ PLL_POSTDIV_W1-1 : 0 ] pll_q11 ;

            assign pll_m = ipc_pllmn[16:12];
            assign pll_n = ipc_pllmn[11: 0];
            assign pll_f = ipc_pllf[23: 0];
            assign pll_fen = ipc_pllf[24];
            assign pll_q00 = ipc_pllq[ 2: 0];
            assign pll_q10 = ipc_pllq[ 6: 4];
            assign pll_q01 = ipc_pllq[10: 8];
            assign pll_q11 = ipc_pllq[14:12];

    logic clkocc1_800m, clkocc2_400m, clkocc3_200m, clkocc4_100m, clkocc5_50m, clkocc6_32m, clkocc7_300m;
    logic clk400mreg, clk200mreg, clk100mreg, clk50mreg;
    logic [6:0]clkplltestfdcnt;
    logic [3:0]clkosctestfdcnt;


    `ifdef FPGA
        `thereg( cmstest ) <=   '0;
        `thereg( cmsuser ) <=   '1;

//        localparam PLLMNIV = 16'h4080; // 200
        localparam PLLMNIV = 16'h4040; // 100

            logic [7:0] clkpll1cfg, clkpll0cfg;

            assign { clkpll1cfg, clkpll0cfg } = ipc_pllmn[15:0];
            assign clkosc = clk32m;

            dyna_clk_dual #(

                .START_F(16)
            ) udrp (
                .osc_clk        (clkxtl),
                .clk_sel_pins0  (clkpll0cfg),
                .clk_sel_pins1  (clkpll1cfg),
                .clkdrp0        (clkpll0),
                .clkdrp1        (clkpll1),
//                .clk_32M        (clk32m),
                .clk_32M        (),
                .led            (),
                .o_lock         ()
            );

        assign clk32m = clkxtl;

    `else
        `theregfull( clksys, sysresetn, cmstest, '0 ) <=   cmscode == cms_pkg::CMS_TEST |  cmscode == cms_pkg::CMS_VRGN;
        `theregfull( clksys, sysresetn, cmsuser, '0 ) <=   cmscode == cms_pkg::CMS_USER;

        localparam PLLMNIV = 16'h0;
//        assign clk32m = clkxtl;
        CLKCELL_BUF buf_clkxtl(.A(clkxtl),.Z(clk32m_unmux));

        `theregfull( clksys, sysresetn, osc_osc32m_cfgreg, IV_OSC32MTRM ) <= ipflow_settrim ? osc_osc32m_nvr : ipflowfsm_setipcr ? ipc_osc : osc_osc32m_cfgreg;
        assign osc_osc32m_cfg = cmstest | cmsatpg ? ipt_socreg[6:0] : osc_osc32m_cfgreg;

        logic clkosc_undft, ipc_oscen0;
        OSC_32M osc32M ( .EN(ipc_oscen0), .CFG(osc_osc32m_cfg),      .CKO( clkosc_undft  ) );
        assign ipc_oscen0 = cmsatpg ? '1 : ipc_oscen;
        assign clkosc_unmux = cmsatpg ? clkocc5_50m : clkosc_undft;

//        OSC_SIM #(1.30)     pll0   ( .EN(ipc_pllen), .CFG(ipc_pllcfg[6:0]), .CKO( clkpll0 ) );
//        OSC_SIM #(10)       pll1   ( .EN(ipc_pllen), .CFG(ipc_pllcfg[6:0]), .CKO( clkpll1 ) );
        assign pll_bias = ipccr[7:0];



        logic t_ipc_setcfgpll, ipc_setcfgpll_atclksys ;
        logic refclk;
        logic t_ipc_pllen;
        logic [ PLL_PREDIV_W-1   : 0 ] t_pll_m     ;
        logic [ PLL_FBDIV_W -1   : 0 ] t_pll_n     ;
        logic [ PLL_FRAC_W-1     : 0 ] t_pll_f     ;
        logic                      t_pll_fen   ;
        logic [ PLL_POSTDIV_W0-1 : 0 ] t_pll_q00 ;
        logic [ PLL_POSTDIV_W1-1 : 0 ] t_pll_q10 ;
        logic [ PLL_POSTDIV_W0-1 : 0 ] t_pll_q01 ;
        logic [ PLL_POSTDIV_W1-1 : 0 ] t_pll_q11 ;
        logic [ 7            : 0 ] t_pll_bias  ;

        cgupll #(
            .PREDIV_W   ( PLL_PREDIV_W   ),
            .FBDIV_W    ( PLL_FBDIV_W    ),
            .FRAC_W     ( PLL_FRAC_W     ),
            .POSTDIV_W0 ( PLL_POSTDIV_W0 ),
            .POSTDIV_W1 ( PLL_POSTDIV_W1 )
        )upll(
            .clk      ( clksys_undft ),
            .resetn   ( sysresetn_undft ),
            .cmsatpg  ( cmsatpg|cmstest ),
            .setcfg   ( t_ipc_setcfgpll ),
            .refclk   ( refclk  ),
            .pllen    ( t_ipc_pllen   ),
            .pll_m    ( t_pll_m   ),
            .pll_n    ( t_pll_n   ),
            .pll_f    ( '0   ),
            .pll_fen  ( t_pll_fen ),
            .pll_q00  ( t_pll_q00 ),
            .pll_q10  ( t_pll_q10 ),
            .pll_q01  ( t_pll_q01 ),
            .pll_q11  ( t_pll_q11 ),

            .gvco_bias (t_pll_bias[7:6] ),
            .cpp_bias  (t_pll_bias[5:3] ),
            .cpi_bias  (t_pll_bias[2:0] ),

             .clkpll0    (clkpll0_unmux),
             .clkpll1    (clkpll1_unmux)
        );

        assign refclk = cmsatpg | cmstest ? clkxtl : clksys2;

        assign t_ipc_setcfgpll = cmsatpg | cmstest ? ipt_socset : ipc_setcfgpll_atclksys;
        assign t_pll_m     = cmsatpg | cmstest ? ipt_socreg[ 36 : 32 ] : pll_m   ;
        assign t_pll_n     = cmsatpg | cmstest ? ipt_socreg[ 31 : 20 ] : pll_n   ;
        assign t_pll_f     = cmsatpg | cmstest ? '0                    : pll_f   ;
        assign t_pll_fen   = cmsatpg | cmstest ? '1                    : pll_fen ;
        assign t_pll_q00   = cmsatpg | cmstest ? ipt_socreg[ 19 : 17 ] : pll_q00 ;
        assign t_pll_q10   = cmsatpg | cmstest ? ipt_socreg[ 16 : 14 ] : pll_q10 ;
        assign t_pll_q01   = cmsatpg | cmstest ? ipt_socreg[ 13 : 11 ] : pll_q01 ;
        assign t_pll_q11   = cmsatpg | cmstest ? ipt_socreg[ 10 : 8  ] : pll_q11 ;
        assign t_ipc_pllen = cmsatpg | cmstest ? ipt_socreg[ 7 ]       : ipc_pllen ;
        assign t_pll_bias  = cmsatpg | cmstest ? ipt_socreg[ 44 : 37 ] : pll_bias;

     CLKCELL_MUX2 u_scanmux_clkosc   (.A(clkosc_unmux),.B(clkocc6_32m),.S(cmsatpg),.Z(clkosc));
     CLKCELL_MUX2 u_scanmux_clk32m   (.A(clk32m_unmux),.B(clkocc6_32m),.S(cmsatpg),.Z(clk32m));
     CLKCELL_MUX2 u_scanmux_clkpll0  (.A(clkpll0_unmux),.B(clkocc1_800m),.S(cmsatpg),.Z(clkpll0));
     CLKCELL_MUX2 u_scanmux_clkpll1  (.A(clkpll1_unmux),.B(clkocc7_300m),.S(cmsatpg),.Z(clkpll1));


    sync_pulse sync_setpll(
        .clka       (pclk),
        .resetn     (coreresetn),
        .pulsea     (ipc_setcfgpll),
        .clkb       (clksys_undft),
        .pulseb     (ipc_setcfgpll_atclksys)
    );

    `endif
// dft
// ■■■■■■■■■■■■■■■

     // ##########zmj 20240928
     logic clkpll0_dft0, clkpll0_dft;
     logic clkpll1_dft0, clkpll1_dft;

     assign clkpll0_dft0 = (cmsatpg | cmstest) ? clkpll0_unmux : 1'b0;
     CLKCELL_BUF u_icg_clkpll0_dft (.A(clkpll0_dft0),.Z(clkpll0_dft));

     assign clkpll1_dft0 = (cmsatpg | cmstest) ? clkpll1_unmux : 1'b0;
     CLKCELL_BUF u_icg_clkpll1_dft (.A(clkpll1_dft0),.Z(clkpll1_dft));

     `theregfull( clkpll0_dft,   sysresetn, clk400mreg, '0) <= ~clk400mreg & ( cmsatpg | cmstest );
     `theregfull( clk400mreg,    sysresetn, clk200mreg, '0) <= ~clk200mreg & ( cmsatpg | cmstest );
     `theregfull( clk200mreg,    sysresetn, clk100mreg, '0) <= ~clk100mreg & ( cmsatpg | cmstest );
     `theregfull( clk100mreg,    sysresetn, clk50mreg , '0) <= ~clk50mreg  & ( cmsatpg | cmstest );

     CLKCELL_BUF u_occ1_800m (.A(clkpll0_dft),  .Z(clkocc1_800m));
     CLKCELL_BUF u_occ2_400m (.A(clk400mreg),   .Z(clkocc2_400m));
     CLKCELL_BUF u_occ3_200m (.A(clk200mreg),   .Z(clkocc3_200m));
     CLKCELL_BUF u_occ4_100m (.A(clk100mreg),   .Z(clkocc4_100m));
     CLKCELL_BUF u_occ5_50m  (.A(clk50mreg),    .Z(clkocc5_50m));
     CLKCELL_BUF u_occ6_32m  (.A(clk50mreg),    .Z(clkocc6_32m));
     CLKCELL_BUF u_occ7_300m (.A(clkpll1_dft),  .Z(clkocc7_300m));

     assign clkocc[0:5] = { clkocc1_800m, clkocc2_400m, clkocc3_200m, clkocc4_100m, clkocc5_50m, clkocc6_32m };

    logic [0:5] clkbist_unmux;

     CLKCELL_BUF u_bist1_800m (.A(clkpll0_dft),  .Z(clkbist_unmux[0])); CLKCELL_MUX2 u_scanmux_clkbist0 ( .A(clkbist_unmux[0]), .B(clkocc[0]), .S(cmsatpg), .Z(clkbist[0]) );
     CLKCELL_BUF u_bist2_400m (.A(clk400mreg),   .Z(clkbist_unmux[1])); CLKCELL_MUX2 u_scanmux_clkbist1 ( .A(clkbist_unmux[1]), .B(clkocc[1]), .S(cmsatpg), .Z(clkbist[1]) );
     CLKCELL_BUF u_bist3_200m (.A(clk200mreg),   .Z(clkbist_unmux[2])); CLKCELL_MUX2 u_scanmux_clkbist2 ( .A(clkbist_unmux[2]), .B(clkocc[2]), .S(cmsatpg), .Z(clkbist[2]) );
     CLKCELL_BUF u_bist4_100m (.A(clk100mreg),   .Z(clkbist_unmux[3])); CLKCELL_MUX2 u_scanmux_clkbist3 ( .A(clkbist_unmux[3]), .B(clkocc[3]), .S(cmsatpg), .Z(clkbist[3]) );
     CLKCELL_BUF u_bist5_50m  (.A(clk50mreg),    .Z(clkbist_unmux[4])); CLKCELL_MUX2 u_scanmux_clkbist4 ( .A(clkbist_unmux[4]), .B(clkocc[4]), .S(cmsatpg), .Z(clkbist[4]) );
     CLKCELL_BUF u_bist6_32m  (.A(clk50mreg),    .Z(clkbist_unmux[5])); CLKCELL_MUX2 u_scanmux_clkbist5 ( .A(clkbist_unmux[5]), .B(clkocc[5]), .S(cmsatpg), .Z(clkbist[5]) );

     `theregfull( clkpll0_dft, sysresetn, clkplltestfdcnt, '0 ) <= ( clkplltestfdcnt == 49 ) ? 0 : clkplltestfdcnt + cmstest ;
     `theregfull( clkpll0_dft, sysresetn, iptpopll, '0 ) <= ( clkplltestfdcnt == 49 ) ? cmstest ^ iptpopll : iptpopll;

     `theregfull( clkosc_unmux, sysresetn, clkosctestfdcnt, '0 ) <= ( clkosctestfdcnt == 9 ) ? 0 : clkosctestfdcnt + cmstest ;
     `theregfull( clkosc_unmux, sysresetn, iptpoosc, '0 ) <= ( clkosctestfdcnt == 9 ) ? cmstest ^ iptpoosc : iptpoosc;

// cgu path sel, cgu fd
// ■■■■■■■■■■■■■■■

    bit [2:0] cfgsetinitregs;
    bit       cfgsetinit;
    logic cfgsetslp, cfgsetwkup;
    logic cfgsetdpslp, cfgsetdpwkup;
    bit [0:1]   clksysselen, clktopselen;
    logic aoclkpre,clkpketop;
    logic clktopenin_ipflow, clktopenin_sec;
    logic fdload;
    assign fdload = cfgset|cfgsetinit|cfgsetslp|cfgsetwkup|cfgsetdpslp|cfgsetdpwkup;

    `theregfull( clktop, coreresetn, clktopenin_ipflow, '1 ) <= cfgsetdpslp ? ~pdreg : cfgsetdpwkup ? '1 : clktopenin_ipflow;

    cgucore
    #(
//        .FDW = 8,
//        .GEARLMT = 2**FDW
    )ucgucore(
        /*input   logic [0:ICNT-1]    */.clksrc             ({clkosc_undft,clk32m,clkpll0,clkpll1}),
                                        .cmsatpg            (cmsatpg),
                                        .atpg_ascapen,
                                         .clkocc1_800m       (clkocc1_800m),
                                         .clkocc2_400m       (clkocc2_400m),
                                         .clkocc3_200m       (clkocc3_200m),
                                         .clkocc4_100m       (clkocc4_100m),
                                         .clkocc5_50m        (clkocc5_50m),
                                         .clkocc7_300m       (clkocc7_300m),
       /*input   logic               */.porresetn          (sysresetn),
        /*input   logic               */.resetn             (sysresetn),//coreresetn),
        /*input   logic               */.clksyssel          (cfgselsys),
        /*input   logic               */.clktopselupdate    (cfgset|cfgsetinit|cfgsetslp|cfgsetwkup|cfgsetdpslp|cfgsetdpwkup),
        /*input   logic               */.clktopsel          (cfgseltop),
        /*output  logic               */.clksys             (clksys),
        /*output  logic               */.clksys2            (clksys2),
        /*output  logic               */.clksys_undft       (clksys_undft),
        /*output  logic               */.clktop             (clktop),
        /*output  logic               */.clkpke             (clkpketop),
        /*input   logic               */.clktopenin         (clktopenin),
        /*input   bit   [0:OCNT-1][FDW*/.fd0                (cgufd0),
        /*input   bit   [0:OCNT-1][FDW*/.fd                 (cgufd),
        /*input   bit                 */.fdload             ,
        /*output  logic [0:OCNT-1]    */.clkout             ({fclk,aclk,hclk,iclk,pclk,aoclkpre}),
        /*output  logic [0:OCNT-1]    */.clkouten           ({fclken,aclken,hclken,iclken,pclken,aoclken}),
        /*output  logic [0:OCNT-1]    */.clkouten_atparent  ({fclken2,aclken2,hclken2,iclken2,pclken2,aoclken2}),
                                        .clksysselen        (clksysselen),
                                        .clktopselen        (clktopselen)
    );

    logic [3:0] clksys1mcnt;
    logic clksys1mreg;
    `theregfull( clksys_undft, sysresetn_undft, clksys1mcnt, '0 ) <= clksys1mcnt + 1;
    `theregfull( clksys_undft, sysresetn_undft, clksys1mreg, '0 ) <= ( clksys1mcnt == '1 ) ^ clksys1mreg;
    logic clksys1mreg_unmux;

    CLKCELL_BUF buf_clksysao_undft(.A(clksys1mreg),.Z(clksys1m_undft));
    CLKCELL_BUF buf_clksysao(.A(clksys1mreg_unmux),.Z(clksys1m));
    CLKCELL_MUX2 u_scanmux_clksys1m  (.A(clksys1mreg),.B(clkocc6_32m),.S(cmsatpg),.Z(clksys1mreg_unmux));

    assign cfgsel0   = cfgsel0cr[0];
    assign cfgsel0lp = cfgsel0cr[1];
    assign cfgseltop = cfgsetdpslp ? '0 : cfgsetslp ? cfgsel0lp : cfgsel0;

    assign { cfgfd0lp[0], cfgfd0[0], cfgfdlp[0], cfgfd[0] } = cfgfdcr[0];
    assign { cfgfd0lp[1], cfgfd0[1], cfgfdlp[1], cfgfd[1] } = cfgfdcr[1];
    assign { cfgfd0lp[2], cfgfd0[2], cfgfdlp[2], cfgfd[2] } = cfgfdcr[2];
    assign { cfgfd0lp[3], cfgfd0[3], cfgfdlp[3], cfgfd[3] } = cfgfdcr[3];
    assign { cfgfd0lp[4], cfgfd0[4], cfgfdlp[4], cfgfd[4] } = cfgfdcr[4];
    assign { cfgfd0lp[5], cfgfd0[5], cfgfdlp[5], cfgfd[5] } = cfgfdcr[5];

    assign cgufd  = cfgsetdpslp ? '0 : cfgsetslp ? cfgfdlp  : cfgfd ;
    assign cgufd0 = cfgsetdpslp ? '0 : cfgsetslp ? cfgfd0lp : cfgfd0;

    assign cfgselsys = cfgsel1;
    assign clktopenin = clktopenin_sec & clktopenin_ipflow;

    `theregfull(clktop, coreresetn, cfgsetinitregs, 3'h1 ) <= cfgsetinitregs * 2;
    assign cfgsetinit = cfgsetinitregs[1];

    assign cfgset = cfgsetar & pclken;


// clkout : ao/aoram
// ==


    logic [15:0] cfgfdaoram;
`ifdef FPGA
    assign clkaoram = aoclkpre;
    assign aoclk = aoclkpre;
`else
    bit aoclkreg;
    bit clkaoramreg, clkaoramen;
    logic [7:0] fdaoram, fdaoram0;

//    `theregfull( fclk, socresetn, aoclkreg, '0 )
    always@(posedge fclk ) aoclkreg <= aoclken ? ~aoclkreg : aoclkreg;
    CLKCELL_MUX2 u_scanmux_aoclk  (.A(aoclkreg),.B(clkocc5_50m),.S(cmsatpg),.Z(aoclk));

    assign { fdaoram0, fdaoram } = cfgfdaoram;
    cgufdsync fduaoram(
        .clk            (clktop),
        .resetn         (sysresetn),
        .clk0en         (clktopenin),
        .clk1en         (iclken),
        .fd0            (fdaoram0),
        .fd2            (fdaoram),
        .fdload         (fdload),
        .clk2en         (clkaoramen),
        .clk2en_atclk1  ()
    );

//    `theregfull( fclk, sysresetn, clkaoramreg, '0 ) <= clkaoramen ? ~clkaoramreg : clkaoramreg;
     always@(posedge fclk ) clkaoramreg <= clkaoramen ? ~clkaoramreg : clkaoramreg;
    CLKCELL_MUX2 u_scanmux_clkaoram  (.A(clkaoramreg),.B(clkocc5_50m),.S(cmsatpg),.Z(clkaoram));
`endif

// clkout 5 : pke
// ==


    logic clkpketopenin;
    logic [7:0] fdpke;
    logic oclkpkeen;// clkpkeen;
    logic clkpke_unmux;
    logic [7:0] cfgfdpke;
    logic [31:0] clkpkecipherseed;
    logic clkpkecipherseedupd,clkpkecipheren;
    logic [7:0] clkpkecipherdat;
    logic [3:0] clkpkecipherlevel;
    logic fdload_clkpke;

`ifdef FPGA
    assign clkpke = hclk;
`else

    assign { fdpke } = cfgfdpke;

    cgufdsync fdupke(
        .clk            (clkpketop),
        .resetn         (sysresetn),
        .clk0en         (clkpketopenin),
        .clk1en         (1'b1),
        .fd0            (8'h0),
        .fd2            (fdpke),
        .fdload         (fdload_clkpke),
        .clk2en         (oclkpkeen),
        .clk2en_atclk1  ()
    );

    sync_pulse syncfdload(
        .clka       (clktop),
        .resetn     (coreresetn),
        .pulsea     (fdload),
        .clkb       (clkpketop),
        .pulseb     (fdload_clkpke)
    );

    ICG fdicgpke ( .CK (clkpketop   ), .EN ( oclkpkeen ), .SE(cmsatpg), .CKG ( clkpke ));
//    CLKCELL_MUX2 u_scanmux_clkpke  (.A(clkpke_unmux),.B(clkocc3_200m),.S(cmsatpg),.Z(clkpke));
`endif

    drng_lfsr #( .LFSR_W(59),.LFSR_NODE({ 10'd57, 10'd55, 10'd52 }), .LFSR_OW(8), .LFSR_IW(32), .LFSR_IV('hfedcba9876543210) )
        ub( .clk(clkpketop), .sen(clkpkecipheren), .resetn(sysresetn), .swr(clkpkecipherseedupd), .sdin(clkpkecipherseed), .sdout(clkpkecipherdat) );

`ifdef FPGA
    `theregfull( clkpketop, coreresetn, clkpketopenin, '1 ) <= '1;
`else
    `theregfull( clkpketop, coreresetn, clkpketopenin, '1 ) <= clkpkecipheren ? ( clkpkecipherdat >= clkpkecipherlevel * 16 ) : '1;
`endif

    assign clkpkecipherlevel = cgusec[11:8];
    assign clkpkecipheren = cgusec[12];

    assign clkpkecipherseed = clkcipherseed;
//    assign clkpkecipherseedupd = clkcipherseedupd;

    sync_pulse syncpulse_clkpkecipherseedupd(
        .clka       (pclk),
        .resetn     (sysresetn),
        .pulsea     (clkcipherseedupd),
        .clkb       (clkpketop),
        .pulseb     (clkpkecipherseedupd)
    );

// clkout 5 : per
// ==

//`ifdef FPGA
//    assign clkper = clkpll1;
//`else
    logic [7:0] fdper,fdperlp,fdper0,fdper0lp,fdper0s,fdpers ;
    bit   oclkperen, clkperreg;// clkperen;
    logic clkper_unmux;
    logic [31:0] cfgfdper;

    assign { fdper0lp, fdper0, fdperlp, fdper } = cfgfdper;

    assign fdpers = cfgsetdpslp ? '0 : cfgsetslp ? fdperlp : fdper;
    assign fdper0s = cfgsetslp ? fdper0lp : fdper0;

    cgufdsync fduper(
        .clk            (clktop),
        .resetn         (sysresetn),
        .clk0en         (1'b1),
        .clk1en         (1'b1),
        .fd0            (fdper0s),
        .fd2            (fdpers),
        .fdload         (fdload),
        .clk2en         (oclkperen),
        .clk2en_atclk1  ()
    );

    always@(posedge clktop) clkperreg <=  oclkperen ? ~clkperreg : clkperreg;
    CLKCELL_MUX2 u_scanmux_clkper  (.A(clkperreg),.B(clkocc4_100m),.S(cmsatpg),.Z(clkper));
//`endif

genvar gvi;
`ifdef FPGA
generate
    for (gvi = 0; gvi < ACKCNT; gvi++) begin: genaclksub
             assign aclksub[gvi] = aclk;
    end
    for (gvi = 0; gvi < HCKCNT; gvi++) begin: genhclksub
             assign hclksub[gvi] = hclk;
    end
    for (gvi = 0; gvi < ICKCNT; gvi++) begin: geniclksub
             assign iclksub[gvi] = iclk;
    end
    for (gvi = 0; gvi < PCKCNT; gvi++) begin: genpclksub
             assign pclksub[gvi] = pclk;
    end
endgenerate
`else
generate
    for (gvi = 0; gvi < ACKCNT; gvi++) begin: genaclksub
             ICG uaclksub ( .CK (clktop   ), .EN ( aclken & aclksubgate[gvi] ), .SE(cmsatpg), .CKG ( aclksub_unmux[gvi] ));
             CLKCELL_MUX2 u_scanmux_clkasub  (.A(aclksub_unmux[gvi]),.B(clkocc2_400m),.S(atpg_ascapen),.Z(aclksub[gvi]));
    end
    for (gvi = 0; gvi < HCKCNT; gvi++) begin: genhclksub
             ICG uhclksub ( .CK (clktop   ), .EN ( hclken & hclksubgate[gvi] ), .SE(cmsatpg), .CKG ( hclksub_unmux[gvi] ));
             CLKCELL_MUX2 u_scanmux_clkhsub  (.A(hclksub_unmux[gvi]),.B(clkocc3_200m),.S(atpg_ascapen),.Z(hclksub[gvi]));
    end
    for (gvi = 0; gvi < ICKCNT; gvi++) begin: geniclksub
             ICG uiclksub ( .CK (clktop   ), .EN ( iclken & iclksubgate[gvi] ), .SE(cmsatpg), .CKG ( iclksub_unmux[gvi] ));
             CLKCELL_MUX2 u_scanmux_clkisub  (.A(iclksub_unmux[gvi]),.B(clkocc4_100m),.S(atpg_ascapen),.Z(iclksub[gvi]));
    end
    for (gvi = 0; gvi < PCKCNT; gvi++) begin: genpclksub
             ICG upclksub ( .CK (clktop   ), .EN ( pclken & pclksubgate[gvi] ), .SE(cmsatpg), .CKG ( pclksub_unmux[gvi] ));
             CLKCELL_MUX2 u_scanmux_clkpsub  (.A(pclksub_unmux[gvi]),.B(clkocc5_50m),.S(atpg_ascapen),.Z(pclksub[gvi]));
    end
endgenerate
`endif
// cgu: freq meter, fixed clk
// ■■■■■■■■■■■■■■■

    freqmeter #(
            .FSCNT(8)
        )cgufs(
            .clk        (clksys),
            .cmsatpg    (cmsatpg),
            .resetn     (resetn),
            .interval   (fsintv),
            .clkin      ({fclk, clkpke, aoclk, clkaoram, clkosc,clk32m,clkpll0,clkpll1}),
            .fsvld      (fsvld),
            .fsfreq     (fsfreq)
        );

    `theregfull( clksys, sysresetn, ref1Mcnt, 0 ) <= ( ref1Mcnt == fsintv -1 ) ? 0 : ref1Mcnt + 1;
    `theregfull( clksys, sysresetn, ref1M, 0 )    <= ( ref1Mcnt == fsintv/2 ) ? 1'b1 : ( ref1Mcnt == fsintv -1 ) ? 1'b0 : ref1M;

    `theregfull( clksys, sysresetn, clk32kcnt, 0 ) <= ( clk32kcnt == 1000 -1 ) ? 0 : clk32kcnt + 1;
    `theregfull( clksys, sysresetn, ref32k, 0 )    <= ( clk32kcnt == 1000/2 ) ? 1'b1 : ( clk32kcnt == 1000 -1 ) ? 1'b0 : ref32k;



// clk cipher
// ■■■■■■■■■■■■■■■


    drng_lfsr #( .LFSR_W(59),.LFSR_NODE({ 10'd57, 10'd55, 10'd52 }), .LFSR_OW(8), .LFSR_IW(32), .LFSR_IV('h55aa_aa55_5a5a_a5a5) )
        ua( .clk(clktop), .sen(clkcipheren), .resetn(sysresetn), .swr(clkcipherseedupd), .sdin(clkcipherseed), .sdout(clkcipherdat) );

`ifdef FPGA
    `theregfull( clktop, coreresetn, clktopenin_sec, '1 ) <= '1;
`else
    `theregfull( clktop, coreresetn, clktopenin_sec, '1 ) <= clkcipheren ? ( clkcipherdat >= clkcipherlevel * 16 ) : '1;
`endif

    assign clkcipherlevel = cgusec[3:0];
    assign clkcipheren = cgusec[4];

// ip ctrl
// ■■■■■■■■■■■■■■■

// static ip control

    assign ipc_oscen = ( ipc_en[0] | cfgsel1 == 0 ) & ~ipsleep[0] | clksysselen[0] | ~clksysselen[1];
    assign ipc_pllen = ( ipc_en[1] | cfgsel0 == 1 ) & ~ipsleep[1] | clktopselen[1] | ~clktopselen[0];
    assign xtalsleep = ipsleep[4] & pdreg;

// ip fsm flow

    localparam IPFLOWFSM_FDOFF = 12'd256;
    localparam IPFLOWFSM_PD = 12'd512;
    localparam IPFLOWFSM_FDON = 12'hfd0;
    localparam IPFLOWFSM_DONE = 12'hfff;

`ifdef FPGA
    assign ipflowstart = '0;
    assign ipflowfsm = '0;
`else
    assign ipflowstart = ipflow_settrim | ipflow_setar | ipflow_ipsleepstart | ipflow_settrim_corereset; // @clksys
    `theregfull( clksys, sysresetn, ipflowfsm, '1 ) <= ipflowstart ? '0 : ( ipflowfsm != IPFLOWFSM_DONE ) ?
                                                                (( ipflowfsm == IPFLOWFSM_PD ) & ( ~lp_deepen & coresleep | pdreg )  ? ipflowfsm : ipflowfsm + 1 ) : ipflowfsm;
`endif

    `theregfull( clksys, sysresetn, ipflowfsm_pd,    '0 ) <= ( ipflowfsm == IPFLOWFSM_PD );
    `theregfull( clksys, sysresetn, ipflowfsm_fdoff, '0 ) <= ( ipflowfsm == IPFLOWFSM_FDOFF );
    `theregfull( clksys, sysresetn, ipflowfsm_fdon,  '0 ) <= ( ipflowfsm == IPFLOWFSM_FDON );

    logic ipflowfsm_setipcrflag;
    `theregfull( clksys, sysresetn, ipflowfsm_setipcrflag,  '0 ) <= ipflowstart ? ipflow_setar : ipflowfsm_setipcr ? '0 : ipflowfsm_setipcrflag;
    assign ipflowfsm_setipcr = ipflowfsm_fdoff & ipflowfsm_setipcrflag;

    sync_pulse ipflowfoff(
        .clka       (clksys),
        .resetn     (sysresetn),
        .pulsea     (ipflowfsm_fdoff),
        .clkb       (clktop),
        .pulseb     (cfgsetdpslp)
    );

    sync_pulse ipflowfon(
        .clka       (clksys),
        .resetn     (sysresetn),
        .pulsea     (ipflowfsm_fdon),
        .clkb       (clktop),
        .pulseb     (cfgsetdpwkup)
    );

    `theregfull( clksys, sysresetn, coreresetnregs, '0 ) <= cmsatpg ? 0 : { coreresetnregs, coreresetn };
    assign ipflow_settrim_corereset = ~coreresetnregs[1] & coreresetnregs[2];

// iptrim handshake

    logic iptrimdatavldreg, iptrimbusy;

    `theregfull( clksys, sysresetn, iptrimbusy, '0) <= ipflow_settrim ? '1 : ( ipflowfsm == IPFLOWFSM_DONE ) ? '0 : iptrimbusy;
    `theregfull( clksys, sysresetn, iptrimready, '0 ) <= iptrimready | (( ipflowfsm == IPFLOWFSM_DONE ) & iptrimbusy );
    `theregfull( clksys, sysresetn, iptrimdatavldreg, '0 ) <= iptrimdatavld;
    assign ipflow_settrim = iptrimdatavldreg;

// pad reton/off

    logic pad_retonreg;

    `theregfull( pclk, socresetn, pad_retonreg, '0) <= ipccr[8];
    assign pad_reton = cmsatpg ? 0 : pad_retonreg;
    assign pad_retoff = ~pad_reton;

// lp
// ■■■■■■■■■■■■■■■

    logic lp_fdlpen, lp_iplpen, lp_clkstplpen;

    assign lp_fdlpen = (cgulp[2:0] == 3'h1) ;
    assign lp_iplpen = cgulp[1];
    assign lp_deepen = cgulp[2];

// cgu lp

    logic coresleepreg, coresleeprise, coresleepfall;

    assign cfgsetwkup = coresleepfall & lp_fdlpen;
    assign cfgsetslp  = coresleeprise & lp_fdlpen;
    `theregfull( clktop, coreresetn, coresleepreg, '0 ) <= coresleep;
    assign coresleeprise =  coresleep & ~coresleepreg;
    assign coresleepfall = ~coresleep &  coresleepreg;


    logic pdresetn0;
//    `theregfull( clksys, pdresetn, coresleepregs_clksys, '0 ) <= { coresleepregs_clksys, 1'b1};
    `theregfull( clksys, pdresetn0, coresleepregs_clksys, '0 ) <= { coresleepregs_clksys, coresleep};
    `theregfull( clksys, pdresetn, pdreg, '0 ) <= ( coresleepregs_clksys[0] & ~coresleepregs_clksys[1] ) & lp_deepen | pdreg;
    assign pdresetn = cmsatpg ? atpgrst : coreresetn & ~wkupvld_async & coresleep;
    assign pdresetn0 = cmsatpg ? atpgrst : coreresetn & ~wkupvld_async;

// ip lp
    logic ipflowfsm_ipsleep;

    `theregfull( clksys, coreresetn, ipflowfsm_ipsleep, '0 ) <= ( ipflowfsm == IPFLOWFSM_PD - 1 ) ? '1 : ( ipflowfsm == IPFLOWFSM_PD + 1 ) ? '0 : ipflowfsm_ipsleep;
    assign ipsleep = ipflow_ipsleep & ipflowfsm_ipsleep ? ipc_lpen : '0;

    assign ipflow_ipsleep = coresleep & lp_iplpen;
    assign ipflow_ipsleepstart = ( coresleepregs_clksys[0] & ~coresleepregs_clksys[1] ) & lp_iplpen;

// reset ctrl
// ■■■■■■■■■■■■■■■

    assign cmsresetn = ( cmscode == cms_pkg::CMS_USER ) & brdone;
    assign rcufr = cmsatpg ? '0 : ('0 | { ~sysresetgen.resetnin, ~coreresetgen.resetnin });

    resetgen #(.ICNT(4),.EXTCNT(RCUEXTCNT))sysresetgen(
        .clk         ( clksys ),
        .cmsatpg     ( cmsatpg ),
        .resetn      ( socresetn ),
        .resetnin    ( { socresetn, vdresetn, secresetn, ~sysreset_sw } ),
        .resetnout   ( sysresetn_unbuf )
    );


    resetgen #(.ICNT(5),.EXTCNT(RCUEXTCNT))coreresetgen(
        .clk         ( clksys ),
        .cmsatpg     ( cmsatpg ),
        .resetn      ( sysresetn ),
        .resetnin    ( { padresetn, sysresetn, cmsresetn, wdtresetn, ~corereset_sw } ),
        .resetnout   ( coreresetn_unbuf )
    );

    assign resetn = coreresetn;
    assign sysresetn_undft =  sysresetn_unbuf;
    assign coreresetn_undft = coreresetn_unbuf;
    assign sysresetn  = cmsatpg ? atpgrst : sysresetn_unbuf;
    assign coreresetn = cmsatpg ? atpgrst : coreresetn_unbuf;

// sfr
// ■■■■■■■■■■■■■■■

    bit [31:0] owr;

    `apbs_common;
    assign apbx.prdata = '0
                | sfr_cgusec.prdata32  | sfr_cgulp.prdata32 | sfr_seed.prdata32
                | sfr_cgusel0.prdata32 | sfr_cgufd.prdata32 | sfr_cgusel1.prdata32 | sfr_cgufdao.prdata32 | sfr_cgufdpke.prdata32 | sfr_cgufdper.prdata32 | sfr_cgufdaoram.prdata32
                | sfr_cgufssr.prdata32 | sfr_cgufscr.prdata32 | sfr_cgufsvld.prdata32
                | sfr_aclkgr.prdata32  | sfr_hclkgr.prdata32 | sfr_iclkgr.prdata32 | sfr_pclkgr.prdata32
                | sfr_rcusrcfr.prdata32
                | sfr_ipccr.prdata32 | sfr_ipcen.prdata32 | sfr_ipclpen.prdata32 | sfr_ipcosc.prdata32
                | sfr_ipcpllmn.prdata32 | sfr_ipcpllf.prdata32 | sfr_ipcpllq.prdata32
                | sfr_owr.prdata32
                ;

// cgu cfg cr
    apb_cr #(.A('h00), .DW(16))     sfr_cgusec  (.cr(cgusec),   .prdata32(),.*);
    apb_cr #(.A('h04), .DW(16))     sfr_cgulp   (.cr(cgulp ),   .prdata32(),.*);

    apb_cr #(.A('h08), .DW(32))       sfr_seed    (.cr(clkcipherseed),   .prdata32(),.*);
    apb_ar #(.A('h0C), .AR('h5a))     sfr_seedar  (.ar(clkcipherseedupd), .*);

    apb_cr #(.A('h10), .DW(1*2))      sfr_cgusel0 (.cr(cfgsel0cr),  .prdata32(),.*);
    apb_cr #(.A('h14), .DW(8*4),
             .IV('h00000f7f), .SFRCNT(5))         sfr_cgufd       (.cr(cfgfdcr[0:4]),   .prdata32(),.*);
    apb_cr #(.A('h3c), .DW(32), .IV('hffffff)  )  sfr_cgufdper    (.cr(cfgfdper),       .prdata32(),.*);
    apb_cr #(.A('h34), .DW(8),  .IV('hff)      )  sfr_cgufdpke    (.cr(cfgfdpke),       .prdata32(),.*);
    apb_cr #(.A('h28), .DW(32), .IV('h0f0f0f0f))  sfr_cgufdao     (.cr(cfgfdcr[5]),     .prdata32(),.*);
    apb_cr #(.A('h38), .DW(16), .IV('h0f0f)    )  sfr_cgufdaoram  (.cr(cfgfdaoram),     .prdata32(),.*);

    apb_ar #(.A('h2c), .AR('h32))   sfr_cguset  (.ar(cfgsetar),               .*);
    apb_cr #(.A('h30), .DW(1))      sfr_cgusel1 (.cr(cfgsel1),  .prdata32(),  .resetn(sysresetn),.*);

// cgu freq meter
    apb_sr #(.A('h40), .DW(32), .SFRCNT(4)   )  sfr_cgufssr   (.sr(fsfreq),     .prdata32(),.*);
    apb_sr #(.A('h50), .DW(8)            )      sfr_cgufsvld  (.sr(fsvld),      .prdata32(),.*);
    apb_cr #(.A('h54), .DW(16), .IV('d48))      sfr_cgufscr   (.cr(fsintv),     .prdata32(),.*);

// clkgate
`ifdef FPGA
    assign aclksubgate = 8'hff;
    assign hclksubgate = 8'hff;
    assign iclksubgate = 8'hff;
    assign pclksubgate = 8'hff;
    apb_sr #(.A('h60), .DW(ACKCNT)             ) sfr_aclkgr     (.sr(aclksubgate),.prdata32(),.*);
    apb_sr #(.A('h64), .DW(HCKCNT)             ) sfr_hclkgr     (.sr(hclksubgate),.prdata32(),.*);
    apb_sr #(.A('h68), .DW(ICKCNT)             ) sfr_iclkgr     (.sr(iclksubgate),.prdata32(),.*);
    apb_sr #(.A('h6c), .DW(PCKCNT)             ) sfr_pclkgr     (.sr(pclksubgate),.prdata32(),.*);
`else
    apb_cr #(.A('h60), .DW(ACKCNT),   .IV('hff)) sfr_aclkgr     (.cr(aclksubgate),.prdata32(),.*);
    apb_cr #(.A('h64), .DW(HCKCNT),   .IV('hff)) sfr_hclkgr     (.cr(hclksubgate),.prdata32(),.*);
    apb_cr #(.A('h68), .DW(ICKCNT),   .IV('hff)) sfr_iclkgr     (.cr(iclksubgate),.prdata32(),.*);
    apb_cr #(.A('h6c), .DW(PCKCNT),   .IV('hff)) sfr_pclkgr     (.cr(pclksubgate),.prdata32(),.*);
`endif

// rcu
    apb_ar #(.A('h80), .AR('h55aa))        sfr_rcurst0    (.ar(sysreset_sw),   .*);
    apb_ar #(.A('h84), .AR('h55aa))        sfr_rcurst1    (.ar(corereset_sw),  .*);
    apb_fr #(.A('h88), .DW(16)    )        sfr_rcusrcfr   (.fr(rcufr),  .prdata32(),.*);

// ipc
    apb_ar #(.A('h90), .AR('h32))              sfr_ipcarpll       (.ar(ipc_setcfgpll),                .*);
    apb_ar #(.A('h90), .AR('h57))              sfr_ipcaripflow    (.ar(ipflow_setar),                .*);
    apb_cr #(.A('h94), .DW(16), .IV('h01) )    sfr_ipcen    (.cr(ipc_en),    .prdata32(),.*);
    apb_cr #(.A('h98), .DW(16), .IV('h01) )    sfr_ipclpen  (.cr(ipc_lpen),  .prdata32(),.*);
    apb_cr #(.A('h9c), .DW(7),  .IV(IV_OSC32MTRM))    sfr_ipcosc   (.cr(ipc_osc),   .prdata32(),.*);
    apb_cr #(.A('ha0), .DW(17), .IV(PLLMNIV))  sfr_ipcpllmn (.cr(ipc_pllmn), .prdata32(),.*);
    apb_cr #(.A('ha4), .DW(25), .IV('hff) )    sfr_ipcpllf  (.cr(ipc_pllf),  .prdata32(),.*);
    apb_cr #(.A('ha8), .DW(15), .IV('0)   )    sfr_ipcpllq  (.cr(ipc_pllq),  .prdata32(),.*);
    apb_cr #(.A('hac), .DW(16), .IV('h53) )    sfr_ipccr    (.cr(ipccr),     .prdata32(),.*);


    apb_owr #(.A('hc0), .DW(32) )    sfr_owr   (.owr(owr),     .prdata32(),.*);

endmodule : sysctrl

module resetgen #(
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

/*
module ipctrl (
    input clk,    // Clock
    input resetn, // Clock Enable
    input rst_n,  // Asynchronous reset active low

);





    ## ipc_nvrld <= bistrd_ipcldreg | socresetrise




ipc_nvr, ipc_nvrld
ipc_sfr, ipc_sfrld
ipc_lp, lpc_lpmd

ipc_out


ipc_nvrld


    `theregrn( ipc_sfr ) <=  ipc_nvrld ? ipc_nvr : ipc_sfr;

    `theregrn( ipc_sfrreg ) <=  ipc_nvrld ? ipc_nvr :
                                ipc_sfrld ? ipc_sfr : ipc_sfrreg;


ipc_out = socresetn ? ipc_sfrmux : ipc_nvr;
ipc_sfrmux = lpc_lpmd ? ipc_lp : ipc_sfrreg;




endmodule
*/
module apb_owr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrpaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrprdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 prdata32    ,
        output logic [DW-1:0]   owr
);


    bit [DW-1:0] wrone, wronereg;
    logic clk;
    assign clk = pclk;

genvar i;
generate
    for (i = 0; i < DW; i++) begin: gar
    apb_ar #(.A(A), .AW(AW), .AR(i)         )  sfr_ar    (.ar(wrone[i]),              .*);
    `theregrn( wronereg[i] ) <= wronereg[i] |wrone[i];
    end
endgenerate

    apb_sr #(.A(A),  .AW(AW),  .DW(DW)           )  sfr_sr    (.sr(wronereg),  .prdata32(prdata32),.*);


endmodule


module dummytb_sysctrl();
    parameter IPMDC = 32;

         bit clkxtl;
         bit clksys;
         bit clktop;
         bit clkper;
         bit fclk;
         bit aclk;
         bit hclk;
         bit iclk;
         bit pclk;
         bit aoclk;
         bit clkaoram;
         bit fclken;
         bit aclken;
         bit hclken;
         bit iclken;
         bit pclken;
         bit aoclken;
         bit fclken2;
         bit aclken2;
         bit hclken2;
         bit iclken2;
         bit pclken2;
         bit aoclken2;
         bit clkpke;
         bit [7:0] aclksub,aclksubgate;
         bit [7:0] hclksub,hclksubgate;
         bit [7:0] iclksub,iclksubgate;
         bit [7:0] pclksub,pclksubgate;
         bit ref1M;
         bit ref32k;
           bit       cmsatpg;
           cms_pkg::cmscode_e   cmscode;
         bit socresetn, socresetn_undft;
         bit secresetn;
         bit padresetn;
         bit wdtresetn;
         bit vdresetn;
         bit sysresetn;
         bit coreresetn;
         bit sfrlock;
         bit brdone;
         bit wkupvld_async, coresleep;
         bit [6:0]  ipsleep;
         bit [0:5]  clkocc;
         bit [0:5]  clkbist;
    logic [IPMDC-1:0][31:0] iptrim32        ;
    logic                   iptrimdatavld   ;
    logic                   iptrimready     ;
    logic clksys1m, clksys1m_undft;
    logic aopmutrmset;
    logic [63:0] aopmutrmdata;
    logic pad_reton, pad_retoff;
    logic [63:0] ipt_socreg;
    logic [6:0] osc_osc32m_nvr;
    logic iptpopll, iptpoosc, ipt_socset, xtalsleep;
// dft
    logic clkatpg, atpgrst, atpgse;
    logic clksys_undft;
    logic sysresetn_undft;
    logic coreresetn_undft;
    logic atpg_ascapen;
    logic ipflowfsm_setipcr;
// apb
apbif apbs();
apbif apbx();
sysctrl u1(.*);

endmodule

