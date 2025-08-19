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
// Description: Data fetcher block for uDMA IP with linear,sliding,circular and 2D capabilities
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

`define MODE_LINEAR   0
`define MODE_SLIDING  1
`define MODE_CIRCULAR 2
`define MODE_2D       3


module udma_filter_tx_datafetch
  #(
    parameter DATA_WIDTH     = 32,
    parameter FILTID_WIDTH   = 8,
    parameter L2_AWIDTH_NOAL = 15,
    parameter TRANS_SIZE     = 16
    )
   (
    input  logic                      clk_i,
    input  logic                      resetn_i,

    output logic                      tx_ch_req_o,
    output logic [L2_AWIDTH_NOAL-1:0] tx_ch_addr_o,
    output logic                [1:0] tx_ch_datasize_o,
    input  logic                      tx_ch_gnt_i,
    input  logic                      tx_ch_valid_i,
    input  logic     [DATA_WIDTH-1:0] tx_ch_data_i,
    output logic                      tx_ch_ready_o,

    input  logic                      cmd_start_i,
    output logic                      cmd_done_o,

    input  logic [L2_AWIDTH_NOAL-1:0] cfg_start_addr_i,
    input  logic                [1:0] cfg_datasize_i,
    input  logic                [1:0] cfg_mode_i,
    input  logic     [TRANS_SIZE-1:0] cfg_len0_i,
    input  logic     [TRANS_SIZE-1:0] cfg_len1_i,
    input  logic     [TRANS_SIZE-1:0] cfg_len2_i,

    output logic     [DATA_WIDTH-1:0] stream_data_o,
    output logic                [1:0] stream_datasize_o,
    output logic                      stream_valid_o,
    output logic                      stream_sof_o,
    output logic                      stream_eof_o,
    input  logic                      stream_ready_i

    );

    logic [L2_AWIDTH_NOAL-1:0] r_loc_startaddr;
    logic [L2_AWIDTH_NOAL-1:0] s_loc_startaddr;
    logic [L2_AWIDTH_NOAL-1:0] r_loc_pointer;
    logic [L2_AWIDTH_NOAL-1:0] s_loc_pointer;
    logic     [TRANS_SIZE-1:0] r_ptn_buffer_l;
    logic     [TRANS_SIZE-1:0] s_ptn_buffer_l;
    logic     [TRANS_SIZE-1:0] r_ptn_buffer_w;
    logic     [TRANS_SIZE-1:0] s_ptn_buffer_w;

    logic                  s_data_tx_req;
    logic                  s_data_tx_gnt;
    logic                  s_data_tx_ready;
    logic                  s_data_tx_valid;
    logic [DATA_WIDTH-1:0] s_data_tx;
    logic                  s_data_int_ready;
    logic                  s_data_int_valid;
    logic [DATA_WIDTH-1:0] s_data_int;
    logic                  s_done;
    logic                  s_sample_loc_startaddr;
    logic                  s_sample_loc_pointer;
    logic                  s_sample_ptn_buffer_w;
    logic                  s_sample_ptn_buffer_l;
    logic            [1:0] r_mode;
    logic [TRANS_SIZE-1:0] s_datasize_toadd;
    logic                  s_start;
    logic                  s_running;
    logic                  s_evnt_sof;
    logic                  s_evnt_eof;
    logic                  s_is_sof;
    logic                  s_is_sof_next;
    logic                  s_is_eof;
    logic                  r_issof;
    
    enum logic [1:0] {ST_IDLE, ST_RUNNING } r_state,s_state;

    assign tx_ch_req_o      = s_data_tx_req & s_running;
    assign tx_ch_addr_o     = r_loc_pointer;
    assign tx_ch_datasize_o = cfg_datasize_i;
    assign s_data_tx_gnt    = tx_ch_gnt_i;
    assign s_data_tx_valid  = tx_ch_valid_i;
    assign s_data_tx        = tx_ch_data_i;
    assign tx_ch_ready_o    = s_data_tx_ready;

    assign s_data_int_ready  = stream_ready_i;
    assign stream_data_o     = s_data_int;
    assign stream_valid_o    = s_data_int_valid;
    assign stream_datasize_o = cfg_datasize_i;
    assign stream_sof_o     = s_evnt_sof;
    assign stream_eof_o     = s_evnt_eof;

    assign cmd_done_o = s_done;

    io_tx_fifo_mark #(
      .DATA_WIDTH(DATA_WIDTH),
      .BUFFER_DEPTH(4)
      ) u_fifo (
        .clk_i   ( clk_i            ),
        .rstn_i  ( resetn_i         ),
        .clr_i   ( 1'b0             ),
        .sof_i   ( s_is_sof         ),
        .eof_i   ( s_is_eof         ),
        .data_o  ( s_data_int       ),
        .valid_o ( s_data_int_valid ),
        .sof_o   ( s_evnt_sof       ),
        .eof_o   ( s_evnt_eof       ),
        .ready_i ( s_data_int_ready ),
        .req_o   ( s_data_tx_req    ),
        .gnt_i   ( s_data_tx_gnt    ),
        .valid_i ( s_data_tx_valid  ),
        .data_i  ( s_data_tx        ),
        .ready_o ( s_data_tx_ready  )
    );

    always_comb
    begin
      s_done = 1'b0;
      s_is_sof = 1'b0;
      s_is_eof = 1'b0;
      s_is_sof_next = 1'b0;
      s_ptn_buffer_w = r_ptn_buffer_w;
      s_ptn_buffer_l = r_ptn_buffer_l;
      s_sample_loc_startaddr = 1'b0;
      s_sample_loc_pointer   = 1'b0;
      s_sample_ptn_buffer_w  = 1'b0;
      s_sample_ptn_buffer_l  = 1'b0;
      s_loc_pointer          = r_loc_pointer;
      s_loc_startaddr        = r_loc_startaddr;
      case(r_mode)
        `MODE_LINEAR:
        begin
          if (s_data_tx_req && s_data_tx_gnt)
          begin
            s_is_sof = r_issof;
            s_sample_ptn_buffer_w = 1'b1;
            if (r_ptn_buffer_w == cfg_len0_i)
            begin
              s_done   = 1'b1;
              s_is_eof = 1'b1;
              s_ptn_buffer_w = 0;
            end
            else
            begin
              s_ptn_buffer_w = r_ptn_buffer_w + 1;
              s_loc_pointer  = r_loc_pointer + s_datasize_toadd;
              s_sample_loc_pointer  = 1'b1;
              s_sample_ptn_buffer_w = 1'b1;
            end
          end
        end
        `MODE_SLIDING:
        begin
          if (s_data_tx_req && s_data_tx_gnt)
          begin
            s_is_sof = r_issof;
            s_sample_ptn_buffer_w = 1'b1;
            if ((r_ptn_buffer_w == cfg_len0_i) && (r_ptn_buffer_l == cfg_len1_i)) 
            begin
              s_done = 1'b1;
              s_is_eof = 1'b1;
              s_ptn_buffer_w = 0;
              s_ptn_buffer_l = 0;
              s_sample_ptn_buffer_l = 1'b1;
            end
            else if (r_ptn_buffer_w == cfg_len0_i)
            begin
              s_is_eof = 1'b1;
              s_is_sof_next = 1'b1;
              s_sample_ptn_buffer_l = 1'b1;
              s_sample_loc_pointer  = 1'b1;
              s_sample_loc_startaddr = 1'b1;
              s_loc_startaddr = r_loc_startaddr + s_datasize_toadd;
              s_ptn_buffer_w = 0;
              s_ptn_buffer_l = r_ptn_buffer_l + 1;
              s_loc_pointer  = r_loc_startaddr + s_datasize_toadd;
            end
            else
            begin
              s_sample_ptn_buffer_w = 1'b1;
              s_sample_loc_pointer  = 1'b1;
              s_ptn_buffer_w = r_ptn_buffer_w + 1;
              s_loc_pointer  = r_loc_pointer + s_datasize_toadd;
            end
          end
        end
        `MODE_CIRCULAR:
        begin
          if (s_data_tx_req && s_data_tx_gnt)
          begin
            s_is_sof = r_issof;
            s_sample_ptn_buffer_w = 1'b1;
            if ((r_ptn_buffer_w == cfg_len0_i) && (r_ptn_buffer_l == cfg_len1_i)) 
            begin
              s_done = 1'b1;
              s_is_eof = 1'b1;
              s_ptn_buffer_w = 0;
              s_ptn_buffer_l = 0;
              s_sample_ptn_buffer_l = 1'b1;
            end
            else if (r_ptn_buffer_w == cfg_len0_i)
            begin
              s_is_eof = 1'b1;
              s_is_sof_next = 1'b1;
              s_sample_ptn_buffer_l = 1'b1;
              s_sample_loc_pointer  = 1'b1;
              s_ptn_buffer_w = 0;
              s_ptn_buffer_l = r_ptn_buffer_l + 1;
              s_loc_pointer  = r_loc_startaddr;
            end
            else
            begin
              s_sample_ptn_buffer_w = 1'b1;
              s_sample_loc_pointer  = 1'b1;
              s_ptn_buffer_w = r_ptn_buffer_w + 1;
              s_loc_pointer  = r_loc_pointer + s_datasize_toadd;
            end
          end
        end
        `MODE_2D:
        begin
          if (s_data_tx_req && s_data_tx_gnt)
          begin
            s_is_sof = r_issof;
            s_sample_ptn_buffer_w = 1'b1;
            if ((r_ptn_buffer_w == cfg_len0_i) && (r_ptn_buffer_l == cfg_len1_i)) 
            begin
              s_done = 1'b1;
              s_is_eof = 1'b1;
              s_ptn_buffer_w = 0;
              s_ptn_buffer_l = 0;
              s_sample_ptn_buffer_l = 1'b1;
            end
            else if (r_ptn_buffer_w == cfg_len0_i)
            begin
              s_sample_ptn_buffer_l  = 1'b1;
              s_sample_loc_pointer   = 1'b1;
              s_sample_loc_startaddr = 1'b1;
              s_ptn_buffer_w = 0;
              s_ptn_buffer_l = r_ptn_buffer_l + 1;
              s_loc_pointer   = r_loc_startaddr + cfg_len2_i;
              s_loc_startaddr = s_loc_pointer;
            end
            else
            begin
              s_sample_ptn_buffer_w = 1'b1;
              s_sample_loc_pointer  = 1'b1;
              s_ptn_buffer_w = r_ptn_buffer_w + 1;
              s_loc_pointer  = r_loc_pointer + s_datasize_toadd;
            end
          end
        end
      endcase
    end

    always_comb
    begin: mux_datasize
      case(cfg_datasize_i)
        2'b00:
          s_datasize_toadd = 'h1;
        2'b01:
          s_datasize_toadd = 'h2;
        2'b10:
          s_datasize_toadd = 'h4;
        default:
          s_datasize_toadd = '0;
      endcase
    end

    always_comb
    begin
      s_state = r_state;
      s_start = 1'b0;
      s_running = 1'b0;
      case(r_state)
        ST_IDLE:
        begin
          if(cmd_start_i)
          begin
            s_state = ST_RUNNING;
            s_start = 1'b1;
          end
        end
        ST_RUNNING:
        begin
          s_running = 1'b1;
          if(s_done)
          begin
            s_state = ST_IDLE;
          end
        end
      endcase // r_state
    end

    always_ff @(posedge clk_i or negedge resetn_i) 
    begin
      if(~resetn_i) 
      begin
        r_loc_startaddr <= 0;
        r_loc_pointer   <= 0;
        r_ptn_buffer_w  <= 0;
        r_ptn_buffer_l  <= 0;
        r_mode          <= `MODE_LINEAR;
        r_state         <= ST_IDLE;
        r_issof         <= 1'b0;
      end else 
      begin
        r_state          <= s_state;

        if(s_start || s_is_sof_next)
          r_issof <= 1'b1;
        else if(r_issof & (s_data_tx_req && s_data_tx_gnt))
          r_issof <= 1'b0;

        if(s_start)
        begin
          r_mode          <= cfg_mode_i;
          r_loc_startaddr <= cfg_start_addr_i;
          r_loc_pointer   <= cfg_start_addr_i;
          r_ptn_buffer_w  <= 0;
          r_ptn_buffer_l  <= 0;
        end
        else
        begin 
          if(s_sample_loc_startaddr)
            r_loc_startaddr <= s_loc_startaddr;
          if(s_sample_loc_pointer)
            r_loc_pointer   <= s_loc_pointer;
          if(s_sample_ptn_buffer_w)
            r_ptn_buffer_w  <= s_ptn_buffer_w;
          if(s_sample_ptn_buffer_l)
            r_ptn_buffer_l  <= s_ptn_buffer_l;
        end
      end
    end
endmodule

