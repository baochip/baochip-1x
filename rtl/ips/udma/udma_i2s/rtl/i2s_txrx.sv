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
// Description: I2S configuration interface
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////


module i2s_txrx (

	input  logic   	                  rstn_i,

    input  logic                      dft_test_mode_i,
    input  logic                      dft_cg_enable_i,

    input  logic                      slave_clk_i,
    input  logic                      slave_ws_i,

    input  logic                      master_clk_i,
    input  logic                      master_ws_i,

    output logic                      pad_pdm_clk_o,

    input  logic                      pad_slave_sd0_i,
    input  logic                      pad_slave_sd1_i,

    output logic                      pad_master_sd0_o,
    output logic                      pad_master_sd1_o,

    input  logic                      cfg_slave_en_i,
    input  logic                      cfg_master_en_i,

    input  logic                      cfg_slave_i2s_lsb_first_i,
    input  logic                      cfg_slave_i2s_2ch_i,
    input  logic                [4:0] cfg_slave_i2s_bits_word_i,
    input  logic                [2:0] cfg_slave_i2s_words_i,

    input  logic                      cfg_slave_pdm_en_i,
    input  logic                [1:0] cfg_slave_pdm_mode_i,
    input  logic                [9:0] cfg_slave_pdm_decimation_i,
    input  logic                [2:0] cfg_slave_pdm_shift_i,

    input  logic                      cfg_master_i2s_lsb_first_i,
    input  logic                      cfg_master_i2s_2ch_i,
    input  logic                [4:0] cfg_master_i2s_bits_word_i,
    input  logic                [2:0] cfg_master_i2s_words_i,

    output logic               [31:0] fifo_rx_data_o,
    output logic                      fifo_rx_data_valid_o,
    input  logic                      fifo_rx_data_ready_i,

    input  logic               [31:0] fifo_tx_data_i,
    input  logic                      fifo_tx_data_valid_i,
    output logic                      fifo_tx_data_ready_o


);

    logic [15:0] s_pdm_fifo_data;
    logic        s_pdm_fifo_data_valid;
    logic        s_pdm_fifo_data_ready;

    logic [31:0] s_i2s_slv_fifo_data;
    logic        s_i2s_slv_fifo_data_valid;
    logic        s_i2s_slv_fifo_data_ready;

    logic        s_i2s_slv_en;

    assign s_i2s_slv_en = cfg_slave_en_i & !cfg_slave_pdm_en_i;

    assign fifo_rx_data_o            = cfg_slave_pdm_en_i ? {16'h0,s_pdm_fifo_data} : s_i2s_slv_fifo_data;
    assign fifo_rx_data_valid_o      = cfg_slave_pdm_en_i ? s_pdm_fifo_data_valid   : s_i2s_slv_fifo_data_valid;
    assign s_i2s_slv_fifo_data_ready = fifo_rx_data_ready_i;
    assign s_pdm_fifo_data_ready     = fifo_rx_data_ready_i;

    i2s_rx_channel i_i2s_slave 
    (
        .sck_i             ( slave_clk_i               ),
        .rstn_i            ( rstn_i                    ),

        .i2s_ch0_i         ( pad_slave_sd0_i           ),
        .i2s_ch1_i         ( pad_slave_sd1_i           ),
        .i2s_ws_i          ( slave_ws_i                ),

        .fifo_data_o       ( s_i2s_slv_fifo_data       ),
        .fifo_data_valid_o ( s_i2s_slv_fifo_data_valid ),
        .fifo_data_ready_i ( s_i2s_slv_fifo_data_ready ),

        .fifo_err_o        (                           ),

        .cfg_en_i          ( s_i2s_slv_en              ),
        .cfg_2ch_i         ( cfg_slave_i2s_2ch_i       ),
        .cfg_wlen_i        ( cfg_slave_i2s_bits_word_i ),
        .cfg_wnum_i        ( cfg_slave_i2s_words_i     ),
        .cfg_lsb_first_i   ( cfg_slave_i2s_lsb_first_i )
    );

    pdm_top i_pdm (
        .clk_i                ( slave_clk_i                ),
        .rstn_i               ( rstn_i                     ),
        .pdm_clk_o            ( pad_pdm_clk_o              ),
        .cfg_pdm_ch_mode_i    ( cfg_slave_pdm_mode_i       ),
        .cfg_pdm_decimation_i ( cfg_slave_pdm_decimation_i ),
        .cfg_pdm_shift_i      ( cfg_slave_pdm_shift_i      ),
        .cfg_pdm_en_i         ( cfg_slave_pdm_en_i         ),
        .pdm_ch0_i            ( pad_slave_sd0_i            ),
        .pdm_ch1_i            ( pad_slave_sd1_i            ),
        .pcm_data_o           ( s_pdm_fifo_data            ),
        .pcm_data_valid_o     ( s_pdm_fifo_data_valid      ),
        .pcm_data_ready_i     ( s_pdm_fifo_data_ready      )
    );

    i2s_tx_channel i_i2s_master 
    (
        .sck_i             ( master_clk_i               ),
        .rstn_i            ( rstn_i                     ),

        .i2s_ch0_o         ( pad_master_sd0_o           ),
        .i2s_ch1_o         ( pad_master_sd1_o           ),
        .i2s_ws_i          ( master_ws_i                ),

        .fifo_data_i       ( fifo_tx_data_i             ),
        .fifo_data_valid_i ( fifo_tx_data_valid_i       ),
        .fifo_data_ready_o ( fifo_tx_data_ready_o       ),

        .fifo_err_o        (                            ),

        .cfg_en_i          ( cfg_master_en_i            ),
        .cfg_2ch_i         ( cfg_master_i2s_2ch_i       ),
        .cfg_wlen_i        ( cfg_master_i2s_bits_word_i ),
        .cfg_wnum_i        ( cfg_master_i2s_words_i     ),
        .cfg_lsb_first_i   ( cfg_master_i2s_lsb_first_i )
    );

endmodule 
