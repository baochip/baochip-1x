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

`define theregfullce( theclk, theresetn, theregname, theinitvalue ) \
    always@( posedge theclk or negedge theresetn ) \
    if( ~theresetn) \
        theregname <= theinitvalue; \
    else if(~ce) \
        theregname <= theregname; \
    else \
        theregname

`define theregrnce(theregname) \
    `theregfullce( clk, resetn, theregname, '0 )

module hashcore_sha3#(
        parameter AW = 10,
        parameter RAMBASE_A = 0,
        parameter RAMBASE_B = 25,
        parameter RAMBASE_P0 = 50,
        parameter RAMBASE_P1 = 55
    )(
        input  logic               clk,
        input  logic               resetn,
        input  logic               ce,

        input logic start,
        output logic busy,
        output logic done,

        input  logic [63:0]   ramrdatreg,
        input  logic [63:0]   ramrdat,
        output logic [AW-1:0] rambase,
        output logic [AW-1:0] ramptr,
        output logic          ramwr,
        output logic          ramrd,
        output logic [63:0]   ramwdat,

        input  logic [0:4][63:0]   vreg,
        output logic [0:4]         vregwr,
        output logic [0:4][63:0]   vregpre

    );

    genvar x,y,z;

    parameter MFSM_IDLE = 8'h00;
    parameter MFSM_DONE = 8'hFF;
    parameter MFSM_ALG1A = 8'h1A;
    parameter MFSM_ALG1B = 8'h1B;
    parameter MFSM_ALG1C = 8'h1C;
    parameter MFSM_ALG2A = 8'h2A;
    parameter MFSM_ALG2B = 8'h2B;
    parameter MFSM_ALG2C = 8'h2C;
    parameter MFSM_ALG2D = 8'h2D;
    parameter MFSM_ALG4A = 8'h4A;
    parameter MFSM_ALG4B = 8'h4B;
    parameter MFSM_ALG4C = 8'h4C;
    parameter MFSM_ALG5A = 8'h5A;
    parameter MFSM_ALG5B = 8'h5B;

    logic [AW-1:0] rambase_alg1a,rambase_alg1c,rambase_alg2a,rambase_alg2b,rambase_alg2d,rambase_alg4a,rambase_alg4c,rambase_alg5a,rambase_alg5b;
    logic [AW-1:0] ramptr_alg1a, ramptr_alg1c, ramptr_alg2a, ramptr_alg2b, ramptr_alg2d, ramptr_alg4a, ramptr_alg4c, ramptr_alg5a, ramptr_alg5b;
    logic ramwr_alg1a, ramrd_alg1a, ramwr_alg1c, ramrd_alg1c, ramwr_alg2a, ramrd_alg2a, ramwr_alg2b, ramrd_alg2b, ramwr_alg2d, ramrd_alg2d, ramwr_alg4a, ramrd_alg4a, ramwr_alg4c, ramrd_alg4c, ramwr_alg5a, ramrd_alg5a, ramwr_alg5b, ramrd_alg5b;
    logic [63:0]   ramwdat_alg1a, ramwdat_alg1c, ramwdat_alg2a, ramwdat_alg2b, ramwdat_alg2d, ramwdat_alg4a, ramwdat_alg4c, ramwdat_alg5a, ramwdat_alg5b;
    logic [0:4][63:0] vregpre_alg1a, vregpre_alg1b, vregpre_alg1c, vregpre_alg2a, vregpre_alg2c, vregpre_alg2d, vregpre_alg4a, vregpre_alg4b, vregpre_alg4c;
    logic [0:4]       vregwr_alg1a, vregwr_alg1b, vregwr_alg1c, vregwr_alg2a, vregwr_alg2c, vregwr_alg2d, vregwr_alg4a, vregwr_alg4b, vregwr_alg4c;

    logic [7:0] mfsm, mfsmnext;
    logic mfsm_alg1adone, mfsm_alg1bdone, mfsm_alg1cdone, mfsm_alg2adone, mfsm_alg2ddone, mfsm_alg2bdone, mfsm_alg2cdone, mfsm_alg4adone, mfsm_alg4bdone, mfsm_alg4cdone, mfsm_alg5adone, mfsm_alg5bdone;
    logic alg2_lasty, alg4_lasty, lastrnd;
    logic mfsm_alg1a_prerise;

    logic [3:0] mfsm_alg1acycx, mfsm_alg1acycy, mfsm_alg1ccycx, mfsm_alg1ccycy, mfsm_alg2acycx, mfsm_alg2bcyc, mfsm_alg2ccyc, mfsm_alg2cycy, mfsm_alg4cycy, mfsm_alg2dcycx, mfsm_alg4acycx, mfsm_alg4ccycx, mfsm_alg5acyc, mfsm_alg5bcyc;
    logic [7:0] algrnd;
    logic ramrd_alg2bpl2, ramrd_alg2bpl1;

// mfsm

    `theregrnce( busy ) <= start ? '1 : done ? '0 : busy;
    assign done = ( mfsm == MFSM_DONE ) & ce;

    `theregrnce( mfsm ) <= mfsmnext;
    assign mfsmnext = start ? MFSM_ALG1A :
                         (( mfsm == MFSM_ALG1A ) &&  mfsm_alg1adone ) ? MFSM_ALG1B :
                         (( mfsm == MFSM_ALG1B ) &&  mfsm_alg1bdone ) ? MFSM_ALG1C :
                         (( mfsm == MFSM_ALG1C ) &&  mfsm_alg1cdone ) ? MFSM_ALG2B :
                         (( mfsm == MFSM_ALG2A ) &&  mfsm_alg2adone ) ? MFSM_ALG2C :
                         (( mfsm == MFSM_ALG2B ) &&  mfsm_alg2bdone ) ? MFSM_ALG2A :
                         (( mfsm == MFSM_ALG2C ) &&  mfsm_alg2cdone ) ? MFSM_ALG2D :
                         (( mfsm == MFSM_ALG2D ) &&  mfsm_alg2ddone ) ? ( alg2_lasty ? MFSM_ALG4A : MFSM_ALG2B ) :
                         (( mfsm == MFSM_ALG4A ) &&  mfsm_alg4adone ) ? MFSM_ALG4B :
                         (( mfsm == MFSM_ALG4B ) &&  mfsm_alg4bdone ) ? MFSM_ALG4C :
                         (( mfsm == MFSM_ALG4C ) &&  mfsm_alg4cdone ) ? ( alg4_lasty ? MFSM_ALG5A : MFSM_ALG4A ) :
//                         (( mfsm == MFSM_ALG5A ) &&  mfsm_alg5adone ) ? MFSM_ALG5B :
                         (( mfsm == MFSM_ALG5A ) &&  mfsm_alg5adone ) ? ( lastrnd ? MFSM_DONE : MFSM_ALG1A ) :
                         ( mfsm == MFSM_DONE ) ? MFSM_IDLE : mfsm;

    assign mfsm_alg1a_prerise = ( mfsm != MFSM_ALG1A ) && ( mfsmnext == MFSM_ALG1A );

    `theregrnce( mfsm_alg2cycy ) <= start ? '0 : (( mfsm == MFSM_ALG2D ) &&  mfsm_alg2ddone ) ? ( alg2_lasty ? 0 : mfsm_alg2cycy + 1 ) : mfsm_alg2cycy;
    `theregrnce( mfsm_alg4cycy ) <= start ? '0 : (( mfsm == MFSM_ALG4C ) &&  mfsm_alg4cdone ) ? ( alg4_lasty ? 0 : mfsm_alg4cycy + 1 ) : mfsm_alg4cycy;
    assign alg2_lasty = mfsm_alg2cycy == 4;
    assign alg4_lasty = mfsm_alg4cycy == 4;
    `theregrnce( algrnd ) <= start ? '0 : (( mfsm == MFSM_ALG5A ) &&  mfsm_alg5adone ) ? algrnd + 1 : algrnd;
    assign lastrnd = algrnd == 23;

    logic vregwr_alg1a_sft;
    logic [63:0] rc64;
    logic [0:4][5:0] alg2_sv, alg3_sv;
    logic [0:4][1:0] alg2c_sftcnt;
    logic [0:4] alg2_svsft, alg3_svsft, alg2c_sft16, alg2c_sft04, alg2c_sft01, alg2c_sftdone;
    logic [3:0] mfsm_alg, mfsm_stp;

    assign {mfsm_alg, mfsm_stp} = mfsm;


