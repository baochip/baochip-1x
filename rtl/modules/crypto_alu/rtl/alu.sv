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
import scedma_pkg::*;

module alu #(
        parameter RAW = 8+2, //## or 9??
        parameter ERRCNT = 8,
        parameter INTCNT = 8,
        parameter DW = 64
    )(

    input  logic clk, clkram, resetn, cmsatpg, cmsbist,
    rbif.slave      rbs[0:1],
    input  logic ramclr,
    input logic  mode_sec,
    apbif.slavein           apbs,
    apbif.slave             apbx,
    output bit busy,
    output bit done,
    output  chnlreq_t       chnl_rpreq, chnl_wpreq   ,
    input   chnlres_t       chnl_rpres, chnl_wpres   ,

    output logic [0:ERRCNT-1]      err,
    output logic [0:INTCNT-1]      intr
);

// localparam
// ■■■■■■■■■■■■■■■

//  cr_func

//    localparam AF_INIT    = 8'hff ;
    localparam AF_0       = 8'h0 ;
    localparam AF_DIV     = 8'h1 ;
    localparam AF_ADD     = 8'h2 ;
    localparam AF_SUB     = 8'h3 ;
    localparam AF_SFT     = 8'h10 ;
    localparam AF_SFTW    = 8'h11 ;
    localparam AF_BLG     = 8'h20 ;
    localparam AF_BEX     = 8'h30 ;

    parameter LW = 4096*4;

    localparam MFSM_IDLE      = 8'h00;
    localparam MFSM_DONE      = 8'hff;
    localparam MFSM_AF_DIV    = 8'h01;
    localparam MFSM_AF_COMM    = 8'h02;
    localparam MFSM_CLRRAM     = 8'h20;
    localparam MFSM_LD_DE     = 8'h10;
    localparam MFSM_LD_DS     = 8'h11;
    localparam MFSM_LD_A      = 8'h14;
    localparam MFSM_LD_B      = 8'h15;
    localparam MFSM_ST_RM     = 8'h12;
    localparam MFSM_ST_QT     = 8'h30;
    localparam MFSM_ST_A     = 8'h31;
    localparam MFSM_ST_B     = 8'h32;

    localparam scedma_pkg::segcfg_t DIVSEG_ALL    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h00, segsize: 'd1536, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t DIVSEG_DE     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h000, segsize: 'd512, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t DIVSEG_DS     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h200, segsize: 'd512, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t DIVSEG_QT     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h400, segsize: 'd512, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t DIVSEG_RM     = DIVSEG_DE;

    localparam scedma_pkg::segcfg_t COMSEG_A = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h000, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t COMSEG_B = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h100, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t COMSEG_M = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h200, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t COMSEG_C = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h400, segsize: 'd256, isfifo:'0, isfifostream:0, fifoid:'0 };

