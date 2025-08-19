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

import hash_pkg::*;
import scedma_pkg::*;

module combohash #(
        parameter [31:0] PM_KS_BA = 32'h60008000,
        parameter SEGCNT = 7,
        parameter ERRCNT = 8,
        parameter INTCNT = 8
    )(

    input  logic clk, clkram, resetn, cmsatpg, cmsbist,
    rbif.slave   rbs   ,
    input  logic ramclr,
//    input   bit             start,
//    output  bit             busy,
//    output  bit             done,
//    input hashfunc_e        cr_func,
//    input hashfuncopt_t     cr_opt,
//    input scedma_pkg::adr_t [0:SEGCNT-1]   cr_segptrstart,
    apbif.slavein           apbs,
    apbif.slave             apbx,

    output  chnlreq_t       chnl_rpreq, chnl_wpreq   ,
    input   chnlres_t       chnl_rpres, chnl_wpres   ,

    output   bit            schcrxsel, schstartx,
    input    bit            schdonex,
    output   chcr_t         schcrx,
    input    chnlreq_t       schxrpreq,
    output   chnlres_t       schxrpres,
    input    chnlreq_t       schxwpreq,
    output   chnlres_t       schxwpres,

    output logic        hmac_pass, hmac_fail,
    output logic [9:0]  hmac_kid,

    output logic busy,done,
    output logic [0:ERRCNT-1]      err,
    output logic [0:INTCNT-1]      intr
);

    localparam INITSIZE = hash_pkg::RAMSEG_CHACHA20_H;

    localparam [7:0] SEGID_LKEY = scedma_pkg::SEGID_LKEY ;
    localparam [7:0] SEGID_KEY  = scedma_pkg::SEGID_KEY  ;
    localparam [7:0] SEGID_SKEY = scedma_pkg::SEGID_SKEY ;
    localparam [7:0] SEGID_SCRT = scedma_pkg::SEGID_SCRT ;
    localparam [7:0] SEGID_MSG  = scedma_pkg::SEGID_MSG  ;
    localparam [7:0] SEGID_HOUT = scedma_pkg::SEGID_HOUT ;
    localparam [7:0] SEGID_SOB  = scedma_pkg::SEGID_SOB  ;
    localparam [7:0] SEGID_HOUT2 = scedma_pkg::SEGID_SOB + 1 ;

    localparam segcfg_t SEG_LKEY = scedma_pkg::SEGCFGS[SEGID_LKEY];
    localparam segcfg_t SEG_KEY  = scedma_pkg::SEGCFGS[SEGID_KEY ];
    localparam segcfg_t SEG_SKEY = scedma_pkg::SEGCFGS[SEGID_SKEY];
    localparam segcfg_t SEG_SCRT = scedma_pkg::SEGCFGS[SEGID_SCRT];
    localparam segcfg_t SEG_MSG  = scedma_pkg::SEGCFGS[SEGID_MSG ];
    localparam segcfg_t SEG_HOUT = scedma_pkg::SEGCFGS[SEGID_HOUT];
    localparam segcfg_t SEG_SOB  = scedma_pkg::SEGCFGS[SEGID_SOB ];
    localparam segcfg_t SEG_HOUT2 = scedma_pkg::SEGCFGS[SEGID_HOUT];
    localparam segcfg_t SEG_INIT =
        '{  segid:      '0 ,
            segtype:    ST_BI,
            ramsel:     'd0,
            segaddr:    '0 ,
            segsize:    INITSIZE ,
            isfifo:     '0,
            isfifostream:'0,
            fifoid:     '0
        };


