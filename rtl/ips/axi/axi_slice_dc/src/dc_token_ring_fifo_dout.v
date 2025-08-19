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

module dc_token_ring_fifo_dout(clk, rstn, data_async, write_token, read_pointer, data, valid, ready);

    parameter                   DATA_WIDTH = 10;
    parameter                   BUFFER_DEPTH = 8;

    input  wire [DATA_WIDTH - 1 : 0]  data_async;

    input  wire                      clk;
    input  wire                      rstn;
    output wire [DATA_WIDTH - 1 : 0] data;
    output wire                      valid;
    input  wire                      ready;

    input  wire [BUFFER_DEPTH - 1 : 0] write_token;
    output wire [BUFFER_DEPTH - 1 : 0] read_pointer;

    wire                        read_enable;
    wire                        stall;
    // Pointers to the write, read addresses (two-hot encoding)
    wire [BUFFER_DEPTH - 1 : 0] read_token;

    wire [BUFFER_DEPTH - 1 : 0]  write_token_dn;
    wire [BUFFER_DEPTH - 1 : 0]  empty;

    assign data = data_async;

    assign stall = ~ready;

    // FIFO read/write enable
    assign read_enable = (valid & ~stall);

    // Logic to compute the read, write pointers
    dc_token_ring
    #(
      .BUFFER_DEPTH ( BUFFER_DEPTH ),
      .RESET_VALUE  ( 'h3          )
    )
    read_tr
    (
      .clk    ( clk         ),
      .rstn   ( rstn        ),
      .enable ( read_enable ),
      .state  ( read_token  )
    );

    // Pointers to the write, read addresses (semi-accurate, leveraging the two-hot encoding for extra robustness)
    assign read_pointer  = {read_token[BUFFER_DEPTH - 3 : 0], read_token[BUFFER_DEPTH - 1 : BUFFER_DEPTH - 2]} &
                           {read_token[BUFFER_DEPTH - 4 : 0], read_token[BUFFER_DEPTH - 1 : BUFFER_DEPTH - 3]};

    // Empty detector; if any of the bits is 1, the synchronizer is empty
    dc_synchronizer
    #(
      .WIDTH       ( BUFFER_DEPTH ),
      .RESET_VALUE ( 'hc          )
    )
    empty_synch
    (
      .clk   ( clk            ),
      .rstn  ( rstn           ),
      .d_in  ( write_token    ),
      .d_out ( write_token_dn )
    );

    assign empty = ~write_token_dn & {write_token_dn[0], write_token_dn[BUFFER_DEPTH - 1 : 1]} & {read_pointer[1 : 0], read_pointer[BUFFER_DEPTH - 1 : 2]};
    assign valid = ~(|empty);

endmodule
