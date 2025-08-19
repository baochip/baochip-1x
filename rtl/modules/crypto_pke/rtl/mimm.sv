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

module mimm #(
    parameter MAX = 1024*6,
    parameter DW = 64,
    parameter PL = 4,
    parameter AW = 12,
    parameter type adr_t = bit[AW-1:0],
    parameter type dat_t = bit[DW-1:0],

//    parameter adr_t BA_RAM0_DA  = 12'h000,
//    parameter adr_t BA_RAM0_DB  = 12'h100,
//    parameter adr_t BA_RAM0_DNI = 12'h200,
//    parameter adr_t BA_RAM0_DN  = 12'h300,
    parameter adr_t BA_RAM2_UI  = 12'h000,
    parameter adr_t BA_RAM2_UU  = BA_RAM2_UI + MAX/DW+PL+2,
    parameter adr_t BA_RAM2_DQ  = BA_RAM2_UU + MAX/DW+PL+2

)(
        input bit clk,
        input bit resetn,
        input bit cmsatpg,
        input bit cmsbist,

        input bit start,
        output bit busy, done,

        input bit[7:0] nlen,// in DW
        input bit[7:0] opt,
        input bit [DW-1:0] db_rnd,

        input bit [PL-1:0][DW-1:0] param_J0,

//      input  bit     [63:0]              ram0rdat,
//      input  bit     [63:0]              ram1rdat,
//      output bit                         mgmr_mul_ram0_rdA,
//      output bit                         mgmr_mul_ram1_rdB,
//      output bit                         mgmr_mul_ram0_rdN,
//      output bit                         mgmr_mul_ram1_rdM,
//      output bit                         mgmr_mul_ram0_wr,
//      output bit                         mgmr_mul_ram1_wr,
//      output bit     [7:0]               mgmr_mul_ram0_addr,
//      output bit     [7:0]               mgmr_mul_ram1_addr,
//      output bit     [63:0]              mgmr_mul_ram0_dat,
//      output bit     [63:0]              mgmr_mul_ram1_dat,

        output bit ram0rdA, ram0rdN,
        output bit ram1rdB, ram1rdM,
        output bit ram0wr,ram1wr,
        output adr_t ram0addr, ram1addr,
        output dat_t ram0wdat, ram1wdat,
        input dat_t ram0rdat,
        input dat_t ram1rdat,

        output bit ram2rd, ram2wr,
        output adr_t ram2raddr, ram2waddr,
        output dat_t ram2wdat,
        input dat_t ram2rdat

);

    parameter MFSM_IDLE = 8'h00;
    parameter MFSM_S0   = 8'h10;
    parameter MFSM_S1   = 8'h11;
    parameter MFSM_S2   = 8'h12;
    parameter MFSM_SUB  = 8'h20;
    parameter MFSM_OUT  = 8'h30;
    parameter MFSM_DONE = 8'hff;

    bit [$clog2(PL):0] opt_pl;
    bit opt_sec;

    assign {opt_sec,opt_pl} = opt;

    bit mfsm_s0done, mfsm_s1done, mfsm_s2done, mfsm_subdone;
    bit firstrnd,lastrnd;
    bit [7:0] mfsm, mfsmnext, mfsmrnd;
    adr_t dblen;
    adr_t dxlen;
    adr_t daptr, dbptr, dxptr, dyptr, daptroffset;
    bit   dard,  dbrd,  dxrd,  dywr;
    bit [DW-1:0] dardat, dbrdat, dxrdat;
    bit [DW-1:0] dywdat;
    adr_t daptr_sub, dbptr_sub, dyptr_sub;
    bit   dard_sub,  dbrd_sub,  dywr_sub;
    bit [DW-1:0] dardat_sub, dbrdat_sub;
    bit [DW-1:0] dywdat_sub;
    bit macstart, macdone, substart, subdone, macbusy, subbusy;
    bit dywrs1, dywrs2, dywrs2enable;
    bit [DW-1:0] J0rdat;
    bit [7:0] mfsm_outcnt;
    bit mfsm_outdone, mfsm_outcntdone;
    bit outrd, outwr;
    adr_t outrdptr, outwrptr;

    `theregrn(mfsm) <= mfsmnext;

    assign mfsmnext = start ? MFSM_S0 :
                      ( mfsm == MFSM_S0 & mfsm_s0done ) ? MFSM_S1 :
                      ( mfsm == MFSM_S1 & mfsm_s1done ) ? MFSM_S2 :
                      ( mfsm == MFSM_S2 & mfsm_s2done ) ? ( lastrnd ? MFSM_SUB : MFSM_S0 ) :
                      ( mfsm == MFSM_SUB & mfsm_subdone ) ? MFSM_OUT :
                      ( mfsm == MFSM_OUT & mfsm_outdone ) ? MFSM_DONE :
                      ( mfsm == MFSM_DONE ) ? MFSM_IDLE : mfsm;
    assign done = ( mfsm == MFSM_DONE );
    assign lastrnd = ( mfsmrnd == nlen/(opt_pl+1) - 1 );
    assign firstrnd = ( mfsmrnd == 0 );
    `theregrn( mfsmrnd ) <= start ? 0 : mfsmrnd+mfsm_s2done;

    `theregrn( busy ) <= start ? '1 : done ? '0 : busy;

  //
  //  MFSM_S0
  //  ==

    assign mfsm_s0done = ( mfsm == MFSM_S0 ) & macdone;
    assign mfsm_s1done = ( mfsm == MFSM_S1 ) & macdone;
    assign mfsm_s2done = ( mfsm == MFSM_S2 ) & macdone;
    assign mfsm_subdone = ( mfsm == MFSM_SUB ) & subdone;

    `theregrn( mfsm_outcnt ) <= (mfsm!=MFSM_OUT)|( (mfsm == MFSM_SUB) & mfsm_subdone ) ? 0 : mfsm_outcntdone ? 0 : mfsm_outcnt + 1;
    `theregrn( mfsm_outdone ) <= mfsm_outcntdone;
    assign mfsm_outcntdone = ( mfsm_outcnt == nlen -1 );

    assign outrdptr = mfsm_outcnt;
    `theregrn( outwrptr ) <= outrdptr;
    `theregrn( outrd ) <= ( (mfsm == MFSM_SUB) & mfsm_subdone ) ? '1 : mfsm_outcntdone ? '0 : outrd;
    `theregrn( outwr ) <= outrd;

