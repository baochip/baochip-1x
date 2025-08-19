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
// Description: Generic counter
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
module io_event_counter
#(
    parameter COUNTER_WIDTH = 6
)
(
    input  logic clk_i,
    input  logic rstn_i,
    input  logic event_i,
    input  logic counter_rst_i,
    input  logic [COUNTER_WIDTH-1:0] counter_target_i,
    output logic [COUNTER_WIDTH-1:0] counter_value_o,
    output logic counter_trig_o
);
    logic [COUNTER_WIDTH-1:0] counter;
    logic [COUNTER_WIDTH-1:0] counter_next;

    logic                   trigger;
    logic                   trigger_old;

    always_comb
    begin
        if (counter_rst_i)
            counter_next = 'h0;
        else if (event_i)
        begin
            if (counter == counter_target_i)
                counter_next = 'h1;
            else
                counter_next = counter + 1;
        end
        else
            counter_next = counter;
    end

    always_comb
    begin
        if (counter == counter_target_i)
            trigger = 1'b1;
        else
            trigger = 1'b0;
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            trigger_old <= 1'b0;
            counter     <= 'h0;
        end
        else
        begin
            trigger_old <= trigger;
            counter     <= counter_next;
        end
    end

    assign counter_value_o = counter;

    assign counter_trig_o = ~trigger_old & trigger;

endmodule