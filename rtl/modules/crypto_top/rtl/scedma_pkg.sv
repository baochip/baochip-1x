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

import sram_pkg::*;

package scedma_pkg;

    parameter AW = 12;  // 16KB at 32bit // the greatest AW of all RAM/size/ptr
    parameter DW = 32;  // 4KB at 32bit
    parameter RAMCNT = 1    ;
    parameter SEGTYPECNT = 5;
    parameter TRANSCNTW = 30;

    typedef bit[AW-1:0]     adr_t   ;
    typedef bit[DW-1:0]     dat_t   ;

    typedef struct packed {
        bit [7:0]   ramid           ;
        adr_t       ramaw           ;
        adr_t       ramsize         ;
    }ramcfg_t;
/*
    typedef enum  bit[$clog2(SEGTYPECNT)-1:0] {
        ST_NONE      = 'd0,
        ST_BI        = 'd1,     //        input  data buf
        ST_BO        = 'd2,     //        output data buf
        ST_SI        = 'd3,     // secure input  data buf ( not used )
        ST_SO        = 'd4      // secure output data buf
    } segtype_e;
*/

    typedef bit[2:0]     segtype_e   ;

    localparam segtype_e ST_NONE      = 'd0;
    localparam segtype_e ST_BI        = 'd1;     //        input  data buf
    localparam segtype_e ST_BO        = 'd2;     //        output data buf
    localparam segtype_e ST_SI        = 'd3;     // secure input  data buf ( not used )
    localparam segtype_e ST_SO        = 'd4;     // secure output data buf
    localparam segtype_e ST_KI        = 'd5;     // secure key buf

    typedef struct packed {
		bit [7:0]	segid 		    ;
        segtype_e   segtype         ;
//        bit [7:0]   ramsel          ;
        bit         ramsel          ;
		adr_t       segaddr 	    ;
        adr_t       segsize 	    ;
        bit 		isfifo		    ;
        bit 		isfifostream	;
        bit [7:0]   fifoid          ; // idx of fifo
    }segcfg_t;

// chnl
// ■■■■■■■■■■■■■■■

    typedef struct packed {
        bit [7:0]   chnlid          ;
        segcfg_t    rpsegcfg        ;
        segcfg_t    wpsegcfg        ;
        adr_t       rpptr_start     ;
        adr_t       wpptr_start     ;

        bit         wpffen          ;
        bit [TRANSCNTW-1:0] transsize       ;
        bit [3:0]   opt_ltx         ;
        bit         opt_xor         ;
        bit         opt_cmpp        ;   // mod
        bit [255:0] opt_prm         ;   // prime to be mod
    }chnlcfg_t;

//    typedef enum  bit[1:0] {
//        PT_NONE      = 'd0,
//        PT_RO        = 'd1,
//        PT_WO        = 'd2,
//        PT_RW        = 'd3
//    } porttype_e;

    typedef bit[1:0]     porttype_e   ;

    localparam porttype_e PT_NONE      = 'd0;
    localparam porttype_e PT_RO        = 'd1;
    localparam porttype_e PT_WO        = 'd2;
    localparam porttype_e PT_RW        = 'd3;

  // chnl port

    typedef struct packed {
        segcfg_t       segcfg       ;
        adr_t          segaddr      ;
        adr_t          segptr       ;
        bit            segrd        ;
        bit            segwr        ;
        dat_t          segwdat      ;
        porttype_e     porttype     ;
    }chnlreq_t;

    typedef struct packed {
        bit            segready     ;
        dat_t          segrdat      ;
        bit            segrdatvld   ;
    }chnlres_t;

  // for arb only @memc

    typedef struct packed {
        adr_t          segaddr      ;
        adr_t          segptr       ;
        bit            ramrd        ;
        bit            ramwr        ;
        dat_t          ramwdat      ;
    }arbdat_t;


    typedef struct packed {
        bit                func     ;
        bit [9:0]          opt      ;
        bit [31:0]         axstart  ;
        bit [7:0]          segid    ;
        adr_t              segstart ;
        bit[TRANSCNTW-1:0] transize ;
    }chcr_t;

    localparam chnlreq_t CHNLRES_NULL = {
            segcfg:    '0,
            segaddr:   '0,
            segptr:    '0,
            segrd:     '0,
            segwr:     '0,
            segwdat:   '0,
            porttype:  '0
        };

    localparam chnlres_t CHNLREP_NULL = {
            segready:     '1,
            segrdat:      '0,
            segrdatvld:   '1
    };

