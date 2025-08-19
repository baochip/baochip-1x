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

module jtagtap #(
	parameter SETCNT = 5,
	parameter integer REGW[0:SETCNT-1] = {64,64,64,64,64},
	parameter REGWMAX = 64,
	parameter [REGWMAX-1:0] REGIV[0:SETCNT-1] = {64'h0, 64'h0, 64'h0, 64'h0, 64'h0}
) (
//	input logic clk,    // Clock
	input logic resetn, // Clock Enable
	jtagif.slave jtags,
	input logic enable,
	input  bit [SETCNT-1:0][REGWMAX-1:0] regin,
	output bit [SETCNT-1:0][REGWMAX-1:0] regout,
	output bit [SETCNT-1:0] regset
);

logic tap_shiftdr, tap_updatedr, tap_capturedr, tap_tdo;
logic jtags_resetn;
assign jtags_resetn = enable & resetn & jtags.trst;

logic [SETCNT-1:0] regsel, tap_tdi;


  tap_top  #(.SETCNT(SETCNT))u_tap(
    // jtag
    .tms_i      ( jtags.tms ),
    .tck_i      ( jtags.tck ),
    .rst_ni     ( jtags_resetn ),
    .td_i       ( jtags.tdi ),
    .td_o       ( jtags.tdo ),
    // tap states
    .shift_dr_o     (tap_shiftdr),
    .update_dr_o    (tap_updatedr),
    .capture_dr_o   (tap_capturedr),
    // select signals for boundary scan or mbist
    .scan_sel_o   (regsel),
    // tdo signal connected to tdi of sub modules
    .scan_in_o      (tap_tdo),
    // tdi signals from sub modules
    .scan_out_i   (tap_tdi)
  );

genvar i;

generate
	for ( i = 0; i < SETCNT; i++) begin: genreg
    jtagreg #(
        .JTAGREGSIZE(REGW[i]),
        .IV(REGIV[i]),
        .SYNC(0)
    ) i_jtagreg1 (
        .clk_i           (jtags.tck ),
        .rst_ni          (jtags_resetn ),
        .enable_i        (regsel[i]),
        .capture_dr_i    (tap_capturedr),
        .shift_dr_i      (tap_shiftdr),
        .update_dr_i     (tap_updatedr),
        .jtagreg_in_i    (regin[i][REGW[i]-1:0]),
        .mode_i          (enable),
        .scan_in_i       (tap_tdo),
        .scan_out_o      (tap_tdi[i]),
        .jtagreg_out_o   (regout[i][REGW[i]-1:0])
    );
	assign regset[i] = tap_updatedr & regsel[i];
	end
endgenerate


endmodule : jtagtap