//  `theregrn( UU ) <= mfsm_s0done ? UI + DA[mfsmrnd] * DB : UU;
//  `theregrn( Dq ) <= mfsm_s1done ? UU[0] * DNI : Dq;
//  `theregrn( UI ) <= mfsm_s2done ? (UU + Dq * DN )>>DW: UI;
//
//  `theregrn( DP ) <= mfsm_subdone ? UI % VN : DP;


//                s0          s1              s2      sub   out       |
//    ram0.rdA    db                                                  |
//    ram0.rdN                                db      db              |
//                                                                    |
//    ram1.rdB    da                                                  |
//    ram1.rdM                                                        |
//    ram1.wr                                               wr        |
//                                                                    |
//    ram2r.UU                db[0]           dx                      |
//    ram2r.Dq                                da[0]                   |
//    ram2r.UI    dx                                  da    rd        |
//                                                                    |
//    ram2w.UU    dy                                                  |
//    ram2w.Dq                dy                                      |
//    ram2w.UI                                dy      dy              |
//                                                                    |
//                            dx=0                                    |
//                            da=j0

    `theregrn( daptroffset ) <= start ? '0 : mfsm_s0done ? daptroffset + opt_pl + 1 : daptroffset;

    assign ram0rdA    =  ( mfsm == MFSM_S0 ) &   dbrd ;
    assign ram0rdN    =  ( mfsm == MFSM_S2 ) &   dbrd | dbrd_sub ;

    assign ram1rdB    =  ( mfsm == MFSM_S0 ) &   dard ;
    assign ram1rdM    =  '0 ;

    assign ram0wr = outwr;
    assign ram1wr = '0;//outwr;

    assign ram0addr = ( mfsm == MFSM_OUT ) ? outwrptr : ( mfsm == MFSM_SUB ) ? dbptr_sub : dbptr;
    assign ram1addr = ( mfsm == MFSM_OUT ) ? outwrptr : daptroffset + daptr ;

    assign ram0wdat = ram2rdat;
    assign ram1wdat = ram2rdat;


    assign ram2rd    = ( mfsm == MFSM_S0 ) ? dxrd & ~firstrnd :
                       ( mfsm == MFSM_S1 ) ? dbrd :
                       ( mfsm == MFSM_S2 ) ? dxrd | dard :
                       ( mfsm == MFSM_SUB ) ? dard_sub :
                                              outrd;
    assign ram2wr    = ( mfsm == MFSM_S0 ) ? dywr :
                       ( mfsm == MFSM_S1 ) ? dywr :
                       ( mfsm == MFSM_S2 ) ? dywrs2 :
                                             dywr_sub;
    assign ram2raddr = ( mfsm == MFSM_S0 ) ? BA_RAM2_UI + dxptr :
                       ( mfsm == MFSM_S1 ) ? BA_RAM2_UU + dbptr :
                       ( mfsm == MFSM_S2 ) ? ( dxrd ?
                                                BA_RAM2_UU + dxptr :
                                                BA_RAM2_DQ + daptr ) :
                       ( mfsm == MFSM_SUB ) ? BA_RAM2_UI + daptr_sub :
                                              BA_RAM2_UI + outrdptr;
    assign ram2waddr = ( mfsm == MFSM_S0 ) ? BA_RAM2_UU + dyptr :
                       ( mfsm == MFSM_S1 ) ? BA_RAM2_DQ + dyptr :
                       ( mfsm == MFSM_S2 ) ? BA_RAM2_UI + dyptr - (opt_pl+1) :
                                             BA_RAM2_UI + dyptr_sub;
    assign ram2wdat = ( mfsm == MFSM_SUB ) ? dywdat_sub : dywdat;

    `theregrn( dywrs2enable ) <= start | macdone ? '0 : ( mfsm == MFSM_S2 ) & (dyptr == opt_pl) ? '1 : dywrs2enable;

    assign dywrs1 = dywr;
    assign dywrs2 = dywr & dywrs2enable;

    assign dardat = ( mfsm == MFSM_S0 ) ? ram1rdat : ( mfsm == MFSM_S1 ) ? J0rdat : ram2rdat ;
    assign dbrdat = ( mfsm == MFSM_S1 ) ? ram2rdat   : ram0rdat;
    assign dxrdat = ( mfsm == MFSM_S1 )|firstrnd&( mfsm == MFSM_S0 ) ? '0 : ram2rdat;
    assign dardat_sub = ram2rdat;
    assign dbrdat_sub = ram0rdat;

    `theregrn( J0rdat ) <= ( mfsm == MFSM_S1 ) & dard ? param_J0[daptr[1:0]] : 0;

    assign dblen = ( mfsm == MFSM_S0 ) ? nlen :
                   ( mfsm == MFSM_S1 ) ? opt_pl+1:
                                         nlen ;

    assign dxlen = ( mfsm == MFSM_S0 ) ? nlen + opt_pl + 1:
                   ( mfsm == MFSM_S1 ) ? 0:
                                         nlen + opt_pl + 1;

    `theregrn( macstart ) <= start | macdone & ~(( mfsm == MFSM_S2 ) & lastrnd );
    assign substart =( mfsm == MFSM_S2 ) & lastrnd & macdone;

    mac_core #(
        .PL ( PL ),
        .DW ( DW ),
        .adr_t (adr_t)
    )mcore(
        .clk,
        .resetn,
        .start(macstart),
        .medone(),
        .busy(macbusy),
        .done(macdone),
        .opt_pl,
        .opt_sec,
        .db_rnd,
        .dblen,
        .dxlen,
        .daptr, .dbptr, .dxptr, .dyptr,
        .dard,  .dbrd,  .dxrd,  .dywr,
        .dardat, .dbrdat, .dxrdat,
        .dywdat
    );

    mimm_sub #(
        .DW ( DW ),
        .adr_t (adr_t)
    )subcore(
        .clk,
        .resetn,
        .start(substart),
        .busy(subbusy),
        .done(subdone),
        .dblen((nlen+1'h1)),
        .daptr(daptr_sub), .dbptr(dbptr_sub), .dyptr(dyptr_sub),
        .dard(dard_sub),  .dbrd(dbrd_sub),  .dywr(dywr_sub),
        .dardat(dardat_sub), .dbrdat(dbrdat_sub),
        .dywdat(dywdat_sub)
    );
/*
    mimm_dpram  #(.DW(DW),.AW(AW),.DCNT(BA_RAM2_DQ+8))ram2 (
        .cmsatpg, .cmsbist,
        .clk        ( clk ),
        .waddr      ( ram2waddr ),
        .wr         ( ram2wr ),
        .wdata      ( ram2wdat ),
        .raddr      ( ram2raddr ),
        .rd         ( ram2rd ),
        .rdata      ( ram2rdat )
    );

`ifdef SIM

    bit [127:0][63:0] ram2_UU;
    bit [127:0][63:0] ram2_UI;
    bit [3:0][63:0] ram2_DQ;

    assign ram2_UU = ram2.memdata[102+BA_RAM2_UU:BA_RAM2_UU];
    assign ram2_UI = ram2.memdata[102+BA_RAM2_UI:BA_RAM2_UI];
    assign ram2_DQ = ram2.memdata[3+BA_RAM2_DQ:BA_RAM2_DQ];

`endif
*/
endmodule : mimm


module mimm_sub #(
    parameter DW = 64,
    parameter type adr_t = bit[12:0]

)(
    input bit clk,
    input bit resetn,

    input bit start,
    output bit busy,
    output bit done,

    input [7:0] dblen,

    output adr_t daptr, dbptr, dyptr,
    output bit   dard,  dbrd,  dywr,
    input bit [DW-1:0] dardat, dbrdat,
    output bit [DW-1:0] dywdat
);

    // if da >= db, dy = da - db;
    // if da <  db, no change

    localparam MFSM_IDLE = 'h0;
    localparam MFSM_SUB0 = 'h1;
    localparam MFSM_SUB1 = 'h2;
    localparam MFSM_DONE = 'hff;

    bit [DW-1:0] areg,breg;
    bit [7:0] mfsm, mfsmnext, mfsmpl2, mfsmpl1;
    bit dardsub1pl2, dardsub1pl1;
    bit mfsm_sub0done, sub0cmpdone, mfsm_sub0pl2, mfsm_sub0pl1, mfsm_sub1done, sub1skip, mfsm_sub0;
    adr_t mfsm_sub0cyc, mfsm_sub0cycpl1, mfsm_sub0cycpl2 , mfsm_sub1cyc, mfsm_sub1cycpl1, mfsm_sub1cycpl2;

// mfsm
    `theregrn( busy ) <= start ? 1 : done ? '0 : busy;
    assign done = ( mfsm == MFSM_DONE ) ;

    `theregrn( mfsm ) <= mfsmnext;
    assign mfsmnext = start ? MFSM_SUB0 :
                         (( mfsm == MFSM_SUB0 ) &&  mfsm_sub0done ) ? MFSM_SUB1:
                         (( mfsm == MFSM_SUB1 ) &&  mfsm_sub1done ) ? MFSM_SUB0:
                         (( mfsm == MFSM_SUB1 ) &&  sub1skip ) ? MFSM_DONE :
                         ( mfsm == MFSM_DONE ) ? MFSM_IDLE : mfsm;

// mfsm sub0/1

    `theregrn( mfsm_sub0cyc ) <= ~( mfsm == MFSM_SUB0 )|mfsm_sub0done ? '0 : ( mfsm_sub0cyc + 1 );
    assign mfsm_sub0done = sub0cmpdone&( mfsm == MFSM_SUB0 );
    assign sub0cmpdone = ( mfsm_sub0cycpl2 == dblen - 1 ) |
                         ( areg != breg ) & mfsm_sub0pl2;
    assign mfsm_sub0 = ( mfsm == MFSM_SUB0 );

    `theregrn( sub1skip ) <= start | done? 0 :
                             ( areg < breg ) & mfsm_sub0pl2 & mfsm_sub0 ? '1 :
                             ( mfsm_sub0cycpl2 == dblen - 1 ) & ( areg == breg ) ? '1 : sub1skip ;

    `theregrn( mfsm_sub1cyc ) <= ~( mfsm == MFSM_SUB1 )|mfsm_sub1done ? '0 : ( mfsm_sub1cyc + 1 );
    assign mfsm_sub1done = mfsm_sub1cycpl2 == dblen - 1;

// pl

    `theregrn( { mfsmpl2, mfsmpl1 } ) <= { mfsmpl1, mfsm };
    `theregrn( { mfsm_sub0pl2, mfsm_sub0pl1 } ) <= { mfsm_sub0pl1, mfsm_sub0 };
    `theregrn( { mfsm_sub0cycpl2, mfsm_sub0cycpl1 } ) <= { mfsm_sub0cycpl1, mfsm_sub0cyc };
    `theregrn( { mfsm_sub1cycpl2, mfsm_sub1cycpl1 } ) <= { mfsm_sub1cycpl1, mfsm_sub1cyc };
    `theregrn( { dardsub1pl2, dardsub1pl1 } ) <= { dardsub1pl1, ~sub1skip&dard&&(( mfsm == MFSM_SUB1 )) };

// dat

    assign daptr = ( mfsm == MFSM_SUB1 ) ? mfsm_sub1cyc : dblen - mfsm_sub0cyc - 1;
    assign dbptr = daptr;
    assign dyptr = mfsm_sub1cycpl2;


    `theregrn( dard ) <= start ? '1 : sub1skip ? '0 :
                        ( mfsm == MFSM_SUB0 ) &&  mfsm_sub0done  ? '1 :
                        ( mfsm == MFSM_SUB1 ) &&  mfsm_sub1done  ? '1 :
                        ( mfsm == MFSM_SUB0 ) && ( mfsm_sub0cyc == dblen - 1 ) ? '0 :
                        ( mfsm == MFSM_SUB1 ) && ( mfsm_sub1cyc == dblen - 1 ) ? '0 :
                                 dard;
    assign dbrd = dard;
    assign dywr = dardsub1pl2;

    `thereg( areg ) <= dardat;
    `thereg( breg ) <= dbrdat;


    bit cr, crreg;
    assign {cr,dywdat} = areg - breg - crreg;
    `theregrn( crreg ) <= ~dywr ? 0 : cr;


endmodule : mimm_sub

`ifdef SIM_MIMM

module mimm_tb ();

    bit clk,resetn,resetnref;
    integer i=0, j=0, k=0, errcnt=0, warncnt=0;
    bit start, done, busy;


    parameter MAX= 1024*6;
//    parameter NW = 4096;
    parameter NW = 4096;
    parameter DW = 64;
    parameter PM = 1;
    parameter PW = 2 * NW;

    parameter PL = 4;
    parameter AW = 12;
    parameter type adr_t = bit[AW-1:0];
    parameter type dat_t = bit[DW-1:0];


//    parameter adr_t BA_RAM0_DA  = 12'h000,
//    parameter adr_t BA_RAM0_DB  = 12'h100,
//    parameter adr_t BA_RAM0_DNI = 12'h200,
//    parameter adr_t BA_RAM0_DN  = 12'h300,
    parameter adr_t BA_RAM2_UI  = 12'h000;
    parameter adr_t BA_RAM2_UU  = BA_RAM2_UI + MAX*2/DW;
    parameter adr_t BA_RAM2_DQ  = BA_RAM2_UU + MAX*2/DW;

    parameter adr_t BA_RAM0_DA  = 12'h000;
    parameter adr_t BA_RAM0_DB  = 12'h100;
    parameter adr_t BA_RAM0_DNI = 12'h200;
    parameter adr_t BA_RAM0_DN  = 12'h300;
//    parameter adr_t BA_RAM1_UI  = 12'h000;
//    parameter adr_t BA_RAM1_UU  = 12'h100;
//    parameter adr_t BA_RAM1_DQ  = 12'h200;
    parameter adr_t BA_RAM1_DA  = 12'h000;
    parameter adr_t BA_RAM1_DP  = 12'h100;

  //  ref0
    bit [NW:0] R;
    bit [NW-1:0] VA, VB, VN, VNI;
    bit [PW-1:0] VP0, VP, VP1, VP_MIMM;
    bit [PW-1:0] tmp;
    bit [0:PL-1][PW-1:0] VP_pl;

    assign VP0 = VA * VB;
    assign VP1 = VP0 % VN;  //reference result for (A * B) % N
//    assign R  =  257'h10000000000000000000000000000000000000000000000000000000000000000; // R's length needs to be one bit larger than N, 2^k
//    assign VN  = 256'h8e54750e723d8eada99445de2b8e3e58881070949fd5891c7ab49b369e220129; // 2^(k-1) < N < 2^k
//    assign VNI = 256'h2d6750782f0d51c27e24c3b564e50238a733669e4252f9dabffbfa7407e3d4e7; // VNI = N0' = R - pow(N, -1, R)
//N prime 4096
assign VN  = 4096'hde938fbc5733d9a5c73ddcc540a5c3241d343411c391387ff73a7623135ed81d81b07219107c8c04a8190fcfbd4cbd5ca58fde062a4e0afab0264cea8a67b0668c365c9a266ac89374ca0843a9898a85c9a996217b539c80e90ea9ffe2ff32759b1bb937ae2de151b2ca9d477b031b28b9759f8f65036f60625eb6bc794895bddff9bd80fb2108bb4689e992cd127eba2324df4743cc41b7556beb5e21723a55219c72b44084032ea18cac29b57d5a18b511898267d6f12167fe59964e3612aa6d4d0e2e1da858f35992cad837110a0ba2f3fd3b337a7fbd2bdb0a4014aa0c756ff54e5ad3e9572d1921ac03bf2bbf439dd1b6ff6a121a5f4b41cbbe8f0c6fb7821d88f9e824e5372c905eb619130db626196f6806086e31dcb8cb22f5be2d6f42e1ae9d8537b4df22f2afafb08d57ee20700e15fa93f6fb9b74b587aec160c7f1ee2e4f9b1ae95b4c07380f56bc9140fbda3e8ae97814da25f7788acaae18cf0dbe3b93b41169c50ff7fef6a1f139264dc56538feec1c49586d91761f6efe223f0a5fcc6ab763a1b892b97872105991f83fff927e3c9ed7ee5490ef6ce13ba972df3194ed03cf77f71723206c8a8b257489489eb09d5c7fdc37539a3aceb1d534146c6b0a4543eeefd611c49d134b04557da52764e900d900c963ecb31ea2cd05a5e93b937fdf4874e5a39896aebf6e7415a1461b4b459a1b47069962c3b7e1;
//R 4097
assign R   = 4097'h10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
//R inv 4095
assign VNI = 4096'h5d43f7236745c171aa3efe7f576f3fbcefc42eb1e66ad59ca6cb548e9bb3799027b122706100238b438c50ad5e0b61fb10645420fd9a2a81a69e5f56b0adaa3f6ff41b2795f218e46dc0a5319af85e9420a76a4f11f882c94276b52837f9842cfca312a1c6e4c2b727098451d500102ecda62fe344c4b8fdf3cb34b0e87a11ceacbb4ba06919487e2cdf954e8083e436e95d6975ded47bde1ca2ecc843f3725e8161859d1529c98f3d62f2965b76e21495a8cc4fb35b9b0cab64a9cc2558c41fe23215ea3614724bcb2572f7808a0955b539a1e7b97e65d9e9cc8381c2bfa266d9c2460350ae305cd7058b73c9d9873d6d64ef767b3fa9cbfe8bfac764d8a5d9c5e890c1032070906dc21f7103a698896caa37d5cb47652d48d209435f8632840ea0f04d7c157cd4e08321ab161eae55f7aa77e24ff707e1e6dc86f60d54468204c09a7a278397ff3b5c8cd156b5ff97d7d04202e268bec4c11379e46bb7f2aa9cb72b0842ae7a70f6f948e513c2d56aa2ce26544a8e8662e23c338e64c7dd6c7c01b1c98c33849b5e61ea045c2c95b46bf072cda754eda0e933719f2ff4f9bb9f10bc1d4248549bd04d4ce0c3595ed96db04a1581e76e9de494e82c288d5463dea014535cb58a9150dc32c51be10374b364325240721d495702dfd5933be0066476a57ee00f69c12e2a93507efd7bcc529bd39683b33d00514688fb3076b8b6;



    bit[7:0] nlen;
    bit[7:0] opt;
    bit ram0rd;
    bit ram1rd;
    bit ram1wr;
    adr_t ram0raddr;
    adr_t ram1raddr;
    adr_t ram1waddr;
    dat_t ram0wdat;
    dat_t ram1wdat;
    dat_t ram0rdat;
    dat_t ram1rdat;
    bit [DW-1:0] db_rnd;

    localparam NWW = NW/DW;
    localparam PWW = PW/DW;

    bit [NWW-1:0][DW-1:0] DA, DB, DN, DNI, ram_vp;
    bit [PWW-1:0][DW-1:0] DP;
    bit [PWW-1:0][DW-1:0] UI, UU;   // U is intermediate variable to store the result
    bit [NWW-1:0][DW-1:0] Dq;

    bit [12'h3ff:0][DW-1:0] ram0dat,ram1dat;

bit ram0rdA, ram0rdN, ram1rdB, ram1rdM;
adr_t ram0addr, ram1addr;
bit cmsatpg, cmsbist;

    assign ram0dat[BA_RAM0_DA +12'h0ff:BA_RAM0_DA ] = DA  ; assign DA  = VA  ;
    assign ram0dat[BA_RAM0_DB +12'h0ff:BA_RAM0_DB ] = DB  ; assign DB  = VB  ;
    assign ram0dat[BA_RAM0_DNI+12'h0ff:BA_RAM0_DNI] = DNI ; assign DNI = VNI ;
    assign ram0dat[BA_RAM0_DN +12'h0ff:BA_RAM0_DN ] = DN  ; assign DN  = VN  ;

    assign ram1dat[BA_RAM1_DA +12'h0ff:BA_RAM1_DA ] = DA  ;
    assign ram1dat[BA_RAM1_DP +12'h0ff:BA_RAM1_DP ] = '0  ;

//    assign ram1dat[BA_RAM1_DA +12'h0ff:BA_RAM1_UI ] = UI  ;
//    assign ram1dat[BA_RAM1_UU +12'h0ff:BA_RAM1_UU ] = UU  ;
//    assign ram1dat[BA_RAM1_DQ +12'h0ff:BA_RAM1_DQ ] = Dq  ;

    `theregrn( ram0rdat ) <= ram0rd ? ram0dat[ram0raddr] : ram0rdat;
    `theregrn( ram1rdat ) <= ram1rd ? ram1dat[ram1raddr] : ram1rdat;

    `theregrn( ram_vp[ram1addr] ) <= ram1wr ? ram1wdat : ram_vp[ram1addr];
    assign VP_MIMM = ram_vp;

//    assign VP_MIMM = UI[NWW:0]%VN;

//  assign tmp = VN*VNI ;

    mac_ref #( .NW(NW), .DW(DW*1), .PM(PM))dutref0(
        .clk,
        .resetn(resetnref),
        .VA, .VB, .VN, .VNI,
        .VP(VP_pl[0]),
        .start,
        .done()
        );


    mac_ref #( .NW(NW), .DW(DW*2), .PM(PM))dutref1(
        .clk,
        .resetn(resetnref),
        .VA, .VB, .VN, .VNI,
        .VP(VP_pl[1]),
        .start,
        .done()
        );

    mac_ref #( .NW(NW), .DW(DW*4), .PM(PM))dutref3(
        .clk,
        .resetn(resetnref),
        .VA, .VB, .VN, .VNI,
        .VP(VP_pl[3]),
        .start,
        .done()
        );

    assign VP = VP_pl[(opt%PL)];

