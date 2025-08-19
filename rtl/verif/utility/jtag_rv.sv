// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// This documentation and source code is licensed under the CERN Open Hardware
// License Version 2 – Weakly Reciprocal (http://ohwr.org/cernohl; the
// “License”). Your use of any source code herein is governed by the License.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

`define CKP 100

module jtag_rv (
  // JTAG signals
  output reg tck,      // Test Clock
  output reg tms,      // Test Mode Select
  output reg tdi,      // Test Data In
  input wire tdo,     // Test Data Out
  output reg jtrst,    // JTAG Reset
  input wire jtag_go
);

  // Internal signals
  reg [3:0] ir; // Instruction Register
  reg [31:0] dr; // Data Register
  reg [31:0] dr_out; // Shift-out data for DR
  reg [31:0] dr_in; // shift-in data from DR

  reg [1:0]  payload_size;
  reg        payload_wr;
  reg [31:0] payload_data;
  reg [31:0] payload_addr;
  reg [66:0] payload;
  reg [66:0] rsp;

  // Testbench parameters
  parameter ID_INSTRUCTION = 4'b0001;
  parameter WR_INSTRUCTION = 4'b0010;
  parameter RD_INSTRUCTION = 4'b0011;
  parameter SHIFT_DATA = 32'hA5A5A5A5; // Example 32-bit data

  initial begin
    // Initialize signals
    tck = 0;
    tms = 1;
    tdi = 0;
    jtrst = 1;
    ir = 4'b0000;
    dr = 32'b0;

    wait (jtag_go == 1);

    // Issue JTAG reset
    #(`CKP) jtrst = 0;
    #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) jtrst = 1;

    #(`CKP * 10);

    // Ensure to idle
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;

    #(`CKP * 10);

    // Move to Shift-IR state
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Select-DR
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Select-IR
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0; // Capture-IR
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0; // Shift-IR

    #(`CKP * 10);

    // Shift in 4-bit ID instruction (0001)
    for (int i = 0; i < 3; i++) begin
      tdi = ID_INSTRUCTION[i];
      #(`CKP) tck = 0;
      #(`CKP) tck = 1;
      #(`CKP) tck = 0;
    end

    #(`CKP * 10);

    // Move to Update-IR state
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Exit1-IR
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Update-IR

    #(`CKP * 10);

    // Move to Shift-DR state
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Select-DR
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0; // Capture-DR
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0; // Shift-DR

    #(`CKP * 10);

    // Shift out 32-bit data
    dr_out = SHIFT_DATA;
    for (int i = 0; i < 31; i++) begin
      tdi = dr_out[i];
      #(`CKP) tck = 0;
      #(`CKP) tck = 1;
      #(`CKP) tck = 0;
      dr_in[i] = tdo;
    end

    #(`CKP * 10);

    // Move to Update-DR state
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Exit1-DR
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Update-DR

    #(`CKP * 10);

    // ---- send a JTAG instruction ----

    // Ensure to idle
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0;

    #(`CKP * 10);

    // Move to Shift-IR state
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Select-DR
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Select-IR
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0; // Capture-IR
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0; // Shift-IR

    #(`CKP * 10);

    // Shift in 4-bit write instruction
    for (int i = 0; i < 3; i++) begin
      tdi = WR_INSTRUCTION[i];
      #(`CKP) tck = 0;
      #(`CKP) tck = 1;
      #(`CKP) tck = 0;
    end

    #(`CKP * 10);

    // Move to Update-IR state
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Exit1-IR
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Update-IR

    #(`CKP * 10);

    // Move to Shift-DR state
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Select-DR
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0; // Capture-DR
    #(`CKP) tms = 0; #(`CKP) tck = 1; #(`CKP) tck = 0; // Shift-DR

    #(`CKP * 10);

    // Shift out 67-bit write instruction
    // Note: it think this coding isn't correct, but it's good
    // enough to exercise the payload transfer which is all I need to see
    // for this test.
    payload_size = 2'b10;
    payload_wr = 1'b1;
    payload_addr = 32'b0;
    payload_data = 32'b10_0000_0000;
    payload = {payload_size, payload_wr, payload_data, payload_addr};
    for (int i = 0; i < 66; i++) begin
      tdi = payload[i];
      #(`CKP) tck = 0;
      #(`CKP) tck = 1;
      #(`CKP) tck = 0;
      rsp[i] = tdo;
    end

    #(`CKP * 10);

    // Move to Update-DR state
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Exit1-DR
    #(`CKP) tms = 1; #(`CKP) tck = 1; #(`CKP) tck = 0; // Update-DR

    #(`CKP * 10);

  end
endmodule
