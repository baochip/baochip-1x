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
// Description: Top level for TX/RX modules instantiating cmd and data modules
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
module sdio_txrx
(
    input  logic         clk_i,
    input  logic         rstn_i,

    input  logic         clr_stat_i,

    input  logic         cmd_start_i,
    input  logic   [5:0] cmd_op_i,
    input  logic  [31:0] cmd_arg_i,
    input  logic   [2:0] cmd_rsp_type_i,
    input  logic   [1:0] cmd_stopopt,

    output logic [127:0] rsp_data_o,

    input  logic         data_en_i,
    input  logic         data_rwn_i,
    input  logic         data_quad_i,
    input  logic   [9:0] data_block_size_i,
    input  logic   [7:0] data_block_num_i,

    output logic         eot_o,

    output logic  [15:0] status_o,

    input  logic  [31:0] in_data_if_data_i,
    input  logic         in_data_if_valid_i,
    output logic         in_data_if_ready_o,

    output logic  [31:0] out_data_if_data_o,
    output logic         out_data_if_valid_o,
    input  logic         out_data_if_ready_i,

    output logic         sdclk_o,

    input  logic         sdcmd_i,
    output logic         sdcmd_o,
    output logic         sdcmd_oen_o,

    output logic   [3:0] sddata_o,
    input  logic   [3:0] sddata_i,
    output logic   [3:0] sddata_oen_o,
    input  logic  [19:0] data_timeout_i,
    output logic  [11:0] debug_stat_o
  );

    logic s_start_write;
    logic s_start_read;

    logic        s_cmd_eot;
    logic        s_cmd_clk_en;
    logic        s_cmd_start;
    logic  [5:0] s_cmd_op;
    logic [31:0] s_cmd_arg;
    logic  [2:0] s_cmd_rsp_type;
    logic  [5:0] s_cmd_status;

    logic        s_stopcmd_start;
    logic  [5:0] s_stopcmd_op;
    logic [31:0] s_stopcmd_arg;
    logic  [2:0] s_stopcmd_rsp_type;

    logic s_cmd_mux;
    logic s_eot;
    logic s_clear_eot;

    logic [5:0] s_data_status;
    logic       s_data_start;
    logic       s_data_eot;
    logic       s_data_last;
    logic       s_data_clk_en;

    logic       r_cmd_eot;
    logic       r_data_eot;

    logic       s_sample_eot;
    logic       s_sample_sb;

    logic       s_single_block;
    logic       r_single_block;

    logic       s_clk_en;

    logic       s_busy;
    logic [5:0] stat_cmd, stat_data;

    enum logic [1:0] {ST_CMD_ONLY,
                      ST_WAIT_LAST,
                      ST_WAIT_EOT
                      } s_state,r_state;

  assign s_stopcmd_op       =  6'd12; //STOP_CMD is cmd 12
  assign s_stopcmd_arg      = 32'h0;  //no argument
  assign s_stopcmd_rsp_type =  3'h1;  //resp is R1

  assign s_data_start = data_en_i & ((data_rwn_i & s_start_read) | (~data_rwn_i & s_start_write));

  assign s_cmd_start    = s_cmd_mux ? s_stopcmd_start    : cmd_start_i   ;
  assign s_cmd_op       = s_cmd_mux ? s_stopcmd_op       : cmd_op_i      ;
  assign s_cmd_arg      = s_cmd_mux ? s_stopcmd_arg      : cmd_arg_i     ;
  assign s_cmd_rsp_type = s_cmd_mux ? s_stopcmd_rsp_type : cmd_rsp_type_i;

  assign eot_o          = s_cmd_mux ? s_eot : s_cmd_eot;

  assign s_eot = r_cmd_eot & r_data_eot;


  assign debug_stat_o = {stat_cmd, stat_data};

  always_comb begin : proc_sm
    s_cmd_mux      = 1'b0;
    s_stopcmd_start = 1'b0;
    s_clear_eot     = 1'b0;
    s_sample_eot    = 1'b0;
    s_state         = r_state;
    s_sample_sb     = 1'b0;
    s_single_block  = 1'b0;
    case(r_state)
      ST_CMD_ONLY:
      begin
        if(cmd_start_i && data_en_i && (data_block_num_i == 0))
        begin
          s_state = ST_WAIT_EOT;
          s_single_block = 1'b1;
          s_sample_sb = 1'b1;
        end
        else if(cmd_start_i && data_en_i)
        begin
          s_state = ST_WAIT_LAST;
          s_single_block = 1'b0;
          s_sample_sb = 1'b1;
        end
      end
      ST_WAIT_LAST:
      begin
        s_cmd_mux = cmd_stopopt[0];
        if(s_data_last)
        begin
          s_stopcmd_start = 1'b1;
          s_state = ST_WAIT_EOT;
        end
      end
      ST_WAIT_EOT:
      begin
        s_cmd_mux = cmd_stopopt[1];
        s_sample_eot = 1'b1;
        if((r_single_block || r_cmd_eot) && r_data_eot)
        begin
          s_clear_eot = 1'b1;
          s_state = ST_CMD_ONLY;
        end
      end
    endcase // r_state
  end

  always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_eot
    if(~rstn_i) begin
      r_cmd_eot  <= 0;
      r_data_eot <= 0;
      r_single_block <= 0;
      r_state <= ST_CMD_ONLY;
    end else begin
      r_state <= s_state;
      if(s_clear_eot)
      begin
        r_cmd_eot  <= 0;
        r_data_eot <= 0;
        r_single_block <= 0;
      end
      else
      begin
        if (s_sample_eot)
        begin
          if(s_cmd_eot)
            r_cmd_eot  <= 1'b1;
          if(s_data_eot)
            r_data_eot <= 1'b1;
        end
        if(s_sample_sb)
          r_single_block <= s_single_block;
      end
    end
  end

  assign s_clk_en = s_cmd_clk_en | s_data_clk_en;

  pulp_clock_gating i_clk_gate_sdio
  (
    .clk_i(clk_i),
    .en_i(s_clk_en),
    .test_en_i(1'b0),
    .clk_o(sdclk_o)
  );

  sdio_txrx_cmd i_cmd_if (
    .clk_i         ( clk_i          ),
    .rstn_i        ( rstn_i         ),
    .busy_i        ( s_busy         ),
    .start_write_o ( s_start_write  ),
    .start_read_o  ( s_start_read   ),
    .clr_stat_i    ( clr_stat_i     ),
    .cmd_start_i   ( s_cmd_start    ),
    .cmd_op_i      ( s_cmd_op       ),
    .cmd_arg_i     ( s_cmd_arg      ),
    .cmd_rsp_type_i( s_cmd_rsp_type ),
    .rsp_data_o    ( rsp_data_o     ),
    .eot_o         ( s_cmd_eot      ),
    .status_o      ( s_cmd_status   ),
    .sdclk_en_o    ( s_cmd_clk_en   ),
    .sdcmd_o       ( sdcmd_o        ),
    .sdcmd_i       ( sdcmd_i        ),
    .sdcmd_oen_o   ( sdcmd_oen_o    ),
    .debug_stat_o  ( stat_cmd       )
  );


  sdio_txrx_data i_data_if (
    .clk_i              ( clk_i               ),
    .rstn_i             ( rstn_i              ),
    .clr_stat_i         ( clr_stat_i          ),
    .status_o           ( s_data_status       ),
    .busy_o             ( s_busy              ),
    .sdclk_en_o         ( s_data_clk_en       ),
    .data_start_i       ( s_data_start        ),
    .data_block_size_i  ( data_block_size_i   ),
    .data_block_num_i   ( data_block_num_i    ),
    .data_rwn_i         ( data_rwn_i          ),
    .data_quad_i        ( data_quad_i         ),
    .data_last_o        ( s_data_last         ),
    .eot_o              ( s_data_eot          ),
    .in_data_if_data_i  ( in_data_if_data_i   ),
    .in_data_if_valid_i ( in_data_if_valid_i  ),
    .in_data_if_ready_o ( in_data_if_ready_o  ),
    .out_data_if_data_o ( out_data_if_data_o  ),
    .out_data_if_valid_o( out_data_if_valid_o ),
    .out_data_if_ready_i( out_data_if_ready_i ),
    .sddata_o           ( sddata_o            ),
    .sddata_i           ( sddata_i            ),
    .sddata_oen_o       ( sddata_oen_o        ),
    .data_timeout_i     ( data_timeout_i      ),
    .debug_stat_o       ( stat_data           )
  );

  assign status_o = {2'b00,s_data_status,2'b00,s_cmd_status};

endmodule

