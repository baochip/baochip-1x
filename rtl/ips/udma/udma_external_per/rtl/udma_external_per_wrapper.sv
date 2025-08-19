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
// Description: External Peripheral configuration interface
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//              Pasquale Davide Schiavone (pschiavo@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_external_per_wrapper #(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE     = 16
) (
    input  logic                      sys_clk_i,
    input  logic                      periph_clk_i,
	input  logic   	                  rstn_i,

	input  logic               [31:0] cfg_data_i,
	input  logic                [4:0] cfg_addr_i,
	input  logic                      cfg_valid_i,
	input  logic                      cfg_rwn_i,
	output logic                      cfg_ready_o,
    output logic               [31:0] cfg_data_o,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_rx_size_o,
    output logic                      cfg_rx_continuous_o,
    output logic                      cfg_rx_en_o,
    output logic                      cfg_rx_clr_o,
    input  logic                      cfg_rx_en_i,
    input  logic                      cfg_rx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_rx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_tx_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_tx_size_o,
    output logic                      cfg_tx_continuous_o,
    output logic                      cfg_tx_en_o,
    output logic                      cfg_tx_clr_o,
    input  logic                      cfg_tx_en_i,
    input  logic                      cfg_tx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_tx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_tx_bytes_left_i,

    output logic                      data_tx_req_o,
    input  logic                      data_tx_gnt_i,
    output logic                [1:0] data_tx_datasize_o,
    input  logic               [31:0] data_tx_i,
    input  logic                      data_tx_valid_i,
    output logic                      data_tx_ready_o,

    output logic                [1:0] data_rx_datasize_o,
    output logic               [31:0] data_rx_o,
    output logic                      data_rx_valid_o,
    input  logic                      data_rx_ready_i
);

    logic          s_data_tx_valid;
    logic          s_data_tx_ready;
    logic   [31:0] s_data_tx;
    logic   [31:0] cfg_setup;
    logic   [31:0] cfg_status;

    //TX side - uDMA <-> external Peripheral
    logic          data_tx_dc_valid;
    logic          data_tx_dc_ready;
    logic   [31:0] data_tx_dc;

    //RX side - uDMA <-> external Peripheral
    logic          data_rx_dc_valid;
    logic          data_rx_dc_ready;
    logic   [31:0] data_rx_dc;

    udma_external_per_top #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE)
    ) external_per_top (
        //TX side - uDMA <-> external Peripheral
        .data_tx_dc_valid_o  ( data_tx_dc_valid     ),
        .data_tx_dc_ready_i  ( data_tx_dc_ready     ),
        .data_tx_dc_o        ( data_tx_dc           ),
        //RX side - uDMA <-> external Peripheral
        .data_rx_dc_valid_i  ( data_rx_dc_valid     ),
        .data_rx_dc_ready_o  ( data_rx_dc_ready     ),
        .data_rx_dc_i        ( data_rx_dc           ),
        //used for Arnold
        .external_per_status_i ( cfg_status         ),
        .external_per_setup_o  ( cfg_setup          ),
        .*
    );

`ifdef PULP_TRAINING
    udma_traffic_gen_tx u_traffic_gen_tx (
        .clk_i           ( periph_clk_i     ),
        .rstn_i          ( rstn_i           ),
        .tx_o            (                  ),//not connected
        .tx_data_i       ( data_tx_dc       ),
        .tx_valid_i      ( data_tx_dc_valid ),
        .tx_ready_o      ( data_tx_dc_ready ),
        .busy_o          ( cfg_status[1]    ),
        .cfg_setup_i     ( cfg_setup        )
    );

    udma_traffic_gen_rx u_traffic_gen_rx (
        .clk_i           ( periph_clk_i     ),
        .rstn_i          ( rstn_i           ),
        .busy_o          ( cfg_status[0]    ),
        .rx_data_o       ( data_rx_dc       ),
        .rx_valid_o      ( data_rx_dc_valid ),
        .rx_ready_i      ( data_rx_dc_ready ),
        .cfg_setup_i     ( cfg_setup        )
    );
`endif


endmodule // udma_uart_top