// typedef
// ■■■■■■■■■■■■■■■

    typedef enum bit[7:0] {
        MFSM_IDLE      = 'h00,
        MFSM_DONE      = 'hff,
        MFSM_HF        = 'h20,
        MFSM_LD_ST     = 'h10,
        MFSM_LD_LKEY   = 'h11,
        MFSM_LD_KEYST  = 'h19,
        MFSM_LD_MSG0   = 'h12,
        MFSM_LD_MSG    = 'h13,
        MFSM_LD_PASS1  = 'h14,
        MFSM_LD_KEY    = 'h15,
        MFSM_LD_PAD    = 'h16,
        MFSM_LD_SECRET = 'h17,
        MFSM_LD_INIT   = 'h18,
        MFSM_WB_HOUT   = 'h30,
        MFSM_WB_SOB    = 'h31,
        MFSM_WB_KEY    = 'h32
    } mfsm_e;

    localparam adr_t RAMSEG_ST = hash_pkg::RAMSEG_ST;
    localparam adr_t RAMSEG_MSG = hash_pkg::RAMSEG_MSG;

    localparam scedma_pkg::segcfg_t HASHSEG_INIT = '{
            segid        : '0,
            segtype      : ST_NONE,
            ramsel       : '0,
            segaddr      : '0,
            segsize      : INITSIZE,
            isfifo       : '0,
            isfifostream : '0,
            fifoid       : '0
        };

    localparam scedma_pkg::segcfg_t HASHSEG_ST = '{
            segid        : '0,
            segtype      : ST_NONE,
            ramsel       : '0,
            segaddr      :  RAMSEG_ST,
            segsize      : 'd32,
            isfifo       : '0,
            isfifostream : '0,
            fifoid       : '0
        };

    localparam scedma_pkg::segcfg_t HASHSEG_MSG = '{
            segid        : '1,
            segtype      : ST_NONE,
            ramsel       : '0,
            segaddr      : RAMSEG_MSG,
            segsize      : 'd64,
            isfifo       : '0,
            isfifostream : '0,
            fifoid       : '0
        };

    localparam scedma_pkg::segcfg_t SEG_PAD = '{
            segid        : '1,
            segtype      : ST_NONE,
            ramsel       : '0,
            segaddr      : '0,
            segsize      : 'd64,
            isfifo       : '0,
            isfifostream : '0,
            fifoid       : '0
        };

    bit [15:0]  opt_cnt, pass1cnt;
    bit         opt_ifstart;
    bit         opt_ifsob;
    bit         opt_ifskey;
    bit         opt_check;
    mfsm_e mfsm, mfsmnext;
    bit [15:0] hashcnt, hashcntnext;
    bit mfsmtog, mfsmdone;
    hashtype_e cfg_hashtype;
    logic hash_start, chnli_start, chnlo_start;
    logic hash_busy, chnli_busy, chnlo_busy;
    logic hash_done, chnli_done, chnlo_done;
    logic [1:0] ramerror;
    scedma_pkg::adr_t MSGSIZE, STSIZE;
    logic hcore_en, hcore_ramrd, chnli_en, chnlo_en;
    chnlreq_t hcore_req, chnlo_rpreq, chnli_wpreq, hramreq;
    chnlres_t hramres;
    chnlcfg_t chnli_cfg, chnlo_cfg;
    scedma_pkg::adr_t hcore_ramaddr;
    scedma_pkg::dat_t hcore_ramrdat, hcore_ramwdat;
    logic hcore_ramwr;
    bit [7:0] chnlo_intr, chnli_intr;
    bit optlock;
    bit             start;
    hashfunc_t        cr_func;
    hashfuncopt_t     cr_opt;
    scedma_pkg::adr_t [0:SEGCNT]   cr_segptrstart;
    logic mfsm_done;
    logic hash0;
    logic ramclrbusy;
    logic [7:0] cr_segltx, cr_optltx, cfg_blkt0;
    logic mfsmcheckscrt, chkpass, chkprepass, chkdone, chkfail;
    chnlreq_t       chnl_wpreq0;
    logic [1:0] opt_schnr;
    logic [9:0] kid;
    logic tsmode;
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
                        | sfr_opt1.prdata32 | sfr_opt2.prdata32 | sfr_opt3.prdata32 | sfr_segptr.prdata32
                        | sfr_keyidx.prdata32
                        ;

    apb_cr #(.A('h00), .DW(8))      sfr_crfunc      (.cr(cr_func), .prdata32(),.*);
    apb_ar #(.A('h04), .AR(32'h5a)) sfr_ar          (.ar(start),.*);
    apb_sr #(.A('h08), .DW(8))      sfr_srmfsm      (.sr(mfsm), .prdata32(),.*);
    apb_fr #(.A('h0c), .DW(7))      sfr_fr          (.fr({chkfail, chkpass, chkdone, chnli_done, chnlo_done, hash_done, mfsm_done}), .prdata32(),.*);

    apb_cr #(.A('h10), .DW(16))      sfr_opt1       (.cr(cr_opt.hashcnt), .prdata32(),.*);
    apb_cr #(.A('h14), .DW(7))       sfr_opt2       (.cr({cr_opt.ifskey,tsmode,opt_schnr[1:0],cr_opt.ifstart,cr_opt.ifsob,cr_opt.scrtchk}), .prdata32(),.*);
    apb_cr #(.A('h18), .DW(8))       sfr_opt3       (.cr(cr_optltx), .prdata32(),.*);
    apb_cr #(.A('h1C), .DW(8), .IV(32'h40))       sfr_blkt0      (.cr(cfg_blkt0), .prdata32(),.*);
    apb_cr #(.A('h60), .DW(10))       sfr_keyidx     (.cr(kid), .prdata32(),.*);

    apb_cr #(.A('h20), .DW(scedma_pkg::AW), .SFRCNT(SEGCNT+1) )      sfr_segptr    (.cr(cr_segptrstart), .prdata32(),.*); //## width?

    assign optlock = ( start & ( mfsm == MFSM_IDLE));

