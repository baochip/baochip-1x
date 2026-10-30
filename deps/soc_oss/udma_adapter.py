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
        shutil.copy('../rtl/modules/common/rtl/io_interface_def.sv', '../verilate/build/sim/gateware/')
        shutil.copy('../rtl/modules/common/rtl/template.sv', '../verilate/build/sim/gateware/')

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "common", "rtl")
        platform.add_source(os.path.join(rtl_dir, "gnrl_sramc_pkg.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "ips", "axi-master", "src")
        platform.add_source(os.path.join(rtl_dir, "axi_pkg.sv"))
        platform.add_source(os.path.join(rtl_dir, "axi_intf.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "ips", "common_cells", "src")
        platform.add_source(os.path.join(rtl_dir, "cf_math_pkg.sv"))
        platform.add_source(os.path.join(rtl_dir, "rr_arb_tree.sv"))
        platform.add_source(os.path.join(rtl_dir, "lzc.sv"))

        # Open-source re-implementations of the ARM CMSDK bus bridges,
        # replacing the closed cmsdk_* models in this sim flow. The
        # define steers amba_components.sv to the oss_* instances; ASIC
        # flows leave it undefined and keep the cmsdk models. Equivalence
        # is verified by tb/oss_equiv/run_equiv.sh.
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "verilate", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "oss_bridges_def.sv"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "amba", "rtl")
        platform.add_source(os.path.join(rtl_dir, "oss_ahb_to_ahb_sync_err_canc.sv"))
        platform.add_source(os.path.join(rtl_dir, "oss_ahb_to_ahb_sync.sv"))
        platform.add_source(os.path.join(rtl_dir, "oss_ahb_to_apb.sv"))
        platform.add_source(os.path.join(rtl_dir, "oss_ahb_to_sram.sv"))
        platform.add_source(os.path.join(rtl_dir, "oss_ahb_master_mux.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "common", "rtl")
        platform.add_source(os.path.join(rtl_dir, "ram_interface_def.sv"))
        platform.add_source(os.path.join(rtl_dir, "amba_interface_def.sv"))
        platform.add_source(os.path.join(rtl_dir, "io_interface_def.sv"))
        platform.add_source(os.path.join(rtl_dir, "gnrl_sramc_pkg.sv"))
        platform.add_source(os.path.join(rtl_dir, "gnrl_sramc.sv"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "model", "rtl")
        platform.add_source(os.path.join(rtl_dir, "icg.v"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "amba", "rtl")
        platform.add_source(os.path.join(rtl_dir, "ahb_demux.sv"))
        platform.add_source(os.path.join(rtl_dir, "amba_components.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "asic_top", "rtl")
        platform.add_source(os.path.join(rtl_dir, "daric_cfg_pkg.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "bio_bdma", "rtl")
        platform.add_source(os.path.join(rtl_dir, "ram_1rw_s.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "common_cells", "src", "deprecated")
        platform.add_source(os.path.join(rtl_dir, "pulp_sync_wedge.sv"))
        platform.add_source(os.path.join(rtl_dir, "pulp_sync.sv"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "ips", "tech_cells_generic", "src", "deprecated")
        platform.add_source(os.path.join(rtl_dir, "pulp_clock_gating_async.sv"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "bio_bdma", "rtl")
        platform.add_source(os.path.join(rtl_dir, "bio_bdma_wrapper.sv"))
        platform.add_source(os.path.join(rtl_dir, "bio_bdma.sv"))
        platform.add_source(os.path.join(rtl_dir, "picorv32.v"))
        platform.add_source(os.path.join(rtl_dir, "pio_divider.v"))
        platform.add_source(os.path.join(rtl_dir, "ram_1rw_s.sv"))
        platform.add_source(os.path.join(rtl_dir, "regfifo.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "verilate", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "cdc_blinded.v"))
        platform.add_source(os.path.join(rtl_dir, "cdc_level_to_pulse.sv"))
        platform.add_source(os.path.join(rtl_dir, "bioram1kx32.v"))

        # abstract model => less accurate but works with verilator
        rtl_dir = os.path.join(os.path.dirname(__file__), ".")
        platform.add_source(os.path.join(rtl_dir, "ifram32kx36.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "ips", "common_cells", "src")
        platform.add_source(os.path.join(rtl_dir, "onehot_to_bin.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "ifsub", "rtl")
        soc_sources = [
            "ifram.sv",
            "ifsub1_intf.sv",
            ### "iom_v0.1.sv",
            "iox.sv",
            "pwm_intf.sv",
            ### "udma_adc_ts_reg_if.sv",
            ### "udma_adc_ts_top.sv",
            #"udma_scif_reg.sv",
            #"udma_scif_rx.sv",
            #"udma_scif_tx.sv",
            #"udma_scif.sv",
            "udma_spis_reg.sv",
            "udma_spis_txrx.sv",
            "udma_spis.sv",
            "udma_sub.sv",
        ]
        for src in soc_sources:
            platform.add_source(os.path.join(rtl_dir, src))

        udma_paths = [
            "../../rtl/ips/udma/udma_core",
            "../../rtl/ips/udma/udma_camera",
            #"../../rtl/ips/udma/udma_i2c",
            #"../../rtl/ips/udma/udma_i2s",
            #"../../rtl/ips/udma/udma_uart",
            #"../../rtl/ips/udma/udma_filter",
            "../../rtl/ips/udma/udma_qspi",
            #"../../rtl/ips/udma/udma_sdio",
            "../do_not_checkin/s32-nto/ips/axi/axi_slice_dc/src",
        ]
        for udma in udma_paths:
            search_root = Path(Path(os.path.dirname(__file__)) / udma)
            files = [file for file in search_root.rglob('*.sv') if file.is_file()]
            files += [file for file in search_root.rglob('*.v') if file.is_file()]
            for file in files:
                platform.add_source(file)

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss")
        platform.add_source(os.path.join(rtl_dir, "soc_ifsub_udma.sv"))
