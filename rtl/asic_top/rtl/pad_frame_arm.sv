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

`ifndef  pad_frame_arm_included
`define pad_frame_arm_included 1

//`include "io_interface_def_v0.1.sv"

module pad_frame #(
    parameter ADCCNT = 4
)(

// workmode pads
    input wire PAD_WMS0,
    input wire PAD_WMS1,
    input wire PAD_WMS2,

// external resetn
    input wire PAD_XRSTn,

////    input  wire XTAL_IN,
//    inout  wire XTAL_OUT,
//    input  wire XTAL24M_IN,
//    inout  wire XTAL24M_OUT,
    input  wire XTAL48M_IN,
    inout  wire XTAL48M_OUT,

// qspiflash
    inout wire QFC_SCK   ,
    inout wire QFC_SCKN  ,
    inout wire QFC_QDS   ,
    inout wire QFC_SS0   ,
    inout wire QFC_SS1   ,
    inout wire QFC_SIO0  ,
    inout wire QFC_SIO1  ,
    inout wire QFC_SIO2  ,
    inout wire QFC_SIO3  ,
    inout wire QFC_SIO4  ,
    inout wire QFC_SIO5  ,
    inout wire QFC_SIO6  ,
    inout wire QFC_SIO7  ,
//    inout wire QFC_RWDS  ,
    inout wire QFC_INT   ,
    inout wire QFC_RSTM0 ,
    inout wire QFC_RSTS0 ,
//    inout wire QFC_RSTM1 ,
//    inout wire QFC_RSTS1 ,

// swd, d-uart, jtag
    inout  wire PAD_DUART ,
    input  wire PAD_SWDCK ,
    inout  wire PAD_SWDIO ,
    inout  wire PAD_JTCK  ,
    inout  wire PAD_JTMS  ,
    inout  wire PAD_JTDI  ,
    inout  wire PAD_JTDO  ,
    inout  wire PAD_JTRST ,

// gpio
    inout wire PA0, PA1, PA2, PA3, PA4, PA5, PA6, PA7,
    inout wire PB0, PB1, PB2, PB3, PB4, PB5, PB6, PB7, PB8, PB9, PB10, PB11, PB12, PB13, PB14, PB15,
    inout wire PC0, PC1, PC2, PC3, PC4, PC5, PC6, PC7, PC8, PC9, PC10, PC11, PC12, PC13, PC14, PC15,
    inout wire PD0, PD1, PD2, PD3, PD4, PD5, PD6, PD7, PD8, PD9, PD10, PD11, PD12, PD13, PD14, PD15,
    inout wire PE0, PE1, PE2, PE3, PE4, PE5, PE6, PE7, PE8, PE9, PE10, PE11, PE12, PE13, PE14, PE15,
/*
    input wire PAD_SDCLK,
    input wire PAD_SDCMD,
    inout wire PAD_SDDAT0,
    inout wire PAD_SDDAT1,
    inout wire PAD_SDDAT2,
    inout wire PAD_SDDAT3,
*/


// to Soc_Top

    output logic        clkxtl,
    output logic [0:2]  cmspad,
    output logic        padresetn,
//    output logic        clkxtl24m,
    output logic        clkxtl48m,
    input  logic        cmstest,
    input  logic        cmsatpg,
//    input  logic        cmsvld,
    input  logic [0:5] iptpo,
        input logic [63:0] ipt_padoe, ipt_padpo,
        output logic [63:0] ipt_padpi,

    output logic        swdclk,
    ioif.load           swdio,
    input  logic        dbgtxd,
    input logic clkocc,
    jtagif.master       jtagvex,
    jtagif.master       jtagrrc[0:1],
    jtagif.master       jtagipt,
    jtagif.master       jtagrb,

    output logic clkatpg, atpgrst, atpgse,

    ioif.load           iopad_A[0: 7],
    ioif.load           iopad_B[0:15],
    ioif.load           iopad_C[0:15],
    ioif.load           iopad_D[0:15],
    ioif.load           iopad_E[0:15],

    input bit xtalsleep,
    input padcfg_arm_t  iocfg_A[0: 7],
    input padcfg_arm_t  iocfg_B[0:15],
    input padcfg_arm_t  iocfg_C[0:15],
    input padcfg_arm_t  iocfg_D[0:15],
    input padcfg_arm_t  iocfg_E[0:15],

    ioif.load           qfc_sck,
    ioif.load           qfc_sckn,
    ioif.load           qfc_dqs,
    ioif.load           qfc_ss[1:0],
    ioif.load           qfc_sio[7:0],
//    ioif.load           qfc_rwds,
    ioif.load           qfc_rstm[1:0],
    ioif.load           qfc_rsts[1:0],
    ioif.load           qfc_int,

    input padcfg_arm_t  padcfg_qfc_sck,
    input padcfg_arm_t  padcfg_qfc_qds,
    input padcfg_arm_t  padcfg_qfc_ss,
    input padcfg_arm_t  padcfg_qfc_sio,
//    input padcfg_arm_t  padcfg_qfc_rwds,
    input padcfg_arm_t  padcfg_qfc_int,
    input padcfg_arm_t  padcfg_qfc_rst,


/*
    ioif.load           sddc_clk,
    ioif.load           sddc_cmd,
//    ioif.load           sddc_dat[3:0],
    ioif.load           sddc_dat0,
    ioif.load           sddc_dat1,
    ioif.load           sddc_dat2,
    ioif.load           sddc_dat3,
*/
    input logic [1:0] rtosnspa,
    input logic [1:0] rtosnspbc,
    input logic [1:0] rtosnspd,
    input logic [1:0] rtosnspe,
    input logic [1:0] rtosnstest,
    input logic [1:0] rtosnsqfc,
    input logic [1:0] rtosnsrr1,
    input logic [1:0] rtosnsrr0,
    input logic [1:0] rtosnspmu,

// adc
    inout  wire         pmu_ana_test,
    inout  wire [0:1]   ana_reramtest,
    output wire [3:0]   adc_si

);
//    ioif jtagio_JTCK();
//    ioif jtagio_JTMS();
//    ioif jtagio_JTDI();
//    ioif jtagio_JTDO();
//    ioif jtagio_JTRST();
//
//    jtag2io j2io(
//        .jtagen,
//        .io_JTCK   (jtagio_JTCK),
//        .io_JTMS   (jtagio_JTMS),
//        .io_JTDI   (jtagio_JTDI),
//        .io_JTDO   (jtagio_JTDO),
//        .io_JTRST  (jtagio_JTRST),
//        .jtagm
//    );
//    padcell_i #(.pu(1'b1)) u_xrstn  ( .pad( PAD_XRSTn ), .thecfg(padcfg_xrst), .pi( padresetn ));

