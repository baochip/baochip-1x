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

module mac_cell #(
	parameter PL = 4,
	parameter DW = 64
)(
	input bit clk,
	input bit resetn,
	input bit opt_sec,
	input bit [$clog2(PL):0] opt_pl,
	input bit ME,
	input bit [0:PL-1][DW-1:0] DA,
	input bit [DW-1:0] DB,
	input bit [DW-1:0] DB_rnd,
	input bit [DW-1:0] DX,
	output bit [DW-1:0] DY
);

	bit [0:PL][DW-1:0] pcc,pss,pa,pb;
	bit [0:PL][2*DW-1:0] pp;
	bit [0:PL+1][DW-1:0] ds;
	bit [0:PL][3:0] rc;
	bit mepl1;

	`thereg ({ rc[0], ds[0] }) <= mepl1 ? rc[0] + DX + pss[0] + ds[1] : rc[0] + DX + ds[1] ;
	assign {pcc[PL],pss[PL]} = 0;

	`theregrn( mepl1 ) <= ME;

	genvar i;
	generate
		for ( i = 0; i < PL; i++) begin
			assign pp[i] = pa[i] * pb[i];
			assign pa[i] =  ( opt_pl >= i )&&( ME | ~ME & opt_sec )  ? DA[i] : '0;
			assign pb[i] =  ME & ( opt_pl >= i ) ? DB :
						   ~ME & ( opt_pl >= i ) ? ( opt_sec ? DB_rnd : '0 ) : '0;
//			`thereg ({ pcc[i], pss[i] }) <= ME & ( opt_pl >= i ) ? DA[i] * DB : '0;//{ pcc[i], pss[i] } ;
			`thereg ({ pcc[i], pss[i] }) <= ( opt_pl >= i )&&( ME | ~ME & opt_sec ) ? pp[i] : '0;
			`thereg ({ rc[i+1], ds[i+1] }) <= mepl1 & ( opt_pl >= i ) ? rc[i+1] + pcc[i] + pss[i+1] + ds[i+2] : rc[i+1] + ds[i+2] ;
		end
	endgenerate

	assign ds[PL+1] = '0;
	assign DY = ds[0];

endmodule



module mac_core #(
	parameter PL = 4,
	parameter DW = 64,
	parameter type adr_t = bit[12:0]

)(
	input bit clk,
	input bit resetn,

	input bit start,
	output bit medone,
	output bit busy,
	output bit done,

	input bit [$clog2(PL):0] opt_pl,
	input bit opt_sec,
	input bit [DW-1:0] db_rnd,
	input adr_t dblen,
	input adr_t dxlen,

	output adr_t daptr, dbptr, dxptr, dyptr,
	output bit   dard,  dbrd,  dxrd,  dywr,
	input bit [DW-1:0] dardat, dbrdat, dxrdat,
	output bit [DW-1:0] dywdat

);
	bit [0:PL-1][DW-1:0] da_rnd;
	adr_t ddlen;
	bit [0:PL-1][DW-1:0] dareg_shift,dareg;
	bit [0:PL-1] dareg_en;
	bit [DW-1:0] dxreg,dbreg;
	bit [7:0] mfsm, mfsmnext;
	bit mfsm_ldadone, mfsm_multdone;
	bit dardpl1,dxrdpl1,dbrdpl1;
	bit [$clog2(PL):0] mfsm_ldacyc;
	adr_t mfsm_multcyc_pl3, mfsm_multcyc_pl2, mfsm_multcyc_pl1, mfsm_multcyc, mfsm_multcyc_pl4;
	bit me;
	bit ldapl1, mfsm_ldadonepl1, mfsm_ldadonepl2;
	bit [DW-1:0] dwzero;
	assign dwzero = 0;

	localparam MFSM_IDLE = 'h0;
	localparam MFSM_LDA = 'h1;
	localparam MFSM_MULT = 'h2;
	localparam MFSM_DONE = 'hff;

