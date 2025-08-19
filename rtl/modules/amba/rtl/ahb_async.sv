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

module ahbasync#(
    parameter AW=32,
    parameter DW=32,
    parameter IDW=4,
    parameter UW=4
)(
	input logic clks,
	input logic clkm,
	input logic resetn,
	ahbif.slave ahbs,
	ahbif.master ahbm
);


  parameter type  cp_t   = logic [64-1:0];
  parameter type  dp_t   = logic [64-1:0];


	logic cpvalids;
	cp_t cpdatas;
	logic dpreadys;
	dp_t dpdatas;
	logic cpvalidm;
	cp_t cpdatam;
	logic dpreadym;
	dp_t dpdatam;

	assign cpvalids = ahbs.hsel & (|ahbs.htrans) & ahbs.hreadym & ahbs.hready;
	assign cpdatas = {
		ahbs.haddr,
		ahbs.htrans,
		ahbs.hwrite,
		ahbs.hsize,
		ahbs.hburst,
		ahbs.hprot,
		ahbs.hmaster[IDW-1:0],
		ahbs.hmasterlock,
		ahbs.hreadym,
		ahbs.hauser[UW-1:0],
		ahbs.hwuser[UW-1:0]
	};
	assign {
		ahbs.hrdata[DW-1:0],
		ahbs.hresp,
		ahbs.hruser[UW-1:0]
	} = dpdatas ;
	assign ahbs.hready = dpreadys;

	bus_async #(
	  .cp_t (cp_t),
	  .dp_t (dp_t)
	)asyncbridge(
		 .resetn,
		 .clks,
		 .cpvalids,
		 .cpdatas,
		 .dpreadys,
		 .dpdatas,

	 	 .clkm,
		 .cpvalidm,
		 .cpdatam,
		 .dpreadym,
		 .dpdatam

	);

	assign ahbm.hsel = cpvalidm;

	assign {
		ahbm.haddr,
		ahbm.htrans,
		ahbm.hwrite,
		ahbm.hsize,
		ahbm.hburst,
		ahbm.hprot,
		ahbm.hmaster[IDW-1:0],
		ahbm.hmasterlock,
		ahbm.hreadym,
		ahbm.hauser[UW-1:0],
		ahbm.hwuser[UW-1:0]
	} = cpdatam;

	assign dpreadym = ahbm.hready;
	assign dpdatam = {
		ahbm.hrdata[DW-1:0],
		ahbm.hresp,
		ahbm.hruser[UW-1:0]
	};

		assign ahbm.hwdata[DW-1:0] = 		ahbs.hwdata[DW-1:0];

endmodule


module __dummytb_ahb_async (
);
	logic clks;
	logic clkm;
	logic resetn;
	ahbif ahbs(), ahbm();

ahbasync dut(.*);

endmodule : __dummytb_ahb_async