/*
    mimm #(
     .DW(DW),
     .PL(PL),
     .AW(AW),
     .adr_t(adr_t),
     .dat_t(dat_t),
     .BA_RAM0_DA(BA_RAM0_DA),
     .BA_RAM0_DB(BA_RAM0_DB),
     .BA_RAM0_DNI(BA_RAM0_DNI),
     .BA_RAM0_DN(BA_RAM0_DN),
     .BA_RAM1_UI(BA_RAM1_UI),
     .BA_RAM1_UU(BA_RAM1_UU),
     .BA_RAM1_DQ(BA_RAM1_DQ)

    )dut(
        . clk,
        . resetn,
        . start,
        . busy,
        . done(),
        . nlen (NW/DW),// in DW
        . opt (opt),
        . db_rnd,
        . ram0rd,
        . ram1rd,
        . ram1wr,
        . ram0raddr,
        . ram1raddr,
        . ram1waddr,
        . ram1wdat,
        . ram0rdat,
        . ram1rdat
    );
*/

bit [7:0] nlen;
assign nlen = NW/DW;

    bit ram2rd, ram2wr;
    adr_t ram2raddr, ram2waddr;
    dat_t ram2wdat, ram2rdat;

mimm #(
     .DW(DW),
     .PL(PL),
     .AW(AW),
     .adr_t(adr_t),
     .dat_t(dat_t)
