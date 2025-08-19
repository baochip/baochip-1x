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
// Description: Module handling data transfer
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
//              Terrance Huang (terrance.huang@crossbar.com)
///////////////////////////////////////////////////////////////////////////////
module sdio_txrx_data
(
    input  logic         clk_i,
    input  logic         rstn_i,

    input  logic         clr_stat_i,

    output logic   [5:0] status_o,

    output logic         busy_o,

    output logic         sdclk_en_o,

    input  logic         data_start_i,
    input  logic   [9:0] data_block_size_i,
    input  logic   [7:0] data_block_num_i,
    input  logic         data_rwn_i,
    input  logic         data_quad_i,
    output logic         data_last_o,

    output logic         eot_o,

    input  logic  [31:0] in_data_if_data_i,
    input  logic         in_data_if_valid_i,
    output logic         in_data_if_ready_o,

    output logic  [31:0] out_data_if_data_o,
    output logic         out_data_if_valid_o,
    input  logic         out_data_if_ready_i,

    output logic   [3:0] sddata_o,
    input  logic   [3:0] sddata_i,
    output logic   [3:0] sddata_oen_o,

    input  logic  [19:0] data_timeout_i,
    output logic   [5:0] debug_stat_o
  );

    localparam STATUS_RSP_TIMEOUT   = 6'h1;

    localparam RSP_TYPE_NULL        = 3'b000;
    localparam RSP_TYPE_48_CRC      = 3'b001;
    localparam RSP_TYPE_48_NOCRC    = 3'b010;
    localparam RSP_TYPE_136         = 3'b011;
    localparam RSP_TYPE_48_BSY      = 3'b100;

    enum logic [4:0] {ST_IDLE,      // 0
                      ST_WAIT,      // 1
                      ST_TX_START,  // 2
                      ST_TX_STOP,   // 3
                      ST_TX_SHIFT,  // 4
                      ST_TX_CRC,    // 5
                      ST_TX_END,    // 6
                      ST_TX_CRCSTAT,// 7
                      ST_TX_BUSY,   // 8
                      ST_RX_START,  // 9
                      ST_RX_STOP,   // a
                      ST_RX_SHIFT,  // b
                      ST_RX_CRC     // c
    } s_state,r_state;

    logic [3:0] [15:0] s_crc;
    logic [3:0]        s_crc_block_en;
    logic [3:0]        s_crc_block_clr;
    logic [3:0]        s_crc_block_shift;
    logic [3:0]        s_crc_in;
    logic [3:0]        s_crc_out;
    logic              s_crc_en;
    logic              s_crc_clr;
    logic              s_crc_shift;
    logic              s_crc_intx;

    logic  [31:0] r_data;

    logic         s_eot;

    logic   [3:0] r_sddata;
    logic   [3:0] s_sddata;
    logic         s_sddata_oen;
    logic         r_sddata_oen;
    logic         s_shift_data;

    logic         s_cnt_start;
    logic         s_cnt_done;
    logic  [19:0] s_cnt_target; // for longer data timeout: 100MHz 10ms, 20bit
    logic  [19:0] r_cnt;
    logic         r_cnt_running;
    logic   [5:0] s_status;
    logic   [5:0] r_status;
    logic         s_status_sample;

    logic   [2:0] r_bit_cnt;
    logic   [2:0] s_bit_cnt_target;

    logic   [7:0] r_cnt_block;
    logic   [7:0] s_cnt_block;
    logic         s_cnt_block_upd;
    logic         s_cnt_block_done;

    logic         s_cnt_byte_evnt;
    logic         s_cnt_byte;
    logic         r_cnt_byte;

    logic   [1:0] r_byte_in_word;
    logic   [3:0] s_dataout;
    logic  [31:0] s_datain;
    logic         s_busy;

    logic         s_in_data_ready;
    logic         s_lastbitofword;

    logic       s_clk_en;
    logic       s_rx_en;
    logic       s_out_data_valid;

    assign s_crc_in = s_crc_intx ? sddata_i : s_sddata;

    assign s_crc_block_en[0] = s_crc_en;
    assign s_crc_block_en[3:1] = {3{data_quad_i & s_crc_en}};

    assign s_crc_block_clr[0] = s_crc_clr;
    assign s_crc_block_clr[3:1] = {3{data_quad_i & s_crc_clr}};

    assign s_crc_block_shift[0] = s_crc_shift;
    assign s_crc_block_shift[3:1] = {3{data_quad_i & s_crc_shift}};

    assign sddata_o = r_sddata;

    assign sddata_oen_o[0] = r_sddata_oen;  //philip,faye
    assign sddata_oen_o[3:1] = {3{data_quad_i ? r_sddata_oen : 1'b1}};//philip,faye

    assign data_last_o = s_busy & s_cnt_block_done;
    assign busy_o = s_busy;
    assign sdclk_en_o = s_clk_en;

    assign in_data_if_ready_o = s_in_data_ready;

    assign out_data_if_valid_o = s_out_data_valid;
    assign out_data_if_data_o = s_datain;

    assign eot_o = s_eot;
    assign status_o = r_status;

    assign debug_stat_o = {1'b0, r_state}; // 20240114, debug, internal stat machine

    genvar i;

    generate
      for(i = 0; i < 4; i++)
      begin
        sdio_crc16 i_data_crc (
          .clk_i         ( clk_i          ),
          .rstn_i        ( rstn_i         ),
          .crc16_o       ( s_crc[i]       ),
          .crc16_serial_o( s_crc_out[i]   ),
          .data_i        ( s_crc_in[i]    ),
          .shift_i       ( s_crc_block_shift[i] ),
          .clr_i         ( s_crc_block_clr[i]   ),
          .sample_i      ( s_crc_block_en[i]    )
        );
      end
    endgenerate

    // TODO:20240112, this part is too ugly. someone fix this!
    always_comb begin : proc_data_in
      s_datain = r_data;
      if(data_quad_i)
      begin
        case(r_byte_in_word)
          0:
            begin
              if(r_bit_cnt == 0)
                s_datain[7:4] = sddata_i;
              else
                s_datain[3:0] = sddata_i;
            end
          1:
            begin
              if(r_bit_cnt == 0)
                s_datain[15:12] = sddata_i;
              else
                s_datain[11:8] = sddata_i;
            end
          2:
            begin
              if(r_bit_cnt == 0)
                s_datain[23:20] = sddata_i;
              else
                s_datain[19:16] = sddata_i;
            end
          3:
            begin
              if(r_bit_cnt == 0)
                s_datain[31:28] = sddata_i;
              else
                s_datain[27:24] = sddata_i;
            end
        endcase
      end
      else
      begin
        s_datain[{r_byte_in_word, 3'd7 ^ r_bit_cnt}] = sddata_i[0];
/*
    TODO what the hell, Prof Tan Haoqiang?
        case(r_byte_in_word)
          0:
          begin //                -  actually subtraction
            s_datain[{2'b00, 3'd7 ^ r_bit_cnt}] = sddata_i[0];
          end
          1:
          begin
            s_datain[{2'b01, 3'd7 ^ r_bit_cnt}] = sddata_i[0];
          end
          2:
          begin
            s_datain[{2'b10, 3'd7 ^ r_bit_cnt}] = sddata_i[0];
          end
          3:
          begin
            s_datain[{2'b11, 3'd7 ^ r_bit_cnt}] = sddata_i[0];
          end
        endcase
*/
      end
    end

    always_comb begin : proc_data_out
      s_dataout = 4'b0;
      if(data_quad_i)
      begin
        case(r_byte_in_word)
          0:
            s_dataout = (r_bit_cnt == 0) ?   r_data[7:4] :   r_data[3:0];
          1:
            s_dataout = (r_bit_cnt == 0) ? r_data[15:12] :  r_data[11:8];
          2:
            s_dataout = (r_bit_cnt == 0) ? r_data[23:20] : r_data[19:16];
          3:
            s_dataout = (r_bit_cnt == 0) ? r_data[31:28] : r_data[27:24];
        endcase
      end
      else
      begin
        //                                          -  actually subtraction
        s_dataout[0] = r_data[{r_byte_in_word, 3'd7 ^ r_bit_cnt}];
      /*
        case(r_byte_in_word)
          0:
          begin //                             -  actually subtraction
            s_dataout[0] = r_data[{2'b00, 3'd7 ^ r_bit_cnt}];
          end
          1:
          begin
            s_dataout[0] = r_data[{2'b01, 3'd7 ^ r_bit_cnt}];
          end
          2:
          begin
            s_dataout[0] = r_data[{2'b10, 3'd7 ^ r_bit_cnt}];
          end
          3:
          begin
            s_dataout[0] = r_data[{2'b11, 3'd7 ^ r_bit_cnt}];
          end
        endcase
      */
      end
    end

    always_comb
    begin
      s_sddata        = 4'hf; //philip,faye
      s_sddata_oen    = 1'b1;
      s_state         = r_state;
      s_shift_data    = 1'b0;
      s_crc_shift     = 1'b0;
      s_crc_en        = 1'b0; // default 0 2024-06-04
      s_crc_clr       = 1'b0; // terrance 2023-09-17
      s_crc_intx      = 1'b0; //default CRC takes input from sddata out
      s_cnt_start     = 1'b0;
      s_cnt_target    = 20'h0; // t 20240113, default 0
      s_cnt_byte      = 1'b0;
      s_status        = 'h0;
      s_status_sample = 1'b0;
      s_busy          = 1'b1;
      s_clk_en        = 1'b1;
      s_rx_en         = 1'b0;
      s_eot           = 1'b0;
      s_cnt_block_upd = 1'b0;
      s_cnt_block     = r_cnt_block;

      s_in_data_ready = 1'b0;
      s_out_data_valid = 1'b0;
      // terrance 2023-09-17, added missing values
      case(r_state)
        ST_IDLE:
        begin
          s_busy = 1'b0;
          s_clk_en = 1'b0;
          s_crc_clr   = 1'b1;  // terrance 2023-09-17                                                                 <
          // s_crc_en     = 1'b0; // terrance 2023-09-17
          if(data_start_i)
          begin
            s_status_sample = 1'b1; // Clear previous status
            s_cnt_block_upd = 1'b1;
            s_cnt_block = data_block_num_i;
            // TODO why time out not set here?
            if(data_rwn_i) begin
              s_state = ST_RX_START;
              s_cnt_start = 1'b1;  // starts counting 20240925, NOTE 20240925, s_cnt_start updates `{r,s}_cnt_target`
              s_cnt_target = data_timeout_i; // TODO ?? 20240604
            end else begin
              // NOTE: there's no wait before writing first block
              s_state = ST_TX_START;
            end
          end
        end
        ST_TX_START:
        begin
          s_crc_clr   = 1'b1;  // terrance 2023-09-17
          // s_crc_en     = 1'b0; // terrance 2023-09-17
          s_sddata     = 4'b0;      //start bit
          s_sddata_oen = 1'b0; // outup enabled //philip,faye
          s_state = ST_TX_SHIFT;
          s_cnt_start = 1'b1;  // starts counting, NOTE 20240925, s_cnt_start updates `{r,s}_cnt_target`
          s_cnt_byte  = 1'b1;  // counting bytes not cycles
          s_cnt_target = {10'h0, data_block_size_i}; // shifts buffer size
          s_in_data_ready = 1'b1;
        end
        ST_TX_STOP: // never happens
        begin
            // TODO what to do ?
        end
        ST_TX_SHIFT:
        begin
          s_in_data_ready = s_lastbitofword;
          s_sddata = s_dataout;      // direction controller to SD periph
          s_sddata_oen = 1'b0; // outup enabled
          s_shift_data = 1'b1;
          s_crc_en = 1'b1;     // crc is calculated
          if(s_cnt_done)
          begin
            s_in_data_ready = 1'b0;
            s_state = ST_TX_CRC;
            s_cnt_start  = 1'b1;  // starts counting, NOTE 20240925, s_cnt_start updates `{r,s}_cnt_target`
            s_cnt_target = 20'd15; // shifts 16bits CRC out/channel
          end
        end
        ST_TX_CRC:
        begin
          s_sddata = s_crc_out;  // outputs CRC
          s_sddata_oen = 1'b0; // outup enabled
          s_crc_shift  = 1'b1; // shifts CRC out
          // s_crc_en     = 1'b0; // crc is not calculated but shifted
          if(s_cnt_done)
          begin
            s_state      = ST_TX_END;
          end
        end
        ST_TX_END:
        begin
          s_sddata = 4'hF;  // outputs CRC
          s_sddata_oen = 1'b0; // outup enabled
          s_crc_shift  = 1'b0; // shifts CRC out
          // s_crc_en     = 1'b0; // crc is not calculated but shifted
          s_state      = ST_TX_CRCSTAT;
          s_cnt_start  = 1'b1; // starts counting, NOTE 20240925, s_cnt_start updates `{r,s}_cnt_target`
          s_cnt_target = 20'd7; // waits 8 cycles
        end
        ST_TX_CRCSTAT:
        begin
          s_sddata_oen = 1'b1; // outup disabled
          if(s_cnt_done)
          begin
            s_cnt_start  = 1'b1;  // starts counting, NOTE 20240925, s_cnt_start updates `{r,s}_cnt_target`
            s_cnt_target = data_timeout_i; // t 20240110, this is wait for read?.  9'h1FF;// waits max 512 cycles
            s_state = ST_TX_BUSY;
          end
        end
        ST_TX_BUSY:
        begin
          s_sddata_oen = 1'b1; // outup disabled
          if(s_cnt_done) // this means timeout
          begin
            s_status = r_status | STATUS_RSP_TIMEOUT;
            s_status_sample = 1'b1;
            s_eot   = 1'b1;
            s_state = ST_IDLE;
          end
          else
          begin
            if(sddata_i[0])
            begin
              if(s_cnt_block_done)
              begin
                s_eot   = 1'b1;
                s_state = ST_IDLE;
              end
              else
              begin
                s_cnt_block_upd = 1'b1;
                s_cnt_block = r_cnt_block - 1;
                s_state = ST_TX_START;
              end
            end
          end
        end
        ST_RX_START:
        begin
          s_crc_clr   = 1'b1;  // terrance 2023-09-17
          if(!sddata_i[0])  // start bit
          begin
            s_cnt_start = 1'b1;  // starts counting, NOTE 20240925, s_cnt_start updates `{r,s}_cnt_target`
            s_cnt_byte  = 1'b1;  // counting bytes not cycles
            s_cnt_target = {10'h0, data_block_size_i}; // shifts buffer size
            s_state = ST_RX_SHIFT;
          end
          else if(s_cnt_done) // timeout
          begin
            s_status = r_status | STATUS_RSP_TIMEOUT;
            s_status_sample = 1'b1;
            s_eot   = 1'b1;
            s_state = ST_IDLE;
          end
        end
        ST_RX_STOP: // TODO never happens?
        begin
        end
        ST_RX_SHIFT:
        begin
          s_crc_clr   = 1'b0;  // terrance 2023-09-17
          s_rx_en = 1'b1;
          s_out_data_valid = s_lastbitofword;
          s_crc_en = 1'b1;      // crc is calculated
          s_crc_intx = 1'b1;    // crc input is from extern
          if(s_cnt_done)
          begin
              s_state = ST_RX_CRC;
              s_cnt_start = 1'b1;  // starts counting, NOTE 20240925, s_cnt_start updates `{r,s}_cnt_target`
              s_cnt_target = 20'd15;// shifts 16 bits
          end
        end
        ST_RX_CRC:
        begin
          s_out_data_valid = s_lastbitofword;
          s_crc_en = 1'b1;      // crc is calculated
          s_crc_intx = 1'b1;    // crc input is from extern
          if(s_cnt_done)
          begin
            if(s_cnt_block_done)
            begin
              s_eot   = 1'b1;
              s_state = ST_IDLE;
            end
            else
            begin
              s_cnt_block_upd = 1'b1;
              s_cnt_block = r_cnt_block - 1;
              s_cnt_start = 1'b1;  // starts counting, NOTE 20240925, s_cnt_start updates `{r,s}_cnt_target`
              s_cnt_target = data_timeout_i; // TODO ? added 20240923
              s_state = ST_RX_START;
            end
          end
        end
        ST_WAIT: // TODO 20240923 never happens?
        begin
          s_crc_clr   = 1'b1;  // terrance 20230917
          if(s_cnt_done)
          begin
            s_eot   = 1'b1;
            s_state = ST_IDLE;
          end
        end
        default:
        begin
        end
      endcase
    end

    assign s_cnt_done = r_cnt_byte ? ((r_cnt == 0) && s_cnt_byte_evnt) : (r_cnt == 0);

    initial begin
        //shall print %t with scaled in ns (-9), with 2 precision digits, and would print the " ns" string
        $timeformat(-9, 2, " ns", 20);
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_cnt
      if(~rstn_i) begin
        r_cnt <= 20'd125_000; // TODO 20240923, default, 25ms @ 5MHz
        r_cnt_running <= 0;
        r_cnt_byte    <= 0;
        r_cnt_block   <= 0;
        r_byte_in_word <= 0;
      end else begin
        if(s_cnt_block_upd)
        begin
          r_cnt_block <=  s_cnt_block;
        end

        if(s_cnt_start)
        begin
          r_cnt <= s_cnt_target;
          // $display("%t start, reload r_cnt %d", $time, s_cnt_target);
          r_cnt_running <= 1'b1;
          r_byte_in_word <= 0;
          r_cnt_byte <= s_cnt_byte;
        end
        else if(s_cnt_done)
        begin
          // r_cnt <= 9'h1FF; // TODO 20240112, should NEVER load 1ff, 20240110, what's this
          r_cnt <= s_cnt_target; // TODO 20240112, should NEVER load 1ff, 20240110, what's this
          // $display("%t done, reload r_cnt %d", $time, s_cnt_target);
 
          r_cnt_running <= 1'b0;
          r_cnt_byte    <= 1'b0;
          r_byte_in_word <= 0;
        end
        else if(r_cnt_running && (!r_cnt_byte || s_cnt_byte_evnt))
        begin
          r_cnt <= r_cnt - 1;
          if(r_cnt_byte)
            r_byte_in_word <= r_byte_in_word + 1;
        end
      end
   end

    assign s_lastbitofword = s_cnt_byte_evnt & (r_byte_in_word == 2'b11);
    assign s_cnt_block_done = (r_cnt_block == 0);

    //bit counter used to count the TX/RX bits(each byte)
    //if in quad mode only 0..1 quad bits
    //if in single count 0..7
    assign s_bit_cnt_target = data_quad_i ? 3'h1 : 3'h7;
    assign s_cnt_byte_evnt  = (r_bit_cnt == s_bit_cnt_target);
    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_bit_cnt
      if(~rstn_i) begin
        r_bit_cnt <= 3'h0;
      end else
      begin
        if(r_cnt_byte)
        begin
          if (s_cnt_byte_evnt)
            r_bit_cnt <= 3'h0;
          else
            r_bit_cnt <= r_bit_cnt + 1;;
        end
      end
    end


    always_ff @(posedge clk_i or negedge rstn_i)
    begin
      if(~rstn_i) begin
        r_state  <=  ST_IDLE;
        r_status <=  'h0;
        r_data   <=  'h0;
      end else
      begin
        if(clr_stat_i)
        begin
          r_state  <= ST_IDLE;
          r_status <= 'h0;
          r_data   <=  'h0;
        end
        else
        begin
          r_state  <= s_state;
          if(s_status_sample)
            r_status <= s_status;
          if(s_in_data_ready)
            r_data <= in_data_if_data_i;
          else if(s_rx_en)
            r_data <= s_datain;
        end
      end
    end

    always_ff @(negedge clk_i or negedge rstn_i) begin : proc_sddata
      if(~rstn_i) begin
        r_sddata     <= 4'hf; // 20240112, idle should be high, even when not OE
      end else begin
        r_sddata     <= s_sddata;
      end
    end


    always_ff @(negedge clk_i or negedge rstn_i) begin : proc_sddataoen
      if(~rstn_i) begin
        r_sddata_oen     <= 'h1;
      end else begin
        r_sddata_oen     <= s_sddata_oen;
      end
    end

endmodule