// mfsm alg1-a

    `theregrnce( mfsm_alg1acycx ) <= ~( mfsm == MFSM_ALG1A )|mfsm_alg1adone|(mfsm_alg1acycx==4) ? '0 : ( mfsm_alg1acycx + 1 );
    `theregrnce( mfsm_alg1acycy ) <= ~( mfsm == MFSM_ALG1A )|mfsm_alg1adone|((mfsm_alg1acycy==4)&&(mfsm_alg1acycx==4)) ? '0 : ( mfsm_alg1acycy + (mfsm_alg1acycx==4) );
    `theregrnce( mfsm_alg1adone ) <= ( mfsm == MFSM_ALG1A )&(mfsm_alg1acycx==4)&(mfsm_alg1acycy==4) ;

    assign rambase_alg1a = RAMBASE_A;
    assign ramptr_alg1a = mfsm_alg1acycx*5 + mfsm_alg1acycy;
    assign ramwr_alg1a = 0;
    `theregrnce( ramrd_alg1a ) <= mfsm_alg1a_prerise ? '1 : ( mfsm_alg1acycx == 4 )&( mfsm_alg1acycy == 4 ) ? '0 : ramrd_alg1a;
    assign ramwdat_alg1a = '0;

    `theregrnce( vregwr_alg1a ) <= (mfsm_alg1acycx==0)&&ramrd_alg1a ? '1 : 'h1;
    assign vregpre_alg1a = vregwr_alg1a_sft ? { vreg, ramrdat } : { vreg[0:3], vreg[4]^ramrdat } ;
    assign vregwr_alg1a_sft = vregwr_alg1a[0];

// mfsm alg1-b
    assign mfsm_alg1bdone = ( mfsm == MFSM_ALG1B );

    assign vregwr_alg1b = mfsm_alg1bdone ? '1 : '0;
    generate
        for( x = 0; x < 5; x = x + 1) begin: ALG1BX
            for( z = 0; z < 64; z = z + 1) begin: LOOPZ
                assign vregpre_alg1b[x][z]= vreg[(x+4)%5][z] ^ vreg[(x+1)%5][(z+63)%64];
            end
        end
    endgenerate

// mfsm alg1-c

    `theregrnce( mfsm_alg1ccycx ) <= ~( mfsm == MFSM_ALG1C )|mfsm_alg1cdone|(mfsm_alg1ccycx==9) ? '0 : ( mfsm_alg1ccycx + 1 );
    `theregrnce( mfsm_alg1ccycy ) <= ~( mfsm == MFSM_ALG1C )|mfsm_alg1cdone|((mfsm_alg1ccycy==4)&&(mfsm_alg1ccycx==9)) ? '0 : ( mfsm_alg1ccycy + (mfsm_alg1ccycx==9) );
    `theregrnce( mfsm_alg1cdone ) <= ( mfsm == MFSM_ALG1C )&(mfsm_alg1ccycx==9)&(mfsm_alg1ccycy==4) ;

    assign rambase_alg1c = RAMBASE_A;
    assign ramptr_alg1c = (mfsm_alg1ccycx/2)*5 + mfsm_alg1ccycy;
    assign ramwr_alg1c =  mfsm_alg1ccycx[0];
    assign ramrd_alg1c = ~mfsm_alg1ccycx[0];
    assign ramwdat_alg1c = vreg[0] ^ ramrdat;

    assign vregwr_alg1c = (mfsm_alg1ccycx==9) ? '1 : '0;
    assign vregpre_alg1c = { vreg, ramrdat };

