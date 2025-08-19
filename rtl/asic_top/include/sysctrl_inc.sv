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
`include "template.sv"
`include "include/common_cell_inc.sv"
`include "modules/sysctrl/rtl/cms.sv"
`include "modules/sysctrl/rtl/nvrcfgs.sv"

`include "modules/sysctrl/rtl/brc.sv"
`include "modules/sysctrl/rtl/sysctrl.sv"
`include "modules/sysctrl/rtl/cgucore.sv"
`include "modules/sysctrl/rtl/cgudyncswt.sv"
`include "modules/sysctrl/rtl/cgufdsync.sv"
`include "modules/sysctrl/rtl/gearbox.sv"
`include "modules/sysctrl/rtl/freqmeter.sv"

`ifdef FPGA
//    `include "rtl/sysctrl/cgufpgadrp_v0.1.sv"
    `include "asic_top/lib/fpga/clock_e4_drp_nostep_20221107/rtl/dyna_clk_vup4.v"
    `include "asic_top/lib/fpga/clock_e4_drp_nostep_20221107/rtl/mmcm4_drp_core.v"
    `include "asic_top/lib/fpga/clock_e4_drp_nostep_20221107/rtl/mmcm4_drp_vup.v"
//    `include "lib/fpga/clock_e4_drp_nostep_20221107/rtl/mmcme4_drp_func.h"
//    `include "lib/fpga/clock_e4_drp_nostep_20221107/rtl/mmcme4_drp_func.human.readable.h"
    `include "asic_top/lib/fpga/clock_e4_drp_nostep_20221107/rtl/mmcm_simple_vup.v"
//    `include "lib/fpga/clock_e4_drp_nostep_20221107/rtl/mmcm_usp_drp_tables.vh"
`else
    `include "modules/sysctrl/rtl/cgupll.sv"
`endif

//`endif
