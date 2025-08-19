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

module mesh #(
    parameter LC = 64,
    parameter PC = 32
)(

    input bit   clk,
    input bit   resetn,
    input bit   cmsatpg,

    apbif.slavein   apbs,
    apbif.slave     apbx,
    output logic irq
);


parameter GC = 4;
parameter GW = PC/GC;

	logic [LC-1:0] cr_mldrv, mldrvin;
	logic [LC-1:0] cr_mlie, t_mlie;
	logic [LC-1:0][GC-1:0] sr_mlsr;
	logic [LC-1:0] mldrv;
	logic [LC-1:0][PC-1:0] mlapt, apt, aptreg, apterr, t_apt;

    logic sfrlock;
    logic apbrd, apbwr;
    logic pclk;
    assign pclk = clk;
    `theregrn( sfrlock ) <= '0;
    `apbs_common;
    assign apbx.prdata = '0
                        | sfr_mldrv.prdata32
                        | sfr_mlie.prdata32 | sfr_mlsr.prdata32
                        ;

    apb_cr #(.A('h00), .DW(32), .REVY(1), .SFRCNT(LC/32))  		sfr_mldrv   (.cr(cr_mldrv), .prdata32(),.*);
    apb_cr #(.A('h10), .DW(32), .REVY(1), .SFRCNT(LC/32))  		sfr_mlie    (.cr(cr_mlie),  .prdata32(),.*);
    apb_sr #(.A('h20), .DW(32), .REVY(1), .SFRCNT(LC*GC/32))  		sfr_mlsr    (.sr(sr_mlsr),  .prdata32(),.*);

	meshlines_2d #(.LC(LC),.PC(PC)) ml(.DRV(mldrv),.APT(mlapt));

generate
	for (genvar i = 0; i < LC; i++) begin: gl
		meshlinedrv ud(.A(mldrvin[i]),.Z(mldrv[i]));
		assign mldrvin[i] = (~cmsatpg) & cr_mldrv[i];
		assign t_mlie[i] = cmsatpg ? '0 : cr_mlie[i];
		for (genvar j = 0; j < PC; j++) begin: gp
			meshlinebuf ua(.A(mlapt[i][j]),.IE(t_mlie[i]),.Z(t_apt[i][j]));
			assign apt[i][j] = cmsatpg ? '0 : t_apt[i][j];
			`theregrn( aptreg[i][j] ) <= apt[i][j];
			assign apterr[i][j] = cr_mlie[i] & ( aptreg[i][j] != cr_mldrv[i] );
		end
		for (genvar k = 0; k < GC; k++) begin: gg
			assign sr_mlsr[i][k] = |apterr[i][GW*k+GW-1:GW*k];
		end
	end
endgenerate

	`theregrn( irq ) <= | sr_mlsr;

endmodule


module meshlinedrv (
	input logic A,
	output logic Z
);

	`ifdef SYN
		BUFFD4BWP40P140HVT u (.I(A), .Z(Z));

	`else
		assign Z = A;
	`endif

endmodule


module meshlinebuf (
	input logic A,
	input logic IE,
	output logic Z
);

	`ifdef SYN
   		AN2D2BWP40P140UHVT_CDM u (.A1(A), .A2(IE), .Z(Z));

	`else
		assign Z = A & IE;
	`endif

endmodule

/*
module meshline #(
	parameter PC=32
)(
	input  logic 		DRV,
	output logic [31:0] APT
);

	`ifdef SYN
	`else

		always@(*)begin
			APT = 'X;
			APT[0] = #( 30 `US) DRV;
			APT[PC-1:1] = APT[PC-2:0];
		end

	`endif

endmodule
*/

module meshlines_2d #(
    parameter LC=64,
	parameter PC=32
)(
	input  logic [LC-1:0] DRV,
	output logic [PC*LC-1:0] APT
);

