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

`ifndef _COMMON_CELLS
`define _COMMON_CELLS

// for axi_xbar
`define VCS
`include "include/ipbox_inc.sv"
//`include "template.sv"
`include "template.sv"

`include "modules/model/rtl/artisan_ram_def.svh"
`include "modules/rbist/rtl/rbist_intf.sv"
`include "amba_interface_def.sv"
`include "io_interface_def.sv"
`include "ram_interface_def.sv"
`include "jtag_interface_def.sv"
`include "modules/model/rtl/artisan_ram_def.svh"
`include "modules/model/rtl/icg.v"
`include "modules/common/rtl/scresetgen.sv"
`include "modules/ifsub/rtl/utmi_def.sv"

`include "modules/amba/rtl/apb_sfr.sv"
`include "modules/amba/rtl/ahb_sfr.sv"
`include "modules/amba/rtl/amba_components.sv"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_ahb_sync/verilog/cmsdk_ahb_to_ahb_sync.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_ahb_sync_down/verilog/cmsdk_ahb_to_ahb_sync_down.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_ahb_sync_down/verilog/cmsdk_ahb_to_ahb_sync_wb.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_ahb_sync_down/verilog/cmsdk_ahb_to_ahb_sync_error_canc.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_ahb_sync_down/verilog/cmsdk_ahb_to_ahb_sync_down_core.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_ahb_sync_up/verilog/cmsdk_ahb_to_ahb_sync_up.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_ahb_sync_up/verilog/cmsdk_ahb_to_ahb_sync_up_core.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_apb/verilog/cmsdk_ahb_to_apb.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_to_sram/verilog/cmsdk_ahb_to_sram.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_downsizer64/verilog/cmsdk_ahb_downsizer64.v"
`include "ips/ambabuilder/logical/cmsdk_ahb_master_mux/verilog/cmsdk_ahb_master_mux.v"
`include "modules/amba/rtl/ahb_async.sv"
`include "modules/common/rtl/bus_async.sv"


`include "ips/common_cells/src/cf_math_pkg.sv"
`include "ips/common_cells/src/addr_decode.sv"
`include "ips/common_cells/src/spill_register.sv"
`include "ips/common_cells/src/rr_arb_tree.sv"
`include "ips/common_cells/src/fifo_v3.sv"
`include "ips/common_cells/src/counter.sv"
`include "ips/common_cells/src/delta_counter.sv"
`include "ips/common_cells/src/spill_register_flushable.sv"
`include "ips/common_cells/src/lzc.sv"

`include "ips/axi-master/src/axi_pkg.sv"
`include "ips/axi-master/src/axi_intf.sv"
`include "ips/axi-master/src/axi_xbar.sv"
`include "ips/axi-master/src/axi_mux.sv"
`include "ips/axi-master/src/axi_err_slv.sv"
`include "ips/axi-master/src/axi_demux_nointf.sv"
`include "ips/axi-master/src/axi_id_prepend.sv"

`include "modules/amba/rtl/aab_intf.sv"
//`include "rtl/amba/ahb_axi_bdg_v0.1.sv"
`include "include/nic400_hxb32_inc.sv"
`include "modules/amba/rtl/ahb_demux.sv"
`include "modules/amba/rtl/axitrans.sv"

`include "ips/cortexm7/logical/cm7aab/verilog/CM7AAB.v"
`include "ips/cortexm7/logical/cm7aab/verilog/cm7aab_ahb.v"
`include "ips/cortexm7/logical/cm7aab/verilog/cm7aab_axi.v"

`include "modules/common/rtl/gnrl_sramc_pkg.sv"
`include "modules/common/rtl/gnrl_sramc.sv"
`include "modules/common/rtl/pulp_icg.sv"
`include "modules/common/rtl/gnrl_sync.sv"

`include "modules/common/rtl/sram.sv"

`include "modules/common/rtl/dummytb.sv"

//`ifdef SIM
`include "modules/model/rtl/osc_sim.sv"

`include "modules/common/rtl/insauth.v" // for fpga or sim

`ifdef FPGA
`include "asic_top/lib/fpga/ram/uram_cas_v0.1.sv"
`include "asic_top/lib/fpga/ram/bram_v0.1.sv"
`endif
`ifdef FPGASIM
`include "xilinx_glbl.v"
`include "asic_top/lib/fpga/ram/URAM288.v"
`include "asic_top/lib/fpga/ram/URAM288_BASE.v"
`include "asic_top/lib/fpga/ram/BRAM_SINGLE_MACRO.v"
`include "asic_top/lib/fpga/ram/BRAM_SDP_MACRO.v"
`include "asic_top/lib/fpga/ram/RAMB18E1.v"
`include "asic_top/lib/fpga/ram/RAMB36E1.v"
`endif
  `ifdef FPGASIM
    `include "asic_top/lib/fpga/mmcm4/MMCME4_ADV.v"
    `include "asic_top/lib/fpga/mmcm4/MMCME4_BASE.v"
    `include "asic_top/lib/fpga/mmcm4/BUFG.v"
    `include "asic_top/lib/fpga/mmcm4/BUFGCE.v"
  `endif

module _____dummytb_commoncell__just_ignore_it();
    dummytb_for_ambainterfaces__just_ignore_it u1();
    tb_aab_intf u2();
       tb_ahbaxi_bdg_intf u3();
       dummytb_ahb_demux u4();
       dummytb_axitrans u5();
       dummytb_axi_xbar u6();
       dummytb_axi_mux u7();
       dummytb_ahbsfr u8();
       dummytb_apbsfr u9();
       ioif ioifa();
       ramif ramifa();
endmodule : _____dummytb_commoncell__just_ignore_it

`ifdef SIM
    `define ARM_UD_MODEL
    `define ARM_DISABLE_EMA_CHECK
    `include "asic_top/lib/arm_sram_macro/fifo128x32/fifo128x32.v"
    `include "asic_top/lib/arm_sram_macro/fifo32x19/fifo32x19.v"
`endif

`endif // `ifndef _COMMON_CELLS

