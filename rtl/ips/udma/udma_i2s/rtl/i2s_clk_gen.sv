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
// Description: Simple clock divider for I2S block
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module i2s_clk_gen
(
    input  logic         clk_i,
    input  logic         rstn_i,

    input  logic         test_mode_i,

    output logic         sck_o,

    input  logic         cfg_clk_en_i,
    output logic         cfg_clk_en_o,
    input  logic  [15:0] cfg_div_i
);

    logic  [15:0] r_counter;
    logic         r_clk;
    logic  [15:0] r_sampled_config;
    logic         r_clock_en;

    assign cfg_clk_en_o = r_clock_en;

    //Generate the internal clock signal
    always_ff  @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_counter  <= 'h0;
            r_sampled_config <= 'h0;
            r_clk      <= 1'b0;
            r_clock_en <= 1'b0;
        end
        else
        begin
            if (cfg_clk_en_i && !r_clock_en)
            begin
                r_clock_en       <= 1'b1;
                r_sampled_config <= cfg_div_i;
            end
            else if(!cfg_clk_en_i)
            begin
                if(!r_clk)
                begin
                    r_counter <= 'h0;
                    r_clock_en <= 1'b0;
                end
                else 
                begin
                    if(r_counter == r_sampled_config)
                    begin
                        r_sampled_config <= cfg_div_i;
                        r_counter <= 'h0;
                        r_clk     <= 'h0;
                    end
                    else
                    begin
                        r_counter <= r_counter + 1;
                    end
                end
            end
            else
            begin
                if(r_counter == r_sampled_config)
                begin
                    r_counter <= 'h0;
                    r_sampled_config <= cfg_div_i;
                    r_clk     <= ~r_clk;
                end
                else
                begin
                    r_counter <= r_counter + 1;
                end
            end
        end
    end

`ifndef PULP_FPGA_EMUL
 `ifdef PULP_DFT
      pulp_clock_mux2 i_clock_mux_dft (
              .clk0_i(r_clk),
              .clk1_i(clk_i),
              .clk_sel_i(test_mode_i),
              .clk_o(sck_o)
      );
 `else
   assign sck_o = r_clk;
 `endif
`else
   assign sck_o = r_clk;
`endif

endmodule

