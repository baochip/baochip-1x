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
// Description: I2S WS signal generator
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////


module i2s_ws_gen
(
    input  logic                    sck_i,
    input  logic                    rstn_i,
    input  logic                    cfg_ws_en_i,

    output logic                    ws_o,

    input  logic              [4:0] cfg_data_size_i,
    input  logic              [2:0] cfg_word_num_i
);

    logic  [4:0] r_counter;
    logic  [2:0] r_word_counter;

    //Generate the internal WS signal
    always_ff  @(posedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_counter      <= 'h0;
            r_word_counter <= 'h0;
        end
        else
        begin
            if (cfg_ws_en_i)
            begin
                if(r_counter == cfg_data_size_i)
                begin
                    r_counter <= 'h0;
                    if(r_word_counter == cfg_word_num_i)
                        r_word_counter <= 'h0;
                    else
                        r_word_counter <= r_word_counter + 1;
                end
                else
                    r_counter <= r_counter + 1;
            end
        end
    end

    //Generate the internal WS signal
    always_ff  @(negedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            ws_o       <= 1'b0;
        end
        else
        begin
            if (cfg_ws_en_i)
            begin
                if( (r_counter == cfg_data_size_i) && (r_word_counter == cfg_word_num_i))
                    ws_o <= ~ws_o;
            end
        end
    end

endmodule

