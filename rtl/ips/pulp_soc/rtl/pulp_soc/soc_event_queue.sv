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


module soc_event_queue #(
    parameter QUEUE_SIZE = 2
) (
    input  logic clk_i,
    input  logic rstn_i,
    input  logic event_i,
    output logic err_o,
    output logic event_o,
    input  logic event_ack_i
);

    logic [1:0] r_event_count;
    logic [1:0] s_event_count;

    logic s_sample_event;


    assign err_o   = event_i & (r_event_count == 2'b11);
    assign event_o = (r_event_count != 0);

    assign s_sample_event = event_i | event_ack_i;

    always_comb
    begin : proc_s_event_count
        s_event_count = r_event_count;
        if (event_ack_i) begin
            if (!event_i && (r_event_count != 0))
                s_event_count = r_event_count - 1;
        end
        else begin
            if (r_event_count != 2'b11)
                s_event_count = r_event_count + 1;
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i)
    begin : proc_r_event_count
        if(~rstn_i) begin
            r_event_count <= 0;
        end
        else begin
            if (s_sample_event)
                r_event_count <= s_event_count;
        end
    end

endmodule // soc_event_queue
