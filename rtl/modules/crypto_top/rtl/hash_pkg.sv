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

//import scedma_pkg::*;

package hash_pkg;

	localparam int HASHTYPECNT = 9;

	typedef logic [$clog2(HASHTYPECNT)-1:0] hashtype_t;

	typedef enum  hashtype_t {
		HT_NONE      = 'd0,
		HT_SHA256    = 'd1,
		HT_SHA512    = 'd2,
		HT_RIPMD     = 'd3,
		HT_BLK2s     = 'd4,
        HT_BLK2b     = 'd5,
        HT_BLK3      = 'd6,
		HT_SHA3      = 'd7,
		HT_CHACHA    = 'd8
	} hashtype_e;

    typedef enum  bit[2:0] {
        CORE_NONE,
        CORE_SHA2,
        CORE_BLK,
        CORE_SHA3,
        CORE_RIPMD
    } coresel_e;

    typedef struct packed {
		hashtype_e	hashtype;
		bit [7:0]	incnt;
        bit [7:0]   rndcnt;
        bit [7:0]   outcnt;
        bit [7:0]   wbcnt;
        bit [7:0]   rndcyc;
        bit [2:0]   inmode;
        bit [2:0]   outmode;
		bit			d32;
		coresel_e	coresel;
    }hashcfg_t;

  localparam hashcfg_t [0:HASHTYPECNT-1] HASHCFGs = '{
    '{hashtype: HT_NONE,   incnt:  8'd2, rndcnt:  8'd2, outcnt:  8'd2, wbcnt:  8'd2, rndcyc:  8'd2, inmode: 3'h0, outmode: 3'h0, d32: 1'b1, coresel: CORE_NONE  },
    '{hashtype: HT_SHA256, incnt:  8'd8, rndcnt: 8'd64, outcnt:  8'd8, wbcnt:  8'd8, rndcyc:  8'd8, inmode: 3'h0, outmode: 3'h0, d32: 1'b1, coresel: CORE_SHA2  },
    '{hashtype: HT_SHA512, incnt:  8'd8, rndcnt: 8'd80, outcnt:  8'd8, wbcnt:  8'd8, rndcyc:  8'd8, inmode: 3'h0, outmode: 3'h0, d32: 1'b0, coresel: CORE_SHA2  },
    '{hashtype: HT_RIPMD,  incnt:  8'd5, rndcnt: 8'd90, outcnt:  8'd5, wbcnt:  8'd5, rndcyc:  8'd5, inmode: 3'h0, outmode: 3'h2, d32: 1'b1, coresel: CORE_RIPMD },
    '{hashtype: HT_BLK2s,  incnt: 8'd24, rndcnt: 8'd10, outcnt: 8'd11, wbcnt:  8'd8, rndcyc: 8'd20, inmode: 3'h1, outmode: 3'h1, d32: 1'b1, coresel: CORE_BLK   },
    '{hashtype: HT_BLK2b,  incnt: 8'd24, rndcnt: 8'd12, outcnt: 8'd11, wbcnt:  8'd8, rndcyc: 8'd20, inmode: 3'h1, outmode: 3'h1, d32: 1'b0, coresel: CORE_BLK   },
    '{hashtype: HT_BLK3,   incnt: 8'd20, rndcnt:  8'd7, outcnt: 8'd10, wbcnt:  8'd8, rndcyc: 8'd20, inmode: 3'h1, outmode: 3'h1, d32: 1'b1, coresel: CORE_BLK   },
    '{hashtype: HT_SHA3,   incnt:  8'd2, rndcnt: 8'd121, outcnt:  8'd8, wbcnt:  8'd8, rndcyc: 8'd48, inmode: 3'h0, outmode: 3'h0, d32: 1'b0, coresel: CORE_SHA3  },
    '{hashtype: HT_CHACHA, incnt: 8'd16, rndcnt: 8'd14, outcnt:  8'd8, wbcnt:  8'd8, rndcyc: 8'd80, inmode: 3'h0, outmode: 3'h0, d32: 1'b0, coresel: CORE_BLK   }
  };
/*
    localparam RAMSEG_SHA256_H   = 0 ;
    localparam RAMSEG_SHA256_K   = RAMSEG_SHA256_H   + 8    ;
    localparam RAMSEG_SHA512_H   = RAMSEG_SHA256_K   + 64   ;
    localparam RAMSEG_SHA512_K   = RAMSEG_SHA512_H   + 8*2  ;
    localparam RAMSEG_RIPMD_H    = RAMSEG_SHA512_K   + 80*2 ;
    localparam RAMSEG_RIPMD_K    = RAMSEG_RIPMD_H    + 6    ;
    localparam RAMSEG_RIPMD_X    = RAMSEG_RIPMD_K    + 10   ;
    localparam RAMSEG_BLK2s_H    = RAMSEG_RIPMD_X    + 40   ;
    localparam RAMSEG_BLK2s_X    = RAMSEG_BLK2s_H    + 8    ;
    localparam RAMSEG_BLK2b_H    = RAMSEG_BLK2s_X    + 20   ;
    localparam RAMSEG_BLK2b_X    = RAMSEG_BLK2b_H    + 16   ;
    localparam RAMSEG_BLK3_H     = RAMSEG_BLK2b_X    + 12   ;
    localparam RAMSEG_BLK3_X     = RAMSEG_BLK3_H     + 16   ;
    localparam RAMSEG_CHACHA20_H = RAMSEG_BLK3_X     + 24   ;
    localparam RAMSEG_CHACHA20_K = RAMSEG_CHACHA20_H + 50   ;
    localparam RAMSEG_ST         = 'h200 ;
    localparam RAMSEG_MSG        = RAMSEG_ST + 32 ;
*/

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
    localparam RAMSEG_CHACHA20_H = RAMSEG_SHA3_P1    + 48   ;
    localparam RAMSEG_ST         = 'h200 ;
    localparam RAMSEG_MSG        = RAMSEG_ST + 32 ;



    typedef logic [7:0] hashfunc_t;

    typedef enum hashfunc_t {
        HF_SHA256          = 'h00,
        HF_SHA512          = 'h01,
        HF_RIPMD           = 'h02,
        HF_BLK2s           = 'h03,
        HF_BLK2b           = 'h04,
        HF_BLK3            = 'h05,
        HF_SHA3            = 'h06,
        HF_HMAC256_KEYHASH = 'h40,
        HF_HMAC256_PASS1   = 'h50,
        HF_HMAC256_PASS2   = 'h60,
        HF_HMAC512_KEYHASH = 'h41,
        HF_HMAC512_PASS1   = 'h51,
        HF_HMAC512_PASS2   = 'h61,
        HF_INIT            = 'hff
    } hashfunc_e;

    typedef struct packed {
        bit [15:0]  hashcnt;
        bit         ifstart;
        bit         ifsob;
        bit         scrtchk;
        bit         ifskey;
    }hashfuncopt_t;

endpackage : hash_pkg
