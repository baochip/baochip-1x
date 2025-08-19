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
// Description: Round robin arbiter block for uDMA channels
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_arbiter
  #(
    parameter N=8,
    parameter S=3
    )
  (
    input  logic            clk_i, 
    input  logic            rstn_i, 
    input  logic    [N-1:0] req_i, 
    output logic    [N-1:0] grant_o,
    input  logic            grant_ack_i,
    output logic            anyGrant_o
  );

  // internal pointers
  reg [N-1:0] r_priority; // one-hot priority vector
  
  
  // Outputs of combinational logic - real wires - declared as regs for use in a alway block
  // Better to change to wires and use generate statements in the future
  
  reg [N-1:0]  g[S:0]; // S levels of priority generate
  reg [N-1:0]  p[S-1:0]; // S-1 levels of priority propagate

  // internal synonym wires of true outputs anyGrant and grant 
  wire anyGnt;
  wire [N-1:0] gnt;

  assign anyGrant_o = anyGnt;
  assign grant_o = gnt;
  
  


/////////////////////////////////////////////////
// Parallel prefix arbitration phase
/////////////////////////////////////////////////
  integer i,j;

  // arbitration phase
  always_comb //@(req_i or r_priority)
    begin
      // transfer request vector to the first propagate positions
      p[0] = {~req_i[N-2:0], ~req_i[N-1]};

      // transfer priority vector to the first generate positions
      g[0] = r_priority;
      
      // first log_2n - 1 prefix levels
      for (i=1; i < S; i = i + 1) begin
        for (j = 0; j < N ; j = j + 1) begin
          if (j-2**(i-1) < 0) begin
            g[i][j] = g[i-1][j] | (p[i-1][j] & g[i-1][N+j-2**(i-1)]);           
            p[i][j] = p[i-1][j] & p[i-1][N+j-2**(i-1)];
          end else begin
            g[i][j] = g[i-1][j] | (p[i-1][j] & g[i-1][j-2**(i-1)]);           
            p[i][j] = p[i-1][j] & p[i-1][j-2**(i-1)];
          end            
        end
      end  
      
      // last prefix level
      for (j = 0; j < N; j = j + 1) begin
        if (j-2**(S-1) < 0) 
          g[S][j] = g[S-1][j] | (p[S-1][j] & g[S-1][N+j-2**(S-1)]);           
        else
          g[S][j] = g[S-1][j] | (p[S-1][j] & g[S-1][j-2**(S-1)]);           
      end
    end      
  
  // any grant generation at last prefix level
  assign anyGnt = ~(p[S-1][N-1] & p[S-1][N/2-1]);
  
  // output stage logic
  assign gnt  = req_i & g[S];  


/////////////////////////////////////////////////
// Pointer update logic
// ------------------------
// Version 1 - blind round robin CHOISE = 0
// Priority visits each input in a circural manner irrespective the granted output
// ------------------------
// Version 2 - true round robin CHOISE = 1
// Priority moves next to the granted output
// ------------------------
// Priority moves only when a grant was given, i.e., at least one active request
//////////////////////////////////////////////////

  always@(posedge clk_i or negedge rstn_i)
    begin
      if (rstn_i == 1'b0) begin
        r_priority <= 1;
      end else begin
        // update pointers only if at leas one match exists and if we received an ack from the controller
        if (anyGnt && grant_ack_i) begin  
            // shift left one-hot grant vector
            r_priority[N-1:1] <= gnt[N-2:0];
            r_priority[0]     <= gnt[N-1];  
        end
      end
    end

 
endmodule
