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
// Description: TX fifo with SOF and EOF marking capabilities
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module io_tx_fifo_mark
#(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH = 2,
    parameter LOG_BUFFER_DEPTH = $clog2(BUFFER_DEPTH)
)
(
    input  logic                    clk_i,
    input  logic                    rstn_i,

    input  logic                    clr_i,

    output logic                    req_o,
    input  logic                    gnt_i,
    input  logic                    sof_i,
    input  logic                    eof_i,

    output logic [DATA_WIDTH-1 : 0] data_o,
    output logic                    sof_o,
    output logic                    eof_o,
    output logic                    valid_o,
    input  logic                    ready_i,

    input  logic                    valid_i,
    input  logic [DATA_WIDTH-1 : 0] data_i,
    output logic                    ready_o
);
    localparam FIFO_WIDTH=DATA_WIDTH+2;
    
    logic [LOG_BUFFER_DEPTH:0]      s_elements;    // number of elements in the buffer
    logic [LOG_BUFFER_DEPTH:0]      s_free_ele;    // number of free elements in the buffer
    logic [LOG_BUFFER_DEPTH:0]      r_inflight; 
    logic [LOG_BUFFER_DEPTH:0]      r_mark_sof_cnt; 
    logic [LOG_BUFFER_DEPTH:0]      r_mark_eof_cnt; 
    logic                           s_stop_req;  
    logic                           s_mark_sof_evt;
    logic                           s_mark_eof_evt;
    logic                           s_mark_sof_dec;
    logic                           s_mark_eof_dec;
    logic                           s_mark; 
    logic                           r_issof;

    logic [FIFO_WIDTH-1:0] s_fifoin;
    logic [FIFO_WIDTH-1:0] s_fifoout;

    assign s_fifoin = {s_mark_eof_evt,s_mark_sof_evt,data_i};

    assign data_o = s_fifoout[DATA_WIDTH-1:0];
    assign sof_o  = s_fifoout[FIFO_WIDTH-2];
    assign eof_o  = s_fifoout[FIFO_WIDTH-1];

    io_generic_fifo #(
        .DATA_WIDTH(FIFO_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH),    
        .LOG_BUFFER_DEPTH(LOG_BUFFER_DEPTH)
    ) i_fifo (
        .clk_i(clk_i),
        .rstn_i(rstn_i),

        .clr_i(clr_i),

        .elements_o(s_elements),

        .data_o(s_fifoout),
        .valid_o(valid_o),
        .ready_i(ready_i),

        .valid_i(valid_i),
        .data_i(s_fifoin),
        .ready_o(ready_o)
    );

    assign s_free_ele = BUFFER_DEPTH - s_elements;
    assign s_stop_req = (s_free_ele == r_inflight);

    assign s_mark_sof_dec = (r_mark_sof_cnt != 0);
    assign s_mark_sof_evt = (r_mark_sof_cnt == 1) & (valid_i & ready_o);
    assign s_mark_eof_dec = (r_mark_eof_cnt != 0);
    assign s_mark_eof_evt = (r_mark_eof_cnt == 1) & (valid_i & ready_o);

    assign req_o = ready_o & ~s_stop_req;

    always_ff @(posedge clk_i, negedge rstn_i)
    begin: elements_sequential
        if (rstn_i == 1'b0)
        begin
            r_inflight <= 0;
            r_mark_sof_cnt  <= 0;
            r_mark_eof_cnt  <= 0;
        end
        else
        begin
            if(sof_i)
            begin
                if ((req_o && gnt_i) && (~valid_i || ~ready_o))
                    r_mark_sof_cnt <= r_inflight + 1;
                else
                    r_mark_sof_cnt <= r_inflight;
            end
            else if (s_mark_sof_dec && (valid_i && ready_o))
            begin
                r_mark_sof_cnt <= r_mark_sof_cnt - 1;
            end

            if(eof_i)
            begin
                if ((req_o && gnt_i) && (~valid_i || ~ready_o))
                    r_mark_eof_cnt <= r_inflight + 1;
                else
                    r_mark_eof_cnt <= r_inflight;
            end
            else if (s_mark_eof_dec && (valid_i && ready_o))
            begin
                r_mark_eof_cnt <= r_mark_eof_cnt - 1;
            end

            if(req_o && gnt_i)
            begin
                if (~valid_i || ~ready_o)
                    r_inflight <= r_inflight + 1;
            end
            else if (valid_i && ready_o)
                r_inflight <= r_inflight - 1;
        end
    end


endmodule
