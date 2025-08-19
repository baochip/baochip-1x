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
// Description: TX fifo with outstanding request support and clock domain crossing
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////


module io_tx_fifo_dc
#(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH_SYNC = 2,
    parameter BUFFER_DEPTH_ASYNC = 8
)
(
    input  logic                    src_clk_i,
    input  logic                    rstn_i,

    input  logic                    clr_i,

    input  logic                    dst_clk_i,

    output logic [DATA_WIDTH-1 : 0] dst_data_o,
    output logic                    dst_valid_o,
    input  logic                    dst_ready_i,

    output logic                    src_req_o,
    input  logic                    src_gnt_i,
    input  logic                    src_valid_i,
    input  logic [DATA_WIDTH-1 : 0] src_data_i,
    output logic                    src_ready_o
);
    localparam LOG_BUFFER_DEPTH = $clog2(BUFFER_DEPTH_SYNC);

    logic [LOG_BUFFER_DEPTH:0]      s_elements;    // number of elements in the buffer
    logic [LOG_BUFFER_DEPTH:0]      s_free_ele;    // number of free elements in the buffer
    logic [LOG_BUFFER_DEPTH:0]      r_inflight; 
    logic                           s_stop_req;  

    logic [DATA_WIDTH-1:0]          s_data;
    logic                           s_valid;
    logic                           s_ready; 

    io_generic_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH_SYNC),    
        .LOG_BUFFER_DEPTH(LOG_BUFFER_DEPTH)
    ) i_fifo (
        .clk_i(src_clk_i),
        .rstn_i(rstn_i),

        .clr_i(clr_i),

        .elements_o(s_elements),

        .data_o(s_data),
        .valid_o(s_valid),
        .ready_i(s_ready),

        .valid_i(src_valid_i),
        .data_i(src_data_i),
        .ready_o(src_ready_o)
    );

    assign s_free_ele = BUFFER_DEPTH_SYNC - s_elements;
    assign s_stop_req = (s_free_ele == r_inflight);

    assign src_req_o = src_ready_o & ~s_stop_req;

    always_ff @(posedge src_clk_i, negedge rstn_i)
    begin: elements_sequential
        if (rstn_i == 1'b0)
            r_inflight <= 0;
        else
        begin
            if(src_req_o && src_gnt_i)
            begin
                if (~src_valid_i || ~src_ready_o)
                    r_inflight <= r_inflight + 1;
            end
            else if (src_valid_i && src_ready_o)
                r_inflight <= r_inflight - 1;
        end
    end

    udma_dc_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH_ASYNC)
    ) i_dc_fifo (
        .src_clk_i   ( src_clk_i ),
        .src_rstn_i  ( rstn_i ),
        .src_data_i  ( s_data ),
        .src_valid_i ( s_valid ),
        .src_ready_o ( s_ready ),
        .dst_clk_i   ( dst_clk_i ),
        .dst_rstn_i  ( rstn_i ),
        .dst_data_o  ( dst_data_o ),
        .dst_valid_o ( dst_valid_o ),
        .dst_ready_i ( dst_ready_i )
    );
    
endmodule
