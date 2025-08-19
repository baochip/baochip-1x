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
//`include "ram_interface_def_v0.3.sv"

import scedma_pkg::*;

module scedma_chnl #(
	parameter TCW = scedma_pkg::TRANSCNTW, // trans size width
	parameter DW = 32
)(
	input	bit				clk,
	input	bit				resetn,

	input   chnlcfg_t       thecfg,
    input   bit             start,
    output  bit             busy,
    output  bit             done,

//  read/write port

    output chnlreq_t       rpreq,
    input  chnlres_t       rpres,
    output chnlreq_t       wpreq,
    input  chnlres_t       wpres,

    output  bit [7:0]       intr
);

//  read port

    adr_t           rpseg;
    adr_t           rpptr;
    bit [DW-1:0]    rprdat;
    bit             rprd;
    bit             rpwr;
    bit [DW-1:0]    rpwdat;
    bit             rpready;

//  write port

    adr_t           wpseg;
    adr_t           wpptr;
    bit [DW-1:0]    wprdat;
    bit             wprd;
    bit             wpwr;
    bit [DW-1:0]    wpwdat;
    bit             wpready;

    bit rprdatready, rprdvld, rprdpl1, rprdpl2, rprdpl1vld;
    bit wprdatready, wprdvld, wprdpl1, wprdpl2, wprdpl1vld;

    assign rpreq.segcfg   = thecfg.rpsegcfg;
    assign wpreq.segcfg   = thecfg.wpsegcfg;

    assign rpreq.segaddr  = rpseg       ;
    assign rpreq.segptr   = rpptr       ;
    assign rpreq.segrd    = rprd        ;
    assign rpreq.segwr    = rpwr        ;
    assign rpreq.segwdat  = rpwdat      ;
    assign rprdat      = rpres.segrdat  ;
    assign rpready     = rpres.segready ;
    assign rprdatready = rpres.segrdatvld;//1;

    assign wpreq.segaddr  = wpseg       ;
    assign wpreq.segptr   = wpptr       ;
    assign wpreq.segrd    = wprd        ;
    assign wpreq.segwr    = wpwr        ;
    assign wpreq.segwdat  = wpwdat      ;
    assign wprdat      = wpres.segrdat  ;
    assign wpready     = wpres.segready ;
    assign wprdatready = wpres.segrdatvld;//1;

    segcfg_t therpsegcfg, thewpsegcfg;
    logic theopt_xor;

    assign therpsegcfg = thecfg.rpsegcfg;
    assign thewpsegcfg = thecfg.wpsegcfg;
    assign theopt_xor =  thecfg.opt_xor & ~( thecfg.wpffen & thewpsegcfg.isfifo );

    assign rpreq.porttype = PT_RO;
    assign wpreq.porttype = theopt_xor ? PT_RW : PT_WO;

//##thecfg.opt_cmpp
//##thecfg.opt_prm
    bit [TCW-1:0] transcnt;
    bit lasttrans,  transdone, transstart, chnlstart, wpwrvld;

    `theregrn( busy ) <=   start ? 1 : busy & done ? 0 : busy;

    assign chnlstart = start & ~busy;

    assign done = lasttrans & transdone;

    `theregrn( transcnt ) <= chnlstart ? 0 : transdone ? ( lasttrans ? 0 : transcnt + 1 ) : transcnt;

    assign lasttrans = ( transcnt == thecfg.transsize - 1 );

    assign transdone = busy & wpready & wpwrvld;

    assign transstart = ~busy ? start : ~lasttrans & transdone;

    assign wpwrvld = wpwr;

// addr

    assign rpseg = therpsegcfg.segaddr;
    assign wpseg = thewpsegcfg.segaddr;

    `theregrn( rpptr ) <= ( rpptr > therpsegcfg.segsize ) ? 0 :
                          chnlstart ? thecfg.rpptr_start :
                          transdone ? (( rpptr == therpsegcfg.segsize - 1 ) ? 0 : rpptr + 1 ) : rpptr;

    `theregrn( wpptr ) <= ( wpptr > thewpsegcfg.segsize ) ? 0 :
                          chnlstart ? thecfg.wpptr_start :
                          transdone ? (( wpptr == thewpsegcfg.segsize - 1 ) ? 0 : wpptr + 1 ) : wpptr;