// opt
    logic apbrd, apbwr;
    logic pclk;
    logic sfrlock;
    logic optlock;
    logic [7:0] mfsm, mfsmnext;
    logic mfsmtog, mfsm_done, mfsmdone;
    logic div_start, div_en, comm_start, comm_en, alu_en;
    logic [7:0] cr_func;
    logic chnli_done, chnlo_done, div_done, comm_done;
    logic [15:0] cr_divlen, sr_divlen;
    logic [7:0] cr_optltx;
    logic [0:3][8+scedma_pkg::AW-1:0] cr_segcfg;
    logic [63:0] comm_ramwdat, div_ramwdat, alu_ramwdat, alu_ramrdat;
    logic chnli_en, chnlo_en;
    chnlreq_t chnlo_rpreq, chnli_wpreq;
    chnlres_t chnlo_rpres, chnli_wpres, aramres;
    chnlcfg_t chnli_cfg, chnlo_cfg;
    bit [7:0] chnlo_intr, chnli_intr;
    logic chnli_start, chnlo_start;
    logic [RAW:0] chnl_ramadd, chnl_segptr, chnli_endptr, chnlo_endptr,chnli_wpreq_segptrx,chnlo_rpreq_segptrx;
    logic  chnl_ramrd, chnl_ramwr;
    dat_t  chnl_ramwdat;
    logic [63:0] ramwdat, ramrdat;
    logic [7:0] chnl_ramwrs, ramwr;
    logic [RAW-1:0]  ramadd, div_ramadd, comm_ramadd, alu_ramadd;
    logic ramrd, div_ramrd, div_ramwr, comm_ramrd, comm_ramwr, alu_ramrd, alu_ramwr;
    logic [1:0] ramready;
    bit chnl_segptrreg;
    logic start;
    logic [1:0] ramclrbusy;
    logic [7:0] dscnt,decnt;
    logic [7:0] rmcnt,qtcnt;
    logic chnli_busy, chnlo_busy;
    logic [1:0][1:0] ramerror;
    logic qs0err,crreg;
    logic chnli_ltx, chnlo_ltx;
    logic chnli_clr;
    chnlreq_t chnl_rpreq0, chnl_wpreq0;
    chnlres_t chnl_rpres0, chnl_wpres0, chnlres_null;
    logic [31:0] cr_opt32;
    logic aluinvld, aluvld;

// apb
// ■■■■■■■■■■■■■■■

    assign pclk = clk;

    `theregrn( sfrlock ) <= optlock ? 1'b1 : mfsm_done ? '0 : sfrlock;

    `apbs_common;
    assign apbx.prdata = '0
                        | sfr_crfunc.prdata32 | sfr_srmfsm.prdata32 | sfr_fr.prdata32
                        | sfr_crdivlen.prdata32 | sfr_srdivlen.prdata32 | sfr_optltx.prdata32 | sfr_segptr.prdata32
                        | sfr_opt.prdata32
                        ;

    apb_cr #(.A('h00), .DW(8))      sfr_crfunc      (.cr(cr_func), .prdata32(),.*);
    apb_ar #(.A('h04), .AR(32'h5a)) sfr_ar          (.ar(start),.*);
    apb_sr #(.A('h08), .DW(9))      sfr_srmfsm      (.sr({crreg,mfsm}), .prdata32(),.*);
    apb_fr #(.A('h0c), .DW(6))      sfr_fr          (.fr({aluinvld, qs0err, chnli_done, chnlo_done, div_done, mfsm_done}), .prdata32(),.*);

    apb_cr #(.A('h10), .DW(16))      sfr_crdivlen   (.cr(cr_divlen), .prdata32(),.*);
    apb_sr #(.A('h14), .DW(16))      sfr_srdivlen   (.sr(sr_divlen), .prdata32(),.*);
    apb_cr #(.A('h18), .DW(32))      sfr_opt        (.cr(cr_opt32), .prdata32(),.*);
    apb_cr #(.A('h1C), .DW(8))       sfr_optltx     (.cr(cr_optltx), .prdata32(),.*);

    apb_cr #(.A('h30), .DW(8+scedma_pkg::AW), .SFRCNT(4) )      sfr_segptr    (.cr(cr_segcfg), .prdata32(),.*); //## width?

    assign optlock = ( start & ( mfsm == MFSM_IDLE));

    assign busy = (|mfsm) | (|ramclrbusy);
    assign done = mfsm_done;

