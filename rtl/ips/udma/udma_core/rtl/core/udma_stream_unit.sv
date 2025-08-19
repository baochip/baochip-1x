// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2015-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module udma_stream_unit
     #(
          parameter L2_AWIDTH_NOAL    = 16,
          parameter DATA_WIDTH        = 32,
          parameter STREAM_ID_WIDTH    = 2,
          parameter INST_ID           = 0
     )
     (
          input  logic                        clk_i,
          input  logic                        rstn_i,
          input  logic                        cmd_clr_i,
          output logic                        tx_ch_req_o,
          output logic [L2_AWIDTH_NOAL-1 : 0] tx_ch_addr_o,
          output logic                [1 : 0] tx_ch_datasize_o,
          input  logic                        tx_ch_gnt_i,
          input  logic                        tx_ch_valid_i,
          input  logic     [DATA_WIDTH-1 : 0] tx_ch_data_i,
          output logic                        tx_ch_ready_o,  
          input  logic [STREAM_ID_WIDTH-1 : 0] in_stream_dest_i,
          input  logic     [DATA_WIDTH-1 : 0] in_stream_data_i,
          input  logic                [1 : 0] in_stream_datasize_i,
          input  logic                        in_stream_valid_i,
          input  logic                        in_stream_sot_i,
          input  logic                        in_stream_eot_i,
          output logic                        in_stream_ready_o,
          output logic     [DATA_WIDTH-1 : 0] out_stream_data_o,
          output logic                [1 : 0] out_stream_datasize_o,
          output logic                        out_stream_valid_o,
          output logic                        out_stream_sot_o,
          output logic                        out_stream_eot_o,
          input  logic                        out_stream_ready_i,
          input  logic [L2_AWIDTH_NOAL-1 : 0] spoof_addr_i, 
          input  logic [STREAM_ID_WIDTH-1 : 0] spoof_dest_i,
          input  logic                [1 : 0] spoof_datasize_i,
          input  logic                        spoof_req_i,
          input  logic                        spoof_gnt_i
     );

     logic          s_spoof_match;
     logic          s_input_match;
     logic          s_ptr_match;
     logic          s_rd_ptr_jmp_match;
     logic          s_trans_stream;
     logic          s_trans_wr;
     logic          s_trans_rd;
     logic          s_stream_sel;

     logic [L2_AWIDTH_NOAL-1:0] r_wr_ptr;
     logic [L2_AWIDTH_NOAL-1:0] r_rd_ptr; 
     logic [L2_AWIDTH_NOAL-1:0] r_jump_dst;
     logic [L2_AWIDTH_NOAL-1:0] r_jump_src;
     logic [L2_AWIDTH_NOAL-1:0] s_datasize_toadd, s_wr_ptr_guess;
     logic            [1:0] r_datasize;

     logic                  s_fifo_out_req  ;
     logic                  s_fifo_out_gnt  ;
     logic                  s_fifo_out_valid;
     logic [DATA_WIDTH-1:0] s_fifo_out_data ;
     logic                  s_fifo_out_ready;
     logic [DATA_WIDTH-1:0] s_fifo_in_data  ;
     logic                  s_fifo_in_valid ;
     logic                  s_fifo_in_ready ;

     logic                  s_req;
     logic                  s_rd_ptr_next;
     logic                  r_do_jump;
     logic                  s_sample_rd;
     logic                  s_sample_wr;
     logic                  s_sample_wr_start;
     logic                  r_err;
     logic                  s_stream_buf_en;
     logic [1:0] s_int_datasize;
     logic s_is_jump;

     enum logic [1:0] {ST_IDLE,ST_BUF_TRAN,ST_BUF_WAIT,ST_STREAM} s_state,r_state;

     assign s_spoof_match  = (spoof_dest_i == INST_ID);
     assign s_input_match  = (in_stream_dest_i == INST_ID);
     assign s_ptr_match    = (r_rd_ptr == r_wr_ptr);
     assign s_rd_ptr_jmp_match = (r_rd_ptr == r_jump_src);
     assign s_trans_stream = in_stream_valid_i & s_input_match;
     assign s_trans_wr     = spoof_gnt_i & spoof_req_i & s_spoof_match;
     assign s_trans_rd     = s_req & tx_ch_gnt_i;
     assign s_int_datasize = s_stream_sel ? r_datasize : in_stream_datasize_i;
     assign out_stream_data_o     = s_stream_sel ? s_fifo_in_data : in_stream_data_i;
     assign out_stream_datasize_o = s_stream_sel ? r_datasize : in_stream_datasize_i; 
     assign out_stream_valid_o    = s_stream_sel ? s_fifo_in_valid : in_stream_valid_i; 
     assign out_stream_sot_o      = s_stream_sel ? 1'b0 : in_stream_sot_i; 
     assign out_stream_eot_o      = s_stream_sel ? 1'b0 : in_stream_eot_i; 

     assign s_wr_ptr_guess = r_wr_ptr + s_datasize_toadd;
     assign s_is_jump      = (spoof_addr_i != s_wr_ptr_guess);

     assign tx_ch_req_o = s_fifo_out_req & s_stream_buf_en;
     assign s_fifo_out_gnt = tx_ch_gnt_i & s_stream_buf_en;
     assign s_fifo_out_valid = tx_ch_valid_i;
     assign s_fifo_out_data = tx_ch_data_i;
     assign tx_ch_ready_o = s_fifo_out_ready;
     assign tx_ch_addr_o = r_rd_ptr;
     assign tx_ch_datasize_o = 'h0;

     io_tx_fifo #(
          .DATA_WIDTH(DATA_WIDTH),
          .BUFFER_DEPTH(4)
     ) i_fifo (
          .clk_i   ( clk_i ),
          .rstn_i  ( rstn_i ),

          .clr_i   ( cmd_clr_i ),

          .req_o   ( s_fifo_out_req   ),
          .gnt_i   ( s_fifo_out_gnt   ),
          .valid_i ( s_fifo_out_valid ),
          .data_i  ( s_fifo_out_data  ),
          .ready_o ( s_fifo_out_ready ),

          .data_o  ( s_fifo_in_data   ),
          .valid_o ( s_fifo_in_valid  ),
          .ready_i ( s_fifo_in_ready  )
     );

     always_comb 
     begin
          s_rd_ptr_next = 'h0;
          if(r_do_jump && s_rd_ptr_jmp_match)
               s_rd_ptr_next = r_jump_dst;
          else
               s_rd_ptr_next = r_rd_ptr + s_datasize_toadd;
     
     end

    always_comb
    begin
      case(s_int_datasize)
        2'b00:
          s_datasize_toadd = 'h1;
        2'b01:
          s_datasize_toadd = 'h2;
        2'b10:
          s_datasize_toadd = 'h4;
        default
          s_datasize_toadd = '0;
      endcase
    end

    always_comb
    begin
        s_fifo_in_ready = 1'b0;
        s_stream_buf_en = 1'b0;
        s_state         = r_state;
        s_req                = 1'b0;
        s_stream_sel         = 1'b0;
        s_sample_rd          = 1'b0;
        s_sample_wr          = 1'b0;
        s_sample_wr_start    = 1'b0;
        case(r_state)
            ST_IDLE:
            begin
               if(cmd_clr_i)
                    s_state = ST_IDLE;
               else if(s_trans_wr)
               begin
                    s_sample_wr_start = 1'b1;
                    s_sample_rd = 1'b1;
                    s_state = ST_BUF_TRAN;
               end
            end
            ST_BUF_TRAN:
            begin
               s_req        = 1'b1;
               s_stream_sel = 1'b1;
               if(s_trans_wr)
                    s_sample_wr = 1'b1;
               if(cmd_clr_i)
                    s_state = ST_IDLE;
               else if(s_trans_rd)
               begin
                    if(!s_ptr_match)
                    begin
                         s_sample_rd = 1'b1;
                    end
                    else
                         s_state = ST_BUF_WAIT;
               end
            end
            ST_BUF_WAIT:
            begin
               s_stream_sel = 1'b1;
               if(cmd_clr_i)
                    s_state = ST_IDLE;
               else if(s_trans_wr) 
               begin
                    s_sample_wr = 1'b1;
                    s_sample_rd = 1'b1;
                    s_state  = ST_BUF_TRAN;
               end
            end
            ST_STREAM:
            begin
               s_state     = ST_IDLE;
            end
            default:
                s_state = ST_IDLE;
        endcase
    end

     always_ff @(posedge clk_i or negedge rstn_i) 
     begin 
          if(~rstn_i) 
          begin
               r_wr_ptr      <= 'h0;
               r_rd_ptr      <= 'h0;
               r_jump_src    <= 'h0;
               r_jump_dst    <= 'h0;
               r_do_jump     <= 'h0;
               r_err         <= 'h0;
               r_state       <= ST_IDLE;
          end 
          else 
          begin
               if(cmd_clr_i) 
               begin
                    r_wr_ptr      <= 'h0;
                    r_rd_ptr      <= 'h0;
                    r_jump_src    <= 'h0;
                    r_jump_dst    <= 'h0;
                    r_do_jump     <= 'h0;
                    r_err         <= 'h0;
                    r_state       <= ST_IDLE;
               end
               else 
               begin
                    r_state <= s_state;

                    if (s_sample_wr_start)
                    begin
                         r_wr_ptr     <= spoof_addr_i;
                    end
                    else if(s_sample_wr)
                    begin
                         if (s_is_jump)
                         begin
                              r_jump_src <= r_wr_ptr;
                              r_jump_dst <= spoof_addr_i;
                              r_do_jump  <= 1'b1;
                         end
                         r_wr_ptr     <= spoof_addr_i;
                    end

               end
          end
     end


endmodule
