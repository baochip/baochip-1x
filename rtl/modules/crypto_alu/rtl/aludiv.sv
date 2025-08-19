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

module aludiv #(
	parameter DW = 64,
	parameter LW = 4096*4,
	parameter DEW = LW,
	parameter DSW = LW/2,
	parameter DWW = $clog2(DW),
	parameter LWW = $clog2(LW)+1,
	parameter RAW = $clog2(LW/DW)+2
)(
	input logic clk,
	input logic resetn,
	input logic start,
	output logic busy,
	output logic done,
	input logic [LWW-1:0] delen,
	input logic [LWW-1:0] dslen,
	output logic [RAW-1:0] ramaddr,
	output logic 		   ramrd,
	output logic 		   ramwr,
	output logic [DW-1:0]  ramwdat,
	input logic [DW-1:0]   ramrdat,
	output logic [LWW-1:0] qtlen,
	output logic [LWW-1:0] rmlen,
	output logic [$clog2(LW/DW)-1:0] qtcnt,
	output logic [$clog2(LW/DW)-1:0] rmcnt,
	output bit qs0err
);

	parameter DSWW = DSW/DW;
	parameter DEWW = DEW/DW;

	parameter RAMBASE_DE = 0;
	parameter RAMBASE_DS = RAMBASE_DE + LW/DW;
	parameter RAMBASE_QT = RAMBASE_DS + LW/DW;

	localparam MFSM_IDLE = 'h0;
	localparam MFSM_IFPRESFT = 'h7;
	localparam MFSM_PRESFT = 'h1;
	localparam MFSM_RND0 = 'h2;
	localparam MFSM_RND1 = 'h3;
	localparam MFSM_SFT1 = 'h4;
	localparam MFSM_DONE = 'h5;
	localparam MFSM_WRQT = 'h6;
	localparam MFSM_CLRRAM = 'h10;

	logic [$clog2(LW/DW):0] dscnt, decnt;
	logic [7:0] mfsm, mfsmnext;
	logic [8:0] mfsm_presftcyc, mfsm_rnd0cyc, mfsm_rnd1cyc, mfsm_sft1cyc, ramaddr_rnd0pl1, mfsm_clrramcyc;
	logic [1:0] mfsm_rnd1cyc0;
	logic mfsm_presftdone, presftdone, presftbit, mfsm_rnd0done, mfsm_rnd1skip, mfsm_rnd1skippre, mfsm_rndlast;
	logic mfsm_rnd1done, cr, crreg;
	logic [DW-1:0] qtreg;
	logic qtreg_clr, qtreg_lshb, qtbit;
	logic mfsm_sft1startpre, mfsm_sft1done, sft1bit;
	logic [RAW-1:0] ramaddr_clrram, ramaddr_ifpresft, ramaddr_presft, ramaddr_rnd0, ramaddr_wrqt, ramaddr_rnd1, ramaddr_sft1;
	logic 		    ramwr_clrram,   ramrd_ifpresft,   ramrd_presft,   ramrd_rnd0,   ramrd_wrqt,   ramrd_rnd1,   ramrd_sft1;
	logic 		    ramrd_clrram,   ramwr_ifpresft,   ramwr_presft,   ramwr_rnd0,   ramwr_wrqt,   ramwr_rnd1,   ramwr_sft1;
	logic [DW-1:0]  ramwdat_clrram, ramwdat_ifpresft, ramwdat_presft, ramwdat_rnd0, ramwdat_wrqt, ramwdat_rnd1, ramwdat_sft1;
	logic [DW-1:0]  ramrdatreg;
	logic [$clog2(LW)-1:0] dsidx_lsb, dsidx_msb, deidx_msd, deidx_msd0, deidx_msdpre;
	logic rnd0cyc_cmpflag, rnd0cyc_rddspl2, rnd0cyc_rddspl1;
	logic mfsm_ifpresftcyc, ifpresft, mfsm_ifpresftdone, mfsm_clrramdone;

	`theregrn( qtlen ) <= mfsm_ifpresftdone ? dsidx_msb+1 : qtlen;
	`theregrn( rmlen ) <= mfsm_ifpresftdone ? dsidx_msb-dsidx_lsb+1 : rmlen;

	assign decnt = delen / DW + |( delen % DW );
	assign dscnt = dslen / DW + |( dslen % DW );
	assign qtcnt = qtlen / DW + |( qtlen % DW );
	assign rmcnt = rmlen / DW + |( rmlen % DW );

