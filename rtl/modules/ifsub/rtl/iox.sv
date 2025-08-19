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
//    `include "amba_interface_def_v0.2.sv"
//    `include "io_interface_def_v0.1.sv"

module iox #(
		parameter IOC = 64,
		parameter IOCW = $clog2(IOC),
		parameter GW = 16,
		parameter GC = IOC/GW,
        parameter AFC = 4, // fixed
        parameter AFCW = $clog2(AFC), // fixed
		parameter INTC = 8
	)(
	input logic clksys,    // Clock
	input logic pclk,    // Clock
	input logic resetn, // Clock Enable
	input logic cmsbist,
	input logic cmsatpg,
    input logic sfrlock,

    apbif.slavein  apbs,
    apbif.slave    apbx,
    output logic wkupvld, wkupvld_async,
    output logic intvld,
    output logic [0:IOC-1] iopi,
    output logic [0:31] piosel,
    input logic [0:IOC-1][AFC-1:0] afconnmask,
    ioif.load  afpad1[0:IOC-1],
    ioif.load  afpad2[0:IOC-1],
    ioif.load  afpad3[0:IOC-1],
    ioif.drive  iopad[0:IOC-1],

    output padcfg_arm_t  iocfg[0:IOC-1]


);

    ioif       afpad0[0:IOC-1]();
    genvar     i, j;
    logic      clk;

    logic apbrd, apbwr;

	assign clk = pclk;

  //
  //  io mtx
  //  ==

    localparam SELC = 16/AFCW;

    logic [0:IOC*AFCW/16-1][15:0]   crafsel;
    logic [0:IOC-1][AFCW-1:0]       afsel;
    logic [0:IOC-1]                 iopireg0, iopireg, iopi_async;
	iomtx #(
			.IOC (IOC),
			.AFC (AFC)
		)iomtx(.afpad0(afpad0),.afsel(afsel),.*);

	apb_cr #(.A('h00), .DW(16), .SFRCNT(IOC*AFCW/16)) sfr_afsel  (.cr(crafsel), .prdata32(),.*);

    generate
        for (i = 0; i < IOC; i++) begin : genpi
            `thereg( iopireg0[i] ) <= iopad[i].pi;
            `thereg( iopireg[i]  ) <= iopireg0[i];
            assign iopi[i] = iopireg[i];
            assign iopi_async[i] = iopad[i].pi;
        end
        for( i=0; i< IOC/SELC;i++) begin:genafsel
            assign { afsel[i*SELC+7],afsel[i*SELC+6],afsel[i*SELC+5],afsel[i*SELC+4],afsel[i*SELC+3],afsel[i*SELC+2],afsel[i*SELC+1],afsel[i*SELC+0] } = crafsel[i];
        end
    endgenerate

  //
  //  int
  //  ==

    bit [0:INTC-1][IOCW-1:0]     ctl_intsel;
    bit [0:INTC-1][1:0]          ctl_intmode;
    bit [0:INTC-1]               ctl_inten, ctl_intvld, ctl_wkupen, wkupvlds, wkupvlds_async, frint ;
    bit [0:INTC-1][IOCW+4-1:0] 	 crint;

    localparam INTMD_RISE = 2'h0;
    localparam INTMD_FALL = 2'h1;
    localparam INTMD_HIGH = 2'h2;
    localparam INTMD_LOW  = 2'h3;

    bit [0:INTC-1]    intsrc, intsrcreg0, intsrcreg, intsrcrise, intsrcfall, intvldpre, intsrc_async;

    generate
    	for( i = 0; i < INTC; i = i + 1) begin: genint

    	assign { ctl_wkupen[i], ctl_inten[i], ctl_intmode[i], ctl_intsel[i] }= crint[i];

 //     `theregrn( intsrc_async[i] ) <= iopi_async[ctl_intsel[i]];
        assign intsrc_async[i] = iopi_async[ctl_intsel[i]];

        `theregrn( intsrc[i] ) <= iopi[ctl_intsel[i]];
        `theregrn( intsrcreg0[i] ) <= intsrc[i];
        `theregrn( intsrcreg[i] ) <= intsrcreg0[i];
        `theregrn( intsrcrise[i] ) <= intsrcreg0[i] & ~intsrcreg[i];
        `theregrn( intsrcfall[i] ) <= ~intsrcreg0[i] & intsrcreg[i];

        assign intvldpre[i] =
                 ( ctl_intmode[i] == INTMD_HIGH ) ? intsrc[i] :
                 ( ctl_intmode[i] == INTMD_LOW  ) ? ~intsrc[i] :
                 ( ctl_intmode[i] == INTMD_RISE ) ? intsrcrise[i] :
                 ( ctl_intmode[i] == INTMD_FALL ) ? intsrcfall[i] : 1'b0;
        `theregrn( ctl_intvld[i] ) <= ctl_inten[i] & intvldpre[i];

       assign wkupvlds[i] = ctl_wkupen[i] & ( ctl_intmode[i][0] ^ intsrc[i] );
 //        assign wkupvlds[i] = ctl_wkupen[i] & ~( ctl_intmode[i][0] ^ intsrc[i] );
        assign wkupvlds_async[i] = ctl_wkupen[i] & ( ctl_intmode[i][0] ^ intsrc_async[i] );
    	end
    endgenerate

    assign intvld = |frint;
    assign wkupvld = |wkupvlds;
    assign wkupvld_async = |wkupvlds_async;
    assign frint = ctl_intvld;

	apb_cr #(.A('h100),      .DW(IOCW+4), .SFRCNT(INTC))  sfr_intcr  (.cr(crint), .prdata32(),.*);
    apb_fr #(.A('h100+INTC*4), .DW(INTC)    )        		 sfr_intfr  (.fr(frint), .prdata32(),.*);

  //
  //  gpio
  //  ==

    parameter GPIOSFRC = IOC / 16;

    logic [0:IOC-1] crgo, crgoe, crgpu, srgi, crgo0, crgoe0, crgpu0;

    wire2ioif_rev #(IOC)gpioif(
    	.ioout 	(crgo0),
    	.iooe  	(crgoe0),
    	.iopu  	(crgpu0),
    	.ioin  	(),
    	.ioifdrv(afpad0)
    	);

	apb_cr #(.A('h130             ), .DW(16), .SFRCNT(GPIOSFRC)		 ) sfr_gpioout  (.cr(crgo ), .prdata32(),.*);
	apb_cr #(.A('h130+GPIOSFRC*1*4), .DW(16), .SFRCNT(GPIOSFRC)		 ) sfr_gpiooe   (.cr(crgoe), .prdata32(),.*);
	apb_cr #(.A('h130+GPIOSFRC*2*4), .DW(16), .SFRCNT(GPIOSFRC), .IV(16'hffff)) sfr_gpiopu   (.cr(crgpu), .prdata32(),.*);
    apb_sr #(.A('h130+GPIOSFRC*3*4), .DW(16), .SFRCNT(GPIOSFRC) 		 ) sfr_gpioin   (.sr(srgi ), .prdata32(),.*);

    generate
        for( i=0; i< GPIOSFRC;i++) begin:gengpio
            assign {  crgo0[i*16+15],
                      crgo0[i*16+14],
                      crgo0[i*16+13],
                      crgo0[i*16+12],
                      crgo0[i*16+11],
                      crgo0[i*16+10],
                      crgo0[i*16+9],
                      crgo0[i*16+8],
                      crgo0[i*16+7],
                      crgo0[i*16+6],
                      crgo0[i*16+5],
                      crgo0[i*16+4],
                      crgo0[i*16+3],
                      crgo0[i*16+2],
                      crgo0[i*16+1],
                      crgo0[i*16+0] } = crgo[i*16:i*16+15];
            assign { crgoe0[i*16+15],
                     crgoe0[i*16+14],
                     crgoe0[i*16+13],
                     crgoe0[i*16+12],
                     crgoe0[i*16+11],
                     crgoe0[i*16+10],
                     crgoe0[i*16+9],
                     crgoe0[i*16+8],
                     crgoe0[i*16+7],
                     crgoe0[i*16+6],
                     crgoe0[i*16+5],
                     crgoe0[i*16+4],
                     crgoe0[i*16+3],
                     crgoe0[i*16+2],
                     crgoe0[i*16+1],
                     crgoe0[i*16+0] } = crgoe[i*16:i*16+15];
            assign { crgpu0[i*16+15],
                     crgpu0[i*16+14],
                     crgpu0[i*16+13],
                     crgpu0[i*16+12],
                     crgpu0[i*16+11],
                     crgpu0[i*16+10],
                     crgpu0[i*16+9],
                     crgpu0[i*16+8],
                     crgpu0[i*16+7],
                     crgpu0[i*16+6],
                     crgpu0[i*16+5],
                     crgpu0[i*16+4],
                     crgpu0[i*16+3],
                     crgpu0[i*16+2],
                     crgpu0[i*16+1],
                     crgpu0[i*16+0] } = crgpu[i*16:i*16+15];
            assign   srgi[i*16:i*16+15] =
                               { iopi[i*16+15],
                                 iopi[i*16+14],
                                 iopi[i*16+13],
                                 iopi[i*16+12],
                                 iopi[i*16+11],
                                 iopi[i*16+10],
                                 iopi[i*16+9],
                                 iopi[i*16+8],
                                 iopi[i*16+7],
                                 iopi[i*16+6],
                                 iopi[i*16+5],
                                 iopi[i*16+4],
                                 iopi[i*16+3],
                                 iopi[i*16+2],
                                 iopi[i*16+1],
                                 iopi[i*16+0] };
        end
    endgenerate

    bit [0:GPIOSFRC-1][15:0]cr_cfg_schmsel;
    bit [0:GPIOSFRC-1][15:0]cr_cfg_slewslow;
    bit [0:GPIOSFRC-1][15:0][1:0]cr_cfg_drvsel;

    apb_cr #(.A('h230             ), .DW(16), .SFRCNT(GPIOSFRC)      ) sfr_cfg_schm   (.cr( cr_cfg_schmsel  ), .prdata32(),.*);
    apb_cr #(.A('h230+GPIOSFRC*1*4), .DW(16), .SFRCNT(GPIOSFRC)      ) sfr_cfg_slew   (.cr( cr_cfg_slewslow ), .prdata32(),.*);
    apb_cr #(.A('h230+GPIOSFRC*2*4), .DW(32), .SFRCNT(GPIOSFRC)      ) sfr_cfg_drvsel (.cr( cr_cfg_drvsel   ), .prdata32(),.*);


    generate
        for (i = 0; i < GPIOSFRC; i++) begin: gcfgi
            for (j = 0; j < 16; j++) begin: gcfgj
                assign iocfg[i*16+j] =
                            '{
                                schmsel:    cr_cfg_schmsel[i][j],
                                anamode:    '0,
                                slewslow:   cr_cfg_slewslow[i][j],
                                drvsel:     cr_cfg_drvsel[i][j][1:0]
                            };
            end
        end
    endgenerate



