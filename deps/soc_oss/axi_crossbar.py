#
# This file is part of LiteX-Verilog-AXI-Test
#
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

# LiteX wrapper around Alex Forencich Verilog-AXI's axi_crossbar.v.

import os
import math
import logging

from enum import IntEnum

from migen import *

from litex.soc.interconnect.axi import *
from soc_oss.axi_common import *

# AXI Crossbar Interface ---------------------------------------------------------------------------

class AXICrossbarInterface:
    def __init__(self, axi, origin=None, size=None,
        aw_reg = AXIRegister.SIMPLE_BUFFER,
        w_reg  = AXIRegister.SKID_BUFFER,
        b_reg  = AXIRegister.SIMPLE_BUFFER,
        ar_reg = AXIRegister.SIMPLE_BUFFER,
        r_reg  = AXIRegister.SKID_BUFFER,
    ):
        self.axi    = axi
        self.origin = origin
        self.size   = size
        self.aw_reg = aw_reg
        self.w_reg  = w_reg
        self.b_reg  = b_reg
        self.ar_reg = ar_reg
        self.r_reg  = r_reg

# AXI Crossbar -------------------------------------------------------------------------------------

class AXICrossbar(Module):
    def __init__(self, platform):
        self.logger = logging.getLogger("AXICrossbar")
        self.s_axis = {}
        self.m_axis = {}

        # Add Sources.
        # ------------
        self.add_sources(platform)

    def get_if_name(self, axi):
        axi_ifs = {**self.s_axis, **self.m_axis}
        for name, axi_if in axi_ifs.items():
            if axi is axi_if.axi:
                return name
        return None

    def add_slave(self, name=None, s_axi=None,
        aw_reg = AXIRegister.SIMPLE_BUFFER,
        w_reg  = AXIRegister.SKID_BUFFER,
        b_reg  = AXIRegister.SIMPLE_BUFFER,
        ar_reg = AXIRegister.SIMPLE_BUFFER,
        r_reg  = AXIRegister.SKID_BUFFER):

        # Get/Check Name.
        name = f"s_axi{len(self.s_axis)}" if name is None else name
        if name in self.s_axis.keys():
            raise ValueError # FIXME: Add error message.

        # Add Slave.
        assert isinstance(s_axi, AXIInterface)
        s_axi = AXICrossbarInterface(
            axi    = s_axi,
            aw_reg = aw_reg,
            w_reg  = w_reg,
            b_reg  = b_reg,
            ar_reg = ar_reg,
            r_reg  = r_reg
        )
        self.s_axis[name] = s_axi

        # Info.
        self.logger.info(f"Add AXI Slave {name} interface.")
        self.logger.info(f"  AW Reg: {aw_reg.name}.")
        self.logger.info(f"   W Reg: { w_reg.name}.")
        self.logger.info(f"   B Reg: { b_reg.name}.")
        self.logger.info(f"  AR Reg: {ar_reg.name}.")
        self.logger.info(f"   R Reg: { r_reg.name}.")

        # Check.
        self.get_check_parameters(show=False)

    def add_master(self, name=None, m_axi=None, origin=None, size=None,
        aw_reg = AXIRegister.SIMPLE_BUFFER,
        w_reg  = AXIRegister.SKID_BUFFER,
        b_reg  = AXIRegister.SIMPLE_BUFFER,
        ar_reg = AXIRegister.SIMPLE_BUFFER,
        r_reg  = AXIRegister.SKID_BUFFER):

        # Get/Check Name.
        name = f"m_axi{len(self.m_axis)}" if name is None else name
        if name in self.m_axis.keys():
            raise ValueError # FIXME: Add error message.

        # Add Master.
        assert isinstance(m_axi, AXIInterface)
        assert origin is not None
        assert size   is not None
        m_axi = AXICrossbarInterface(
            axi    = m_axi,
            origin = origin,
            size   = size,
            aw_reg = aw_reg,
            w_reg  = w_reg,
            b_reg  = b_reg,
            ar_reg = ar_reg,
            r_reg  = r_reg
        )
        self.m_axis[name] = m_axi

        # Info.
        self.logger.info(f"Add AXI Master {name} interface.")
        self.logger.info(f"  Origin: 0x{origin:08x}.")
        self.logger.info(f"  Size:   0x{size:0x}.")
        self.logger.info(f"  AW Reg: {aw_reg.name}.")
        self.logger.info(f"   W Reg: { w_reg.name}.")
        self.logger.info(f"   B Reg: { b_reg.name}.")
        self.logger.info(f"  AR Reg: {ar_reg.name}.")
        self.logger.info(f"   R Reg: { r_reg.name}.")

        # Check.
        self.get_check_parameters(show=False)

    def get_check_parameters(self, show=True):
        axi_ifs = {**self.s_axis, **self.m_axis}
        axis    = [axi_if.axi for name, axi_if in axi_ifs.items()]

        # Clock Domain.
        self.clock_domain = clock_domain = axis[0].clock_domain
        for i, axi in enumerate(axis):
            if i == 0:
                continue
            else:
                if axi.clock_domain != clock_domain:
                    self.logger.error("{} on {} ({}: {} / {}: {}), should be {}.".format(
                        colorer("Different Clock Domain", color="red"),
                        colorer("AXI interfaces."),
                        self.get_if_name(axis[0]),
                        colorer(clock_domain),
                        self.get_if_name(axi),
                        colorer(axi.clock_domain),
                        colorer("the same")))
                    raise AXIError()
        if show:
            self.logger.info(f"Clock Domain: {colorer(clock_domain)}")

        # Address width.
        self.address_width = address_width = len(axis[0].aw.addr)
        for i, axi in enumerate(axis):
            if i == 0:
                continue
            else:
                if len(axi.aw.addr) != address_width:
                    self.logger.error("{} on {} ({}: {} / {}: {}), should be {}.".format(
                        colorer("Different Address Width", color="red"),
                        colorer("AXI interfaces."),
                        self.get_if_name(axis[0]),
                        colorer(address_width),
                        self.get_if_name(axi),
                        colorer(len(axi.aw.addr)),
                        colorer("the same")))
                    raise AXIError()
        if show:
            self.logger.info(f"Address Width: {colorer(address_width)}")

        # Data width.
        self.data_width = data_width = len(axis[0].w.data)
        for i, axi in enumerate(axis):
            if i == 0:
                continue
            else:
                if len(axi.w.data) != data_width:
                    self.logger.error("{} on {} ({}: {} / {}: {}), should be {}.".format(
                        colorer("Different Data Width", color="red"),
                        colorer("AXI interfaces."),
                        self.get_if_name(axis[0]),
                        colorer(data_width),
                        self.get_if_name(axi),
                        colorer(len(axi.w.data)),
                        colorer("the same")))
                    raise AXIError()
        if show:
            self.logger.info(f"Data Width: {colorer(data_width)}")

        # Burst.
        # FIXME: Add check.

        # User width.
        for i, axi in enumerate(axis):
            if i == 0:
                continue
            else:
                for c in ["aw", "w", "b", "ar", "r"]:
                    axi_c_0 = getattr(axis[0], c)
                    axi_c_i = getattr(axis[i], c)
                    if not hasattr(axi_c_0, "user_width") and not hasattr(axi_c_i, "user_width"):
                        continue
                    if axi_c_0.user_width != axi_c_i.user_width:
                        self.logger.error("{} on {} ({} / {}), should be {}.".format(
                            colorer("Different User Width", color="red"),
                            colorer("AXI interfaces."),
                            colorer(axi_c_0.user_width),
                            colorer(axi_c_i.user_width),
                            colorer("the same")))
                        raise AXIError()
                    else:
                        self.logger.info(f"{c.upper()} User Width: {colorer(axi_c_0.user_width)}")

    def do_finalize(self):
        axis_ifs = {**self.s_axis}
        axiss   = [axi_if.axi for name, axi_if in axis_ifs.items()]
        axim_ifs = {**self.m_axis}
        axims   = [axi_if.axi for name, axi_if in axim_ifs.items()]
        # ID width. Can't be checked until all interfaces have been added.
        self.s_id_width = s_id_width = len(axiss[0].aw.id)
        # This is slightly disturbing. The IP works without `+ len(axiss[0].aw.id)` (proven in silicon)
        # but for some reason, it refuses to pass a check when I compile this using the Vivado builder
        # without that addition. Allow this in for Vivado builds (because we use that solely for
        # critical path, area analysis and not function), but it MUST be commented out for production.
        if hasattr(self, 'vivado_only'):
            bodge = len(axiss[0].aw.id)
            self.logger.error(f"BODGE IS {bodge}: this is an error if targeting production silicon. This is a Vivado-only work-around!")
        else:
            bodge = 0
        self.m_id_width = m_id_width = len(axims[0].aw.id) + bodge
        self.logger.info(f"Slave ID Width: {colorer(s_id_width)}")
        self.logger.info(f"Master ID width: {colorer(m_id_width)}")
        if m_id_width != s_id_width + log2_int(len(self.s_axis)):
            self.logger.error(
                "ID width mismatch. Expected slave ID width of {} and master ID width of {}".format(
                    s_id_width, m_id_width + log2_int(len(self.s_axis))
            ))

        # Get/Check Parameters.
        # ---------------------
        self.get_check_parameters()

        # Get/Check Parameters.
        # ---------------------
        self.logger.info(f"Finalized {len(self.s_axis)}X{len(self.m_axis)} Crossbar:")
        self.logger.info(f"  Slaves:")
        for s_name, s_axi in self.s_axis.items():
            self.logger.info(f"  - {s_name}.")
        self.logger.info(f"  Masters:")
        for m_name, m_axi in self.m_axis.items():
            self.logger.info(f"  - {m_name}, Origin: 0x{m_axi.origin:08x}, Size: 0x{m_axi.size:0x}.")


        # Module instance.
        # ----------------

        s_axis    = [axi_if.axi                        for axi_if in self.s_axis.values()]
        m_axis    = [axi_if.axi                        for axi_if in self.m_axis.values()]
        m_origins = [axi_if.origin                     for axi_if in self.m_axis.values()]
        m_widths  = [math.ceil(math.log2(axi_if.size)) for axi_if in self.m_axis.values()]

        def format_m_params(params, width):
            value = 0
            for param in reversed(params):
                value <<= width
                value |= param
            return Constant(value, len(params)*width)


        # User Enable/Width computation.
        awuser_enable = 0 if not hasattr(s_axis[0].aw, "user") else 1 if s_axis[0].aw.user_width !=0 else 0
        awuser_width  = 1 if not hasattr(s_axis[0].aw, "user") else len(s_axis[0].aw) if s_axis[0].aw.user_width !=0 else 1
        wuser_enable  = 0 if not hasattr(s_axis[0].w,  "user") else 1 if s_axis[0].w.user_width !=0 else 0
        wuser_width   = 1 if not hasattr(s_axis[0].w,  "user") else len(s_axis[0].w) if s_axis[0].aw.user_width !=0 else 1
        buser_enable  = 0 if not hasattr(s_axis[0].b,  "user") else 1 if s_axis[0].b.user_width !=0 else 0
        buser_width   = 1 if not hasattr(s_axis[0].b,  "user") else len(s_axis[0].b) if s_axis[0].aw.user_width !=0 else 1
        aruser_enable = 0 if not hasattr(s_axis[0].ar, "user") else 1 if s_axis[0].ar.user_width !=0 else 0
        aruser_width  = 1 if not hasattr(s_axis[0].ar, "user") else len(s_axis[0].ar) if s_axis[0].aw.user_width !=0 else 1
        ruser_enable  = 0 if not hasattr(s_axis[0].r,  "user") else 1 if s_axis[0].r.user_width !=0 else 0
        ruser_width   = 1 if not hasattr(s_axis[0].r,  "user") else len(s_axis[0].r) if s_axis[0].aw.user_width !=0 else 1

        print("ruser_enable: {}, ruser_width: {}".format(ruser_enable, ruser_width))

        self.specials += Instance("axi_crossbar",
            # Parameters.
            # -----------
            p_S_COUNT    = len(s_axis),
            p_M_COUNT    = len(m_axis),
            p_DATA_WIDTH = self.data_width,
            p_ADDR_WIDTH = self.address_width,
            p_S_ID_WIDTH = self.s_id_width,
            p_M_ID_WIDTH = self.m_id_width,

            p_AWUSER_ENABLE = awuser_enable,
            p_AWUSER_WIDTH  = awuser_width,
            p_WUSER_ENABLE  = wuser_enable,
            p_WUSER_WIDTH   = wuser_width,
            p_BUSER_ENABLE  = buser_enable,
            p_BUSER_WIDTH   = buser_width,
            p_ARUSER_ENABLE = aruser_enable,
            p_ARUSER_WIDTH  = aruser_width,
            p_RUSER_ENABLE  = ruser_enable,
            p_RUSER_WIDTH   = ruser_width,

            # Slave Registers.
            p_S_AW_REG_TYPE = format_m_params([axi_if.aw_reg for axi_if in self.s_axis.values()], 2),
            p_S_W_REG_TYPE  = format_m_params([axi_if.w_reg  for axi_if in self.s_axis.values()], 2),
            p_S_B_REG_TYPE  = format_m_params([axi_if.b_reg  for axi_if in self.s_axis.values()], 2),
            p_S_AR_REG_TYPE = format_m_params([axi_if.ar_reg for axi_if in self.s_axis.values()], 2),
            p_S_R_REG_TYPE  = format_m_params([axi_if.r_reg  for axi_if in self.s_axis.values()], 2),

            # Masters Origin/Size.
            p_M_BASE_ADDR  = format_m_params(m_origins, self.address_width),
            p_M_ADDR_WIDTH = format_m_params(m_widths,  32),

            # Master Registers.
            p_M_AW_REG_TYPE = format_m_params([axi_if.aw_reg for axi_if in self.m_axis.values()], 2),
            p_M_W_REG_TYPE  = format_m_params([axi_if.w_reg  for axi_if in self.m_axis.values()], 2),
            p_M_B_REG_TYPE  = format_m_params([axi_if.b_reg  for axi_if in self.m_axis.values()], 2),
            p_M_AR_REG_TYPE = format_m_params([axi_if.ar_reg for axi_if in self.m_axis.values()], 2),
            p_M_R_REG_TYPE  = format_m_params([axi_if.r_reg  for axi_if in self.m_axis.values()], 2),

            # FIXME: Expose other parameters.

            # Clk / Rst.
            # ----------
            i_clk = ClockSignal(self.clock_domain),
            i_rst = ResetSignal(self.clock_domain),

            # AXI Slave Interfaces.
            # --------------------
            # AW.
            i_s_axi_awid     = Cat(*[s_axi.aw.id    for s_axi in s_axis]),
            i_s_axi_awaddr   = Cat(*[s_axi.aw.addr  for s_axi in s_axis]),
            i_s_axi_awlen    = Cat(*[s_axi.aw.len   for s_axi in s_axis]),
            i_s_axi_awsize   = Cat(*[s_axi.aw.size  for s_axi in s_axis]),
            i_s_axi_awburst  = Cat(*[s_axi.aw.burst for s_axi in s_axis]),
            i_s_axi_awlock   = Cat(*[s_axi.aw.lock  for s_axi in s_axis]),
            i_s_axi_awcache  = Cat(*[s_axi.aw.cache for s_axi in s_axis]),
            i_s_axi_awprot   = Cat(*[s_axi.aw.prot  for s_axi in s_axis]),
            i_s_axi_awqos    = Cat(*[s_axi.aw.qos   for s_axi in s_axis]),
            i_s_axi_awuser   = Cat(*[s_axi.aw.user  for s_axi in s_axis]),
            i_s_axi_awvalid  = Cat(*[s_axi.aw.valid for s_axi in s_axis]),
            o_s_axi_awready  = Cat(*[s_axi.aw.ready for s_axi in s_axis]),

            # W.
            i_s_axi_wdata    = Cat(*[s_axi.w.data   for s_axi in s_axis]),
            i_s_axi_wstrb    = Cat(*[s_axi.w.strb   for s_axi in s_axis]),
            i_s_axi_wlast    = Cat(*[s_axi.w.last   for s_axi in s_axis]),
            i_s_axi_wuser    = Cat(*[s_axi.w.user   for s_axi in s_axis]),
            i_s_axi_wvalid   = Cat(*[s_axi.w.valid  for s_axi in s_axis]),
            o_s_axi_wready   = Cat(*[s_axi.w.ready  for s_axi in s_axis]),

            # B.
            o_s_axi_bid      = Cat(*[s_axi.b.id     for s_axi in s_axis]),
            o_s_axi_bresp    = Cat(*[s_axi.b.resp   for s_axi in s_axis]),
            o_s_axi_buser    = Cat(*[s_axi.b.user   for s_axi in s_axis]),
            o_s_axi_bvalid   = Cat(*[s_axi.b.valid  for s_axi in s_axis]),
            i_s_axi_bready   = Cat(*[s_axi.b.ready  for s_axi in s_axis]),

            # AR.
            i_s_axi_arid     = Cat(*[s_axi.ar.id    for s_axi in s_axis]),
            i_s_axi_araddr   = Cat(*[s_axi.ar.addr  for s_axi in s_axis]),
            i_s_axi_arlen    = Cat(*[s_axi.ar.len   for s_axi in s_axis]),
            i_s_axi_arsize   = Cat(*[s_axi.ar.size  for s_axi in s_axis]),
            i_s_axi_arburst  = Cat(*[s_axi.ar.burst for s_axi in s_axis]),
            i_s_axi_arlock   = Cat(*[s_axi.ar.lock  for s_axi in s_axis]),
            i_s_axi_arcache  = Cat(*[s_axi.ar.cache for s_axi in s_axis]),
            i_s_axi_arprot   = Cat(*[s_axi.ar.prot  for s_axi in s_axis]),
            i_s_axi_arqos    = Cat(*[s_axi.ar.qos   for s_axi in s_axis]),
            i_s_axi_aruser   = Cat(*[s_axi.ar.user  for s_axi in s_axis]),
            i_s_axi_arvalid  = Cat(*[s_axi.ar.valid for s_axi in s_axis]),
            o_s_axi_arready  = Cat(*[s_axi.ar.ready for s_axi in s_axis]),

            # R.
            o_s_axi_rid      = Cat(*[s_axi.r.id     for s_axi in s_axis]),
            o_s_axi_rdata    = Cat(*[s_axi.r.data   for s_axi in s_axis]),
            o_s_axi_rresp    = Cat(*[s_axi.r.resp   for s_axi in s_axis]),
            o_s_axi_rlast    = Cat(*[s_axi.r.last   for s_axi in s_axis]),
            o_s_axi_ruser    = Cat(*[s_axi.r.user   for s_axi in s_axis]),
            o_s_axi_rvalid   = Cat(*[s_axi.r.valid  for s_axi in s_axis]),
            i_s_axi_rready   = Cat(*[s_axi.r.ready  for s_axi in s_axis]),

            # AXI Master Interfaces.
            # ----------------------
            # AW.
            o_m_axi_awid     = Cat(*[m_axi.aw.id     for m_axi in m_axis]),
            o_m_axi_awaddr   = Cat(*[m_axi.aw.addr   for m_axi in m_axis]),
            o_m_axi_awlen    = Cat(*[m_axi.aw.len    for m_axi in m_axis]),
            o_m_axi_awsize   = Cat(*[m_axi.aw.size   for m_axi in m_axis]),
            o_m_axi_awburst  = Cat(*[m_axi.aw.burst  for m_axi in m_axis]),
            o_m_axi_awlock   = Cat(*[m_axi.aw.lock   for m_axi in m_axis]),
            o_m_axi_awcache  = Cat(*[m_axi.aw.cache  for m_axi in m_axis]),
            o_m_axi_awprot   = Cat(*[m_axi.aw.prot   for m_axi in m_axis]),
            o_m_axi_awqos    = Cat(*[m_axi.aw.qos    for m_axi in m_axis]),
            o_m_axi_awregion = Cat(*[m_axi.aw.region for m_axi in m_axis]),
            o_m_axi_awuser   = Cat(*[m_axi.aw.user   for m_axi in m_axis]),
            o_m_axi_awvalid  = Cat(*[m_axi.aw.valid  for m_axi in m_axis]),
            i_m_axi_awready  = Cat(*[m_axi.aw.ready  for m_axi in m_axis]),

            # W.
            o_m_axi_wdata    = Cat(*[m_axi.w.data    for m_axi in m_axis]),
            o_m_axi_wstrb    = Cat(*[m_axi.w.strb    for m_axi in m_axis]),
            o_m_axi_wlast    = Cat(*[m_axi.w.last    for m_axi in m_axis]),
            o_m_axi_wuser    = Cat(*[m_axi.w.user    for m_axi in m_axis]),
            o_m_axi_wvalid   = Cat(*[m_axi.w.valid   for m_axi in m_axis]),
            i_m_axi_wready   = Cat(*[m_axi.w.ready   for m_axi in m_axis]),

            # B.
            i_m_axi_bid      = Cat(*[m_axi.b.id      for m_axi in m_axis]),
            i_m_axi_bresp    = Cat(*[m_axi.b.resp    for m_axi in m_axis]),
            i_m_axi_buser    = Cat(*[m_axi.b.user    for m_axi in m_axis]),
            i_m_axi_bvalid   = Cat(*[m_axi.b.valid   for m_axi in m_axis]),
            o_m_axi_bready   = Cat(*[m_axi.b.ready   for m_axi in m_axis]),

            # AR.
            o_m_axi_arid     = Cat(*[m_axi.ar.id     for m_axi in m_axis]),
            o_m_axi_araddr   = Cat(*[m_axi.ar.addr   for m_axi in m_axis]),
            o_m_axi_arlen    = Cat(*[m_axi.ar.len    for m_axi in m_axis]),
            o_m_axi_arsize   = Cat(*[m_axi.ar.size   for m_axi in m_axis]),
            o_m_axi_arburst  = Cat(*[m_axi.ar.burst  for m_axi in m_axis]),
            o_m_axi_arlock   = Cat(*[m_axi.ar.lock   for m_axi in m_axis]),
            o_m_axi_arcache  = Cat(*[m_axi.ar.cache  for m_axi in m_axis]),
            o_m_axi_arprot   = Cat(*[m_axi.ar.prot   for m_axi in m_axis]),
            o_m_axi_arqos    = Cat(*[m_axi.ar.qos    for m_axi in m_axis]),
            o_m_axi_arregion = Cat(*[m_axi.ar.region for m_axi in m_axis]),
            o_m_axi_aruser   = Cat(*[m_axi.ar.user   for m_axi in m_axis]),
            o_m_axi_arvalid  = Cat(*[m_axi.ar.valid  for m_axi in m_axis]),
            i_m_axi_arready  = Cat(*[m_axi.ar.ready  for m_axi in m_axis]),

            # R.
            i_m_axi_rid      = Cat(*[m_axi.r.id      for m_axi in m_axis]),
            i_m_axi_rdata    = Cat(*[m_axi.r.data    for m_axi in m_axis]),
            i_m_axi_rresp    = Cat(*[m_axi.r.resp    for m_axi in m_axis]),
            i_m_axi_rlast    = Cat(*[m_axi.r.last    for m_axi in m_axis]),
            i_m_axi_ruser    = Cat(*[m_axi.r.user    for m_axi in m_axis]),
            i_m_axi_rvalid   = Cat(*[m_axi.r.valid   for m_axi in m_axis]),
            o_m_axi_rready   = Cat(*[m_axi.r.ready   for m_axi in m_axis]),
        )

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "verilog-axi", "rtl")
        platform.add_source(os.path.join(rtl_dir, "arbiter.v"))
        platform.add_source(os.path.join(rtl_dir, "priority_encoder.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_register_wr.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_register_rd.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_crossbar.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_crossbar_wr.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_crossbar_rd.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_crossbar_addr.v"))