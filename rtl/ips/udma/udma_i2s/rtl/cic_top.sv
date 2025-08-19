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
// Description: Top level of CIC filter
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
module varcic #( 


  //design parameters
  parameter STAGES = 5,
  //computed parameters
  //ACC_WIDTH = IN_WIDTH + Ceil(STAGES * Log2(decimation factor))
  parameter ACC_WIDTH = 51
) (

  input  logic             clk_i,
  input  logic             rstn_i,

  input  logic             cfg_en_i,
  input  logic  [1:0]      cfg_ch_num_i,

  input  logic  [9:0]      cfg_decimation_i,
  input  logic  [2:0]      cfg_shift_i,

  input  logic             data_i,
  input  logic             data_valid_i,

  output logic [15:0]      data_o,
  output logic             data_valid_o

);

logic [ACC_WIDTH-1:0] integrator_data [0:STAGES];
logic [ACC_WIDTH-1:0] comb_data [0:STAGES];

//------------------------------------------------------------------------------
//                               control
//------------------------------------------------------------------------------
logic [9:0] r_sample_nr;
logic [1:0] r_ch_nr;
logic       r_en;
logic       s_clr;

assign s_clr = cfg_en_i & !r_en;

always_ff @(posedge clk_i or negedge rstn_i)
begin
  if(~rstn_i)
    r_en <= 'h0;
  else
    r_en <= cfg_en_i;
end

always_ff @(posedge clk_i or negedge rstn_i)
begin
  if(~rstn_i)
  begin
    r_sample_nr  <=  'h0;
    r_ch_nr      <=  'h0;
  end
  else
  begin
    if (s_clr)
    begin
      r_sample_nr  <= 0;
      r_ch_nr      <= 0;
    end
    else if (data_valid_i)
    begin
      if(r_ch_nr == cfg_ch_num_i)
      begin
        r_ch_nr <= 'h0;
        if (r_sample_nr == cfg_decimation_i)
          r_sample_nr  <= 0;
        else
          r_sample_nr  <= r_sample_nr + 1;
      end
      else
        r_ch_nr <= r_ch_nr + 1;
      end
  end
end

logic  s_out_data_valid;
assign s_out_data_valid = data_valid_i & (r_sample_nr == cfg_decimation_i);
assign data_valid_o     = s_out_data_valid;


//------------------------------------------------------------------------------
//                                stages
//------------------------------------------------------------------------------
assign integrator_data[0] = data_i ? 'h1 : {ACC_WIDTH{1'b1}};
assign comb_data[0] = integrator_data[STAGES];

genvar i;
generate
  for (i=0; i<STAGES; i=i+1)
    begin : cic_stages

    cic_integrator #(ACC_WIDTH) cic_integrator_inst(
      .clk_i(clk_i),
      .rstn_i(rstn_i),
      .clr_i(s_clr),
      .sel_i(r_ch_nr),
      .en_i(data_valid_i),
      .data_i(integrator_data[i]),
      .data_o(integrator_data[i+1])
      );

    cic_comb #(ACC_WIDTH) cic_comb_inst(
      .clk_i(clk_i),
      .rstn_i(rstn_i),
      .clr_i(s_clr),
      .sel_i(r_ch_nr),
      .en_i(s_out_data_valid),
      .data_i(comb_data[i]),
      .data_o(comb_data[i+1])
      );
    end
endgenerate

always_comb begin : proc_data_o
  data_o = 'h0;
  case(cfg_shift_i)
    0:
      data_o = comb_data[STAGES][ACC_WIDTH-1:ACC_WIDTH-16];
    1:
      data_o = comb_data[STAGES][ACC_WIDTH-6:ACC_WIDTH-21];
    2:
      data_o = comb_data[STAGES][ACC_WIDTH-11:ACC_WIDTH-26];
    3:
      data_o = comb_data[STAGES][ACC_WIDTH-16:ACC_WIDTH-31];
    4:
      data_o = comb_data[STAGES][ACC_WIDTH-21:ACC_WIDTH-36];
    5:
      data_o = comb_data[STAGES][ACC_WIDTH-26:ACC_WIDTH-41];
    6:
      data_o = comb_data[STAGES][ACC_WIDTH-31:ACC_WIDTH-46];
    7:
      data_o = comb_data[STAGES][ACC_WIDTH-36:ACC_WIDTH-51];
    default:
      data_o = comb_data[STAGES][ACC_WIDTH-1:ACC_WIDTH-16];
    endcase // cfg_shift_i
end

//------------------------------------------------------------------------------
//                            output rounding
//------------------------------------------------------------------------------
// localparam MSB0 = ACC_WIDTH - 1;         //63
// localparam LSB0 = ACC_WIDTH - OUT_WIDTH; //41

// localparam MSB1 = MSB0 - STAGES;         //58
// localparam LSB1 = LSB0 - STAGES;         //36

// localparam MSB2 = MSB1 - STAGES;         //53
// localparam LSB2 = LSB1 - STAGES;         //31


// always @(posedge clock)
//   case (extra_decimation)
//     0: out_data <= comb_data[STAGES][MSB0:LSB0] + comb_data[STAGES][LSB0-1];
//     1: out_data <= comb_data[STAGES][MSB1:LSB1] + comb_data[STAGES][LSB1-1];
//     2: out_data <= comb_data[STAGES][MSB2:LSB2] + comb_data[STAGES][LSB2-1];
//   endcase



endmodule
