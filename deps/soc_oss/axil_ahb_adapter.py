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
from litex.soc.interconnect.axi.axi_common import BURST_FIXED
from litex.soc.interconnect import ahb
from soc_oss.axi_common import *

# AXI to AXI-Lite Adapter --------------------------------------------------------------------------

PRODUCTION_MODULE="CM7AAB"
SIMULATION_MODULE="axi2ahb"
SELECTED_MODULE=SIMULATION_MODULE
class AXILite2AHBAdapter(Module):
    def __init__(self, platform, s_axil, m_ahb):
        self.logger = logging.getLogger("AXILite2AHBAdapter")

        # Get/Check Parameters.
        # ---------------------
        assert isinstance(s_axil,  AXILiteInterface)
        assert isinstance(m_ahb, ahb.AHBInterface)
        s_data_width = len(s_axil.w.data)
        # assert (s_data_width, 32)
        if s_data_width == 64:
            dw_param = 1
        else:
            dw_param = 0

        # Clock Domain.
        clock_domain = s_axil.clock_domain
        # TODO: Add clock domain check

        # Module instance.
        # ----------------
        if SELECTED_MODULE == PRODUCTION_MODULE:
            self.specials += Instance(PRODUCTION_MODULE,
                # Parameters.
                # -----------
                p_DW_64      = dw_param,

                # Clk / Rst.
                # ----------
                i_CLK        = ClockSignal(clock_domain),
                i_nSYSRESET  = ~ResetSignal(clock_domain),

                # AXI Slave Interface, adapted from AXI Lite.
                # --------------------
                # AW.
                i_AWADDR     = s_axil.aw.addr,
                i_AWBURST    = BURST_FIXED,
                i_AWID       = 0,
                i_AWLEN      = 0,
                i_AWSIZE     = 0, #log2_int(s_data_width),
                i_AWLOCK     = 0,
                i_AWPROT     = 0,
                i_AWCACHE    = 0, # or maybe 1, would indicate that the transaction is "bufferable"
                i_AWSPARSE   = 0,
                i_AWVALID    = s_axil.aw.valid,
                i_AWUSER     = 0,
                o_AWREADY    = s_axil.aw.ready,

                # W.
                i_WLAST      = 1,
                i_WSTRB      = s_axil.w.strb,
                i_WDATA      = s_axil.w.data,
                i_WVALID     = s_axil.w.valid,
                o_WREADY     = s_axil.w.ready,

                # B.
                o_BID        = Open(),
                o_BRESP      = s_axil.b.resp,
                o_BVALID     = s_axil.b.valid,
                i_BREADY     = s_axil.b.ready,

                # AR.
                i_ARADDR     = s_axil.ar.addr,
                i_ARBURST    = BURST_FIXED,
                i_ARID       = 0,
                i_ARLEN      = 0,
                i_ARSIZE     = 0, #log2_int(s_data_width),
                i_ARLOCK     = 0,
                i_ARPROT     = 0,
                i_ARCACHE    = 0, # or maybe 1
                i_ARUSER     = 0,
                i_ARVALID    = s_axil.ar.valid,
                o_ARREADY    = s_axil.ar.ready,

                # R.
                i_RREADY     = s_axil.r.ready,
                o_RVALID     = s_axil.r.valid,
                o_RID        = Open(),
                o_RLAST      = Open(),
                o_RDATA      = s_axil.r.data,
                o_RUSER      = Open(),
                o_RRESP      = s_axil.r.resp,

                # AHB Master interface
                # --------------------------
                o_HADDR                = m_ahb.addr,
                o_HWRITE               = m_ahb.write,
                o_HSIZE                = m_ahb.size,
                o_HWDATA               = m_ahb.wdata,
                o_HPROT                = m_ahb.prot,
                o_HAUSER               = Open(),
                o_HWUSER               = Open(),
                o_HBURST               = m_ahb.burst,
                o_HTRANS               = m_ahb.trans,
                o_HMASTLOCK            = m_ahb.mastlock,

                i_HRDATA               = m_ahb.rdata,
                i_HRUSER               = Open(),
                i_HREADY               = m_ahb.readyout,
                i_HRESP                = m_ahb.resp,
                i_EXRESP               = Open()
            )
        else:
            zero4 = Signal(4)
            self.specials += Instance(SIMULATION_MODULE,
                # Clk / Rst.
                # ----------
                i_clk        = ClockSignal(clock_domain),
                i_reset      = ResetSignal(clock_domain),

                # AXI Slave Interface, adapted from AXI Lite.
                # --------------------
                # AW.
                i_AWADDR     = s_axil.aw.addr,
                i_AWID       = zero4,
                i_AWLEN      = zero4,
                i_AWSIZE     = log2_int(s_data_width),
                i_AWVALID    = s_axil.aw.valid,
                o_AWREADY    = s_axil.aw.ready,

                # W.
                i_WID        = zero4,
                i_WLAST      = 1,
                i_WSTRB      = s_axil.w.strb,
                i_WDATA      = s_axil.w.data,
                i_WVALID     = s_axil.w.valid,
                o_WREADY     = s_axil.w.ready,

                # B.
                o_BID        = Open(),
                o_BRESP      = s_axil.b.resp,
                o_BVALID     = s_axil.b.valid,
                i_BREADY     = s_axil.b.ready,

                # AR.
                i_ARADDR     = s_axil.ar.addr,
                i_ARID       = zero4,
                i_ARLEN      = zero4,
                i_ARSIZE     = log2_int(s_data_width),
                i_ARVALID    = s_axil.ar.valid,
                o_ARREADY    = s_axil.ar.ready,

                # R.
                i_RREADY     = s_axil.r.ready,
                o_RVALID     = s_axil.r.valid,
                o_RID        = Open(),
                o_RLAST      = Open(),
                o_RDATA      = s_axil.r.data,
                o_RRESP      = s_axil.r.resp,

                # AHB Master interface
                # --------------------------
                o_HADDR                = m_ahb.addr,
                o_HWRITE               = m_ahb.write,
                o_HSIZE                = m_ahb.size,
                o_HWDATA               = m_ahb.wdata,
                o_HBURST               = m_ahb.burst,
                o_HTRANS               = m_ahb.trans,

                i_HRDATA               = m_ahb.rdata,
                i_HREADY               = m_ahb.readyout,
                i_HRESP                = m_ahb.resp,
            )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "axi2ahb")
        platform.add_source(os.path.join(rtl_dir, "axi2ahb.v"))
        platform.add_source(os.path.join(rtl_dir, "axi2ahb_cmd.v"))
        platform.add_source(os.path.join(rtl_dir, "axi2ahb_ctrl.v"))
        platform.add_source(os.path.join(rtl_dir, "axi2ahb_rd_fifo.v"))
        platform.add_source(os.path.join(rtl_dir, "axi2ahb_wr_fifo.v"))
        platform.add_source(os.path.join(rtl_dir, "prgen_fifo.v"))
