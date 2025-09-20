#
# This file is part of LiteX-Verilog-AXI-Test
#
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

# LiteX wrapper around Alex Forencich Verilog-AXI's axil_ram.v.

import os
import math

from migen import *

from litex.soc.interconnect.axi import *

from litex.soc.interconnect.axi import *
from soc_oss.axi_common import *

# AXI Lite RAM ---------------------------------------------------------------------------------------------------------

class AXILiteRAM(Module):
    def __init__(self, platform, s_axil, size=1024, pipeline_output=False):
        self.logger = logging.getLogger("AXILiteRAM")

        # Get/Check Parameters.
        # ---------------------

        # Clock Domain.
        clock_domain = s_axil.clock_domain
        self.logger.info(f"Clock Domain: {colorer(clock_domain)}")

        # Address width.
        address_width = len(s_axil.aw.addr)
        self.logger.info(f"Address Width: {colorer(address_width)}")

        # Data width.
        data_width = len(s_axil.w.data)
        self.logger.info(f"Data Width: {colorer(data_width)}")

        # Size.
        self.logger.info(f"Size: {colorer(size)}bytes")

        # Module instance.
        # ----------------

        self.specials += Instance("axil_ram",
            # Parameters.
            # -----------
            p_DATA_WIDTH      = data_width,
            p_ADDR_WIDTH      = math.ceil(math.log2(size)),
            p_PIPELINE_OUTPUT = pipeline_output,

            # Clk / Rst.
            # ----------
            i_clk = ClockSignal(clock_domain),
            i_rst = ResetSignal(clock_domain),

            # AXI-Lite Slave Interface.
            # -------------------------
            # AW.
            i_s_axil_awaddr   = s_axil.aw.addr,
            i_s_axil_awprot   = 0b0, # CHECKME.
            i_s_axil_awvalid  = s_axil.aw.valid,
            o_s_axil_awready  = s_axil.aw.ready,

            # W.
            i_s_axil_wdata    = s_axil.w.data,
            i_s_axil_wstrb    = s_axil.w.strb,
            i_s_axil_wvalid   = s_axil.w.valid,
            o_s_axil_wready   = s_axil.w.ready,

            # B.
            o_s_axil_bresp    = s_axil.b.resp,
            o_s_axil_bvalid   = s_axil.b.valid,
            i_s_axil_bready   = s_axil.b.ready,

            # AR.
            i_s_axil_araddr   = s_axil.ar.addr,
            i_s_axil_arprot   = 0b0, # CHECKME.
            i_s_axil_arvalid  = s_axil.ar.valid,
            o_s_axil_arready  = s_axil.ar.ready,

            # R.
            o_s_axil_rdata    = s_axil.r.data,
            o_s_axil_rresp    = s_axil.r.resp,
            o_s_axil_rvalid   = s_axil.r.valid,
            i_s_axil_rready   = s_axil.r.ready,
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "verilog-axi", "rtl")
        platform.add_source(os.path.join(rtl_dir, "axil_ram.v"))
