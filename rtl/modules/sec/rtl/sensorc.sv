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

module sensorc #(
    parameter VDC = 8,
    parameter LDC = 4
)(

    input bit   clk,
    input bit   clksys,
    input bit   resetn,
    input bit   cmsatpg,

    apbif.slavein   apbs,
    apbif.slave     apbx,

    input logic [VDC-1:0] vd,
    input logic [LDC-1:0] ld,

    output logic [VDC/2+2-1:0] vdena,
    output logic [VDC-1:0]   vdtst,
    output logic [LDC-1:0]   ldtst,
    output logic             ldclk,

    output logic vdresetn,
    output logic irq
);

	logic [VDC-1:0] cr_vdmask0, cr_vdmask1, sr_vdsr;
	logic [LDC-1:0] cr_ldmask,  sr_ldsr;
	logic [3:0] cr_ldcfg;
	logic [0:VDC-1][3:0] cr_vdcfg;
    logic [15:0] ldfdcnt, ldfd;
    logic [VDC-1:0] vds, vdflag, vdreg;
    bit [0:VDC-1][3:0] vdcnt;
    logic [LDC-1:0] lds, ldflag, ldreg;
    logic [LDC-1:0][3:0] ldcnt;

    logic sfrlock;
    logic apbrd, apbwr;
    logic pclk;
    assign pclk = clk;
    `theregrn( sfrlock ) <= '0;
    `apbs_common;
    assign apbx.prdata = '0
                        | sfr_vdmask0.prdata32 | sfr_vdmask1.prdata32 | sfr_vdsr.prdata32 | sfr_vdfr.prdata32
                        | sfr_ldmask.prdata32  | sfr_ldsr.prdata32
                        | sfr_ldcfg.prdata32 | sfr_vdcfg.prdata32
                        | sfr_vdip_ena.prdata32 | sfr_vdip_test.prdata32
                        | sfr_ldip_test.prdata32 | sfr_ldip_fd.prdata32
                        ;

    apb_cr #(.A('h00), .DW(VDC), .IV({VDC{1'b1}}) )  		sfr_vdmask0   (.cr(cr_vdmask0), .prdata32(),.*); // irq mask
    apb_cr #(.A('h04), .DW(VDC), .IV({VDC{1'b1}}) )  		sfr_vdmask1   (.cr(cr_vdmask1), .prdata32(),.*); // reset mask
    apb_sr #(.A('h08), .DW(VDC) )       sfr_vdsr      (.sr(vdflag),    .prdata32(),.*);
    apb_fr #(.A('h0C), .DW(VDC) )       sfr_vdfr      (.fr(vdflag),    .prdata32(),.*);

    apb_cr #(.A('h10), .DW(LDC) )  		sfr_ldmask    (.cr(cr_ldmask),  .prdata32(),.*);
    apb_sr #(.A('h14), .DW(LDC) )  		sfr_ldsr      (.sr(sr_ldsr),    .prdata32(),.*);
    apb_cr #(.A('h18), .DW(4)   )  		sfr_ldcfg     (.cr(cr_ldcfg),   .prdata32(),.*);

    apb_cr #(.A('h20), .DW(4), .SFRCNT(VDC) )  		sfr_vdcfg   (.cr(cr_vdcfg), .prdata32(),.*);

    apb_cr #(.A('h40), .DW(VDC/2+2), .IV({2'h0,{VDC/2{1'b1}}}) ) sfr_vdip_ena     (.cr(vdena),   .prdata32(),.*);
    apb_cr #(.A('h44), .DW(VDC) )           sfr_vdip_test    (.cr(vdtst),   .prdata32(),.*);

    apb_cr #(.A('h48), .DW(LDC) )           sfr_ldip_test    (.cr(ldtst),   .prdata32(),.*);
    apb_cr #(.A('h4C), .DW(16), .IV('h1FF) )            sfr_ldip_fd      (.cr(ldfd),    .prdata32(),.*);

    `theregfull( clksys, resetn, ldfdcnt, '0) <= ( ldfdcnt == ldfd ) ? '0 : ldfdcnt + 1;
    `theregfull( clksys, resetn, ldclk, '0) <= ( ldfdcnt == ldfd ) ^ ldclk;


    logic vdresetnreg;

	`theregfull(clksys, resetn, vds, '1 ) <= vd;
	assign sr_vdsr = vdflag & ~cr_vdmask0;
//	assign vdresetn = & ( cr_vdmask1 ? '1 : ~vdflag );
    `theregfull(clksys, resetn, vdresetnreg, '1 ) <= & ( cr_vdmask1 ? '1 : ~vdflag );
    always@(posedge clksys) vdresetn <= vdresetnreg;

	generate
		for (genvar i = 0; i < VDC; i++) begin: gvd
			assign vdflag[i] = ( cr_vdcfg[i] == 0 ) ? ~vd[i] : vdreg[i];
			`theregfull(clksys, resetn, vdreg[i], '0 ) <= ( vdcnt[i] == cr_vdcfg[i] );
			`theregfull(clksys, resetn, vdcnt[i], '0 ) <= vds[i] ? '0 : ( vdcnt[i] == cr_vdcfg[i] ) ? vdcnt[i] : vdcnt[i] + 1;
		end
	endgenerate

	`theregfull(clksys, resetn, lds, '0 ) <= ld;
	assign sr_ldsr = ldflag & ~cr_ldmask;
	assign ldflag = ldreg;

	generate
		for (genvar i = 0; i < LDC; i++) begin: gld
			`theregfull(clksys, resetn, ldreg[i], '0 ) <= ( ldcnt[i] == cr_ldcfg+1 );
			`theregfull(clksys, resetn, ldcnt[i], '0 ) <= ~lds[i] ? '0 : ( ldcnt[i] == cr_ldcfg+1 ) ? ldcnt[i] : ldcnt[i] + 1;
		end
	endgenerate

	`theregrn( irq ) <= | { sr_vdsr, sr_ldsr };

endmodule : sensorc

module dummytb_sensor ();
    parameter VDC = 8;
    parameter LDC = 4;
    bit   clk;
    bit   clksys;
    bit   resetn;
    bit   cmsatpg;
    apbif   apbs();
    apbif   apbx();
    logic [VDC-1:0] vd;
    logic [LDC-1:0] ld;
    logic vdresetn;
    logic irq;
    logic [2+VDC/2-1:0] vdena;
    logic [VDC-1:0]   vdtst;
    logic [LDC-1:0]   ldtst;
    logic             ldclk;

    sensorc u(.*);

endmodule