// mfsm

	logic done_pl4, done_pl3, done_pl2, done_pl1, done_pl0;
	`theregrn( busy ) <= start ? 1 : done ? '0 : busy;
	assign done_pl0 = ( mfsm_multcyc == ddlen ) & ( ddlen != 0 );//( mfsm == MFSM_DONE );
	`theregrn( { done_pl4, done_pl3, done_pl2, done_pl1} ) <= { done_pl3, done_pl2, done_pl1, done_pl0 };
	assign done = done_pl4;

	`theregrn( mfsm ) <= mfsmnext;
	assign mfsmnext = start ? MFSM_LDA :
						 (( mfsm == MFSM_LDA ) &&  mfsm_ldadone ) ? MFSM_MULT:
						 (( mfsm == MFSM_MULT ) &&  mfsm_multdone ) ? MFSM_DONE :
					     ( mfsm == MFSM_DONE ) ? MFSM_IDLE : mfsm;

// mfsm

	mac_cell #( .PL(PL), .DW(DW) ) mcell (
		.clk, .resetn,
		.opt_pl,
		.ME(me),
		.opt_sec,
		.DB_rnd(db_rnd),
		.DA(dareg),
		.DB(dbreg),
		.DX(dxreg),
		.DY(dywdat)
		);


// mfsm load a

 	`theregrn( mfsm_ldacyc ) <= ~( mfsm == MFSM_LDA )|mfsm_ldadone ? '0 : ( mfsm_ldacyc + 1 );
	assign mfsm_ldadone = ( mfsm == MFSM_LDA )&( mfsm_ldacyc == PL-1 );

 	assign daptr = mfsm_ldacyc;
 	assign dard = ( mfsm == MFSM_LDA ) & (mfsm_ldacyc<=opt_pl);

 	`thereg( dareg_shift ) <= ldapl1 ? { dareg_shift, dardat } : dareg_shift;
 	`theregrn( ldapl1 ) <= ( mfsm == MFSM_LDA );
 	`theregrn( dardpl1 ) <= dard;
	`theregrn( {mfsm_ldadonepl2, mfsm_ldadonepl1} ) <= {mfsm_ldadonepl1, mfsm_ldadone};
 	genvar i;
 	generate
 		for (i = 0; i < PL; i++) begin:gg
 			`thereg(dareg[i])<=mfsm_ldadonepl2?(dareg_en[i]?dareg_shift[i]:'0):dareg[i];
 			assign dareg_en[i] = (i<=opt_pl);
 		end
 	endgenerate

// mfsm mult
/*
	`thereg( ddlen ) <= (dblen+PL > dxlen) ? dblen+PL : dxlen;

 	`theregrn( mfsm_multcyc ) <= ~( mfsm == MFSM_MULT )|mfsm_multdone ? '0 : ( mfsm_multcyc + 1 );
	assign mfsm_multdone = ( mfsm_multcyc == ddlen );
	`theregrn( {mfsm_multcyc_pl3, mfsm_multcyc_pl2, mfsm_multcyc_pl1} ) <= { mfsm_multcyc_pl2, mfsm_multcyc_pl1, mfsm_multcyc };

	assign dbptr = mfsm_multcyc;
	assign dxptr = mfsm_multcyc;
	assign dyptr = mfsm_multcyc_pl3;
	`theregrn( dbrd ) <= mfsm_ldadone ? '1 : ( mfsm_multcyc == dblen - 1 ) ? '0 : dbrd;
	`theregrn( dxrd ) <= mfsm_ldadone ? (dxlen != '0) : ( mfsm_multcyc == dxlen - 1 ) ? '0 : dxrd;
	`theregrn( dywr ) <= (mfsm_multcyc==2) ? '1 : ( mfsm_multcyc_pl3 == ddlen  ) ? '0 : dywr;

	`thereg( dxreg ) <= dxrdpl1 ? dxrdat : '0;
	`theregrn( dxrdpl1 ) <= dxrd;
	`theregrn( me ) <= dbrd;
	assign medone = me & ~dbrd;
*/
	`thereg( ddlen ) <= (dblen+PL > dxlen) ? dblen+PL : dxlen;

 	`theregrn( mfsm_multcyc ) <= ~( mfsm == MFSM_MULT )|mfsm_multdone|start ? '0 : ( mfsm_multcyc + 1 );
	assign mfsm_multdone = ( mfsm_multcyc == ddlen ) & ( ddlen != 0 );
	`theregrn( {mfsm_multcyc_pl4, mfsm_multcyc_pl3, mfsm_multcyc_pl2, mfsm_multcyc_pl1} ) <= start? '0 : { mfsm_multcyc_pl3, mfsm_multcyc_pl2, mfsm_multcyc_pl1, mfsm_multcyc };

	assign dbptr = mfsm_multcyc;
	assign dxptr = mfsm_multcyc_pl1;
	assign dyptr = mfsm_multcyc_pl4;
	`theregrn( dbrd ) <= mfsm_ldadone ? '1 : ( mfsm_multcyc == dblen - 1 ) ? '0 : dbrd;
	`theregrn( dxrd ) <= ( mfsm == MFSM_MULT )&(mfsm_multcyc==0) ? (dxlen != '0) : ( mfsm_multcyc_pl1 == dxlen - 1 ) ? '0 : dxrd;
	`theregrn( dywr ) <= start ? '0 : (mfsm_multcyc_pl1==2) ? '1 : ( mfsm_multcyc_pl4 == ddlen  ) ? '0 : dywr;

	`thereg( dxreg ) <= dxrdpl1 ? dxrdat : '0;
	`thereg( dbreg ) <= dbrdpl1 ? dbrdat : dbreg;
	`theregrn( dxrdpl1 ) <= dxrd;
	`theregrn( dbrdpl1 ) <= dbrd;
	`theregrn( me ) <= dbrdpl1;
	assign medone = me & ~dbrdpl1;
endmodule


`ifdef SIM_MACCORE


module mac_core_tb ();

    integer i=0, j=0, k=0, errcnt=0, warncnt=0;

    parameter NW = 4096;
    parameter PW = 2 * NW;
	parameter PL = 4;
    parameter DW = 64;
	parameter type adr_t = bit[12:0];

	bit clk;
	bit resetn;
	bit start;
	bit medone;
	bit busy;
	bit done;
	adr_t dblen;
	adr_t dxlen;
	adr_t daptr, dbptr, dxptr, dyptr;
	bit   dard,  dbrd,  dxrd,  dywr;
	bit [DW-1:0] dardat, dbrdat, dxrdat;
	bit [DW-1:0] dywdat;
	bit [$clog2(PL):0] opt_pl;
	bit opt_sec=1;
	bit [DW-1:0] db_rnd;
	bit [PL-1:0][DW-1:0] dadat,refpcc,refpss;
	bit [(NW/DW)-1:0][DW-1:0] dbdat;
	bit [(PW/DW)-1:0][DW-1:0] dxdat;
	bit [(PW/DW)  :0][DW-1:0] dydat, refp0, refp, refy0;
	bit [DW-1:0] refy;

  //  ref0
    bit [PL*DW-1:0] VA;
	bit [NW-1:0] VB;
	bit [PW:0]   VX, VY, VP0, VY0;

	assign VP0 = VA * VB;
	assign VY0 = VP0 + VX;

//	assign tmp = VN*VNI ;

	mac_core #(
		.PL(PL),
		.DW(DW),
		.adr_t(adr_t)
	)dut(.*);


	always@( posedge clk ) trnd( DW/32, db_rnd );


	assign dblen = NW/DW;
	assign dxlen = PW/DW;

	assign dadat = VA; `theregrn( dardat ) <= dard ? dadat[daptr] : dardat;
	assign dbdat = VB; `theregrn( dbrdat ) <= dbrd ? dbdat[dbptr] : dbrdat;
	assign dxdat = VX; `theregrn( dxrdat ) <= dxrd ? dxdat[dxptr] : dxrdat;

	assign VY = dydat; `theregrn( dydat[dyptr] ) <= dywr ? dywdat : dydat[dyptr];

	genvar gvi;

	bit me, mereg, mereg1;
	bit [15:0] tmcnt;
	assign me = dut.mcell.ME;
	`theregrn( mereg ) <= me;
	`theregrn( mereg1 ) <= mereg;
	generate
		for (gvi = 0; gvi < PL; gvi++) begin:gg
			`thereg( {refpcc[gvi],refpss[gvi]} ) <= me ? dadat[gvi] * dbrdat : 0;
		end
	endgenerate

	`thereg( refp0 ) <= start? '0 : (refp0>>DW) + refpss + {refpcc,{DW{1'b0}}};
	`thereg( refp ) <= start? '0 : (tmcnt<=PW/DW+1) ? { refp0[0], (refp[(PW/DW):1])} : refp;

	`theregrn( tmcnt ) <= ( me & ~mereg ) ? 0 : tmcnt + 1;

	assign refy0 = refp + VX;
	`thereg( refy ) <= refp[0] + dxrdat;

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

    `maintest(mac_core_tb,mac_core_tb)
    resetn = 0; #(103) resetn = 1;
    #( 1 `US );

     for( j = 0; j>=0; j++)begin