//     .BA_RAM2_UI(BA_RAM1_UI),
//     .BA_RAM2_UU(BA_RAM1_UU),
//     .BA_RAM2_DQ(BA_RAM1_DQ)
    )dut(
        . clk,
        . resetn,
        . cmsatpg,
        . cmsbist,
        . start,
        . busy,
        . done(),
        . nlen (nlen),// in DW
        . opt (opt),
        . db_rnd,

        .param_J0(VNI[DW*PL-1:0]),
        .ram0rdA,
        .ram0rdN,
        .ram1rdB,
        .ram1rdM,

        .ram0wr(),
        .ram1wr(ram1wr),
        .ram0addr,
        .ram1addr,
        .ram0wdat,
        .ram1wdat,
        .ram0rdat,
        .ram1rdat,


.ram2waddr,
.ram2wr,
.ram2wdat,
.ram2raddr,
.ram2rd,
.ram2rdat

);

    mimm_dpram  #(.DW(DW),.AW(AW),.DCNT(BA_RAM2_DQ+8))ram2 (
        .cmsatpg, .cmsbist,
        .clk        ( clk ),
        .waddr      ( ram2waddr ),
        .wr         ( ram2wr ),
        .wdata      ( ram2wdat ),
        .raddr      ( ram2raddr ),
        .rd         ( ram2rd ),
        .rdata      ( ram2rdat )
    );

    assign ram0rd = ram0rdA | ram0rdN;
    assign ram1rd = ram1rdB | ram1rdM;

    assign ram0raddr = ram0rdA ? ram0addr + BA_RAM0_DB : ram0addr + BA_RAM0_DN;
    assign ram1raddr = ram1addr + BA_RAM1_DA;
    assign ram1waddr = ram1addr + BA_RAM1_DP;