// mfsm alg2-a

    `theregrnce( mfsm_alg2acycx ) <= ~( mfsm == MFSM_ALG2A )|mfsm_alg2adone|(mfsm_alg2acycx==4) ? '0 : ( mfsm_alg2acycx + 1 );
    `theregrnce( mfsm_alg2adone ) <= ( mfsm == MFSM_ALG2A )&(mfsm_alg2acycx==4);

    assign rambase_alg2a = RAMBASE_A;
    assign ramptr_alg2a = mfsm_alg2acycx*5 + mfsm_alg2cycy;
    assign ramwr_alg2a = '0;
    assign ramrd_alg2a = ( mfsm == MFSM_ALG2A )&~mfsm_alg2adone;
    assign ramwdat_alg2a = '0;

    `theregrnce( vregwr_alg2a ) <= ramrd_alg2a ? '1 : '0;
    assign vregpre_alg2a = { vreg, ramrdat };

// mfsm alg2-b

    `theregrnce( mfsm_alg2bcyc ) <= ~( mfsm == MFSM_ALG2B )|mfsm_alg2bdone|(mfsm_alg2bcyc==2) ? '0 : ( mfsm_alg2bcyc + 1 );
    assign mfsm_alg2bdone = ( mfsm == MFSM_ALG2B );//&(mfsm_alg2bcyc==2);

    assign rambase_alg2b = RAMBASE_P0;
    assign ramptr_alg2b = mfsm_alg2cycy;
    assign ramwr_alg2b = '0;
    assign ramrd_alg2b = ( mfsm == MFSM_ALG2B );//& (mfsm_alg2bcyc == '0);
    assign ramwdat_alg2b = '0;

    `theregrnce( {ramrd_alg2bpl2, ramrd_alg2bpl1} ) <= {ramrd_alg2bpl1, ramrd_alg2b};

// mfsm alg2-c
/*
    `theregrnce( mfsm_alg2ccyc ) <= ~( mfsm == MFSM_ALG2C )|mfsm_alg2cdone|(mfsm_alg2ccyc==11) ? '0 : ( mfsm_alg2ccyc + 1 );
    `theregrnce( mfsm_alg2cdone ) <= ( mfsm == MFSM_ALG2C )&(mfsm_alg2ccyc==11);

    assign alg2_svsft = (mfsm_alg2ccyc[1:0] == '1);
    assign alg2c_sft01 = (mfsm_alg2ccyc[3:2] == 'h0);
    assign alg2c_sft04 = (mfsm_alg2ccyc[3:2] == 'h1);
    assign alg2c_sft16 = (mfsm_alg2ccyc[3:2] == 'h2);

    generate
        for( x = 0; x < 5; x = x + 1) begin: ALG2CX
            assign vregwr_alg2c[x] = mfsm_alg2ccyc[1:0] < alg2_sv[x][1:0];
            assign vregpre_alg2c[x] = alg2c_sft16 ?  { vreg[x] , vreg[x][63:48] } : alg2c_sft04 ?  { vreg[x] , vreg[x][63:60] } : { vreg[x] , vreg[x][63] } ;
            `theregrnce( alg2_sv[x] ) <= ramrd_alg2bpl2 ? ramrdatreg[(4-x)*6+5:(4-x)*6+0] : alg2_svsft ? alg2_sv[x]/4 : alg2_sv[x];
        end
    endgenerate
    `theregrnce( alg3_sv ) <= ramrd_alg2bpl2 ? ramrdatreg[59:30] : alg3_svsft ? {alg3_sv,6'h0} : alg3_sv;
*/

    assign mfsm_alg2cdone = ( mfsm == MFSM_ALG2C )&(alg2c_sftdone=='1);

    generate
        for( x = 0; x < 5; x = x + 1) begin: ALG2CX

            `theregrnce(alg2c_sftcnt[x])<= mfsm_alg2adone || alg2_sv[x][1:0]==0 || alg2c_sftcnt[x] == alg2_sv[x][1:0] ? 1 : alg2c_sftcnt[x]+(alg2c_sft01[x]|alg2c_sft04[x]|alg2c_sft16[x]);
            `theregrnce(alg2c_sft01[x]) <= mfsm_alg2adone ? '1 :  (alg2_sv[x][1:0]==0 || alg2c_sftcnt[x] == alg2_sv[x][1:0]) ? '0 : alg2c_sft01[x];
            `theregrnce(alg2c_sft04[x]) <= (alg2_sv[x][1:0]==0 || alg2c_sftcnt[x] == alg2_sv[x][1:0]) ? alg2c_sft01[x] : alg2c_sft04[x];
            `theregrnce(alg2c_sft16[x]) <= (alg2_sv[x][1:0]==0 || alg2c_sftcnt[x] == alg2_sv[x][1:0]) ? alg2c_sft04[x] : alg2c_sft16[x];
            `theregrnce(alg2c_sftdone[x]) <= mfsm_alg2cdone?'0:(alg2_sv[x][1:0]==0 || alg2c_sftcnt[x] == alg2_sv[x][1:0]) & alg2c_sft16[x]?'1:alg2c_sftdone[x];

            assign alg2_svsft[x] = (alg2c_sft01 || alg2c_sft04) && (alg2_sv[x][1:0]==0 || alg2c_sftcnt[x] == alg2_sv[x][1:0]);

            assign vregwr_alg2c[x] = (alg2c_sft16[x] | alg2c_sft04[x] | alg2c_sft01[x]) & (alg2_sv[x][1:0]!=0);
            assign vregpre_alg2c[x] = alg2c_sft16[x] ?  { vreg[x] , vreg[x][63:48] } : alg2c_sft04[x] ?  { vreg[x] , vreg[x][63:60] } : { vreg[x] , vreg[x][63] } ;
            `theregrnce( alg2_sv[x] ) <= ramrd_alg2bpl2 ? ramrdatreg[(4-x)*6+5:(4-x)*6+0] : alg2_svsft[x] ? alg2_sv[x]/4 : alg2_sv[x];
        end
    endgenerate
    `theregrnce( alg3_sv ) <= ramrd_alg2bpl2 ? ramrdatreg[59:30] : alg3_svsft ? {alg3_sv,6'h0} : alg3_sv;

// mfsm alg2-d/3

    `theregrnce( mfsm_alg2dcycx ) <= ~( mfsm == MFSM_ALG2D )|mfsm_alg2ddone|(mfsm_alg2dcycx==4) ? '0 : ( mfsm_alg2dcycx + 1 );
    assign mfsm_alg2ddone = ( mfsm == MFSM_ALG2D )&(mfsm_alg2dcycx==4);
    assign alg3_svsft = ( mfsm == MFSM_ALG2D );
//    assign ramptr_alg2d = mfsm_alg2cycy*5 + mfsm_alg2dcycx;
    assign rambase_alg2d = RAMBASE_B;
    assign ramptr_alg2d = alg3_sv[0];
    assign ramwr_alg2d = ( mfsm == MFSM_ALG2D );
    assign ramrd_alg2d = '0;
    assign ramwdat_alg2d = vreg[0];

    assign vregwr_alg2d = ramwr_alg2d ? '1 : '0;
    assign vregpre_alg2d = { vreg, ramrdat };

// mfsm alg4-a

    `theregrnce( mfsm_alg4acycx ) <= ~( mfsm == MFSM_ALG4A )|mfsm_alg4adone|(mfsm_alg4acycx==4) ? '0 : ( mfsm_alg4acycx + 1 );
    `theregrnce( mfsm_alg4adone ) <= ( mfsm == MFSM_ALG4A )&(mfsm_alg4acycx==4);

    assign rambase_alg4a = RAMBASE_B;
    assign ramptr_alg4a = mfsm_alg4acycx*5 + mfsm_alg4cycy;
    assign ramwr_alg4a = '0;
    assign ramrd_alg4a = ( mfsm == MFSM_ALG4A )&~mfsm_alg4adone;
    assign ramwdat_alg4a = '0;

    `theregrnce( vregwr_alg4a ) <= ramrd_alg4a ? '1 : '0;
    assign vregpre_alg4a = { vreg, ramrdat };

// mfsm alg4-b

    assign mfsm_alg4bdone = ( mfsm == MFSM_ALG4B );

    assign vregwr_alg4b = mfsm_alg4bdone ? '1 : '0;
    generate
        for( x = 0; x < 5; x = x + 1) begin: ALG4BX
            assign vregpre_alg4b[x] = vreg[x] ^ ( ~vreg[(x+1)%5] & vreg[(x+2)%5] );
        end
    endgenerate

// mfsm alg4-c

    `theregrnce( mfsm_alg4ccycx ) <= ~( mfsm == MFSM_ALG4C )|mfsm_alg4cdone|(mfsm_alg4ccycx==4) ? '0 : ( mfsm_alg4ccycx + 1 );
    assign mfsm_alg4cdone = ( mfsm == MFSM_ALG4C )&(mfsm_alg4ccycx==4);

    assign rambase_alg4c = RAMBASE_A;
    assign ramptr_alg4c = mfsm_alg4ccycx + mfsm_alg4cycy*5;
    assign ramwr_alg4c = ( mfsm == MFSM_ALG4C );
    assign ramrd_alg4c = '0;
    assign ramwdat_alg4c = vreg[0];

    assign vregwr_alg4c = ramwr_alg4c ? '1 : '0;
    assign vregpre_alg4c = { vreg, ramrdat };

// mfsm alg5-a

    `theregrnce( mfsm_alg5acyc ) <= ~( mfsm == MFSM_ALG5A )|mfsm_alg5adone|(mfsm_alg5acyc==3) ? '0 : ( mfsm_alg5acyc + 1 );
    `theregrnce( mfsm_alg5adone ) <= ( mfsm == MFSM_ALG5A )&(mfsm_alg5acyc==3);

    assign rambase_alg5a = (mfsm_alg5acyc==0) ? RAMBASE_P1 : RAMBASE_A;
    assign ramptr_alg5a = (mfsm_alg5acyc==0) ? algrnd : '0;
    assign ramwr_alg5a = (mfsm_alg5acyc==3);
    assign ramrd_alg5a = ( mfsm == MFSM_ALG5A )& (mfsm_alg5acyc/2 == '0);
    assign ramwdat_alg5a = rc64 ^ ramrdatreg;;

    `theregrnce( rc64 ) <= (mfsm_alg5acyc==2) ? ramrdatreg : rc64;

// ram ref mux

    logic ramwr0, ramrd0;
    logic [0:4] vregwr0;

    assign {ramwr, ramrd} = {ramwr0, ramrd0&ce};
    assign vregwr = ce ? vregwr0 : '0;

    always_comb begin
        case(mfsm)
            MFSM_ALG1A:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg1a, ramptr_alg1a, ramwr_alg1a, ramrd_alg1a, ramwdat_alg1a };
            MFSM_ALG1C:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg1c, ramptr_alg1c, ramwr_alg1c, ramrd_alg1c, ramwdat_alg1c };
            MFSM_ALG2A:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg2a, ramptr_alg2a, ramwr_alg2a, ramrd_alg2a, ramwdat_alg2a };
            MFSM_ALG2B:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg2b, ramptr_alg2b, ramwr_alg2b, ramrd_alg2b, ramwdat_alg2b };
            MFSM_ALG2D:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg2d, ramptr_alg2d, ramwr_alg2d, ramrd_alg2d, ramwdat_alg2d };
            MFSM_ALG4A:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg4a, ramptr_alg4a, ramwr_alg4a, ramrd_alg4a, ramwdat_alg4a };
            MFSM_ALG4C:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg4c, ramptr_alg4c, ramwr_alg4c, ramrd_alg4c, ramwdat_alg4c };
            MFSM_ALG5A:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg5a, ramptr_alg5a, ramwr_alg5a, ramrd_alg5a, ramwdat_alg5a };
