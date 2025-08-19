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

module dc_token_ring(clk, rstn, enable, state);

    parameter                     BUFFER_DEPTH = 8;
    parameter                     RESET_VALUE = 'h3;

    input  wire                        clk;
    input  wire                        rstn;
    input  wire                        enable;
    output  [BUFFER_DEPTH - 1 : 0] state;

    reg [BUFFER_DEPTH - 1 : 0]    state;
    reg [BUFFER_DEPTH - 1 : 0]    next_state;

    always @(posedge clk or negedge rstn)
    begin: update_state
        if (rstn == 1'b0)
            state <= RESET_VALUE;
        else
            state <= next_state;
    end

    always @(enable, state)
    begin
        if (enable)
            next_state = {state[BUFFER_DEPTH - 2 : 0], state[BUFFER_DEPTH - 1]};
        else
            next_state = state;
    end

endmodule
