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


module bus_async #(
  parameter type         cp_t   = logic [31:0],
  parameter type         dp_t   = logic [31:0]
)(
	input logic resetn,
	input logic clks,
	input logic cpvalids,
	input cp_t cpdatas,
	output logic dpreadys,
	output dp_t dpdatas,

	input logic clkm,
	output logic cpvalidm,
	output cp_t cpdatam,
	input logic dpreadym,
	input dp_t dpdatam

);
bit cpvalids_sync, cpvalids_syncex;
cp_t cpdatasreg;
dp_t dpdatamreg;
bit dpm, dps, dpmdone, dpsdone;

sync_pulse cpsync ( .clka(clks), .resetn, .clkb(clkm), .pulsea (cpvalids), .pulseb( cpvalids_sync ) );

`theregfull( clks, resetn, cpdatasreg, '0 ) <= cpvalids ? cpdatas : cpdatasreg;


`theregfull( clkm, resetn, cpvalids_syncex, '0 ) <= cpvalids_sync & ~dpreadym ? '1 : dpreadym ? '0 : cpvalids_syncex;

assign cpvalidm = cpvalids_sync | cpvalids_syncex;

assign cpdatam = cpdatasreg;

`theregfull( clkm, resetn, dpm, '0 ) <= cpvalidm ? 1'b1 : dpm & dpreadym ? 1'b0 : dpm;
`theregfull( clks, resetn, dps, '0 ) <= cpvalids ? 1'b1 : dps & dpreadys ? 1'b0 : dps;

`theregfull( clks, resetn, dpreadys, '1 ) <= dpreadys & cpvalids ? 1'b0 : ~dpreadys & dpsdone ? '1 : dpreadys;

sync_pulse dpsync ( .clka(clkm), .resetn, .clkb(clks), .pulsea (dpmdone), .pulseb( dpsdone ) );

assign dpmdone = dpm & dpreadym;

`theregfull( clks, resetn, dpdatamreg, '0 ) <= dpmdone ? dpdatam : dpdatamreg;
assign dpdatas = dpdatamreg;

endmodule
