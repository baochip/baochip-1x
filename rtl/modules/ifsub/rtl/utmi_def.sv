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


`define UTMI_IF_DEF \
    inout  wire            VCCA3P3,               \
    inout  wire            VCCCORE,               \
    inout  wire            VDD,                   \
    inout  wire            VSS,                   \
    inout  wire            VSSA,                  \
    inout  wire            VSSD,                  \
    input  wire            utmi_clk,              \
    output wire            u2p0_external_rst,     \
    output wire  [1:0]     utmi_xcvrselect,       \
    output wire            utmi_termselect,       \
    output wire            utmi_suspendm,         \
    input  wire  [1:0]     utmi_linestate,        \
    output wire  [1:0]     utmi_opmode,           \
    output wire  [7:0]     utmi_datain7_0,        \
    output wire            utmi_txvalid,          \
    input  wire            utmi_txready,          \
    input  wire  [7:0]     utmi_dataout7_0,       \
    input  wire            utmi_rxvalid,          \
    input  wire            utmi_rxactive,         \
    input  wire            utmi_rxerror,          \
    output wire            utmi_dppulldown,       \
    output wire            utmi_dmpulldown,       \
    input  wire            utmi_hostdisconnect,   


`define UTMI_IF_INST \
    .VCCA3P3(),               \
    .VCCCORE(),               \
    .VDD(),                   \
    .VSS(),                   \
    .VSSA(),                  \
    .VSSD(),                  \
    .utmi_clk,              \
    .u2p0_external_rst,     \
    .utmi_xcvrselect,       \
    .utmi_termselect,       \
    .utmi_suspendm,         \
    .utmi_linestate,        \
    .utmi_opmode,           \
    .utmi_datain7_0,        \
    .utmi_txvalid,          \
    .utmi_txready,          \
    .utmi_dataout7_0,       \
    .utmi_rxvalid,          \
    .utmi_rxactive,         \
    .utmi_rxerror,          \
    .utmi_dppulldown,       \
    .utmi_dmpulldown,       \
    .utmi_hostdisconnect,   

