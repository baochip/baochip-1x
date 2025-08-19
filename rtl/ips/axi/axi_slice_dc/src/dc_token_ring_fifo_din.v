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

module dc_token_ring_fifo_din(clk, rstn, data, valid, ready, write_token, read_pointer, data_async);

    parameter                   DATA_WIDTH = 10;
    parameter                   BUFFER_DEPTH = 8;

    input logic                       clk;
    input logic                       rstn;
    input logic [DATA_WIDTH - 1 : 0]  data;
    input logic                       valid;
    output logic                     ready;

    output logic [BUFFER_DEPTH - 1 : 0] write_token;
    input  logic [BUFFER_DEPTH - 1 : 0] read_pointer;

    output logic [DATA_WIDTH - 1 : 0] data_async;

    wire                        stall;
    wire                        write_enable;
    wire [BUFFER_DEPTH - 1 : 0] write_pointer;

    assign ready = ~stall;

    // FIFO read/write enable
    assign write_enable = (valid & ready);

    // Actual FIFO
    dc_data_buffer
    #(
      .DATA_WIDTH   ( DATA_WIDTH   ),
      .BUFFER_DEPTH ( BUFFER_DEPTH )
    )
    buffer
    (
      .clk           ( clk           ),
      .rstn          ( rstn          ),
      .write_enable  ( write_enable  ),
      .write_pointer ( write_pointer ),
      .write_data    ( data          ),
      .read_pointer  ( read_pointer  ),
      .read_data     ( data_async    )
    );

    // Logic to compute the read, write pointers
    dc_token_ring
    #(
      .BUFFER_DEPTH ( BUFFER_DEPTH ),
      .RESET_VALUE  ( 'hc          )
    )
    write_tr
    (
      .clk    ( clk          ),
      .rstn   ( rstn         ),
      .enable ( write_enable ),
      .state  ( write_token  )
    );

    // Pointers to the write, read addresses (semi-accurate, leveraging the two-hot encoding for extra robustness)
    assign write_pointer = {write_token[BUFFER_DEPTH - 2 : 0], write_token[BUFFER_DEPTH - 1]} & write_token;

    // Full detector
    dc_full_detector
    #(
      .BUFFER_DEPTH ( BUFFER_DEPTH )
    )
    full
    (
      .clk           ( clk           ),
      .rstn          ( rstn          ),
      .read_pointer  ( read_pointer  ),
      .write_pointer ( write_pointer ),
      .valid         ( valid         ),
      .full          ( stall         )
    );

endmodule
