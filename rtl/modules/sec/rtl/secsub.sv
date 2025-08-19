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

module secsub #(
	    parameter MESHLC    = 64,
	    parameter MESHPC    = 32,
	    parameter SENSORVDC = 8,
	    parameter SENSORLDC = 4,
		parameter GLCX      = 32,
		parameter GLCY      = 32

)(
	input logic clksys, // clksys
	input logic pclk,
	input logic pclkmesh,
	input logic porresetn,
	input logic resetn,
	input logic cmsatpg,
    input logic [SENSORVDC-1:0] vd,
    input logic [SENSORLDC-1:0] ld,
    output logic [2+SENSORVDC/2-1:0] vdena,
    output logic [SENSORVDC-1:0]   vdtst,
    output logic [SENSORLDC-1:0]   ldtst,
    output logic             ldclk,
    output logic vdresetn,
    output logic [7:0] irq8,
    apbif.slave apbs
);

	logic meshirq, sensorcirq, glcirq;
    apbif #(.PAW(12),.DW(32)) apbsec[0:15]();
    apb_mux  #(.DECAW(4)) apbsecmux(.apbslave (apbs), .apbmaster(apbsec));
    apbs_nulls #(.SLVCNT(2)) apbsec_null0 (apbsec[0:1]);
    apbs_nulls #(.SLVCNT(11)) apbsec_null1 (apbsec[5:15]);

`ifndef MPW
	mesh #(
	    .LC ( MESHLC ),
	    .PC ( MESHPC )
	)meshc(
	    .clk 		( pclkmesh ),
	    .resetn,
	    .cmsatpg,
	    .apbs 		( apbsec[2] ),
	    .apbx 		( apbsec[2] ),
	    .irq		( meshirq )
	);
`else
	apbs_null mesh_apbnull(apbsec[2]);
	assign meshirq = '0;
`endif

	sensorc #(
	    .VDC (SENSORVDC),
	    .LDC (SENSORLDC)
	)sensorc(
	    .clk 		( pclk ),
	    .clksys,
	    .resetn 	( porresetn ),
	    .cmsatpg,
	    .apbs 		( apbsec[3] ),
	    .apbx 		( apbsec[3] ),
		.vdena,
		.vdtst,
		.ldtst,
		.ldclk,
	    .vd,
	    .ld,
	    .vdresetn,
	    .irq		( sensorcirq )
	);

	gluechain #(
		.GCX ( GLCX ),
		.GCY ( GLCY )
	)glc(
	    .clk 		( pclk ),
	    .clksys,
	    .resetn,
	    .cmsatpg,
	    .apbs 		( apbsec[4] ),
	    .apbx 		( apbsec[4] ),
		.irq    	( glcirq )
	);

	assign irq8 = {meshirq, sensorcirq, glcirq} | '0;

endmodule

module dummytb_secsub ();
	    parameter MESHLC    = 32;
	    parameter MESHPC    = 32;
	    parameter SENSORVDC = 8;
	    parameter SENSORLDC = 4;
		parameter GLCX      = 32;
		parameter GLCY      = 32;
	logic clksys;
	logic cmsatpg;
	logic pclk,pclkmesh;
	logic porresetn;
	logic resetn;
    logic [SENSORVDC-1:0] vd;
    logic [SENSORLDC-1:0] ld;
    logic vdresetn;
    logic [7:0] irq8;
    apbif #(.PAW(16)) apbs();
    logic [2+SENSORVDC/2-1:0] vdena;
    logic [SENSORVDC-1:0]   vdtst;
    logic [SENSORLDC-1:0]   ldtst;
    logic             ldclk;
	secsub u(
		.clksys, // clksys
		.pclk,
		.porresetn,
		.resetn,
	    .vd,
	    .ld,
	    .vdresetn,
	    .irq8,
	    .apbs,
	    .*
	);

endmodule


