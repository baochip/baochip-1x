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
//`include "hash_pkg_v0.1.sv"

import hash_pkg::*;

module hashcore #(
        parameter AW = 10,
        parameter VREGCNT = 16
)(
	input   bit	            clk,    // Clock
	input   bit	            resetn,  // Asynchronous reset active low

	input 	bit	            start,
	output 	bit	            busy,
	output 	bit             done,
	input 	hashtype_t      cfg_hashtype,
    input   bit             cfg_firsthash,
    input   bit             cfg_finalhash,
    input   bit [7:0]       cfg_blkt0,

	output bit	[AW-1:0]  	ramaddr,
	input  bit	[31:0]		ramrdat32,
	output bit	   		    ramwr32,
    output bit 	[31:0]		ramwdat32
);

    localparam HASHTYPECNT = hash_pkg::HASHTYPECNT;
    localparam PLCNT = 3;

    localparam RAMSEG_SHA256_H   = 0 ;
    localparam RAMSEG_SHA256_K   = RAMSEG_SHA256_H   + 8    ;
    localparam RAMSEG_SHA512_H   = RAMSEG_SHA256_K   + 64   ;
    localparam RAMSEG_SHA512_K   = RAMSEG_SHA512_H   + 8*2  ;
    localparam RAMSEG_BLK2s_H    = RAMSEG_SHA512_K   + 80*2   ;
    localparam RAMSEG_BLK2b_H    = RAMSEG_BLK2s_H    + 8    ;
    localparam RAMSEG_BLK2_X     = RAMSEG_BLK2b_H    + 16   ;
    localparam RAMSEG_BLK3_H     = RAMSEG_BLK2_X     + 20   ;
    localparam RAMSEG_BLK3_X     = RAMSEG_BLK3_H     + 8    ;
    localparam RAMSEG_RIPMD_H    = RAMSEG_BLK3_X     + 14   ;
    localparam RAMSEG_RIPMD_K    = RAMSEG_RIPMD_H    + 6    ;
    localparam RAMSEG_RIPMD_X    = RAMSEG_RIPMD_K    + 10   ;
    localparam RAMSEG_SHA3_P0    = RAMSEG_RIPMD_X    + 40   ;
    localparam RAMSEG_SHA3_P1    = RAMSEG_SHA3_P0    + 10   ; //48
    localparam RAMSEG_ST         = 'h200 ;
    localparam RAMSEG_MSG        = RAMSEG_ST + 32 ;

    localparam hashcfg_t [0:HASHTYPECNT-1] theHASHCFGs = hash_pkg::HASHCFGs;

    hashcfg_t [0:HASHTYPECNT-1] sim_HASHCFGs;
    assign sim_HASHCFGs = theHASHCFGs;

    hashcfg_t  sim_HASHCFGs0;
    assign sim_HASHCFGs0 = theHASHCFGs[1];

