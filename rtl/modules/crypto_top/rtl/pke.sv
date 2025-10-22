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

//import hash_pkg::*;
import scedma_pkg::*;

module pke #(
        parameter RAW = 9, // one of the ram macro's AW
        parameter ERRCNT = 8,
        parameter INTCNT = 8
)(

    input  logic clk, resetn, cmsatpg, cmsbist,
    rbif.slave      rbs[0:1],
    rbif.slavedp    rbsmimm   ,
    input logic clksce,
    input logic clksceen,
    input logic clkpke,
    input logic clkpkeen,
    input  logic ramclr,
    apbif.slavein           apbs,
    apbif.slave             apbx,
    ahbif.slave             ahbs,
    input logic ahbslock,
    output  chnlreq_t       chnl_rpreq, chnl_wpreq   ,
    input   chnlres_t       chnl_rpres, chnl_wpres   ,

    output bit busy, done,
    output logic [0:ERRCNT-1]      err,
    output logic [0:INTCNT-1]      intr
);
// localparam
// ■■■■■■■■■■■■■■■
    localparam adr_t SEGSIZE_PCON = 'd512;

    localparam bit [7:0] SEGID_PCON = scedma_pkg::SEGID_PCON ;
    localparam bit [7:0] SEGID_PKB  = scedma_pkg::SEGID_PKB  ;
    localparam bit [7:0] SEGID_PIB  = scedma_pkg::SEGID_PIB  ;
    localparam bit [7:0] SEGID_PSIB = scedma_pkg::SEGID_PSIB ;
    localparam bit [7:0] SEGID_POB  = scedma_pkg::SEGID_POB  ;
    localparam bit [7:0] SEGID_PSOB = scedma_pkg::SEGID_PSOB ;

    localparam segcfg_t SEG_PCON = //scedma_pkg::SEGCFGS[SEGID_PCON];
        '{ segid:SEGID_PCON , segtype:ST_BI,  ramsel: '0/*'d1*/,  segaddr:SEGADDR_PCON , segsize:SEGSIZE_PCON ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 };
    localparam segcfg_t SEG_PKB  = scedma_pkg::SEGCFGS[SEGID_PKB ];
    localparam segcfg_t SEG_PIB  = scedma_pkg::SEGCFGS[SEGID_PIB ];
    localparam segcfg_t SEG_PSIB = scedma_pkg::SEGCFGS[SEGID_PSIB];
    localparam segcfg_t SEG_POB  = scedma_pkg::SEGCFGS[SEGID_POB ];
    localparam segcfg_t SEG_PSOB = scedma_pkg::SEGCFGS[SEGID_PSOB];

//  cr_func

    localparam PIR_RSAINIT    = 8'h11 ;
    localparam PIR_ECINIT     = 8'h01 ;
    localparam PIR_INVINIT    = 8'hfe ;
    localparam PIR_ECMM    = 8'h02 ;
    localparam PIR_ECMA    = 8'h09 ;
    localparam PIR_ECMS    = 8'h0A ;
    localparam PIR_ECINV   = 8'h08 ;
    localparam PIR_ECI2MA  = 8'h03 ;
    localparam PIR_ECI2MD  = 8'h04 ;
    localparam PIR_ECM2I   = 8'h07 ;
    localparam PIR_ECPA    = 8'h05 ;
    localparam PIR_ECPD    = 8'h06 ;
    localparam PIR_ECPM    = 8'h0b ;
    localparam PIR_EDI2MA  = 8'h23 ;
    localparam PIR_EDI2MD  = 8'h24 ;
    localparam PIR_EDM2I   = 8'h27 ;
    localparam PIR_EDPA    = 8'h25 ;
    localparam PIR_EDPD    = 8'h26 ;
    localparam PIR_EDPM    = 8'h2b ;
    localparam PIR_X25519  = 8'h3b ;
    localparam PIR_GCD     = 8'h51 ;
    localparam PIR_RSAMM   = 8'h12 ;
    localparam PIR_RSAME   = 8'h13 ;
    localparam PIR_RSAMA   = 8'h19 ;
    localparam PIR_RSAMS   = 8'h1A ;
//    localparam PIR_RSAMI   = 8'h18 ;
    localparam PIR_MODINV  = 8'h18 ;
    localparam PIR_RMODL   = 8'h81 ;
    localparam PIR_PCORE   = 8'hff ;

    localparam MFSM_IDLE      = 8'h00;
    localparam MFSM_DONE      = 8'hff;
    //localparam MFSM_PF        = 8'h01;
    localparam MFSM_LD_X      = 8'h10;
    localparam MFSM_LD_Y      = 8'h11;
    localparam MFSM_LD_RSAU   = 8'h12;
    localparam MFSM_LD_RSAUT  = 8'h13;
    localparam MFSM_LD_GCDA   = 8'h14;
    localparam MFSM_LD_GCDB   = 8'h15;
    localparam MFSM_LD_R0     = 8'h16;
    localparam MFSM_LD_R1     = 8'h17;
    localparam MFSM_LD_E      = 8'h18;
    localparam MFSM_LD_Q0I    = 8'h19;
    localparam MFSM_LD_Q1I    = 8'h1a;
    localparam MFSM_LD_Q0M    = 8'h1b;
    localparam MFSM_LD_Q1M    = 8'h1c;
    localparam MFSM_LD_P0M    = 8'h1d;
    localparam MFSM_LD_P1M    = 8'h1e;
    localparam MFSM_LD_K      = 8'h1f;
    localparam MFSM_LD_ECU    = 8'h20;
    localparam MFSM_LD_Q0X    = 8'h21;
    localparam MFSM_LD_H0     = 8'h22;
    localparam MFSM_LD_RML    = 8'h23;
    localparam MFSM_WB_X      = 8'h30;
    localparam MFSM_WB_Q0M    = 8'h31;
    localparam MFSM_WB_Q1M    = 8'h32;
    localparam MFSM_WB_Q0I    = 8'h33;
    localparam MFSM_WB_ECINVU = 8'h34;
    localparam MFSM_WB_Q0X    = 8'h35;
    localparam MFSM_WB_GCDA   = 8'h36;
    localparam MFSM_WB_R0     = 8'h37;
    localparam MFSM_WB_D      = 8'h38;
    localparam MFSM_WB_RML    = 8'h39;
    localparam MFSM_ST_P0M    = 8'h40;
    localparam MFSM_ST_P1M    = 8'h41;
    localparam MFSM_PF        = 8'h70;

    localparam MFSM_LD_N      = 8'h50;
    localparam MFSM_LD_NT     = 8'h59;
    localparam MFSM_LD_H      = 8'h51;
    localparam MFSM_LD_P      = 8'h52;
    localparam MFSM_LD_PT     = 8'h53;
    localparam MFSM_LD_A      = 8'h54;
    localparam MFSM_LD_EC_H   = 8'h55;
    localparam MFSM_LD_CON1   = 8'h56;
    localparam MFSM_LD_P_INV  = 8'h57;
    localparam MFSM_LD_PT_INV = 8'h58;
    localparam MFSM_J0        = 8'h71;

    localparam scedma_pkg::segcfg_t RSASEG_X      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h000, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t RSASEG_R1     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h100, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t RSASEG_N      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h200, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t RSASEG_E      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h300, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t RSASEG_Y      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h400, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t RSASEG_H      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h600, segsize: 'd258, isfifo:'0, isfifostream:0, fifoid:'0 }; // H is higher by 2 word for lenght=4096 the H will need 4097 bit

    localparam scedma_pkg::segcfg_t INVSEG_U      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h000/*##*/, segsize: 'd128/*#*/, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t INVSEG_P      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h084/*##*/, segsize: 'd128/*#*/, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t INVSEG_UT     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h400/*##*/, segsize: 'd128/*#*/, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t INVSEG_PT     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h484/*##*/, segsize: 'd128/*#*/, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t INVSEG_D      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h610/*##*/, segsize: 'd128/*#*/, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t INVSEG_CON1   = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h508, segsize: 'd128, isfifo:'0, isfifostream:0, fifoid:'0 };

    localparam scedma_pkg::segcfg_t ECCSEG_Q0X    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h000, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_Q0Y    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h400, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_Q0Z    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h024, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_Q0T    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h090/*##*/, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_Q1X    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h012, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_Q1Y    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h412, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_Q1Z    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h424, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_Q1T    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h490/*##*/, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P0X    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h59e, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P0Y    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h19e, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P0Z    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h1d4, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P0T    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h5d4, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P1X    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h5c2, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P1Y    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h1c2, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P1Z    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h1e6, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P1T    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h5e6, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_A      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h036, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_P      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h048, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_K      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h05a, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_U      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h18c, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_H      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h436, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_PT     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h448, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_M      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h45a, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_CON1   = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h46c, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_INVU   = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h568, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t ECCSEG_UT     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h58c, segsize: 'd144, isfifo:'0, isfifostream:0, fifoid:'0 };

    localparam scedma_pkg::segcfg_t GCDSEG_A      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h000, segsize: 'd128, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t GCDSEG_B      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h400, segsize: 'd128, isfifo:'0, isfifostream:0, fifoid:'0 };

    localparam scedma_pkg::segcfg_t RSASEG_R0     = RSASEG_X;
    localparam scedma_pkg::segcfg_t ECCSEG_RML     = ECCSEG_H;


    localparam PTRID_PCON = 0;
    localparam PTRID_PIB0 = 1;
    localparam PTRID_PIB1 = 2;
    localparam PTRID_PKB = 3;
    localparam PTRID_POB = 4;


