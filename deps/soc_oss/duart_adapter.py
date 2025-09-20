#
# Adapt AXILite to AHB. Derived from files in the verilog-axi test directory
#
# Copyright (c) 2022 Cramium Inc
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

import os
import math
import logging

from enum import IntEnum

from migen import *

from litex.soc.interconnect.axi import *
from litex.soc.interconnect import ahb
from soc_oss.axi_common import *
from .apb import *

# AHB to APB to DUART --------------------------------------------------------------------------

class DuartAdapter(Module):
    def __init__(self, platform, s_ahb, pads, base = 0x42000,
        address_width = 12,
    ):
        self.logger = logging.getLogger("DuartAdapter")

        apb = APBInterface(address_width=address_width)
        self.submodules += AHB2APB(s_ahb, apb, base=base)

        self.specials += Instance("duart_top",
            # Parameters.
            # -----------
            p_AW = address_width,
            p_INITETU = 32,

            # Clk / Rst.
            # ----------
            i_clk = ClockSignal(),
            i_resetn = ~ResetSignal(),
            i_sclk = ClockSignal(),

            # AHB Slave interface
            # --------------------------
            i_PADDR                = apb.paddr,
            i_PENABLE              = apb.penable,
            i_PWRITE               = apb.pwrite,
            i_PSTRB                = apb.pstrb,
            i_PPROT                = apb.pprot,
            i_PWDATA               = apb.pwdata,
            i_PSEL                 = apb.psel,
            i_APBACTIVE            = apb.pactive,
            o_PRDATA               = apb.prdata,
            o_PREADY               = apb.pready,
            o_PSLVERR              = apb.pslverr,

            o_txd                  = pads.tx,
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "common", "rtl")
        platform.add_source(os.path.join(rtl_dir, "template.sv"))
        platform.add_source(os.path.join(rtl_dir, "amba_interface_def.sv"))
        platform.add_source(os.path.join(rtl_dir, "gnrl_sync.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "amba", "rtl")
        platform.add_source(os.path.join(rtl_dir, "apb_sfr.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "core", "rtl")
        platform.add_source(os.path.join(rtl_dir, "duart.sv"))
        rtl_dir = os.path.join(os.path.dirname(__file__))
        platform.add_source(os.path.join(rtl_dir, "duart_top.sv"))

