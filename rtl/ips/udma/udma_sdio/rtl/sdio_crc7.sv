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
// Description: CRC7 module
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
module sdio_crc7
(
    input  logic	                       clk_i,
    input  logic                         rstn_i,
    output logic                   [6:0] crc7_o,
    output logic                         crc7_serial_o,
    input  logic                         data_i,
    input  logic                         shift_i,
    input  logic                         clr_i,
    input  logic                         sample_i
  );

    logic [6:0] r_crc;
    logic [6:0] s_crc;

    assign crc7_o = r_crc;
    assign crc7_serial_o = r_crc[6];

    always_comb
    begin
      s_crc = r_crc;
      if(sample_i)
      begin
        s_crc[0] = data_i ^ r_crc[6];
        s_crc[1] = r_crc[0];
        s_crc[2] = r_crc[1];
        s_crc[3] = r_crc[2] ^ s_crc[0];
        s_crc[4] = r_crc[3];
        s_crc[5] = r_crc[4];
        s_crc[6] = r_crc[5];
      end
      else if(clr_i)
        s_crc = 7'h0;
      else if(shift_i)
        s_crc = {r_crc[5:0],1'b0};
    end


    always_ff @(posedge clk_i or negedge rstn_i) 
    begin : ff_addr
      if(~rstn_i) begin
        r_crc  <=  '0;
      end else 
      begin
        if(sample_i || clr_i || shift_i)
          r_crc <= s_crc;
      end
    end

endmodule