$display("@i::");
    resetn = 0; #(103) resetn = 1;

    	opt_pl = (opt_pl + 1 ) % PL;

     #( 1 `US );
     	trnd((opt_pl+1)*DW/32,VA);
     	trnd(NW/32,VB);
//		VA = {32'hffffffff,32'h2,32'h0,32'h0};
//		VB = { 32'h2, 32'h1};
     	trnd(PW/32,VX);
     #( 1 `US );
     	@(negedge clk) start = 1;
     	@(negedge clk) start = 0;
     	@(posedge done);
	  #( 1 `US );

     	$display("VA  %x", VA);
     	$display("VB  %x", VB);
     	$display("VX  %x", VX);
     	$display("VY  %x", VY);
     	$display("ref %x", VY0);

     	if(VY0==VY)$display("pass!!");
     	else begin
     		$display("failed!!");
     		$stop;
     		errcnt++;
     	end

  #( 1 `US );
// $finish;

end

    `maintestend


task trnd(input bit [7:0] cnt, output bit [PW-1:0] dato);
	integer ti=0;
	dato = 0;
	for(ti=0;ti<cnt;ti++)begin
		dato = {dato, $random()};
//		dato = {dato, 32'hffffffff};
	end
endtask : trnd


endmodule : mac_core_tb


`endif

