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

class SceAdapter(Module):
    def __init__(self, platform, s_ahb):
        self.logger = logging.getLogger("SceAdapter")

        tie_one = Signal()
        self.comb += [
            tie_one.eq(1)
        ]

        trust_state = Signal(256)
        iptorndlf = Signal()
        iptorndhf = Signal()
        sceintr = Signal()
        sceerrs = Signal()
        secmode = Signal()
        sceuser = Signal(8)

        self.specials += Instance("soc_sce",
            # Parameters.
            # -----------

            # Clk / Rst.
            # ----------
            i_ana_rng_0p1u = 0,
            i_clkpke = ClockSignal("pclk"),
            i_clksce = ClockSignal("pclk"),
            i_clktop = ClockSignal("pclk"),
            i_clken = tie_one,
            i_resetn = ~ResetSignal("pclk"),
            i_sysresetn = ~ResetSignal("pclk"),

            i_scedevmode = tie_one,
            i_coreuser = 0,
            i_coreuser_vex = 0,
            o_sceuser = sceuser,
            o_secmode = secmode,
            i_cfgsce = 0,
            o_truststate = trust_state,
            o_iptorndlf = iptorndlf,
            o_iptorndhf = iptorndhf,
            i_ipt_rngcfg = 0,

            o_sceintr = sceintr,
            o_sceerrs = sceerrs,

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
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        shutil.copy('../rtl/modules/crypto_top/rtl/scedma_pkg.sv', '../verilate/build/sim/gateware/')

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "common", "rtl")
        platform.add_source(os.path.join(rtl_dir, "gnrl_sramc_pkg.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "ips", "axi-master", "src")
        platform.add_source(os.path.join(rtl_dir, "axi_pkg.sv"))
        platform.add_source(os.path.join(rtl_dir, "axi_intf.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "ips", "common_cells", "src")
        platform.add_source(os.path.join(rtl_dir, "cf_math_pkg.sv"))
        platform.add_source(os.path.join(rtl_dir, "rr_arb_tree.sv"))
        platform.add_source(os.path.join(rtl_dir, "lzc.sv"))

        # TODO: fix these "cheats" in bus converters
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..", "cram-nto", "ips", "ambabuilder", "logical", "cmsdk_ahb_to_apb", "verilog")
        platform.add_source(os.path.join(rtl_dir, "cmsdk_ahb_to_apb.v"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..", "cram-nto", "ips", "ambabuilder", "logical", "cmsdk_ahb_to_ahb_sync", "verilog")
        platform.add_source(os.path.join(rtl_dir, "cmsdk_ahb_to_ahb_sync.v"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..", "cram-nto", "ips", "ambabuilder", "logical", "cmsdk_ahb_to_ahb_sync_down", "verilog")
        platform.add_source(os.path.join(rtl_dir, "cmsdk_ahb_to_ahb_sync_error_canc.v"))

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

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "verilate", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "cryptorams.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "crypto_top", "rtl")
        soc_sources = [
            "scedma_pkg.sv",
            "hash_pkg.sv",
            "aes.sv",
            "cryptoram_verilate.sv",
            "hashcore.sv",
            "hashcore_ripe.sv",
            "sce.sv",
            "sce_glbsfra.sv",
            "sce_sec.sv",
            "scedma_ac.sv",
            "combohasha.sv",
            "hashcore_blk.sv",
            "pke.sv",
            "sce_dmachnl.sv",
            "sce_memc.sv",
            "scedma.sv",
            "scedma_amba.sv",
            "trng.sv",
        ]
        for src in soc_sources:
            platform.add_source(os.path.join(rtl_dir, src))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "crypto_hash", "rtl")
        platform.add_source(os.path.join(rtl_dir, "hashcore_sha3.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), ".")
        platform.add_source(os.path.join(rtl_dir, "sce_adapter.sv"))