// mfsm
// ■■■■■■■■■■■■■■■
    `theregfull(clk, resetn, mfsm, MFSM_IDLE ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone ? mfsmnext : mfsm;
    `theregrn( mfsmtog ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone;
    assign mfsm_done = ( mfsm == MFSM_DONE );

    always_comb begin
        mfsmnext = mfsm;
        mfsmdone = '0;
        case (cr_func)
            AF_DIV:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_CLRRAM;
                    MFSM_CLRRAM : begin
                                                mfsmnext = MFSM_LD_DE;        mfsmdone = chnli_done;
                        end
                    MFSM_LD_DE : begin
                                                mfsmnext = MFSM_LD_DS;        mfsmdone = chnli_done;
                        end
                    MFSM_LD_DS : begin
                                                mfsmnext = MFSM_AF_DIV;       mfsmdone = chnli_done;
                        end
                    MFSM_AF_DIV : begin
                                                mfsmnext = MFSM_ST_RM;        mfsmdone = div_done;
                        end
                    MFSM_ST_RM : begin
                                                mfsmnext = MFSM_ST_QT;        mfsmdone = chnlo_done;
                        end
                    MFSM_ST_QT : begin
                                                mfsmnext = MFSM_DONE;         mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;         mfsmdone = 'h1;
                        end
                endcase
            AF_ADD, AF_SUB, AF_BLG:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_CLRRAM;
                    MFSM_CLRRAM : begin
                                                mfsmnext = MFSM_LD_A;         mfsmdone = chnli_done;
                        end
                    MFSM_LD_A : begin
                                                mfsmnext = MFSM_LD_B;         mfsmdone = chnli_done;
                        end
                    MFSM_LD_B : begin
                                                mfsmnext = MFSM_AF_COMM;      mfsmdone = chnli_done;
                        end
                    MFSM_AF_COMM : begin
                                                mfsmnext = MFSM_ST_A;         mfsmdone = comm_done;
                        end
                    MFSM_ST_A : begin
                                                mfsmnext = MFSM_DONE;         mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;         mfsmdone = 'h1;
                        end
                endcase
            AF_SFT, AF_SFTW:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_CLRRAM;
                    MFSM_CLRRAM : begin
                                                mfsmnext = MFSM_LD_A;         mfsmdone = chnli_done;
                        end
                    MFSM_LD_A : begin
                                                mfsmnext = MFSM_AF_COMM;      mfsmdone = chnli_done;
                        end
                    MFSM_AF_COMM : begin
                                                mfsmnext = MFSM_ST_A;         mfsmdone = comm_done;
                        end
                    MFSM_ST_A : begin
                                                mfsmnext = MFSM_DONE;         mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;         mfsmdone = 'h1;
                        end
                endcase
            AF_BEX:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_CLRRAM;
                    MFSM_CLRRAM : begin
                                                mfsmnext = MFSM_LD_A;         mfsmdone = chnli_done;
                        end
                    MFSM_LD_A : begin
                                                mfsmnext = MFSM_AF_COMM;      mfsmdone = chnli_done;
                        end
                    MFSM_AF_COMM : begin
                                                mfsmnext = MFSM_ST_B;         mfsmdone = comm_done;
                        end
                    MFSM_ST_B : begin
                                                mfsmnext = MFSM_DONE;         mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;         mfsmdone = 'h1;
                        end
                endcase
            default :
                begin
                    mfsmnext = mfsm;
                    mfsmdone = '1;
                end
        endcase
    end

// subcore, chnl
// ■■■■■■■■■■■■■■■

    `theregrn( div_start ) <= mfsmtog & ( mfsm == MFSM_AF_DIV  );
    `theregrn( comm_start ) <= mfsmtog & ( mfsm == MFSM_AF_COMM  );

    assign alu_en = div_en | comm_en;
    assign div_en = ( mfsm == MFSM_AF_DIV );
    assign comm_en = ( mfsm == MFSM_AF_COMM );

	aludiv #(.LW(LW))div(
		.clk       ( clk       ),
		.resetn    ( resetn    ),
		.start     ( div_start     ),
		.busy      (       ),
		.done      ( div_done      ),
		.delen     ( {1'b0,cr_divlen[7:0],6'h0}     ),
		.dslen     ( {1'b0,cr_divlen[15:8],6'h0}    ),
		.ramaddr   ( div_ramadd   ),
		.ramrd     ( div_ramrd     ),
		.ramwr     ( div_ramwr     ),
		.ramwdat   ( div_ramwdat   ),
		.ramrdat   ( alu_ramrdat   ),
        .qtlen(),
        .rmlen(),
		.qtcnt    (sr_divlen[7:0]),
		.rmcnt    (sr_divlen[15:8]),
        .qs0err  (qs0err)

	);

    alucomm #(.LW(4096),.RAW(RAW))comm(
        .clk       ( clk       ),
        .resetn    ( resetn    ),
        .func      (cr_func),
        .opt       (cr_opt32),
        .start     ( comm_start     ),
        .busy      (       ),
        .done      ( comm_done      ),
        .alen      ( {cr_divlen[6:0],6'h0}     ),
        .ramaddr   ( comm_ramadd   ),
        .ramrd     ( comm_ramrd     ),
        .ramwr     ( comm_ramwr     ),
        .ramwdat   ( comm_ramwdat   ),
        .ramrdat   ( alu_ramrdat   ),
        .crreg
    );

    assign alu_ramadd  = div_en ? div_ramadd  : comm_ramadd  ;
    assign alu_ramrd   = div_en ? div_ramrd   : comm_ramrd   ;
    assign alu_ramwr   = div_en ? div_ramwr   : comm_ramwr   ;
    assign alu_ramwdat = div_en ? div_ramwdat : comm_ramwdat ;

    assign {dscnt,decnt} = cr_divlen;
    assign {rmcnt,qtcnt} = sr_divlen;

// chnl behavior
// ■■■■■■■■■■■■■■■

    `theregrn( chnli_start ) <= mfsmtog & chnli_en;
    `theregrn( chnlo_start ) <= mfsmtog & chnlo_en;

    localparam PTRID_DE = 0;
    localparam PTRID_DS = 1;
    localparam PTRID_QT = 2;
    localparam PTRID_RM = 3;

    scedma_pkg::adr_t ds_DIVSEG_DS_segaddr;
    assign ds_DIVSEG_DS_segaddr = 'h200+(decnt-dscnt)*2;

    scedma_pkg::segcfg_t ds_DIVSEG_DS;
    assign  ds_DIVSEG_DS    = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: ds_DIVSEG_DS_segaddr, segsize: 'd512, isfifo:'0, isfifostream:0, fifoid:'0 };

    always_comb begin
        chnli_en = '0;
        chnli_cfg.opt_ltx = '0;
        chnli_endptr = 0;
        chnli_cfg.wpptr_start = '0;
        chnli_ltx = '0;//cr_optltx[PTRID_DE];
        chnli_clr = '0;
        case(mfsm)
            MFSM_CLRRAM      :
                begin
                    chnli_clr = '1;
                    chnli_cfg.wpsegcfg =    DIVSEG_ALL;
                    chnli_cfg.rpsegcfg =    scedma_pkg::SEGCFGS[0];
                    chnli_cfg.rpptr_start = '0;
//                    chnli_cfg.opt_ltx =     cr_optltx[PTRID_DE];
                    chnli_cfg.transsize =   1536*2;
                    chnli_endptr = '0;
                    chnli_ltx = '0;
                    chnli_en = '1;
                end
            MFSM_LD_DE,MFSM_LD_A      :
                begin
                    chnli_cfg.wpsegcfg =    DIVSEG_DE;
                    chnli_cfg.rpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_DE][15:12]];
                    chnli_cfg.rpptr_start = cr_segcfg[PTRID_DE][(scedma_pkg::AW-1):0];
                    chnli_cfg.opt_ltx =     cr_optltx[PTRID_DE+4];
                    chnli_cfg.transsize =   decnt*2;
                    chnli_endptr = decnt*2;
                    chnli_ltx = cr_optltx[PTRID_DE];
                    chnli_en = '1;
                end
            MFSM_LD_B      :
                begin
                    chnli_cfg.wpsegcfg =    COMSEG_B;
                    chnli_cfg.rpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_DS][15:12]];
                    chnli_cfg.rpptr_start = cr_segcfg[PTRID_DS][(scedma_pkg::AW-1):0];
                    chnli_cfg.opt_ltx =     cr_optltx[PTRID_DS+4];
                    chnli_cfg.transsize =   decnt*2;
                    chnli_endptr = decnt*2;
                    chnli_ltx = cr_optltx[PTRID_DS];
                    chnli_en = '1;
                end
            MFSM_LD_DS     :
                begin
                    chnli_cfg.wpsegcfg =    ds_DIVSEG_DS;//DIVSEG_DS;
                    chnli_cfg.rpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_DS][15:12]];
                    chnli_cfg.rpptr_start = cr_segcfg[PTRID_DS][(scedma_pkg::AW-1):0];
                    chnli_cfg.opt_ltx =     cr_optltx[PTRID_DS+4];
                    chnli_cfg.transsize =   dscnt*2;
                    chnli_en = '1;
                    chnli_cfg.wpptr_start = 0;//(decnt-dscnt)*2;
                    chnli_ltx = cr_optltx[PTRID_DS];
                    chnli_endptr = dscnt*2;
                end
            default : /* default */
                begin
                    chnli_cfg.wpsegcfg =    DIVSEG_DE;
                    chnli_cfg.rpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_DE][15:12]];
                    chnli_cfg.rpptr_start = cr_segcfg[PTRID_DE][(scedma_pkg::AW-1):0];
