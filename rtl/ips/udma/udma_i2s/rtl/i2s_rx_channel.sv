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
// Description: RX channles of I2S module
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
`define I2S_MODE_1CH_INT
`define I2S_MODE_1CH_EXT
`define I2S_MODE_2CH_INT
`define I2S_MODE_2CH_EXT

module i2s_rx_channel (
    input  logic                    sck_i,
    input  logic                    rstn_i,

    input  logic                    i2s_ch0_i,
    input  logic                    i2s_ch1_i,
    input  logic                    i2s_ws_i,

    output logic             [31:0] fifo_data_o,
    output logic                    fifo_data_valid_o,
    input  logic                    fifo_data_ready_i,

    output logic                    fifo_err_o,

    input  logic                    cfg_en_i, 
    input  logic                    cfg_2ch_i, 
    input  logic              [4:0] cfg_wlen_i, 
    input  logic              [2:0] cfg_wnum_i, 
    input  logic                    cfg_lsb_first_i
);


    logic  [1:0] r_ws_sync;
    logic        s_ws_edge;
    logic        s_ws_redge;

    logic [31:0] r_shiftreg_ch0;
    logic [31:0] r_shiftreg_ch1;
    logic [31:0] s_shiftreg_ch0;
    logic [31:0] s_shiftreg_ch1;
    logic [31:0] r_shiftreg_shadow;

    logic [4:0]  r_count_bit;
    logic [2:0]  r_count_word;

    logic        r_word_done_dly;
    logic        s_word_done;

    logic        r_started;

    assign s_ws_edge = r_ws_sync[1] ^ r_ws_sync[0]; 

    assign s_word_done = r_count_bit == cfg_wlen_i;

    assign fifo_data_o = s_word_done ? s_shiftreg_ch0 : (r_word_done_dly ? r_shiftreg_shadow : 32'h0);
    assign fifo_data_valid_o = s_word_done | (cfg_2ch_i & r_word_done_dly);
    assign fifo_err_o = fifo_data_valid_o & ~fifo_data_ready_i;

    always_comb begin : proc_shiftreg
        s_shiftreg_ch0 = r_shiftreg_ch0;
        s_shiftreg_ch1 = r_shiftreg_ch1;
        if(cfg_lsb_first_i)
        begin
            s_shiftreg_ch0 = {1'b0,r_shiftreg_ch0[31:1]};
            s_shiftreg_ch0[cfg_wlen_i] = i2s_ch0_i;
            s_shiftreg_ch1 = {1'b0,r_shiftreg_ch1[31:1]};
            s_shiftreg_ch1[cfg_wlen_i] = i2s_ch1_i;
        end
        else
        begin
            s_shiftreg_ch0 = {r_shiftreg_ch0[30:0],i2s_ch0_i};
            s_shiftreg_ch1 = {r_shiftreg_ch1[30:0],i2s_ch1_i};
        end
    end

    always_ff  @(posedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_shiftreg_ch0  <=  'h0;
            r_shiftreg_ch1  <=  'h0;
        end
        else
        begin
            if(r_started)
            begin
                r_shiftreg_ch0  <= s_shiftreg_ch0;
                if(cfg_2ch_i)
                begin
                    r_shiftreg_ch1  <= s_shiftreg_ch1;  
                    if(s_word_done)
                        r_shiftreg_shadow <= s_shiftreg_ch1;          
                end
            end
        end
    end

    always_ff  @(negedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_count_bit <= 'h0;
        end
        else
        begin
            if(r_started)
            begin
                if (s_word_done)
                    r_count_bit <= 'h0;
                else 
                    r_count_bit <= r_count_bit + 1;
            end
        end
    end

    always_ff  @(negedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_word_done_dly <= 'h0;
        end
        else
        begin
            if(r_started)
                r_word_done_dly <= s_word_done;
        end
    end

    always_ff  @(negedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_ws_sync <= 'h0;
            r_started <= 'h0;
        end
        else
        begin
            r_ws_sync <= {r_ws_sync[0],i2s_ws_i};
            if(s_ws_edge)
            begin
                if(cfg_en_i)
                    r_started <= 1'b1;
                else
                    r_started <= 1'b0;
            end
        end
    end

endmodule

