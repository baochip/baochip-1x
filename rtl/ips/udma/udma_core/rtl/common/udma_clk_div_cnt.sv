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
// Description: Counter used in integer clock divider
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_clk_div_cnt
  (
   input  logic       clk_i,
   input  logic       rstn_i,
   input  logic       en_i,
   input  logic [7:0] clk_div_i,
   input  logic       clk_div_valid_i,
   output logic       clk_o
   );
   
   logic [7:0] 	      r_counter;
   logic [7:0] 	      r_target;    
   
   always_ff @(posedge clk_i, negedge rstn_i)
     begin
        if (~rstn_i)
          begin
             r_counter  <=  'h0;
             r_target   <=  'h0;
             clk_o      <= 1'b0;
          end
        else
          begin
             if (clk_div_valid_i)
               begin
                  r_target  <= clk_div_i;
                  r_counter <=  'h0;
                  clk_o     <= 1'b0;
               end
             else
               begin
                  if(en_i)
                    if (r_counter == (r_target - 1))
                      begin
                         clk_o <= ~clk_o;
                         r_counter <= 'h0;
                      end
		    else
		      begin
			 r_counter <= r_counter + 1;		       
		      end
               end
	   
          end
     end

endmodule
