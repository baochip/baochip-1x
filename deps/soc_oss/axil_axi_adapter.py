import os
import math
import logging

from enum import IntEnum

from migen import *

from litex.soc.interconnect.axi import *
from soc_oss.axi_common import *

# AXI-Lite to AXI Adapter --------------------------------------------------------------------------

class AXILite2AXIAdapter(Module):
    def __init__(self, platform, m_axi, s_axil, axi_id
    ):
        self.logger = logging.getLogger("AXILite2AXIAdapter")
        # Get/Check Parameters.
        # ---------------------
        assert isinstance(m_axi,  AXIInterface)
        assert isinstance(s_axil, AXILiteInterface)

        # Clock Domain.
        clock_domain = m_axi.clock_domain
        if m_axi.clock_domain != s_axil.clock_domain:
            self.logger.error("{} on {} (Master: {} / Slave: {}), should be {}.".format(
                colorer("Different Clock Domain", color="red"),
                colorer("AXI interfaces."),
                colorer(m_axi.clock_domain),
                colorer(s_axil.clock_domain),
                colorer("the same")))
            raise AXIError()
        else:
            self.logger.info(f"Clock Domain: {colorer(clock_domain)}")

        # Address width.
        address_width = len(m_axi.aw.addr)
        if len(m_axi.aw.addr) != len(s_axil.aw.addr):
            self.logger.error("{} on {} (Master: {} / Slave: {}), should be {}.".format(
                colorer("Different Address Width", color="red"),
                colorer("AXI interfaces."),
                colorer(len(m_axi.aw.addr)),
                colorer(len(s_axil.aw.addr)),
                colorer("the same")))
            raise AXIError()
        else:
            self.logger.info(f"Address Width: {colorer(address_width)}")

        # Data width.
        s_data_width = len(m_axi.w.data)
        m_data_width = len(s_axil.w.data)
        self.logger.info(f"Slave Data Width: {colorer(s_data_width)}")
        self.logger.info(f"Master Data Width: {colorer(m_data_width)}")

        # ID width.
        id_width = len(m_axi.aw.id)
        self.logger.info(f"ID Width: {colorer(address_width)}")

        self.specials += Instance("axil_axi_adapter",
            # Parameters.
            # -----------
            p_AW          = address_width,
            p_DW          = s_data_width,
            p_IDW         = id_width,

            # Clk / Rst.
            # ----------
            i_clk = ClockSignal(clock_domain),
            i_reset = ResetSignal(clock_domain),
            i_axi_id = axi_id,

            # AXI Master Interface.
            # --------------------
            # AW.
            o_axi_awid     = m_axi.aw.id,
            o_axi_awaddr   = m_axi.aw.addr,
            o_axi_awlen    = m_axi.aw.len,
            o_axi_awsize   = m_axi.aw.size,
            o_axi_awburst  = m_axi.aw.burst,
            # o_axi_awlock   = m_axi.aw.lock,
            # o_axi_awcache  = m_axi.aw.cache,
            o_axi_awprot   = m_axi.aw.prot,
            o_axi_awvalid  = m_axi.aw.valid,
            i_axi_awready  = m_axi.aw.ready,

            # W.
            o_axi_wdata    = m_axi.w.data,
            o_axi_wstrb    = m_axi.w.strb,
            o_axi_wlast    = m_axi.w.last,
            o_axi_wvalid   = m_axi.w.valid,
            i_axi_wready   = m_axi.w.ready,

            # B.
            i_axi_bid      = m_axi.b.id,
            i_axi_bresp    = m_axi.b.resp,
            i_axi_bvalid   = m_axi.b.valid,
            o_axi_bready   = m_axi.b.ready,

            # AR.
            o_axi_arid     = m_axi.ar.id,
            o_axi_araddr   = m_axi.ar.addr,
            o_axi_arlen    = m_axi.ar.len,
            o_axi_arsize   = m_axi.ar.size,
            o_axi_arburst  = m_axi.ar.burst,
            # o_axi_arlock   = m_axi.ar.lock,
            # o_axi_arcache  = m_axi.ar.cache,
            o_axi_arprot   = m_axi.ar.prot,
            o_axi_arvalid  = m_axi.ar.valid,
            i_axi_arready  = m_axi.ar.ready,

            # R.
            i_axi_rid      = m_axi.r.id,
            i_axi_rdata    = m_axi.r.data,
            i_axi_rresp    = m_axi.r.resp,
            # i_axi_rlast    = m_axi.r.last,
            i_axi_rvalid   = m_axi.r.valid,
            o_axi_rready   = m_axi.r.ready,

            # AXI-Lite Slave Interface.
            # --------------------------
            # AW.
            i_s_axil_awaddr   = s_axil.aw.addr,
            i_s_axil_awprot   = s_axil.aw.prot,
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
            i_s_axil_arprot   = s_axil.ar.prot,
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
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "verilate", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "axil_axi_adapter.v"))