// define cmd/opt
// ■■■■■■■■■■■■■■■

    `theregrn( opt_ifsob   ) <= optlock ? cr_opt.ifsob & ~cr_opt.ifskey  : opt_ifsob   ;
    `theregrn( opt_ifstart ) <= optlock ? cr_opt.ifstart : opt_ifstart ;
    `theregrn( opt_cnt     ) <= optlock ? cr_opt.hashcnt : opt_cnt     ;
    `theregrn( opt_check   ) <= optlock ? cr_opt.scrtchk : opt_check   ;
    `theregrn( cr_segltx   ) <= optlock ? cr_optltx      : cr_segltx   ;
    `theregrn( opt_ifskey  ) <= optlock ? cr_opt.ifskey  : opt_ifskey   ;

    assign busy = |mfsm | ramclrbusy;
    assign done = mfsm_done;

// mfsm
// ■■■■■■■■■■■■■■■
    `theregfull(clk, resetn, mfsm, MFSM_IDLE ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone ? mfsmnext : mfsm;
    `theregrn( hashcnt ) <= ( start & ( mfsm == MFSM_IDLE)) ? '0 : hash_done ? hashcntnext : hashcnt;
    `theregrn( mfsmtog ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone;// ~( mfsm == mfsmnext ) & ~( mfsmnext == MFSM_IDLE );
    assign mfsm_done = ( mfsm == MFSM_DONE );

    assign hash0 = cr_opt.ifstart & ( hashcnt == 0 );
    assign pass1cnt = cr_opt.ifstart ? ( opt_cnt + 1 ) : opt_cnt;

    // hash0 will load skip ST load.

    always_comb begin
        mfsmnext = mfsm;
        mfsmdone = '0;
        hashcntnext = hashcnt;
        case (cr_func)
            HF_INIT:
                case( mfsm )
                    MFSM_IDLE: begin
                                                mfsmnext = MFSM_LD_INIT;
                        end
                    MFSM_LD_INIT: begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnli_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            HF_SHA256,
            HF_SHA512,
            HF_RIPMD,
            HF_BLK2s,
            HF_BLK2b,
            HF_BLK3:
                case( mfsm )
                    MFSM_IDLE:
                        if( hash0 )
                                                mfsmnext = MFSM_LD_MSG;
                        else
                                                mfsmnext = MFSM_LD_ST;
                    MFSM_LD_ST : begin
                                                mfsmnext = MFSM_LD_MSG;         mfsmdone = chnli_done;
                        end
                    MFSM_LD_MSG: begin
                                                mfsmnext = MFSM_HF;             mfsmdone = chnli_done;
                        end
                    MFSM_HF :
                        if( opt_cnt == hashcnt )begin
                                                mfsmnext = MFSM_WB_HOUT;        mfsmdone = hash_done;
                                                                                hashcntnext = '0;
                        end
                        else begin
                                                mfsmnext = MFSM_LD_MSG;         mfsmdone = hash_done;
                                                                                hashcntnext = hashcnt + 'h1;
                        end
                    MFSM_WB_HOUT :
                        if( opt_ifsob )begin
                                                mfsmnext = MFSM_WB_SOB;         mfsmdone = chnlo_done;

                        end
                        else begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnlo_done;
                        end
                    MFSM_WB_SOB : begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            HF_SHA3:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_MSG;
                    MFSM_LD_MSG: begin
                                                mfsmnext = MFSM_HF;             mfsmdone = chnli_done;
                        end
                    MFSM_HF : begin
                                                mfsmnext = MFSM_WB_HOUT;        mfsmdone = hash_done;
                        end
                    MFSM_WB_HOUT :
                        if( opt_ifsob )begin
                                                mfsmnext = MFSM_WB_SOB;         mfsmdone = chnlo_done;
                        end
                        else begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnlo_done;
                        end
                    MFSM_WB_SOB : begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            HF_HMAC256_KEYHASH,
            HF_HMAC512_KEYHASH:
                case( mfsm )
                    MFSM_IDLE:
                        if( hash0 )
                                                mfsmnext = MFSM_LD_LKEY;
                        else
                                                mfsmnext = MFSM_LD_KEYST;
                    MFSM_LD_KEYST : begin
                                                mfsmnext = MFSM_LD_LKEY;        mfsmdone = chnli_done;
                        end
                    MFSM_LD_LKEY: begin
                                                mfsmnext = MFSM_HF;             mfsmdone = chnli_done;
                        end
                    MFSM_HF :
                        if( opt_cnt == hashcnt )begin
                                                mfsmnext = MFSM_WB_KEY;         mfsmdone = hash_done;
                                                                                hashcntnext = '0;
                        end
                        else begin
                                                mfsmnext = MFSM_LD_LKEY;        mfsmdone = hash_done;
                                                                                hashcntnext = hashcnt + 'h1;
                        end
                    MFSM_WB_KEY : begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            HF_HMAC256_PASS1,
            HF_HMAC512_PASS1:
                case( mfsm )
                    MFSM_IDLE:
                        if( hash0 )
                                                mfsmnext = MFSM_LD_KEY ;
                        else
                                                mfsmnext = MFSM_LD_ST;
                    MFSM_LD_ST : begin
                                                mfsmnext = MFSM_LD_MSG;         mfsmdone = chnli_done;
                        end
                    MFSM_LD_KEY : begin
//                                                mfsmnext = MFSM_LD_MSG0;        mfsmdone = chnli_done;
//                        end
//                    MFSM_LD_MSG0: begin
                                                mfsmnext = MFSM_HF;             mfsmdone = chnli_done;
                        end
                    MFSM_LD_MSG: begin
                                                mfsmnext = MFSM_HF;             mfsmdone = chnli_done;
                        end
                    MFSM_HF :
                        if( hashcnt == pass1cnt )begin
                                                mfsmnext = MFSM_WB_HOUT;        mfsmdone = hash_done;
                                                                                hashcntnext = '0;
                        end
                        else begin
                                                mfsmnext = MFSM_LD_MSG;         mfsmdone = hash_done;
                                                                                hashcntnext = hashcnt + 'h1;
                        end
                    MFSM_WB_HOUT:
                        begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            HF_HMAC256_PASS2,
            HF_HMAC512_PASS2:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_KEY ;
                    MFSM_LD_KEY  : begin
                                                mfsmnext = MFSM_HF;             mfsmdone = chnli_done;
                        end
                    MFSM_HF :
                        if( hashcnt == 0 )begin
                                                mfsmnext = MFSM_LD_PASS1;       mfsmdone = hash_done;
                                                                                hashcntnext = '1;
                        end
                        else if( opt_check )begin
                                                mfsmnext = MFSM_LD_SECRET;      mfsmdone = hash_done;
                                                                                hashcntnext = '0;
                        end else begin
                                                mfsmnext = MFSM_WB_HOUT;        mfsmdone = hash_done;
                                                                                hashcntnext = '0;
                        end
                    MFSM_LD_PASS1: begin
                                                mfsmnext = MFSM_HF;             mfsmdone = chnli_done;
                        end
                    MFSM_LD_SECRET: begin
                                                mfsmnext = MFSM_DONE;
                                                                                mfsmdone = tsmode ? schdonex:chnli_done;
                        end
                    MFSM_WB_HOUT:
                        if( opt_ifsob )begin
                                                mfsmnext = MFSM_WB_SOB;         mfsmdone = chnlo_done;
                        end
                        else begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnlo_done;
                        end
                    MFSM_WB_SOB : begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = chnlo_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            default : /* default */
                begin
                    mfsmnext = MFSM_IDLE;
                    mfsmdone = '0;
                    hashcntnext = hashcnt;
                end
        endcase
    end

// hmac check
// ■■■■■■■■■■■■■■■
    chnlreq_t chnlscrt_wpreq;
    chnlreq_t chnlis_wpreq;
    assign schcrxsel = tsmode & mfsmcheckscrt;
    `theregrn( schstartx ) <= mfsmtog & mfsmcheckscrt & tsmode;


    assign schcrx.func     = '0;
    assign schcrx.opt      = 'h108 + cr_segltx[SEGID_SCRT] ;
    assign schcrx.axstart  = PM_KS_BA + kid * ( 256/8 );
    assign schcrx.segid    = 'h1f;
    assign schcrx.segstart = 0;
    assign schcrx.transize = STSIZE;

    assign schxrpres = scedma_pkg::CHNLRES_NULL;
    assign chnlis_wpreq.segcfg    = HASHSEG_ST  ;
    assign chnlis_wpreq.segaddr   = HASHSEG_ST.segaddr   ;
    assign chnlis_wpreq.segptr    = schxwpreq.segptr    ;
    assign chnlis_wpreq.segrd     = schxwpreq.segrd     ;
    assign chnlis_wpreq.segwr     = '0;//schxwpreq.segwr     ;
    assign chnlis_wpreq.segwdat   = schxwpreq.segwdat   ;
    assign chnlis_wpreq.porttype  = schxwpreq.porttype  ;
    assign schxwpres = hramres;

    assign chnlscrt_wpreq = tsmode ? chnlis_wpreq : chnli_wpreq;

    assign mfsmcheckscrt = ( mfsm == MFSM_LD_SECRET );
    `theregrn( chkprepass ) <=  ~mfsmcheckscrt ? '0 :
                                mfsmtog & mfsmcheckscrt ? '1 :
                                schxwpreq.segwr | chnli_wpreq.segwr ? chkprepass && ( chnlscrt_wpreq.segwdat == '0 ) : chkprepass;

    `theregrn( chkdone ) <= mfsmcheckscrt & (schdonex|chnli_done) ;
    assign chkpass = chkdone && chkprepass;
    assign chkfail = chkdone && ~chkprepass;

    `theregrn( hmac_pass ) <= chkpass;
    `theregrn( hmac_fail ) <= chkfail;
    assign hmac_kid = kid;

