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
// Description: Filter arithmetic unit
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
`define MODE0     0   // AxB
`define MODE1     1   // AxB+reg
`define MODE2     2   // accAxB
`define MODE3     3   // AxA
`define MODE4     4   // AxA+B
`define MODE5     5   // AxA-B
`define MODE6     6   // accAxA
`define MODE7     7   // AxA+reg
`define MODE8     8   // Axreg
`define MODE9     9   // Axreg+B
`define MODE10    10  // Axreg-B
`define MODE11    11  // Axreg+reg
`define MODE12    12  // accAxreg
`define MODE13    13  // A+B
`define MODE14    14  // A-B
`define MODE15    15  // A+reg


module udma_filter_au
#(
  parameter DATA_WIDTH     = 32
)   (
  input  logic                  clk_i,
  input  logic                  resetn_i,

  input  logic                  cfg_use_signed_i,
  input  logic                  cfg_bypass_i,
  input  logic            [3:0] cfg_mode_i,
  input  logic            [4:0] cfg_shift_i,
  input  logic           [31:0] cfg_reg0_i,
  input  logic           [31:0] cfg_reg1_i,

  input  logic                  cmd_start_i,

  input  logic [DATA_WIDTH-1:0] operanda_data_i,
  input  logic            [1:0] operanda_datasize_i,
  input  logic                  operanda_valid_i,
  input  logic                  operanda_sof_i,
  input  logic                  operanda_eof_i,
  output logic                  operanda_ready_o,

  input  logic [DATA_WIDTH-1:0] operandb_data_i,
  input  logic            [1:0] operandb_datasize_i,
  input  logic                  operandb_valid_i,
  output logic                  operandb_ready_o,

  output logic [DATA_WIDTH-1:0] output_data_o,
  output logic            [1:0] output_datasize_o,
  output logic                  output_valid_o,
  input  logic                  output_ready_i

  );

    logic [65:0] s_mac;
    logic [31:0] s_sum;
    logic [31:0] s_opa;
    logic [31:0] s_opb;
    logic [31:0] r_accumulator;
    logic [31:0] s_outpostshift;

    logic [31:0] r_operanda;
    logic [31:0] r_operandb;

    logic s_en_opb;
    logic s_mulb_opa;
    logic s_mulb_opb;
    logic s_mulb_reg;
    logic s_sum_acc;
    logic s_sum_reg;
    logic s_sum_opb;
    logic s_sum_inv;

    logic r_sample_dly;
    logic r_sample_out;

    logic s_sample_opa;
    logic s_sample_opb;

    logic [DATA_WIDTH-1:0] s_in_opa;
    logic [DATA_WIDTH-1:0] s_in_opb;

    logic r_sof;
    logic r_eof;
    logic r_accoutvalid;

    always_comb 
    begin
      s_in_opa = operanda_data_i;
      case(operanda_datasize_i)
        2'b00:
          s_in_opa = $signed({operanda_data_i[7] & cfg_use_signed_i,operanda_data_i[7:0]});
        2'b01:
          s_in_opa = $signed({operanda_data_i[15] & cfg_use_signed_i,operanda_data_i[15:0]});
      endcase // operanda_datasize_i
    end

    always_comb 
    begin
      s_in_opb = operandb_data_i;
      case(operandb_datasize_i)
        2'b00:
          s_in_opb = $signed({operandb_data_i[7] & cfg_use_signed_i,operandb_data_i[7:0]});
        2'b01:
          s_in_opb = $signed({operandb_data_i[15] & cfg_use_signed_i,operandb_data_i[15:0]});
      endcase // operanda_datasize_i
    end

    assign s_outpostshift = $signed(r_accumulator) >>> cfg_shift_i;
    assign output_data_o  = s_outpostshift[31:0];
    assign output_valid_o = s_sum_acc ? r_accoutvalid : r_sample_out;
    assign output_datasize_o = operanda_datasize_i;

    assign s_mac = $signed(s_opa)*$signed(s_opb) + $signed({s_sum[31] & cfg_use_signed_i,s_sum});

    assign s_sample_opa = output_ready_i & (operanda_valid_i & (cfg_bypass_i | !s_en_opb | (s_en_opb & operandb_valid_i)));
    assign s_sample_opb = output_ready_i & (operanda_valid_i &                             (s_en_opb & operandb_valid_i));

    assign operanda_ready_o = s_sample_opa;
    assign operandb_ready_o = s_sample_opb;

    assign s_opa = r_operanda;

    always_comb begin : proc_opb_mux
      s_opb = 32'h1;
      if (cfg_bypass_i)
        s_opb = 32'h1;
      else if(s_mulb_opb)
        s_opb = r_operandb;
      else if(s_mulb_reg)
        s_opb = cfg_reg1_i;
      else if(s_mulb_opa)
        s_opb = r_operanda;  
    end

    always_comb begin : proc_sum_mux
      s_sum = 0;
      if (cfg_bypass_i)
        s_sum = 32'h0;
      else if(s_sum_opb)
        s_sum = r_operandb;
      else if(s_sum_reg)
        s_sum = cfg_reg0_i;
      else if(s_sum_acc & !r_sof)
        s_sum = r_accumulator;  
    end

    always_comb 
    begin
      s_en_opb   = 1'b1;
      s_mulb_opa = 1'b0;
      s_mulb_opb = 1'b0;
      s_mulb_reg = 1'b0;
      s_sum_acc  = 1'b0;
      s_sum_reg  = 1'b0;
      s_sum_opb  = 1'b0;
      s_sum_inv  = 1'b0;
      case(cfg_mode_i)
        `MODE0: // AxB
        begin
          s_mulb_opb = 1'b1;
        end
        `MODE1: // AxB+reg
        begin
          s_mulb_opb = 1'b1;
          s_sum_reg  = 1'b1;
        end
        `MODE2: // accAxB
        begin
          s_mulb_opb = 1'b1;
          s_sum_acc  = 1'b1;
        end
        `MODE3:  // AxA
        begin
          s_en_opb = 1'b0;
          s_mulb_opa = 1'b1;
        end
        `MODE4: // AxA+B
        begin
          s_mulb_opa = 1'b1;
          s_sum_opb  = 1'b1;
        end
        `MODE5: // AxA-B
        begin
          s_mulb_opa = 1'b1;
          s_sum_opb  = 1'b1;
          s_sum_inv  = 1'b1;
        end
        `MODE6: // accAxA
        begin
          s_en_opb = 1'b0;
          s_mulb_opa = 1'b1;
          s_sum_acc  = 1'b1;
        end
        `MODE7: // AxA+reg
        begin
          s_en_opb = 1'b0;
          s_mulb_opa = 1'b1;
          s_sum_reg  = 1'b1;
        end
        `MODE8: // Axreg
        begin
          s_en_opb = 1'b0;
          s_mulb_reg = 1'b1;
        end
        `MODE9: // Axreg+B
        begin
          s_mulb_reg = 1'b1;
          s_sum_opb  = 1'b1;
        end
        `MODE10: // Axreg-B
        begin
          s_mulb_reg = 1'b1;
          s_sum_opb  = 1'b1;
          s_sum_inv  = 1'b1;
        end
        `MODE11: // Axreg+reg
        begin
          s_en_opb = 1'b0;
          s_mulb_reg = 1'b1;
          s_sum_reg  = 1'b1;
        end
        `MODE12: // accAxreg
        begin
          s_en_opb = 1'b0;
          s_mulb_reg = 1'b1;
          s_sum_acc  = 1'b1;
        end
        `MODE13: // A+B
        begin
          s_sum_opb  = 1'b1;
        end
        `MODE14: // A-B
        begin
          s_sum_opb  = 1'b1;
          s_sum_inv  = 1'b1;
        end
        `MODE15: // A+reg
        begin
          s_en_opb = 1'b0;
          s_sum_reg  = 1'b1;
        end
      endcase // cfg_mode_i
    end

    always_ff @(posedge clk_i or negedge resetn_i) 
    begin
      if(~resetn_i) 
      begin
        r_accumulator  <= 0;
        r_sample_dly   <= 1'b0;
        r_sample_out   <= 1'b0;
        r_operanda     <= 0;
        r_operandb     <= 0;
        r_sof          <= 1'b0;
        r_eof          <= 1'b0;
        r_accoutvalid  <= 0;
      end 
      else 
      begin
        if (cmd_start_i)
        begin
          r_sample_dly  <= 1'b0;
          r_sample_out  <= 1'b0;
          r_accoutvalid <= 1'b0;
          r_sof         <= 1'b0;
          r_eof         <= 1'b0;
        end
        else if(output_ready_i)
        begin
          r_sample_dly  <= s_sample_opa;
          r_sample_out  <= r_sample_dly;
          r_accoutvalid <= r_eof;
          r_sof         <= operanda_sof_i & s_sample_opa;
          r_eof         <= operanda_eof_i & s_sample_opa;
          if(r_sample_dly)
            r_accumulator <= s_mac[31:0];
          if(s_sample_opa)
          begin
            r_operanda    <= s_in_opa;
          end
          if(s_sample_opb)
            r_operandb    <= s_in_opb;
        end
      end
    end

endmodule

