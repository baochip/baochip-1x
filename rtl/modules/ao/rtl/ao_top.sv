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


module  ao_top3 #(
    parameter IOC=10,
    parameter PMUDFTW  = 6,
    parameter PMUCRW   = 8,
    parameter PMUTRMW  = 34,
    parameter OSCCRW   = 1,
    parameter OSCTRMW  = 7,
    parameter bit [PMUDFTW-1:0] IV_PMUDFT  = { 3'h0, 3'h2},
    parameter bit [PMUCRW -1:0] IV_PMUCR   = 8'b01111100,
    parameter bit [PMUTRMW-1:0] IV_PMUTRM  = { 6'h20,5'h10,5'h10,5'h10,5'h10,5'h10,3'h0},
    parameter bit [OSCCRW -1:0] IV_OSC32KCR =    1'b1,
    parameter bit [OSCTRMW-1:0] IV_OSC32KTRM =    7'b0100110,
    parameter IPTBW = 64
 )(

//pbus
    input logic     clksysao,
    input logic     clksysao_undft,
    input logic     clkocc,
    input logic     aopclk, //1M by default
    apbif.slave     apbao,
    output logic    aoint,
    input logic cmsatpg,
    input logic cmstest,
    input logic cmsuser,

    input  logic    clkxtl32k,
    ioif.load       socpad[0:IOC-1],
    ioif.drive      aopad[0:IOC-1],

    input logic socjtagipt_set,
    input logic socipflow_set,
    input logic socipnvr_set,
    input logic [IPTBW-1:0]     socip_nvript,

    input logic     ipsleep,
    output logic    aowkupvld,
    output logic    aowkupint,
    output logic [0:5] ao_iptpo,
    output logic aocmsuser,
    output logic aocmsatpg,
//    output logic aoxtalsleep,
    input logic aoatpgrst,
    input logic aoatpgse,

    input logic [1:0]   aoram_clkb,
    input logic [1:0]   aoram_bcen,
    input logic [1:0]   aoram_bwen,
    input logic [35:0]  aoram_bd,
    input logic [9:0]   aoram_ba,
    output  logic [1:0][35:0]   aoram_bq,

// pmu
    input   wire  pmu_POR                 ,    // pmu
    input   wire  pmu_BGRDY               ,    // pmu
    input   wire  pmu_VR25RDY             ,    // pmu
    input   wire  pmu_VR85ARDY            ,    // pmu
    input   wire  pmu_VR85DRDY            ,    // pmu

    output wire pmu_TRM_LATCH_b,

    output   wire  pmu_VDDAO_CURRENT_CFG       ,
    output   wire  pmu_VR25ENA                 ,
    output   wire  pmu_VR85AENA                ,
    output   wire  pmu_VR85DENA                ,
    output   wire  pmu_IOUTENA                 ,
    output   wire  pmu_POCENA                  ,
    output   wire  pmu_VR85A95ENA              ,
    output   wire  pmu_VR85D95ENA              ,
    output wire [2:0] pmu_TEST_SEL        ,
    output wire [2:0] pmu_TEST_EN         ,

    output wire [6-1:0] pmu_TRM_CUR            ,
    output wire [5-1:0] pmu_TRM_CTAT           ,
    output wire [5-1:0] pmu_TRM_PTAT           ,
    output wire [5-1:0] pmu_TRM_DP60_VDD25           ,
    output wire [5-1:0] pmu_TRM_DP60_VDD85A    ,
    output wire [5-1:0] pmu_TRM_DP60_VDD85D    ,
    output wire [3-1:0] pmu_VDDAO_VOLTAGE_CFG  ,

//    output  wire [7-1:0] pmu_osc32k_cfg,
// reset ctrl
    input  logic    padresetn,  // from aopad
    output logic    socresetn,   // to   soc
    output logic    socresetn_undft   // to   soc
);
    logic aoxtalsleep;

    ioif kpio[7:0]();
    logic clk32k, porresetn, clk1hz;
    logic pclk, pclkenreg, pclk32kenreg;
    logic ao_iso_enable;
    logic porresetn_undft;
    logic wkupvld_async;
    logic [7:0] wkupintsrc;
    logic dkpcintr, wdtintr, tmrintr, rtcintr, wdtreset;
    assign wkupintsrc = {wkupvld_async, dkpcintr, wdtintr, tmrintr, rtcintr, wdtreset};

//    assign aoint = |wkupintsrc;

//  apt
// ■■■■■■■■■■■■■■■

    logic pclk_peri, pclk_32k;

    apbif #(.PAW(12),.DW(32)) apbaos[0:15]();
    apbs_nulls #(10)as7(apbaos[6:15]);

    apb_mux  #(.DECAW(4)) apbaomux(.apbslave (apbao), .apbmaster(apbaos));

    ICG_hvt icg_pclk   ( .CK (aopclk), .EN ( pclkenreg ), .SE(cmsatpg), .CKG ( pclk ));
    ICG_hvt icg_pclk32 ( .CK (clk32k), .EN ( pclk32kenreg ), .SE(cmsatpg), .CKG ( pclk_32k ));

    assign pclk_peri = cmsatpg ? pclk : pclk | pclk_32k;