//                    chnli_cfg.opt_ltx =     cr_optltx[PTRID_DE];
                    chnli_cfg.transsize =   decnt*2;
                    chnli_en = '0;
                end
        endcase
    end

//    assign chnli_cfg.opt_ltx = chnli_ltx;//'0;
    assign chnli_cfg.chnlid = '0;
    assign chnli_cfg.opt_xor = '0;
    assign chnli_cfg.opt_cmpp = '0;
    assign chnli_cfg.opt_prm = '0;
    assign chnli_cfg.wpffen = '0;

    always_comb begin
        chnlo_en = '0;
        chnlo_cfg.rpsegcfg =    DIVSEG_RM;
        chnlo_cfg.wpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_RM][15:12]];
        chnlo_cfg.wpptr_start = cr_segcfg[PTRID_RM][(scedma_pkg::AW-1):0];
        chnlo_cfg.opt_ltx =     cr_optltx[PTRID_RM+4];
        chnlo_cfg.transsize =   rmcnt*2;
        chnlo_ltx = '0;//cr_optltx[PTRID_RM];
        chnlo_endptr = chnlo_cfg.transsize;
        case(mfsm)
            MFSM_ST_QT:
                begin
                    chnlo_en = '1;
                    chnlo_cfg.rpsegcfg =    DIVSEG_QT;
                    chnlo_cfg.wpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_QT][15:12]];
                    chnlo_cfg.wpptr_start = cr_segcfg[PTRID_QT][(scedma_pkg::AW-1):0];
                    chnlo_cfg.opt_ltx =     cr_optltx[PTRID_QT+4];
                    chnlo_ltx = cr_optltx[PTRID_QT];
                    chnlo_cfg.transsize =   decnt*2;
                    chnlo_endptr = chnlo_cfg.transsize;
                end
            MFSM_ST_A:
                begin
                    chnlo_en = '1;
                    chnlo_cfg.rpsegcfg =    COMSEG_A;
                    chnlo_cfg.wpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_QT][15:12]];
                    chnlo_cfg.wpptr_start = cr_segcfg[PTRID_QT][(scedma_pkg::AW-1):0];
                    chnlo_cfg.opt_ltx =     cr_optltx[PTRID_QT+4];
                    chnlo_ltx = cr_optltx[PTRID_QT];
                    chnlo_cfg.transsize =   decnt*2;
                    chnlo_endptr = chnlo_cfg.transsize;
                end
            MFSM_ST_B:
                begin
                    chnlo_en = '1;
                    chnlo_cfg.rpsegcfg =    COMSEG_B;
                    chnlo_cfg.wpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_RM][15:12]];
                    chnlo_cfg.wpptr_start = cr_segcfg[PTRID_RM][(scedma_pkg::AW-1):0];
                    chnlo_cfg.opt_ltx =     cr_optltx[PTRID_RM+4];
                    chnlo_ltx = cr_optltx[PTRID_RM];
                    chnlo_cfg.transsize =   dscnt*2;
                    chnlo_endptr = chnlo_cfg.transsize;
                end
            MFSM_ST_RM:
                begin
                    chnlo_en = '1;
                    chnlo_cfg.rpsegcfg =    DIVSEG_RM;
                    chnlo_cfg.wpsegcfg =    scedma_pkg::SEGCFGS[cr_segcfg[PTRID_RM][15:12]];
                    chnlo_cfg.wpptr_start = cr_segcfg[PTRID_RM][(scedma_pkg::AW-1):0];
                    chnlo_cfg.opt_ltx =     cr_optltx[PTRID_RM+4];
                    chnlo_ltx = cr_optltx[PTRID_RM];
                    chnlo_cfg.transsize =   dscnt*2;
                    chnlo_endptr = chnlo_cfg.transsize;
                end
            default : /* default */
                begin
                    chnlo_en = '0;
                end
        endcase
    end
