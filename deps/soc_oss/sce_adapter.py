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
    def __init__(self, platform, s_ahb, m_axi0, m_axi1):
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
        vex_user = Signal(4, reset=4) # this is the AMBAID4_VEXD constant

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
            i_hauser               = vex_user,
            # i_hwuser               = 0,

            # AXI Master interfaces
            o_axi0_awvalid         = m_axi0.aw.valid,
            i_axi0_awready         = m_axi0.aw.ready,
            o_axi0_awid            = m_axi0.aw.id   ,
            o_axi0_awaddr          = m_axi0.aw.addr ,
            o_axi0_awsize          = m_axi0.aw.size ,
            o_axi0_awprot          = m_axi0.aw.prot ,
            o_axi0_awlen           = m_axi0.aw.len  ,
            o_axi0_awburst         = m_axi0.aw.burst,
            o_axi0_wvalid          = m_axi0.w.valid ,
            i_axi0_wready          = m_axi0.w.ready ,
            o_axi0_wdata           = m_axi0.w.data  ,
            o_axi0_wstrb           = m_axi0.w.strb  ,
            o_axi0_wlast           = m_axi0.w.last  ,
            i_axi0_bvalid          = m_axi0.b.valid ,
            o_axi0_bready          = m_axi0.b.ready ,
            i_axi0_bresp           = m_axi0.b.resp  ,
            i_axi0_bid             = m_axi0.b.id    ,
            o_axi0_arvalid         = m_axi0.ar.valid,
            i_axi0_arready         = m_axi0.ar.ready,
            o_axi0_arid            = m_axi0.ar.id   ,
            o_axi0_araddr          = m_axi0.ar.addr ,
            o_axi0_arsize          = m_axi0.ar.size ,
            o_axi0_arprot          = m_axi0.ar.prot ,
            o_axi0_arlen           = m_axi0.ar.len  ,
            o_axi0_arburst         = m_axi0.ar.burst,
            i_axi0_rvalid          = m_axi0.r.valid ,
            o_axi0_rready          = m_axi0.r.ready ,
            i_axi0_rid             = m_axi0.r.id    ,
            i_axi0_rdata           = m_axi0.r.data  ,
            i_axi0_rresp           = m_axi0.r.resp  ,

            o_axi1_awvalid         = m_axi1.aw.valid,
            i_axi1_awready         = m_axi1.aw.ready,
            o_axi1_awid            = m_axi1.aw.id   ,
            o_axi1_awaddr          = m_axi1.aw.addr ,
            o_axi1_awsize          = m_axi1.aw.size ,
            o_axi1_awprot          = m_axi1.aw.prot ,
            o_axi1_awlen           = m_axi1.aw.len  ,
            o_axi1_awburst         = m_axi1.aw.burst,
            o_axi1_wvalid          = m_axi1.w.valid ,
            i_axi1_wready          = m_axi1.w.ready ,
            o_axi1_wdata           = m_axi1.w.data  ,
            o_axi1_wstrb           = m_axi1.w.strb  ,
            o_axi1_wlast           = m_axi1.w.last  ,
            i_axi1_bvalid          = m_axi1.b.valid ,
            o_axi1_bready          = m_axi1.b.ready ,
            i_axi1_bresp           = m_axi1.b.resp  ,
            i_axi1_bid             = m_axi1.b.id    ,
            o_axi1_arvalid         = m_axi1.ar.valid,
            i_axi1_arready         = m_axi1.ar.ready,
            o_axi1_arid            = m_axi1.ar.id   ,
            o_axi1_araddr          = m_axi1.ar.addr ,
            o_axi1_arsize          = m_axi1.ar.size ,
            o_axi1_arprot          = m_axi1.ar.prot ,
            o_axi1_arlen           = m_axi1.ar.len  ,
            o_axi1_arburst         = m_axi1.ar.burst,
            i_axi1_rvalid          = m_axi1.r.valid ,
            o_axi1_rready          = m_axi1.r.ready ,
            i_axi1_rid             = m_axi1.r.id    ,
            i_axi1_rdata           = m_axi1.r.data  ,
            i_axi1_rresp           = m_axi1.r.resp  ,

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
