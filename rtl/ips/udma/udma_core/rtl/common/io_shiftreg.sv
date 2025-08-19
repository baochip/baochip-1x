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
// Description: Generic shift register
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
module io_shiftreg
#(
    parameter DATA_WIDTH = 32
)
(
    input  logic [DATA_WIDTH-1:0] data_i,
    output logic [DATA_WIDTH-1:0] data_o,
    input  logic                  serial_i,
    output logic                  serial_o,
    input  logic                  load_i,
    input  logic                  shift_i,
    input  logic                  lsbfirst_i,
    input  logic                  clk_i,
    input  logic                  rstn_i
);

    logic [DATA_WIDTH-1:0] shift_reg;
    logic [DATA_WIDTH-1:0] shift_reg_next;

    always_comb
    begin
        if (load_i)
            if (shift_i)
                if (lsbfirst_i)
                    shift_reg_next = {serial_i,data_i[DATA_WIDTH-1:1]};
                else
                    shift_reg_next = {data_i[DATA_WIDTH-2:0],serial_i};
            else
                shift_reg_next = data_i[DATA_WIDTH-1:0];
        else if (shift_i)
            if (lsbfirst_i)
                shift_reg_next = {serial_i,shift_reg[DATA_WIDTH-1:1]};
            else
                shift_reg_next = {shift_reg[DATA_WIDTH-2:0],serial_i};
        else
            shift_reg_next = shift_reg;
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
            shift_reg <= 'h0;
        else
            shift_reg <= shift_reg_next;
    end

    assign data_o = shift_reg;
    assign serial_o = lsbfirst_i ? shift_reg[0] : shift_reg[DATA_WIDTH-1];

endmodule

