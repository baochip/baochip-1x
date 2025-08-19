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
// Description: Module that handles command interface
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
module sdio_txrx_cmd
(
    input  logic         clk_i,
    input  logic         rstn_i,

    input  logic         clr_stat_i,

    input  logic         cmd_start_i,
    input  logic   [5:0] cmd_op_i,
    input  logic  [31:0] cmd_arg_i,
    input  logic   [2:0] cmd_rsp_type_i,

    output logic [127:0] rsp_data_o,

    input  logic         busy_i,

    output logic         start_write_o,
    output logic         start_read_o,

    output logic         eot_o,

    output logic   [5:0] status_o,

    output logic         sdclk_en_o,

    input  logic         sdcmd_i,
    output logic         sdcmd_o,
    output logic         sdcmd_oen_o,
    output logic   [5:0] debug_stat_o // 20240113 for debugging
  );

  localparam STATUS_RSP_TIMEOUT      = 6'b000001;
  localparam STATUS_RSP_WRONG_DIR    = 6'b000010;
  localparam STATUS_RSP_BUSY_TIMEOUT = 6'b000100;

  localparam RSP_TYPE_NULL        = 3'b000;
  localparam RSP_TYPE_48_CRC      = 3'b001;
  localparam RSP_TYPE_48_NOCRC    = 3'b010;
  localparam RSP_TYPE_136         = 3'b011;
  localparam RSP_TYPE_48_BSY      = 3'b100;

    enum logic [3:0] {ST_IDLE,
                      ST_WAIT,
                      ST_WAIT_BUSY,
                      ST_TX_START,
                      ST_TX_STOP,
                      ST_TX_DIR,
                      ST_TX_SHIFT,
                      ST_TX_CRC,
                      ST_RX_START,
                      ST_RX_STOP,
                      ST_RX_DIR,
                      ST_RX_SHIFT,
                      ST_RX_CRC} s_state,r_state;

    logic [6:0] s_crc;
    logic       s_crc_in;
    logic       s_crc_out;
    logic       s_crc_en;
    logic       s_crc_clr;
    logic       s_crc_shift;
    logic       s_crc_intx;

    logic       s_clk_en;

    logic [37:0] r_cmd;

    logic [135:0] r_rsp;
    logic       s_rsp_en;
    logic [7:0] s_rsp_len;
    logic       s_rsp_crc;
    logic       s_rsp_bsy;

    logic       s_eot;

    logic       s_sdcmd;
    logic       s_sdcmd_oen;
    logic       r_sdcmd;
    logic       r_sdcmd_oen;
    logic       s_shift_cmd;
    logic       s_shift_resp;

    logic       s_start_write;
    logic       s_start_read;

    logic       s_cnt_start;
    logic       s_cnt_done;
    logic [7:0] s_cnt_target;
    logic [7:0] r_cnt;
    logic       r_cnt_running;
    logic [5:0] s_status;
    logic [5:0] r_status;
    logic       s_status_sample;

    assign s_crc_in    = s_crc_intx ? sdcmd_i : s_sdcmd;
    assign sdcmd_o     = r_sdcmd;
    assign sdcmd_oen_o = r_sdcmd_oen;
    assign eot_o       = s_eot;
    assign sdclk_en_o  = s_clk_en;
    assign rsp_data_o  = r_rsp[127:0];

    assign start_write_o = s_start_write;
    assign start_read_o  = s_start_read;

    assign status_o = r_status;
    assign debug_stat_o = {2'b00, r_state}; // 20240114, debug, internal stat machine

  sdio_crc7 i_cmd_crc (
    .clk_i        ( clk_i  ),
    .rstn_i       ( rstn_i ),
    .crc7_o       ( s_crc  ),
    .crc7_serial_o( s_crc_out   ),
    .data_i       ( s_crc_in    ),
    .shift_i      ( s_crc_shift ),
    .clr_i        ( s_crc_clr   ),
    .sample_i     ( s_crc_en    )
  );

    always_comb 
    begin
      s_rsp_en  = 1'b0;
      s_rsp_crc = 1'b0;
      s_rsp_len = 8'hFF;
      s_rsp_bsy = 1'b0;
      case(cmd_rsp_type_i)
        RSP_TYPE_48_CRC:
        begin
          s_rsp_en = 1'b1;
          s_rsp_crc = 1'b1;
          s_rsp_len = 8'd37;
        end
        RSP_TYPE_48_BSY:
        begin
          s_rsp_en = 1'b1;
          s_rsp_crc = 1'b1;
          s_rsp_len = 8'd37;
          s_rsp_bsy = 1'b1;
        end
        RSP_TYPE_48_NOCRC:
        begin
          s_rsp_en = 1'b1;
          s_rsp_crc = 1'b0;
          s_rsp_len = 8'd37;
        end
        RSP_TYPE_136:
        begin
          s_rsp_en = 1'b1;
          s_rsp_crc = 1'b0;
          s_rsp_len = 8'd133;
        end
      endcase
    end

    always_comb
    begin
      s_sdcmd      = 1'b1;
      s_sdcmd_oen  = 1'b1;
      s_state      = r_state;
      s_shift_cmd  = 1'b0;
      s_shift_resp = 1'b0;
      s_crc_shift  = 1'b0;
      s_crc_en     = 1'b0;
      s_crc_intx   = 1'b0; //default CRC takes input from sddata out
      s_cnt_start  = 1'b0;
      s_cnt_target = 8'h0;
      s_status     = 'h0;
      s_status_sample = 1'b0;
      s_eot        = 1'b0;
      s_crc_clr    = 1'b0;
      s_clk_en     = 1'b1;
      s_start_write = 1'b0;
      s_start_read  = 1'b0;
      case(r_state)
        ST_IDLE:
        begin
          s_clk_en = 1'b0;
          if(cmd_start_i)
          begin
            s_status_sample = 1'b1; // Clear previous status
            s_state = ST_TX_START;
            s_clk_en = 1'b1;
          end
        end
        ST_TX_START:
        begin
          s_sdcmd = 1'b0;      //start bit
          s_sdcmd_oen  = 1'b0; // CMD  output enabled
          s_crc_clr = 1'b1;
          s_state = ST_TX_DIR;
        end
        ST_TX_DIR:
        begin
          s_sdcmd = 1'b1;      // direction controller to SD periph
          s_sdcmd_oen  = 1'b0; // CMD  output enabled
          s_crc_en = 1'b1;     // crc is calculated
          s_cnt_start = 1'b1;  // starts counting
          s_cnt_target = 8'd37;// shifts 38 bits
          s_state = ST_TX_SHIFT;
        end
        ST_TX_SHIFT:
        begin
          s_sdcmd = r_cmd[37]; // outputs command and argument
          s_sdcmd_oen  = 1'b0; // CMD  output enabled
          s_shift_cmd  = 1'b1; // shifts data out
          s_crc_en = 1'b1;     // crc is calculated
          if(s_cnt_done)
          begin
            s_state = ST_TX_CRC;
            s_cnt_start = 1'b1;  // starts counting
            s_cnt_target = 8'd6;// shifts 7 bits
          end
        end
        ST_TX_CRC:
        begin
          s_sdcmd = s_crc_out;  // outputs CRC
          s_sdcmd_oen  = 1'b0; // CMD  output enabled
          s_crc_shift  = 1'b1; // shifts CRC out
          s_crc_en     = 1'b1; // crc is calculated
          if(s_cnt_done)
          begin
            s_state = ST_TX_STOP;
          end
        end
        ST_TX_STOP:
        begin
          s_sdcmd = 1'b1;      // stop bit
          s_sdcmd_oen  = 1'b0; // CMD  output enabled
          s_start_read = 1'b1; 
          if(s_rsp_en)
          begin
            s_cnt_start = 1'b1;  // starts counting
            s_cnt_target = 8'd37;// waits 38 cycles max          
            s_sdcmd_oen = 1'b0;  // bug, 20241230, should not hi-z CMD now!
            s_state = ST_RX_START;
          end
          else
          begin
            s_cnt_start = 1'b1;  // starts counting
            s_cnt_target = 8'd7; // waits 8 cycles max          
            s_state = ST_WAIT;
          end
        end
        ST_RX_START:
        begin
          s_sdcmd_oen = 1'b1;
          if(!sdcmd_i)
            s_state = ST_RX_DIR;
          else if(s_cnt_done)
          begin
            s_status = r_status | STATUS_RSP_TIMEOUT;
            s_status_sample = 1'b1;
            s_state = ST_IDLE;
          end
        end
        ST_RX_DIR:
        begin
          s_sdcmd_oen = 1'b1;
          if(!sdcmd_i)
          begin
            s_cnt_start = 1'b1;      // starts counting
            s_cnt_target = s_rsp_len; // gets rsp                      
            s_state = ST_RX_SHIFT;
          end
          else 
          begin
            s_status = r_status | STATUS_RSP_WRONG_DIR;
            s_status_sample = 1'b1;
            s_state = ST_IDLE;
          end
        end
        ST_RX_SHIFT:
        begin
          s_sdcmd_oen = 1'b1;
          s_shift_resp  = 1'b1; // shifts data out
          s_crc_en = 1'b1;      // crc is calculated
          if(s_cnt_done)
          begin
            if(s_rsp_crc)
            begin
              s_state = ST_RX_CRC;
              s_cnt_start = 1'b1;  // starts counting
              s_cnt_target = 8'd7;// shifts 8 bits
            end
            else
            begin
              if (s_rsp_bsy)
              begin
                s_cnt_start  = 1'b1;  // starts counting
                s_cnt_target = 8'hFF; // waits 256 cycles max(TIMEOUT)          
                s_state      = ST_WAIT_BUSY;
              end
              else
              begin
                s_cnt_start  = 1'b1; // starts counting
                s_cnt_target = 8'd7; // waits 8 cycles max          
                s_state      = ST_WAIT;
              end
            end
          end
        end
        ST_RX_CRC:
        begin
          s_sdcmd_oen = 1'b1;
          if(s_cnt_done)
          begin
            s_cnt_start  = 1'b1; // starts counting
            s_cnt_target = 8'd7; // waits 8 cycles max          
            s_state      = ST_WAIT;
          end
        end
        ST_WAIT_BUSY:
        begin
          s_sdcmd_oen = 1'b1;
          if(!busy_i)
          begin
            s_cnt_start  = 1'b1; // starts counting
            s_cnt_target = 8'd7; // waits 8 cycles max          
            s_state      = ST_WAIT;
          end
          else if(s_cnt_done)
          begin
            s_status = r_status | STATUS_RSP_BUSY_TIMEOUT;
            s_status_sample = 1'b1;
            s_cnt_start  = 1'b1; // starts counting
            s_cnt_target = 8'd7; // waits 8 cycles max          
            s_state      = ST_WAIT;
          end
        end
        ST_WAIT:
        begin
          if(s_cnt_done)
          begin
            s_eot   = 1'b1;
            s_start_write = 1'b1;
            s_state = ST_IDLE;
          end
        end
      endcase
    end

    assign s_cnt_done = (r_cnt == 0);

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_cnt
      if(~rstn_i) begin
        r_cnt <= 8'hFF;
        r_cnt_running <= 0;
      end else begin
        if(s_cnt_start)
        begin
          r_cnt <= s_cnt_target;
          r_cnt_running <= 1'b1;
        end
        else if(s_cnt_done)
        begin
          r_cnt <= 8'hFF;
          r_cnt_running <= 1'b0;
        end
        else if(r_cnt_running)
        begin
          r_cnt <= r_cnt - 1;
        end
      end
    end

    always_ff @(posedge clk_i or negedge rstn_i) 
    begin : ff_addr
      if(~rstn_i) begin
        r_state  <=  ST_IDLE;
        r_status <=  'h0;
        r_rsp   <=  'h0;
        r_cmd    <=  'h0;
      end else 
      begin
        if(clr_stat_i)
        begin
          r_state  <= ST_IDLE;
          r_status <= 'h0;
          r_rsp   <=  'h0;
          r_cmd    <=  'h0;
        end
        else
        begin 
          r_state <= s_state;
          if(s_status_sample)
            r_status <= s_status;
          if(cmd_start_i)
            r_cmd <= {cmd_op_i,cmd_arg_i};
          else if(s_shift_cmd)
            r_cmd <= {r_cmd[36:0],1'b0};
          if(s_shift_resp)
            r_rsp <= {r_rsp[134:0],sdcmd_i};
        end
      end
    end

    always_ff @(negedge clk_i or negedge rstn_i) begin : proc_sdcmd
      if(~rstn_i) begin
        r_sdcmd     <= 1'b1;
        r_sdcmd_oen <= 1'b1;
      end else begin
        r_sdcmd     <= s_sdcmd;
        r_sdcmd_oen <= s_sdcmd_oen;
      end
    end

endmodule

