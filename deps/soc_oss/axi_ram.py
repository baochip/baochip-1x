#
# This file is part of LiteX-Verilog-AXI-Test
#
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

# LiteX wrapper around Alex Forencich Verilog-AXI's axi_ram.v.

import os
import math
import logging

from migen import *

from litex.soc.interconnect.axi import *
from soc_oss.axi_common import *

# AXI RAM ------------------------------------------------------------------------------------------

class AXIRAM(Module):
    def __init__(self, platform, s_axi, name=None, size=1024, pipeline_output=False, init=[]):
        self.logger = logging.getLogger("AXIRAM")

        # Get/Check Parameters.
        # ---------------------

        # Clock Domain.
        clock_domain = s_axi.clock_domain
        self.logger.info(f"Clock Domain: {colorer(clock_domain)}")

        # Address width.
        address_width = len(s_axi.aw.addr)
        self.logger.info(f"Address Width: {colorer(address_width)}")

        # Data width.
        data_width = len(s_axi.w.data)
        self.logger.info(f"Data Width: {colorer(data_width)}")

        # Size.
        self.logger.info(f"Size: {colorer(size)}bytes")

        # ID width.
        id_width = len(s_axi.aw.id)
        self.logger.info(f"ID Width: {colorer(id_width)}")

        # Generate memory file.
        if len(init) > 0:
            if name is None:
                print("Must specify `name` when specifying `init`")
                exit(1)
            if False:
                content = ""
                formatter = f"{{:0{int(data_width/4)}x}}\n"
                lines = [init[i:i + data_width // 8] for i in range(0, len(init), data_width // 8)]
                for d in lines:
                    content += formatter.format(int.from_bytes(d, 'little'))
                memory_filename = f"{name}_mem.init"
                with open(os.path.normpath("build/gateware/" + memory_filename), "w") as f:
                    f.write(content)
                    f.close()
            else:
                content = ""
                formatter = f"{{:0{int(data_width/4)}x}}\n"
                lines = [init[i:i + data_width // 8] for i in range(0, len(init), data_width // 8)]
                for d in lines:
                    content += bin(int.from_bytes(d, 'little')).zfill(data_width).replace('0b', '') + '\n'
                memory_filename = f"{name}_mem.init"
                with open(os.path.normpath("build/gateware/" + memory_filename), "w") as f:
                    f.write(content)
                    f.close()
        else:
            memory_filename = ""


        # Module instance.
        # ----------------
        ram_addr_width = math.ceil(math.log2(size))
        self.specials += Instance("axi_ram",
            # Parameters.
            # -----------
            p_DATA_WIDTH      = data_width,
            p_ADDR_WIDTH      = ram_addr_width,
            p_ID_WIDTH        = id_width,
            p_PIPELINE_OUTPUT = pipeline_output,
            p_MEM_INIT        = memory_filename,

            # Clk / Rst.
            # ----------
            i_clk = ClockSignal(clock_domain),
            i_rst = ResetSignal(clock_domain),

            # AXI Slave Interface.
            # --------------------
            # AW.
            i_s_axi_awid     = s_axi.aw.id,
            i_s_axi_awaddr   = s_axi.aw.addr[:ram_addr_width],
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
            i_s_axi_araddr   = s_axi.ar.addr[:ram_addr_width],
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
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "verilog-axi", "rtl")
        platform.add_source(os.path.join(rtl_dir, "axi_ram.v"))
