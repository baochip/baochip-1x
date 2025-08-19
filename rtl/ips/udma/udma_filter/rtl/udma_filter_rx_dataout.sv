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
// Description: Data out dma engine for uDMA filtering block
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

`define MODE_LINEAR   0
`define MODE_2D_ROW   1
`define MODE_2D_COL   2


module udma_filter_rx_dataout
  #(
    parameter DATA_WIDTH     = 32,
    parameter FILTID_WIDTH   = 8,
    parameter L2_AWIDTH_NOAL = 15,
    parameter BUFFER_DEPTH   = 4,
    parameter TRANS_SIZE     = 16
    )
   (
    input  logic                      clk_i,
    input  logic                      resetn_i,

    output logic [L2_AWIDTH_NOAL-1:0] rx_ch_addr_o,
    output logic                [1:0] rx_ch_datasize_o,
    output logic                      rx_ch_valid_o,
    output logic     [DATA_WIDTH-1:0] rx_ch_data_o,
    input  logic                      rx_ch_ready_i,

    input  logic                      cmd_start_i,
    output logic                      cmd_done_o,

    input  logic [L2_AWIDTH_NOAL-1:0] cfg_start_addr_i,
    input  logic                [1:0] cfg_datasize_i,
    input  logic                [1:0] cfg_mode_i,
    input  logic     [TRANS_SIZE-1:0] cfg_len0_i,
    input  logic     [TRANS_SIZE-1:0] cfg_len1_i,
    input  logic     [TRANS_SIZE-1:0] cfg_len2_i,

    input  logic     [DATA_WIDTH-1:0] stream_data_i,
    input  logic                      stream_valid_i,
    output logic                      stream_ready_o

    );

    logic [L2_AWIDTH_NOAL-1:0] r_loc_startaddr;
    logic [L2_AWIDTH_NOAL-1:0] s_loc_startaddr;
    logic [L2_AWIDTH_NOAL-1:0] r_loc_pointer;
    logic [L2_AWIDTH_NOAL-1:0] s_loc_pointer;
    logic     [TRANS_SIZE-1:0] r_ptn_buffer_l;
    logic     [TRANS_SIZE-1:0] s_ptn_buffer_l;
    logic     [TRANS_SIZE-1:0] r_ptn_buffer_w;
    logic     [TRANS_SIZE-1:0] s_ptn_buffer_w;

    logic [DATA_WIDTH-1:0] s_data_rx;
    logic                  s_data_rx_valid;
    logic                  s_data_rx_ready;
    
    logic                  s_done;
    logic                  s_sample_loc_startaddr;
    logic                  s_sample_loc_pointer;
    logic                  s_sample_ptn_buffer_w;
    logic                  s_sample_ptn_buffer_l;
    logic            [1:0] r_mode;
    logic [TRANS_SIZE-1:0] s_datasize_toadd;
    logic                  s_start;
    logic                  s_running;

    enum logic [1:0] {ST_IDLE, ST_RUNNING } r_state,s_state;

    assign rx_ch_addr_o     = r_loc_pointer;
    assign rx_ch_datasize_o = cfg_datasize_i;
    assign rx_ch_data_o     = s_data_rx;
    assign rx_ch_valid_o    = s_data_rx_valid;
    assign s_data_rx_ready  = rx_ch_ready_i;

    assign cmd_done_o = s_done;

    io_generic_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH)
    ) i_fifo (
        .clk_i     ( clk_i     ),
        .rstn_i    ( resetn_i  ),

        .clr_i     ( 1'b0 ),

        .elements_o(      ),

        .data_o    ( s_data_rx       ),
        .valid_o   ( s_data_rx_valid ),
        .ready_i   ( s_data_rx_ready ),

        .valid_i   ( stream_valid_i ),
        .data_i    ( stream_data_i  ),
        .ready_o   ( stream_ready_o )
    );

    always_comb
    begin
      s_done = 1'b0;
      s_loc_startaddr = r_loc_startaddr;
      s_loc_pointer   = r_loc_pointer;
      s_ptn_buffer_w = r_ptn_buffer_w;
      s_ptn_buffer_l = r_ptn_buffer_l;
      s_sample_loc_startaddr = 1'b0;
      s_sample_loc_pointer   = 1'b0;
      s_sample_ptn_buffer_w  = 1'b0;
      s_sample_ptn_buffer_l  = 1'b0;
      if(s_running)
      begin
        case(r_mode)
          `MODE_LINEAR:
          begin
            if (s_data_rx_valid && s_data_rx_ready)
            begin
              s_sample_ptn_buffer_w = 1'b1;
              if (r_ptn_buffer_w == cfg_len0_i)
              begin
                s_done = 1'b1;
                s_ptn_buffer_w = 0;
              end
              else
              begin
                s_ptn_buffer_w = r_ptn_buffer_w + 1;
                s_loc_pointer  = r_loc_pointer + s_datasize_toadd;
                s_sample_loc_pointer = 1'b1;
              end
            end
          end
          `MODE_2D_ROW:
          begin
            if (s_data_rx_valid && s_data_rx_ready)
            begin
              s_sample_ptn_buffer_w = 1'b1;
              if ((r_ptn_buffer_w == cfg_len0_i) && (r_ptn_buffer_l == cfg_len1_i)) 
              begin
                s_done = 1'b1;
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
          `MODE_2D_COL:
          begin
            if (s_data_rx_valid && s_data_rx_ready)
            begin
              s_sample_ptn_buffer_w = 1'b1;
              if ((r_ptn_buffer_w == cfg_len0_i) && (r_ptn_buffer_l == cfg_len1_i)) 
              begin
                s_done = 1'b1;
                s_ptn_buffer_w = 0;
                s_ptn_buffer_l = 0;
                s_sample_ptn_buffer_l = 1'b1;
              end
              else if (r_ptn_buffer_l == cfg_len1_i)
              begin
                s_sample_ptn_buffer_l  = 1'b1;
                s_sample_loc_pointer   = 1'b1;
                s_sample_loc_startaddr = 1'b1;
                s_ptn_buffer_l = 0;
                s_ptn_buffer_w = r_ptn_buffer_w + 1;
                s_loc_pointer   = r_loc_startaddr + s_datasize_toadd;
                s_loc_startaddr = s_loc_pointer;
              end
              else
              begin
                s_sample_ptn_buffer_l = 1'b1;
                s_sample_loc_pointer  = 1'b1;
                s_ptn_buffer_l = r_ptn_buffer_l + 1;
                s_loc_pointer  = r_loc_pointer + cfg_len2_i;
              end
            end
          end
        endcase
      end
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
      end else 
      begin
        r_state <= s_state;
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

