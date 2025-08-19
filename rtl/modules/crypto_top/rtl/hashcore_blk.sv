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


module hashcore_blk#(
        parameter AW = 10,
        parameter [AW-1:0] RAMSEG_MSG = 32,
        parameter [AW-1:0] RAMSEG_BLK2_X = 32,
//        parameter [AW-1:0] RAMSEG_BLK2b_X = 32,
        parameter [AW-1:0] RAMSEG_BLK3_X = 32
    )(
        input  logic               clk,
        input  logic               resetn,

        input  hashcfg_t           thecfg,
        input  logic               start,
        input  logic               mfsm_hash,
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

        input  logic [0:15][63:0]   vreg,
        output logic [0:15]         vregwr,
        output logic [0:15][63:0]   vregpre

    );

    logic cfgd64;
    logic ramcp_x, ramcp_m, ramcp_x_pl1, ramcp_x_pl2, ramcp_m_pl1, ramcp_m_pl2;
    logic [AW-1:0] ramptr_x, ramptr_m, ramseg_x;
    logic msgptrld1, msgptrld2, msgptrshf;
    logic [2:0] gidx, gidxpl1, gidxpl2;
    logic [0:3][3:0] vidxpl1, vidxpl2;
    logic [63:0] msgptr;

// cfg
// ■■■■■■■■■■■■■■■

    assign cfgd64 = ~thecfg.d32;
    assign ramseg_x = ( thecfg.hashtype == HT_BLK2s ) ? RAMSEG_BLK2_X :
                      ( thecfg.hashtype == HT_BLK2b ) ? RAMSEG_BLK2_X :
                                                        RAMSEG_BLK3_X ;