//    ioif iopad_B_T[0:15]();

    logic jtagclk, jtagtrst, jtagtdi, jtagrrc0_tdo, jtagrrc1_tdo;
    logic patestpi4, patestpi5, patestpi7;
    logic [15:0] pbtestpi, pbtestpo;
    logic [7:0] scanout;
    logic jtagclk_occ, swdclk_unmux;
    logic xtalsleep_dft;

//    assign adc_si[0] = u_PA4.ai; defparam u_PA4.ANA = 1'b1;
//    assign adc_si[1] = u_PA5.ai; defparam u_PA5.ANA = 1'b1;
//    assign adc_si[2] = u_PA6.ai; defparam u_PA6.ANA = 1'b1;
//    assign adc_si[3] = u_PA7.ai; defparam u_PA7.ANA = 1'b1;
//    logic ujr_cmstest;
//    assign ujr_cmstest = ~cmsvld & (cmspad[2]  == 1 ) | cmstest;
//    io_cmstest_outmux #(16) ujr ( .cmstest(ujr_cmstest), .testsig( jtdo16 ), .ios(iopad_B), .iom( iopad_B_T ) );

    parameter padcfg_arm_t padcfg_xtal = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:2'b11};    // 24.1M~48M 11
//    parameter padcfg_arm_t padcfg_xtal24m = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:2'b01}; // 12.1M~24M 01
    parameter padcfg_arm_t padcfg_xtal48m = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:2'b11}; // 24.1M~48M 11
    parameter padcfg_arm_t padcfg_cms  = '{schmsel:'1, anamode:'0, slewslow:'0, drvsel:2'b00};
    parameter padcfg_arm_t padcfg_dev  = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:2'b00};
    parameter padcfg_arm_t padcfg_xrst = '{schmsel:'1, anamode:'0, slewslow:'0, drvsel:2'b00};

//    padcell_xtal  u_xtal   ( .padxin(XTAL_IN),    .padxout(XTAL_OUT),    .thecfg(padcfg_xtal),    .pc(clkxtl),     .rtosns(rtosnsqfc));
    CLKCELL_BUF  u_xtal (.A(clkxtl48m),.Z(clkxtl));
    assign xtalsleep_dft = cmsatpg ? 1'b0 : xtalsleep;
    padcell_xtal  u_xtal48m( .padxin(XTAL48M_IN), .padxout(XTAL48M_OUT), .thecfg(padcfg_xtal48m), .pc(clkxtl48m) , .rtosns(rtosnstest), .sleep(xtalsleep_dft));
    padcell_i #(.pu('0), .pd('1), .H('0)) u_cmspad0( .pad( PAD_WMS0 ), .thecfg(padcfg_cms), .pi( cmspad[0] ), .rtosns(rtosnstest));//zmj 20230909
    padcell_i #(.pu('0), .pd('1), .H('0)) u_cmspad1( .pad( PAD_WMS1 ), .thecfg(padcfg_cms), .pi( cmspad[1] ), .rtosns(rtosnstest));//zmj 20230909
    padcell_i #(.pu('0), .pd('1), .H('0)) u_cmspad2( .pad( PAD_WMS2 ), .thecfg(padcfg_cms), .pi( cmspad[2] ), .rtosns(rtosnstest));//zmj 20230909

    padcell_i #(.H('0),.pu(1'b1)) u_xrstn  ( .pad( PAD_XRSTn ), .thecfg(padcfg_xrst), .pi( padresetn ), .rtosns(rtosnstest));
    padcell_i #(.H('0),.pu(1'b1)) u_swdck  ( .pad( PAD_SWDCK ), .thecfg(padcfg_dev), .pi( swdclk_unmux ), .rtosns(rtosnstest));
    padcell_io #(.H('0))  u_swdio  ( .pad( PAD_SWDIO ), .thecfg(padcfg_dev), .pio( swdio ), .ai(), .rtosns(rtosnstest), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_o  #(.H('0))  u_duart  ( .pad( PAD_DUART ), .thecfg(padcfg_dev), .po( dbgtxd ), .rtosns(rtosnstest), .cmsatpg(cmsatpg));
    padcell_i #(.H('0)) u_JTCK  ( .pad( PAD_JTCK  ), .thecfg(padcfg_dev), .pi( jtagvex.tck  ), .rtosns(rtosnstest));
    padcell_i #(.H('0)) u_JTMS  ( .pad( PAD_JTMS  ), .thecfg(padcfg_dev), .pi( jtagvex.tms  ), .rtosns(rtosnstest));
    padcell_i #(.H('0)) u_JTDI  ( .pad( PAD_JTDI  ), .thecfg(padcfg_dev), .pi( jtagvex.tdi  ), .rtosns(rtosnstest));
    padcell_o #(.H('0)) u_JTDO  ( .pad( PAD_JTDO  ), .thecfg(padcfg_dev), .po( jtagvex.tdo  ), .rtosns(rtosnstest), .cmsatpg(cmsatpg));
    padcell_i  #(.H('0),.pu(0),.pd(1)) u_JTRST ( .pad( PAD_JTRST ), .thecfg(padcfg_dev), .pi( jtagvex.trst ), .rtosns(rtosnstest));

