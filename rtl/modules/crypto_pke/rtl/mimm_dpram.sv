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

module mimm_dpram #(
	parameter AW = 8,
	parameter DW = 64,
	parameter DCNT = 2**AW
)(
	input  bit cmsatpg, cmsbist,
	rbif.slavedp rbs,
	input  bit clk,
	input  bit [AW-1:0] waddr,
	input  bit wr,
	input  bit [DW-1:0] wdata,
	input  bit [AW-1:0] raddr,
	input  bit rd,
	output bit [DW-1:0] rdata,
	output bit parityerr
);


`ifdef FPGA
    bramdp #(.AW(AW),.DW(DW))u(
        .rclk(clk),
        .wclk(clk),
        .rramaddr(raddr),
        .wramaddr(waddr),
        .rramrd(rd),
        .wramwr(wr),
        .rramrdata(rdata),
        .wramwdata(wdata)
        );
    assign parityerr = '0;
`else


	`ifdef SIM
		bit [DCNT-1:0][DW-1:0] memdata;
		bit [DW-1:0] rdata0;
		`thereg(memdata[waddr]) <= wr ? wdata : memdata[waddr];
		`thereg(rdata0) <= rd ? memdata[raddr] : 'hDEAD_C0DE;
	`endif

    logic clka, clkb, cena, cenb;

     logic [7:0][7:0] rdata64, wdata64;
     logic [8:0][7:0] rdata72, wdata72;
     logic [71:0] wenb;
     logic [7:0]  rdataerr;
     logic rdatavld;

     logic clkdp;
    CLKCELL_BUF ckbuf_clkdp( .A(clk), .Z(clkdp));
    ICG icga(.CK(clkdp),.EN(~cena),.SE(cmsatpg),.CKG(clka));
    ICG icgb(.CK(clkdp),.EN(~cenb),.SE(cmsatpg),.CKG(clkb));
    assign #0.5 cena = ~( rd );
    assign #0.5 cenb = ~( wr );

    assign wenb = wr ? '0 : '1;

    assign wdata64 = wdata;
    assign rdata64 = rdata72[7:0];
    assign rdata = rdata64;

    genvar i;
    generate
    	for (i = 0; i < 8; i++) begin: genparity
    		assign wdata72[8][i] = ^wdata64[i];
    		assign wdata72[i] = wdata64[i];
    		assign rdataerr[i] = rdatavld & (rdata72[8][i] != ^rdata72[i]);
    	end
    endgenerate

    `thereg( rdatavld ) <= rd;

    assign parityerr = |rdataerr;

    logic rb_clka, rb_cena, rb_clkb, rb_cenb;
    logic [AW-1:0] rb_aa, rb_ab;
    logic [  71:0] rb_wenb, rb_qa, rb_db;

    rbdpmux #(.AW(AW),.DW(72))rbmux(
         .cmsatpg   ,
         .cmsbist   ,
            .clka     (clka     ),.clkb      (clkb     ),
            .qa       (rdata72  ),.qb        (         ),
            .cena     (cena     ),.cenb      (cenb     ),
            .gwena    ('1       ),.gwenb     ('1       ),
            .wena     ('1       ),.wenb      (wenb     ),
            .aa       (raddr    ),.ab        (waddr    ),
            .da       ('0       ),.db        (wdata72  ),
            .rb_clka  (rb_clka  ),.rb_clkb   (rb_clkb  ),
            .rb_qa    (rb_qa    ),.rb_qb     ('0       ),
            .rb_cena  (rb_cena  ),.rb_cenb   (rb_cenb  ),
            .rb_gwena (         ),.rb_gwenb  (         ),
            .rb_wena  (         ),.rb_wenb   (rb_wenb  ),
            .rb_aa    (rb_aa    ),.rb_ab     (rb_ab    ),
            .rb_da    (         ),.rb_db     (rb_db    ),
         .rbs         (rbs)
       );

	sce_mimmdpram m(

		.clka   (rb_clka   ),
		.cena   (rb_cena   ),
		.aa     (rb_aa     ),
		.qa     (rb_qa     ),
		.clkb   (rb_clkb   ),
		.cenb   (rb_cenb   ),
		.wenb   (rb_wenb   ),
		.ab     (rb_ab     ),
		.db     (rb_db     ),
	///*  input        */    .STOV   ('0),
	///*  input [2:0]  */    .EMAA   ('0),
	///*  input        */    .EMASA  ('0),
	///*  input [2:0]  */    .EMAB   ('0),
	///*  input        */    .RET1N  ('1)
	`rf_2p_hdc_inst
	);


`endif

endmodule : mimm_dpram
