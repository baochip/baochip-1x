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


module itcm16kx18x2 (
  output logic [17:0] q,
  input logic  clk,
  input logic  cen,
  input logic  gwen,
  input logic [14:0] a,
  input logic [17:0] d,
  input logic [17:0] wen,
  input logic  stov,
  input logic [2:0] ema,
  input logic [1:0] emaw,
  input logic  emas,
  input logic  ret1n,
  input logic  rawl,
  input logic [1:0] rawlm,
  input logic  wabl,
  input logic [1:0] wablm
);

logic uqsel;
logic [1:0][17:0] uq;

`thereg(uqsel) <= cen ? uqsel : a[14];
assign q = uqsel ? uq[1]:uq[0];

generate
        for (genvar i = 0; i < 2; i++) begin: gr

                logic usel, ucen, ugwen;
                logic [17:0] uwen;

                assign usel = (a[14] == i);
                assign uwen = usel ? wen : '1;
                assign ucen = usel ? cen : '1;
                assign ugwen = usel ? gwen : '1;

                itcm16kx18 u(
                        .q       (uq[i]),
                        .clk     (clk),
                        .cen     (ucen),
                        .gwen    (ugwen),
                        .a       (a[13:0]),
                        .d       (d),
                        .wen     (uwen),
                        .stov    ,
                        .ema     ,
                        .emaw    ,
                        .emas    ,
                        .ret1n   ,
                        .rawl    ,
                        .rawlm   ,
                        .wabl    ,
                        .wablm
                );

        end
endgenerate

endmodule
