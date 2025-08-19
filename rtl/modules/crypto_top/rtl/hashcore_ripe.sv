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

module hashcore_ripe #(
        parameter AW = 10,
        parameter [AW-1:0] RAMSEG_MSG = 32
    )(
        input  logic               clk,
        input  logic               resetn,

        input  hashcfg_t           thecfg,
        input  logic               start,
//        input  logic               mfsm_hash,
//        input  logic [7:0]         hashrnd,
//        input  logic [5:0]         hashrndcyc,
//        input  logic [5:0]         hashrndcycpl1,
//        input  logic [5:0]         hashrndcycpl2,

        input  logic [63:0]   ramrdatreg,
        output logic [AW-1:0] rambase,
        output logic [AW-1:0] ramptr,
        output logic          ramwr,
        output logic [63:0]   ramwdat,

        input  logic [0:15][63:0]   vreg,
        output logic [0:15]         vregwr,
        output logic [0:15][63:0]   vregpre

    );

    localparam HASHTYPECNT 		 = hash_pkg::HASHTYPECNT;
    localparam RAMSEG_RIPMD_H    = hash_pkg::RAMSEG_RIPMD_H  ;
    localparam RAMSEG_RIPMD_K    = hash_pkg::RAMSEG_RIPMD_K  ;
    localparam RAMSEG_RIPMD_X    = hash_pkg::RAMSEG_RIPMD_X  ;

    localparam hashcfg_t [0:HASHTYPECNT-1] theHASHCFGs = hash_pkg::HASHCFGs;

