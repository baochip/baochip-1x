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

module mac_ref #(
    parameter NW = 256,
    parameter DW = 32,
    parameter PM = 4,
    parameter PW = 2 * NW
	)(
		input bit clk,
		input bit resetn,
		input bit [NW-1:0] VA, VB, VN, VNI,
		output bit [PW-1:0] VP,

		input bit start,
		output bit done
	);
	localparam NWW = NW/DW;
	localparam PWW = PW/DW;

	parameter MFSM_IDLE = 8'h00;
	parameter MFSM_S0   = 8'h10;
	parameter MFSM_S1   = 8'h11;
	parameter MFSM_S2   = 8'h12;
	parameter MFSM_SUB  = 8'h20;
	parameter MFSM_DONE = 8'hff;

	bit [NWW-1:0][DW-1:0] DA, DB, DN, DNI;
	bit [PWW-1:0][DW-1:0] DP;
  	bit [PWW-1:0][DW-1:0] UI, UU,UI0;	// U is intermediate variable to store the result
  	bit [DW-1:0] Dq;

	assign { DA, DB, DN, DNI } = { VA, VB, VN, VNI };
	assign VP = DP;

	bit mfsm_s0done, mfsm_s1done, mfsm_s2done, mfsm_subdone;
	bit lastrnd;
	bit [7:0] mfsm, mfsmnext, mfsmrnd;
	`theregrn(mfsm) <= mfsmnext;

	assign mfsmnext = start ? MFSM_S0 :
					  ( mfsm == MFSM_S0 & mfsm_s0done ) ? MFSM_S1 :
					  ( mfsm == MFSM_S1 & mfsm_s1done ) ? MFSM_S2 :
					  ( mfsm == MFSM_S2 & mfsm_s2done ) ? ( lastrnd ? MFSM_SUB : MFSM_S0 ) :
					  ( mfsm == MFSM_SUB & mfsm_subdone ) ? MFSM_DONE :
					  ( mfsm == MFSM_DONE ) ? MFSM_IDLE : mfsm;
	assign done = ( mfsm == MFSM_DONE );
	assign lastrnd = ( mfsmrnd == NWW - 1 );
	`theregrn( mfsmrnd ) <= start ? 0 : mfsmrnd+mfsm_s2done;

  //
  //  MFSM_S0
  //  ==

	assign mfsm_s0done = ( mfsm == MFSM_S0 );
	assign mfsm_s1done = ( mfsm == MFSM_S1 );
	assign mfsm_s2done = ( mfsm == MFSM_S2 );
	assign mfsm_subdone = ( mfsm == MFSM_SUB );

	`theregrn( UU ) <= mfsm_s0done ? UI + DA[mfsmrnd] * DB : UU;
	`theregrn( Dq ) <= mfsm_s1done ? UU[0] * DNI : Dq;
	`theregrn( UI ) <= mfsm_s2done ? (UU + Dq * DN )>>DW: UI;
	`theregrn( UI0 ) <= mfsm_s2done ? (UU + Dq * DN ): UI0;

	`theregrn( DP ) <= mfsm_subdone ? UI % VN : DP;

endmodule : mac_ref


`ifdef SIM_MACREF

module mac_ref_tb ();

    bit clk,resetn;
    integer i=0, j=0, k=0, errcnt=0, warncnt=0;
    bit start, done;

    parameter NW = 256;
    parameter DW = 32;
    parameter PM = 1;
    parameter PW = 2 * NW;

  //  ref0
	bit [NW:0] R;
	bit [NW-1:0] VA, VB, VN, VNI;
	bit [PW-1:0] VP0, VP, VP1;
	bit [PW-1:0] tmp;

	assign VP0 = VA * VB;
	assign VP1 = VP0 % VN;	//reference result for (A * B) % N
	assign R  =  257'h10000000000000000000000000000000000000000000000000000000000000000; // R's length needs to be one bit larger than N, 2^k
	assign VN  = 256'h8e54750e723d8eada99445de2b8e3e58881070949fd5891c7ab49b369e220129; // 2^(k-1) < N < 2^k
	assign VNI = 256'h2d6750782f0d51c27e24c3b564e50238a733669e4252f9dabffbfa7407e3d4e7; // VNI = N0' = R - pow(N, -1, R)
																						//pow(N, -1, R) is calculating the modular inverse of N under R

//	assign tmp = VN*VNI ;

	mac_ref #( .NW(NW), .DW(DW), .PM(PM))dut(
		.clk,
		.resetn,
		.VA, .VB, .VN, .VNI,
		.VP,
		.start,
		.done
		);
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

    `maintest(mac_ref_tb,mac_ref_tb)
$display("Test start");
    resetn = 0; #(103) resetn = 1;
    #( 1 `US );

     for( j = 0; j>=0; j++)begin

    resetn = 0; #(103) resetn = 1;

     #( 1 `US );
     	trnd(VA);
     	trnd(VB);
     #( 1 `US );

    // 	@(negedge clk) start = 1;
    // 	@(negedge clk) start = 0;


    //     #( 100 `US );
    // end

	//assign VA = 256'h8e54750e723d8eada99445de2b8e3e58881070949fd5891c7ab49b369e233333;
	//assign VB = 256'h8e54750e723d8eada99445de2b8e3e58881070949fd5891c7ab49b369e220122;

	     	@(negedge clk) start = 1;
     	@(negedge clk) start = 0;

  #( 10 `US );
	$display("VP  %x", VP * R % VN); // To compare with the original result, we need to convert the result from montgomery field back to ordinary
    $display("VP1 %x", VP1);
//$stop;
end

    `maintestend


task trnd(output bit [NW-1:0] dato);
	integer ti=0;
	for(ti=0;ti<NW/32;ti++)begin
		dato = {dato, $random()};
	end
endtask : trnd


endmodule : mac_ref_tb
`endif