//  config
//  ===

    hashcfg_t   thecfg;
    hashtype_t  hashtypereg;
    bit         startvld, firstrnd, finalrnd;

    assign thecfg = theHASHCFGs[hashtypereg];
    `theregrn(hashtypereg) <= startvld ? cfg_hashtype : hashtypereg;
    `theregrn(firstrnd) <= startvld ? cfg_firsthash : firstrnd;
    `theregrn(finalrnd) <= startvld ? cfg_finalhash : finalrnd;
    `theregrn(busy) <= startvld ? 1'b1 : done ? 1'b0 : busy;
    assign startvld = start & ~busy & ~( cfg_hashtype == '0 );

    logic hashcoresel_sha2, hashcoresel_sha3, hashcoresel_blk, hashcoresel_ripe;

    assign hashcoresel_sha2 = ( thecfg.coresel == CORE_SHA2 );
    assign hashcoresel_sha3 = ( thecfg.coresel == CORE_SHA3 );
    assign hashcoresel_blk =  ( thecfg.coresel == CORE_BLK  );
    assign hashcoresel_ripe = ( thecfg.coresel == CORE_RIPMD );

`ifdef SIM
    hashtype_e cfg_hashtype0;
    assign cfg_hashtype0 = theHASHCFGs[cfg_hashtype].hashtype;
    always@(posedge clk)
        if(startvld) begin
            $write("\n===========================\n");
            $write("@i:HASH start:%s\n", cfg_hashtype0.name());
//            $write("@i:W    = \n"); for(i=0;i<8 ;i++)$write(" %016x ", sim_ww64[i]); $write("\n"); for(i=8;i<16 ;i++)$write(" %016x ", sim_ww64[i]); $write("\n");
    end
`endif
//  fsm
//  ==

    bit         d64tog0, d64tog;
    bit [2:0]   mfsm_nxt;
    bit [2:0]   mfsm;
    bit [4:0]   mfsm_incnt, mfsm_outcnt, mfsm_wbcnt, mfsm_incntpl1, mfsm_outcntpl1, mfsm_incntpl2, mfsm_outcntpl2, mfsm_wbcntpl1, mfsm_wbcntpl2;
    bit mfsm_in_pl1, mfsm_hash_pl1, mfsm_out_pl1;
    bit mfsm_in_pl2, mfsm_hash_pl2, mfsm_out_pl2;

    bit hashrnddone, hashrndlast;
    bit mfsm_in;        assign mfsm_in =    (mfsm == 1);
    bit mfsm_hash;      assign mfsm_hash =  (mfsm == 2);
    bit mfsm_out;       assign mfsm_out =   (mfsm == 3);
    bit mfsm_wb;        assign mfsm_wb =    (mfsm == 4);
    bit mfsm_indone;    assign mfsm_indone  =   ( mfsm_incnt  == thecfg.incnt -1 ) & d64tog ;
    bit mfsm_wbdone;    assign mfsm_wbdone  =   ( mfsm_wbcnt  == thecfg.wbcnt -1 ) & d64tog ;
    bit mfsm_outdone;   assign mfsm_outdone =   ( mfsm_outcnt == thecfg.outcnt-1 ) & d64tog ;
    bit mfsm_hashdone;  assign mfsm_hashdone =  ( hashrndlast &  hashrnddone     ) & d64tog ;
    `theregrn( mfsm ) <= mfsm_nxt;
    assign mfsm_nxt =   startvld ? 1 :
                        mfsm_in & mfsm_indone ? 2 :
                        mfsm_hash & mfsm_hashdone ? 3 :
                        mfsm_out & mfsm_outdone ? 4 :
                        mfsm_wb & mfsm_wbdone ? 0 :
                                    mfsm;
    assign done = mfsm_wbdone;

    bit [7:0] hashrnd, hashrndpl1, hashrndpl2;
    bit [5:0] hashrndcyc, hashrndcycpl1, hashrndcycpl2;

    assign hashrndlast = hashrnd == thecfg.rndcnt - 1 ;
    assign hashrnddone = ( hashrndcyc == thecfg.rndcyc - 1 ) & d64tog ;
    `theregrn( hashrnd ) <= mfsm_indone ? 0 :
                            hashrnddone ? ( hashrndlast ? 0 : hashrnd + 1 ) : hashrnd;
    `theregrn( hashrndcyc ) <= ( mfsm_indone | hashrnddone ) ? 0 : hashrndcyc + ( mfsm_hash & d64tog ) ;
    `theregrn( mfsm_incnt ) <=  startvld | mfsm_indone ? 0  :  mfsm_incnt + ( mfsm_in & d64tog  );
    `theregrn( mfsm_outcnt ) <= mfsm_hashdone | mfsm_outdone ? 0 : mfsm_outcnt + ( mfsm_out & d64tog );
    `theregrn( mfsm_wbcnt ) <=  mfsm_outdone  | done ? 0 : mfsm_wbcnt +  ( mfsm_wb & d64tog );

    `theregrn( d64tog0 ) <= startvld ? 0 : ~d64tog0;
    assign d64tog = thecfg.d32 ? 1'b1 : d64tog0;


    `theregrn( { mfsm_in_pl1 } )   <= d64tog ? { mfsm_in } : ( { mfsm_in_pl1 } ) ;
    `theregrn( { mfsm_hash_pl1 } ) <= d64tog ? { mfsm_hash } : ( { mfsm_hash_pl1 } ) ;
    `theregrn( { mfsm_out_pl1 } )  <= d64tog ? { mfsm_out } : ( { mfsm_out_pl1 } );
    `theregrn( { mfsm_in_pl2, mfsm_hash_pl2, mfsm_out_pl2 } ) <= d64tog ? { mfsm_in_pl1, mfsm_hash_pl1, mfsm_out_pl1} : ( { mfsm_in_pl2, mfsm_hash_pl2, mfsm_out_pl2 } );
    `theregrn( { hashrndpl1, hashrndcycpl1 }) <= d64tog ? { hashrnd, hashrndcyc } : ( { hashrndpl1, hashrndcycpl1 } );
    `theregrn( { hashrndpl2, hashrndcycpl2 }) <= d64tog ? { hashrndpl1, hashrndcycpl1 } : ( { hashrndpl2, hashrndcycpl2 } );
    `theregrn( { mfsm_incntpl1, mfsm_outcntpl1, mfsm_wbcntpl1 } ) <= d64tog ?  { mfsm_incnt,    mfsm_outcnt,    mfsm_wbcnt    }  : ( { mfsm_incntpl1, mfsm_outcntpl1, mfsm_wbcntpl1 } );
    `theregrn( { mfsm_incntpl2, mfsm_outcntpl2, mfsm_wbcntpl2 } ) <= d64tog ?  { mfsm_incntpl1, mfsm_outcntpl1, mfsm_wbcntpl1 }  : ( { mfsm_incntpl2, mfsm_outcntpl2, mfsm_wbcntpl2 } );

// pipeline stage 1: addrs
// pipeline stage 2: ramdat
// pipeline stage 3: ramrdatreg, vregpre
// pipeline stage 4: vreg

    logic [63:0]    ramrdatreg;

    logic [0:VREGCNT-1] vregwr, vregwr_mfsmin, vregwr_mfsmhash, vregwr_mfsmout, vregwr_sha2, vregwr_sha3, vregwr_blk, vregwr_ripe, vregwr0;
    logic [0:VREGCNT-1][63:0] vreg, vregpre, vregpre_mfsmin, vregpre_mfsmhash, vregpre_mfsmout;
    logic [0:VREGCNT*2-1][31:0] vreg32, vreg32pre;

// pl0 : pipeline0 : ram-address phase
// ==

    logic [AW-1:0]  rambase, rambase_mfsmin, rambase_mfsmhash, rambase_mfsmout, rambase_mfsmwb;
    logic [AW-1:0]  ramptr0, ramptr_mfsmin,  ramptr_mfsmhash,  ramptr_mfsmout,  ramptr_mfsmwb, ramptr;
    logic           ramwr, ramwr_mfsmin, ramwr_mfsmhash, ramwr_mfsmout, ramwr_mfsmwb;
    logic [63:0]    ramwdat, ramwdat_mfsmin, ramwdat_mfsmhash, ramwdat_mfsmout, ramwdat_mfsmwb;

    assign { rambase, ramptr0, ramwr, ramwdat } =
                    mfsm_in   ? { rambase_mfsmin  , ramptr_mfsmin  , ramwr_mfsmin  , ramwdat_mfsmin   }:
                    mfsm_hash ? { rambase_mfsmhash, ramptr_mfsmhash, ramwr_mfsmhash, ramwdat_mfsmhash }:
                    mfsm_out  ? { rambase_mfsmout , ramptr_mfsmout , ramwr_mfsmout , ramwdat_mfsmout  }:
                    mfsm_wb   ? { rambase_mfsmwb  , ramptr_mfsmwb  , ramwr_mfsmwb  , ramwdat_mfsmwb   }:
                                '0;

    assign ramptr  = thecfg.d32 ? ramptr0 : { ramptr0, d64tog0 };
    assign ramaddr = rambase + ramptr;
    assign ramwr32 = ramwr;
    assign ramwdat32 = thecfg.d32 ? ramwdat[31:0] : ~d64tog ? ramwdat[63:32] : ramwdat[31:0];

    logic [AW-1:0]  rambase_sha2,  rambase_sha3,  rambase_blk,  rambase_ripe;
    logic [AW-1:0]  ramptr_sha2 ,  ramptr_sha3 ,  ramptr_blk,   ramptr_ripe ;
    logic           ramwr_sha2  ,  ramwr_sha3  ,  ramwr_blk,    ramwr_ripe  ;
    logic [63:0]    ramwdat_sha2,  ramwdat_sha3,  ramwdat_blk,  ramwdat_ripe;

    assign { rambase_mfsmhash, ramptr_mfsmhash, ramwr_mfsmhash, ramwdat_mfsmhash } =
                    hashcoresel_sha2  ? { rambase_sha2  , ramptr_sha2  , ramwr_sha2  , ramwdat_sha2   }:
                    hashcoresel_sha3  ? { rambase_sha3  , ramptr_sha3  , ramwr_sha3  , ramwdat_sha3   }:
                    hashcoresel_blk   ? { rambase_blk   , ramptr_blk   , ramwr_blk   , ramwdat_blk    }:
                    hashcoresel_ripe  ? { rambase_ripe  , ramptr_ripe  , ramwr_ripe  , ramwdat_ripe   }:
                                        '0;

//  mfsm in
//  ==

    logic [AW-1:0]  ramseg_h;
    logic blk_mfsmin_segst;

    always_comb begin : proc_
    case (thecfg.hashtype)
        HT_SHA256   : ramseg_h = RAMSEG_SHA256_H;
        HT_SHA512   : ramseg_h = RAMSEG_SHA512_H;
        HT_RIPMD    : ramseg_h = RAMSEG_RIPMD_H;
        HT_BLK2s    : ramseg_h = RAMSEG_BLK2s_H;
        HT_BLK2b    : ramseg_h = RAMSEG_BLK2b_H;
        HT_BLK3     : ramseg_h = RAMSEG_BLK3_H;
//        HT_CHACHA   : ramseg_h = RAMSEG_CHACHA20_H;
        default     : ramseg_h = '0;/* default */
    endcase
    end

    assign ramwdat_mfsmin = 0;
    assign ramwr_mfsmin = 0;

    assign ramptr_mfsmin = //( thecfg.inmode == 0 ) ? mfsm_incnt :
                                                    blk_mfsmin_segst ? mfsm_incnt[3:0] : mfsm_incnt[2:0] ;
    assign rambase_mfsmin = ( thecfg.inmode == 0 ) ? ( cfg_firsthash ? ramseg_h : RAMSEG_ST ) :
                            ( thecfg.inmode == 1 ) ? ( blk_mfsmin_segst ? RAMSEG_ST : ramseg_h ) : 0;

    // for blake
    assign blk_mfsmin_segst = ~mfsm_incnt[4];


//  mfsm out
//  ==

//    assign rambase_mfsmout = ( thecfg.outmode == 0 ) ? ( cfg_firsthash ? ramseg_h : RAMSEG_ST ) : 0;
//    assign ramptr_mfsmout = mfsm_outcnt;
//    assign ramwr_mfsmout = 0;
//    assign ramwdat_mfsmout = 0;

//  mfsm wb
//  ==

    assign rambase_mfsmwb = RAMSEG_ST;
    assign ramptr_mfsmwb = mfsm_wbcnt;
    assign ramwr_mfsmwb = 1;
    assign ramwdat_mfsmwb = thecfg.d32 ? vreg[mfsm_wbcnt][31:0] : vreg[mfsm_wbcnt];

// pl1 : pipeline1 : ram read data phase
// ==


// pl2 : pipeline2 : ram read reg data phase
// ==

    bit [31:0]  ramrdatreg0, ramdatreg64H, ramdatreg64L ;

    `thereg( ramrdatreg0 ) <= ~thecfg.d32 ? ramrdat32 : 0;
//    `thereg( ramrdatreg  ) <= d64tog ^ ~thecfg.d32 ? { ramrdatreg0, ramrdat32 } : ramrdatreg;

    `thereg( ramdatreg64H ) <= ~thecfg.d32 &  d64tog ? ramrdat32 : ramdatreg64H;
    `thereg( ramdatreg64L ) <= ~thecfg.d32 & ~d64tog ? ramrdat32 : ramdatreg64L;

    `thereg( ramrdatreg  ) <= thecfg.d32 ? { '0, ramrdat32 } : d64tog ? { ramdatreg64H,ramdatreg64L } : ramrdatreg;




    assign vregwr  = d64tog ? vregwr0 : '0;
    assign vregwr0  = mfsm_in_pl2   ? vregwr_mfsmin :
                      mfsm_hash_pl2 ? vregwr_mfsmhash :
                      mfsm_out_pl2  ? vregwr_mfsmout : 0;

    assign vregpre =  mfsm_in_pl2   ? vregpre_mfsmin :
                      mfsm_hash_pl2 ? vregpre_mfsmhash :
                      mfsm_out_pl2  ? vregpre_mfsmout : 0;

//  mfsm in
//  ==
    logic blk_mfsmin_segstpl1, blk_mfsmin_segstpl2;
    logic [8:15][63:0] vreg_mfsmin_blk;

    assign blk_mfsmin_segstpl1 = ~mfsm_incntpl1[4];
    assign blk_mfsmin_segstpl2 = ~mfsm_incntpl2[4];

    `theregrn( vregwr_mfsmin ) <= ( mfsm_in_pl1 & (mfsm_incntpl1 == 0) ) ? 2**(VREGCNT-1)
                                                            : d64tog ? ( (mfsm_incntpl1 == 16) ? 2**7 : vregwr_mfsmin / 2 ) : vregwr_mfsmin;
    assign vregpre_mfsmin = blk_mfsmin_segstpl2 ? { VREGCNT{ ramrdatreg }} : { VREGCNT{ ramrdatreg }} ^ { 512'h0, vreg_mfsmin_blk[8:15] } ;

    assign vreg_mfsmin_blk[8:13] = vreg[8:13];
    assign vreg_mfsmin_blk[14] = cfg_finalhash ? ~vreg[14] : vreg[14];
    assign vreg_mfsmin_blk[15] = vreg[15];


//  mfsm hash
//  ==

    bit [0:VREGCNT-1][63:0]  vregpre_sha2, vregpre_sha3, vregpre_blk, vregpre_ripe;

    assign vregpre_mfsmhash = hashcoresel_sha2 ? vregpre_sha2 :
                              hashcoresel_sha3 ? vregpre_sha3 :
                              hashcoresel_blk  ? vregpre_blk :
                              hashcoresel_ripe ? vregpre_ripe : 0;
    assign vregwr_mfsmhash =  hashcoresel_sha2 ? vregwr_sha2 :
                              hashcoresel_sha3 ? vregwr_sha3 :
                              hashcoresel_blk  ? vregwr_blk :
                              hashcoresel_ripe ? vregwr_ripe : 0;

//  mfsm out
//  ==

    hashcore_hout#(
            .AW                 (AW),
            .VREGCNT            (VREGCNT),
            .RAMSEG_ST          (RAMSEG_ST)
        )hout(
            .clk,
            .resetn,
            .thecfg,
            .cfg_firsthash,
            .mfsm_out_pl1,
            .mfsm_out_pl2,
            .mfsm_outcnt,
            .mfsm_outcntpl1,
            .d64tog,
            .cfg_blkt0,
            .ramseg_h,
            .ramrdatreg,
            .rambase        (rambase_mfsmout),
            .ramptr         (ramptr_mfsmout ),
            .ramwr          (ramwr_mfsmout ),
            .ramwdat        (ramwdat_mfsmout),

            .vreg           (vreg),
            .vregwr         (vregwr_mfsmout),
            .vregpre        (vregpre_mfsmout)
        );

//vreg32

// pl3 : pipeline3 : ram read reg data phase
// ==

    genvar gvi;
    generate
        for( gvi = 0; gvi < VREGCNT ; gvi++ )begin: genvreg
            assign { vreg32[gvi*2:gvi*2+1] }    = vreg[gvi];
            assign { vreg32pre[gvi*2:gvi*2+1] } = vregpre[gvi];
            `thereg( vreg[gvi] ) <= vregwr[gvi] ? vregpre[gvi] : vreg[gvi];
        end
    endgenerate

// ========
// hash core
// ========

hashcore_sha2#(
        .AW                 (AW),
        .RAMSEG_MSG         (RAMSEG_MSG),
        .RAMSEG_SHA256_K    (RAMSEG_SHA256_K),
        .RAMSEG_SHA512_K    (RAMSEG_SHA512_K)
    )sha2(
        .clk,
        .resetn,
        .thecfg,
        .hashrnd,
        .hashrndcyc,
        .hashrndcycpl1,
        .hashrndcycpl2,

        .d64tog,
        .ramrdatreg,
        .rambase        (rambase_sha2),
        .ramptr         (ramptr_sha2 ),
        .ramwr          (ramwr_sha2 ),
        .ramwdat        (ramwdat_sha2),

        .vreg           (vreg[0:8]),
        .vregwr         (vregwr_sha2[0:8]),
        .vregpre        (vregpre_sha2[0:8])
    );

hashcore_blk#(
        .AW                 (AW),
        .RAMSEG_MSG         (RAMSEG_MSG),
        .RAMSEG_BLK2_X     (RAMSEG_BLK2_X),
//        .RAMSEG_BLK2b_X     (RAMSEG_BLK2b_X),
        .RAMSEG_BLK3_X      (RAMSEG_BLK3_X)
    )blk(
        .clk,
        .resetn,
        .thecfg,
        .start,
        .mfsm_hash,
        .hashrnd,
        .hashrndcyc,
        .hashrndcycpl1,
        .hashrndcycpl2,

        .d64tog,
        .ramrdatreg,
        .rambase        (rambase_blk),
        .ramptr         (ramptr_blk ),
        .ramwr          (ramwr_blk ),
        .ramwdat        (ramwdat_blk),

        .vreg           (vreg[0:15]),
        .vregwr         (vregwr_blk[0:15]),
        .vregpre        (vregpre_blk[0:15])
    );


    logic sha3_start;
    logic mfsm_indone_pl2, mfsm_indone_pl1;

    assign sha3_start = mfsm_indone_pl2 && hashcoresel_sha3 & d64tog;
    `theregrn({mfsm_indone_pl2, mfsm_indone_pl1}) <= d64tog ? { mfsm_indone_pl1, mfsm_indone } : {mfsm_indone_pl2, mfsm_indone_pl1};

hashcore_sha3#(
        .AW                 (AW),
        .RAMBASE_A         (RAMSEG_MSG),
        .RAMBASE_B         (RAMSEG_MSG+50),
        .RAMBASE_P0        (RAMSEG_SHA3_P0),
        .RAMBASE_P1        (RAMSEG_SHA3_P1)
    )sha3(
        .clk,
        .resetn,
        .ce (d64tog),
        .start (sha3_start),
        .busy(),
        .done(),

        .ramrdatreg,
        .ramrdat({ ramdatreg64H,ramdatreg64L } ),
        .rambase        (rambase_sha3),
        .ramptr         (ramptr_sha3 ),
        .ramwr          (ramwr_sha3 ),
        .ramrd          (),
        .ramwdat        (ramwdat_sha3),

        .vreg           (vreg[11:15]),
        .vregwr         (vregwr_sha3[11:15]),
        .vregpre        (vregpre_sha3[11:15])
    );

    logic ripernd_start;
    assign ripernd_start = mfsm_indone && ( thecfg.hashtype == HT_RIPMD );