//            MFSM_ALG5B:     { rambase, ramptr, ramwr0, ramrd0, ramwdat } = { rambase_alg5b, ramptr_alg5b, ramwr_alg5b, ramrd_alg5b, ramwdat_alg5b };
            default:        { rambase, ramptr, ramwr0, ramrd0, ramwdat } = '0;
        endcase
    end

    always_comb begin
        case(mfsm)
            MFSM_ALG1A:     { vregpre, vregwr0 } = { vregpre_alg1a, vregwr_alg1a };
            MFSM_ALG1B:     { vregpre, vregwr0 } = { vregpre_alg1b, vregwr_alg1b };
            MFSM_ALG1C:     { vregpre, vregwr0 } = { vregpre_alg1c, vregwr_alg1c };
            MFSM_ALG2A:     { vregpre, vregwr0 } = { vregpre_alg2a, vregwr_alg2a };
            MFSM_ALG2C:     { vregpre, vregwr0 } = { vregpre_alg2c, vregwr_alg2c };
            MFSM_ALG2D:     { vregpre, vregwr0 } = { vregpre_alg2d, vregwr_alg2d };
            MFSM_ALG4A:     { vregpre, vregwr0 } = { vregpre_alg4a, vregwr_alg4a };
            MFSM_ALG4B:     { vregpre, vregwr0 } = { vregpre_alg4b, vregwr_alg4b };
            MFSM_ALG4C:     { vregpre, vregwr0 } = { vregpre_alg4c, vregwr_alg4c };
            default:        { vregpre, vregwr0 } = '0;
        endcase
    end





