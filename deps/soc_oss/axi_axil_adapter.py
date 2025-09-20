#
# This file is part of LiteX-Verilog-AXI-Test
#
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

# LiteX wrapper around Alex Forencich Verilog-AXI's axi_axil_adapter.v.

import os
import math
import logging

from enum import IntEnum

from migen import *

from litex.soc.interconnect.axi import *
from soc_oss.axi_common import *

# AXI to AXI-Lite Adapter --------------------------------------------------------------------------

class AXI2AXILiteAdapter(Module):
    def __init__(self, platform, s_axi, m_axil,
        convert_burst        = True,
        convert_narrow_burst = False,
    ):
        self.logger = logging.getLogger("AXI2AXILiteAdapter")

        # Get/Check Parameters.
        # ---------------------
        assert isinstance(s_axi,  AXIInterface)
        assert isinstance(m_axil, AXILiteInterface)

        # Clock Domain.
        clock_domain = s_axi.clock_domain
        if s_axi.clock_domain != m_axil.clock_domain:
            self.logger.error("{} on {} (Slave: {} / Master: {}), should be {}.".format(
                colorer("Different Clock Domain", color="red"),
                colorer("AXI interfaces."),
                colorer(s_axi.clock_domain),
                colorer(m_axil.clock_domain),
                colorer("the same")))
            raise AXIError()
        else:
            self.logger.info(f"Clock Domain: {colorer(clock_domain)}")

        # Address width.
        address_width = len(s_axi.aw.addr)
        if len(s_axi.aw.addr) != len(m_axil.aw.addr):
            self.logger.error("{} on {} (Slave: {} / Master: {}), should be {}.".format(
                colorer("Different Address Width", color="red"),
                colorer("AXI interfaces."),
                colorer(len(s_axi.aw.addr)),
                colorer(len(m_axil.aw.addr)),
                colorer("the same")))
            raise AXIError()
        else:
            self.logger.info(f"Address Width: {colorer(address_width)}")

        # Data width.
        s_data_width = len(s_axi.w.data)
        m_data_width = len(m_axil.w.data)
        self.logger.info(f"Slave Data Width: {colorer(s_data_width)}")
        self.logger.info(f"Master Data Width: {colorer(m_data_width)}")

        # ID width.
        id_width = len(s_axi.aw.id)
        self.logger.info(f"ID Width: {colorer(address_width)}")

        # Burst.
        # FIXME: Add check.

        # Module instance.
        # ----------------

        self.specials += Instance("axi_axil_adapter",
            # Parameters.
            # -----------
            p_ADDR_WIDTH           = address_width,
            p_AXI_DATA_WIDTH       = s_data_width,
            p_AXIL_DATA_WIDTH      = m_data_width,
            p_CONVERT_BURST        = convert_burst,
            p_CONVERT_NARROW_BURST = convert_narrow_burst,
            p_AXI_ID_WIDTH         = id_width,

            # Clk / Rst.
            # ----------
            i_clk = ClockSignal(clock_domain),
            i_rst = ResetSignal(clock_domain),

            # AXI Slave Interface.
            # --------------------
            # AW.
            i_s_axi_awid     = s_axi.aw.id,
            i_s_axi_awaddr   = s_axi.aw.addr,
            i_s_axi_awlen    = s_axi.aw.len,
            i_s_axi_awsize   = s_axi.aw.size,
            i_s_axi_awburst  = s_axi.aw.burst,
            i_s_axi_awlock   = s_axi.aw.lock,
            i_s_axi_awcache  = s_axi.aw.cache,
            i_s_axi_awprot   = s_axi.aw.prot,
            i_s_axi_awvalid  = s_axi.aw.valid,
            o_s_axi_awready  = s_axi.aw.ready,

            # W.
            i_s_axi_wdata    = s_axi.w.data,
            i_s_axi_wstrb    = s_axi.w.strb,
            i_s_axi_wlast    = s_axi.w.last,
            i_s_axi_wvalid   = s_axi.w.valid,
            o_s_axi_wready   = s_axi.w.ready,

            # B.
            o_s_axi_bid      = s_axi.b.id,
            o_s_axi_bresp    = s_axi.b.resp,
            o_s_axi_bvalid   = s_axi.b.valid,
            i_s_axi_bready   = s_axi.b.ready,

            # AR.
            i_s_axi_arid     = s_axi.ar.id,
            i_s_axi_araddr   = s_axi.ar.addr,
            i_s_axi_arlen    = s_axi.ar.len,
            i_s_axi_arsize   = s_axi.ar.size,
            i_s_axi_arburst  = s_axi.ar.burst,
            i_s_axi_arlock   = s_axi.ar.lock,
            i_s_axi_arcache  = s_axi.ar.cache,
            i_s_axi_arprot   = s_axi.ar.prot,
            i_s_axi_arvalid  = s_axi.ar.valid,
            o_s_axi_arready  = s_axi.ar.ready,

            # R.
            o_s_axi_rid      = s_axi.r.id,
            o_s_axi_rdata    = s_axi.r.data,
            o_s_axi_rresp    = s_axi.r.resp,
            o_s_axi_rlast    = s_axi.r.last,
            o_s_axi_rvalid   = s_axi.r.valid,
            i_s_axi_rready   = s_axi.r.ready,

            # AXI-Lite Master Interface.
            # --------------------------
            # AW.
            o_m_axil_awaddr   = m_axil.aw.addr,
            o_m_axil_awprot   = m_axil.aw.prot,
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
            o_m_axil_arprot   = m_axil.ar.prot,
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
        platform.add_source(os.path.join(rtl_dir, "axi_axil_adapter.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_axil_adapter_wr.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_axil_adapter_rd.v"))