hashcore_ripe#(
        .AW                 (AW),
        .RAMSEG_MSG         (RAMSEG_MSG)
//        .RAMSEG_RIPMD_K     (RAMSEG_RIPMD_K),
//        .RAMSEG_RIPMD_X     (RAMSEG_RIPMD_X)
    )ripe(
        .clk,
        .resetn,
        .start (ripernd_start),
        .thecfg,
//        .hashrnd,
//        .hashrndcyc,
//        .hashrndcycpl1,
//        .hashrndcycpl2,

        .ramrdatreg,
        .rambase        (rambase_ripe),
        .ramptr         (ramptr_ripe ),
        .ramwr          (ramwr_ripe ),
        .ramwdat        (ramwdat_ripe),

        .vreg           (vreg),
        .vregwr         (vregwr_ripe),
        .vregpre        (vregpre_ripe)
    );

endmodule : hashcore
/*
module hashcore_ripe#(
        parameter AW = 10,
        parameter [AW-1:0] RAMSEG_MSG = 32,
        parameter [AW-1:0] RAMSEG_RIPMD_K = 32,
        parameter [AW-1:0] RAMSEG_RIPMD_X = 32
    )(
        input  logic               clk,
        input  logic               resetn,

        input  hashcfg_t           thecfg,

        input  logic [7:0]         hashrnd,
        input  logic [5:0]         hashrndcyc,
        input  logic [5:0]         hashrndcycpl1,
        input  logic [5:0]         hashrndcycpl2,

        input  logic [63:0]   ramrdatreg,
        output logic [AW-1:0] rambase,
        output logic [AW-1:0] ramptr,
        output logic          ramwr,
        output logic [63:0]   ramwdat,

        input  logic [0:8][63:0]   vreg,
        output logic [0:8]         vregwr,
        output logic [0:8][63:0]   vregpre

    );

    assign rambase = '0;
    assign ramptr = '0;
    assign ramwr = '0;
    assign ramwdat = '0;
    assign vregwr = '0;
    assign vregpre = '0;

endmodule
*/
/*module hashcore_sha3#(
        parameter AW = 10,
        parameter [AW-1:0] RAMSEG_MSG = 32
    )(
        input  logic               clk,
        input  logic               resetn,

        input  hashcfg_t           thecfg,

        input  logic [7:0]         hashrnd,
        input  logic [5:0]         hashrndcyc,
        input  logic [5:0]         hashrndcycpl1,
        input  logic [5:0]         hashrndcycpl2,

        input  logic [63:0]   ramrdatreg,
        output logic [AW-1:0] rambase,
        output logic [AW-1:0] ramptr,
        output logic          ramwr,
        output logic [63:0]   ramwdat,

        input  logic [0:8][63:0]   vreg,
        output logic [0:8]         vregwr,
        output logic [0:8][63:0]   vregpre

    );

    assign rambase = '0;
    assign ramptr = '0;
    assign ramwr = '0;
    assign ramwdat = '0;
    assign vregwr = '0;
    assign vregpre = '0;

endmodule
*/
module hashcore_sha2#(
        parameter AW = 10,
        parameter [AW-1:0] RAMSEG_MSG = 32,
        parameter [AW-1:0] RAMSEG_SHA256_K = 32,
        parameter [AW-1:0] RAMSEG_SHA512_K = 32
    )(
        input  logic               clk,
        input  logic               resetn,

        input  hashcfg_t           thecfg,

        input  logic [7:0]         hashrnd,
        input  logic [5:0]         hashrndcyc,
        input  logic [5:0]         hashrndcycpl1,
        input  logic [5:0]         hashrndcycpl2,

        input  logic          d64tog,
        input  logic [63:0]   ramrdatreg,
        output logic [AW-1:0] rambase,
        output logic [AW-1:0] ramptr,
        output logic          ramwr,
        output logic [63:0]   ramwdat,

        input  logic [0:8][63:0]   vreg,
        output logic [0:8]         vregwr,
        output logic [0:8][63:0]   vregpre

    );

    logic [AW-1:0] ramseg_msg;
    logic [AW-1:0] ramseg_k;

    assign ramseg_msg = RAMSEG_MSG;
    assign ramseg_k =   ( thecfg.hashtype == HT_SHA256 ) ? RAMSEG_SHA256_K : RAMSEG_SHA512_K;

    logic hashrnd_msgwr;

    logic [63:0] va, vb, vc, vd, ve, vf, vg, vh, mreg;
    logic [63:0] vapre, vbpre, vcpre, vdpre, vepre, vfpre, vgpre, vhpre, vepre0, mregpre;
    logic vvregwr, mregwr;

    assign rambase = hashrndcyc == 4 ? ramseg_k : ramseg_msg;

    assign ramptr = ramwr ? hashrnd + 16 :
                hashrndcyc == 0 ? hashrnd + 0:
                hashrndcyc == 1 ? hashrnd + 1:
                hashrndcyc == 2 ? hashrnd + 9:
                hashrndcyc == 3 ? hashrnd + 14:
//                hashrndcyc == 4 ? hashrnd :
//                hashrndcyc == 5 ? hashrnd :
                                  hashrnd ;

    `theregrn( ramwr ) <= d64tog ? ( ( hashrndcycpl1 == 4 ) & hashrnd_msgwr  ) : ramwr ;
    assign hashrnd_msgwr = 1;
    assign ramwdat = mreg;

    `theregrn( vvregwr ) <= d64tog ? ( ( hashrndcycpl1 == 6 ) ) : vvregwr ;
    assign { va, vb, vc, vd, ve, vf, vg, vh, mreg } = vreg[0:8];
    assign vregwr = { {8{ vvregwr }}, mregwr };
    assign vregpre = { vapre, vbpre, vcpre, vdpre, vepre, vfpre, vgpre, vhpre, mregpre };

// shacore
// ==
  function [63:0] func_maj(input [63:0] fva, input [63:0] fvb, input [63:0] fvc ); func_maj = ( fva & fvb ) ^ ( fva & fvc ) ^ ( fvb & fvc ); endfunction
  function [63:0] func_ch(input [63:0] fve, input [63:0] fvf, input [63:0] fvg ); func_ch = ( fve & fvf ) | ( ~fve & fvg ); endfunction  // XOR could be optimized w/ OR

  function [31:0] func_sigma0_32(input [31:0] fva); func_sigma0_32 = { fva[1:0], fva[31:2] } ^ { fva[12:0], fva[31:13] } ^ { fva[21:0], fva[31:22] }; endfunction
  function [31:0] func_sigma1_32(input [31:0] fve); func_sigma1_32 = { fve[5:0], fve[31:6] } ^ { fve[10:0], fve[31:11] } ^ { fve[24:0], fve[31:25] }; endfunction
  function [31:0] func_alpha0_32(input [31:0] fww); func_alpha0_32 = { fww[6:0], fww[31:7] } ^ { fww[17:0], fww[31:18] } ^ { 3'h0, fww[31:3] }; ; endfunction
  function [31:0] func_alpha1_32(input [31:0] fww); func_alpha1_32 = { fww[16:0],fww[31:17] } ^ { fww[18:0], fww[31:19] } ^ { 10'h0, fww[31:10] }; endfunction

  function [63:0] func_sigma0_64(input [63:0] fva); func_sigma0_64 = { fva[27:0],fva[63:28] } ^ { fva[33:0], fva[63:34] } ^ { fva[38:0], fva[63:39] }; endfunction
  function [63:0] func_sigma1_64(input [63:0] fve); func_sigma1_64 = { fve[13:0],fve[63:14] } ^ { fve[17:0], fve[63:18] } ^ { fve[40:0], fve[63:41] }; endfunction
  function [63:0] func_alpha0_64(input [63:0] fww); func_alpha0_64 = { fww[   0],fww[63: 1] } ^ { fww[ 7:0], fww[63: 8] } ^ {  7'h0, fww[63:7] }; ; endfunction
  function [63:0] func_alpha1_64(input [63:0] fww); func_alpha1_64 = { fww[18:0],fww[63:19] } ^ { fww[60:0], fww[63:61] } ^ {  6'h0, fww[63:6] }; endfunction


    logic [63:0] sigma0, sigma1, alpha0, alpha1;

    assign sigma0 = thecfg.d32 ? func_sigma0_32( va[31:0] ) | 64'h0 : func_sigma0_64( va[63:0] );
    assign sigma1 = thecfg.d32 ? func_sigma1_32( ve[31:0] ) | 64'h0 : func_sigma1_64( ve[63:0] );
    assign alpha0 = thecfg.d32 ? func_alpha0_32( ramrdatreg[31:0] ) | 64'h0 : func_alpha0_64( ramrdatreg[63:0] );
    assign alpha1 = thecfg.d32 ? func_alpha1_32( ramrdatreg[31:0] ) | 64'h0 : func_alpha1_64( ramrdatreg[63:0] );

    assign mregpre = hashrndcycpl2 == 0 | hashrndcycpl2 == 4 ? ramrdatreg :
                     hashrndcycpl2 == 1 ? alpha0 + mreg :
                     hashrndcycpl2 == 3 ? alpha1 + mreg :
                                          ramrdatreg + mreg ; // for hashrndcycpl2 = 2 or 4

//        `theregrn( mregwr ) <= d64tog ? ( ( hashrndcycpl1 == 0 ) ? 1 : ( hashrndcycpl1 == 4 ) ? 0 : mregwr ) : mregwr ;
    `theregrn( mregwr ) <= d64tog ? ( ( hashrndcycpl1 == 0 ) ? 1 : ( hashrndcycpl1 == 6 ) ? 0 : mregwr ) : mregwr ;

    bit [63:0] fmaj, fch;
    assign fmaj = func_maj( va, vb, vc );
    assign fch  = func_ch( ve, vf, vg );

    assign vapre = sigma0 + func_maj( va, vb, vc ) + vepre0;
    assign vbpre = va;
    assign vcpre = vb;
    assign vdpre = vc;
    assign vepre = vd + vepre0;
    assign vfpre = ve;
    assign vgpre = vf;
    assign vhpre = vg;
    assign vepre0 = mreg + func_ch( ve, vf, vg ) + sigma1 + vh;
/*
  function [31:0] func_sigma0(input [31:0] fva); func_sigma0 = { fva[1:0], fva[31:2] } ^ { fva[12:0], fva[31:13] } ^ { fva[21:0], fva[31:22] }; endfunction
  function [31:0] func_sigma1(input [31:0] fve); func_sigma1 = { fve[5:0], fve[31:6] } ^ { fve[10:0], fve[31:11] } ^ { fve[24:0], fve[31:25] }; endfunction
  function [31:0] func_maj(input [31:0] fva, input [31:0] fvb, input [31:0] fvc ); func_maj = ( fva & fvb ) ^ ( fva & fvc ) ^ ( fvb & fvc ); endfunction
  function [31:0] func_ch(input [31:0] fve, input [31:0] fvf, input [31:0] fvg ); func_ch = ( fve & fvf ) | ( ~fve & fvg ); endfunction  // XOR could be optimized w/ OR
  function [31:0] func_alpha0(input [31:0] fww); func_alpha0 = { fww[6:0], fww[31:7] } ^ { fww[17:0], fww[31:18] } ^ { 3'h0, fww[31:3] }; ; endfunction
  function [31:0] func_alpha1(input [31:0] fww); func_alpha1 = { fww[16:0], fww[31:17] } ^ { fww[18:0], fww[31:19] } ^ { 10'h0, fww[31:10] }; endfunction

    assign mregpre = hashrndcycpl2 == 0 | hashrndcycpl2 == 4 ? ramrdatreg :
                     hashrndcycpl2 == 1 ? func_alpha0( ramrdatreg ) + mreg :
                     hashrndcycpl2 == 3 ? func_alpha1( ramrdatreg ) + mreg :
                                          ramrdatreg + mreg ; // for hashrndcycpl2 = 2 or 4

//        `theregrn( mregwr ) <= ( hashrndcycpl1 == 0 ) ? 1 : ( hashrndcycpl1 == 4 ) ? 0 : mregwr;
    `theregrn( mregwr ) <= ( hashrndcyc == 1 ) ? 1 : ( hashrndcycpl1 == 6 ) ? 0 : mregwr;

    assign vapre = func_sigma0( va ) + func_maj( va, vb, vc ) + vepre0;
    assign vbpre = va;
    assign vcpre = vb;
    assign vdpre = vc;
    assign vepre = vd + vepre0;
    assign vfpre = ve;
    assign vgpre = vf;
    assign vhpre = vg;
    assign vepre0 = mreg + func_ch( ve, vf, vg ) + func_sigma1( ve ) + vh;
*/
endmodule

module hashcore_hout#(
        parameter AW = 10,
        parameter VREGCNT = 16,
        parameter RAMSEG_ST = 0
    )(
        input  logic               clk,
        input  logic               resetn,

        input  hashcfg_t            thecfg,
        input  logic                cfg_firsthash,
        input  logic                mfsm_out_pl1,
        input  logic                mfsm_out_pl2,
        input  logic [4:0]          mfsm_outcnt,
        input  logic [4:0]          mfsm_outcntpl1,
        input  logic                d64tog,
        input   bit [7:0]       cfg_blkt0,
        input  logic [AW-1:0] ramseg_h,
        input  logic [63:0]   ramrdatreg,
        output logic [AW-1:0] rambase,
        output logic [AW-1:0] ramptr,
        output logic          ramwr,
        output logic [63:0]   ramwdat,

        input  logic [0:VREGCNT-1][63:0]   vreg,
        output logic [0:VREGCNT-1]         vregwr,
        output logic [0:VREGCNT-1][63:0]   vregpre

    );


    bit [0:VREGCNT-1][63:0]   vregpre_m0, vregpre_m1, vregpre_m2;
    bit [0:VREGCNT-1]         vregwr_m0,  vregwr_m1 , vregwr_m2 ;

    logic [AW-1:0] rambase_m0,   rambase_m1   , rambase_m2   ;
    logic [AW-1:0] ramptr_m0,    ramptr_m1    , ramptr_m2    ;
    logic          ramwr_m0,     ramwr_m1     , ramwr_m2     ;
    logic [63:0]   ramwdat_m0,   ramwdat_m1   , ramwdat_m2   ;


// mode 0: ramrdatreg + vreg


    assign rambase_m0 = cfg_firsthash ? ramseg_h : RAMSEG_ST;
    assign ramptr_m0  = mfsm_outcnt;
    assign ramwr_m0   = 0;
    assign ramwdat_m0 = 0;

    `theregrn( vregwr_m0 ) <= d64tog ? (( mfsm_out_pl1 & (mfsm_outcntpl1 == 0) ) ? 2**(VREGCNT-1) : vregwr_m0 / 2 ) : vregwr_m0;

    assign vregpre_m0[7] = vreg[7] + ramrdatreg; //xor
    assign vregpre_m0[6] = vreg[6] + ramrdatreg; //xor
    assign vregpre_m0[5] = vreg[5] + ramrdatreg; //xor
    assign vregpre_m0[4] = vreg[4] + ramrdatreg; //xor
    assign vregpre_m0[3] = vreg[3] + ramrdatreg; //xor
    assign vregpre_m0[2] = vreg[2] + ramrdatreg; //xor
    assign vregpre_m0[1] = vreg[1] + ramrdatreg; //xor
    assign vregpre_m0[0] = vreg[0] + ramrdatreg; //xor

// mode 1
    logic [AW-1:0] ramptr_m1_cnt;
    logic [AW-1:0] msglen;
    logic thecfg_blk3;
    assign msglen = cfg_blkt0;//thecfg.d32 ? 'h40 : 'h80;
    assign thecfg_blk3 = thecfg.hashtype == HT_BLK3;

    assign ramptr_m1_cnt = 'd12;
    assign rambase_m1 = RAMSEG_ST;
    assign ramptr_m1  = mfsm_outcnt[3] ? ramptr_m1_cnt : mfsm_outcnt[2:0] ;
    assign ramwr_m1   = mfsm_outcnt == 'd10;
    assign ramwdat_m1 = ramrdatreg + msglen;

    assign rambase_m2 = rambase_m0 ;
    assign ramptr_m2  = ( mfsm_outcnt == 4 ) ? 0: mfsm_outcnt+1;
    assign ramwr_m2   = '0;//mfsm_outcnt == 'd10;
    assign ramwdat_m2 = '0;//ramrdatreg + msglen;

    `theregrn( vregwr_m1[0:7] ) <= d64tog ? (( mfsm_out_pl1 & (mfsm_outcntpl1 == 0) ) ? 2**7 : vregwr_m1[0:7] / 2 ) : vregwr_m1[0:7];
    `theregrn( vregwr_m1[8:15] ) <= '0;

    logic [63:0] blkh;
    assign blkh = thecfg_blk3 ? 64'h0 : ramrdatreg;
    assign vregpre_m1[7] = vreg[7] ^ vreg[7+8] ^ blkh; //xor
    assign vregpre_m1[6] = vreg[6] ^ vreg[6+8] ^ blkh; //xor
    assign vregpre_m1[5] = vreg[5] ^ vreg[5+8] ^ blkh; //xor
    assign vregpre_m1[4] = vreg[4] ^ vreg[4+8] ^ blkh; //xor
    assign vregpre_m1[3] = vreg[3] ^ vreg[3+8] ^ blkh; //xor
    assign vregpre_m1[2] = vreg[2] ^ vreg[2+8] ^ blkh; //xor
    assign vregpre_m1[1] = vreg[1] ^ vreg[1+8] ^ blkh; //xor
    assign vregpre_m1[0] = vreg[0] ^ vreg[0+8] ^ blkh; //xor

//vregpre_m1
//vregwr_m1

    assign vregpre_m2[0] = vreg[2+6][31:0]+vreg[3+6][63:32]+ramrdatreg;
    assign vregpre_m2[1] = vreg[3+6][31:0]+vreg[4+6][63:32]+ramrdatreg;
    assign vregpre_m2[2] = vreg[4+6][31:0]+vreg[0+6][63:32]+ramrdatreg;
    assign vregpre_m2[3] = vreg[0+6][31:0]+vreg[1+6][63:32]+ramrdatreg;
    assign vregpre_m2[4] = vreg[1+6][31:0]+vreg[2+6][63:32]+ramrdatreg;

// mode

    assign vregpre = thecfg.outmode == 0 ? vregpre_m0 :
                     thecfg.outmode == 1 ? vregpre_m1 : vregpre_m2;
    assign vregwr  = thecfg.outmode == 0 ? vregwr_m0  : vregwr_m1 ;

    assign { rambase, ramptr, ramwr, ramwdat } =
                    ( thecfg.outmode == 0 ) ? { rambase_m0, ramptr_m0, ramwr_m0, ramwdat_m0 } :
                    ( thecfg.outmode == 1 ) ? { rambase_m1, ramptr_m1, ramwr_m1, ramwdat_m1 } :
                                              { rambase_m2, ramptr_m2, ramwr_m2, ramwdat_m2 } ;

endmodule