// ctrl
// ■■■■■■■■■■■■■■■

    assign ramcp_x = mfsm_hash & (( hashrndcyc == 0 ) | ~cfgd64 & ( hashrndcyc == 1 ));
    `theregrn( ramcp_x_pl1 ) <= d64tog ? ramcp_x : ramcp_x_pl1;
    `theregrn( ramcp_x_pl2 ) <= d64tog ? ramcp_x_pl1 : ramcp_x_pl2;
    `theregrn( ramcp_m ) <= ~mfsm_hash ? '0 : d64tog & ( hashrndcyc == 3 ) ? 'b1 : d64tog & ( hashrndcyc == thecfg.rndcyc-1 ) ? 'b0 : ramcp_m ;
    `theregrn( ramcp_m_pl1 ) <= d64tog ? ramcp_m : ramcp_m_pl1;
    `theregrn( ramcp_m_pl2 ) <= d64tog ? ramcp_m_pl1 : ramcp_m_pl2;

    assign rambase = ( hashrndcyc == 0 ) | ( hashrndcyc == 1 ) ? ramseg_x : RAMSEG_MSG;
    assign ramptr = ramcp_x ? ramptr_x : ramptr_m;

    `theregrn( ramptr_x ) <= ~mfsm_hash ? 0 : ramcp_x & d64tog ? ( cfgd64 & ( ramptr_x == 9 ) | ramptr_x == 19 ? 0 : ramptr_x + 1 ) : ramptr_x;
    assign ramptr_m = msgptr[63:60] | 0;

    assign msgptrld1 = ramcp_x_pl2;
    assign msgptrld2 = ramcp_x_pl2 & ~ramcp_x_pl1 & ~cfgd64;
    assign msgptrshf = ramcp_m;

    `theregrn( msgptr ) <=  msgptrshf & d64tog ? ( msgptr << 4 )  :  
                                                  cfgd64 & ramcp_x_pl2 & d64tog ? ramrdatreg : 
                                                 ~cfgd64 & msgptrld2 ? {msgptr[63:32], ramrdatreg[31:0]} :
                                                  msgptrld1 ? {ramrdatreg, msgptr[31:0] }: 
                                                                            msgptr ;

    assign ramwr = '0;
    assign ramwdat = '0;

// G idx
// ==

    assign gidx = ( hashrndcyc - 4 ) / 2;
    always_comb begin
        case (gidxpl1)
            'h0 : vidxpl1 = 'h048c;
            'h1 : vidxpl1 = 'h159d;
            'h2 : vidxpl1 = 'h26ae;
            'h3 : vidxpl1 = 'h37bf;
            'h4 : vidxpl1 = 'h05af;
            'h5 : vidxpl1 = 'h16bc;
            'h6 : vidxpl1 = 'h278d;
            default :
                  vidxpl1 = 'h349e;
        endcase
    end

    `theregrn( { gidxpl2, gidxpl1 } ) <= d64tog ? { gidxpl1, gidx } : { gidxpl2, gidxpl1 };
    `theregrn( vidxpl2 ) <= d64tog ? vidxpl1 : vidxpl2;

// gfunc
// ■■■■■■■■■■■■■■■

    logic [0:3][63:0] gvi,gvo;
    logic [63:0] va0, vd0, vd1a, vd1b, vd1, vc0, vb0, vb1a, vb1b, vb1;
    logic gtog;

    function bit [31:0] frr32 ( bit [31:0] fv, int fn);
        bit [31:0] tmpbit;
        tmpbit = ( fv << ( 32-fn ) ) | ( fv >> fn );
        return tmpbit;
    endfunction  

    function bit [63:0] frr64 ( bit [63:0] fv, int fn);
        bit [63:0] tmpbit;
        tmpbit = ( fv << ( 64-fn ) ) | ( fv >> fn );
        return tmpbit;
    endfunction  

    assign gvi[0] = vreg[vidxpl2[0]];
    assign gvi[1] = vreg[vidxpl2[1]];
    assign gvi[2] = vreg[vidxpl2[2]];
    assign gvi[3] = vreg[vidxpl2[3]];

// 32/24/16/63
// 16/12/8/7
    assign gtog = ~hashrndcycpl2[0];

    assign va0 = gvi[0] + gvi[1] + ramrdatreg;
    assign vd0 = gvi[3] ^ va0;
    assign vd1a = gtog ? frr32 ( vd0[31:0], 16 ) : frr32 ( vd0[31:0], 8  );
    assign vd1b = gtog ? frr64 ( vd0, 32 ) : frr64 ( vd0, 16 );
    assign vd1 = cfgd64 ? vd1b : vd1a;
    assign vc0 = gvi[2] + vd1;
    assign vb0 = gvi[1] ^ vc0;
    assign vb1a = gtog ? frr32 ( vb0[31:0], 12 ) : frr32 ( vb0[31:0], 7  );
    assign vb1b = gtog ? frr64 ( vb0, 24 ) : frr64 ( vb0, 63 );
    assign vb1 = cfgd64 ? vb1b : vb1a;

    assign gvo = { va0, vb1, vc0, vd1 };

`ifdef SIM
/*
v[00] = 0x6a09e667f2bdc948  v[01] = 0xbb67ae8584caa73b  v[02] = 0x3c6ef372fe94f82b  v[03] = 0xa54ff53a5f1d36f1
v[04] = 0x510e527fade682d1  v[05] = 0x9b05688c2b3e6c1f  v[06] = 0x1f83d9abfb41bd6b  v[07] = 0x5be0cd19137e2179
v[08] = 0x6a09e667f3bcc908  v[09] = 0xbb67ae8584caa73b  v[10] = 0x3c6ef372fe94f82b  v[11] = 0xa54ff53a5f1d36f1
v[12] = 0x510e527fade682d2  v[13] = 0x9b05688c2b3e6c1f  v[14] = 0xe07c265404be4294  v[15] = 0x5be0cd19137e217
*/
/*
00,04,08,12::76024d01 14a50838 4f685c10 f4c9848a 00000000 00000000 ::2d800655 c9e3c45b c6295331 bda6949a 
01,05,09,13::8c5cc5f9 a2541963 aa619624 fba726d4 00000000 00000000 ::715ebf08 3101f453 da2d2585 cb3215c7 
02,06,10,14::ac4c65b7 06232b8f 85a22f65 d5a851bd 00000000 00000000 ::4e91206f 49862d7f b8e29996 8924e48a 
03,07,11,15::d88c285f ab8b9c46 81539e5d 43d1a889 00636261 00000000 ::690f9253 0cfad099 62e90301 7c9d0df7 
00,05,10,15::2d800655 3101f453 b8e29996 7c9d0df7 00000000 00000000 ::e8faeadd 0d294cb9 8cec5669 87fea4f1 
01,06,11,12::715ebf08 49862d7f 62e90301 bda6949a 00000000 00000000 ::2c25d629 ad27debd 27d306fc 3bd7a537 
02,07,08,13::4e91206f 0cfad099 c6295331 cb3215c7 00000000 00000000 ::b94f8c0b 667287fe eefad8fc df67f026 
03,04,09,14::690f9253 c9e3c45b da2d2585 8924e48a 00000000 00000000 ::0db5cf35 b1aebc47 021526a4 b40f7e6d 
*/
    logic hashtypevld;
    assign hashtypevld = ( thecfg.hashtype == HT_BLK2b );
    logic gflag0, gflag1;
    logic [7:0]         hashrndpl1, hashrndpl2;
    assign gflag0 = ( hashrndcycpl2 > 3 ) & d64tog &  gtog & hashtypevld;
    assign gflag1 = ( hashrndcycpl2 > 3 ) & d64tog & ~gtog & hashtypevld;
    `theregrn( hashrndpl1 ) <= d64tog ? hashrnd : hashrndpl1;
    `theregrn( hashrndpl2 ) <= d64tog ? hashrndpl1 : hashrndpl2;
