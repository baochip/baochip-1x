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

`default_nettype wire

`include "include/common_cell_inc.sv"

`include "ips/ahb_bmx33/ahb_bmx33_intf.sv"
`include "ips/ahb_bmx33/ahb_bmx33.v"
`include "ips/ahb_bmx33/ahb_bmx33_default_slave.v"
`include "ips/ahb_bmx33/abm0.v"
`include "ips/ahb_bmx33/abm1.v"
`include "ips/ahb_bmx33/abm2.v"
`include "ips/ahb_bmx33/ib.v"
`include "ips/ahb_bmx33/mbs0.v"
`include "ips/ahb_bmx33/mbs1.v"
`include "ips/ahb_bmx33/mbs2.v"
`include "ips/ahb_bmx33/obm0.v"
`include "ips/ahb_bmx33/obm1.v"
`include "ips/ahb_bmx33/obm2.v"

`include "include/nic400_inc.sv"

`include "modules/bmxcore/rtl/bmxcore.sv"
`include "modules/bmxcore/rtl/nic1_intf.sv"