//    assign jtdo16[3:15] = iptpo[0:3];
    assign jtagclk_occ = cmsatpg ? clkocc : jtagclk;
    assign swdclk = cmsatpg ? clkocc : swdclk_unmux;

    assign jtagrrc[0].tck  = jtagclk_occ;
    assign jtagrrc[0].trst = cmstest & jtagtrst;
    assign jtagrrc[0].tms =  cmstest & patestpi4;
    assign jtagrrc[0].tdi  = cmstest & jtagtdi;
    assign jtagrrc0_tdo = jtagrrc[0].tdo;

    assign jtagrrc[1].tck  = jtagclk_occ;
    assign jtagrrc[1].trst = cmstest & jtagtrst;
    assign jtagrrc[1].tms =  cmstest & pbtestpi[0 ];
    assign jtagrrc[1].tdi  = cmstest & pbtestpi[4 ];//jtagtdi;

    assign jtagrb.tck  = jtagclk_occ;
    assign jtagrb.trst = cmstest & jtagtrst;
    assign jtagrb.tms =  cmstest & pbtestpi[2 ];
    assign jtagrb.tdi  = cmstest & jtagtdi;

    assign jtagipt.tck     = jtagclk;
    assign jtagipt.trst    = (cmstest | cmsatpg ) & jtagtrst;
    assign jtagipt.tdi     = (cmstest | cmsatpg ) & jtagtdi;


    DATACELL_BUF buf_scanin0  (.A(pbtestpi[0 ]),.Z());  DATACELL_BUF buf_scanout0 (.A(1'b0),.Z(scanout[0]));
    DATACELL_BUF buf_scanin1  (.A(pbtestpi[2 ]),.Z());  DATACELL_BUF buf_scanout1 (.A(1'b0),.Z(scanout[1]));
    DATACELL_BUF buf_scanin2  (.A(pbtestpi[4 ]),.Z());  DATACELL_BUF buf_scanout2 (.A(1'b0),.Z(scanout[2]));
    DATACELL_BUF buf_scanin3  (.A(pbtestpi[6 ]),.Z());  DATACELL_BUF buf_scanout3 (.A(1'b0),.Z(scanout[3]));
    DATACELL_BUF buf_scanin4  (.A(pbtestpi[8 ]),.Z());  DATACELL_BUF buf_scanout4 (.A(1'b0),.Z(scanout[4]));
    DATACELL_BUF buf_scanin5  (.A(pbtestpi[10]),.Z());  DATACELL_BUF buf_scanout5 (.A(1'b0),.Z(scanout[5]));
    DATACELL_BUF buf_scanin6  (.A(pbtestpi[12]),.Z());  DATACELL_BUF buf_scanout6 (.A(1'b0),.Z(scanout[6]));
    DATACELL_BUF buf_scanin7  (.A(pbtestpi[14]),.Z());  DATACELL_BUF buf_scanout7 (.A(1'b0),.Z(scanout[7]));

    assign pbtestpo[1-1]  = '0; assign pbtestpo[1]  = cmstest ? jtagrrc[1].tdo : scanout[0];
    assign pbtestpo[3-1]  = '0; assign pbtestpo[3]  = cmstest ? jtagrb.tdo     : scanout[1];
    assign pbtestpo[5-1]  = '0; assign pbtestpo[5]  = cmstest ? iptpo[0]       : scanout[2];
    assign pbtestpo[7-1]  = '0; assign pbtestpo[7]  = cmstest ? iptpo[1]       : scanout[3];
    assign pbtestpo[9-1]  = '0; assign pbtestpo[9]  = cmstest ? iptpo[2]       : scanout[4];
    assign pbtestpo[11-1] = '0; assign pbtestpo[11] = cmstest ? iptpo[3]       : scanout[5];
    assign pbtestpo[13-1] = '0; assign pbtestpo[13] = cmstest ? iptpo[4]       : scanout[6];
    assign pbtestpo[15-1] = '0; assign pbtestpo[15] = cmstest ? iptpo[5]       : scanout[7];

    padcfg_arm_t iocfg_A05;
    padcfg_arm_t iocfg_A_5aitest;
    assign iocfg_A05 = cmstest ? iocfg_A_5aitest : iocfg_A[5];
    assign iocfg_A_5aitest.drvsel = '0;
    assign iocfg_A_5aitest.anamode = '1;
    assign iocfg_A_5aitest.schmsel = '0;
    assign iocfg_A_5aitest.slewslow = '0;

    CLKCELL_BUF  buf_atpgclk (.A(patestpi4&cmsatpg),.Z(clkatpg));
    DATACELL_BUF buf_atpgrst (.A(patestpi7&cmsatpg),.Z(atpgrst));
    DATACELL_BUF buf_atpgse  (.A(patestpi5&cmsatpg),.Z(atpgse));

    padcell_io #(.H('0)) u_PA0  ( .pad( PA0  ), .pio( iopad_A[0 ]), .thecfg(iocfg_A[0 ]), .ai(), .rtosns(rtosnspa), .cmsatpg(cmstest|cmsatpg), .testpo('0), .testoe('0), .testpi(jtagclk));
    padcell_io #(.H('0)) u_PA1  ( .pad( PA1  ), .pio( iopad_A[1 ]), .thecfg(iocfg_A[1 ]), .ai(), .rtosns(rtosnspa), .cmsatpg(cmstest|cmsatpg), .testpo('0), .testoe('0), .testpi(jtagtrst));
    padcell_io #(.H('0)) u_PA2  ( .pad( PA2  ), .pio( iopad_A[2 ]), .thecfg(iocfg_A[2 ]), .ai(), .rtosns(rtosnspa), .cmsatpg(cmstest|cmsatpg), .testpo('0), .testoe('0), .testpi(jtagtdi));
    padcell_io #(.H('0)) u_PA3  ( .pad( PA3  ), .pio( iopad_A[3 ]), .thecfg(iocfg_A[3 ]), .ai(), .rtosns(rtosnspa), .cmsatpg(cmstest|cmsatpg), .testpo('0), .testoe('0), .testpi(jtagipt.tms));
    padcell_io #(.H('0),.ANA(1'b1)) u_PA4  ( .pad( PA4  ), .pio( iopad_A[4 ]), .thecfg(iocfg_A[4 ]), .ai(adc_si[0]), .rtosns(rtosnspa), .cmsatpg(cmstest|cmsatpg), .testpo('0), .testoe('0), .testpi(patestpi4));
    padcell_io #(.H('0),.ANA(1'b1)) u_PA5  ( .pad( PA5  ), .pio( iopad_A[5 ]), .thecfg(iocfg_A05  ), .ai(adc_si[1]), .rtosns(rtosnspa), .cmsatpg(cmstest|cmsatpg), .testpo('0), .testoe('0), .testpi(patestpi5));
    padcell_io #(.H('0),.ANA(1'b1)) u_PA6  ( .pad( PA6  ), .pio( iopad_A[6 ]), .thecfg(iocfg_A[6 ]), .ai(adc_si[2]), .rtosns(rtosnspa), .cmsatpg(cmstest|cmsatpg), .testpo(jtagipt.tdo ), .testoe('1), .testpi());
    padcell_io #(.H('1),.ANA(1'b1)) u_PA7  ( .pad( PA7  ), .pio( iopad_A[7 ]), .thecfg(iocfg_A[7 ]), .ai(adc_si[3]), .rtosns(rtosnspa), .cmsatpg(cmstest|cmsatpg), .testpo(jtagrrc0_tdo), .testoe(cmstest), .testpi(patestpi7));

    padcell_io u_PB0  ( .pad( PB0  ), .pio( iopad_B[0 ]), .thecfg(iocfg_B[0 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[0 ]), .testoe('0),      .testpi(pbtestpi[0 ]));
    padcell_io u_PB1  ( .pad( PB1  ), .pio( iopad_B[1 ]), .thecfg(iocfg_B[1 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[1 ]), .testoe('1),      .testpi(pbtestpi[1 ]));
    padcell_io u_PB2  ( .pad( PB2  ), .pio( iopad_B[2 ]), .thecfg(iocfg_B[2 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[2 ]), .testoe('0),      .testpi(pbtestpi[2 ]));
    padcell_io u_PB3  ( .pad( PB3  ), .pio( iopad_B[3 ]), .thecfg(iocfg_B[3 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[3 ]), .testoe('1),      .testpi(pbtestpi[3 ]));
    padcell_io u_PB4  ( .pad( PB4  ), .pio( iopad_B[4 ]), .thecfg(iocfg_B[4 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[4 ]), .testoe('0),      .testpi(pbtestpi[4 ]));
    padcell_io u_PB5  ( .pad( PB5  ), .pio( iopad_B[5 ]), .thecfg(iocfg_B[5 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[5 ]), .testoe('1),      .testpi(pbtestpi[5 ]));
    padcell_io u_PB6  ( .pad( PB6  ), .pio( iopad_B[6 ]), .thecfg(iocfg_B[6 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg,                  .testpo(pbtestpo[6 ]), .testoe('0),      .testpi(pbtestpi[6 ]));
    padcell_io u_PB7  ( .pad( PB7  ), .pio( iopad_B[7 ]), .thecfg(iocfg_B[7 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[7 ]), .testoe('1),      .testpi(pbtestpi[7 ]));
    padcell_io u_PB8  ( .pad( PB8  ), .pio( iopad_B[8 ]), .thecfg(iocfg_B[8 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg,                  .testpo(pbtestpo[8 ]), .testoe('0),      .testpi(pbtestpi[8 ]));
    padcell_io u_PB9  ( .pad( PB9  ), .pio( iopad_B[9 ]), .thecfg(iocfg_B[9 ]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[9 ]), .testoe('1),      .testpi(pbtestpi[9 ]));
    padcell_io u_PB10 ( .pad( PB10 ), .pio( iopad_B[10]), .thecfg(iocfg_B[10]), .ai(), .rtosns(rtosnspbc), .cmsatpg,                  .testpo(pbtestpo[10]), .testoe('0),      .testpi(pbtestpi[10]));
    padcell_io u_PB11 ( .pad( PB11 ), .pio( iopad_B[11]), .thecfg(iocfg_B[11]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[11]), .testoe('1),      .testpi(pbtestpi[11]));
    padcell_io u_PB12 ( .pad( PB12 ), .pio( iopad_B[12]), .thecfg(iocfg_B[12]), .ai(), .rtosns(rtosnspbc), .cmsatpg,                  .testpo(pbtestpo[12]), .testoe('0),      .testpi(pbtestpi[12]));
    padcell_io u_PB13 ( .pad( PB13 ), .pio( iopad_B[13]), .thecfg(iocfg_B[13]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[13]), .testoe('1),      .testpi(pbtestpi[13]));
    padcell_io u_PB14 ( .pad( PB14 ), .pio( iopad_B[14]), .thecfg(iocfg_B[14]), .ai(), .rtosns(rtosnspbc), .cmsatpg,                  .testpo(pbtestpo[14]), .testoe('0),      .testpi(pbtestpi[14]));
    padcell_io u_PB15 ( .pad( PB15 ), .pio( iopad_B[15]), .thecfg(iocfg_B[15]), .ai(), .rtosns(rtosnspbc), .cmsatpg(cmstest|cmsatpg), .testpo(pbtestpo[15]), .testoe('1),      .testpi(pbtestpi[15]));
    padcell_io           u_PC0  ( .pad( PC0  ), .pio( iopad_C[0 ]),  .thecfg(iocfg_C[0 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[0 ]), .testoe(ipt_padoe[0 ]), .testpi(ipt_padpi[0 ]));
    padcell_io           u_PC1  ( .pad( PC1  ), .pio( iopad_C[1 ]),  .thecfg(iocfg_C[1 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[1 ]), .testoe(ipt_padoe[1 ]), .testpi(ipt_padpi[1 ]));
    padcell_io           u_PC2  ( .pad( PC2  ), .pio( iopad_C[2 ]),  .thecfg(iocfg_C[2 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[2 ]), .testoe(ipt_padoe[2 ]), .testpi(ipt_padpi[2 ]));
    padcell_io           u_PC3  ( .pad( PC3  ), .pio( iopad_C[3 ]),  .thecfg(iocfg_C[3 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[3 ]), .testoe(ipt_padoe[3 ]), .testpi(ipt_padpi[3 ]));
    padcell_io           u_PC4  ( .pad( PC4  ), .pio( iopad_C[4 ]),  .thecfg(iocfg_C[4 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[4 ]), .testoe(ipt_padoe[4 ]), .testpi(ipt_padpi[4 ]));
    padcell_io           u_PC5  ( .pad( PC5  ), .pio( iopad_C[5 ]),  .thecfg(iocfg_C[5 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[5 ]), .testoe(ipt_padoe[5 ]), .testpi(ipt_padpi[5 ]));
    padcell_io           u_PC6  ( .pad( PC6  ), .pio( iopad_C[6 ]),  .thecfg(iocfg_C[6 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[6 ]), .testoe(ipt_padoe[6 ]), .testpi(ipt_padpi[6 ]));
    padcell_io           u_PC7  ( .pad( PC7  ), .pio( iopad_C[7 ]),  .thecfg(iocfg_C[7 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[7 ]), .testoe(ipt_padoe[7 ]), .testpi(ipt_padpi[7 ]));
    padcell_io           u_PC8  ( .pad( PC8  ), .pio( iopad_C[8 ]),  .thecfg(iocfg_C[8 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[8 ]), .testoe(ipt_padoe[8 ]), .testpi(ipt_padpi[8 ]));
    padcell_io           u_PC9  ( .pad( PC9  ), .pio( iopad_C[9 ]),  .thecfg(iocfg_C[9 ]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[9 ]), .testoe(ipt_padoe[9 ]), .testpi(ipt_padpi[9 ]));
    padcell_io           u_PC10 ( .pad( PC10 ), .pio( iopad_C[10]),  .thecfg(iocfg_C[10]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[10]), .testoe(ipt_padoe[10]), .testpi(ipt_padpi[10]));
    padcell_io           u_PC11 ( .pad( PC11 ), .pio( iopad_C[11]),  .thecfg(iocfg_C[11]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[11]), .testoe(ipt_padoe[11]), .testpi(ipt_padpi[11]));
    padcell_io           u_PC12 ( .pad( PC12 ), .pio( iopad_C[12]),  .thecfg(iocfg_C[12]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[12]), .testoe(ipt_padoe[12]), .testpi(ipt_padpi[12]));
    padcell_io           u_PC13 ( .pad( PC13 ), .pio( iopad_C[13]),  .thecfg(iocfg_C[13]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[13]), .testoe(ipt_padoe[13]), .testpi(ipt_padpi[13]));
    padcell_io           u_PC14 ( .pad( PC14 ), .pio( iopad_C[14]),  .thecfg(iocfg_C[14]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[14]), .testoe(ipt_padoe[14]), .testpi(ipt_padpi[14]));
    padcell_io           u_PC15 ( .pad( PC15 ), .pio( iopad_C[15]),  .thecfg(iocfg_C[15]),       .ai(),  .rtosns(rtosnspbc),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[15]), .testoe(ipt_padoe[15]), .testpi(ipt_padpi[15]));
    padcell_io #(.H('1)) u_PD0  ( .pad( PD0  ), .pio( iopad_D[0 ]),  .thecfg(iocfg_D[0 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[0 ]), .testoe(ipt_padoe[0 ]), .testpi(ipt_padpi[16+0 ]));
    padcell_io #(.H('1)) u_PD1  ( .pad( PD1  ), .pio( iopad_D[1 ]),  .thecfg(iocfg_D[1 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[1 ]), .testoe(ipt_padoe[1 ]), .testpi(ipt_padpi[16+1 ]));
    padcell_io #(.H('0)) u_PD2  ( .pad( PD2  ), .pio( iopad_D[2 ]),  .thecfg(iocfg_D[2 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[2 ]), .testoe(ipt_padoe[2 ]), .testpi(ipt_padpi[16+2 ]));
    padcell_io #(.H('0)) u_PD3  ( .pad( PD3  ), .pio( iopad_D[3 ]),  .thecfg(iocfg_D[3 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[3 ]), .testoe(ipt_padoe[3 ]), .testpi(ipt_padpi[16+3 ]));
    padcell_io #(.H('0)) u_PD4  ( .pad( PD4  ), .pio( iopad_D[4 ]),  .thecfg(iocfg_D[4 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[4 ]), .testoe(ipt_padoe[4 ]), .testpi(ipt_padpi[16+4 ]));
    padcell_io #(.H('0)) u_PD5  ( .pad( PD5  ), .pio( iopad_D[5 ]),  .thecfg(iocfg_D[5 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[5 ]), .testoe(ipt_padoe[5 ]), .testpi(ipt_padpi[16+5 ]));
    padcell_io #(.H('0)) u_PD6  ( .pad( PD6  ), .pio( iopad_D[6 ]),  .thecfg(iocfg_D[6 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[6 ]), .testoe(ipt_padoe[6 ]), .testpi(ipt_padpi[16+6 ]));
    padcell_io #(.H('0)) u_PD7  ( .pad( PD7  ), .pio( iopad_D[7 ]),  .thecfg(iocfg_D[7 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[7 ]), .testoe(ipt_padoe[7 ]), .testpi(ipt_padpi[16+7 ]));
    padcell_io #(.H('0)) u_PD8  ( .pad( PD8  ), .pio( iopad_D[8 ]),  .thecfg(iocfg_D[8 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[8 ]), .testoe(ipt_padoe[8 ]), .testpi(ipt_padpi[16+8 ]));
    padcell_io #(.H('0)) u_PD9  ( .pad( PD9  ), .pio( iopad_D[9 ]),  .thecfg(iocfg_D[9 ]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[9 ]), .testoe(ipt_padoe[9 ]), .testpi(ipt_padpi[16+9 ]));
    padcell_io #(.H('0)) u_PD10 ( .pad( PD10 ), .pio( iopad_D[10]),  .thecfg(iocfg_D[10]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[10]), .testoe(ipt_padoe[10]), .testpi(ipt_padpi[16+10]));
    padcell_io #(.H('0)) u_PD11 ( .pad( PD11 ), .pio( iopad_D[11]),  .thecfg(iocfg_D[11]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[11]), .testoe(ipt_padoe[11]), .testpi(ipt_padpi[16+11]));
    padcell_io #(.H('0)) u_PD12 ( .pad( PD12 ), .pio( iopad_D[12]),  .thecfg(iocfg_D[12]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[12]), .testoe(ipt_padoe[12]), .testpi(ipt_padpi[16+12]));
    padcell_io #(.H('0)) u_PD13 ( .pad( PD13 ), .pio( iopad_D[13]),  .thecfg(iocfg_D[13]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[13]), .testoe(ipt_padoe[13]), .testpi(ipt_padpi[16+13]));
    padcell_io #(.H('0)) u_PD14 ( .pad( PD14 ), .pio( iopad_D[14]),  .thecfg(iocfg_D[14]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[14]), .testoe(ipt_padoe[14]), .testpi(ipt_padpi[16+14]));
    padcell_io #(.H('0)) u_PD15 ( .pad( PD15 ), .pio( iopad_D[15]),  .thecfg(iocfg_D[15]),       .ai(),  .rtosns(rtosnspd),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[15]), .testoe(ipt_padoe[15]), .testpi(ipt_padpi[16+15]));
    padcell_io #(.H('0)) u_PE0  ( .pad( PE0  ), .pio( iopad_E[0 ]),  .thecfg(iocfg_E[0 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[0 ]), .testoe(ipt_padoe[0 ]), .testpi(ipt_padpi[32+0 ]));
    padcell_io           u_PE1  ( .pad( PE1  ), .pio( iopad_E[1 ]),  .thecfg(iocfg_E[1 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[1 ]), .testoe(ipt_padoe[1 ]), .testpi(ipt_padpi[32+1 ]));
    padcell_io           u_PE2  ( .pad( PE2  ), .pio( iopad_E[2 ]),  .thecfg(iocfg_E[2 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[2 ]), .testoe(ipt_padoe[2 ]), .testpi(ipt_padpi[32+2 ]));
    padcell_io           u_PE3  ( .pad( PE3  ), .pio( iopad_E[3 ]),  .thecfg(iocfg_E[3 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[3 ]), .testoe(ipt_padoe[3 ]), .testpi(ipt_padpi[32+3 ]));
    padcell_io           u_PE4  ( .pad( PE4  ), .pio( iopad_E[4 ]),  .thecfg(iocfg_E[4 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[4 ]), .testoe(ipt_padoe[4 ]), .testpi(ipt_padpi[32+4 ]));
    padcell_io           u_PE5  ( .pad( PE5  ), .pio( iopad_E[5 ]),  .thecfg(iocfg_E[5 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[5 ]), .testoe(ipt_padoe[5 ]), .testpi(ipt_padpi[32+5 ]));
    padcell_io           u_PE6  ( .pad( PE6  ), .pio( iopad_E[6 ]),  .thecfg(iocfg_E[6 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[6 ]), .testoe(ipt_padoe[6 ]), .testpi(ipt_padpi[32+6 ]));
    padcell_io           u_PE7  ( .pad( PE7  ), .pio( iopad_E[7 ]),  .thecfg(iocfg_E[7 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[7 ]), .testoe(ipt_padoe[7 ]), .testpi(ipt_padpi[32+7 ]));
    padcell_io           u_PE8  ( .pad( PE8  ), .pio( iopad_E[8 ]),  .thecfg(iocfg_E[8 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[8 ]), .testoe(ipt_padoe[8 ]), .testpi(ipt_padpi[32+8 ]));
    padcell_io           u_PE9  ( .pad( PE9  ), .pio( iopad_E[9 ]),  .thecfg(iocfg_E[9 ]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[9 ]), .testoe(ipt_padoe[9 ]), .testpi(ipt_padpi[32+9 ]));
    padcell_io           u_PE10 ( .pad( PE10 ), .pio( iopad_E[10]),  .thecfg(iocfg_E[10]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[10]), .testoe(ipt_padoe[10]), .testpi(ipt_padpi[32+10]));
    padcell_io           u_PE11 ( .pad( PE11 ), .pio( iopad_E[11]),  .thecfg(iocfg_E[11]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[11]), .testoe(ipt_padoe[11]), .testpi(ipt_padpi[32+11]));
    padcell_io           u_PE12 ( .pad( PE12 ), .pio( iopad_E[12]),  .thecfg(iocfg_E[12]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[12]), .testoe(ipt_padoe[12]), .testpi(ipt_padpi[32+12]));
    padcell_io           u_PE13 ( .pad( PE13 ), .pio( iopad_E[13]),  .thecfg(iocfg_E[13]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[13]), .testoe(ipt_padoe[13]), .testpi(ipt_padpi[32+13]));
    padcell_io           u_PE14 ( .pad( PE14 ), .pio( iopad_E[14]),  .thecfg(iocfg_E[14]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[14]), .testoe(ipt_padoe[14]), .testpi(ipt_padpi[32+14]));
    padcell_io           u_PE15 ( .pad( PE15 ), .pio( iopad_E[15]),  .thecfg(iocfg_E[15]),       .ai(),  .rtosns(rtosnspe),  .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[15]), .testoe(ipt_padoe[15]), .testpi(ipt_padpi[32+15]));
    padcell_io u_QFC_SCK   ( .pad( QFC_SCK   ), .pio( qfc_sck     ), .thecfg( padcfg_qfc_sck  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[0 ]), .testoe(ipt_padoe[0 ]), .testpi(ipt_padpi[48+0 ]));
    padcell_io u_QFC_SCKN  ( .pad( QFC_SCKN  ), .pio( qfc_sckn    ), .thecfg( padcfg_qfc_sck  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[1 ]), .testoe(ipt_padoe[1 ]), .testpi(ipt_padpi[48+1 ]));
    padcell_io u_QFC_QDS   ( .pad( QFC_QDS   ), .pio( qfc_dqs     ), .thecfg( padcfg_qfc_qds  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[2 ]), .testoe(ipt_padoe[2 ]), .testpi(ipt_padpi[48+2 ]));
    padcell_io u_QFC_SS0   ( .pad( QFC_SS0   ), .pio( qfc_ss[0]   ), .thecfg( padcfg_qfc_ss   ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[3 ]), .testoe(ipt_padoe[3 ]), .testpi(ipt_padpi[48+3 ]));
    padcell_io u_QFC_SS1   ( .pad( QFC_SS1   ), .pio( qfc_ss[1]   ), .thecfg( padcfg_qfc_ss   ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[4 ]), .testoe(ipt_padoe[4 ]), .testpi(ipt_padpi[48+4 ]));
    padcell_io u_QFC_SIO0  ( .pad( QFC_SIO0  ), .pio( qfc_sio[0]  ), .thecfg( padcfg_qfc_sio  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[5 ]), .testoe(ipt_padoe[5 ]), .testpi(ipt_padpi[48+5 ]));
    padcell_io u_QFC_SIO1  ( .pad( QFC_SIO1  ), .pio( qfc_sio[1]  ), .thecfg( padcfg_qfc_sio  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[6 ]), .testoe(ipt_padoe[6 ]), .testpi(ipt_padpi[48+6 ]));
    padcell_io u_QFC_SIO2  ( .pad( QFC_SIO2  ), .pio( qfc_sio[2]  ), .thecfg( padcfg_qfc_sio  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[7 ]), .testoe(ipt_padoe[7 ]), .testpi(ipt_padpi[48+7 ]));
    padcell_io u_QFC_SIO3  ( .pad( QFC_SIO3  ), .pio( qfc_sio[3]  ), .thecfg( padcfg_qfc_sio  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[8 ]), .testoe(ipt_padoe[8 ]), .testpi(ipt_padpi[48+8 ]));
    padcell_io u_QFC_SIO4  ( .pad( QFC_SIO4  ), .pio( qfc_sio[4]  ), .thecfg( padcfg_qfc_sio  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[9 ]), .testoe(ipt_padoe[9 ]), .testpi(ipt_padpi[48+9 ]));
    padcell_io u_QFC_SIO5  ( .pad( QFC_SIO5  ), .pio( qfc_sio[5]  ), .thecfg( padcfg_qfc_sio  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[10]), .testoe(ipt_padoe[10]), .testpi(ipt_padpi[48+10]));
    padcell_io u_QFC_SIO6  ( .pad( QFC_SIO6  ), .pio( qfc_sio[6]  ), .thecfg( padcfg_qfc_sio  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[11]), .testoe(ipt_padoe[11]), .testpi(ipt_padpi[48+11]));
    padcell_io u_QFC_SIO7  ( .pad( QFC_SIO7  ), .pio( qfc_sio[7]  ), .thecfg( padcfg_qfc_sio  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[12]), .testoe(ipt_padoe[12]), .testpi(ipt_padpi[48+12]));
    padcell_io u_QFC_INT   ( .pad( QFC_INT   ), .pio( qfc_int     ), .thecfg( padcfg_qfc_int  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[13]), .testoe(ipt_padoe[13]), .testpi(ipt_padpi[48+13]));
    padcell_io u_QFC_RSTM0 ( .pad( QFC_RSTM0 ), .pio( qfc_rstm[0] ), .thecfg( padcfg_qfc_rst  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[14]), .testoe(ipt_padoe[14]), .testpi(ipt_padpi[48+14]));
    padcell_io u_QFC_RSTS0 ( .pad( QFC_RSTS0 ), .pio( qfc_rsts[0] ), .thecfg( padcfg_qfc_rst  ), .ai() , .rtosns(rtosnsqfc), .cmsatpg(cmstest|cmsatpg), .testpo(ipt_padpo[15]), .testoe(ipt_padoe[15]), .testpi(ipt_padpi[48+15]));
    assign qfc_rstm[1].pi = '1;
    assign qfc_rsts[1].pi = '1;

`ifndef FPGA
wire VDD25;
wire ANA_RRTST0, ANA_RRTST1, ANA_PMUTST, ANA_VDD25A, ANA_VDD25B ; //
        PANALOG_33_33_NT_DR_V u_ANA0(.RTO(rtosnsrr0[1]),.SNS(rtosnsrr0[0]),.PAD(ANA_RRTST0),.PADC_IOV(ana_reramtest[0]),.PADR1_IOV(),.PADR2_IOV());
        PANALOG_33_33_NT_DR_V u_ANA1(.RTO(rtosnsrr1[1]),.SNS(rtosnsrr1[0]),.PAD(ANA_RRTST1),.PADC_IOV(ana_reramtest[1]),.PADR1_IOV(),.PADR2_IOV());
        PANALOG_33_33_NT_DR_V u_ANA2(.RTO(rtosnspmu[1]),.SNS(rtosnspmu[0]),.PAD(ANA_PMUTST),.PADC_IOV(    ),.PADR1_IOV(),.PADR2_IOV(pmu_ana_test));
        PANALOG_33_33_NT_DR_V u_VDD25A(.RTO(rtosnspmu[1]),.SNS(rtosnspmu[0]),.PAD(ANA_VDD25A ),.PADC_IOV(VDD25           ),.PADR1_IOV(),.PADR2_IOV());
//        PANALOG_33_33_NT_DR_V u_VDD25B(.RTO(rtosnspmu[1]),.SNS(rtosnspmu[0]),.PAD(ANA_VDD25B ),.PADC_IOV(VDD25           ),.PADR1_IOV(),.PADR2_IOV());
`endif

endmodule

module padao_frame (
// always on
    input  wire XTAL32K_IN,
    inout  wire XTAL32K_OUT,
    input  wire PAD_AOXRSTn,
    inout  wire PF0, PF1, PF2, PF3, PF4, PF5, PF6, PF7, PF8, PF9,

// to AO_Top
//    input bit aoxtalsleep,
    input logic [1:0] rtosnsao,
    input logic aocmsatpg,

    output logic        clkxtl32k,
    output logic        ao_padresetn,
    ioif.load           ao_iopad_F[0: 9]

);
    logic cmsatpg;
    assign cmsatpg = aocmsatpg;

    parameter padcfg_arm_t padcfg_xrst = '{schmsel:'1, anamode:'0, slewslow:'0, drvsel:2'b00};

// always on
    padcell_xtal #(.X33k(1),.H('0)) u_xtal32k( .padxin(XTAL32K_IN), .padxout(XTAL32K_OUT), .pc( clkxtl32k ), .thecfg('0), .rtosns(rtosnsao),.sleep(1'b0) );//zmj 20230909
    padcell_i #(.pu(1), .H('0))  u_aoxrstn  ( .pad( PAD_AOXRSTn ), .pi( ao_padresetn ), .thecfg( padcfg_xrst ), .rtosns(rtosnsao) );//zmj 20230909
    padcell_io #(.H('0)) u_PF0  ( .pad( PF0  ), .pio( ao_iopad_F[0 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF1  ( .pad( PF1  ), .pio( ao_iopad_F[1 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF2  ( .pad( PF2  ), .pio( ao_iopad_F[2 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF3  ( .pad( PF3  ), .pio( ao_iopad_F[3 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF4  ( .pad( PF4  ), .pio( ao_iopad_F[4 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF5  ( .pad( PF5  ), .pio( ao_iopad_F[5 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF6  ( .pad( PF6  ), .pio( ao_iopad_F[6 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF7  ( .pad( PF7  ), .pio( ao_iopad_F[7 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF8  ( .pad( PF8  ), .pio( ao_iopad_F[8 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());
    padcell_io #(.H('0)) u_PF9  ( .pad( PF9  ), .pio( ao_iopad_F[9 ] ), .thecfg('0), .ai(), .rtosns(rtosnsao), .cmsatpg, .testpo('0), .testoe('0), .testpi());

endmodule
/*
module io_cmstest_outmux#(
    parameter IOC = 16
)(
    input logic cmstest,
    input logic [IOC-1:0] testsig,
    ioif.load   ios[IOC-1:0],
    ioif.drive  iom[IOC-1:0]
);

genvar i;
generate
    for ( i = 0; i < IOC; i++) begin
        assign iom[i].po = cmstest ? testsig[i] : ios[i].po;
        assign iom[i].oe = cmstest ? '1 : ios[i].oe;
        assign iom[i].pu = cmstest ? '1 : ios[i].pu;
        assign ios[i].pi = cmstest ? '0 : iom[i].pi;
    end
endgenerate

endmodule
*/

`endif // pad_frame_v0.2_arm.sv