endmodule






`ifdef SIM_SHA3


module tb_sha3();

    bit clk,resetn;
    integer i, j, k, errcnt=0, warncnt=0;

    parameter AW = 10;
    parameter RAW = 10;
    parameter DW = 64;

    parameter RAMBASE_A = 0;
    parameter RAMBASE_B = 25;
    parameter RAMBASE_P0 = 50;
    parameter RAMBASE_P1 = 55;

    bit start;
    bit busy;
    bit done;
    bit [RAW-1:0] rambase, ramptr, ramaddr;
    bit            ramrd;
    bit            ramwr;
    bit [DW-1:0]  ramwdat;
    bit [DW-1:0]  ramrdat, ramrdatreg;

    bit [0:50+5+24-1][DW-1:0] ramdat;

    bit [0:24][63:0] ramitemA ;
    bit [0:24][63:0] ramitemB ;
    bit [0:4] [63:0] ramitemP0;
    bit [0:23][63:0] ramitemP1;

    bit [0:4][63:0]   vreg;
    bit [0:4]         vregwr;
    bit [0:4][63:0]   vregpre;

    bit     [0:24][63:0] stin;
    bit     [0:24][63:0] stout;
    bit ce;
    assign ce = '1;

generate
    for (genvar gvi = 0; gvi < 5; gvi++) begin:GG
        `thereg(vreg[gvi]) <= vregwr[gvi] ? vregpre[gvi] : vreg[gvi];
    end
