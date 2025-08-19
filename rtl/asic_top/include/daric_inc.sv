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

`timescale 1 ns/1 ps
//`define MPW
`define PULP_DFT
`define INITIALIZE_MEMORY

`include "include/ipbox_inc.sv"
`include "template.sv"

`include "include/common_cell_inc.sv"
`include "asic_top/rtl/daric_cfg_pkg.sv"
`include "include/sysctrl_inc.sv"
`include "modules/rrc/rtl/rrc_pkg.sv"
`include "include/bmxcore_inc.sv"
`include "include/cm7sys_inc.sv"
`include "include/sce_inc.sv"
`include "include/mdma_inc.sv"
`include "include/vexrv_inc.sv"
`include "include/qfc_inc.sv"
`include "include/rbist_inc.sv"
//`include "rtl/ifsub/soc_ifsub_v0.1.sv"
`include "include/soc_ifsub_inc.sv"
`include "include/sec_inc.sv"

//`include "ips/cortexm7/logical/testbench/execution_tb/verilog/example_sys/cm7_ik_ahb_sram_bridge_64.v"
`include "modules/amba/rtl/ahb_sram_bridge_64_waitcyc.v"
`include "modules/core/rtl/coresub_sramtrm.sv"

`include "modules/common/rtl/axisramc.sv"
`include "modules/soc_coresub/rtl/soc_coresub.sv"
`include "include/jtagtap_inc.sv"
`include "asic_top/rtl/soc_top.sv"
`ifdef SIM
`include "asic_top/lib/arm_sram_macro/acram2kx64/acram2kx64.v"
`include "asic_top/lib/arm_sram_macro/aoram1kx36_hvt/aoram1kx36.v"
`endif

`include "modules/core/rtl/core_srambank.try8k.sv"
`ifdef FPGA
    `include "modules/rrc/rtl/rrc_emu.sv"
`else
    `include "include/reram_inc.sv"
    `include "modules/rrc/rtl/rerammacro.sv"
    `include "modules/rrc/rtl/trbcx1r32_daric_wrapper.sv"
    `include "modules/rrc/rtl/rrc.sv"
`endif

`include "modules/core/rtl/duart.sv"
`include "modules/sysctrl/rtl/apbsys_intf.sv"
`include "modules/sysctrl/rtl/evc.sv"
`include "ips/pulp_soc/rtl/pulp_soc/soc_event_queue.sv"
`include "ips/pulp_soc/rtl/pulp_soc/soc_event_arbiter.sv"
`include "ips/ambabuilder/logical/cmsdk_apb_watchdog/verilog/cmsdk_apb_watchdog.v"
`include "ips/ambabuilder/logical/cmsdk_apb_watchdog/verilog/cmsdk_apb_watchdog_frc.v"
//`include "ips/ambabuilder/logical/cmsdk_apb_uart/verilog/cmsdk_apb_uart.v"
`include "ips/pulp_soc/rtl/components/apb_timer_unit.sv"
`include "ips/timer_unit/rtl/timer_unit_counter.sv"

`include "asic_top/rtl/sparecell.v"

// ao

`include "modules/ao/rtl/aobureg.sv"
`include "modules/ao/rtl/dkpc.sv"
`include "modules/sysctrl/rtl/aoperi.sv"
`include "include/rtc_inc.sv"
`include "modules/ao/rtl/ao_sysctrl.sv"
`include "modules/ao/rtl/ao_top.sv"
`include "modules/ao/rtl/aoram.sv"

// pad
`include "modules/model/rtl/padcell_arm.sv"
`include "asic_top/rtl/pad_frame_arm.sv"
`include "asic_top/rtl/powerpad.sv"

//`ifndef FPGA
// top
    `include "asic_top/rtl/daric_top.sv"
//`endif


`ifdef FPGASIM
`include "asic_top/lib/fpga/PULLUP.v"
`include "asic_top/lib/fpga/PULLDOWN.v"
`endif

`ifdef SIM
`include "modules/model/rtl/sim_mon.sv"
`include "modules/model/rtl/usbipmon.sv"
`endif


// for less dummytb on the top level
module _____dummytb_soc_coresub__just_ignore_it();
       _____dummytb_commoncell__just_ignore_it u1();
       dummytb_ahb_bmx33 u2();
       dummytb_bmxcore u3();
//       cm7dpu_alu_sbitx u4();
//       cm7_pmu_sync_reset u5();
//       cm7_rst_send_set u6();
//       cm7_pmu_sync_set u7();
//       cm7_cdc_random u8();
//       cm7_pmu_cdc_send_reset u9();
//       cm7_rst_sync uc();
//       cortexm7_ecc_repair64 ua();
//       __dummy_tb_cm7sys_ ub();
//       dummytb_soc_coresub u();
endmodule : _____dummytb_soc_coresub__just_ignore_it
