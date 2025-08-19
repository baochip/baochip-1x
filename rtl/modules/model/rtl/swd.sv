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

`timescale 1ns / 1ps
`default_nettype none
module swd(clkin, SWCLK, SWDIO);
    input   wire clkin;
    output  wire SWCLK;
    inout   wire SWDIO;
    
    parameter DIV_HALF = 24;
    localparam N_CMD = 16;
    //localparam logic [0 : N_CMD - 1]  [45:0] CMD0 = {
    // localparam bit [45:0] CMD0 [N_CMD] = {
    // wire [45:0] CMDS [0 : N_CMD - 1] = {
    //wire 
    logic [45:0] CMDS [0: N_CMD - 1] ; 

    initial begin
        CMDS[ 0] = {1'b1,  1'b1,   32'hffff_ffff,  4'b1111,    8'hFF}; // line Reset
        CMDS[ 1] = {1'b1,  1'b1,   32'hffff_ffff,  4'b1111,    8'hFF}; // line Reset
        CMDS[ 2] = {1'b1,  1'b1,   32'hFF9E_7Bff,  4'b1111,    8'hFF}; // JTAG -> SWD
        CMDS[ 3] = {1'b1,  1'b1,   32'hffff_ffff,  4'b1111,    8'hFF}; // line Reset
        CMDS[ 4] = {1'b0,  1'b0,   32'h00ff_ffff,  4'b1111,    8'hFF}; // line Reset, sync

        CMDS[ 5] = {1'b1,  1'b1,   32'hffff_ffff,  4'b1111,    8'hA5}; // Read DP.DPIDR
        CMDS[ 6] = {1'b1,  1'b1,   32'hffff_ffff,  4'b1111,    8'h8D}; // READ DP.STAT
        CMDS[ 7] = {1'b0,          32'h0000_001e,  5'b11111,   8'h81}; // ABORT
        CMDS[ 8] = {1'b0,          32'h5000_0000,  5'b11111,   8'hA9}; // Power up debugger
        CMDS[ 9] = {1'b0,          32'h0000_001e,  5'b11111,   8'h81}; // ABORT 
        CMDS[10] = {1'b0,          32'h5000_0000,  5'b11111,   8'hA9}; // Power up debugger

        CMDS[11] = {1'b0,          32'h0000_0000,  5'b11111,   8'hB1}; // DP.SELECT 0
        CMDS[12] = {1'b0,          32'h2300_0002,  5'b11111,   8'hA3}; // W AP.CSW
        CMDS[13] = {1'b1,          32'hE000_ED00,  5'b11111,   8'h8B}; // Address 
        CMDS[14] = {1'b1,  1'b1,   32'hffff_ffff,  4'b1111,    8'h9F}; // Read
        CMDS[15] = {1'b1,  1'b1,   32'hffff_ffff,  4'b1111,    8'hBD}; // READ
    end

    reg     [5:0] delay = 1;
    reg     [4:0] longDelay = 1;

    logic [$clog2(DIV_HALF): 0] divCounter = 0;
    reg [48:0] fsm = 0;
    reg [$clog2(N_CMD):0] idx = 0;
    reg rSWCLK = 0;
    reg rSWDIO = 0;
    assign SWCLK = rSWCLK;
    assign SWDIO = rSWDIO;
    always @(posedge clkin) begin
        delay <= delay + 1;
        if (0 == delay) begin
            case({fsm[48:47], | fsm[46:1], fsm[0]}) 
                4'b0100: begin  // final bit
                    rSWDIO = 1'b1;
                    // rSWCLK <= ~rSWCLK;
                    // if (1'b1 == rSWCLK) begin // falling edge
                        fsm <= fsm << 1;
                    // end
                end
                4'b1000: begin  // finished
                    fsm[48] <= 1'b0;
                    fsm[0]  <= 1'b1;
                    longDelay = 1;
                    idx <= (idx == (N_CMD - 1)) ? 0 : idx + 1;
                    rSWDIO = 1'b1;
                end
                4'b0001: begin // begin
                    longDelay <= longDelay + 1;
                    if (0 == longDelay) begin
                        fsm <= fsm << 1;  // data first, 
                        rSWDIO <= CMDS[idx][0];
                    end
                end
                4'b0010: begin
                    rSWCLK <= ~rSWCLK;
                    if (1'b1 == rSWCLK) begin // falling edge
                        rSWDIO <=  (1'b1 == fsm[46]) ? 1'b1 : | (CMDS[idx] & fsm[45:0]); // << 1
                        fsm <= fsm << 1;
                    end
                end
                default: begin
                    fsm = 49'h0_0000_0000_0001;  // auto reset
                    idx <= 0;
                end
            endcase;
        end

    end
endmodule 