endgenerate

    assign ramaddr = rambase + ramptr;

    `thereg(ramdat[ramaddr]) <= ramwr ? ramwdat : ramdat[ramaddr];
    `thereg(ramrdat) <= ramdat[ramaddr];
    `thereg(ramrdatreg) <= ramrdat;

    assign ramitemA = ramdat[0:24];
    assign ramitemB = ramdat[25:49];
    assign ramitemP0 = ramdat[50:54];
    assign ramitemP1 = ramdat[55:78];

    initial ramdat[50] = { 4'h0, 6'd0,    6'd8,    6'd11,     6'd19,    6'd22,      6'd0,    6'd36,    6'd3,     6'd41,    6'd18 };
    initial ramdat[51] = { 4'h0, 6'd2,    6'd5,    6'd13,     6'd16,    6'd24,      6'd1,    6'd44,    6'd10,    6'd45,     6'd2 };
    initial ramdat[52] = { 4'h0, 6'd4,    6'd7,    6'd10,     6'd18,    6'd21,      6'd62,    6'd6,    6'd43,    6'd15,    6'd61 };
    initial ramdat[53] = { 4'h0, 6'd1,    6'd9,    6'd12,     6'd15,    6'd23,      6'd28,   6'd55,    6'd25,    6'd21,    6'd56 };
    initial ramdat[54] = { 4'h0, 6'd3,    6'd6,    6'd14,     6'd17,    6'd20,      6'd27,   6'd20,    6'd39,     6'd8,    6'd14 };

    initial ramdat[55:78] = {
        64'h0000000000000001, 64'h0000000000008082, 64'h800000000000808a,
        64'h8000000080008000, 64'h000000000000808b, 64'h0000000080000001,
        64'h8000000080008081, 64'h8000000000008009, 64'h000000000000008a,
        64'h0000000000000088, 64'h0000000080008009, 64'h000000008000000a,
        64'h000000008000808b, 64'h800000000000008b, 64'h8000000000008089,
        64'h8000000000008003, 64'h8000000000008002, 64'h8000000000000080,
        64'h000000000000800a, 64'h800000008000000a, 64'h8000000080008081,
        64'h8000000000008080, 64'h0000000080000001, 64'h8000000080008008
    };

  //
  //  dut
  //  ==

    hashcore_sha3 dut (.*);
    sha3_flatcore dut_ref(.*);

  //
  //  monitor and clk
  //  ==

    `genclk( clk, 100 )
    `timemarker2
    integer timer=0;
    `theregrn( timer ) <= timer+1;

  //
  //  subtitle
  //  ==

    bit errqt, errrm;

    bit [63:0] rngdat64;

    `ifndef NOFSDB
    initial begin
        #(10 `MS);
        #(1 `US);
    `maintestend
    `endif

    `maintest(tb_sha3,tb_sha3)

    resetn = 0; #(103) resetn = 1;
    #( 1 `US );


    for( j = 0; j>=0; j++)begin
//    resetn = 0; #(103) resetn = 1;
    #( 1 `US );
        for(i=0;i<25;i++)
        begin
            rngdat64[63:32] = $random();
            rngdat64[31:0] = $random();
            ramdat[i] = rngdat64;
            stin[i] = rngdat64;
        end

        #(1 `US); @(negedge clk) start = 1; @(negedge clk) start = 0;timer=0;    #(1 `US);
        @(negedge done);
        $display("    timer= %0d", timer);

        #( 00 `US );
    end

    #( 10 `US );
    `maintestend


    initial begin
        $display("parameter");
        for(i=0;i<(5+24);i++)$display("%08x %08x",ramdat[50+i][31:0],ramdat[50+i][63:32]);
    end

endmodule

`endif