// fsm
// ■■■■■■■■■■■■■■■

	bit [3:0] hashrnd, hashrndcyc;
	bit [4:0] hashrnd2;
	bit [3:0] hashrndpl1, hashrndcycpl1;
	bit [4:0] hashrnd2pl1;
	bit [3:0] hashrndpl2, hashrndcycpl2;
	bit [4:0] hashrnd2pl2;
	bit hashbusy;
	bit [0:1][3:0] msgptr;
	bit startpl3, startpl2, startpl1;

    `theregrn( hashrnd    ) <= start ? 'h1 : ( hashrndcyc == 4 ) & ( hashrnd2 == 17 ) ? (( hashrnd == 'h5 ) ? '0 : ( hashrnd + 1 )) : hashrnd;
    `theregrn( hashrnd2   ) <= start ? 'h0 : ( hashrndcyc == 4 ) ? (( hashrnd2 == 17 ) ? '0 : ( hashrnd2 + 1 )) : hashrnd2;
    `theregrn( hashrndcyc ) <= start ? 'h0 : ( hashrndcyc == 4 ) ? '0 : ( hashrndcyc + hashbusy );
    assign hashbusy = ~( hashrnd == 0 );

    `theregrn( { hashrndpl1, hashrndpl2, hashrnd2pl1, hashrnd2pl2, hashrndcycpl1, hashrndcycpl2 } ) <= { hashrnd, hashrndpl1, hashrnd2, hashrnd2pl1, hashrndcyc, hashrndcycpl1 };
    `theregrn( { startpl3, startpl2, startpl1 }) <= { startpl2, startpl1, start };
// ctrl
// ■■■■■■■■■■■■■■■

	bit hashrndcyc_sr, hashrndcyc_kk;
	bit [AW-1:0] ramptr_xx, ramptr_sr, ramptr_kk;

	assign hashrndcyc_sr = (( hashrnd2 == 0 ) | ( hashrnd2 == 1 )) & ( hashrndcyc != 4 ) & hashbusy;
	assign hashrndcyc_kk = (( hashrnd2 == 0 ) | ( hashrnd2 == 1 )) & ( hashrndcyc == 4 );
	assign ramptr_xx = ( hashrndcyc == 0 ) ? msgptr[0] : msgptr[1];
	`theregrn( ramptr_sr ) <= start ? '0 : ramptr_sr + hashrndcyc_sr;
	`theregrn( ramptr_kk ) <= start ? '0 : ramptr_kk + hashrndcyc_kk;

    assign { rambase, ramptr } = hashrndcyc_sr   ? { RAMSEG_RIPMD_X , ramptr_sr } :
    				 			 hashrndcyc_kk   ? { RAMSEG_RIPMD_K , ramptr_kk } :
    				 							   { RAMSEG_MSG ,     ramptr_xx } ;

	assign ramwr = '0;
    assign ramwdat = '0;



	bit hashrndcycpl2_varot4, hashrndcycpl2_varot2, hashrndcycpl2_shift;
	assign hashrndcycpl2_varot4 = ( hashrnd2pl2 > 1 ) && ( hashrndcycpl2 == 2 );
	assign hashrndcycpl2_varot2 = ( hashrnd2pl2 > 1 ) && ( hashrndcycpl2 == 3 );
	assign hashrndcycpl2_shift = ( hashrnd2pl2 > 1 ) && ( hashrndcycpl2 == 4 );

generate
	for (genvar i = 0; i < 2; i++) begin: gRND16

		bit [2:0] ffidx;
		bit [0:4][31:0] ff;
		bit [63:0]  vs, vspre, vr, vrpre;
		bit [31:0] 	va, vb, vc, vd, ve, vk, vapre, vbpre, vcpre, vdpre, vepre, vkpre, va2, vapre2,
					vapre_ffadd, vapre_ffaddrot8, vapre_rot4, vapre_rot2, vapre_rot1;
		bit hashrndcycpl2_vaadd;
		bit vs_8, vs_4, vs_2, vs_1;
		bit vkwr, vswr0, vswr1, vrwr0, vrwr1, vrrhift, vsshift;
		bit vawr;

		assign vswr0  = ( hashrnd2pl2 == i ) && ( hashrndcycpl2 == 0 ) & ~( hashrndpl2 == 0 );;
		assign vswr1  = ( hashrnd2pl2 == i ) && ( hashrndcycpl2 == 1 );
		assign vrwr0  = ( hashrnd2pl2 == i ) && ( hashrndcycpl2 == 2 );
		assign vrwr1  = ( hashrnd2pl2 == i ) && ( hashrndcycpl2 == 3 );
		assign vkwr   = ( hashrnd2pl2 == i ) && ( hashrndcycpl2 == 4 );
		assign vrrhift = ( hashrnd2 > 1 )   && ( hashrndcyc == 2 );
		assign vsshift = ( hashrnd2pl2 > 1 ) && ( hashrndcycpl2 == 4 );

		assign hashrndcycpl2_vaadd = ( hashrnd2pl2 > 1 ) && ( hashrndcycpl2 == i );

		assign vkpre = vkwr ? ramrdatreg : vk;
		assign vspre = vsshift ? vs*16 : { ( vswr0 ? ramrdatreg[31:0] : vs[63:32] ), ( vswr1 ? ramrdatreg[31:0] : vs[31:0] )};
		assign vrpre = vrrhift ? vr*16 : { ( vrwr0 ? ramrdatreg[31:0] : vr[63:32] ), ( vrwr1 ? ramrdatreg[31:0] : vr[31:0] )};
		assign { vs_8, vs_4, vs_2, vs_1 } = vs[63:60];
		assign msgptr[i] = vr[63:60];

		assign ffidx = i ? ( 4 - hashrndpl2 + 1 ) : hashrndpl2 - 1;
		assign ff[0] = vb ^ vc ^ vd  ;
		assign ff[1] = (vb & vc) | (~vb & vd ) ;
		assign ff[2] = (vb | ~vc) ^ vd  ;
		assign ff[3] = (vb & vd ) | (vc & ~vd ) ;
		assign ff[4] = vb ^ (vc | ~vd ) ;

		assign vapre_ffadd = ( va + ff[ffidx] + vk + ramrdatreg );
		assign vapre_ffaddrot8 = vs_8 ? { vapre_ffadd, vapre_ffadd[31:24] } : vapre_ffadd;
		assign vapre_rot4 = vs_4 ? { va,va[31:28] } : va;
		assign vapre_rot2 = vs_2 ? { va,va[31:30] } : va;
		assign vapre_rot1 = vs_1 ? { va,va[31] } : va;

		assign vapre =  hashrndcycpl2_vaadd ? 	vapre_ffaddrot8 :
						hashrndcycpl2_varot4 ?  vapre_rot4 :
						hashrndcycpl2_varot2 ?  vapre_rot2 :
						hashrndcycpl2_shift ? 	ve :
												va;
		assign vbpre = startpl3? {vreg[1][31:0],vreg[1][31:0]} : hashrndcycpl2_shift ? vapre_rot1 + ve : vb;
		assign vcpre = startpl3? {vreg[2][31:0],vreg[2][31:0]} : hashrndcycpl2_shift ? vb : vc;
		assign vdpre = startpl3? {vreg[3][31:0],vreg[3][31:0]} : hashrndcycpl2_shift ? { vc, vc[31:22] } : vd;
		assign vepre = startpl3? {vreg[4][31:0],vreg[4][31:0]} : hashrndcycpl2_shift ? vd : ve;

		assign vapre2 = hashrndcycpl2_shift ? 	ve : va2;


		assign vawr = hashrndcycpl2_vaadd | hashrndcycpl2_varot4 | hashrndcycpl2_varot2 | hashrndcycpl2_shift;

		`theregrn( va ) <= startpl3 ? {vreg[0][31:0],vreg[0][31:0]} : vawr ? vapre : va;
		assign va2= vreg[6][i*32+31:i*32];
		assign vb = vreg[7][i*32+31:i*32];
		assign vc = vreg[8][i*32+31:i*32];
		assign vd = vreg[9][i*32+31:i*32];
		assign ve = vreg[10][i*32+31:i*32];
		assign vk = vreg[11][i*32+31:i*32];
		assign vs = vreg[12+i];
		assign vr = vreg[14+i];

		assign vregpre[6][i*32+31:i*32]  = vapre2 ;
		assign vregpre[7][i*32+31:i*32]  = vbpre ;
		assign vregpre[8][i*32+31:i*32]  = vcpre ;
		assign vregpre[9][i*32+31:i*32]  = vdpre ;
		assign vregpre[10][i*32+31:i*32] = vepre ;
		assign vregpre[11][i*32+31:i*32] = vkpre ;
		assign vregpre[12+i]             = vspre ;
		assign vregpre[14+i]             = vrpre ;

		assign vregwr[12+i] = vswr0|vswr1|vsshift;
		assign vregwr[14+i] = vrwr0|vrwr1|vrrhift;

	end
endgenerate

	assign vregwr[6]    = hashrndcycpl2_shift;

	assign vregwr[7]    = startpl3 | hashrndcycpl2_shift;
	assign vregwr[8]    = startpl3 | hashrndcycpl2_shift;
	assign vregwr[9]    = startpl3 | hashrndcycpl2_shift;
	assign vregwr[10]   = startpl3 | hashrndcycpl2_shift;
	assign vregwr[11]   = ( hashrnd2pl2 < 2 ) && ( hashrndcycpl2 == 4 );

	assign vregwr[0:5]  = '0;
	assign vregpre[0:5] = '0;

endmodule