// subcore, chnl
// ■■■■■■■■■■■■■■■

    `theregrn( hash_start ) <= mfsmtog & ( mfsm == MFSM_HF  );

    always_comb
    case (cr_func)
            HF_SHA256:
                    cfg_hashtype = HT_SHA256;
            HF_SHA512:
                    cfg_hashtype = HT_SHA512;
            HF_RIPMD:
                    cfg_hashtype = HT_RIPMD;
            HF_BLK2s:
                    cfg_hashtype = HT_BLK2s;
            HF_BLK2b:
                    cfg_hashtype = HT_BLK2b;
            HF_BLK3:
                    cfg_hashtype = HT_BLK3;
            HF_SHA3:
                    cfg_hashtype = HT_SHA3;
            HF_HMAC256_KEYHASH,
            HF_HMAC256_PASS1,
            HF_HMAC256_PASS2:
                    cfg_hashtype = HT_SHA256;
            HF_HMAC512_KEYHASH,
            HF_HMAC512_PASS1,
            HF_HMAC512_PASS2:
                    cfg_hashtype = HT_SHA512;
         default :
                    cfg_hashtype = HT_NONE;
     endcase

    always_comb
    case(cfg_hashtype)
        HT_SHA256: begin  MSGSIZE = 16; STSIZE =  8;  end
        HT_SHA512: begin  MSGSIZE = 32; STSIZE = 16;  end
        HT_RIPMD:  begin  MSGSIZE = 16; STSIZE =  5;  end
        HT_BLK2s:  begin  MSGSIZE = 16; STSIZE = 16;  end
        HT_BLK2b:  begin  MSGSIZE = 32; STSIZE = 32;  end
        HT_BLK3:   begin  MSGSIZE = 32; STSIZE = 32;  end
        HT_SHA3:   begin  MSGSIZE = 50; STSIZE = 50;  end
        default :  begin  MSGSIZE =  0; STSIZE =  0;  end
    endcase


    assign hcore_en = ( mfsm == MFSM_HF );
    assign hcore_ramrd = 1'b1;

    hashcore hcore
    (
        .clk    (clk),
        .resetn (resetn),
        .start  (hash_start),
        .busy   (hash_busy),
        .done   (hash_done),
        .cfg_hashtype (cfg_hashtype),
        .cfg_firsthash(hash0),
        .cfg_finalhash('0),
        .cfg_blkt0,
        .ramaddr(hcore_ramaddr[9:0]),
        .ramrdat32(hcore_ramrdat),
        .ramwr32(hcore_ramwr),
        .ramwdat32(hcore_ramwdat)
    );

    assign hcore_req.segaddr = hcore_ramaddr|'0;
    assign hcore_req.segptr  = '0;
    assign hcore_req.segrd   = ~hcore_ramwr;
    assign hcore_req.segwr   = hcore_ramwr;
    assign hcore_req.segwdat = hcore_ramwdat;
    assign hcore_ramrdat     = hramres.segrdat;

    adr_t segptrdyna, segptrdynanext;

    `theregrn( segptrdyna ) <= ( mfsm == MFSM_IDLE ) | ( mfsm == MFSM_DONE ) ? '0 :
                               (( mfsm == MFSM_LD_LKEY ) | ( mfsm == MFSM_LD_MSG )) & chnli_done ? segptrdynanext : segptrdyna;

    assign segptrdynanext = ( chnl_rpreq.segptr == chnli_cfg.rpsegcfg.segsize - 1 ) ? '0 : chnl_rpreq.segptr + 1;

    always_comb begin
            chnli_cfg.rpsegcfg = SEG_MSG;
            chnli_cfg.wpsegcfg = HASHSEG_MSG;
            chnli_cfg.rpptr_start = cr_segptrstart[SEGID_MSG];
            chnli_cfg.opt_ltx     = cr_segltx[SEGID_MSG] | '0;
            chnli_cfg.transsize = MSGSIZE;
            chnli_en = '0;
            case(mfsm)
            MFSM_LD_INIT     :
                begin
                    chnli_cfg.rpsegcfg = SEG_INIT;
                    chnli_cfg.wpsegcfg = HASHSEG_INIT;
                    chnli_cfg.opt_ltx     = cr_segltx[0] | '0;
                    chnli_cfg.rpptr_start = '0;
                    chnli_cfg.transsize = INITSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_ST     :
                begin
                    chnli_cfg.rpsegcfg = SEG_HOUT;
                    chnli_cfg.wpsegcfg = HASHSEG_ST;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_HOUT];
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_HOUT] | '0;
                    chnli_cfg.transsize = STSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_KEYST     :
                begin
                    chnli_cfg.rpsegcfg = SEG_KEY;
                    chnli_cfg.wpsegcfg = HASHSEG_ST;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_KEY];
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_KEY] | '0;
                    chnli_cfg.transsize = STSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_LKEY   :
                begin
                    chnli_cfg.rpsegcfg = SEG_LKEY;
                    chnli_cfg.wpsegcfg = HASHSEG_MSG;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_LKEY] + segptrdyna;
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_LKEY] | '0;
                    chnli_cfg.transsize = MSGSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_MSG0   :
                begin
                    chnli_cfg.rpsegcfg = SEG_MSG;
                    chnli_cfg.wpsegcfg = HASHSEG_MSG;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_MSG];
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_MSG] | '0;
                    chnli_cfg.transsize = MSGSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_MSG    :
                begin
                    chnli_cfg.rpsegcfg = SEG_MSG;
                    chnli_cfg.wpsegcfg = HASHSEG_MSG;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_MSG] + segptrdyna;
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_MSG] | '0;
                    chnli_cfg.transsize = MSGSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_PASS1  :
                begin
                    chnli_cfg.rpsegcfg = SEG_HOUT;
                    chnli_cfg.wpsegcfg = HASHSEG_MSG;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_HOUT];
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_HOUT] | '0;
                    chnli_cfg.transsize = MSGSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_KEY    :
                begin
                    chnli_cfg.rpsegcfg = opt_ifskey ? SEG_SKEY : SEG_KEY; //SEG_SKEY##
                    chnli_cfg.wpsegcfg = HASHSEG_MSG;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_KEY];
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_KEY] | '0;
                    chnli_cfg.transsize = MSGSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_PAD    :
                begin
                    chnli_cfg.rpsegcfg = SEG_PAD;
                    chnli_cfg.wpsegcfg = HASHSEG_MSG;
