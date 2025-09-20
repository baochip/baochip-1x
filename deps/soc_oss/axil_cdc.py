#
# This file is part of LiteX-Verilog-AXI-Test
#
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

# LiteX wrapper around Alex Forencich Verilog-AXI's axil_cdc.v.

import os

from migen import *

from litex.soc.interconnect.axi import *

from soc_oss.axi_common import *

# AXI-Lite Clock Domain Crossing -------------------------------------------------------------------

class AXILiteCDC(Module):
    def __init__(self, platform, s_axil, m_axil):
        self.logger = logging.getLogger("AXILiteCDC")

        # Get/Check Parameters.
        # ---------------------

        # Clock Domain.
        self.logger.info(f"Slave  Clock Domain: {colorer(s_axil.clock_domain)}")
        self.logger.info(f"Master Clock Domain: {colorer(m_axil.clock_domain)}")

        # Address width.
        address_width = len(s_axil.aw.addr)
        if len(s_axil.aw.addr) != len(m_axil.aw.addr):
            self.logger.error("{} on {} (Slave: {} / Master: {}), should be {}.".format(
                colorer("Different Address Width", color="red"),
                colorer("AXI-Lite interfaces."),
                colorer(len(s_axil.aw.addr)),
                colorer(len(m_axil.aw.addr)),
                colorer("the same")))
            raise AXIError()
        else:
            self.logger.info(f"Address Width: {colorer(address_width)}")

        # Data width.
        data_width = len(s_axil.w.data)
        if len(s_axil.w.data) != len(m_axil.w.data):
            self.logger.error("{} on {} (Slave: {} / Master: {}), should be {}.".format(
                colorer("Different Data Width", color="red"),
                colorer("AXI-Lite interfaces."),
                colorer(len(s_axil.w.data)),
                colorer(len(m_axil.w.data)),
                colorer("the same")))
            raise AXIError()
        else:
            self.logger.info(f"Data Width: {colorer(data_width)}")

        # Module instance.
        # ----------------

        self.specials += Instance("axil_cdc",
            # Parameters.
            # -----------
            p_DATA_WIDTH = data_width,
            p_ADDR_WIDTH = address_width,

            # Clk / Rst.
            # ----------
            i_s_clk = ClockSignal(s_axil.clock_domain),
            i_s_rst = ResetSignal(s_axil.clock_domain),
            i_m_clk = ClockSignal(m_axil.clock_domain),
            i_m_rst = ResetSignal(m_axil.clock_domain),
            i_clkmode = 0,

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

            # AXI-Lite Master Interface.
            # --------------------------
            # AW.
            o_m_axil_awaddr   = m_axil.aw.addr,
            o_m_axil_awprot   = Open(), # CHECKME.
            o_m_axil_awvalid  = m_axil.aw.valid,
            i_m_axil_awready  = m_axil.aw.ready,

            # W.
            o_m_axil_wdata    = m_axil.w.data,
            o_m_axil_wstrb    = m_axil.w.strb,
            o_m_axil_wvalid   = m_axil.w.valid,
            i_m_axil_wready   = m_axil.w.ready,

            # B.
            i_m_axil_bresp    = m_axil.b.resp,
            i_m_axil_bvalid   = m_axil.b.valid,
            o_m_axil_bready   = m_axil.b.ready,

            # AR.
            o_m_axil_araddr   = m_axil.ar.addr,
            o_m_axil_arprot   = Open(), # CHECKME.
            o_m_axil_arvalid  = m_axil.ar.valid,
            i_m_axil_arready  = m_axil.ar.ready,

            # R.
            i_m_axil_rdata    = m_axil.r.data,
            i_m_axil_rresp    = m_axil.r.resp,
            i_m_axil_rvalid   = m_axil.r.valid,
            o_m_axil_rready   = m_axil.r.ready,
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "verilog-axi", "rtl")
        platform.add_source(os.path.join(rtl_dir, "axil_cdc_wr.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_cdc_rd.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_cdc.v"))