// mfsm

	`theregrn( busy ) <= start ? 1 : done ? '0 : busy;
	assign done = ( mfsm == MFSM_DONE );

	`theregrn( mfsm ) <= mfsmnext;
	assign mfsmnext = start ? MFSM_IFPRESFT :
						 (( mfsm == MFSM_IFPRESFT ) &&  mfsm_ifpresftdone ) ? ( ifpresft ? ( qs0err ? MFSM_DONE : MFSM_PRESFT ) : MFSM_RND0 ):
						 (( mfsm == MFSM_PRESFT ) &&  mfsm_presftdone ) ? MFSM_IFPRESFT :
					     (( mfsm == MFSM_RND0 ) && mfsm_rnd0done ) ? MFSM_WRQT :
					     (( mfsm == MFSM_WRQT ) ) ? MFSM_RND1 :
					     (( mfsm == MFSM_RND1 ) && mfsm_rnd1done | mfsm_rnd1skip ) ? ( mfsm_rndlast ? MFSM_DONE : MFSM_SFT1 ) :
					     (( mfsm == MFSM_SFT1 ) && mfsm_sft1done ) ? MFSM_RND0 :
//						 (( mfsm == MFSM_CLRRAM ) &&  mfsm_clrramdone ) ? MFSM_DONE :
					     ( mfsm == MFSM_DONE ) ? MFSM_IDLE : mfsm;

