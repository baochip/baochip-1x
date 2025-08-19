// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: MIT
//
// This file may have been modified and is redistributed by CrossBar, Inc.
//
// You may redistribute and modify this documentation 
// under the terms of the License. This documentation 
// and source code is distributed WITHOUT ANY EXPRESS 
// OR IMPLIED WARRANTY, MERCHANTABILITY, 
// SATISFACTORY QUALITY OR FITNESS FOR A PARTICULAR PURPOSE. 
// Please see the License for the specific language governing permissions 
// and limitations under the License.
//
/*

Copyright (c) 2019 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4 lite clock domain crossing module (read)
 */
module axil_cdc_rd #
(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    /*
     * AXI lite slave interface
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,

    // clocking flag
    // 00: asynchronous (two stage synchronizer)
    // 01 or 10: mechronous (one stage synchronizer)
    // 11: isochronous (edge synced but different frequency - no synchronizer)
    input wire [1:0]              clkmode,

    /*
     * AXI lite master interface
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [2:0]             m_axil_arprot,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);

reg [1:0] s_state_reg;
reg s_flag_reg;
(* srl_style = "register" *)
reg s_flag_sync_reg_1;
(* srl_style = "register" *)
reg s_flag_sync_reg_2;

reg [1:0] m_state_reg;
reg m_flag_reg;
(* srl_style = "register" *)
reg m_flag_sync_reg_1;
(* srl_style = "register" *)
reg m_flag_sync_reg_2;

reg [ADDR_WIDTH-1:0]  s_axil_araddr_reg;
reg [2:0]             s_axil_arprot_reg ;
reg                   s_axil_arvalid_reg;
reg [DATA_WIDTH-1:0]  s_axil_rdata_reg ;
reg [1:0]             s_axil_rresp_reg ;
reg                   s_axil_rvalid_reg;

reg [ADDR_WIDTH-1:0]  m_axil_araddr_reg;
reg [2:0]             m_axil_arprot_reg;
reg                   m_axil_arvalid_reg;
reg [DATA_WIDTH-1:0]  m_axil_rdata_reg ;
reg [1:0]             m_axil_rresp_reg ;
reg                   m_axil_rvalid_reg;

wire                  m_flag_sync_reg_target;
wire                  s_flag_sync_reg_target;
// these should be statically configured before any activity happens
// on the AXI bus; but pulled into the target clock domain to make
// timing cleaner
reg [1:0]             m_clkmode[2];
reg [1:0]             s_clkmode[2];

assign s_axil_arready = !s_axil_arvalid_reg && !s_axil_rvalid_reg;
assign s_axil_rdata = s_axil_rdata_reg;
assign s_axil_rresp = s_axil_rresp_reg;
assign s_axil_rvalid = s_axil_rvalid_reg;

assign m_axil_araddr = m_axil_araddr_reg;
assign m_axil_arprot = m_axil_arprot_reg;
assign m_axil_arvalid = m_axil_arvalid_reg;
assign m_axil_rready = !m_axil_rvalid_reg;

// slave side
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_state_reg <= 2'd0;
        s_flag_reg <= 1'b0;
        s_axil_arvalid_reg <= 1'b0;
        s_axil_rvalid_reg <= 1'b0;

        s_axil_araddr_reg <= 0;
        s_axil_arprot_reg <= 0;
        s_axil_rdata_reg <= 0;
        s_axil_rresp_reg <= 0;
    end else begin
        s_axil_rvalid_reg <= s_axil_rvalid_reg && !s_axil_rready;

        if (!s_axil_arvalid_reg && !s_axil_rvalid_reg) begin
            s_axil_araddr_reg <= s_axil_araddr;
            s_axil_arprot_reg <= s_axil_arprot;
            s_axil_arvalid_reg <= s_axil_arvalid;
        end

        case (s_state_reg)
            2'd0: begin
                if (s_axil_arvalid_reg) begin
                    s_state_reg <= 2'd1;
                    s_flag_reg <= 1'b1;
                end
            end
            2'd1: begin
                if (m_flag_sync_reg_target) begin
                    s_state_reg <= 2'd2;
                    s_flag_reg <= 1'b0;
                    s_axil_rdata_reg <= m_axil_rdata_reg;
                    s_axil_rresp_reg <= m_axil_rresp_reg;
                    s_axil_rvalid_reg <= 1'b1;
                end
            end
            2'd2: begin
                if (!m_flag_sync_reg_target) begin
                    s_state_reg <= 2'd0;
                    s_axil_arvalid_reg <= 1'b0;
                end
            end
        endcase
    end
end

// synchronization
always @(posedge s_clk) begin
    m_flag_sync_reg_1 <= m_flag_reg;
    m_flag_sync_reg_2 <= m_flag_sync_reg_1;

    m_clkmode[1] <= m_clkmode[0];
    m_clkmode[0] <= clkmode;
end
assign m_flag_sync_reg_target = ~|m_clkmode[1] ? m_flag_sync_reg_2 : ^m_clkmode[1] ? m_flag_sync_reg_1 : m_flag_reg;

always @(posedge m_clk) begin
    s_flag_sync_reg_1 <= s_flag_reg;
    s_flag_sync_reg_2 <= s_flag_sync_reg_1;

    s_clkmode[1] <= s_clkmode[0];
    s_clkmode[0] <= clkmode;
end
assign s_flag_sync_reg_target = ~|s_clkmode[1] ? s_flag_sync_reg_2 : ^s_clkmode[1] ? s_flag_sync_reg_1 : s_flag_reg;

// master side
always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_state_reg <= 2'd0;
        m_flag_reg <= 1'b0;
        m_axil_arvalid_reg <= 1'b0;
        m_axil_rvalid_reg <= 1'b1;

        m_axil_rdata_reg <= 0;
        m_axil_rresp_reg <= 0;
        m_axil_araddr_reg <= 0;
        m_axil_arprot_reg <= 0;
    end else begin
        m_axil_arvalid_reg <= m_axil_arvalid_reg && !m_axil_arready;

        if (!m_axil_rvalid_reg) begin
            m_axil_rdata_reg <= m_axil_rdata;
            m_axil_rresp_reg <= m_axil_rresp;
            m_axil_rvalid_reg <= m_axil_rvalid;
        end

        case (m_state_reg)
            2'd0: begin
                if (s_flag_sync_reg_target) begin
                    m_state_reg <= 2'd1;
                    m_axil_araddr_reg <= s_axil_araddr_reg;
                    m_axil_arprot_reg <= s_axil_arprot_reg;
                    m_axil_arvalid_reg <= 1'b1;
                    m_axil_rvalid_reg <= 1'b0;
                end
            end
            2'd1: begin
                if (m_axil_rvalid_reg) begin
                    m_flag_reg <= 1'b1;
                    m_state_reg <= 2'd2;
                end
            end
            2'd2: begin
                if (!s_flag_sync_reg_target) begin
                    m_state_reg <= 2'd0;
                    m_flag_reg <= 1'b0;
                end
            end
        endcase
    end
end

endmodule

`resetall