// pio sel ( mux is out of iox )
// ==

    apb_cr #(.A('h200), .DW(32), .REVX(1) ) sfr_piosel   (.cr(piosel), .prdata32(),.*);

// sfr
// ==

    `apbs_common;
    assign apbx.prdata = '0
    					| sfr_afsel.prdata32
						| sfr_intcr.prdata32 | sfr_intfr.prdata32
						| sfr_gpioout.prdata32 | sfr_gpiooe.prdata32 | sfr_gpiopu.prdata32 | sfr_gpioin.prdata32
                        | sfr_piosel.prdata32
                        | sfr_cfg_schm.prdata32 | sfr_cfg_slew.prdata32 | sfr_cfg_drvsel.prdata32
						;

endmodule


//
//
//
//

module iomtx #(
		parameter IOC = 64,
		parameter AFC = 4
//		parameter [0:IOC-1][AFC-1:0]afconnmask = '1
	)(

	input logic cmsbist,
	input logic cmsatpg,
	input logic [0:IOC-1][$clog2(AFC)-1:0] afsel,

    input logic [0:IOC-1][AFC-1:0] afconnmask,
    ioif.load  afpad0[0:IOC-1],
    ioif.load  afpad1[0:IOC-1],
    ioif.load  afpad2[0:IOC-1],
    ioif.load  afpad3[0:IOC-1],
    ioif.drive  iopad[0:IOC-1]
);

	genvar gvi;
	logic [0:IOC-1] afseldefault;

    generate
    	for( gvi = 0; gvi < IOC; gvi = gvi + 1) begin: geni

	assign iopad[gvi].po = 	( afsel[gvi] == 3 ) & afconnmask[gvi][3] ? afpad3[gvi].po :
							( afsel[gvi] == 2 ) & afconnmask[gvi][2] ? afpad2[gvi].po :
							( afsel[gvi] == 1 ) & afconnmask[gvi][1] ? afpad1[gvi].po :
						   											   afpad0[gvi].po;

	assign iopad[gvi].oe = 	( afsel[gvi] == 3 ) & afconnmask[gvi][3] ? afpad3[gvi].oe :
							( afsel[gvi] == 2 ) & afconnmask[gvi][2] ? afpad2[gvi].oe :
							( afsel[gvi] == 1 ) & afconnmask[gvi][1] ? afpad1[gvi].oe :
									 								   afpad0[gvi].oe;

	assign iopad[gvi].pu =  ( afsel[gvi] == 3 ) & afconnmask[gvi][3] ? afpad3[gvi].pu :
						    ( afsel[gvi] == 2 ) & afconnmask[gvi][2] ? afpad2[gvi].pu :
							( afsel[gvi] == 1 ) & afconnmask[gvi][1] ? afpad1[gvi].pu :
																	   afpad0[gvi].pu;

	assign afpad3[gvi].pi = ( afsel[gvi] == 3 ) & afconnmask[gvi][3] ? iopad[gvi].pi : '1;
	assign afpad2[gvi].pi = ( afsel[gvi] == 2 ) & afconnmask[gvi][2] ? iopad[gvi].pi : '1;
	assign afpad1[gvi].pi = ( afsel[gvi] == 1 ) & afconnmask[gvi][1] ? iopad[gvi].pi : '1;
	assign afpad0[gvi].pi = afseldefault[gvi]                        ? iopad[gvi].pi : '1;

	assign afseldefault[gvi] = ~(( afsel[gvi] == 3 ) & afconnmask[gvi][3]
						   		|( afsel[gvi] == 2 ) & afconnmask[gvi][2]
						   		|( afsel[gvi] == 1 ) & afconnmask[gvi][1]);

    	end
    endgenerate

endmodule


module dummytb_iox();
        parameter IOC = 64;
        parameter IOCW = $clog2(IOC);
        parameter GW = 16;
        parameter GC = IOC/GW;
        parameter AFC = 4; // fixed
        parameter AFCW = $clog2(AFC); // fixed
        parameter INTC = 8;

    bit clksys;
    bit pclk;
    bit resetn;
    bit cmsbist;
    bit cmsatpg;
    bit wkupvld, wkupvld_async;
    bit intvld;
    bit sfrlock;
    bit [0:31] piosel;
    bit [0:IOC-1][AFC-1:0] afconnmask;
    apbif  apbs();
    apbif  apbx();
    ioif  afpad1[0:IOC-1]();
    ioif  afpad2[0:IOC-1]();
    ioif  afpad3[0:IOC-1]();
    ioif  iopad[0:IOC-1]();
    logic [0:IOC-1] iopi;
    apbm_null2 u0(apbs);
    ioifdrv_nulls #(IOC) uaf1 (.ioifdrv(afpad1));
    ioifdrv_nulls #(IOC) uaf2 (.ioifdrv(afpad2));
    ioifdrv_nulls #(IOC) uaf3 (.ioifdrv(afpad3));
    ioifld_nulls  #(IOC) uio  (.ioifld (iopad));
    iox #(.IOC(IOC))u1(.*, .apbs(apbs),.afpad1(afpad1),.afpad2(afpad2),.afpad3(afpad3));
    padcfg_arm_t  iocfg[0:IOC-1];

    `ifdef DUMMYTB_IOX_FSDB
        `maintest(dummytb_iox,dummytb_iox)
            #105 ;
            #(1 `MS);
        `maintestend
    `endif

endmodule