//                    chnli_cfg.rpptr_start = crptr_msg;
                    chnli_cfg.transsize = MSGSIZE;
                    chnli_en = '1;
                end
            MFSM_LD_SECRET :
                begin
                    chnli_cfg.rpsegcfg = SEG_SCRT;
                    chnli_cfg.wpsegcfg = HASHSEG_ST;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_SCRT];
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_SCRT] | '0;
                    chnli_cfg.transsize = STSIZE;
                    chnli_en = '1;
                end
            default : /* default */
                begin
                    chnli_cfg.rpsegcfg = SEG_MSG;
                    chnli_cfg.wpsegcfg = HASHSEG_MSG;
                    chnli_cfg.rpptr_start = cr_segptrstart[SEGID_MSG];
                    chnli_cfg.opt_ltx     = cr_segltx[SEGID_MSG] | '0;
                    chnli_cfg.transsize = MSGSIZE;
                    chnli_en = '0;
                end
        endcase
    end

    assign chnli_cfg.chnlid = '0;
    assign chnli_cfg.wpptr_start = '0;
//    assign chnli_cfg.opt_ltx = '0;
    assign chnli_cfg.opt_xor =  ( mfsm == MFSM_LD_SECRET );
    assign chnli_cfg.opt_cmpp = '0;
    assign chnli_cfg.opt_prm = '0;
    assign chnli_cfg.wpffen = '0;

    `theregrn( chnli_start ) <= mfsmtog &
                                   (( mfsm == MFSM_LD_ST     )|
                                    ( mfsm == MFSM_LD_INIT   )|
                                    ( mfsm == MFSM_LD_LKEY   )|
                                    ( mfsm == MFSM_LD_KEYST  )|
                                    ( mfsm == MFSM_LD_MSG0   )|
                                    ( mfsm == MFSM_LD_MSG    )|
                                    ( mfsm == MFSM_LD_PASS1  )|
                                    ( mfsm == MFSM_LD_KEY    )|
                                    ( mfsm == MFSM_LD_PAD    )|
                                    ( mfsm == MFSM_LD_SECRET )&~tsmode);

    `theregrn( chnlo_start ) <= mfsmtog &
                                   (( mfsm == MFSM_WB_HOUT  )|
                                    ( mfsm == MFSM_WB_SOB   )|
                                    ( mfsm == MFSM_WB_KEY   ));

    always_comb begin
        case(mfsm)
            MFSM_WB_HOUT     :
                begin
                    chnlo_cfg.rpsegcfg = (cfg_hashtype==HT_SHA3) ? HASHSEG_MSG : HASHSEG_ST;
                    chnlo_cfg.wpsegcfg = SEG_HOUT;
          //          chnlo_cfg.wpptr_start = cr_segptrstart[SEGID_HOUT2];
                    chnlo_cfg.transsize = STSIZE;
                end
            MFSM_WB_SOB   :
                begin
                    chnlo_cfg.rpsegcfg = (cfg_hashtype==HT_SHA3) ? HASHSEG_MSG : HASHSEG_ST;
                    chnlo_cfg.wpsegcfg = SEG_SOB;
          //          chnlo_cfg.wpptr_start = cr_segptrstart[SEGID_SOB];
                    chnlo_cfg.transsize = STSIZE;
                end
            MFSM_WB_KEY   :
                begin
                    chnlo_cfg.rpsegcfg = HASHSEG_ST;
                    chnlo_cfg.wpsegcfg = SEG_KEY;// ##SEG_SKEY
          //          chnlo_cfg.wpptr_start = cr_segptrstart[SEGID_KEY];
                    chnlo_cfg.transsize = STSIZE;
                end
            default : /* default */
                begin
                    chnlo_cfg.rpsegcfg = HASHSEG_ST;
                    chnlo_cfg.wpsegcfg = SEG_HOUT;
                    chnlo_cfg.transsize = STSIZE;
                end
        endcase
    end

    assign chnlo_cfg.chnlid = '0;
    assign chnlo_cfg.rpptr_start = '0;
    assign chnlo_cfg.wpptr_start = cr_segptrstart[SEGID_HOUT2];
    assign chnlo_cfg.opt_ltx = cr_segltx[SEGID_HOUT2] | '0;
    assign chnlo_cfg.opt_xor = '0;
    assign chnlo_cfg.opt_cmpp = '0;
    assign chnlo_cfg.opt_prm = '0;
    assign chnlo_cfg.wpffen = '0;

