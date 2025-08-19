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
// Description: Address generation block for a uDMA channel
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_ch_addrgen
  #(
    parameter L2_AWIDTH_NOAL = 18,
    parameter TRANS_SIZE     = 16,
    parameter STREAM_ID_WIDTH = 3
   ) (
    input  logic	                       clk_i,
    input  logic                         rstn_i,

    input  logic  [L2_AWIDTH_NOAL-1 : 0] cfg_startaddr_i,
    input  logic      [TRANS_SIZE-1 : 0] cfg_size_i,
    input  logic                         cfg_continuous_i,
    input  logic                         cfg_en_i,
    input  logic                 [1 : 0] cfg_stream_i,
    input  logic [STREAM_ID_WIDTH-1 : 0] cfg_stream_id_i,
    input  logic                         cfg_clr_i,

    input  logic                         int_not_stall_i,
    input  logic                 [1 : 0] int_datasize_i,

    output logic  [L2_AWIDTH_NOAL-1 : 0] int_ch_curr_addr_o,
    output logic      [TRANS_SIZE-1 : 0] int_ch_bytes_left_o,
    output logic                         int_ch_pending_o,
    output logic                 [1 : 0] int_ch_curr_bytes_o,

    input  logic                         int_ch_grant_i,
    output logic                         int_ch_en_o,
    output logic                         int_ch_en_prev_o,
    output logic                         int_ch_events_o,
    output logic                         int_ch_sot_o,
    output logic                 [1 : 0] int_stream_o,
    output logic [STREAM_ID_WIDTH-1 : 0] int_stream_id_o
  );

    logic  [L2_AWIDTH_NOAL-1 : 0] r_addresses;
    logic      [TRANS_SIZE-1 : 0] r_counters;
    logic                 [1 : 0] r_stream;
    logic [STREAM_ID_WIDTH-1 : 0] r_stream_id;
    logic                         r_en;
    logic                         r_event;
    logic                         r_ch_en;

    logic [L2_AWIDTH_NOAL-1 : 0] s_addresses;
    logic     [TRANS_SIZE-1 : 0] s_counters;
    logic                [1 : 0] s_stream;
    logic [STREAM_ID_WIDTH-1 : 0] s_stream_id;
    logic                        s_en;
    logic                        s_event;
    logic                        s_ch_en;

    logic                        r_sot;
    logic                        s_sot;

    logic                        s_compare;

    logic                        r_pending_en;
    logic                        s_pending_en;
    logic     [TRANS_SIZE-1 : 0] s_datasize_toadd;

    logic                        s_continuous;

    assign int_ch_en_o      = r_en;
    assign int_ch_en_prev_o = s_en;
    assign int_ch_events_o  = r_event;
    assign int_ch_sot_o     = r_sot;
    assign int_ch_pending_o = r_pending_en;

    assign int_ch_curr_addr_o  = r_addresses;
    assign int_ch_bytes_left_o = r_counters;
    assign int_stream_o    = r_stream;
    assign int_stream_id_o = r_stream_id;

    assign s_compare = (r_counters <= s_datasize_toadd);

    always_comb
    begin: proc_curr_bytes 
      case(int_datasize_i)
        2'b00:
          int_ch_curr_bytes_o = 'h0;
        2'b01:
        begin
          if(s_compare && (r_counters[1:0] == 2'h1))
              int_ch_curr_bytes_o = 'h0;
          else
              int_ch_curr_bytes_o = 'h1;
        end
        2'b10:
          if(s_compare && (r_counters[1:0] == 2'h1))
              int_ch_curr_bytes_o = 'h0;
          else if (s_compare && (r_counters[1:0] == 2'h2))
              int_ch_curr_bytes_o = 'h1;
          else if (s_compare && (r_counters[1:0] == 2'h3))
              int_ch_curr_bytes_o = 'h2;
          else
              int_ch_curr_bytes_o = 'h3;
        default:
          int_ch_curr_bytes_o = 'h0;
      endcase
    end

    always_comb
    begin: mux_datasize
      case(int_datasize_i)
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
    begin : proc_pending_en
      s_pending_en = r_pending_en;
      if(cfg_en_i && (r_ch_en || r_en) && (!s_compare || (s_compare && (!int_not_stall_i || ~int_ch_grant_i) )) )
        s_pending_en = 1'b1;
      else if (r_en && int_ch_grant_i && int_not_stall_i && (r_counters <= s_datasize_toadd))
        s_pending_en = 1'b0;
    end


    always_comb 
    begin : proc_next_val
      s_counters  = r_counters ;  
      s_addresses = r_addresses;  
      s_en        = r_en       ;  
      s_ch_en     = r_ch_en    ;  
      s_event     = r_event    ;  
      s_stream    = r_stream   ;
      s_stream_id = r_stream_id;
      s_sot       = r_sot;
      if(cfg_en_i && !r_en) //sample config data when enabling the channel
      begin
          s_counters  =  cfg_size_i;
          s_addresses =  cfg_startaddr_i;
          s_en        =  1'b1;
          s_ch_en     =  1'b0;
          s_event     =  1'b0;
          s_sot       =  1'b1;
          s_stream    =  cfg_stream_i;
          s_stream_id = cfg_stream_id_i;
      end
      else if (cfg_clr_i)
      begin
          s_counters  =   '0;
          s_addresses =   '0;
          s_en        =  1'b0;
          s_ch_en     =  1'b0;
          s_event     =  1'b0;
          s_sot       =  1'b0;
          s_stream    =  1'b0;
      end
      else
      begin
        if (int_not_stall_i && r_en && int_ch_grant_i) //if granted and channel enabled then
        begin
          if (s_compare) //if this is last transfer for the channel 
          begin
            s_event     =  1'b1;
            if (!cfg_continuous_i && !r_pending_en && !cfg_en_i)
            begin
              s_en    = 1'b0; //if not in continuous mode then stop the channel
              s_ch_en = 1'b0;
              s_counters  = '0;
              s_addresses = '0;
              s_stream    = 1'b0;
              s_sot       = 1'b0;
            end
            else
            begin
              s_counters  = cfg_size_i;      //reload the buffer size
              s_addresses = cfg_startaddr_i; //reload the start address
              s_stream    = cfg_stream_i;
              s_stream_id = cfg_stream_id_i;
              s_en        = 1'b1;
              s_ch_en     = 1'b1;
              s_sot       = 1'b1;
            end
          end
          else
          begin
            s_event     = 1'b0;
            s_sot       = 1'b0;
            s_ch_en     = 1'b1;
            s_counters  = r_counters - s_datasize_toadd;  //decrement the remaining bytes of the channel
            s_addresses = r_addresses + s_datasize_toadd; //increment the address
          end
        end
        else
        begin
          s_event     =  1'b0;
          s_sot       =  1'b0;
        end
      end
    end    

    always_ff @(posedge clk_i or negedge rstn_i) 
    begin : ff_addr
      if(~rstn_i) begin
        r_addresses  <=  '0;
        r_counters   <=  '0;
        r_en         <= 1'b0;
        r_ch_en      <= 1'b0;
        r_event      <= 1'b0;
        r_pending_en <= 1'b0;
        r_stream     <= 1'b0;
        r_stream_id  <=  'h0;
        r_sot        <= 1'b0;
      end else 
      begin
        r_event        <=  s_event;
        r_sot          <=  s_sot;
        //if(int_not_stall_i)
            r_pending_en   <=  s_pending_en;

        if( ((cfg_en_i && !r_en) || cfg_clr_i)      ||
            (cfg_en_i && s_compare && int_not_stall_i)   )
        begin
            r_counters  <= s_counters ; 
            r_addresses <= s_addresses; 
            r_en        <= s_en       ; 
            r_ch_en     <= s_ch_en    ; 
            r_stream    <= s_stream;
            r_stream_id <= s_stream_id;
        end
        else
        begin
          if (int_not_stall_i && r_en && int_ch_grant_i) //if granted and channel enabled then
          begin
            if (s_compare) //if this is last transfer for the channel 
            begin
              r_counters  <= s_counters;
              r_addresses <= s_addresses;
              r_stream    <= s_stream;
              r_stream_id <= s_stream_id;
              if (!cfg_continuous_i && !r_pending_en)
              begin
                r_en        <= s_en; 
                r_ch_en     <= s_ch_en;
              end
            end
            else
            begin
              r_ch_en     <= s_ch_en;
              r_counters  <= s_counters;  //decrement the remaining bytes of the channel
              r_addresses <= s_addresses; //increment the address
            end
          end
        end
      end
    end

endmodule