// typedef
// ■■■■■■■■■■■■■■■

/*
cr_opt.pmode =
    0 none
    1 ec
    2 ed
    3 rsa
cr_opt.nlen
cr_opt.elen
cr_opt.opmask
    0, no i2m
    1, no m2i
    2, no dbl
    3, no wb
*/

    bit [7:0]   cr_func, cr_pcoreir;
//    bit [###]   cr_opt;

    scedma_pkg::segcfg_t ecpsegwpcfg, ecpsegrpcfg;
    logic [7:0] mfsm, mfsmnext;
    bit mfsmtog, mfsmdone, mfsm_done;
    logic pcore_start, chnli_start, chnlo_start, chnlx_start;
    logic pcore_busy,  chnli_busy, chnlo_busy, chnlx_busy;
    logic pcore_done,  chnli_done, chnlo_done, chnlx_done;
    logic [1:0] ramerror;
    logic pcore_en, chnli_en, chnlo_en, chnlx_en;
    chnlreq_t chnlo_rpreq, chnli_wpreq, chnlx_rpreq, chnlx_wpreq;
    chnlres_t chnlo_rpres, chnli_wpres, chnlx_rpres, chnlx_wpres, pramres;
    chnlcfg_t chnli_cfg, chnlo_cfg, chnlx_cfg;
    bit [7:0] chnlo_intr, chnli_intr, chnlx_intr;
    bit optlock;

    logic cr_func_ed, cr_func_ec, cr_func_rsa;
    logic cr_func_bypass;
    logic [2:0] mcnt;

    logic [RAW+1:0] chnl_ramadd, chnl_segptr;
    logic  chnl_ramrd, chnl_ramwr;
    dat_t  chnl_ramwdat, chnl_ramrdat0, chnl_ramrdat1;
    logic [63:0] ramwdat0, ramwdat1, ramrdat0, ramrdat1, pcore_ramrdat0, pcore_ramrdat1, pcore_ramwdat0, pcore_ramwdat1;
//    chnlres_t chnli_wpres, chnlo_rpres, chnlx_rpres, chnlx_wpres, pramres;
    logic  chnl_ramsel0, chnl_ramsel1, chnl_ramrd0, chnl_ramrd1;
    logic [7:0] chnl_ramwr0, chnl_ramwr1, chnl_ramwrs, ramwr0, ramwr1;
    logic [RAW-1:0] chnl_ramadd0, chnl_ramadd1, ramadd0, ramadd1, pcore_ramadd0, pcore_ramadd1;
    logic ramsel0reg, chnl_ramdatselreg;
    logic ramrd0, ramrd1, pcore_ramrd0, pcore_ramrd1, pcore_ramwr0, pcore_ramwr1;
    logic [1:0] ramerror0, ramerror1;
    logic ramready0, ramready1;

    logic [8:0] opt_nw32, opt_nw320, opt_nw32b, opt_nw32b0, opt_ew32, opt_ew320;
    logic [13:0] opt_nw, opt_ew, opt_nwb;
    logic [15:0] opt_mask;
    bit [3:0] opt_n0lwr, opt_n0hwr;
    bit start;
    bit [3:0][63:0] opt_n0;
    adr_t [0:4] cr_segptrstart;
    logic chnli_dummy_con1;
    logic modinvready;
    logic ramclrbusy0, ramclrbusy1;
    logic [9:0] opt_rw;
    adr_t chnli_endptr, chnlo_endptr;
    adr_t chnli_wpreq_segptrx, chnlo_rpreq_segptrx;
    logic chnli_ltx, chnlo_ltx;
    logic [4:0] cr_optltx;
    logic opt_inithcal, opt_inithnt;
    logic [8:0] mimmcr;
    chnlreq_t chnl_wpreq0;
    logic parityerr;
    bit [7:0] tickcyc;
    bit [31:0] tickcntsr;
    logic [31:0] maskseed;
    logic maskseedupd;
    logic opt_wbpsob;
    logic ramclrar;