//preprocess_out

    logic opt_preproc0, opt_preproc1;
    logic preproc0_mfsm, preproc1_mfsm;
    adr_t chnlo_rpreq_segptr_a, chnlo_rpreq_segptr_b;
    logic preproc0_a_pl1, preproc0_b_pl1, preproc1_a_pl1, preproc1_b_pl1;
    logic preproc0_a_wr, preproc0_b_wr, preproc1_a_wr, preproc1_b_wr;

    assign opt_preproc0 = opt_schnr[0];
    assign opt_preproc1 = opt_schnr[1];

    assign preproc0_mfsm = ( mfsm == MFSM_WB_HOUT );
    assign preproc1_mfsm = ( mfsm == MFSM_WB_SOB );

    assign chnlo_rpreq_segptr_a = 'h0;
    assign chnlo_rpreq_segptr_b = 'h7;

    `theregrn( preproc0_a_pl1 ) <= preproc0_mfsm && chnlo_rpreq.segrd && ( chnlo_rpreq.segptr == chnlo_rpreq_segptr_a );
    `theregrn( preproc0_b_pl1 ) <= preproc0_mfsm && chnlo_rpreq.segrd && ( chnlo_rpreq.segptr == chnlo_rpreq_segptr_b );
    `theregrn( preproc1_a_pl1 ) <= preproc1_mfsm && chnlo_rpreq.segrd && ( chnlo_rpreq.segptr == chnlo_rpreq_segptr_a );
    `theregrn( preproc1_b_pl1 ) <= preproc1_mfsm && chnlo_rpreq.segrd && ( chnlo_rpreq.segptr == chnlo_rpreq_segptr_b );

    assign preproc0_a_wr = preproc0_mfsm && chnl_wpreq0.segwr && ( chnlo_rpreq.segptr == chnlo_rpreq_segptr_a );
    assign preproc0_b_wr = preproc0_mfsm && chnl_wpreq0.segwr && ( chnlo_rpreq.segptr == chnlo_rpreq_segptr_b );
    assign preproc1_a_wr = preproc1_mfsm && chnl_wpreq0.segwr && ( chnlo_rpreq.segptr == chnlo_rpreq_segptr_a );
    assign preproc1_b_wr = preproc1_mfsm && chnl_wpreq0.segwr && ( chnlo_rpreq.segptr == chnlo_rpreq_segptr_b );

    assign chnl_wpreq.segwdat = ( preproc0_a_wr && preproc0_mfsm && opt_preproc0 ) | ( preproc1_a_wr && preproc1_mfsm && opt_preproc1 ) ? { chnl_wpreq0.segwdat[31:28], 4'h8, chnl_wpreq0.segwdat[23:0]} :
                                ( preproc0_b_wr && preproc0_mfsm && opt_preproc0 ) | ( preproc1_b_wr && preproc1_mfsm && opt_preproc1 ) ? { chnl_wpreq0.segwdat[31:8],2'h1,chnl_wpreq0.segwdat[5:0] } :
                                                                                                                                           chnl_wpreq0.segwdat;


    // assign chnl_wpreq.segwdat = ( preproc0_a_wr && preproc0_mfsm && opt_preproc0 ) | ( preproc1_a_wr && preproc1_mfsm && opt_preproc1 ) ? { chnl_wpreq0.segwdat[31:3], 3'h0 } :
    //                             ( preproc0_b_wr && preproc0_mfsm && opt_preproc0 ) | ( preproc1_b_wr && preproc1_mfsm && opt_preproc1 ) ? { 2'h0, chnl_wpreq0.segwdat[29:0] } :
    //                                                                                                                                        chnl_wpreq0.segwdat;
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
        .wpres    (hramres     ),
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
        .rpres    (hramres     ),
        .wpreq    (chnl_wpreq0  ),
        .wpres    (chnl_wpres  ),
        .intr     (chnlo_intr  )
    );

    assign hramreq  =   hcore_en ? hcore_req :
                        schcrxsel ? chnlis_wpreq :
                        chnli_en ? chnli_wpreq :
                                    chnlo_rpreq ;

// subcore, chnl
// ■■■■■■■■■■■■■■■

    // 768 x 32, 3KB
    // the real ram is 768x36

    localparam sramcfg_t thecfg = '{
        AW: 10,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 256*3,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };


    logic [9:0] cryptoramaddr;
    logic [31:0] hmac_keypadding, ramwdat, ramwdat_pass1padding, PASS1PADDING_END;
    logic pass1padding_en;
    adr_t blk64patch;

    assign cryptoramaddr = hramreq.segaddr + hramreq.segptr ^ blk64patch ;

    assign blk64patch = ~hcore_en & ( ( cr_func == HF_BLK2b )) ? 'h1 : '0;

    cryptoram #(
        .ramname    ("HRAM"), // HRAM, PRAM, ARAM, SCERAM
        .thecfg     (thecfg),
        .clrstart   (INITSIZE)
    )m(
        .clk(clkram), .resetn, .cmsatpg, .cmsbist,.rbs,
        .clkram(clkram), .clkramen('1),
        .ramclr,
        .ramclren(ramclrbusy),
        .ramaddr (cryptoramaddr ),
        .ramen('1),
        .ramrd(hramreq.segrd),
        .ramwr({4{hramreq.segwr}}),
        .ramwdat(ramwdat),
        .ramrdat(hramres.segrdat),
        .ramready(hramres.segready),
        .ramerror(ramerror)
    );
    assign hramres.segrdatvld = 1'b1;

    assign pass1padding_en = ( mfsm == MFSM_LD_PASS1 ) && ( chnli_wpreq.segptr >= STSIZE );
    assign ramwdat_pass1padding = pass1padding_en?
                                             (( chnli_wpreq.segptr == STSIZE ) ? 'h80000000 :
                                              ( chnli_wpreq.segptr == MSGSIZE-1 ) ? PASS1PADDING_END : '0 ):
                                             hramreq.segwdat;
    assign PASS1PADDING_END = ( cr_func == HF_HMAC256_PASS2 ) ? 'h00000300 : 'h00000600;

    assign ramwdat = ramwdat_pass1padding ^ hmac_keypadding;


    assign hmac_keypadding = ( mfsm == MFSM_LD_KEY ) ?
                                            (( cr_func == HF_HMAC256_PASS1 ) | ( cr_func == HF_HMAC512_PASS1 ) ? 32'h36363636 : 32'h5c5c5c5c )
                                          : '0;


// err/intr
// ■■■■■■■■■■■■■■■


    `theregrn( intr[0] ) <= ( mfsm == MFSM_DONE );
    `theregrn( err[0:1] ) <= ramerror;

endmodule


module dummytb_combohash ();
    bit            schcrxsel, schstartx, schdonex;
    chcr_t         schcrx;
    chnlreq_t       schxrpreq;
    chnlres_t       schxrpres;
    chnlreq_t       schxwpreq;
    chnlres_t       schxwpres;
    logic        hmac_pass, hmac_fail;
    logic [9:0]  hmac_kid;
    logic clk, resetn, cmsatpg, cmsbist;
    apbif apbs();
    rbif #(.AW(10   ),      .DW(36))    rbs  ();
    chnlreq_t       chnl_rpreq, chnl_wpreq;
    chnlres_t       chnl_rpres, chnl_wpres;
    logic [0:8-1]      err;
    logic [0:8-1]      intr;
    logic busy,done,clkram,ramclr;
combohash u1(
    .apbs(apbs),
    .apbx(apbs),
    .*
    );



endmodule


