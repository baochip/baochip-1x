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
// Description: Configuration IP for uDMA and filtering block
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

// SPI Master Registers
`define REG_TX_CH0_ADD  5'b00000 //BASEADDR+0x00
`define REG_TX_CH0_CFG  5'b00001 //BASEADDR+0x04
`define REG_TX_CH0_LEN0 5'b00010 //BASEADDR+0x08
`define REG_TX_CH0_LEN1 5'b00011 //BASEADDR+0x0C
`define REG_TX_CH0_LEN2 5'b00100 //BASEADDR+0x10
`define REG_TX_CH1_ADD  5'b00101 //BASEADDR+0x14
`define REG_TX_CH1_CFG  5'b00110 //BASEADDR+0x18
`define REG_TX_CH1_LEN0 5'b00111 //BASEADDR+0x1C
`define REG_TX_CH1_LEN1 5'b01000 //BASEADDR+0x20
`define REG_TX_CH1_LEN2 5'b01001 //BASEADDR+0x24
`define REG_RX_CH_ADD   5'b01010 //BASEADDR+0x28
`define REG_RX_CH_CFG   5'b01011 //BASEADDR+0x2C
`define REG_RX_CH_LEN0  5'b01100 //BASEADDR+0x30
`define REG_RX_CH_LEN1  5'b01101 //BASEADDR+0x34
`define REG_RX_CH_LEN2  5'b01110 //BASEADDR+0x38
`define REG_AU_CFG      5'b01111 //BASEADDR+0x3C
`define REG_AU_REG0     5'b10000 //BASEADDR+0x40
`define REG_AU_REG1     5'b10001 //BASEADDR+0x44
`define REG_BINCU_TH    5'b10010 //BASEADDR+0x48
`define REG_BINCU_CNT   5'b10011 //BASEADDR+0x4C
`define REG_BINCU_SETUP 5'b10100 //BASEADDR+0x50
`define REG_BINCU_VAL   5'b10101 //BASEADDR+0x54
`define REG_FILT        5'b10110 //BASEADDR+0x58
`define REG_FILT_CMD    5'b10111 //BASEADDR+0x5C
`define REG_STATUS      5'b11000 //BASEADDR+0x60

module udma_filter_reg_if
  #(
    parameter L2_AWIDTH_NOAL = 15,
    parameter TRANS_SIZE     = 15
    )
   (
    input logic                             clk_i,
    input logic                             rstn_i,

    input logic [31:0]                      cfg_data_i,
    input logic [4:0]                       cfg_addr_i,
    input logic                             cfg_valid_i,
    input logic                             cfg_rwn_i,
    output logic [31:0]                     cfg_data_o,
    output logic                            cfg_ready_o,

    output logic [3:0]                      cfg_filter_mode_o,
    output logic                            cfg_filter_start_o,

    output logic [1:0] [L2_AWIDTH_NOAL-1:0] cfg_filter_tx_start_addr_o,
    output logic [1:0] [1:0]                cfg_filter_tx_datasize_o,
    output logic [1:0] [1:0]                cfg_filter_tx_mode_o,
    output logic [1:0] [TRANS_SIZE-1:0]     cfg_filter_tx_len0_o,
    output logic [1:0] [TRANS_SIZE-1:0]     cfg_filter_tx_len1_o,
    output logic [1:0] [TRANS_SIZE-1:0]     cfg_filter_tx_len2_o,

    output logic [L2_AWIDTH_NOAL-1:0]       cfg_filter_rx_start_addr_o,
    output logic [1:0]                      cfg_filter_rx_datasize_o,
    output logic [1:0]                      cfg_filter_rx_mode_o,
    output logic [TRANS_SIZE-1:0]           cfg_filter_rx_len0_o,
    output logic [TRANS_SIZE-1:0]           cfg_filter_rx_len1_o,
    output logic [TRANS_SIZE-1:0]           cfg_filter_rx_len2_o,

    output logic                            cfg_au_use_signed_o,
    output logic                            cfg_au_bypass_o,
    output logic [3:0]                      cfg_au_mode_o,
    output logic [4:0]                      cfg_au_shift_o,
    output logic [31:0]                     cfg_au_reg0_o,
    output logic [31:0]                     cfg_au_reg1_o,

    output logic [31:0]                     cfg_bincu_threshold_o,
    output logic [TRANS_SIZE-1:0]           cfg_bincu_counter_o,
    output logic                            cfg_bincu_en_counter_o,
    output logic [1:0]                      cfg_bincu_datasize_o,

    input logic [TRANS_SIZE-1:0]            bincu_counter_i,

    input logic                             filter_done_i
);

    logic [1:0]  [L2_AWIDTH_NOAL-1:0] r_filter_tx_start_addr;
    logic [1:0]                 [1:0] r_filter_tx_datasize;
    logic [1:0]                 [1:0] r_filter_tx_mode;
    logic [1:0]      [TRANS_SIZE-1:0] r_filter_tx_len0;
    logic [1:0]      [TRANS_SIZE-1:0] r_filter_tx_len1;
    logic [1:0]      [TRANS_SIZE-1:0] r_filter_tx_len2;
    logic        [L2_AWIDTH_NOAL-1:0] r_filter_rx_start_addr;
    logic                       [1:0] r_filter_rx_datasize;
    logic                       [1:0] r_filter_rx_mode;
    logic            [TRANS_SIZE-1:0] r_filter_rx_len0;
    logic            [TRANS_SIZE-1:0] r_filter_rx_len1;
    logic            [TRANS_SIZE-1:0] r_filter_rx_len2;
    logic                             r_au_use_signed;
    logic                             r_au_bypass;
    logic                       [3:0] r_au_mode;
    logic                       [4:0] r_au_shift;
    logic                      [31:0] r_au_reg0;
    logic                      [31:0] r_au_reg1;
    logic                      [31:0] r_bincu_threshold;
    logic            [TRANS_SIZE-1:0] r_bincu_counter;
    logic                       [1:0] r_bincu_datasize;
    logic                             r_bincu_en_counter;
    logic                       [3:0] r_filter_mode;

    logic [1:0]  [L2_AWIDTH_NOAL-1:0] r_commit_filter_tx_start_addr;
    logic [1:0]                 [1:0] r_commit_filter_tx_datasize;
    logic [1:0]                 [1:0] r_commit_filter_tx_mode;
    logic [1:0]      [TRANS_SIZE-1:0] r_commit_filter_tx_len0;
    logic [1:0]      [TRANS_SIZE-1:0] r_commit_filter_tx_len1;
    logic [1:0]      [TRANS_SIZE-1:0] r_commit_filter_tx_len2;
    logic        [L2_AWIDTH_NOAL-1:0] r_commit_filter_rx_start_addr;
    logic                       [1:0] r_commit_filter_rx_datasize;
    logic                       [1:0] r_commit_filter_rx_mode;
    logic            [TRANS_SIZE-1:0] r_commit_filter_rx_len0;
    logic            [TRANS_SIZE-1:0] r_commit_filter_rx_len1;
    logic            [TRANS_SIZE-1:0] r_commit_filter_rx_len2;
    logic                             r_commit_au_use_signed;
    logic                             r_commit_au_bypass;
    logic                       [3:0] r_commit_au_mode;
    logic                       [4:0] r_commit_au_shift;
    logic                      [31:0] r_commit_au_reg0;
    logic                      [31:0] r_commit_au_reg1;
    logic                      [31:0] r_commit_bincu_threshold;
    logic            [TRANS_SIZE-1:0] r_commit_bincu_counter;
    logic                       [1:0] r_commit_bincu_datasize;
    logic                             r_commit_bincu_en_counter;
    logic                       [3:0] r_commit_filter_mode;

    logic                             r_filter_start;
    logic                             r_filter_done;

    logic                [4:0] s_wr_addr;
    logic                [4:0] s_rd_addr;

    logic s_sample_commit;
    logic s_set_pending;
    logic s_clr_pending;
    logic r_pending;

    enum logic [1:0] { ST_IDLE, ST_SAMPLE, ST_BUSY} r_state,s_state;

    assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i) ? cfg_addr_i : 5'h0;
    assign s_rd_addr = (cfg_valid_i &  cfg_rwn_i) ? cfg_addr_i : 5'h0;

    assign cfg_filter_tx_start_addr_o = r_commit_filter_tx_start_addr;
    assign cfg_filter_tx_datasize_o   = r_commit_filter_tx_datasize;
    assign cfg_filter_tx_mode_o       = r_commit_filter_tx_mode;
    assign cfg_filter_tx_len0_o       = r_commit_filter_tx_len0;
    assign cfg_filter_tx_len1_o       = r_commit_filter_tx_len1;
    assign cfg_filter_tx_len2_o       = r_commit_filter_tx_len2;
    assign cfg_filter_rx_start_addr_o = r_commit_filter_rx_start_addr;
    assign cfg_filter_rx_datasize_o   = r_commit_filter_rx_datasize;
    assign cfg_filter_rx_mode_o       = r_commit_filter_rx_mode;
    assign cfg_filter_rx_len0_o       = r_commit_filter_rx_len0;
    assign cfg_filter_rx_len1_o       = r_commit_filter_rx_len1;
    assign cfg_filter_rx_len2_o       = r_commit_filter_rx_len2;
    assign cfg_filter_mode_o          = r_commit_filter_mode;
    assign cfg_au_use_signed_o        = r_commit_au_use_signed;
    assign cfg_au_bypass_o            = r_commit_au_bypass;
    assign cfg_au_mode_o              = r_commit_au_mode;
    assign cfg_au_shift_o             = r_commit_au_shift;
    assign cfg_au_reg0_o              = r_commit_au_reg0;
    assign cfg_au_reg1_o              = r_commit_au_reg1;
    assign cfg_bincu_counter_o        = r_commit_bincu_counter;
    assign cfg_bincu_threshold_o      = r_commit_bincu_threshold;
    assign cfg_bincu_en_counter_o     = r_commit_bincu_en_counter;
    assign cfg_bincu_datasize_o       = r_commit_bincu_datasize;


    always_comb begin : proc_pending
        s_sample_commit  = 1'b0;
        s_set_pending    = 1'b0;
        s_clr_pending    = 1'b0;
        s_state          = r_state;
        cfg_filter_start_o = 1'b0;

        case(r_state)
            ST_IDLE:
            begin
                if(r_filter_start)
                begin
                    s_sample_commit = 1'b1;
                    s_state         = ST_SAMPLE;
                end
            end
            ST_SAMPLE:
            begin
                cfg_filter_start_o = 1'b1;
                s_state = ST_BUSY;
            end
            ST_BUSY:
            begin
                if(r_filter_start)
                begin
                    if(filter_done_i)
                    begin
                        s_sample_commit = 1'b1;
                        s_state         = ST_SAMPLE;
                    end
                    else
                    begin
                        s_set_pending = 1'b1;
                    end
                end
                else
                begin
                    if(filter_done_i)
                    begin
                        if(r_pending)
                        begin
                            s_sample_commit = 1'b1;
                            s_state         = ST_SAMPLE;
                            s_clr_pending   = 1'b1;
                        end
                        else
                        begin
                            s_state = ST_IDLE;
                        end
                    end
                end
            end
        endcase
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if(~rstn_i)
        begin
            r_state <= ST_IDLE;
        end
        else
            r_state <= s_state;
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if(~rstn_i)
        begin
            r_pending                        <= 0;
            r_commit_filter_tx_start_addr[0] <= 0;
            r_commit_filter_tx_datasize[0]   <= 0;
            r_commit_filter_tx_mode[0]       <= 0;
            r_commit_filter_tx_len0[0]       <= 0;
            r_commit_filter_tx_len1[0]       <= 0;
            r_commit_filter_tx_len2[0]       <= 0;
            r_commit_filter_tx_start_addr[1] <= 0;
            r_commit_filter_tx_datasize[1]   <= 0;
            r_commit_filter_tx_mode[1]       <= 0;
            r_commit_filter_tx_len0[1]       <= 0;
            r_commit_filter_tx_len1[1]       <= 0;
            r_commit_filter_tx_len2[1]       <= 0;
            r_commit_filter_rx_start_addr    <= 0;
            r_commit_filter_rx_datasize      <= 0;
            r_commit_filter_rx_mode          <= 0;
            r_commit_filter_rx_len0          <= 0;
            r_commit_filter_rx_len1          <= 0;
            r_commit_filter_rx_len2          <= 0;
            r_commit_au_use_signed           <= 0;
            r_commit_au_bypass               <= 0;
            r_commit_au_mode                 <= 0;
            r_commit_au_shift                <= 0;
            r_commit_au_reg0                 <= 0;
            r_commit_au_reg1                 <= 0;
            r_commit_bincu_threshold         <= 0;
            r_commit_bincu_counter           <= 0;
            r_commit_bincu_datasize          <= 0;
            r_commit_bincu_en_counter        <= 0;
            r_commit_filter_mode             <= 0;
        end
        else
        begin
            if(s_sample_commit)
            begin
                r_commit_filter_tx_start_addr[0] <= r_filter_tx_start_addr[0];
                r_commit_filter_tx_datasize[0]   <= r_filter_tx_datasize[0]  ;
                r_commit_filter_tx_mode[0]       <= r_filter_tx_mode[0]      ;
                r_commit_filter_tx_len0[0]       <= r_filter_tx_len0[0]      ;
                r_commit_filter_tx_len1[0]       <= r_filter_tx_len1[0]      ;
                r_commit_filter_tx_len2[0]       <= r_filter_tx_len2[0]      ;
                r_commit_filter_tx_start_addr[1] <= r_filter_tx_start_addr[1];
                r_commit_filter_tx_datasize[1]   <= r_filter_tx_datasize[1]  ;
                r_commit_filter_tx_mode[1]       <= r_filter_tx_mode[1]      ;
                r_commit_filter_tx_len0[1]       <= r_filter_tx_len0[1]      ;
                r_commit_filter_tx_len1[1]       <= r_filter_tx_len1[1]      ;
                r_commit_filter_tx_len2[1]       <= r_filter_tx_len2[1]      ;
                r_commit_filter_rx_start_addr    <= r_filter_rx_start_addr   ;
                r_commit_filter_rx_datasize      <= r_filter_rx_datasize     ;
                r_commit_filter_rx_mode          <= r_filter_rx_mode         ;
                r_commit_filter_rx_len0          <= r_filter_rx_len0         ;
                r_commit_filter_rx_len1          <= r_filter_rx_len1         ;
                r_commit_filter_rx_len2          <= r_filter_rx_len2         ;
                r_commit_au_use_signed           <= r_au_use_signed          ;
                r_commit_au_bypass               <= r_au_bypass              ;
                r_commit_au_mode                 <= r_au_mode                ;
                r_commit_au_shift                <= r_au_shift               ;
                r_commit_au_reg0                 <= r_au_reg0                ;
                r_commit_au_reg1                 <= r_au_reg1                ;
                r_commit_bincu_threshold         <= r_bincu_threshold        ;
                r_commit_bincu_counter           <= r_bincu_counter          ;
                r_commit_bincu_datasize          <= r_bincu_datasize         ;
                r_commit_bincu_en_counter        <= r_bincu_en_counter       ;
                r_commit_filter_mode             <= r_filter_mode            ;
            end
            if(s_clr_pending)
                r_pending <= 1'b0;
            else if(s_set_pending)
                r_pending <= 1'b1;
        end
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if(~rstn_i)
        begin
            r_filter_tx_start_addr[0] <= 0;
            r_filter_tx_datasize[0]   <= 0;
            r_filter_tx_mode[0]       <= 0;
            r_filter_tx_len0[0]       <= 0;
            r_filter_tx_len1[0]       <= 0;
            r_filter_tx_len2[0]       <= 0;
            r_filter_tx_start_addr[1] <= 0;
            r_filter_tx_datasize[1]   <= 0;
            r_filter_tx_mode[1]       <= 0;
            r_filter_tx_len0[1]       <= 0;
            r_filter_tx_len1[1]       <= 0;
            r_filter_tx_len2[1]       <= 0;
            r_filter_rx_start_addr    <= 0;
            r_filter_rx_datasize      <= 0;
            r_filter_rx_mode          <= 0;
            r_filter_rx_len0          <= 0;
            r_filter_rx_len1          <= 0;
            r_filter_rx_len2          <= 0;
            r_au_use_signed           <= 0;
            r_au_bypass               <= 0;
            r_au_mode                 <= 0;
            r_au_shift                <= 0;
            r_au_reg0                 <= 0;
            r_au_reg1                 <= 0;
            r_bincu_threshold         <= 0;
            r_bincu_counter           <= 0;
            r_bincu_datasize          <= 0;
            r_bincu_en_counter        <= 0;
            r_filter_mode             <= 0;
            r_filter_start            <= 0;
            r_filter_done             <= 1'b0;
        end
        else
        begin
           if (filter_done_i)
             r_filter_done <= 1'b1;

            if (cfg_valid_i && !cfg_rwn_i && (s_wr_addr == `REG_FILT_CMD) && cfg_data_i[0])
                r_filter_start <= 1'b1;
            else
                r_filter_start <= 1'b0;

            if (cfg_valid_i & ~cfg_rwn_i)
            begin
                case (s_wr_addr)
                `REG_TX_CH0_ADD:
                begin
                    r_filter_tx_start_addr[0] <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                end
                `REG_TX_CH0_CFG:
                begin
                   r_filter_tx_datasize[0] <= cfg_data_i[1:0];
                   r_filter_tx_mode[0]     <= cfg_data_i[9:8];
                end
                `REG_TX_CH0_LEN0:
                begin
                    r_filter_tx_len0[0] <= cfg_data_i[TRANS_SIZE-1:0];
                end
                `REG_TX_CH0_LEN1:
                begin
                    r_filter_tx_len1[0] <= cfg_data_i[TRANS_SIZE-1:0];
                end
                `REG_TX_CH0_LEN2:
                begin
                    r_filter_tx_len2[0] <= cfg_data_i[TRANS_SIZE-1:0];
                end
                `REG_TX_CH1_ADD:
                begin
                    r_filter_tx_start_addr[1] <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                end
                `REG_TX_CH1_CFG:
                begin
                   r_filter_tx_datasize[1] <= cfg_data_i[1:0];
                   r_filter_tx_mode[1]     <= cfg_data_i[9:8];
                end
                `REG_TX_CH1_LEN0:
                begin
                    r_filter_tx_len0[1] <= cfg_data_i[TRANS_SIZE-1:0];
                end
                `REG_TX_CH1_LEN1:
                begin
                    r_filter_tx_len1[1] <= cfg_data_i[TRANS_SIZE-1:0];
                end
                `REG_TX_CH1_LEN2:
                begin
                    r_filter_tx_len2[1] <= cfg_data_i[TRANS_SIZE-1:0];
                end
                `REG_RX_CH_ADD:
                begin
                    r_filter_rx_start_addr <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                end
                `REG_RX_CH_CFG:
                begin
                   r_filter_rx_datasize <= cfg_data_i[1:0];
                   r_filter_rx_mode     <= cfg_data_i[9:8];
                end
                `REG_RX_CH_LEN0:
                begin
                    r_filter_rx_len0 <= cfg_data_i[15:0];
                end
                `REG_RX_CH_LEN1:
                begin
                    r_filter_rx_len1 <= cfg_data_i[15:0];
                end
                `REG_RX_CH_LEN2:
                begin
                    r_filter_rx_len2 <= cfg_data_i[15:0];
                end
                `REG_AU_CFG:
                begin
                    r_au_use_signed        <= cfg_data_i[0];
                    r_au_bypass            <= cfg_data_i[1];
                    r_au_mode              <= cfg_data_i[11:8];
                    r_au_shift             <= cfg_data_i[20:16];
                end
                `REG_AU_REG0:
                begin
                    r_au_reg0 <= cfg_data_i;
                end
                `REG_AU_REG1:
                begin
                    r_au_reg1 <= cfg_data_i;
                end
                `REG_BINCU_TH:
                begin
                    r_bincu_threshold <= cfg_data_i;
                end
                `REG_BINCU_SETUP:
                begin
                    r_bincu_datasize <= cfg_data_i[1:0];
                end
                `REG_BINCU_CNT:
                begin
                    r_bincu_counter    <= cfg_data_i[TRANS_SIZE-1:0];
                    r_bincu_en_counter <= cfg_data_i[31];
                end
                `REG_FILT:
                begin
                    r_filter_mode <= cfg_data_i[3:0];
                end
                `REG_STATUS:
                begin
                   if (cfg_data_i[0])
                     r_filter_done <= 1'b0;
                end
                endcase
            end
        end
    end //always

    always_comb
    begin
        cfg_data_o = 32'h0;
        case (s_rd_addr)
        `REG_TX_CH0_ADD:
            cfg_data_o[L2_AWIDTH_NOAL-1:0] =r_commit_filter_tx_start_addr[0];
        `REG_TX_CH0_CFG:
        begin
            cfg_data_o[9:8] = r_commit_filter_tx_mode[0];
            cfg_data_o[1:0] = r_commit_filter_tx_datasize[0];
        end
        `REG_TX_CH0_LEN0:
            cfg_data_o[TRANS_SIZE-1:0] = r_commit_filter_tx_len0[0];
        `REG_TX_CH0_LEN1:
            cfg_data_o[TRANS_SIZE-1:0] = r_commit_filter_tx_len1[0];
        `REG_TX_CH0_LEN2:
            cfg_data_o[TRANS_SIZE-1:0] = r_commit_filter_tx_len2[0];
        `REG_TX_CH1_ADD:
            cfg_data_o[L2_AWIDTH_NOAL-1:0] = r_commit_filter_tx_start_addr[1];
        `REG_TX_CH1_CFG:
        begin
           cfg_data_o[1:0] = r_commit_filter_tx_datasize[1];
           cfg_data_o[9:8] = r_commit_filter_tx_mode[1]    ;
        end
        `REG_TX_CH1_LEN0:
            cfg_data_o[TRANS_SIZE-1:0] = r_commit_filter_tx_len0[1];
        `REG_TX_CH1_LEN1:
            cfg_data_o[TRANS_SIZE-1:0] = r_commit_filter_tx_len1[1];
        `REG_TX_CH1_LEN2:
            cfg_data_o[TRANS_SIZE-1:0] = r_commit_filter_tx_len2[1];
        `REG_RX_CH_ADD:
            cfg_data_o[L2_AWIDTH_NOAL-1:0] = r_commit_filter_rx_start_addr[1];
        `REG_RX_CH_CFG:
        begin
           cfg_data_o[1:0] = r_commit_filter_rx_datasize[1];
           cfg_data_o[9:8] = r_commit_filter_rx_mode[1]    ;
        end
        `REG_RX_CH_LEN0:
            cfg_data_o[15:0] = r_commit_filter_rx_len0[1];
        `REG_RX_CH_LEN1:
            cfg_data_o[15:0] = r_commit_filter_rx_len1[1];
        `REG_RX_CH_LEN2:
            cfg_data_o[15:0] = r_commit_filter_rx_len2[1];
        `REG_AU_CFG:
        begin
            cfg_data_o[0]     = r_commit_au_use_signed;
            cfg_data_o[1]     = r_commit_au_bypass    ;
            cfg_data_o[11:8]  = r_commit_au_mode      ;
            cfg_data_o[20:16] = r_commit_au_shift     ;
        end
        `REG_AU_REG0:
            cfg_data_o = r_commit_au_reg0;
        `REG_AU_REG1:
            cfg_data_o = r_commit_au_reg1;
        `REG_BINCU_TH:
            cfg_data_o = r_commit_bincu_threshold;
        `REG_BINCU_SETUP:
            cfg_data_o[1:0] = r_commit_bincu_datasize;
        `REG_BINCU_VAL:
            cfg_data_o[TRANS_SIZE-1:0] = bincu_counter_i;
        `REG_BINCU_CNT:
        begin
            cfg_data_o[TRANS_SIZE-1:0] = r_commit_bincu_counter;
            cfg_data_o[31] = r_commit_bincu_en_counter;
        end
        `REG_FILT:
            cfg_data_o[3:0] = r_commit_filter_mode;
        `REG_STATUS:
            cfg_data_o[0]   = r_filter_done;
        default:
            cfg_data_o = 'h0;
        endcase
    end

    assign cfg_ready_o  = 1'b1;


endmodule

`undef REG_TX_CH0_ADD  
`undef REG_TX_CH0_CFG  
`undef REG_TX_CH0_LEN0 
`undef REG_TX_CH0_LEN1 
`undef REG_TX_CH0_LEN2 
`undef REG_TX_CH1_ADD  
`undef REG_TX_CH1_CFG  
`undef REG_TX_CH1_LEN0 
`undef REG_TX_CH1_LEN1 
`undef REG_TX_CH1_LEN2 
`undef REG_RX_CH_ADD   
`undef REG_RX_CH_CFG   
`undef REG_RX_CH_LEN0  
`undef REG_RX_CH_LEN1  
`undef REG_RX_CH_LEN2  
`undef REG_AU_CFG      
`undef REG_AU_REG0     
`undef REG_AU_REG1     
`undef REG_BINCU_TH    
`undef REG_BINCU_CNT   
`undef REG_BINCU_SETUP 
`undef REG_BINCU_VAL   
`undef REG_FILT        
`undef REG_FILT_CMD    
`undef REG_STATUS      