// apb
// ■■■■■■■■■■■■■■■

    logic apbrd, apbwr;
    logic pclk;
    logic sfrlock;
    assign pclk = clk;

    `theregrn( sfrlock ) <= optlock ? 1'b1 : mfsm_done ? '0 : sfrlock;

    `apbs_common;
    assign apbx.prdata = '0
                        | sfr_crfunc.prdata32 | sfr_srmfsm.prdata32 | sfr_fr.prdata32
                        | sfr_optnw.prdata32 | sfr_optew.prdata32 | sfr_optrw.prdata32 | sfr_optltx.prdata32 | sfr_optmask.prdata32 | sfr_mimmcr.prdata32
                        | sfr_segptr.prdata32
                        | sfr_tickcyc.prdata32 | sfr_tickcnt.prdata32
                        | sfr_maskseed.prdata32
                        ;

    apb_cr #(.A('h00), .DW(16))     sfr_crfunc      (.cr({cr_pcoreir, cr_func}), .prdata32(),.*);
    apb_ar #(.A('h04), .AR(32'h5a)) sfr_ar          (.ar(start),.*);
    apb_ar #(.A('h04), .AR(32'hff)) sfr_ar2         (.ar(ramclrar),.*);
    apb_sr #(.A('h08), .DW(9))      sfr_srmfsm      (.sr({modinvready,mfsm}), .prdata32(),.*);
    apb_fr #(.A('h0c), .DW(5))      sfr_fr          (.fr({chnlx_done, chnli_done, chnlo_done, pcore_done, mfsm_done}), .prdata32(),.*);

    apb_cr #(.A('h10), .DW(14))      sfr_optnw      (.cr(opt_nw), .prdata32(),.*);
    apb_cr #(.A('h14), .DW(14))      sfr_optew      (.cr(opt_ew), .prdata32(),.*);
    apb_cr #(.A('h18), .DW(10))      sfr_optrw      (.cr(opt_rw), .prdata32(),.*);
    apb_cr #(.A('h1C), .DW(5))       sfr_optltx     (.cr(cr_optltx), .prdata32(),.*);

    apb_cr #(.A('h20), .DW(16))      sfr_optmask    (.cr(opt_mask), .prdata32(),.*); //## width?
    apb_cr #(.A('h24), .DW(9))       sfr_mimmcr     (.cr(mimmcr), .prdata32(),.*); //## width?
    apb_cr #(.A('h30), .DW(scedma_pkg::AW), .SFRCNT(5) )      sfr_segptr    (.cr(cr_segptrstart), .prdata32(),.*); //## width?

    apb_cr #(.A('h50), .DW(8))   sfr_tickcyc    (.cr(tickcyc),    .prdata32(),.*);
    apb_sr #(.A('h54), .DW(32))  sfr_tickcnt    (.sr(tickcntsr),  .prdata32(),.*);

    apb_cr #(.A('h60), .DW(32))      sfr_maskseed     (.cr(maskseed), .prdata32(),.*);
    apb_ar #(.A('h64), .AR(32'h5a))  sfr_maskseedar   (.ar(maskseedupd),  .*);

    assign optlock = ( start & ( mfsm == MFSM_IDLE));

    assign cr_func_ed = ( cr_func[7:4] == 4'h2 );
    assign cr_func_ec = ( cr_func[7:4] == 4'h0 );
    assign cr_func_rsa = ( cr_func[7:4] == 4'h1 );
    assign cr_func_bypass = ( cr_func[7:0] == 8'hff );
    assign mcnt = cr_func_ed ? 4 : 3;  // montgemary cnt
    assign busy = |mfsm | ramclrbusy0 | ramclrbusy1;
    assign done = mfsm_done;

// mfsm
// ■■■■■■■■■■■■■■■
    `theregfull(clk, resetn, mfsm, MFSM_IDLE ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone ? mfsmnext : mfsm;
//    `theregrn( mfsmtog ) <= ( mfsm != mfsmnext ) & ( mfsmnext != MFSM_IDLE );
    `theregrn( mfsmtog ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone;// ~( mfsm == mfsmnext ) & ~( mfsmnext == MFSM_IDLE );
    assign mfsm_done = ( mfsm == MFSM_DONE );

genvar i;
generate
    for (i = 0; i < 4; i++) begin: gen_n0;
    `theregrn( opt_n0[i][31:0]  ) <= opt_n0lwr[i] ? chnli_wpreq.segwdat : opt_n0[i][31:0];
    `theregrn( opt_n0[i][63:32] ) <= opt_n0hwr[i] ? chnli_wpreq.segwdat : opt_n0[i][63:32];

    assign opt_n0lwr[i] = (( mfsm == MFSM_LD_N ) | ( mfsm == MFSM_LD_P )) & ( chnli_wpreq_segptrx == i*2 + 0 ) & chnli_wpreq.segwr ;
    assign opt_n0hwr[i] = (( mfsm == MFSM_LD_N ) | ( mfsm == MFSM_LD_P )) & ( chnli_wpreq_segptrx == i*2 + 1 ) & chnli_wpreq.segwr ;
    end
endgenerate

    assign opt_inithcal = ~opt_mask[0];
    assign opt_inithnt = ~opt_mask[1];
    assign opt_wbpsob = opt_mask[3];

    always_comb begin
        mfsmnext = mfsm;
        mfsmdone = '0;
        case (cr_func)
            // rsa: N/H - J0(20) - HCal(11)
            // ec:  P/PT/A/H/const1  - J0(20) - HCal(01)
            // inv: P/PT
            PIR_RSAINIT:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_N;
                    MFSM_LD_N : begin
                                                mfsmnext = opt_inithcal ? MFSM_LD_H : MFSM_J0;
                                                                            mfsmdone = chnli_done;
                        end
                    MFSM_LD_H : begin
                                                mfsmnext = MFSM_J0;         mfsmdone = chnli_done;
                        end
                    MFSM_J0 : begin
                                                mfsmnext = opt_inithcal ? MFSM_PF :
                                                           opt_inithnt ?  MFSM_LD_NT : MFSM_DONE;
                                                                            mfsmdone = pcore_done;
                        end
                    MFSM_LD_NT : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = pcore_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_ECINIT:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_P;
                    MFSM_LD_P : begin
                                                mfsmnext = MFSM_LD_PT;      mfsmdone = chnli_done;
                        end
                    MFSM_LD_PT : begin
                                                mfsmnext = MFSM_LD_A;       mfsmdone = chnli_done;
                        end
                    MFSM_LD_A : begin
                                                mfsmnext = MFSM_LD_EC_H;    mfsmdone = chnli_done;
                        end
                    MFSM_LD_EC_H : begin
                                                mfsmnext = MFSM_LD_CON1;    mfsmdone = chnli_done;
                        end
                    MFSM_LD_CON1 : begin
                                                mfsmnext = MFSM_J0;         mfsmdone = chnli_done;
                        end
                    MFSM_J0 : begin
                                                mfsmnext = opt_inithcal ? MFSM_PF : MFSM_DONE;
                                                                            mfsmdone = pcore_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = pcore_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_INVINIT:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_P_INV;
                    MFSM_LD_P_INV : begin
                                                mfsmnext = MFSM_LD_PT_INV;  mfsmdone = chnli_done;
                        end
                    MFSM_LD_PT_INV : begin
                                                mfsmnext = MFSM_LD_CON1;    mfsmdone = chnli_done;
                        end
                    MFSM_LD_CON1 : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnli_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase

            PIR_RSAMM,
            PIR_RSAMA,
            PIR_RSAMS,
            PIR_ECMM,
            PIR_ECMA,
            PIR_ECMS:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_X;
                    MFSM_LD_X : begin
                                                mfsmnext = MFSM_LD_Y;       mfsmdone = chnli_done;
                        end
                    MFSM_LD_Y : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_X;       mfsmdone = pcore_done;
                        end
                    MFSM_WB_X : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_MODINV:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_RSAU;
                    MFSM_LD_RSAU : begin
                                                mfsmnext = MFSM_LD_RSAUT;   mfsmdone = chnli_done;
                        end
                    MFSM_LD_RSAUT : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_D;       mfsmdone = pcore_done;
                        end
                    MFSM_WB_D : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_ECI2MA,
            PIR_EDI2MA:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_Q0I;
                    MFSM_LD_Q0I : begin
                                                mfsmnext = MFSM_LD_Q1I;     mfsmdone = chnli_done;
                        end
                    MFSM_LD_Q1I : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_Q0M;     mfsmdone = pcore_done;
                        end
                    MFSM_WB_Q0M : begin
                                                mfsmnext = MFSM_WB_Q1M;     mfsmdone = chnlo_done;
                        end
                    MFSM_WB_Q1M : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_ECI2MD,
            PIR_EDI2MD:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_Q0I;
                    MFSM_LD_Q0I : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_Q0M;     mfsmdone = pcore_done;
                        end
                    MFSM_WB_Q0M : begin
                                                mfsmnext = MFSM_ST_P0M;     mfsmdone = chnlo_done;
                        end
                    MFSM_ST_P0M : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlx_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_ECM2I,
            PIR_EDM2I:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_Q0M;
                    MFSM_LD_Q0M : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_Q0M;     mfsmdone = pcore_done;
                        end
                    MFSM_WB_Q0M : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_ECPA,
            PIR_EDPA:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_Q0M ;
                    MFSM_LD_Q0M : begin
                                                mfsmnext = MFSM_LD_Q1M;     mfsmdone = chnli_done;
                        end
                    MFSM_LD_Q1M : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_Q0M;     mfsmdone = pcore_done;
                        end
                    MFSM_WB_Q0M : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                     MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
               endcase
            PIR_ECPD,
            PIR_EDPD:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_Q0M ;
                    MFSM_LD_Q0M : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_Q0M;     mfsmdone = pcore_done;
                        end
                    MFSM_WB_Q0M : begin
                                                mfsmnext = MFSM_ST_P1M;     mfsmdone = chnlo_done;
                        end
                    MFSM_ST_P1M : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlx_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_ECPM,
            PIR_EDPM:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_P0M ;
                    MFSM_LD_P0M : begin
                                                mfsmnext = MFSM_LD_P1M;     mfsmdone = chnli_done;
                        end
                    MFSM_LD_P1M : begin
                                                mfsmnext = MFSM_LD_K;       mfsmdone = chnli_done;
                        end
                    MFSM_LD_K : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_ST_P0M;     mfsmdone = pcore_done;
                        end
                    MFSM_ST_P0M : begin
                                                mfsmnext = MFSM_WB_Q0M;     mfsmdone = chnlx_done;
                        end
                    MFSM_WB_Q0M : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_ECINV:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_ECU ;
                    MFSM_LD_ECU : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_ECINVU;  mfsmdone = pcore_done;
                        end
                    MFSM_WB_ECINVU : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_X25519:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_Q0X ;//##
                    MFSM_LD_Q0X : begin
                                                mfsmnext = MFSM_LD_K;       mfsmdone = chnli_done;
                        end
                    MFSM_LD_K : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_Q0M;     mfsmdone = pcore_done;
                        end
                    MFSM_WB_Q0M : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_GCD:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_GCDA;
                    MFSM_LD_GCDA : begin
                                                mfsmnext = MFSM_LD_GCDB;       mfsmdone = chnli_done;
                        end
                    MFSM_LD_GCDB : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_GCDA;       mfsmdone = pcore_done;
                        end
                    MFSM_WB_GCDA : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            PIR_RSAME:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_R0;
                    MFSM_LD_R0 : begin
                                                mfsmnext = MFSM_LD_R1;      mfsmdone = chnli_done;
                        end
                    MFSM_LD_R1 : begin
                                                mfsmnext = MFSM_LD_E;       mfsmdone = chnli_done;
                        end
                    MFSM_LD_E : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_R0;       mfsmdone = pcore_done;
                        end
                    MFSM_WB_R0 : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            //PIR_RSAMI,
            PIR_RMODL:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_H0;
                    MFSM_LD_H0 : begin
                                                mfsmnext = MFSM_LD_RML;      mfsmdone = chnli_done;
                        end
                    MFSM_LD_RML : begin
                                                mfsmnext = MFSM_PF;         mfsmdone = chnli_done;
                        end
                    MFSM_PF : begin
                                                mfsmnext = MFSM_WB_RML;     mfsmdone = pcore_done;
                        end
                    MFSM_WB_RML : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase

            PIR_PCORE:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_PF;
                    MFSM_PF : begin
                                                mfsmnext = MFSM_DONE;     mfsmdone = pcore_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            default :
                begin
                    mfsmnext = mfsm;
                    mfsmdone = '0;
                end
        endcase
    end

// subcore, chnl
// ■■■■■■■■■■■■■■■

    `theregrn( pcore_start ) <= mfsmtog & (( mfsm == MFSM_PF  ) | ( mfsm == MFSM_J0 ));

    assign pcore_en = (( mfsm == MFSM_PF  ) | ( mfsm == MFSM_J0 ));
    assign opt_nw320 = opt_nw[13:5] + |opt_nw[4:0];
    assign opt_nw32 = opt_nw320 + opt_nw320[0] ;

    assign opt_ew320 = opt_ew[13:5] + |opt_ew[4:0];
    assign opt_ew32 = opt_ew320 + opt_ew320[0] ;

    assign opt_nwb = opt_nw + 1;
    assign opt_nw32b0 = opt_nwb[13:5] + |opt_nwb[4:0];
    assign opt_nw32b = opt_nw32b0 + opt_nw32b0[0] ;

    logic [7:0] pkeir;
    assign pkeir =  cr_func_bypass ? cr_pcoreir : ( mfsm == MFSM_J0 ) ? 8'h20 : cr_func;

    logic  pcore_start_sync, pcore_done_sync;
    logic  pcore_start0, pcore_done0;
    logic  maskseedupd_sync;
    logic [63:0] pkemaskdat, mimm_dbrnd;
    logic optsec0, optsec;

    PkeCore pcore(
            .Clk              (clkpke),
            .Resetn           (resetn),
            .PkeIR            (pkeir),
            .NLen             (opt_nw),
            .ELen             (opt_ew),
            .N0Dat            (opt_n0),
            .PkeStart         (pcore_start_sync),
            .PkeInt           (pcore_done_sync),
            .ModInvRdy        (modinvready),
            .parityerr        (parityerr),

            .mmsel            (mimmcr[8]),
            .mimm_opt         (mimmcr[7:0]),
            .mimm_dbrnd       ,

            .PkeRamRd0        (pcore_ramrd0),
            .PkeRamWr0        (pcore_ramwr0),
            .PkeRamAddr0      (pcore_ramadd0[RAW-1:0]),
            .PkeRamDat0       (pcore_ramwdat0),
            .RamPkeDat0       (pcore_ramrdat0),

            .PkeRamRd1        (pcore_ramrd1),
            .PkeRamWr1        (pcore_ramwr1),
            .PkeRamAddr1      (pcore_ramadd1[RAW-1:0]),
            .PkeRamDat1       (pcore_ramwdat1),
            .RamPkeDat1       (pcore_ramrdat1),
            .cmsatpg, .cmsbist, .rbs(rbsmimm)
          );

// chnl behavior
// ■■■■■■■■■■■■■■■

    `theregfull( clkpke, resetn, optsec0, '0 ) <= mimmcr[3];
    `theregfull( clkpke, resetn, optsec,  '0 ) <= optsec0;
`ifdef FPGA
    assign mimm_dbrnd = '0;
`else
    assign mimm_dbrnd = optsec ? pkemaskdat : '0;
`endif
    sync_pulse sync_reseed ( .clka(clk),    .resetn, .clkb(clkpke), .pulsea (maskseedupd), .pulseb( maskseedupd_sync ) );

    // tapeout deviation (bunnie) - LFSR_IV is too long, causes verilator errors. Original value: 'h55aa_aa55_5a5a_a5a5, assume
    // truncatetion to the LSB's.
    drng_lfsr #( .LFSR_W(229),.LFSR_NODE({ 10'd228, 10'd225, 10'd219 }), .LFSR_OW(32), .LFSR_IW(32), .LFSR_IV('h5a5a_a5a5) )
        ua( .clk(clkpke), .sen(optsec), .resetn(resetn), .swr(maskseedupd_sync), .sdin(maskseed), .sdout(pkemaskdat[31:0]) );

    // tapeout deviation (bunnie) - LFSR_IV is too long, causes verilator errors. Original value: 'h55aa_aa55_5a5a_a5a5, assume
    // truncatetion to the LSB's.
    drng_lfsr #( .LFSR_W(229),.LFSR_NODE({ 10'd228, 10'd225, 10'd219 }), .LFSR_OW(32), .LFSR_IW(32), .LFSR_IV('ha5a5_5a5a) )
        ub( .clk(clkpke), .sen(optsec), .resetn(resetn), .swr(maskseedupd_sync), .sdin(pkemaskdat[31:0]), .sdout(pkemaskdat[63:32]) );

// tick
// ■■■■■■■■■■■■■■■

generate
    if(1)begin:gtick_clkpke

        bit [7:0] tickcnt0;
        bit tickclr, ticklock, tickhit;
        bit [31:0] tickcnt;
        bit pcore_busy;

        assign tickclr = ~pcore_busy;
        assign ticklock = pcore_done_sync;
        assign tickhit = ( tickcnt0 == tickcyc );
        `theregfull(clkpke, resetn, pcore_busy, '0) <= pcore_start_sync ? 1'b1 : pcore_done_sync ? 1'b0 : pcore_busy;
        `theregfull(clkpke, resetn, tickcnt0, '0 ) <= tickclr | tickhit ? '0 : tickcnt0 + 1;
        `theregfull(clkpke, resetn, tickcnt, '0 ) <= tickclr ? '0 : tickcnt + tickhit ;
        `theregfull(clkpke, resetn, tickcntsr, '0 ) <= ticklock ? tickcnt : tickcntsr;
    end
endgenerate

    sync_pulse sync_start ( .clka(clk),    .resetn, .clkb(clkpke), .pulsea (pcore_start0), .pulseb( pcore_start_sync ) );
    sync_pulse sync_done  ( .clka(clkpke), .resetn, .clkb(clk),    .pulsea (pcore_done_sync ), .pulseb( pcore_done0 ) );

    logic [7:0] pcore_start_regs, pcore_done_regs;

    `theregfull( clk, resetn, pcore_start_regs, '0 ) <= { pcore_start_regs, pcore_start };
    `theregfull( clk, resetn, pcore_done_regs,  '0 ) <= { pcore_done_regs,  pcore_done0 };

    assign pcore_start0 = pcore_start_regs[7];
    assign pcore_done   =pcore_done_regs[7];


    logic clkram_clkpke, clkram_clksce, clkramen, clkram;

    `theregfull( clksce, resetn, clkram_clksce, '1 ) <= pcore_start  ? '0 : pcore_done  ? '1 : clkram_clksce;
//    `theregrn( clkram_clkpke ) <= pcore_start0 ? '1 : pcore_done0 ? '0 : clkram_clkpke;
    `theregfull( clkpke, resetn, clkram_clkpke, '0 ) <= pcore_start_sync ? '1 : pcore_done_sync ? '0 : clkram_clkpke;
`ifdef FPGA
    assign clkramen = '1;
    assign clkram = clk;
`else
//    assign clkramen = clkram_clkpke & clkpkeen | clkram_clksce & clksceen;
//    ICG icg_clkram(.CK(clktop), .SE(cmsatpg), .EN(clkramen), .CKG(clkram));

    logic [1:0] clkram0, clkram01;
    logic clkram_unmux, clkram_unbuf;

    ICG uclkram0 ( .CK (clksce ), .EN ( clkram_clksce ), .SE(cmsatpg), .CKG ( clkram0[0] ));
    ICG uclkram1 ( .CK (clkpke ), .EN ( clkram_clkpke ), .SE(cmsatpg), .CKG ( clkram0[1] ));

    assign clkram_unmux = |clkram0 ;
    CLKCELL_MUX2 u_scanmux_clkram (.A(clkram_unmux),.B(clk),.S(cmsatpg),.Z(clkram_unbuf));
    CLKCELL_BUF buf_clkram(.A(clkram_unbuf),.Z(clkram));

`endif

// ecpseg
// ■■■■■■■■■■■■■■■
    logic [1:0] ecpsegrpaddrsel_x, ecpsegwpaddrsel_x, ecpsegwpaddrsel_i, ecpsegrpaddrsel_o;
    logic ecpsegrpen, ecpsegwpen, ecpsegxpen;
//    segcfg_t  ecpsegwpcfg, ecpsegrpcfg;
    logic [RAW:0] ecpsegsize, ecpsegptr ;

    adr_t [0:3] ecpsegwpaddrs, ecpsegrpaddrs, ecpsegwpaddr, ecpsegrpaddr;
    logic ecpsegwpaddrset, ecpsegrpaddrset;
    logic [1:0] ecpsegwpaddrsel, ecpsegrpaddrsel, ecpsegidx;

    adr_t ecpsegwpaddr0, ecpsegrpaddr0;

    assign ecpsegwpaddr0 = ecpsegwpaddr[ecpsegidx];
    assign ecpsegrpaddr0 = ecpsegrpaddr[ecpsegidx];

    assign ecpsegwpcfg = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: ecpsegwpaddr0, segsize: ecpsegsize, isfifo:'0, isfifostream:0, fifoid:'0 };
    assign ecpsegrpcfg = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: ecpsegrpaddr0, segsize: ecpsegsize, isfifo:'0, isfifostream:0, fifoid:'0 };
    assign ecpsegsize = opt_nw32;

    localparam scedma_pkg::adr_t [0:3] ECPSEGADDR_Q0 = { ECCSEG_Q0X.segaddr, ECCSEG_Q0Y.segaddr, ECCSEG_Q0Z.segaddr, ECCSEG_Q0T.segaddr };
    localparam scedma_pkg::adr_t [0:3] ECPSEGADDR_Q1 = { ECCSEG_Q1X.segaddr, ECCSEG_Q1Y.segaddr, ECCSEG_Q1Z.segaddr, ECCSEG_Q1T.segaddr };
    localparam scedma_pkg::adr_t [0:3] ECPSEGADDR_P0 = { ECCSEG_P0X.segaddr, ECCSEG_P0Y.segaddr, ECCSEG_P0Z.segaddr, ECCSEG_P0T.segaddr };
    localparam scedma_pkg::adr_t [0:3] ECPSEGADDR_P1 = { ECCSEG_P1X.segaddr, ECCSEG_P1Y.segaddr, ECCSEG_P1Z.segaddr, ECCSEG_P1T.segaddr };

    assign ecpsegwpaddrset = mfsmtog;
    assign ecpsegrpaddrset = mfsmtog;
    `theregrn( ecpsegwpaddr ) <= ecpsegwpaddrset ? ecpsegwpaddrs : ecpsegwpaddr;
    `theregrn( ecpsegrpaddr ) <= ecpsegrpaddrset ? ecpsegrpaddrs : ecpsegrpaddr;

    assign ecpsegwpaddrsel = chnlx_en ? ecpsegwpaddrsel_x : ecpsegwpaddrsel_i;
    assign ecpsegrpaddrsel = chnlx_en ? ecpsegrpaddrsel_x : ecpsegrpaddrsel_o;
    assign ecpsegwpaddrs = ( ecpsegwpaddrsel == 0 ) ? ECPSEGADDR_Q0 :
                           ( ecpsegwpaddrsel == 1 ) ? ECPSEGADDR_Q1 :
                           ( ecpsegwpaddrsel == 2 ) ? ECPSEGADDR_P0 :
                                                      ECPSEGADDR_P1 ;
    assign ecpsegrpaddrs = ( ecpsegrpaddrsel == 0 ) ? ECPSEGADDR_Q0 :
                           ( ecpsegrpaddrsel == 1 ) ? ECPSEGADDR_Q1 :
                           ( ecpsegrpaddrsel == 2 ) ? ECPSEGADDR_P0 :
                                                      ECPSEGADDR_P1 ;
    `theregrn( ecpsegidx ) <= mfsmtog ? '0 : ( ecpsegptr == opt_nw32 - 1 ) & ( chnl_ramwr |  chnl_wpreq0.segwr ) ? ecpsegidx + 1 : ecpsegidx;
    `theregrn( ecpsegptr ) <= mfsmtog ? '0 : ( chnl_ramwr | chnl_wpreq0.segwr ) ? (( ecpsegptr == opt_nw32 - 1 ) ? '0 : ecpsegptr + 1 ) : ecpsegptr;

// chnl behavior
// ■■■■■■■■■■■■■■■

    `theregrn( chnli_start ) <= mfsmtog & chnli_en;
    `theregrn( chnlo_start ) <= mfsmtog & chnlo_en;
    `theregrn( chnlx_start ) <= mfsmtog & chnlx_en;

    always_comb begin
        chnli_cfg.wpsegcfg = ECCSEG_U;
        chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PIB0];
        chnli_ltx = cr_optltx[PTRID_PIB0];
        chnli_endptr = opt_nw32;
        chnli_cfg.rpsegcfg = SEG_PIB;
        chnli_cfg.transsize = opt_nw32;
        ecpsegwpaddrsel_i = 0;
        ecpsegwpen = 1'b0;
        chnli_en = '0;
        chnli_dummy_con1 = 0;
        case(mfsm)
            MFSM_LD_X      :  // rsa, ec
                begin
                    chnli_cfg.wpsegcfg = RSASEG_X;
                    chnli_en = '1;
                end
            MFSM_LD_Y      :  // rsa,
                begin
                    chnli_cfg.wpsegcfg = RSASEG_Y;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PIB1];
                    chnli_ltx = cr_optltx[PTRID_PIB1];
                    chnli_en = '1;
                end
            MFSM_LD_RSAU      :  // modinv
                begin
                    chnli_cfg.wpsegcfg = INVSEG_U;
                    chnli_en = '1;
                end
            MFSM_LD_RSAUT      :  // modinv
                begin
                    chnli_cfg.wpsegcfg = INVSEG_UT;
                    chnli_en = '1;
                end
            MFSM_LD_GCDA      :    // gcd
                begin
                    chnli_cfg.wpsegcfg = GCDSEG_A;
                    chnli_en = '1;
                end
            MFSM_LD_GCDB      :
                begin
                    chnli_cfg.wpsegcfg = GCDSEG_B;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PIB1];
                    chnli_ltx = cr_optltx[PTRID_PIB1];
                    chnli_en = '1;
                end
            MFSM_LD_R0     :
                begin
                    chnli_cfg.rpsegcfg = '0;//SEG_R0;//####
                    chnli_dummy_con1 = 1;
                    chnli_cfg.wpsegcfg = RSASEG_X;
                    chnli_cfg.rpptr_start = '0;
                    chnli_en = '1;
                end
            MFSM_LD_R1     :
                begin
                    chnli_cfg.wpsegcfg = RSASEG_R1;
                    chnli_en = '1;
                end
            MFSM_LD_E      :
                begin
                    chnli_cfg.rpsegcfg = SEG_PKB;
                    chnli_cfg.wpsegcfg = RSASEG_E;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PKB];
                    chnli_ltx = cr_optltx[PTRID_PKB];
                    chnli_cfg.transsize =(opt_ew > opt_nw) ? opt_ew32 : opt_nw32;
                    chnli_endptr = (opt_ew > opt_nw) ? opt_ew32 : opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_Q0I    :
                begin
                    chnli_cfg.wpsegcfg = ecpsegwpcfg;//####PKESEG_Q0;
                    ecpsegwpen = 1'b1;
                    ecpsegwpaddrsel_i = 0;
                    chnli_cfg.transsize = opt_nw32 * mcnt;
                    chnli_endptr = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_Q1I    :
                begin
                    chnli_cfg.wpsegcfg = ecpsegwpcfg;//####PKESEG_Q1;
                    ecpsegwpen = 1'b1;
                    ecpsegwpaddrsel_i = 1;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PIB1];
                    chnli_ltx = cr_optltx[PTRID_PIB1];
                    chnli_cfg.transsize = opt_nw32 * mcnt;
                    chnli_endptr = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_Q0M    :
                begin
                    chnli_cfg.wpsegcfg = ecpsegwpcfg;//####PKESEG_Q0;
                    ecpsegwpen = 1'b1;
                    ecpsegwpaddrsel_i = 0;
                    chnli_cfg.transsize = opt_nw32 * mcnt;
                    chnli_endptr = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_Q1M    :
                begin
                    chnli_cfg.wpsegcfg = ecpsegwpcfg;//####PKESEG_Q1;
                    ecpsegwpen = 1'b1;
                    ecpsegwpaddrsel_i = 1;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PIB1];
                    chnli_ltx = cr_optltx[PTRID_PIB1];
                    chnli_cfg.transsize = opt_nw32 * mcnt;
                    chnli_endptr = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_P0M    :
                begin
                    chnli_cfg.wpsegcfg = ecpsegwpcfg;//####PKESEG_P0;
                    ecpsegwpen = 1'b1;
                    ecpsegwpaddrsel_i = 2;
                    chnli_cfg.transsize = opt_nw32 * mcnt;
                    chnli_endptr = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_P1M    :
                begin
                    chnli_cfg.wpsegcfg = ecpsegwpcfg;//####PKESEG_P1;
                    ecpsegwpen = 1'b1;
                    ecpsegwpaddrsel_i = 3;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PIB1];
                    chnli_ltx = cr_optltx[PTRID_PIB1];
                    chnli_cfg.transsize = opt_nw32 * mcnt;
                    chnli_endptr = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_K      :
                begin
                    chnli_cfg.rpsegcfg = SEG_PKB;
                    chnli_cfg.wpsegcfg = ECCSEG_K;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PKB];
                    chnli_ltx = cr_optltx[PTRID_PKB];
                    chnli_en = '1;
                end
            MFSM_LD_ECU      :
                begin
                    chnli_cfg.wpsegcfg = ECCSEG_U;
                    chnli_en = '1;
                end
            MFSM_LD_Q0X    :
                begin
                    chnli_cfg.wpsegcfg = ecpsegwpcfg;//####PKESEG_Q0X;
                    ecpsegwpen = 1'b1;
                    ecpsegwpaddrsel_i = 0;
                    chnli_cfg.transsize = opt_nw32*3;
                    chnli_endptr = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_N      :
                begin
                    chnli_cfg.wpsegcfg = RSASEG_N;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON];
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_NT      :
                begin
                    chnli_cfg.wpsegcfg = RSASEG_H;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON];
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_H      :
                begin
                    chnli_cfg.wpsegcfg = RSASEG_H;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON] + opt_nw32;
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = opt_nw32b;
                    chnli_endptr = opt_nw32b;
                    chnli_en = '1;
                end
            MFSM_LD_P      :
                begin
                    chnli_cfg.wpsegcfg = ECCSEG_P;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON];
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_PT     :
                begin
                    chnli_cfg.wpsegcfg = ECCSEG_PT;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON];
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_A      :
                begin
                    chnli_cfg.wpsegcfg = ECCSEG_A;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON] + opt_nw32 ;
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_EC_H   :
                begin
                    chnli_cfg.wpsegcfg = ECCSEG_H;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON] + opt_nw32 * 2;
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = (opt_nw >'d512) ? opt_nw32: opt_nw32+1;
                    chnli_endptr = (opt_nw >'d512) ? opt_nw32 : opt_nw32+1;
                    chnli_en = '1;
                end
            MFSM_LD_CON1   :
                begin
                    chnli_cfg.rpsegcfg = '0;//SEG_R0;//####
                    chnli_cfg.rpptr_start = '0;
                    chnli_ltx = '0;
                    chnli_cfg.wpsegcfg = ( cr_func == PIR_INVINIT ) ? INVSEG_CON1 : ECCSEG_CON1;
                    chnli_cfg.transsize = opt_nw32;
                    chnli_dummy_con1 = 1;
                    chnli_en = '1;
                end
            MFSM_LD_P_INV  :
                begin
                    chnli_cfg.wpsegcfg = INVSEG_P;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON];
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_PT_INV :
                begin
                    chnli_cfg.wpsegcfg = INVSEG_PT;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_PCON];
                    chnli_ltx = cr_optltx[PTRID_PCON];
                    chnli_cfg.rpsegcfg = SEG_PCON ;
                    chnli_cfg.transsize = opt_nw32;
                    chnli_en = '1;
                end
            MFSM_LD_H0 :
                begin
                    chnli_cfg.wpsegcfg = ECCSEG_RML;
                    chnli_cfg.transsize = 18; // 576/32;
                    chnli_en = '1;
                end
            MFSM_LD_RML :
                begin
                    chnli_cfg.wpsegcfg = ECCSEG_RML;
                    chnli_cfg.transsize = opt_rw[9:5];
                    chnli_endptr = opt_rw[9:5];
                    chnli_en = '1;
                end
            default :
                begin
                    chnli_cfg.wpsegcfg = ECCSEG_Q0X;
                    chnli_en = '0;
                end
        endcase
    end

    assign chnli_cfg.chnlid = '0;
    assign chnli_cfg.wpptr_start = '0;
    assign chnli_cfg.opt_ltx = '0 | chnli_ltx;
    assign chnli_cfg.opt_xor = '0;
    assign chnli_cfg.opt_cmpp = '0;
    assign chnli_cfg.opt_prm = '0;
    assign chnli_cfg.wpffen = '0;

    always_comb begin
        ecpsegrpen = 1'b0;
        ecpsegrpaddrsel_o = 0;
        chnlo_cfg.wpsegcfg = opt_wbpsob ? SEG_PSOB : SEG_POB;
        chnlo_cfg.wpptr_start = cr_segptrstart[PTRID_POB];
        chnlo_ltx = cr_optltx[PTRID_POB];
        chnlo_cfg.transsize = opt_nw32;
        chnlo_endptr = opt_nw32;
        case(mfsm)
            MFSM_WB_X:
                begin
                    chnlo_cfg.rpsegcfg = RSASEG_X;
                    chnlo_en = '1;
                end
            MFSM_WB_Q0M:
                begin
                    chnlo_cfg.rpsegcfg = ecpsegrpcfg;
                    ecpsegrpen = 1'b1;
                    ecpsegrpaddrsel_o = 0;
                    chnlo_cfg.transsize = opt_nw32 * mcnt;
                    chnlo_en = '1;
                end
            MFSM_WB_Q1M:
                begin
                    chnlo_cfg.rpsegcfg = ecpsegrpcfg;
                    ecpsegrpen = 1'b1;
                    chnlo_cfg.wpptr_start = cr_segptrstart[PTRID_POB] + ( opt_nw32 * mcnt );
                    ecpsegrpaddrsel_o = 1;
                    chnlo_cfg.transsize = opt_nw32 * mcnt;
                    chnlo_en = '1;
                end
            MFSM_WB_Q0I:
                begin
                    chnlo_cfg.rpsegcfg = ecpsegrpcfg;
                    ecpsegrpen = 1'b1;
                    ecpsegrpaddrsel_o = 0;
                    chnlo_cfg.transsize = opt_nw32 * 2;
                    chnlo_en = '1;
                end
            MFSM_WB_ECINVU:
                begin
                    chnlo_cfg.rpsegcfg = ECCSEG_INVU;
                    chnlo_en = '1;
                end
            MFSM_WB_Q0X:
                begin
                    chnlo_cfg.rpsegcfg = ECCSEG_Q0X;
                    chnlo_en = '1;
                end
            MFSM_WB_GCDA:
                begin
                    chnlo_cfg.rpsegcfg = GCDSEG_A;
                    chnlo_en = '1;
                end
            MFSM_WB_R0:
                begin
                    chnlo_cfg.rpsegcfg = RSASEG_R0;
                    chnlo_en = '1;
                end
            MFSM_WB_D:
                begin
                    chnlo_cfg.rpsegcfg = INVSEG_D;
                    chnlo_en = '1;
                end
            MFSM_WB_RML:
                begin
                    chnlo_cfg.rpsegcfg = ECCSEG_RML;
                    chnlo_en = '1;
                end
            default : /* default */
                begin
                    chnlo_cfg.rpsegcfg = RSASEG_X;
                    chnlo_en = '0;
                end
        endcase
    end

    assign chnlo_cfg.chnlid = '0;
    assign chnlo_cfg.rpptr_start = '0;
    assign chnlo_cfg.opt_ltx = '0 | chnlo_ltx;
    assign chnlo_cfg.opt_xor = '0;
    assign chnlo_cfg.opt_cmpp = '0;
    assign chnlo_cfg.opt_prm = '0;
    assign chnlo_cfg.wpffen = '0;

    assign ecpsegxpen = chnlx_en;
    always_comb begin
                    chnlx_cfg.rpsegcfg = ecpsegrpcfg; //ECCSEG_P0X;
                    chnlx_cfg.wpsegcfg = ecpsegwpcfg; //ECCSEG_Q0X;
                    ecpsegrpaddrsel_x = 2;
                    ecpsegwpaddrsel_x = 0;
                    chnlx_cfg.wpptr_start = '0;
                    chnlx_cfg.transsize = opt_nw32 * mcnt;
                    chnlx_en = '0;
        case(mfsm)
            MFSM_ST_P0M:
                begin
                    chnlx_en = '1;
                end
            MFSM_ST_P1M:
                begin
                    ecpsegrpaddrsel_x = 3;
                    chnlx_en = '1;
                end
            default : /* default */
                begin
                    chnlx_cfg.rpsegcfg = ecpsegrpcfg;
                    chnlx_cfg.wpsegcfg = ecpsegwpcfg;
                    ecpsegrpaddrsel_x = 2;
                    ecpsegwpaddrsel_x = 0;
                    chnlx_cfg.wpptr_start = '0;
                    chnlx_cfg.transsize = opt_nw32 * mcnt;
                    chnlx_en = '0;
                end
        endcase
    end

    assign chnlx_cfg.chnlid = '0;
    assign chnlx_cfg.rpptr_start = '0;
    assign chnlx_cfg.opt_ltx = '0;
    assign chnlx_cfg.opt_xor = '0;
    assign chnlx_cfg.opt_cmpp = '0;
    assign chnlx_cfg.opt_prm = '0;
    assign chnlx_cfg.wpffen = '0;

// point comp

    logic edpcomp_mfsm, edpcomp_x_pl1, edpcomp_x00, edpcomp_y;
    logic opt_edpcomp;

    assign opt_edpcomp = opt_mask[2];

    assign edpcomp_mfsm = ( mfsm == MFSM_WB_Q0M );// && opt_edpcomp;

    `theregrn( edpcomp_x_pl1 ) <= edpcomp_mfsm && chnlo_rpreq.segrd && ( chnlo_rpreq.segaddr == ECCSEG_Q0X.segaddr ) && ( chnlo_rpreq.segptr == 'h0 );
    `theregrn( edpcomp_x00 ) <= edpcomp_x_pl1 ? chnlo_rpres.segrdat : edpcomp_x00;

    assign edpcomp_y = edpcomp_mfsm && chnl_wpreq0.segwr && ( chnlo_rpreq.segaddr == ECCSEG_Q0Y.segaddr ) && ( chnlo_rpreq.segptr == 'h7 );

    assign chnl_wpreq.segwdat = ( edpcomp_y && opt_edpcomp ) ? { edpcomp_x00, chnl_wpreq0.segwdat[30:0]} : chnl_wpreq0.segwdat;
    assign chnl_wpreq.segwr = chnl_wpreq0.segwr;
    assign chnl_wpreq.segaddr = chnl_wpreq0.segaddr;
    assign chnl_wpreq.segrd = chnl_wpreq0.segrd;
    assign chnl_wpreq.segptr = chnl_wpreq0.segptr;
    assign chnl_wpreq.segcfg = chnl_wpreq0.segcfg;
    assign chnl_wpreq.porttype = chnl_wpreq0.porttype;

// chnl instance
// ■■■■■■■■■■■■■■■

    scedma_chnl chnli(
        .clk,
        .resetn,
        .thecfg   (chnli_cfg   ),
        .start    (chnli_start ),
        .busy     (chnli_busy  ),
        .done     (chnli_done  ),
        .rpreq    (chnl_rpreq  ),
        .rpres    (chnl_rpres  ),
        .wpreq    (chnli_wpreq ),
        .wpres    (chnli_wpres ),
        .intr     (chnli_intr  )
    );

    scedma_chnl chnlo(
        .clk,
        .resetn,
        .thecfg   (chnlo_cfg   ),
        .start    (chnlo_start ),
        .busy     (chnlo_busy  ),
        .done     (chnlo_done  ),
        .rpreq    (chnlo_rpreq ),
        .rpres    (chnlo_rpres ),
        .wpreq    (chnl_wpreq0  ),
        .wpres    (chnl_wpres  ),
        .intr     (chnlo_intr  )
    );

    scedma_chnl chnlx(
        .clk,
        .resetn,
        .thecfg   (chnlx_cfg   ),
        .start    (chnlx_start ),
        .busy     (chnlx_busy  ),
        .done     (chnlx_done  ),
        .rpreq    (chnlx_rpreq ),
        .rpres    (chnlx_rpres ),
        .wpreq    (chnlx_wpreq ),
        .wpres    (chnlx_wpres ),
        .intr     (chnlx_intr  )
    );


// ahbs ( dev mode )
// ■■■■■■■■■■■■■■■

    logic [13-3:0] ahbs_ramaddr;
    logic   [31:0] ahbs_ramwdat;
    logic          ahbs_ramrd, ahbs_ramwr, ahbs_en;
    logic    [3:0] hramwen;
    logic          hramcs;

cmsdk_ahb_to_sram #( .AW (13) )u0(
  .HCLK           (clk),
  .HRESETn        (resetn),
  .HSEL           (ahbs.hsel),
  .HREADY         (ahbs.hreadym),
  .HTRANS         (ahbs.htrans),
  .HSIZE          (ahbs.hsize),
  .HWRITE         (ahbs.hwrite),
  .HADDR          (ahbs.haddr[13-1:0]),
  .HWDATA         (ahbs.hwdata),
  .HREADYOUT      (ahbs.hready),
  .HRESP          (ahbs.hresp),
  .HRDATA         (ahbs.hrdata),
  .SRAMRDATA      (pramres.segrdat),
  .SRAMADDR       (ahbs_ramaddr),
  .SRAMWEN        (hramwen),
  .SRAMWDATA      (ahbs_ramwdat),
  .SRAMCS         (hramcs));

    assign ahbs_ramwr = ahbslock ? '0 : |hramwen;
    assign ahbs_ramrd = ahbslock ? '0 : hramcs & ~ahbs_ramwr;
    assign ahbs_en    = ahbslock ? '0 : hramcs;

// mem data path
// ■■■■■■■■■■■■■■■

    logic chnl_ramwr0l, chnl_ramwr0h, chnl_ramwr1l, chnl_ramwr1h;
    logic [63:0] pramres_segrdat64;

    assign chnli_wpreq_segptrx = chnli_ltx ? chnli_endptr - chnli_wpreq.segptr - 1 : chnli_wpreq.segptr ;
    assign chnlo_rpreq_segptrx = chnlo_ltx ? chnlo_endptr - chnlo_rpreq.segptr - 1 : chnlo_rpreq.segptr ;
    assign chnl_ramadd = chnlo_en ?  chnlo_rpreq.segaddr + chnlo_rpreq_segptrx  :
                         ahbs_en  ?  ahbs_ramaddr :
                         chnlx_en ?( chnlx_rpreq.segrd ?
                                     chnlx_rpreq.segaddr + chnlx_rpreq.segptr  :
                                     chnlx_wpreq.segaddr + chnlx_wpreq.segptr ):
                                     chnli_wpreq.segaddr + chnli_wpreq_segptrx  ; //chnli_en ?

    assign chnl_segptr = chnlo_en ?  chnlo_rpreq.segptr  :
                         chnlx_en ?( chnlx_rpreq.segrd ?
                                     chnlx_rpreq.segptr  :
                                     chnlx_wpreq.segptr ):
                                     chnli_wpreq.segptr  ; //chnli_en ?

    assign chnl_ramrd  = chnli_wpreq.segrd | chnlo_rpreq.segrd | chnlx_rpreq.segrd | chnlx_wpreq.segrd | ahbs_ramrd;
    assign chnl_ramwr  = chnli_wpreq.segwr | chnlo_rpreq.segwr | chnlx_rpreq.segwr | chnlx_wpreq.segwr | ahbs_ramwr;
    assign chnl_ramwrs = chnl_ramadd[0] ? {4'h0, {4{chnl_ramwr}}} : {{4{chnl_ramwr}}, 4'h0};

    logic mfsm_ld_con1_en, mfsm_ld_qi_z, mfsm_fill0_en;
    assign mfsm_ld_con1_en = ( mfsm == MFSM_LD_CON1 ) | chnli_dummy_con1;
    assign mfsm_fill0_en =   ( mfsm == MFSM_LD_H0 );
    assign mfsm_ld_qi_z = ( mfsm == MFSM_LD_Q0I | mfsm == MFSM_LD_Q1I ) & ( ecpsegidx > 1 );
    assign chnl_ramwdat = chnlo_en ?  chnlo_rpreq.segwdat  :
                          ahbs_en  ?  ahbs_ramwdat :
                          chnlx_en ?( chnlx_rpreq.segrd ?
                                      chnlx_rpreq.segwdat  :
                                      chnlx_wpreq.segwdat ):
                                      ( mfsm_ld_con1_en | mfsm_ld_qi_z ? ( chnli_wpreq_segptrx == 0 )|'0 :
                                       mfsm_fill0_en ? '0 :
                                            chnli_wpreq.segwdat )  ; //chnli_en ?
    assign chnli_wpres = pramres;
    assign chnlo_rpres = pramres;
    assign chnlx_rpres = pramres;
    assign chnlx_wpres = pramres;

    assign chnl_ramsel0 = ( chnl_ramadd[RAW+1] == 'h0 ) ;
    assign chnl_ramsel1 = ( chnl_ramadd[RAW+1] == 'h1 ) ;
    assign chnl_ramrd0  = chnl_ramsel0 & chnl_ramrd ;
    assign chnl_ramrd1  = chnl_ramsel1 & chnl_ramrd ;
    assign chnl_ramwr0  = chnl_ramsel0 ? chnl_ramwr : 0;
    assign chnl_ramwr1  = chnl_ramsel1 ? chnl_ramwr : 0;
    assign chnl_ramwr0l = ( chnl_ramadd[0] == 'h0 ) & chnl_ramwr0 ;
    assign chnl_ramwr0h = ( chnl_ramadd[0] == 'h1 ) & chnl_ramwr0 ;
    assign chnl_ramwr1l = ( chnl_ramadd[0] == 'h0 ) & chnl_ramwr1 ;
    assign chnl_ramwr1h = ( chnl_ramadd[0] == 'h1 ) & chnl_ramwr1 ;

    assign chnl_ramadd0 = chnl_ramadd[RAW:1];
    assign chnl_ramadd1 = chnl_ramadd[RAW:1];

    `theregrn( ramsel0reg ) <= chnl_ramsel0;
    `theregrn( chnl_ramdatselreg ) <= chnl_ramadd[0];
    assign pramres.segready = '1;  // pram always ready
    assign pramres_segrdat64  = ramsel0reg ? ramrdat0 : ramrdat1;
    assign pramres.segrdat = chnl_ramdatselreg ? pramres_segrdat64[63:32] : pramres_segrdat64[31:0] ;
    assign pramres.segrdatvld = '1;

    assign chnl_ramrdat0 = chnl_ramdatselreg ? ramrdat0[63:32] : ramrdat0[31:0] ;
    assign chnl_ramrdat1 = chnl_ramdatselreg ? ramrdat1[63:32] : ramrdat1[31:0] ;

    assign ramrd0 = pcore_en ? clkpkeen && pcore_ramrd0 : clksceen && chnl_ramrd0;
    assign ramrd1 = pcore_en ? clkpkeen && pcore_ramrd1 : chnl_ramrd1;
    assign ramwr0 = pcore_en ? {8{clkpkeen && pcore_ramwr0}} : {{4{ clksceen && chnl_ramwr0h}},{4{ clksceen && chnl_ramwr0l}}};
    assign ramwr1 = pcore_en ? {8{clkpkeen && pcore_ramwr1}} : {{4{ clksceen && chnl_ramwr1h}},{4{ clksceen && chnl_ramwr1l}}};
    assign ramadd0 = pcore_en ? pcore_ramadd0 : chnl_ramadd0;
    assign ramadd1 = pcore_en ? pcore_ramadd1 : chnl_ramadd1;
    assign ramwdat0 = pcore_en ? pcore_ramwdat0 : { chnl_ramwdat, chnl_ramwdat };
    assign ramwdat1 = pcore_en ? pcore_ramwdat1 : { chnl_ramwdat, chnl_ramwdat };

    assign pcore_ramrdat0 = ramrdat0;
    assign pcore_ramrdat1 = ramrdat1;

// mem
// ■■■■■■■■■■■■■■■

    localparam sramcfg_t thecfg = '{
        AW: RAW,
        DW: 64,
        KW: 64,
        PW: 8,
        WCNT: 2**RAW,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };

//    logic clkramen;
//    assign clkramen = pcore_en ? clkpkeen : clksceen;
    logic ramclr0;
    assign ramclr0 = ramclr | ramclrar;

    cryptoram #(
        .ramname    ("PRAM"), // HRAM, PRAM, ARAM, SCERAM
        .thecfg     (thecfg)
    )m0(
        .clk(clkram), .resetn, .cmsatpg, .cmsbist,.rbs(rbs[0]),
        .clkram(clkram), .clkramen('1),
        .ramclr(ramclr0),
        .ramclren(ramclrbusy0),
        .ramaddr (ramadd0 ),
        .ramen('1),
        .ramrd(ramrd0),
        .ramwr(ramwr0),
        .ramwdat(ramwdat0),
        .ramrdat(ramrdat0),
        .ramready(ramready0),
        .ramerror(ramerror0)
    );

    cryptoram #(
        .ramname    ("PRAM"), // HRAM, PRAM, ARAM, SCERAM
        .thecfg     (thecfg)
    )m1(
        .clk(clkram), .resetn, .cmsatpg, .cmsbist,.rbs(rbs[1]),
        .clkram(clkram), .clkramen('1),
        .ramclr(ramclr0),
        .ramclren(ramclrbusy1),
        .ramaddr (ramadd1 ),
        .ramen('1),
        .ramrd(ramrd1),
        .ramwr(ramwr1),
        .ramwdat(ramwdat1),
        .ramrdat(ramrdat1),
        .ramready(ramready1),
        .ramerror(ramerror1)
    );
    logic ramadd0_12;
    assign ramadd0_12 = ramadd0 == 'h12;
// err/intr
// ■■■■■■■■■■■■■■■

    `theregrn( intr[0] ) <= ( mfsm == MFSM_DONE );
    `theregrn( err[0] ) <= |{ ramerror0, ramerror1, parityerr };

endmodule

module dummytb_pke ();

    logic clk, resetn, cmsatpg, cmsbist;
    apbif apbs();
    chnlreq_t       chnl_rpreq, chnl_wpreq;
    chnlres_t       chnl_rpres, chnl_wpres;
    logic [0:8-1]      err;
    logic [0:8-1]      intr;
    logic busy,done,clkram,ramclr;
    ahbif ahbs();
    logic clksce, clksceen, clkpke, clkpkeen;
    rbif #(.AW(9    ),      .DW(72))    rbs  [0:1]   ();
    rbif #(.AW(8    ),      .DW(72))    rbsmimm   ();
    logic ahbslock;

    pke u1(
        .apbs(apbs),
        .apbx(apbs),
        .*
    );



endmodule

