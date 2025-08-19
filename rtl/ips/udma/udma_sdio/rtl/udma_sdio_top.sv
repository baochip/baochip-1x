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
// Description: Top level module
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_sdio_top #(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE     = 16
)
(
	//
	// inputs & outputs
	//
	input  logic                      sys_clk_i,      // master clock
	input  logic                      periph_clk_i,   // master clock
	input  logic                      sys_rstn_i,     // system clock domain asynchronous active low reset
	input  logic                      per_rstn_i,     // peripheral clock domain asynchronous active low reset
    input  logic                      dft_test_mode_i,
    input  logic                      dft_cg_enable_i,

	input  logic               [31:0] cfg_data_i,
	input  logic                [4:0] cfg_addr_i,
	input  logic                      cfg_valid_i,
	input  logic                      cfg_rwn_i,
	output logic               [31:0] cfg_data_o,
	output logic                      cfg_ready_o,

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

    // output logic               [11:0] cfg_stat_o,

    output logic                      data_tx_req_o,
    input  logic                      data_tx_gnt_i,
	output logic                [1:0] data_tx_datasize_o,
	input  logic               [31:0] data_tx_i,
	input  logic                      data_tx_valid_i,
	output logic                      data_tx_ready_o,

	output logic                [1:0] data_rx_datasize_o,
	output logic               [31:0] data_rx_o,
	output logic                      data_rx_valid_o,
	input  logic                      data_rx_ready_i,

    output logic                      eot_o,
	output logic                      err_o,

	// SDIO signals
    output logic                      sdclk_o,
    output logic                      sdcmd_o,
    input  logic                      sdcmd_i,
    output logic                      sdcmd_oen_o,
    output logic                [3:0] sddata_o,
    input  logic                [3:0] sddata_i,
    output logic                [3:0] sddata_oen_o
);

	logic [31:0] s_data_tx;
	logic        s_data_tx_valid;
	logic        s_data_tx_ready;

    logic [31:0] s_data_tx_dc;
    logic        s_data_tx_dc_valid;
    logic        s_data_tx_dc_ready;

    logic [31:0] s_data_rx_dc;
    logic        s_data_rx_dc_valid;
    logic        s_data_rx_dc_ready;

    logic   [5:0] s_cmd_op;
    logic  [31:0] s_cmd_arg;
    logic   [2:0] s_cmd_rsp_type;
    logic   [1:0] s_cmd_stopopt;
    logic [127:0] s_rsp_data;
    logic         s_data_en;
    logic         s_data_rwn;
    logic         s_data_quad;
    logic   [9:0] s_data_block_size;
    logic   [7:0] s_data_block_num;

    logic  [15:0] s_status;

    logic         s_start;
    logic         s_start_sync;

    logic         s_clkdiv_en;
    logic   [7:0] s_clkdiv_data;
    logic         s_clkdiv_valid;
    logic         s_clkdiv_ack;
    logic         s_clk_sdio;

    logic         s_eot;
    logic         s_err;

    logic  [11:0] cfg_debug_stat;
    logic  [19:0] cfg_data_timeout;

    assign data_tx_datasize_o = 2'b10;
    assign data_rx_datasize_o = 2'b10;

    assign s_clkdiv_en = 1'b1;

   assign s_err = s_status ? 1'b1 : 1'b0;

    pulp_sync_wedge error_int_sync
     (
      .clk_i(sys_clk_i),
      .rstn_i(sys_rstn_i),
      .en_i(1'b1),
      .serial_i(s_err),
      .r_edge_o(err_o),
      .f_edge_o(),
      .serial_o()
      );

    udma_sdio_reg_if #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE)
    ) u_reg_if (
        .clk_i                ( sys_clk_i           ),
        .rstn_i               ( sys_rstn_i          ),

        .cfg_data_i           ( cfg_data_i          ),
        .cfg_addr_i           ( cfg_addr_i          ),
        .cfg_valid_i          ( cfg_valid_i         ),
        .cfg_rwn_i            ( cfg_rwn_i           ),
        .cfg_ready_o          ( cfg_ready_o         ),
        .cfg_data_o           ( cfg_data_o          ),

        .cfg_rx_startaddr_o   ( cfg_rx_startaddr_o  ),
        .cfg_rx_size_o        ( cfg_rx_size_o       ),
        .cfg_rx_continuous_o  ( cfg_rx_continuous_o ),
        .cfg_rx_en_o          ( cfg_rx_en_o         ),
        .cfg_rx_clr_o         ( cfg_rx_clr_o        ),
        .cfg_rx_en_i          ( cfg_rx_en_i         ),
        .cfg_rx_pending_i     ( cfg_rx_pending_i    ),
        .cfg_rx_curr_addr_i   ( cfg_rx_curr_addr_i  ),
        .cfg_rx_bytes_left_i  ( cfg_rx_bytes_left_i ),

        .cfg_tx_startaddr_o   ( cfg_tx_startaddr_o  ),
        .cfg_tx_size_o        ( cfg_tx_size_o       ),
        .cfg_tx_continuous_o  ( cfg_tx_continuous_o ),
        .cfg_tx_en_o          ( cfg_tx_en_o         ),
        .cfg_tx_clr_o         ( cfg_tx_clr_o        ),
        .cfg_tx_en_i          ( cfg_tx_en_i         ),
        .cfg_tx_pending_i     ( cfg_tx_pending_i    ),
        .cfg_tx_curr_addr_i   ( cfg_tx_curr_addr_i  ),
        .cfg_tx_bytes_left_i  ( cfg_tx_bytes_left_i ),

        .cfg_sdio_start_o     ( s_start             ),

        .cfg_clk_div_data_o   ( s_clkdiv_data       ),
        .cfg_clk_div_valid_o  ( s_clkdiv_valid      ),
        .cfg_clk_div_ack_i    ( s_clkdiv_ack        ),

        .txrx_status_i        ( s_status            ),
        .txrx_eot_i           ( eot_o               ),
        .txrx_err_i           ( err_o               ),

        .cfg_cmd_op_o         ( s_cmd_op            ),
        .cfg_cmd_arg_o        ( s_cmd_arg           ),
        .cfg_cmd_rsp_type_o   ( s_cmd_rsp_type      ),
        .cfg_cmd_stopopt      ( s_cmd_stopopt       ),
        .cfg_rsp_data_i       ( s_rsp_data          ),
        .cfg_data_en_o        ( s_data_en           ),
        .cfg_data_rwn_o       ( s_data_rwn          ),
        .cfg_data_quad_o      ( s_data_quad         ),
        .cfg_data_block_size_o( s_data_block_size   ),
        .cfg_data_block_num_o ( s_data_block_num    ),

        .cfg_data_timeout_o   ( cfg_data_timeout    ),
        .cfg_debug_stat_i         ( cfg_debug_stat      )
    );

    udma_clkgen u_clockgen
    (
        .clk_i           ( periph_clk_i    ),
        .rstn_i          ( per_rstn_i   ),
        .dft_test_mode_i ( dft_test_mode_i ),
        .dft_cg_enable_i ( dft_cg_enable_i ),
        .clock_enable_i  ( s_clkdiv_en     ),
        .clk_div_data_i  ( s_clkdiv_data   ),
        .clk_div_valid_i ( s_clkdiv_valid  ),
        .clk_div_ack_o   ( s_clkdiv_ack    ),
        .clk_o           ( s_clk_sdio      )
    );

    edge_propagator i_start_sync
    (
        .clk_tx_i        ( sys_clk_i    ),
        .rstn_tx_i       ( sys_rstn_i   ),
        .edge_i          ( s_start      ),
        .clk_rx_i        ( s_clk_sdio   ),
        .rstn_rx_i       ( per_rstn_i   ),
        .edge_o          ( s_start_sync )
    );

    edge_propagator i_eot_sync
    (
        .clk_tx_i        ( s_clk_sdio   ),
        .rstn_tx_i       ( per_rstn_i   ),
        .edge_i          ( s_eot        ),
        .clk_rx_i        ( sys_clk_i    ),
        .rstn_rx_i       ( sys_rstn_i   ),
        .edge_o          ( eot_o        )
    );

    sdio_txrx i_sdio_txrx (
        .clk_i              ( s_clk_sdio          ),
        .rstn_i             ( per_rstn_i          ),

        .clr_stat_i         ( 1'b0                ),
        .cmd_start_i        ( s_start_sync        ),
        .cmd_op_i           ( s_cmd_op            ),
        .cmd_arg_i          ( s_cmd_arg           ),
        .cmd_rsp_type_i     ( s_cmd_rsp_type      ),
        .cmd_stopopt        ( s_cmd_stopopt       ),
        .rsp_data_o         ( s_rsp_data          ),
        .data_en_i          ( s_data_en           ),
        .data_rwn_i         ( s_data_rwn          ),
        .data_quad_i        ( s_data_quad         ),
        .data_block_size_i  ( s_data_block_size   ),
        .data_block_num_i   ( s_data_block_num    ),
        .eot_o              ( s_eot               ),
        .status_o           ( s_status            ),

        .in_data_if_data_i  ( s_data_tx_dc        ),
        .in_data_if_valid_i ( s_data_tx_dc_valid  ),
        .in_data_if_ready_o ( s_data_tx_dc_ready  ),

        .out_data_if_data_o ( s_data_rx_dc        ),
        .out_data_if_valid_o( s_data_rx_dc_valid  ),
        .out_data_if_ready_i( s_data_rx_dc_ready  ),

        .sdclk_o            ( sdclk_o             ),
        .sdcmd_o            ( sdcmd_o             ),
        .sdcmd_i            ( sdcmd_i             ),
        .sdcmd_oen_o        ( sdcmd_oen_o         ),
        .sddata_o           ( sddata_o            ),
        .sddata_i           ( sddata_i            ),
        .sddata_oen_o       ( sddata_oen_o        ),
        .debug_stat_o       ( cfg_debug_stat      ),
        .data_timeout_i     ( cfg_data_timeout    )
  );


    io_tx_fifo #(
      .DATA_WIDTH(32),
      .BUFFER_DEPTH(2)
      ) i_sdio_tx_fifo (
        .clk_i        ( sys_clk_i          ),
        .rstn_i       ( sys_rstn_i         ),
        .clr_i        ( 1'b0               ),
        .data_o       ( s_data_tx          ),
        .valid_o      ( s_data_tx_valid    ),
        .ready_i      ( s_data_tx_ready    ),
        .req_o        ( data_tx_req_o      ),
        .gnt_i        ( data_tx_gnt_i      ),
        .valid_i      ( data_tx_valid_i    ),
        .data_i       ( data_tx_i          ),
        .ready_o      ( data_tx_ready_o    )
    );

    udma_dc_fifo #(32,4) i_dc_fifo_tx
    (
        .src_clk_i    ( sys_clk_i          ),
        .src_rstn_i   ( sys_rstn_i         ),
        .src_data_i   ( s_data_tx          ),
        .src_valid_i  ( s_data_tx_valid    ),
        .src_ready_o  ( s_data_tx_ready    ),
        .dst_clk_i    ( s_clk_sdio         ),
        .dst_rstn_i   ( per_rstn_i         ),
        .dst_data_o   ( s_data_tx_dc       ),
        .dst_valid_o  ( s_data_tx_dc_valid ),
        .dst_ready_i  ( s_data_tx_dc_ready )
    );

    udma_dc_fifo #(32,4) u_dc_fifo_rx
    (
        .src_clk_i    ( s_clk_sdio         ),
        .src_rstn_i   ( per_rstn_i         ),
        .src_data_i   ( s_data_rx_dc       ),
        .src_valid_i  ( s_data_rx_dc_valid ),
        .src_ready_o  ( s_data_rx_dc_ready ),
        .dst_clk_i    ( sys_clk_i          ),
        .dst_rstn_i   ( sys_rstn_i         ),
        .dst_data_o   ( data_rx_o          ),
        .dst_valid_o  ( data_rx_valid_o    ),
        .dst_ready_i  ( data_rx_ready_i    )
    );

endmodule