// read port

    //assign rprdatready = 1;

    `theregrn( rprdvld ) <= transstart ? 1'b1 : rprdvld & rpready ? 1'b0 : rprdvld;
    `theregrn( rprdpl1 ) <= rprdvld & rpready ? 1'b1 : rprdpl1vld ? 1'b0 : rprdpl1;
    `theregrn( rprdpl2 ) <= transdone ? 1'b0 : rprdpl1vld ? 1'b1 : rprdpl2;

    assign rprdpl1vld = rprdpl1 & rprdatready ;
    assign rprd = rprdvld;

    // only for xor
    //assign wprdatready = 1;

    `theregrn( wprdvld ) <= theopt_xor & ( transstart ? 1'b1 : wprdvld & wpready ? 1'b0 : wprdvld );
    `theregrn( wprdpl1 ) <= theopt_xor & ( wprdvld & wpready ? 1'b1 : wprdpl1vld ? 1'b0 : wprdpl1 );
    `theregrn( wprdpl2 ) <= theopt_xor & ( transdone ? 1'b0 : wprdpl1vld ? 1'b1 : wprdpl2 );

    assign wprdpl1vld = wprdpl1 & wprdatready ;
    assign wprd = wprdvld;

// datreg

    dat_t thedatreg, thedatxor00, thedatxor10, thedatxor01, thedatxor11;
    dat_t thedatxor, thedat0, wpwdatx;
    bit wpwrxor, wpwr0;
    dat_t rprdatx, rpwdatx, wprdatx;

    `theregrn( thedatreg ) <=
            theopt_xor ? (
                ( transstart | transdone ) ? '0 :
                ( rprdpl1vld & wprdpl1vld ) ? thedatxor00 :
                ( rprdpl1vld )              ? thedatxor01 :
                ( wprdpl1vld )              ? thedatxor10 :
//                ( rprdpl2    & wprdpl1vld    ) ? thedatxor10 :
//                ( rprdpl1vld & wprdpl2       ) ? thedatxor01 :
                                              thedatxor11
            ):(
                rprdpl1vld ? rprdatx : thedatreg );

    assign thedatxor00 =   rprdatx ^ wprdatx ;
    assign thedatxor10 = thedatreg ^ wprdatx ;
    assign thedatxor01 =   rprdatx ^ thedatreg ;
    assign thedatxor11 =             thedatreg ;

    assign thedatxor =
//                ( rprdpl1vld & wprdpl1vld    ) ? thedatxor00 :
//                ( rprdpl2    & wprdpl1vld    ) ? thedatxor10 :
//                ( rprdpl1vld & wprdpl2       ) ? thedatxor01 :
//                                                 thedatxor11 ;
                ( rprdpl1vld & wprdpl1vld ) ? thedatxor00 :
                ( rprdpl1vld )              ? thedatxor01 :
                ( wprdpl1vld )              ? thedatxor10 :
//                ( rprdpl2    & wprdpl1vld    ) ? thedatxor10 :
//                ( rprdpl1vld & wprdpl2       ) ? thedatxor01 :
                                              thedatxor11;

    assign thedat0 = rprdpl1vld ? rprdatx : thedatreg;

    // axi style, wpwr has no comb path with ready
    // if rprdatready / wprdatready are not tie high. the *rprdpl1vld should be remove, but the wr req will be late after *vld.
    assign wpwrxor = ( rprdpl1vld | rprdpl2 ) &  ( wprdpl1vld | wprdpl2 ) ;
    assign wpwr0 =   ( rprdpl1vld | rprdpl2 ) ;


    assign wpwr = theopt_xor ? wpwrxor : wpwr0;
    assign wpwdatx = theopt_xor ? thedatxor : thedat0;

    assign rprdatx = thecfg.opt_ltx[0] ? { rprdat[7:0] , rprdat[15:8] , rprdat[23:16] , rprdat[31:24] } : rprdat;
    assign wpwdat  = thecfg.opt_ltx[1] ? { wpwdatx[7:0], wpwdatx[15:8], wpwdatx[23:16], wpwdatx[31:24]} : wpwdatx;
    assign wprdatx = thecfg.opt_ltx[2] ? { wprdat[7:0] , wprdat[15:8] , wprdat[23:16] , wprdat[31:24] } : wprdat;
    assign rpwdat  = thecfg.opt_ltx[3] ? { rpwdatx[7:0], rpwdatx[15:8], rpwdatx[23:16], rpwdatx[31:24]} : rpwdatx;

    assign rpwdatx = '0;
    assign rpwr = '0;

// interrupt pulse

    assign intr[0] = '0;
    assign intr[7:1] = '0;

endmodule : scedma_chnl

module scedma_chnlbi #(
    parameter TCW = scedma_pkg::TRANSCNTW, // trans size width
    parameter DW = 32
)(
    input   bit             clk,
    input   bit             resetn,

    input   bit             e2w, // dir,  1:east2west
    input   chnlcfg_t       thecfg,
    input   bit             start,
    output  bit             busy,
    output  bit             done,

//  east/west port

    output chnlreq_t       eastreq,
    input  chnlres_t       eastres,
    output chnlreq_t       westreq,
    input  chnlres_t       westres,

    output  bit [7:0]       intr
);

    chnlreq_t chnli_rpreq, chnli_wpreq;
    chnlreq_t chnlo_rpreq, chnlo_wpreq;

    bit chnli_busy, chnli_done;
    bit chnlo_busy, chnlo_done;
    bit [7:0] chnli_intr, chnlo_intr;

    scedma_chnl  #(.TCW(TCW),.DW(DW))chnli(
        .clk,
        .resetn,
        .thecfg   (thecfg),
        .start    (start&e2w),
        .busy     (chnli_busy),
        .done     (chnli_done),
        .rpreq    (chnli_rpreq ),
        .rpres    (eastres ),
        .wpreq    (chnli_wpreq ),
        .wpres    (westres ),
        .intr     (chnli_intr     )
    );

    scedma_chnl  #(.TCW(TCW),.DW(DW))chnlo(
        .clk,
        .resetn,
        .thecfg   (thecfg),
        .start    (start&~e2w),
        .busy     (chnlo_busy),
        .done     (chnlo_done),
        .rpreq    (chnlo_rpreq ),
        .rpres    (westres ),
        .wpreq    (chnlo_wpreq ),
        .wpres    (eastres ),
        .intr     (chnlo_intr     )
    );

    assign busy = chnli_busy | chnlo_busy;
    assign done = chnli_done | chnlo_done;
    assign intr = chnli_intr | chnlo_intr;

    assign eastreq = e2w ? chnli_rpreq : chnlo_wpreq;
    assign westreq = e2w ? chnli_wpreq : chnlo_rpreq;

endmodule




module scedma_simplefifo #(
//    parameter TCW = scedma_pkg::TRANSCNTW, // trans size width
    parameter ALMF = 2,
    parameter ALME = 2
//    parameter bit OPT_STREAMING = 1'b0
)(
    input   bit             clk,
    input   bit             resetn,

    input   segcfg_t        thecfg,

    input   bit             ffen,
    input   bit             ffclr,
    output  adr_t           ffcnt,

//  write port | fifo in

    input   bit             fi_wr,      // fifo in write
    output  bit             fi_full,    // fifo in full
    output  bit             fi_almf,    // fifo in almost full

//  read port | fifo out

    input   bit             fo_rd,     // fifo out read, should be pulse
    output  bit             fo_empt,   // fifo out empty
    output  bit             fo_alme,   // fifo out almost empty

//  ram  port

//    output  bit [RAW-1:0]   ramseg,
    output  adr_t           ramptr,

    output  bit [7:0]       intr

);

//    OPT_STREAMING
    adr_t    fi_ptr, fo_ptr, fi_ptrnext, fo_ptrnext;
//    bit [AW:0]      ffcnt;
//    bit             fi_full, fo_empt, fi_almf, fo_alme;
    bit             fi_inc, fo_inc, fi_incforce, fo_incforce, fi_vld, fo_vld;

    `theregrn( fi_ptr ) <= ffclr ? 0 : fi_inc | fi_incforce ? fi_ptrnext : fi_ptr;
    `theregrn( fo_ptr ) <= ffclr ? 0 : fo_inc | fo_incforce ? fo_ptrnext : fo_ptr;

    `theregrn( ffcnt ) <= ffclr ? 0 :
                                     fi_incforce ?      ffcnt :
                                     fi_inc &  fo_inc ? ffcnt :
                                     fi_inc & ~fo_inc ? ffcnt + 1 :
                                    ~fi_inc &  fo_inc ? ffcnt - 1 : ffcnt;

    assign fi_full = ( ffcnt == thecfg.segsize ) & ~thecfg.isfifostream;
    assign fo_empt = ( ffcnt == 0 );
    assign fi_almf = ( ffcnt == thecfg.segsize - ALMF );
    assign fo_alme = ( ffcnt == ALME );

    assign fi_inc = ffen & fi_wr & fi_vld;
    assign fo_inc = ffen & fo_rd & fo_vld;
    assign fi_incforce = thecfg.isfifostream & ffen & fi_wr & ~fi_vld & ~fo_inc;
    assign fo_incforce = fi_incforce;

    assign fi_vld = ~fi_full;
    assign fo_vld = ~fo_empt;

    assign fi_ptrnext = ( fi_ptr == thecfg.segsize - 1 ) ? 0 : fi_ptr + 1;
    assign fo_ptrnext = ( fo_ptr == thecfg.segsize - 1 ) ? 0 : fo_ptr + 1;

    assign ramptr = fi_inc ? fi_ptr : fo_ptr;

// interrupt pulse

    assign intr = '0;

endmodule;

