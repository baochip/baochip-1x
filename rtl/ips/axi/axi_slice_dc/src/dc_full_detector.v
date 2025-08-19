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

module dc_full_detector(clk, rstn, read_pointer, write_pointer, valid, full);

    parameter                    BUFFER_DEPTH = 8;

    input  wire                        clk;
    input  wire                        rstn;
    input  wire [BUFFER_DEPTH - 1 : 0] read_pointer;
    input  wire [BUFFER_DEPTH - 1 : 0] write_pointer;
    input  wire                        valid;
    output wire                        full;

    wire                         fifo_full;
    wire                         fifo_1_free;
    wire                         fifo_2_free;
    wire                         full_dn;
    wire                         full_up;
    reg                          latched_full_s;

    assign fifo_full = |(read_pointer & {write_pointer[BUFFER_DEPTH - 2 : 0], write_pointer[BUFFER_DEPTH - 1]});
    assign fifo_1_free = |(read_pointer & {write_pointer[BUFFER_DEPTH - 3 : 0], write_pointer[BUFFER_DEPTH - 1 : BUFFER_DEPTH - 2]});
    assign fifo_2_free = |(read_pointer & {write_pointer[BUFFER_DEPTH - 4 : 0], write_pointer[BUFFER_DEPTH - 1 : BUFFER_DEPTH - 3]});
    assign full_dn = (fifo_full | fifo_1_free | fifo_2_free);

    dc_synchronizer
    #(
      .WIDTH(1),
      .RESET_VALUE(1'b0)
    )
    full_synch
    (
      .clk   ( clk     ),
      .rstn  ( rstn    ),
      .d_in  ( full_dn ),
      .d_out ( full_up )
    );

    always @(posedge clk  or negedge rstn)
    begin: full_evaluator
        if (rstn == 1'b0)
            latched_full_s <= 1'b0;
        else
            latched_full_s <= full_up | valid;
    end

    assign full = latched_full_s & full_up;

endmodule