//    assign chnlo_cfg.opt_ltx = chnlo_ltx;//'0;
    assign chnlo_cfg.chnlid = '0;
    assign chnlo_cfg.rpptr_start = '0;
    assign chnlo_cfg.opt_xor = '0;
    assign chnlo_cfg.opt_cmpp = '0;
    assign chnlo_cfg.opt_prm = '0;
    assign chnlo_cfg.wpffen = '0;

// chnl instance
// ■■■■■■■■■■■■■■■

    scedma_chnl chnli(
        .clk,
        .resetn,
        .thecfg   (chnli_cfg   ),
        .start    (chnli_start ),
        .busy     (chnli_busy  ),
        .done     (chnli_done  ),
        .rpreq    (chnl_rpreq0 ),
        .rpres    (chnl_rpres0 ),
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
        .wpres    (chnl_wpres0  ),
        .intr     (chnlo_intr  )
    );

// mem data path
// ■■■■■■■■■■■■■■■

    `theregrn( aluinvld ) <= mode_sec & (
            ( scedma_pkg::SEGCFGS[cr_segcfg[0][15:12]].segtype == scedma_pkg::ST_KI )|
            ( scedma_pkg::SEGCFGS[cr_segcfg[1][15:12]].segtype == scedma_pkg::ST_KI )|
            ( scedma_pkg::SEGCFGS[cr_segcfg[2][15:12]].segtype == scedma_pkg::ST_KI )|
            ( scedma_pkg::SEGCFGS[cr_segcfg[3][15:12]].segtype == scedma_pkg::ST_KI ));
    assign aluvld = ~aluinvld;

    assign chnl_wpreq = aluvld ? chnl_wpreq0 : '0;
    assign chnl_wpres0 = aluvld ? chnl_wpres : chnlres_null;

    assign chnl_rpreq = chnli_clr | ~aluvld ? '0 : chnl_rpreq0;
    assign chnl_rpres0 = chnli_clr | ~aluvld ? chnlres_null: chnl_rpres;

    assign chnlres_null.segrdatvld = '1;
    assign chnlres_null.segready = '1;
    assign chnlres_null.segrdat = '0;

    `theregrn( chnl_segptrreg ) <= chnl_segptr;

    assign chnli_wpreq_segptrx = chnli_ltx ? chnli_endptr - chnli_wpreq.segptr - 1 : chnli_wpreq.segptr ;
    assign chnlo_rpreq_segptrx = chnlo_ltx ? chnlo_endptr - chnlo_rpreq.segptr - 1 : chnlo_rpreq.segptr ;

    assign chnl_ramadd = chnlo_en ?  chnlo_rpreq.segaddr + chnlo_rpreq_segptrx  :
                                     chnli_wpreq.segaddr + chnli_wpreq_segptrx  ; //chnli_en ?

    assign chnl_segptr = chnlo_en ?  chnlo_rpreq.segptr  :
                                     chnli_wpreq.segptr  ; //chnli_en ?

    assign chnl_ramrd  = chnli_wpreq.segrd | chnlo_rpreq.segrd;
    assign chnl_ramwr  = chnli_wpreq.segwr | chnlo_rpreq.segwr;
    assign chnl_ramwrs =  chnl_segptr[0] ? {4'h0,{4{chnl_ramwr}}}:{{4{chnl_ramwr}},4'h0};

    assign chnl_ramwdat = chnlo_en ?  chnlo_rpreq.segwdat  :
                                      chnli_wpreq.segwdat  ; //chnli_en ?

    assign ramrd = alu_en ? alu_ramrd : chnl_ramrd;
    assign ramwr = alu_en ? {8{alu_ramwr}} : chnl_ramwrs;
    assign ramadd = alu_en ? alu_ramadd : chnl_ramadd/2;
    assign ramwdat = alu_en ? alu_ramwdat : { chnl_ramwdat, chnl_ramwdat };

    assign chnli_wpres = aramres;
    assign chnlo_rpres.segready = aramres.segready;
    assign chnlo_rpres.segrdatvld = aramres.segrdatvld;
    assign chnlo_rpres.segrdat = aramres.segrdat ;

    assign alu_ramrdat = ramrdat;
    assign aramres.segready = '1;  // pram always ready
    assign aramres.segrdat  = chnl_segptrreg ^ (chnli_ltx|chnlo_ltx) ? ramrdat[63:32] : ramrdat[31:0] ;
    assign aramres.segrdatvld = '1;



