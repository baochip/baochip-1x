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

module aobureg #(
	parameter REGCNT = 8
)(
    input logic     pclk   ,
    input logic     resetn,
    apbif.slavein   apbs,
    apbif.slave     apbx
);


	bit [REGCNT-1:0][31:0] cr_buregs;
    logic apbrd, apbwr;
    logic sfrlock;

    assign sfrlock = '0;

    `apbs_common;
    assign apbx.prdata = sfr_bureg.prdata32;

    apb_cr #(.A('h0), .DW(32), .SFRCNT(REGCNT))   sfr_bureg      (.cr( cr_buregs           ), .prdata32(),.*);



endmodule