// mfsm clrram

 	`theregrn( mfsm_clrramcyc ) <= ~( mfsm == MFSM_CLRRAM )|mfsm_clrramdone ? '0 : ( mfsm_clrramcyc + 1 );
 	assign mfsm_clrramdone = ( mfsm_clrramcyc == LW*3/DW-1 );

 	assign ramaddr_clrram = mfsm_clrramcyc;
 	assign ramwr_clrram = '1;
 	assign ramrd_clrram = '0;
 	assign ramwdat_clrram = 0;

// mfsm ifpresft

 	`theregrn( mfsm_ifpresftcyc ) <= ~( mfsm == MFSM_IFPRESFT )|mfsm_ifpresftdone ? '0 : ( mfsm_ifpresftcyc + 1 );
	assign mfsm_ifpresftdone = ( mfsm_ifpresftcyc == 'h1 );
	assign ifpresft = mfsm_ifpresftdone & ~ramrdat[DW-1];
	assign qs0err = ifpresft & ( dsidx_msb == 0 );

 	assign ramaddr_ifpresft = RAMBASE_DS + dsidx_msb/DW;
 	assign ramwr_ifpresft = '0;
 	assign ramrd_ifpresft = '1;
 	assign ramwdat_ifpresft = '0;

// mfsm presft

 	`theregrn( mfsm_presftcyc ) <= ~( mfsm == MFSM_PRESFT )|mfsm_presftdone|presftdone ? '0 : ( mfsm_presftcyc + 1 );
 	assign mfsm_presftdone = presftdone;//( mfsm_presftcyc == 1 ) & (ramrdat[DW-1]==1);
 	assign presftdone = ( ramaddr_presft == (dsidx_msb/DW + RAMBASE_DS)) & ( mfsm_presftcyc[0] == 1 );

 	assign ramaddr_presft = RAMBASE_DS + dsidx_lsb/DW + mfsm_presftcyc/2;
 	assign ramwr_presft = mfsm_presftcyc[0];// & ~mfsm_presftdone;
 	assign ramrd_presft = ~mfsm_presftcyc[0];
 	assign ramwdat_presft = { ramrdat, presftbit };

	`theregrn( presftbit ) <= start|presftdone ? '0 : mfsm_presftcyc[0] ? ramrdat[DW-1] : presftbit;

// mfsm rnd0/rnd1

 	`theregrn( mfsm_rnd0cyc ) <= ~( mfsm == MFSM_RND0 )|mfsm_rnd0done ? '0 : ( mfsm_rnd0cyc + 1 );
	assign mfsm_rnd0done = rnd0cyc_cmpflag & ( ramrdatreg != ramrdat ) |
						   rnd0cyc_cmpflag & ( ramrdatreg == ramrdat ) & ( ramaddr_rnd0pl1 == ( dsidx_lsb/DW + RAMBASE_DS));
	`theregrn( mfsm_rnd1skip ) <= start|mfsm_rnd1done ? '0 : mfsm_rnd0done ? mfsm_rnd1skippre : mfsm_rnd1skip;
	assign mfsm_rnd1skippre = rnd0cyc_cmpflag & ( ramrdatreg > ramrdat );
	`theregrn( { rnd0cyc_rddspl2, rnd0cyc_rddspl1 } ) <= {rnd0cyc_rddspl1, ( mfsm == MFSM_RND0 ) && ~mfsm_rnd0cyc[0]};
	assign rnd0cyc_cmpflag = rnd0cyc_rddspl2 & ( mfsm == MFSM_RND0 );
	`theregrn( ramaddr_rnd0pl1 ) <= ~mfsm_rnd0cyc[0] ? ramaddr_rnd0 : ramaddr_rnd0pl1;

 	assign ramaddr_rnd0 = ( mfsm_rnd0cyc[0] ? RAMBASE_DE : RAMBASE_DS ) + deidx_msd - mfsm_rnd0cyc/2;
 	assign ramrd_rnd0 = '1;
 	assign ramwr_rnd0 = '0;
 	assign ramwdat_rnd0 = '0;

	assign mfsm_rndlast = ( dsidx_lsb == 0 );

 	`theregrn( mfsm_rnd1cyc0 ) <= ~( mfsm == MFSM_RND1 )|mfsm_rnd1done|(mfsm_rnd1cyc0=='h2) ? '0 : ( mfsm_rnd1cyc0 + 1 );
 	`theregrn( mfsm_rnd1cyc ) <= ~( mfsm == MFSM_RND1 )|mfsm_rnd1done ? '0 :
 								  (mfsm_rnd1cyc0=='h2) ? ( mfsm_rnd1cyc + 1 ) : mfsm_rnd1cyc;
	assign mfsm_rnd1done = ( ramaddr_rnd1 == ( deidx_msd + RAMBASE_DE ) ) & (mfsm_rnd1cyc0=='h2);
 	assign ramaddr_rnd1 = ( mfsm_rnd1cyc0 == 0 ? RAMBASE_DS : RAMBASE_DE ) + dsidx_lsb/DW + mfsm_rnd1cyc;
 	assign ramrd_rnd1 = ~ramwr_rnd1;
 	assign ramwr_rnd1 = (mfsm_rnd1cyc0=='h2);
	assign { cr, ramwdat_rnd1 } = { 1'b0, ramrdat[DW-1:0] } - { 1'b0, ramrdatreg } - crreg;
	`theregrn( crreg ) <= start | mfsm_rnd0done ? '0 : ( mfsm_rnd1cyc0 == 'h2 ) ? cr : crreg;


// mfsm wrqt
	`theregrn( qtreg ) <= qtreg_clr ? '0 :
						  qtreg_lshb ? { qtreg, qtbit } :
						  			   qtreg;

	assign qtreg_clr = start;
	assign qtreg_lshb = ( mfsm == MFSM_RND0 ) && mfsm_rnd0done;
	assign qtbit = mfsm_rnd1skippre ? '0 : '1;

 	assign ramaddr_wrqt = RAMBASE_QT + dsidx_lsb/DW ;
 	assign ramrd_wrqt = '0;
 	assign ramwr_wrqt = ( mfsm == MFSM_WRQT ) & (dsidx_lsb%DW == 0);
 	assign ramwdat_wrqt = qtreg;

// mfsm sft1

 	`theregrn( mfsm_sft1cyc ) <= ~( mfsm == MFSM_SFT1 )|mfsm_sft1done ? '0 : ( mfsm_sft1cyc + 1 );
	assign mfsm_sft1startpre = ( mfsmnext == MFSM_SFT1 ) & ( mfsm != MFSM_SFT1 );
	assign mfsm_sft1done = ( mfsm == MFSM_SFT1 )&( ramaddr_sft1 == ( dsidx_lsb/DW + RAMBASE_DS ))&mfsm_sft1cyc[0];

 	assign ramaddr_sft1 = RAMBASE_DS + dsidx_msb/DW - mfsm_sft1cyc/2;
 	assign ramwr_sft1 = mfsm_sft1cyc[0];
 	assign ramrd_sft1 = ~mfsm_sft1cyc[0];
 	assign ramwdat_sft1 = { sft1bit, ramrdat[DW-1:1] };

	`theregrn( sft1bit ) <= (( mfsm == MFSM_RND0 ) && mfsm_rnd0done ) ? '0 : mfsm_sft1cyc[0] ? ramrdat[0] : sft1bit;

// ram mux

	assign { ramaddr, ramrd, ramwr, ramwdat } =
				( mfsm == MFSM_CLRRAM ) ? { ramaddr_clrram, ramrd_clrram, ramwr_clrram, ramwdat_clrram } :
				( mfsm == MFSM_IFPRESFT ) ? { ramaddr_ifpresft, ramrd_ifpresft, ramwr_ifpresft, ramwdat_ifpresft } :
				( mfsm == MFSM_PRESFT ) ? { ramaddr_presft, ramrd_presft, ramwr_presft, ramwdat_presft } :
				( mfsm == MFSM_RND0 ) ?   { ramaddr_rnd0, ramrd_rnd0, ramwr_rnd0, ramwdat_rnd0 } :
				( mfsm == MFSM_WRQT ) ?   { ramaddr_wrqt, ramrd_wrqt, ramwr_wrqt, ramwdat_wrqt } :
				( mfsm == MFSM_RND1 ) ?   { ramaddr_rnd1, ramrd_rnd1, ramwr_rnd1, ramwdat_rnd1 } :
				 						  { ramaddr_sft1, ramrd_sft1, ramwr_sft1, ramwdat_sft1 } ;
    `theregrn( ramrdatreg ) <= ramrdat;

// ds/de idx

	`theregrn( dsidx_lsb ) <= start ? (( decnt - dscnt ) * DW ) : ifpresft ? dsidx_lsb + 1 : mfsm_sft1startpre ? dsidx_lsb - 1 : dsidx_lsb;
	`theregrn( dsidx_msb ) <= start ? (  decnt  * DW - 1 ) : mfsm_sft1done ? dsidx_msb - 1 : dsidx_msb;

	`theregrn( deidx_msd0 ) <= 	start ? (decnt-1):
								ramwr_rnd1 && ( ramwdat_rnd1 != 0 ) ? deidx_msdpre : deidx_msd0;
	assign deidx_msdpre = ( ramaddr_rnd1 > ( dsidx_msb/DW + RAMBASE_DE )) ? ( ramaddr_rnd1 - RAMBASE_DE ) : dsidx_msb/DW ;

	`theregrn( deidx_msd ) <= 	start ? (decnt-1): mfsm_rnd1done ? deidx_msd0 : deidx_msd;

endmodule

`ifdef SIM_ALUDIV


module tb_aludiv();

    bit clk,resetn;
    integer i, j, k, errcnt=0, warncnt=0;

	parameter LW = 4096;
	parameter DW = 64;
	parameter DEW = LW;
	parameter DSW = LW/2;
	parameter DWW = $clog2(DW);
	parameter LWW = $clog2(LW)+1;
	parameter RAW = $clog2(LW/DW)+2;

	bit start;
	bit busy;
	bit done;
	bit [LWW-1:0] delen=DEW;
	bit [LWW-1:0] dslen=DSW;
	bit [RAW-1:0] ramaddr;
	bit 		   ramrd;
	bit 		   ramwr;
	bit [DW-1:0]  ramwdat;
	bit [DW-1:0]  ramrdat;
	logic [LWW-1:0] qtlen;
	logic [LWW-1:0] rmlen;
	logic [$clog2(LW/DW)-1:0] qtcnt;
	logic [$clog2(LW/DW)-1:0] rmcnt;

	bit [4*DEW/DW-1:0][DW-1:0] ramdat;
	bit [0:3][DEW/DW-1:0][DW-1:0] ramitem;

	`thereg(ramdat[ramaddr]) <= ramwr ? ramwdat : ramdat[ramaddr];
	`thereg(ramrdat) <= ramdat[ramaddr];
	assign ramitem = ramdat;

  //
  //  dut
  //  ==

	aludiv #(.LW (LW)) dut (.*);

	bit [DEW-1:0] de;
	bit [DSW-1:0] ds;
	bit [LW-1:0]  qt,rm;

	aludiv_ref #(.LW(LW))dut0(.*);

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

  	bit [31:0] rngdat32;

    `ifndef NOFSDB
    initial begin
    	#(100 `MS);
    	#(1 `US);
    	$display("@I:::: errcnt = %d", dut0.errcnt);
    `maintestend
    `endif

    `maintest(tb_aludiv,tb_aludiv)

    resetn = 0; #(103) resetn = 1;
    #( 1 `US );


    for( j = 0; j>=0; j++)begin
//    resetn = 0; #(103) resetn = 1;
    #( 1 `US );
	    delen = LW; dslen = DSW;
	    for(i=0;i<DEW/32;i++) de = {de,32'h0} + $random();
	    for(i=0;i<DSW/32;i++)
	    begin
	    	rngdat32 = $random();
	    	ds = {ds,32'h0} + rngdat32;
	    end
		ramdat[2*DEW/DW-1:DEW/DW] = {ds, {(DEW-DSW){1'b0}}};
		ramdat[DEW/DW-1:0] = de;

	    #(1 `US); @(negedge clk) start = 1; @(negedge clk) start = 0;timer=0;    #(1 `US);
	    @(negedge done);
		$display("    timer= %0d", timer);

	    errqt = ( qt != ramitem[1] );
	    errrm = ( rm != ramitem[3] );
		$display("    rm= %0x, qt= %0x", ramitem[3],ramitem[1]);
		if(errqt||errrm)begin
			$display("@E: qt/rm error!!" );
			errcnt++;
		end

	    #( 100 `US );
	end

    #( 10 `US );
    `maintestend

endmodule

`endif