// ram define
// ■■■■■■■■■■■■■■■
/*
    localparam sramcfg_t samplecfg = {
        AW: 10,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 1024,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };
*/
// ram define
// ■■■■■■■■■■■■■■■

    localparam [7:0] SEGID_LKEY = 8'd0;              //  0
    localparam [7:0] SEGID_KEY  = SEGID_LKEY + 'd1;  //  1
    localparam [7:0] SEGID_SKEY = SEGID_KEY  + 'd1;  //  2
    localparam [7:0] SEGID_SCRT = SEGID_SKEY + 'd1;  //  3
    localparam [7:0] SEGID_MSG  = SEGID_SCRT + 'd1;  //  4
    localparam [7:0] SEGID_HOUT = SEGID_MSG  + 'd1;  //  5
    localparam [7:0] SEGID_SOB  = SEGID_HOUT + 'd1;  //  6
    localparam [7:0] SEGID_PCON = SEGID_SOB  + 'd1;  //  7
    localparam [7:0] SEGID_PKB  = SEGID_PCON + 'd1;  //  8
    localparam [7:0] SEGID_PIB  = SEGID_PKB  + 'd1;  //  9
    localparam [7:0] SEGID_PSIB = SEGID_PIB  + 'd1;  //  a
    localparam [7:0] SEGID_POB  = SEGID_PSIB + 'd1;  //  b
    localparam [7:0] SEGID_PSOB = SEGID_POB  + 'd1;  //  c
    localparam [7:0] SEGID_AKEY = SEGID_PSOB + 'd1;  //  d
    localparam [7:0] SEGID_AIB  = SEGID_AKEY + 'd1;  //  e
    localparam [7:0] SEGID_AOB  = SEGID_AIB  + 'd1;  //  f
    localparam [7:0] SEGID_RNGA = SEGID_AOB  + 'd1;  // 10
    localparam [7:0] SEGID_RNGB = SEGID_RNGA + 'd1;  // 11

    localparam adr_t SEGSIZE_LKEY = 'd256/4; localparam adr_t SEGADDR_LKEY = 'd0;
    localparam adr_t SEGSIZE_KEY  = 'd256/4; localparam adr_t SEGADDR_KEY  = SEGADDR_LKEY + SEGSIZE_LKEY;
    localparam adr_t SEGSIZE_SKEY = 'd256/4; localparam adr_t SEGADDR_SKEY = SEGADDR_KEY  + SEGSIZE_KEY ;
    localparam adr_t SEGSIZE_SCRT = 'd256/4; localparam adr_t SEGADDR_SCRT = SEGADDR_SKEY + SEGSIZE_SKEY;
    localparam adr_t SEGSIZE_MSG  = 'd512/4; localparam adr_t SEGADDR_MSG  = SEGADDR_SCRT + SEGSIZE_SCRT;
    localparam adr_t SEGSIZE_HOUT = 'd256/4; localparam adr_t SEGADDR_HOUT = SEGADDR_MSG  + SEGSIZE_MSG ;
    localparam adr_t SEGSIZE_SOB  = 'd256/4; localparam adr_t SEGADDR_SOB  = SEGADDR_HOUT + SEGSIZE_HOUT;
//  localparam adr_t SEGSIZE_PCON = 'd256/4; localparam adr_t SEGADDR_PCON = SEGADDR_SOB  + SEGSIZE_SOB ;
    localparam adr_t SEGSIZE_PCON = '0;      localparam adr_t SEGADDR_PCON = SEGADDR_SOB  + SEGSIZE_SOB ;
