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

module i2s_tx_channel (
    input  logic                    sck_i,
    input  logic                    rstn_i,

    output logic                    i2s_ch0_o,
    output logic                    i2s_ch1_o,
    input  logic                    i2s_ws_i,

    input  logic             [31:0] fifo_data_i,
    input  logic                    fifo_data_valid_i,
    output logic                    fifo_data_ready_o,

    output logic                    fifo_err_o,

    input  logic                    cfg_en_i, 
    input  logic                    cfg_2ch_i, 
    input  logic              [4:0] cfg_wlen_i, 
    input  logic              [2:0] cfg_wnum_i, 
    input  logic                    cfg_lsb_first_i
);


    logic  [1:0] r_ws_sync;
    logic        s_ws_edge;

    logic [31:0] r_shiftreg_ch0;
    logic [31:0] r_shiftreg_ch1;
    logic [31:0] s_shiftreg_ch0;
    logic [31:0] s_shiftreg_ch1;
    logic [31:0] r_shiftreg_shadow;
    logic [31:0] s_shiftreg_shadow;

    logic        s_sample_in;
    logic        s_sample_sr0;
    logic        s_sample_sr1;
    logic        s_sample_swd;
    logic        s_update_cnt;

    logic [4:0]  r_count_bit;
    logic [2:0]  r_count_word;

    logic        s_word_done;

    logic        r_started;
    logic s_word_done_pre, s_i2s_ch0, s_i2s_ch1;
    enum logic [1:0] {ST_START,ST_SAMPLE,ST_WAIT,ST_RUNNING} r_state,s_state;

    assign s_ws_edge = i2s_ws_i ^ r_ws_sync[0]; 

    assign s_word_done     = r_count_bit == cfg_wlen_i;
    assign s_word_done_pre = r_count_bit == (cfg_wlen_i - 1);
    assign fifo_data_ready_o = s_sample_in;

    assign s_i2s_ch0 = cfg_lsb_first_i ? r_shiftreg_ch0[0] : r_shiftreg_ch0[cfg_wlen_i];
    assign s_i2s_ch1 = cfg_lsb_first_i ? r_shiftreg_ch1[0] : r_shiftreg_ch1[cfg_wlen_i];

    always_comb begin : proc_SM
        s_sample_in  = 1'b0;
        s_update_cnt = 1'b0;
        s_sample_sr0 = 1'b0;
        s_sample_sr1 = 1'b0;
        s_sample_swd = 1'b0;
        s_shiftreg_ch0    = r_shiftreg_ch0;
        s_shiftreg_ch1    = r_shiftreg_ch1;
        s_shiftreg_shadow = r_shiftreg_shadow;
        s_state = r_state;
        case(r_state)
            ST_START:
            begin
                if(fifo_data_valid_i)
                begin
                    s_sample_in    = 1'b1;
                    s_sample_sr0   = 1'b1;
                    s_shiftreg_ch0 = fifo_data_i;
                    s_state = ST_SAMPLE;
                end
            end
            ST_SAMPLE:
            begin
                if(fifo_data_valid_i)
                begin
                    s_sample_in    = 1'b1;
                    s_sample_sr1   = 1'b1;
                    s_shiftreg_ch1 = fifo_data_i;
                    s_state = ST_WAIT;
                end
            end
            ST_WAIT:
            begin
                if(s_ws_edge)
                    s_state = ST_RUNNING;
            end
            ST_RUNNING:
            begin
                s_update_cnt = 1'b1;
                s_sample_sr0 = 1'b1;
                s_sample_sr1 = cfg_2ch_i;
                if(s_word_done_pre)
                begin
                    if(cfg_2ch_i)
                    begin
                        s_sample_in    = 1'b1;
                        s_shiftreg_shadow = fifo_data_i;
                        s_sample_swd      = 1'b1;
                    end
                end
                if(s_word_done)
                begin
                    s_sample_in = 1'b1;                    
                    if(cfg_2ch_i)
                        s_shiftreg_ch0 = r_shiftreg_shadow; 
                    else
                        s_shiftreg_ch0 = fifo_data_i; 
                    s_shiftreg_ch1 = fifo_data_i; 
                end
                else
                begin
                    if(cfg_lsb_first_i)
                    begin
                        s_shiftreg_ch0 = {1'b0,r_shiftreg_ch0[31:1]};
                        s_shiftreg_ch1 = {1'b0,r_shiftreg_ch1[31:1]};
                    end
                    else
                    begin
                        s_shiftreg_ch1 = {r_shiftreg_ch1[30:0],1'b0};
                        s_shiftreg_ch0 = {r_shiftreg_ch0[30:0],1'b0};
                    end
                end
            end
        endcase // r_state
    end

    always_ff  @(posedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
            r_state <= ST_START;
        else
            r_state <= s_state;
    end

    always_ff  @(posedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_shiftreg_ch0  <=  'h0;
            r_shiftreg_ch1  <=  'h0;
            r_shiftreg_shadow <= 'h0;
        end
        else
        begin
            if(s_sample_sr0)
                r_shiftreg_ch0  <= s_shiftreg_ch0;
            if(s_sample_sr1)
                r_shiftreg_ch1  <= s_shiftreg_ch1;
            if(s_sample_swd)
                r_shiftreg_shadow  <= s_shiftreg_shadow;
        end
    end

    always_ff  @(posedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_count_bit <= 'h0;
        end
        else
        begin
            if(s_update_cnt)
            begin
                if (s_word_done)
                    r_count_bit <= 'h0;
                else 
                    r_count_bit <= r_count_bit + 1;
            end
        end
    end

    always_ff  @(posedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_ws_sync <= 'h0;
        end
        else
        begin
            r_ws_sync <= {r_ws_sync[0],i2s_ws_i};
        end
    end

    always_ff  @(negedge sck_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            i2s_ch0_o <= 'h0;
            i2s_ch1_o <= 'h0;
        end
        else
        begin
            i2s_ch0_o <= s_i2s_ch0;
            i2s_ch1_o <= s_i2s_ch1;
        end
    end




endmodule

