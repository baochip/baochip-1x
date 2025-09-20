#
# Adapt Mbox AHB client to LiteX native bus interface
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

# AHB to APB to PIO --------------------------------------------------------------------------

class MboxAdapter(Module):
    def __init__(self, platform, s_ahb, mbox, irq_available, irq_abort_init, irq_abort_done, irq_error, base = 0x1_3000,
        address_width = 12, sim=False,
    ):
        self.logger = logging.getLogger("MboxAdapter")

        apb = APBInterface(address_width=address_width)
        self.submodules += AHB2APB(s_ahb, apb, base=base)

        self.specials += Instance("mbox_wrapper",
            # Parameters.
            # -----------
            p_AW = 12,

            # Clk / Rst.
            # ----------
            i_aclk = ClockSignal(),
            i_pclk = ClockSignal("pclk"),
            i_resetn = ~ResetSignal(),
            i_cmatpg = Open(),
            i_cmbist = Open(),
            i_sramtrm = Open(),

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

            o_mbox_w_dat           = mbox.w_dat,
            o_mbox_w_valid         = mbox.w_valid,
            i_mbox_w_ready         = mbox.w_ready,
            o_mbox_w_done          = mbox.w_done,
            i_mbox_r_dat           = mbox.r_dat,
            i_mbox_r_valid         = mbox.r_valid,
            o_mbox_r_ready         = mbox.r_ready,
            i_mbox_r_done          = mbox.r_done,
            o_mbox_w_abort         = mbox.w_abort,
            i_mbox_r_abort         = mbox.r_abort,

            o_irq_available        = irq_available,
            o_irq_abort_init       = irq_abort_init,
            o_irq_abort_done       = irq_abort_done,
            o_irq_error            = irq_error,
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "common", "rtl")
        platform.add_source(os.path.join(rtl_dir, "template.sv"))
        platform.add_source(os.path.join(rtl_dir, "amba_interface_def.sv"))
        platform.add_source(os.path.join(rtl_dir, "io_interface_def.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "amba", "rtl")
        platform.add_source(os.path.join(rtl_dir, "apb_sfr.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "verilate", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "mbox_v0.1.sv"))
        platform.add_source(os.path.join(rtl_dir, "mbox_client.v"))
        platform.add_source(os.path.join(rtl_dir, "mbox_wrapper.sv"))
