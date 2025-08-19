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

`include "udma_i2c_defines.sv"

module udma_i2c_top #(
    parameter L2_AWIDTH_NOAL = 21,
    parameter TRANS_SIZE     = 16
)
(
	//
	// inputs & outputs
	//
	input  logic                      sys_clk_i,      // master clock
	input  logic                      periph_clk_i,   // master clock
	input  logic                      sys_rstn_i,     // sys_clk domain asynchronous active low reset
	input  logic                      per_rstn_i,     // per_clk domain asynchronous active low reset

	input  logic                [3:0] ext_events_i,

	input  logic               [31:0] cfg_data_i,
	input  logic                [4:0] cfg_addr_i,
	input  logic                      cfg_valid_i,
	input  logic                      cfg_rwn_i,
	output logic               [31:0] cfg_data_o,
	output logic                      cfg_ready_o,


    output logic [L2_AWIDTH_NOAL-1:0] cfg_cmd_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_cmd_size_o,
    output logic                      cfg_cmd_continuous_o,
    output logic                      cfg_cmd_en_o,
    output logic                      cfg_cmd_clr_o,
    input  logic                      cfg_cmd_en_i,
    input  logic                      cfg_cmd_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_cmd_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_cmd_bytes_left_i,

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

    output logic                      cmd_req_o,
    input  logic                      cmd_gnt_i,
    output logic                [1:0] cmd_datasize_o,
    input  logic               [31:0] cmd_i,
    input  logic                      cmd_valid_i,
    output logic                      cmd_ready_o,

    output logic                      data_tx_req_o,
    input  logic                      data_tx_gnt_i,
	output logic                [1:0] data_tx_datasize_o,
	input  logic                [7:0] data_tx_i,
	input  logic                      data_tx_valid_i,
	output logic                      data_tx_ready_o,

	output logic                [1:0] data_rx_datasize_o,
	output logic                [7:0] data_rx_o,
	output logic                      data_rx_valid_o,
	input  logic                      data_rx_ready_i,

	output logic                      err_o,
	output logic                      eot_o,      // i2c end of transfer event
	output logic                      nack_o,     // i2c slave device does not aknowledge the event

	// I2C signals
	input  logic                      scl_i,
	output logic                      scl_o,
	output logic                      scl_oe,
	input  logic                      sda_i,
	output logic                      sda_o,
	output logic                      sda_oe
);

	logic [7:0] s_data_tx;
	logic       s_data_tx_valid;
	logic       s_data_tx_ready;

    logic [7:0] s_data_tx_dc;
    logic       s_data_tx_dc_valid;
    logic       s_data_tx_dc_ready;

    logic [7:0] s_data_rx_dc;
    logic       s_data_rx_dc_valid;
    logic       s_data_rx_dc_ready;

    logic       s_do_rst;

    logic [31:0] s_udma_cmd;
    logic        s_udma_cmd_valid;
    logic        s_udma_cmd_ready;

    logic [31:0] s_i2c_cmd;
    logic        s_i2c_cmd_valid;
    logic        s_i2c_cmd_ready;

    logic        s_i2c_busy;
    logic        s_i2c_al;
    logic        s_i2c_eot;
    logic        s_i2c_nack;

    logic [3:0] s_events;

    assign data_tx_datasize_o = 2'b00;
    assign data_rx_datasize_o = 2'b00;
    assign cmd_datasize_o     = 2'b10;

    generate
        for (genvar i = 0; i < 4; i++)
        begin
            edge_propagator i_event_sync
            (
                .clk_tx_i ( sys_clk_i       ),
                .rstn_tx_i( sys_rstn_i      ),
                .edge_i   ( ext_events_i[i] ),
                .clk_rx_i ( periph_clk_i    ),
                .rstn_rx_i( per_rstn_i      ),
                .edge_o   ( s_events[i]     )
            );
        end
    endgenerate

    edge_propagator i_nack_sync (
        .clk_tx_i ( periph_clk_i ),
        .rstn_tx_i( per_rstn_i   ),
        .edge_i   ( s_i2c_nack   ),
        .clk_rx_i ( sys_clk_i    ),
        .rstn_rx_i( sys_rstn_i   ),
        .edge_o   ( nack_o       )
    );

    udma_i2c_reg_if #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE)
    ) u_reg_if (
        .clk_i              ( sys_clk_i           ),
        .rstn_i             ( sys_rstn_i          ),

        .cfg_data_i         ( cfg_data_i          ),
        .cfg_addr_i         ( cfg_addr_i          ),
        .cfg_valid_i        ( cfg_valid_i         ),
        .cfg_rwn_i          ( cfg_rwn_i           ),
        .cfg_ready_o        ( cfg_ready_o         ),
        .cfg_data_o         ( cfg_data_o          ),

        .cfg_cmd_startaddr_o ( cfg_cmd_startaddr_o  ),
        .cfg_cmd_size_o      ( cfg_cmd_size_o       ),
        .cfg_cmd_continuous_o( cfg_cmd_continuous_o ),
        .cfg_cmd_en_o        ( cfg_cmd_en_o         ),
        .cfg_cmd_clr_o       ( cfg_cmd_clr_o        ),
        .cfg_cmd_en_i        ( cfg_cmd_en_i         ),
        .cfg_cmd_pending_i   ( cfg_cmd_pending_i    ),
        .cfg_cmd_curr_addr_i ( cfg_cmd_curr_addr_i  ),
        .cfg_cmd_bytes_left_i( cfg_cmd_bytes_left_i ),

        .cfg_rx_startaddr_o ( cfg_rx_startaddr_o  ),
        .cfg_rx_size_o      ( cfg_rx_size_o       ),
        .cfg_rx_continuous_o( cfg_rx_continuous_o ),
        .cfg_rx_en_o        ( cfg_rx_en_o         ),
        .cfg_rx_clr_o       ( cfg_rx_clr_o        ),
        .cfg_rx_en_i        ( cfg_rx_en_i         ),
        .cfg_rx_pending_i   ( cfg_rx_pending_i    ),
        .cfg_rx_curr_addr_i ( cfg_rx_curr_addr_i  ),
        .cfg_rx_bytes_left_i( cfg_rx_bytes_left_i ),

        .cfg_tx_startaddr_o ( cfg_tx_startaddr_o  ),
        .cfg_tx_size_o      ( cfg_tx_size_o       ),
        .cfg_tx_continuous_o( cfg_tx_continuous_o ),
        .cfg_tx_en_o        ( cfg_tx_en_o         ),
        .cfg_tx_clr_o       ( cfg_tx_clr_o        ),
        .cfg_tx_en_i        ( cfg_tx_en_i         ),
        .cfg_tx_pending_i   ( cfg_tx_pending_i    ),
        .cfg_tx_curr_addr_i ( cfg_tx_curr_addr_i  ),
        .cfg_tx_bytes_left_i( cfg_tx_bytes_left_i ),

        .cfg_do_rst_o       ( s_do_rst ),

        .status_busy_i      ( s_i2c_busy ),
        .status_al_i        ( s_i2c_al   ),
        .nack_i             ( s_i2c_nack ),

        .udma_cmd_i         ( s_i2c_cmd           ),
        .udma_cmd_valid_i   ( s_i2c_cmd_valid     ),
        .udma_cmd_ready_i   ( s_i2c_cmd_ready     )
    );


    // command TX FIFO
    // 32 bits wide to allow embbeding size/addresses in UCA/UCS
    // 24 lower bits ignored for other commands
    io_tx_fifo #(
      .DATA_WIDTH(32),
      .BUFFER_DEPTH(2)
      ) u_cmd_fifo (
        .clk_i   ( sys_clk_i        ),
        .rstn_i  ( sys_rstn_i       ),
        .clr_i   ( 1'b0             ),
        .data_o  ( s_i2c_cmd        ),
        .valid_o ( s_i2c_cmd_valid  ),
        .ready_i ( s_i2c_cmd_ready  ),
        .req_o   ( cmd_req_o        ),
        .gnt_i   ( cmd_gnt_i        ),
        .valid_i ( cmd_valid_i      ),
        .data_i  ( cmd_i            ),
        .ready_o ( cmd_ready_o      )
    );

    udma_dc_fifo #(32,4) u_dc_cmd
    (
        .dst_clk_i          ( periph_clk_i      ),
        .dst_rstn_i         ( per_rstn_i        ),
        .dst_data_o         ( s_udma_cmd        ),
        .dst_valid_o        ( s_udma_cmd_valid  ),
        .dst_ready_i        ( s_udma_cmd_ready  ),
        .src_clk_i          ( sys_clk_i         ),
        .src_rstn_i         ( sys_rstn_i        ),
        .src_data_i         ( s_i2c_cmd         ),
        .src_valid_i        ( s_i2c_cmd_valid   ),
        .src_ready_o        ( s_i2c_cmd_ready   )
    );


    // data TX FIFO
    io_tx_fifo #(
      .DATA_WIDTH(8),
      .BUFFER_DEPTH(2)
      ) i_i2c_tx_fifo (
        .clk_i(sys_clk_i),
        .rstn_i(sys_rstn_i),
        .clr_i(1'b0),
        .data_o(s_data_tx),
        .valid_o(s_data_tx_valid),
        .ready_i(s_data_tx_ready),
        .req_o(data_tx_req_o),
        .gnt_i(data_tx_gnt_i),
        .valid_i(data_tx_valid_i),
        .data_i(data_tx_i),
        .ready_o(data_tx_ready_o)
    );

    udma_dc_fifo #(8,4) i_dc_fifo_tx
    (
        .src_clk_i    ( sys_clk_i          ),
        .src_rstn_i   ( sys_rstn_i         ),
        .src_data_i   ( s_data_tx          ),
        .src_valid_i  ( s_data_tx_valid    ),
        .src_ready_o  ( s_data_tx_ready    ),
        .dst_clk_i    ( periph_clk_i       ),
        .dst_rstn_i   ( per_rstn_i         ),
        .dst_data_o   ( s_data_tx_dc       ),
        .dst_valid_o  ( s_data_tx_dc_valid ),
        .dst_ready_i  ( s_data_tx_dc_ready )
    );

    udma_dc_fifo #(8,4) u_dc_fifo_rx
    (
        .src_clk_i    ( periph_clk_i       ),
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


	udma_i2c_control i_i2c_control
	(
		.clk_i           ( periph_clk_i ),
		.rstn_i          ( per_rstn_i ),
		.ext_events_i    ( s_events ),

		.data_tx_i       ( s_data_tx_dc ),
		.data_tx_valid_i ( s_data_tx_dc_valid),
		.data_tx_ready_o ( s_data_tx_dc_ready),

		.data_rx_o       ( s_data_rx_dc ),
		.data_rx_valid_o ( s_data_rx_dc_valid ),
		.data_rx_ready_i ( s_data_rx_dc_ready ),

        .sw_rst_i        ( s_do_rst ),

        .busy_o          ( s_i2c_busy),
        .al_o            ( s_i2c_al  ),
	    .eot_o           ( s_i2c_eot ),
		.ack_no          ( s_i2c_nack),
	    .err_o           ( err_o  ),
		.scl_i           ( scl_i  ),
		.scl_o           ( scl_o  ),
		.scl_oe          ( scl_oe ),
		.sda_i           ( sda_i  ),
		.sda_o           ( sda_o  ),
		.sda_oe          ( sda_oe ),

        .udma_cmd_i(s_udma_cmd),
        .udma_cmd_valid_i(s_udma_cmd_valid),
        .udma_cmd_ready_o(s_udma_cmd_ready)
	);

    edge_propagator u_eot_ep
    (
        .clk_tx_i ( periph_clk_i ),
        .rstn_tx_i( per_rstn_i   ),
        .edge_i   ( s_i2c_eot    ),
        .clk_rx_i ( sys_clk_i    ),
        .rstn_rx_i( sys_rstn_i   ),
        .edge_o   ( eot_o        )
    );

endmodule