`ifdef BLKVERBOSE
    always@(posedge clk) begin
        if((hashrndcycpl2==3)&hashtypevld&d64tog) begin
            $write("v[00] = %016x  v[01] = %016x  v[02] = %016x  v[03] = %016x \n", vreg[00],vreg[01],vreg[02],vreg[03] );
            $write("v[04] = %016x  v[05] = %016x  v[06] = %016x  v[07] = %016x \n", vreg[04],vreg[05],vreg[06],vreg[07] );
            $write("v[08] = %016x  v[09] = %016x  v[10] = %016x  v[11] = %016x \n", vreg[08],vreg[09],vreg[10],vreg[11] );
            $write("v[12] = %016x  v[13] = %016x  v[14] = %016x  v[15] = %016x \n\n", vreg[12],vreg[13],vreg[14],vreg[15] );
        end
        if(gflag0) begin
            $write("@g(%02d:%02d): %02d %02d %02d %2d::", hashrndpl2, hashrndcycpl2, vidxpl2[0], vidxpl2[1], vidxpl2[2], vidxpl2[3] );
            $write("::%08x %08x %08x %08x %08x ", gvi[0][31:0], gvi[1][31:0], gvi[2][31:0], gvi[3][31:0], ramrdatreg[31:0]);
        end
        if(gflag1) begin
            $write("%08x ", ramrdatreg);
            $write("::%08x %08x %08x %08x \n", gvo[0][31:0], gvo[1][31:0], gvo[2][31:0], gvo[3][31:0]);
        end

    end
`endif

`endif

// vregwr
// ■■■■■■■■■■■■■■■

    logic vregwrvld;

    assign vregwrvld = ramcp_m_pl2;
    always_comb begin
        vregwr = '0;
        vregpre = vreg;
        vregwr[vidxpl2[0]] = vregwrvld & '1;
        vregwr[vidxpl2[1]] = vregwrvld & '1;
        vregwr[vidxpl2[2]] = vregwrvld & '1;
        vregwr[vidxpl2[3]] = vregwrvld & '1;
        vregpre[vidxpl2[0]] = gvo[0];
        vregpre[vidxpl2[1]] = gvo[1];
        vregpre[vidxpl2[2]] = gvo[2];
        vregpre[vidxpl2[3]] = gvo[3];
    end

endmodule