//  localparam adr_t SEGSIZE_PKB  = 'd256/4; localparam adr_t SEGADDR_PKB  = SEGADDR_PCON + SEGSIZE_PCON;
    localparam adr_t SEGSIZE_PKB  = 'd1024/4; localparam adr_t SEGADDR_PKB  = SEGADDR_PCON + SEGSIZE_PCON;
    localparam adr_t SEGSIZE_PIB  = 'd2048/4; localparam adr_t SEGADDR_PIB  = SEGADDR_PKB  + SEGSIZE_PKB ;
    localparam adr_t SEGSIZE_PSIB = 'd0/4;    localparam adr_t SEGADDR_PSIB = SEGADDR_PIB  + SEGSIZE_PIB ;
    localparam adr_t SEGSIZE_POB  = 'd1024/4; localparam adr_t SEGADDR_POB  = SEGADDR_PSIB + SEGSIZE_PSIB;
    localparam adr_t SEGSIZE_PSOB = 'd1024/4; localparam adr_t SEGADDR_PSOB = SEGADDR_POB  + SEGSIZE_POB ;
    localparam adr_t SEGSIZE_AKEY = 'd256/4; localparam adr_t SEGADDR_AKEY = SEGADDR_PSOB + SEGSIZE_PSOB;
    localparam adr_t SEGSIZE_AIB  = 'd256/4; localparam adr_t SEGADDR_AIB  = SEGADDR_AKEY + SEGSIZE_AKEY;
    localparam adr_t SEGSIZE_AOB  = 'd256/4; localparam adr_t SEGADDR_AOB  = SEGADDR_AIB  + SEGSIZE_AIB ;
    localparam adr_t SEGSIZE_RNGA = 'd1024/4; localparam adr_t SEGADDR_RNGA = SEGADDR_AOB  + SEGSIZE_AOB ;
    localparam adr_t SEGSIZE_RNGB = 'd1024/4; localparam adr_t SEGADDR_RNGB = SEGADDR_RNGA + SEGSIZE_RNGA;

    localparam SEGCNT = SEGID_RNGB+1;

    localparam segcfg_t [0:SEGCNT-1] SEGCFGS =
    '{
