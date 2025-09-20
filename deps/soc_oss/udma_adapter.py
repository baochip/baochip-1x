#
# Adapt PIO to LiteX native bus interface
#
# Copyright (c) 2022 Cramium Inc
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

import os
import shutil
import logging
from pathlib import Path

from enum import IntEnum

from migen import *

from litex.soc.interconnect.axi import *
from litex.soc.interconnect import ahb
from soc_oss.axi_common import *
from .apb import *
from litex.soc.interconnect.csr import *

# AHB to APB to BIO --------------------------------------------------------------------------

class UdmaAdapter(Module):
    def __init__(self, platform, s_ahb):
        self.logger = logging.getLogger("UdmaAdapter")

        tie_one = Signal()
        self.comb += [
            tie_one.eq(1)
        ]

        self.specials += Instance("soc_ifsub_udma",
            # Parameters.
            # -----------

            # Clk / Rst.
            # ----------
            i_clk = ClockSignal("pclk"),
            i_pclk = ClockSignal("pclk"),
            i_pclken = tie_one,
            i_clk32m = ClockSignal("pclk"),
            i_clkao25m = ClockSignal("pclk"),
            i_resetn = ~ResetSignal("pclk"),
            i_perclk = ClockSignal("pclk"),
            i_cmsatpg = Open(),
            i_cmsbist = Open(),
            # i_sramtrm = Open(3),
            i_clksys = ClockSignal(),
            i_ioxlock = 0,
            i_ifev_vld = 0,
            i_ifev_dat = 0,
            o_ifev_rdy = Open(),
            o_wkupvld = Open(),
            o_wkupvld_async = Open(),
            o_ifsubevo = Open(128),
            o_ifsuberro = Open(1),
            i_ana_adcsrc = 0,

            # AHB Slave interface
            i_hsel                 = tie_one,
            i_haddr                = s_ahb.addr,          # Address bus
            i_htrans               = s_ahb.trans,         # Transfer type
            i_hwrite               = s_ahb.write,         # Transfer direction
            i_hsize                = 2, # s_ahb.size,         # Transfer size
            i_hburst               = 0, # s_ahb.burst,         # Burst type
            i_hmasterlock          = 0, # s_ahb.mastlock,      # Locked Sequence
            i_hwdata               = s_ahb.wdata,         # Write data
            i_hreadyin             = tie_one, # Not sure if this is correct?

            o_hrdata               = s_ahb.rdata,         # Read data bus
            o_hready               = s_ahb.readyout,      # Transfer done
            o_hresp                = s_ahb.resp,          # Transfer response
            # o_hruser               = Open(),

            # AHB NC wires
            i_hprot                = 0,         # Protection control
            i_hmaster              = 0,         # Master select. Should this be zero??
            # i_hauser               = 0,
            # i_hwuser               = 0,
            i_pi = 0,
            o_po = Open(96),
            o_oe = Open(96),
            o_pu = Open(96),
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        # shutil.copy('./soc_oss/rtl/common/amba_interface_def_v0.1.sv', './build/sim/gateware/')
        shutil.copy('./soc_oss/rtl/common/io_interface_def_v0.1.sv', './build/sim/gateware/')
        shutil.copy('./soc_oss_tapeout/rtl/common/template_v0.1.sv', './build/sim/gateware/')

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss", "rtl", "common")
        platform.add_source(os.path.join(rtl_dir, "ram_interface_def_v0.3.sv"))
        platform.add_source(os.path.join(rtl_dir, "io_interface_def_v0.1.sv"))
        platform.add_source(os.path.join(rtl_dir, "amba_interface_def_v0.2.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "candidate", "bio", "soc")
        platform.add_source(os.path.join(rtl_dir, "axi_pkg.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss", "ips", "common_cells", "src")
        platform.add_source(os.path.join(rtl_dir, "edge_propagator.sv"))
        platform.add_source(os.path.join(rtl_dir, "edge_propagator_ack.sv"))
        platform.add_source(os.path.join(rtl_dir, "edge_propagator_rx.sv"))
        platform.add_source(os.path.join(rtl_dir, "edge_propagator_tx.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss", "rtl", "general")
        platform.add_source(os.path.join(rtl_dir, "gnrl_sramc_pkg_v0.2.sv"))
        platform.add_source(os.path.join(rtl_dir, "gnrl_sramc_v0.2.sv"))
        platform.add_source(os.path.join(rtl_dir, "pulp_icg_v0.1.sv"))
        platform.add_source(os.path.join(rtl_dir, "ahbsramc_v0.1.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss", "rtl", "amba")
        platform.add_source(os.path.join(rtl_dir, "amba_components_v0.2.sv"))
        platform.add_source(os.path.join(rtl_dir, "aab_intf_v0.1.sv"))
        platform.add_source(os.path.join(rtl_dir, "ahb_demux_v0.1.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss", "rtl", "model")
        platform.add_source(os.path.join(rtl_dir, "artisan_ram_def_v0.1.svh"))
        platform.add_source(os.path.join(rtl_dir, "icg_v0.2.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_mpw", "ips", "L2_tcdm_hybrid_interco", "RTL")
        platform.add_source(os.path.join(rtl_dir, "lint_2_axi.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_mpw", "ips", "tech_cells_generic", "src", "deprecated")
        platform.add_source(os.path.join(rtl_dir, "pulp_clk_cells.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_mpw", "ips", "ambabuilder", "logical", "cmsdk_ahb_master_mux", "verilog")
        platform.add_source(os.path.join(rtl_dir, "cmsdk_ahb_master_mux.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_mpw", "ips", "ambabuilder", "logical", "cmsdk_ahb_to_apb", "verilog")
        platform.add_source(os.path.join(rtl_dir, "cmsdk_ahb_to_apb.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_mpw", "ips", "ambabuilder", "logical", "cmsdk_ahb_to_sram", "verilog")
        platform.add_source(os.path.join(rtl_dir, "cmsdk_ahb_to_sram.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss", "ips", "common_cells", "src", "deprecated")
        platform.add_source(os.path.join(rtl_dir, "pulp_sync_wedge.sv"))
        platform.add_source(os.path.join(rtl_dir, "pulp_sync.sv"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_mpw", "ips", "tech_cells_generic", "src", "deprecated")
        platform.add_source(os.path.join(rtl_dir, "pulp_clock_gating_async.sv"))

        # ARM model => not fully supported by verilator
        #rtl_dir = os.path.join(os.path.dirname(__file__), "..", "do_not_checkin", "s32-tapeout", "lib", "arm_sram_macro", "ifram32kx36")
        #platform.add_source(os.path.join(rtl_dir, "ifram32kx36.v"))
        # abstract model => less accurate but works with verilator
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "ifram32kx36.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "do_not_checkin", "s32-tapeout", "ips", "common_cells", "src")
        platform.add_source(os.path.join(rtl_dir, "onehot_to_bin.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "deps", "bio", "soc")
        # platform.add_source(os.path.join(rtl_dir, "template_v0.1.sv"))
        # platform.add_source(os.path.join(rtl_dir, "amba_interface_def_v0.2.sv"))
        platform.add_source(os.path.join(rtl_dir, "io_interface_def_v0.1.sv"))
        platform.add_source(os.path.join(rtl_dir, "apb_sfr_v0.1.sv"))
        # platform.add_source(os.path.join(rtl_dir, "icg_v0.2.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_intf.sv"))
        platform.add_source(os.path.join(rtl_dir, "daric_cfg_sim_v0.1.sv")) # this crashes the sim
        # platform.add_source(os.path.join(rtl_dir, "axi_pkg.sv")) # as `include already

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "deps", "bio")
        platform.add_source(os.path.join(rtl_dir, "bio_bdma_wrapper.sv"))
        platform.add_source(os.path.join(rtl_dir, "bio_bdma.sv"))
        platform.add_source(os.path.join(rtl_dir, "picorv32.v"))
        platform.add_source(os.path.join(rtl_dir, "pio_divider.v"))
        platform.add_source(os.path.join(rtl_dir, "ram_1rw_s.sv"))
        platform.add_source(os.path.join(rtl_dir, "regfifo.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "cdc_blinded.v"))
        platform.add_source(os.path.join(rtl_dir, "cdc_level_to_pulse.sv"))

        # CM7AAB sources - proprietary sim model for validation against SoC sources
        # TODO: remove once we have validated that we don't need this anymore (e.g. we have a clean test against full chip source)
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_mpw", "ips", "cortexm7", "logical", "cm7aab", "verilog")
        platform.add_source(os.path.join(rtl_dir, "cm7aab_axi.v"))
        platform.add_source(os.path.join(rtl_dir, "cm7aab_ahb.v"))
        platform.add_source(os.path.join(rtl_dir, "CM7AAB.v"))
        platform.add_source(os.path.join(rtl_dir, "cortexm7_decl_axi_types.v"))
        platform.add_source(os.path.join(rtl_dir, "cortexm7_decl_ahb_types.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss", "rtl", "ifsub")
        soc_sources = [
            "ifram_v0.1.sv",
            "ifsub1_intf_v0.1.sv",
            ### "iom_v0.1.sv",
            "iox_v0.3.sv",
            "pwm_intf_v0.1.sv",
            ### "udma_adc_ts_reg_if_v0.1.sv",
            ### "udma_adc_ts_top_v0.1.sv",
            #"udma_scif_reg_v0.1.sv",
            #"udma_scif_rx_v0.1.sv",
            #"udma_scif_tx_v0.1.sv",
            #"udma_scif_v0.1.sv",
            "udma_spis_reg_v0.2.sv",
            "udma_spis_txrx_v0.1.sv",
            "udma_spis_v0.3.sv",
            "udma_sub_v0.2.sv",
        ]
        for src in soc_sources:
            platform.add_source(os.path.join(rtl_dir, src))

        udma_paths = [
            "../soc_oss/ips/udma/udma_core",
            "../soc_oss/ips/udma/udma_camera",
            #"../soc_oss/ips/udma/udma_i2c",
            #"../soc_oss/ips/udma/udma_i2s",
            #"../soc_oss/ips/udma/udma_uart",
            #"../soc_oss/ips/udma/udma_filter",
            "../soc_oss/ips/udma/udma_qspi",
            #"../soc_oss/ips/udma/udma_sdio",
            "../do_not_checkin/s32-nto/ips/axi/axi_slice_dc/src",
            "../soc_mpw/ips/ahb_bmxif2",
        ]
        for udma in udma_paths:
            search_root = Path(Path(os.path.dirname(__file__)) / udma)
            files = [file for file in search_root.rglob('*.sv') if file.is_file()]
            files += [file for file in search_root.rglob('*.v') if file.is_file()]
            for file in files:
                platform.add_source(file)

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss")
        platform.add_source(os.path.join(rtl_dir, "soc_ifsub_udma.sv"))
