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


`include "template.sv"
`include "modules/model/rtl/artisan_ram_def.svh"
`include "modules/rbist/rtl/rbist_intf.sv"
`include "modules/rbist/rtl/rbist_rtl1_tessent_clk_buf.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_clk_inv.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_clk_mux2.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_bap.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c10_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c10_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c10_interface_m2.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c10_interface_m3.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c1_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c1_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c2_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c2_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c3_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c3_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c4_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c4_interface_m15.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c4_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c4_interface_m7.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c5_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c5_interface_m13.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c5_interface_m15.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c5_interface_m17.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c5_interface_m19.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c5_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c5_interface_m9.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c6_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c6_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c6_interface_m3.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c6_interface_m4.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c6_interface_m5.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c7_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c7_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c7_interface_m3.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c7_interface_m4.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c7_interface_m5.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c7_interface_m6.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c7_interface_m7.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c7_interface_m8.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c8_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c8_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c9_controller.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mbist_c9_interface_m1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_posedge_synchronizer_reset.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_sib_1.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_sib_2.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_tap_main.v"
`include "modules/rbist/rtl/rbist.sv"
`include "modules/rbist/rtl/rbist_wrp.sv"
`include "modules/rbist/rtl/rbist_rtl1_tessent_buf.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_clk_gate_and.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_inv.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_mux2.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_or2.v"
`include "modules/rbist/rtl/rbist_rtl1_tessent_and2.v"

`ifdef SIM
`default_nettype wire
`include "asic_top/lib/std/tcbn22ullbwp35p140/TSMCHOME/digital/Front_End/verilog/tcbn22ullbwp35p140uhvt_110a/tcbn22ullbwp35p140uhvt.v"
`endif