//  sysctrl
// ■■■■■■■■■■■■■■■

    wire [PMUDFTW-1:0]   pmu_dft;
    wire [PMUCRW-1:0]    pmu_ctrl;
    wire [PMUTRMW-1:0]   pmu_trm;
    wire                 osc_ctrl;
    wire [OSCTRMW-1:0]   osc_trm;
    wire                 aocmsatpg_unbuf;

    `theregfull( clksysao_undft, porresetn_undft, aocmsuser, '0) <= aocmsuser | cmsuser;
    assign aocmsatpg_unbuf = ~aocmsuser & cmsatpg;
    DATACELL_BUF aocmsatpg_buf ( .A(aocmsatpg_unbuf), .Z(aocmsatpg) );

    ao_sysctrl #(
        .IOC          (IOC          ),
        .PMUDFTW      (PMUDFTW      ),
        .PMUCRW       (PMUCRW       ),
        .PMUTRMW      (PMUTRMW      ),
        .OSCCRW       (OSCCRW       ),
        .OSCTRMW      (OSCTRMW      ),
        .IV_PMUDFT    (IV_PMUDFT    ),
        .IV_PMUCR     (IV_PMUCR     ),
        .IV_PMUTRM    (IV_PMUTRM    ),
        .IV_OSC32KCR  (IV_OSC32KCR  ),
        .IV_OSC32KTRM (IV_OSC32KTRM )

    ) aosc(
        .apbs(apbaos[0]),
        .apbx(apbaos[0]),
        .atpgrst        (aoatpgrst),
        .cmsatpg        (aocmsatpg),
        .cmsuser        (aocmsuser),

        .aoint,
        .aowkupvld,
        .aowkupint,
        .ao_iptpo       (ao_iptpo[0:5]),
        .kpio           (kpio[7:0]),
        .*
    );

    assign {
        pmu_VDDAO_CURRENT_CFG       ,
        pmu_VR25ENA                 ,
        pmu_VR85AENA                ,
        pmu_VR85DENA                ,
        pmu_IOUTENA                 ,
        pmu_POCENA                  ,
        pmu_VR85A95ENA              ,
        pmu_VR85D95ENA
        } =  pmu_ctrl;

    assign {
        pmu_TEST_SEL        ,
        pmu_TEST_EN
        } =  pmu_dft;

    assign {
        pmu_TRM_CUR            ,
        pmu_TRM_CTAT           ,
        pmu_TRM_PTAT           ,
        pmu_TRM_DP60_VDD25           ,
        pmu_TRM_DP60_VDD85A    ,
        pmu_TRM_DP60_VDD85D    ,
        pmu_VDDAO_VOLTAGE_CFG
        } =  pmu_trm;

    assign aoxtalsleep = '0;

//  peri
// ■■■■■■■■■■■■■■■

    ao_peri aoperi(
            .pclk            (pclk_peri),
            .presetn         (porresetn),
            .cmsatpg(aocmsatpg),
            .apbs(apbaos[1:3]),

            .clk32k (clk32k),
            .clk1hz (clk1hz),

            .wdtintr(wdtintr),
            .tmrintr(tmrintr),
            .rtcintr(rtcintr),
            .wdtrst (wdtreset)
    );

    dkpc dkpc(
        .pclk(pclk),
        .resetn(porresetn),
        .clk (clk32k),
        .apbs(apbaos[4]),.apbx(apbaos[4]),
        .kpo(kpio[7:4]),
        .kpi(kpio[3:0]),
        .evirq(dkpcintr),
        .wkupvld_async(wkupvld_async),
        .*
        );

    aobureg aobureg(
        .pclk(pclk),
        .resetn(porresetn),
        .apbs(apbaos[5]),.apbx(apbaos[5])
        );

//  aoram
// ■■■■■■■■■■■■■■■

`ifndef FPGA

genvar i;
generate
    for (i = 0; i < 2; i++) begin:gaoram
    aoram1kx36  m (
         .clk         (aoram_clkb[i]),
         .q           (aoram_bq[i]),
         .cen         (aoram_bcen[i]|ao_iso_enable),
         .gwen        (aoram_bwen[i]|ao_iso_enable),
//         .wen         ({36{aoram_bwen[i]}}),
         .a           (aoram_ba),
         .d           (aoram_bd),
//        `sram_sp_uhde_inst
         .ema         (3'b100),
         .emaw        (2'b00),
         .emas        (1'b0),
         .wabl        (1'b1),
         .wablm       (3'b001),
         .rawl        (1'b0),
         .rawlm       (2'b00),
         .ret1n       (1'b1),
         .stov        (1'b0)
         );
    end
endgenerate

`endif

    sparecell #(8) aospcell();

endmodule : ao_top3