`ifdef SYN

	logic [31:0]
	APT63, APT62, APT61, APT60, APT59, APT58, APT57, APT56,
	APT55, APT54, APT53, APT52, APT51, APT50, APT49, APT48,
	APT47, APT46, APT45, APT44, APT43, APT42, APT41, APT40,
	APT39, APT38, APT37, APT36, APT35, APT34, APT33, APT32,
	APT31, APT30, APT29, APT28, APT27, APT26, APT25, APT24,
	APT23, APT22, APT21, APT20, APT19, APT18, APT17, APT16,
	APT15, APT14, APT13, APT12, APT11, APT10, APT09, APT08,
	APT07, APT06, APT05, APT04, APT03, APT02, APT01, APT00;

	assign APT = {
	APT63, APT62, APT61, APT60, APT59, APT58, APT57, APT56,
	APT55, APT54, APT53, APT52, APT51, APT50, APT49, APT48,
	APT47, APT46, APT45, APT44, APT43, APT42, APT41, APT40,
	APT39, APT38, APT37, APT36, APT35, APT34, APT33, APT32,
	APT31, APT30, APT29, APT28, APT27, APT26, APT25, APT24,
	APT23, APT22, APT21, APT20, APT19, APT18, APT17, APT16,
	APT15, APT14, APT13, APT12, APT11, APT10, APT09, APT08,
	APT07, APT06, APT05, APT04, APT03, APT02, APT01, APT00};


	meshlines u(.DRV,.*);

`elsif SIM
	logic [LC-1:0][PC-1:0] disconn=0, activepoint;

	genvar i, j;

	generate
		for (i = 0; i < LC; i++) begin
				assign activepoint[i][0] = ~disconn[i][0] ? DRV[i] : (i)%2 ;
			for (j = 1; j < PC; j++) begin
				assign activepoint[i][j] = ~disconn[i][j] ? activepoint[i][j-1] : (i+j)%2 ;
			end
		end
	endgenerate

	assign APT = activepoint;

	integer a,b;
	initial begin
		while (1) begin
			#(1 `MS );
			disconn = 0;
			a = $urandom_range(31);
			b = $urandom_range(31);
			disconn[a][b] = 1;
		end
	end
`else
	assign APT = 0;
`endif

endmodule

`ifndef SYN
module meshlines #(
    parameter LC=64,
	parameter PC=32
)(
	input  logic [LC-1:0] DRV,
	output logic [31:0] APT00,
	output logic [31:0] APT01,
	output logic [31:0] APT02,
	output logic [31:0] APT03,
	output logic [31:0] APT04,
	output logic [31:0] APT05,
	output logic [31:0] APT06,
	output logic [31:0] APT07,
	output logic [31:0] APT08,
	output logic [31:0] APT09,
	output logic [31:0] APT10,
	output logic [31:0] APT11,
	output logic [31:0] APT12,
	output logic [31:0] APT13,
	output logic [31:0] APT14,
	output logic [31:0] APT15,
	output logic [31:0] APT16,
	output logic [31:0] APT17,
	output logic [31:0] APT18,
	output logic [31:0] APT19,
	output logic [31:0] APT20,
	output logic [31:0] APT21,
	output logic [31:0] APT22,
	output logic [31:0] APT23,
	output logic [31:0] APT24,
	output logic [31:0] APT25,
	output logic [31:0] APT26,
	output logic [31:0] APT27,
	output logic [31:0] APT28,
	output logic [31:0] APT29,
	output logic [31:0] APT30,
	output logic [31:0] APT31,
	output logic [31:0] APT32,
	output logic [31:0] APT33,
	output logic [31:0] APT34,
	output logic [31:0] APT35,
	output logic [31:0] APT36,
	output logic [31:0] APT37,
	output logic [31:0] APT38,
	output logic [31:0] APT39,
	output logic [31:0] APT40,
	output logic [31:0] APT41,
	output logic [31:0] APT42,
	output logic [31:0] APT43,
	output logic [31:0] APT44,
	output logic [31:0] APT45,
	output logic [31:0] APT46,
	output logic [31:0] APT47,
	output logic [31:0] APT48,
	output logic [31:0] APT49,
	output logic [31:0] APT50,
	output logic [31:0] APT51,
	output logic [31:0] APT52,
	output logic [31:0] APT53,
	output logic [31:0] APT54,
	output logic [31:0] APT55,
	output logic [31:0] APT56,
	output logic [31:0] APT57,
	output logic [31:0] APT58,
	output logic [31:0] APT59,
	output logic [31:0] APT60,
	output logic [31:0] APT61,
	output logic [31:0] APT62,
	output logic [31:0] APT63
);
endmodule
`endif

module dummytb_mesh ();

    parameter LC = 64;
    parameter PC = 32;

    bit   clk;
    bit   resetn;
    bit   cmsatpg;
    apbif   apbs();
    apbif   apbx();
    logic irq;
	mesh u(.*);

endmodule

