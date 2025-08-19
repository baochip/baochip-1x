// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2015-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module dc_synchronizer (clk, rstn, d_in, d_out);

    parameter WIDTH       = 1;
    parameter RESET_VALUE = 'h0;

    input  wire                 clk;
    input  wire                 rstn;
    input  wire [WIDTH - 1 : 0] d_in;
    output  [WIDTH - 1 : 0] d_out;

    reg [WIDTH - 1 : 0]    d_middle;
    reg [WIDTH - 1 : 0]    d_out;

    always @(posedge clk  or negedge rstn)
    begin: update_state
        if (rstn == 1'b0)
        begin
            d_middle <= RESET_VALUE;
            d_out    <= RESET_VALUE;
        end
        else
        begin
            d_middle <= d_in;
            d_out    <= d_middle;
        end
    end

endmodule
