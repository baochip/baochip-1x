// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

///////////////////////////////////////////////////////////////////////////////
//
// Description: RX FIFO with clock domain crossing capabilities
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_dc_fifo #(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH = 8
) (
    input  logic                  src_clk_i,
    input  logic                  src_rstn_i,
    input  logic [DATA_WIDTH-1:0] src_data_i,
    input  logic                  src_valid_i,
    output logic                  src_ready_o,
    input  logic                  dst_clk_i,
    input  logic                  dst_rstn_i,
    output logic [DATA_WIDTH-1:0] dst_data_o,
    output logic                  dst_valid_o,
    input  logic                  dst_ready_i
    );

  logic [DATA_WIDTH-1:0] data_async;
  logic [BUFFER_DEPTH-1:0] write_token;
  logic [BUFFER_DEPTH-1:0] read_pointer;

 dc_token_ring_fifo_din #(
    .DATA_WIDTH(DATA_WIDTH),
    .BUFFER_DEPTH(BUFFER_DEPTH)
    ) u_din (
    .clk(src_clk_i),
    .rstn(src_rstn_i),
    .data(src_data_i),
    .valid(src_valid_i),
    .ready(src_ready_o),
    .write_token(write_token),
    .read_pointer(read_pointer),
    .data_async(data_async));

 dc_token_ring_fifo_dout #(
    .DATA_WIDTH(DATA_WIDTH),
    .BUFFER_DEPTH(BUFFER_DEPTH)
    ) u_dout (.clk(dst_clk_i),
    .rstn(dst_rstn_i),
    .data(dst_data_o),
    .valid(dst_valid_o),
    .ready(dst_ready_i),
    .write_token(write_token),
    .read_pointer(read_pointer),
    .data_async(data_async));

endmodule
