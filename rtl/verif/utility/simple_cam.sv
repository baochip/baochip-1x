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

`define ROWS 12'd8
`define COLS 12'd64
// 2 clocks per pixel required
`define HACTIVE (2 * `COLS)

`define HSYNC 12'd16
`define VSYNC 12'd2

module simple_cam (
    output logic   hsync,
    output logic   vsync,
    output logic   pclk,
    output logic   [7:0] pixels,
    input  logic   resetn
);
    // camera has an internal free-running clock
    OSC_SIM #(80)   osc_cam ( .EN('1), .CFG('0),      .CKO( pclk ) );

    logic [11:0] hcnt;
    logic [11:0] hcnt_d;
    logic [11:0] hcnt_d2;
    logic [11:0] vcnt;

    // simple sync generator
    always_ff @(posedge pclk or negedge resetn) begin
        if (~resetn) begin
            hcnt <= '0;
            vcnt <= '0;
        end else begin
            if (hcnt >= (`HACTIVE + `HSYNC)) begin
                hcnt <= 0;
            end else begin
                hcnt <= hcnt + 1;
            end
            if (vcnt >= `ROWS + `VSYNC) begin
                vcnt <= 0;
            end else begin
                if (hcnt == 0) begin
                    vcnt <= vcnt + 1;
                end else begin
                    vcnt <= vcnt;
                end
            end
        end
        hcnt_d <= hcnt;
        hcnt_d2 <= hcnt_d;
    end
    assign #0.5 hsync =  ~(((vcnt >= `VSYNC) & (hcnt_d < `HSYNC)) | (vcnt < `VSYNC));
    assign #0.5 vsync =  ~((vcnt < `VSYNC));

    // just some random values that move but also give some diagnostic hint
    assign pixels = hcnt[7:0] ^ (vcnt[3:0] << 4);
endmodule