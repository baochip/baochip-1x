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

module fdre_cosim(
    output wire Q,
    input wire R,
    input wire C,
    input wire CE,
    input wire D
);

    reg inner_Q;
    // force the asic synthesis tool to infer an async, active-low reset FF
    always @(posedge C or posedge R) begin
        if(R) begin
            inner_Q <= 0;
        end else begin
            if(CE) begin
                inner_Q <= D;
            end else begin
                inner_Q <= Q;
            end
        end
    end
    assign Q = inner_Q;

endmodule