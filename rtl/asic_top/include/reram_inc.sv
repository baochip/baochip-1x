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

`default_nettype none
//`define NO_FIXING_PARITY
//`define DETECT_3_BITS

/************************************************/
// pragma protect

`timescale 1ns/10ps

//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_global_rtl_define.vh"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_regif_auto_define.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_regif_auto_define.vh"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_rtl_define.vh"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_user_rtl_define.vh"
////`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_rtl_parameter.vh"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_user_rtl_parameter.vh"
//
//`include "decoder_invless.v"
//`include "encoder_new_h.v"
//`include "trbcx1r32_22ull128kx144m32i8r16d25shvt220530_wrapper.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_generic_icg.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_generic_mux.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_generic_or.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_generic_dlatn.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_misr.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_cr72_sector.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_cr72_din_regroup.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_dyn_grp_1bit.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_dyn_grp_8_4_2_1.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_dyn_prg_sector_crdin.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_macro_cr.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_macro_rr.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_pop_counter_32b.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_row_buf.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_rr_bk.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_signed_adder.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_action_flow.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_dyn_prg.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_if.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_regif_auto.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_regif.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_rw.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_top.v"
//`include "trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_to_rram_read.v"
//`include "rrn22ull128kx144m32i8r16_d25_shvt_c220530_wrapper.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_top_mux.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_top.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_dft.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_regif.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_regif_auto.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_main.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_generic_synchronizer.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_tap_bypass.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_tap_fsm.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_tap_ir.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_tap.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_col_repair.v"
//`include "trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_row_repair.v"
//
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/decoder_invless.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/encoder_new_h.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_global_rtl_define.vh"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_user_rtl_define.vh"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_user_rtl_parameter.vh"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_rtl_define.vh"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_regif_auto_define.vh"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/rrn22ull128kx144m32i8r16_d25_shvt_c220530_wrapper.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_regif.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_regif_auto.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_dft.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_top_mux.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_top.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_main.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_generic_synchronizer.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_tap_bypass.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_tap_fsm.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_tap_ir.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_tap.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_col_repair.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trbx1r32_22ull128kx144m32i8r16d25shvt220530_bist_row_repair.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_generic_icg.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_generic_mux.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_generic_or.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_generic_dlatn.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_misr.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_cr72_sector.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_cr72_din_regroup.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_dyn_grp_1bit.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_dyn_grp_8_4_2_1.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_dyn_prg_sector_crdin.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_macro_cr.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_macro_rr.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_pop_counter_32b.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_row_buf.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_rr_bk.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_signed_adder.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_action_flow.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_dyn_prg.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_if.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_top.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_to_rram_read.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_regif_auto_define.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_regif_auto.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_regif.v"
`include "asic_top/lib/trbcx1r32_22ull128kx144m32i8r16d25shvt220530_010d/rtl/trcx1r32_22ull128kx144m32i8r16d25shvt220530_trc_rw.v"

`ifdef SIM
//`include "ips/tsmc/flash/Front_End/verilog/rrn22ull128kx144m32i8r16_d25_shvt_c220530_010c/rram_model_parameter.vh"
`include "asic_top/lib/rrn22ull128kx144m32i8r16_d25_shvt_c220530_010c.v"
`endif