// mem
// ■■■■■■■■■■■■■■■

    localparam sramcfg_t thecfg = '{
        AW: RAW,
        DW: 64/2,
        KW: 64/2,
        PW: 8/2,
        WCNT: 256*3,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };

    cryptoram #(
        .ramname    ("ALURAM"), // HRAM, PRAM, ARAM, SCERAM
        .thecfg     (thecfg)
    )m0(
        .clk(clkram), .resetn, .cmsatpg, .cmsbist,.rbs(rbs[0]),
        .clkram(clkram), .clkramen('1),
        .ramaddr (ramadd[RAW-1:0] ),
        .ramclr(ramclr),
        .ramclren(ramclrbusy[0]),
        .ramen('1),
        .ramrd(ramrd),
        .ramwr(ramwr[3:0]),
        .ramwdat(ramwdat[31:0]),
        .ramrdat(ramrdat[31:0]),
        .ramready(ramready[0]),
        .ramerror(ramerror[0])
    );

    cryptoram #(
        .ramname    ("ALURAM"), // HRAM, PRAM, ARAM, SCERAM
        .thecfg     (thecfg)
    )m1(
        .clk(clkram), .resetn, .cmsatpg, .cmsbist,.rbs(rbs[1]),
        .clkram(clkram), .clkramen('1),
        .ramaddr (ramadd[RAW-1:0] ),
        .ramclr(ramclr),
        .ramclren(ramclrbusy[1]),
        .ramen('1),
        .ramrd(ramrd),
        .ramwr(ramwr[7:4]),
        .ramwdat(ramwdat[63:32]),
        .ramrdat(ramrdat[63:32]),
        .ramready(ramready[1]),
        .ramerror(ramerror[1])
    );

// err/intr
// ■■■■■■■■■■■■■■■

    `theregrn( intr[0] ) <= ( mfsm == MFSM_DONE );
    `theregrn( err[0:1] ) <= ramerror[1]|ramerror[0];

endmodule
