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

// Assumes: clk_a is slower than clk_faster

module cdc_level_to_pulse (
    input  wire          reset,
    input  wire          clk_a,
    input  wire          clk_faster,
    input  wire          in_a,
    output wire          out_b
);

logic in_a_d;
always_ff @(posedge clk_a) begin
    in_a_d <= in_a;
end

logic [2:0] pulse;
always_ff @(posedge clk_faster) begin
    pulse[2] <= ~in_a_d & in_a;
    pulse[1] <= pulse[2];
    pulse[0] <= pulse[1];
end

assign out_b = ~pulse[0] & pulse[1];
endmodule
