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

# AHB to AXI Adapter --------------------------------------------------------------------------

class AHB2AxiAdapter(Module):
    def __init__(self, platform, m_axi, s_ahb):
        self.logger = logging.getLogger("AHB2AxiAdapter")

        # Get/Check Parameters.
        # ---------------------
        assert isinstance(m_axi, AXIInterface)
        assert isinstance(s_ahb, ahb.AHBInterface)

        # Clock Domain.
        clock_domain = m_axi.clock_domain

        # Module instance.
        # ----------------
        self.specials += Instance("ahb_to_axi4",
            # Clk / Rst.
            # ----------
            i_clk       = ClockSignal(clock_domain),
            i_resetn    = ~ResetSignal(clock_domain),

            # AXI signals
            # AXI Write Channels
            o_axi_awvalid = m_axi.aw.valid,
            i_axi_awready = m_axi.aw.ready,
            o_axi_awid    = m_axi.aw.id,
            o_axi_awaddr  = m_axi.aw.addr,
            o_axi_awsize  = m_axi.aw.size,
            o_axi_awprot  = m_axi.aw.prot,
            o_axi_awlen   = m_axi.aw.len,
            o_axi_awburst = m_axi.aw.burst,

            o_axi_wvalid = m_axi.w.valid,
            i_axi_wready = m_axi.w.ready,
            o_axi_wdata  = m_axi.w.data,
            o_axi_wstrb  = m_axi.w.strb,
            o_axi_wlast  = m_axi.w.last,

            i_axi_bvalid = m_axi.b.valid,
            o_axi_bready = m_axi.b.ready,
            i_axi_bresp  = m_axi.b.resp,
            i_axi_bid    = m_axi.b.id,

            # AXI Read Channels
            o_axi_arvalid = m_axi.ar.valid,
            i_axi_arready = m_axi.ar.ready,
            o_axi_arid    = m_axi.ar.id,
            o_axi_araddr  = m_axi.ar.addr,
            o_axi_arsize  = m_axi.ar.size,
            o_axi_arprot  = m_axi.ar.prot,
            o_axi_arlen   = m_axi.ar.len,
            o_axi_arburst = m_axi.ar.burst,

            i_axi_rvalid = m_axi.r.valid,
            o_axi_rready = m_axi.r.ready,
            i_axi_rid    = m_axi.r.id,
            i_axi_rdata  = m_axi.r.data,
            i_axi_rresp  = m_axi.r.resp,

            # AHB-Lite signals
            i_ahb_haddr     =s_ahb.addr,     # ahb bus address
            i_ahb_hburst    =s_ahb.burst,    # tied to 0
            i_ahb_hmastlock =s_ahb.mastlock, # tied to 0
            i_ahb_hprot     =s_ahb.prot,     # tied to 4'b0011
            i_ahb_hsize     =s_ahb.size,     # size of bus transaction (possible values 0,1,2,3)
            i_ahb_htrans    =s_ahb.trans,    # Transaction type (possible values 0,2 only right now)
            i_ahb_hwrite    =s_ahb.write,    # ahb bus write
            i_ahb_hwdata    =s_ahb.wdata,    # ahb bus write data
            i_ahb_hsel      =1,              # this slave was selected
            i_ahb_hreadyin  =1,              # previous hready was accepted or not

            o_ahb_hrdata    =s_ahb.rdata,    # ahb bus read data
            o_ahb_hreadyout =s_ahb.readyout, # slave ready to accept transaction
            o_ahb_hresp     =s_ahb.resp      # slave response (high indicates erro)
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "common", "rtl")
        platform.add_source(os.path.join(rtl_dir, "amba_interface_def.sv"))
        platform.add_source(os.path.join(rtl_dir, "io_interface_def.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "soc_oss")
        platform.add_source(os.path.join(rtl_dir, "ahb_to_axi4.sv"))