/*  0*/    '{ segid:SEGID_LKEY , segtype:ST_BI,  ramsel: '0/*'d0*/,  segaddr:SEGADDR_LKEY , segsize:SEGSIZE_LKEY ,  isfifo:'1,  isfifostream:'0,  fifoid: 'd0 },
/*  1*/    '{ segid:SEGID_KEY  , segtype:ST_BI,  ramsel: '0/*'d0*/,  segaddr:SEGADDR_KEY  , segsize:SEGSIZE_KEY  ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  2*/    '{ segid:SEGID_SKEY , segtype:ST_KI,  ramsel: '0/*'d0*/,  segaddr:SEGADDR_SKEY , segsize:SEGSIZE_SKEY ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  3*/    '{ segid:SEGID_SCRT , segtype:ST_KI,  ramsel: '0/*'d0*/,  segaddr:SEGADDR_SCRT , segsize:SEGSIZE_SCRT ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  4*/    '{ segid:SEGID_MSG  , segtype:ST_BI,  ramsel: '0/*'d0*/,  segaddr:SEGADDR_MSG  , segsize:SEGSIZE_MSG  ,  isfifo:'1,  isfifostream:'0,  fifoid: 'd1 },
/*  5*/    '{ segid:SEGID_HOUT , segtype:ST_BO,  ramsel: '0/*'d0*/,  segaddr:SEGADDR_HOUT , segsize:SEGSIZE_HOUT ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  6*/    '{ segid:SEGID_SOB  , segtype:ST_SO,  ramsel: '0/*'d0*/,  segaddr:SEGADDR_SOB  , segsize:SEGSIZE_SOB  ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  7*/    '{ segid:SEGID_PCON , segtype:ST_BI,  ramsel: '0/*'d1*/,  segaddr:SEGADDR_PCON , segsize:SEGSIZE_PCON ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  8*/    '{ segid:SEGID_PKB  , segtype:ST_KI,  ramsel: '0/*'d1*/,  segaddr:SEGADDR_PKB  , segsize:SEGSIZE_PKB  ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  9*/    '{ segid:SEGID_PIB  , segtype:ST_BI,  ramsel: '0/*'d1*/,  segaddr:SEGADDR_PIB  , segsize:SEGSIZE_PIB  ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  a*/    '{ segid:SEGID_PSIB , segtype:ST_BI,  ramsel: '0/*'d1*/,  segaddr:SEGADDR_PSIB , segsize:SEGSIZE_PSIB ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  b*/    '{ segid:SEGID_POB  , segtype:ST_BO,  ramsel: '0/*'d1*/,  segaddr:SEGADDR_POB  , segsize:SEGSIZE_POB  ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  c*/    '{ segid:SEGID_PSOB , segtype:ST_SO,  ramsel: '0/*'d1*/,  segaddr:SEGADDR_PSOB , segsize:SEGSIZE_PSOB ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  d*/    '{ segid:SEGID_AKEY , segtype:ST_KI,  ramsel: '0/*'d2*/,  segaddr:SEGADDR_AKEY , segsize:SEGSIZE_AKEY ,  isfifo:'0,  isfifostream:'0,  fifoid: 'd0 },
/*  e*/    '{ segid:SEGID_AIB  , segtype:ST_BI,  ramsel: '0/*'d2*/,  segaddr:SEGADDR_AIB  , segsize:SEGSIZE_AIB  ,  isfifo:'1,  isfifostream:'0,  fifoid: 'd2 },
/*  f*/    '{ segid:SEGID_AOB  , segtype:ST_SO,  ramsel: '0/*'d2*/,  segaddr:SEGADDR_AOB  , segsize:SEGSIZE_AOB  ,  isfifo:'1,  isfifostream:'0,  fifoid: 'd3 },
/* 10*/    '{ segid:SEGID_RNGA , segtype:ST_BO,  ramsel: '0/*'d3*/,  segaddr:SEGADDR_RNGA , segsize:SEGSIZE_RNGA ,  isfifo:'1,  isfifostream:'1,  fifoid: 'd4 },
/* 11*/    '{ segid:SEGID_RNGB , segtype:ST_BO,  ramsel: '0/*'d3*/,  segaddr:SEGADDR_RNGB , segsize:SEGSIZE_RNGB ,  isfifo:'1,  isfifostream:'1,  fifoid: 'd5 }
    };
    localparam FFCNT = 6;

    localparam bit [0:FFCNT-1][7:0] FFIDS = {SEGID_LKEY, SEGID_MSG, SEGID_AIB, SEGID_AOB, SEGID_RNGA, SEGID_RNGB };

    localparam segcfg_t SEG_LKEY = SEGCFGS[SEGID_LKEY];
    localparam segcfg_t SEG_KEY  = SEGCFGS[SEGID_KEY ];
    localparam segcfg_t SEG_SKEY = SEGCFGS[SEGID_SKEY];
    localparam segcfg_t SEG_SCRT = SEGCFGS[SEGID_SCRT];
    localparam segcfg_t SEG_MSG  = SEGCFGS[SEGID_MSG ];
    localparam segcfg_t SEG_HOUT = SEGCFGS[SEGID_HOUT];
    localparam segcfg_t SEG_SOB  = SEGCFGS[SEGID_SOB ];
    localparam segcfg_t SEG_PCON = SEGCFGS[SEGID_PCON];
    localparam segcfg_t SEG_PKB  = SEGCFGS[SEGID_PKB ];
    localparam segcfg_t SEG_PIB  = SEGCFGS[SEGID_PIB ];
    localparam segcfg_t SEG_PSIB = SEGCFGS[SEGID_PSIB];
    localparam segcfg_t SEG_POB  = SEGCFGS[SEGID_POB ];
    localparam segcfg_t SEG_PSOB = SEGCFGS[SEGID_PSOB];
    localparam segcfg_t SEG_AKEY = SEGCFGS[SEGID_AKEY];
    localparam segcfg_t SEG_AIB  = SEGCFGS[SEGID_AIB ];
    localparam segcfg_t SEG_AOB  = SEGCFGS[SEGID_AOB ];
    localparam segcfg_t SEG_RNGA = SEGCFGS[SEGID_RNGA];
    localparam segcfg_t SEG_RNGB = SEGCFGS[SEGID_RNGB];

    localparam CHNLACCNT = 8;
        // 0/1: ahb:   R/W,
        // 2/3: axi:   R/W
        // 4/5: axi-s: R/W
        // 6/7: ich:   R/W

    typedef struct packed {
        bit [7:0]   segid          ;
        bit [0:CHNLACCNT-1]
                    accessrule  ;   // should be
    }accessrule_t;

    localparam accessrule_t [0:SEGCNT-1] ACRULEs =
    '{
        '{ segid:SEGID_LKEY , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_KEY  , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_SKEY , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_SCRT , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_MSG  , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_HOUT , accessrule: 8'b01_00_00_10 },
        '{ segid:SEGID_SOB  , accessrule: 8'b10_00_10_00 },
        '{ segid:SEGID_PCON , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_KEY  , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_PIB  , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_PSIB , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_POB  , accessrule: 8'b00_00_00_10 },
        '{ segid:SEGID_PSOB , accessrule: 8'b10_00_10_00 },
        '{ segid:SEGID_AKEY , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_AIB  , accessrule: 8'b01_01_01_01 },
        '{ segid:SEGID_AOB  , accessrule: 8'b10_10_10_10 },
        '{ segid:SEGID_RNGA , accessrule: 8'b10_11_10_10 },
        '{ segid:SEGID_RNGB , accessrule: 8'b10_11_10_10 }
    };



    localparam sram_pkg::sramcfg_t [0:RAMCNT-1] SCERAMCFGS = '{'{
        AW: AW,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 256*10,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    }};







endpackage : scedma_pkg
