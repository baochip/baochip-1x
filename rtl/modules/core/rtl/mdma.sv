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

module mdma #(
		parameter CHNLC = 8,
		parameter AHBMID4 = 7,
		parameter EVC = 256
	)(
	input logic clk,
	input logic resetn,

	input  logic [EVC-1:0]  evin,
	output logic 			irq,
	output logic 			err,

	ahbif.master ahbm,
	apbif.slave apbs_dma,
	apbif.slavein apbs,
	apbif.slave apbx
);

	logic [CHNLC-1:0] dma_req;              // DMA transfer request
	logic [CHNLC-1:0] dma_sreq;             // DMA single transfer request
	logic [CHNLC-1:0] dma_waitonreq;        // DMA wait for request fall
	logic             dma_stall;            // DMA transfer stall
	logic [CHNLC-1:0] dma_active;           // DMA transfer active
	logic [CHNLC-1:0] dma_done;             // DMA transfer done
	logic             dma_err;              // DMA slave response not OK
	logic 			  hresetn;
	assign err = dma_err;
	assign irq = |dma_done;
	assign dma_stall = '0;
	assign hresetn = resetn;

	pl230_udma u(
		.hclk           (clk            ),    // AMBA bus clock
		.hresetn        (hresetn        ),    // AMBA bus reset
		.dma_req        (dma_req        ),    // DMA transfer request
		.dma_sreq       (dma_sreq       ),    // DMA single transfer request
		.dma_waitonreq  (dma_waitonreq  ),    // DMA wait for request fall
		.dma_stall      (dma_stall      ),    // DMA transfer stall
		.dma_active     (dma_active     ),    // DMA transfer active
		.dma_done       (dma_done       ),    // DMA transfer done
		.dma_err        (dma_err        ),    // DMA slave response not OK
		.hready         (ahbm.hready    ),    // AHB slave ready
		.hresp          (ahbm.hresp     ),    // AHB slave response
		.hrdata         (ahbm.hrdata    ),    // AHB read data
		.htrans         (ahbm.htrans    ),    // AHB transfer enable
		.hwrite         (ahbm.hwrite    ),    // AHB transfer direction
		.haddr          (ahbm.haddr     ),    // AHB address
		.hsize          (ahbm.hsize     ),    // AHB transfer size
		.hburst         (ahbm.hburst    ),    // AHB burst length
		.hmastlock      (ahbm.hmasterlock ),    // AHB locked access control
		.hprot          (ahbm.hprot     ),    // AHB protection control
		.hwdata         (ahbm.hwdata    ),    // AHB write data
		.pclken         (1'b1               ),    // APB clock enable
		.psel           (apbs_dma.psel      ),    // APB peripheral select
		.pen            (apbs_dma.penable   ),    // APB transfer enable
		.pwrite         (apbs_dma.pwrite    ),    // APB transfer direction
		.paddr          (apbs_dma.paddr     ),    // APB address
		.pwdata         (apbs_dma.pwdata    ),    // APB write data
		.prdata         (apbs_dma.prdata    )     // APB read data
	);

	assign ahbm.hsel = '1;
	assign ahbm.hmaster = AHBMID4;
	assign ahbm.hreadym = ahbm.hready;//'1;
	assign ahbm.hauser = AHBMID4 |'0;
	assign ahbm.hwuser = '0;

	assign apbs_dma.pready = '1;
	assign apbs_dma.pslverr = '0;

	parameter EVCW = $clog2(EVC);
	logic [0:CHNLC-1][4:0] cr_mdmareq;
	logic [0:CHNLC-1][4:0] sr_mdmareq;
	logic [0:CHNLC-1][EVCW-1:0] cr_evsel;
	logic [EVC-1:0] dma_reqin;

	logic pclk;
	assign pclk = clk;

    logic apbrd, apbwr;
    `apbs_common;
    logic sfrlock;
    assign sfrlock = '0;
    assign apbx.prdata = '0
                | sfr_evsel.prdata32 |  sfr_cr.prdata32 | sfr_sr.prdata32
                ;

	apb_cr #(.A('h00),  	   .DW(EVCW), .SFRCNT(CHNLC))  sfr_evsel   (.cr(cr_evsel  ),   .prdata32(),.*);
	apb_cr #(.A('h00+CHNLC*4  ), .DW(5),    .SFRCNT(CHNLC))  sfr_cr      (.cr(cr_mdmareq),   .prdata32(),.*);
	apb_sr #(.A('h00+CHNLC*8  ), .DW(5),    .SFRCNT(CHNLC))  sfr_sr      (.sr(sr_mdmareq),   .prdata32(),.*);

	generate
		for (genvar i = 0; i < CHNLC; i++) begin: greq
			assign dma_reqin[i] = evin[cr_evsel[i]];
			mdmareq u(
				.clk,
				.resetn,
				.cr ( cr_mdmareq[i] ),
				.sr ( sr_mdmareq[i] ),
				.dmareqin ( dma_reqin[i] ),
				.dmareq ( dma_req[i] ),
				.dmareqs ( dma_sreq[i] ),
				.dmawaitonreq ( dma_waitonreq[i] ),
				.dmaactive ( dma_active[i] )
			);
		end
	endgenerate

endmodule

module mdmareq(
	input logic clk,
	input logic resetn,

	input  logic [4:0] 	cr,
	output logic [4:0] 	sr,
	input  logic 		dmareqin,
	output logic dmareq,
	output logic dmareqs,
	output logic dmawaitonreq,
//	output logic dmastall,

	input  logic dmaactive
//	input logic dmadone,
//	input logic dmaerr
);

	logic 		cr_en;
	logic 		cr_mode; // 0: level, 1: pulse
	logic [1:0] cr_reqen;
	logic 		cr_waiton;
	logic 		cr_mode1;

	logic [3:0] quelen, quelennext;
	logic  		fr_queof;
	logic 		dmareqinreg, dmareqrise, dmareqsig;
	logic 		dmaactreg, dmaactrise;

	assign { cr_waiton, cr_reqen[1:0], cr_mode, cr_en } = cr;
	assign sr = { fr_queof, quelen };

	assign cr_mode1 = ( cr_mode == '1 );
	`theregrn( dmareqinreg ) <= dmareqin;
	`theregrn( dmareqrise ) <= dmareqin & ~dmareqinreg;
	assign dmareqsig = cr_mode1 ? dmareqrise : dmareqinreg;

	assign dmareq  = cr_en & cr_reqen[0] & dmareqsig;
	assign dmareqs = cr_en & cr_reqen[1] & dmareqsig;

	assign dmawaitonreq = cr_waiton;

	`theregrn( dmaactreg ) <= dmaactive;
	assign dmaactrise = dmaactive & ~dmaactreg;

	`theregrn( quelen ) <= cr_en & cr_mode1 ? quelennext : '0;
	assign quelennext = (  dmareqrise & ~dmaactrise ) ? quelen + 1 :
						( ~dmareqrise &  dmaactrise ) ? quelen - 1 : quelen;

	`theregrn( fr_queof ) <= cr_en & cr_mode1 ? (( quelen > 1 ) | fr_queof ) : '0;

endmodule : mdmareq

module dummytb_mdma ();
	parameter EVC = 256;
	logic clk;
	logic resetn;
	logic [EVC-1:0] evin;
	logic 			irq;
	logic 			err;
	ahbif  ahbm();
	apbif #(.PAW(12)) apbs_dma(), apbs(), apbx();

	mdma u(.*);

endmodule