//    assign ram0waddr = '0;


    integer timercnt;

    `theregrn( timercnt ) <= start ? '0 : timercnt + busy;
    always@( posedge clk ) trnd2( DW/32, db_rnd );

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

    `maintest(mimm_tb,mimm_tb)
    $display("Test start");
    resetn = 0; #(103) resetn = 1;
    resetnref = 0; #(103) resetnref = 1;
    #( 1 `US );

     for( j = 0; j>=0; j++)begin

    resetnref = 0; #(103) resetnref = 1;
/*
    opt = ((opt%PL) == 0) ? 1 + 8:
          ((opt&PL) == 1) ? 3 + 8:
                       0 + 8;
*/
    opt = 8+3;



     #( 1 `US );
        trnd(VA);
        trnd(VB);

//        VA = VA%VN;
//        VB = VB%VN;

//        UU = '0;
//        UI = '0;
//        Dq = '0;
     #( 1 `US );

    //  @(negedge clk) start = 1;
    //  @(negedge clk) start = 0;


    //     #( 100 `US );
    // end

    //assign VA = 256'h8e54750e723d8eada99445de2b8e3e58881070949fd5891c7ab49b369e233333;
    //assign VB = 256'h8e54750e723d8eada99445de2b8e3e58881070949fd5891c7ab49b369e220122;

        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        @(posedge dut.done );

    #( 10 `US );

//    $display("VP-ref0  %x", VP * R % VN); // To compare with the original result, we need to convert the result from montgomery field back to ordinary
    $display("VA-      %x", VA);
    $display("VB-      %x", VB);
    $display("VP-ref1  %x", VP);
    $display("VP-MIMM  %x", VP_MIMM  );
    $display("timer[%1d]:   %d", opt, timercnt );


        if((VP_MIMM)==VP)$display("pass!!");
        else begin
            $display("failed!!");
          $stop;
            errcnt++;
        end
    #( 1 `US );
//    resetn = 0; #(103) resetn = 1;
    #( 1 `US );
//$stop;
end

    `maintestend


task trnd(output bit [NW-1:0] dato);
    integer ti=0;
    for(ti=0;ti<NW/32;ti++)begin
        dato = {dato, $random()};
    end
endtask : trnd


task trnd2(input bit [7:0] cnt, output bit [PW-1:0] dato);
    integer ti=0;
    dato = 0;
    for(ti=0;ti<cnt;ti++)begin
        dato = {dato, $random()};
//      dato = {dato, 32'hffffffff};
    end
endtask : trnd2

endmodule : mimm_tb

`endif