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


`ifndef _IPBOX_INC
`define _IPBOX_INC

// usbphy / pll / adc
// ■■■■■■■■■■■■■■■

	`include "modules/ifsub/rtl/utmi_def.sv"
	`ifdef SIM
		`ifdef PHYSIM
	//		`include "lib/INNO_PKG_U2_PRJ2210CBS1_S2210_T22ULL_V1P0_R20221020/FRONTEND/MODEL/presim_model/src/short_time_model/vcs/inno_usb_phy.vp"
	//		`include "lib/innosilico/INNO_PKG_U2_PRJ2210CBS1_S2210_T22ULL_V2P0_R20230726/FRONTEND/MODEL/presim_model/src/real_time_model/vcs/inno_usb_phy.vp"
			`include "asic_top/lib/innosilico/u2p/FRONTEND/MODEL/presim_model/src/real_time_model/vcs/inno_usb_phy.vp"
		`else
			`include "modules/model/rtl/udphydummy.sv"
		`endif
	`endif

	`ifdef SIM
	//`include "lib/INNO_PKG_PLL_PRJ2210CBS1_S2210_T22_V1P1_R20221020/model/presim/sim_vcs/rtl/INNO_PLL_TOP.vp"
	//`include "lib/innosilico/INNO_PKG_PLL_PRJ2210CBS1_S2210_T22_V2P0_R20230726/FRONTEND/MODEL/presim_model/src/vcs/INNO_FNPLL_TOP.vp"
	`include "asic_top/lib/innosilico/pll/FRONTEND/MODEL/presim_model/src/vcs/INNO_FNPLL_TOP.vp"
	`else
	//`include "lib/INNO_PKG_PLL_PRJ2210CBS1_S2210_T22_V1P1_R20221020/model/presim/sim_vcs/rtl/INNO_PLL_TOP_blackbox.v"
	`endif

	`ifndef FPGA
	`ifdef SIM
	`default_nettype wire
	//`include "lib/innosilico/INNO_PKG_TVSENSOR_PRJ2210CBS1_S2210_T22_V2P0_R20230726/FRONTEND/MODEL/presim_model/src/vcs/inno_tsensor_ip.vp"
	`include "asic_top/lib/innosilico/tvsensor/FRONTEND/MODEL/presim_model/src/vcs/inno_tsensor_ip.vp"
	`endif
	`endif

// io
// ■■■■■■■■■■■■■■■

`ifdef SIM
    //`include "lib/io/tphn28hpcgv2od3_fast.v"
    //`include "lib/io/tphn22ullgv2od3.v"
    `include "asic_top/lib/io/io_gppr_cln22ul_t25_mv09_mv33_fs33_svt_dr_fast.v"
    `include "template.sv"
`endif


// self design
// pmu/adcmux/osc32m/osc32k/rng/ld/gluecell
// ■■■■■■■■■■■■■■■

`ifdef SYN
//	`include "rtl/top/pmu_top_v0.2.sv"
//	`include "modules/model/rtl/adcmux_sim.sv"
//	`include osc32m
//	`include osc32k
//	`include "modules/model/rtl/rng_cell.sv"
//	`include "modules/model/rtl/ld.sv"
//	`include "modules/model/rtl/gluecell.sv"
`else
	`include "asic_top/rtl/pmu_top.sv"
	`include "modules/model/rtl/adcmux_sim.sv"
//	`include osc32m
//	`include osc32k
	`include "modules/model/rtl/rng_cell.sv"
	`include "modules/model/rtl/ld.sv"
	`include "modules/model/rtl/gluecell.sv"
`endif


`endif