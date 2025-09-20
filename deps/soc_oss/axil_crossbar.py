#
# This file is part of LiteX-Verilog-AXI-Test
#
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

# LiteX wrapper around Alex Forencich Verilog-AXI's axil_crossbar.v.

import os
import math

from migen import *

from litex.soc.interconnect.axi import *

from soc_oss.axi_common import *

# AXI Lite Crossbar Interface ----------------------------------------------------------------------

class AXILiteCrossbarInterface:
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

# AXI Lite Crossbar --------------------------------------------------------------------------------

class AXILiteCrossbar(Module):
    def __init__(self, platform):
        self.logger = logging.getLogger("AXILiteCrossbar")
        self.s_axils = {}
        self.m_axils = {}

        # Add Sources.
        # ------------
        self.add_sources(platform)

    def get_if_name(self, axil):
        axil_ifs = {**self.s_axils, **self.m_axils}
        for name, axil_if in axil_ifs.items():
            if axil is axil_if.axi:
                return name
        return None

    def add_slave(self, name=None, s_axil=None,
        aw_reg = AXIRegister.SIMPLE_BUFFER,
        w_reg  = AXIRegister.SKID_BUFFER,
        b_reg  = AXIRegister.SIMPLE_BUFFER,
        ar_reg = AXIRegister.SIMPLE_BUFFER,
        r_reg  = AXIRegister.SKID_BUFFER):

        # Get/Check Name.
        name = f"s_axil{len(self.s_axils)}" if name is None else name
        if name in self.s_axils.keys():
            raise ValueError # FIXME: Add error message.

        # Add Slave.
        assert isinstance(s_axil, AXILiteInterface)
        s_axil = AXILiteCrossbarInterface(
            axi    = s_axil,
            aw_reg = aw_reg,
            w_reg  = w_reg,
            b_reg  = b_reg,
            ar_reg = ar_reg,
            r_reg  = r_reg
        )
        self.s_axils[name] = s_axil

        # Info.
        self.logger.info(f"Add AXI-Lite Slave {name} interface.")
        self.logger.info(f"  AW Reg: {aw_reg.name}.")
        self.logger.info(f"   W Reg: { w_reg.name}.")
        self.logger.info(f"   B Reg: { b_reg.name}.")
        self.logger.info(f"  AR Reg: {ar_reg.name}.")
        self.logger.info(f"   R Reg: { r_reg.name}.")

        # Check.
        self.get_check_parameters(show=False)

    def add_master(self, name=None, m_axil=None, origin=None, size=None,
        aw_reg = AXIRegister.SIMPLE_BUFFER,
        w_reg  = AXIRegister.SKID_BUFFER,
        b_reg  = AXIRegister.SIMPLE_BUFFER,
        ar_reg = AXIRegister.SIMPLE_BUFFER,
        r_reg  = AXIRegister.SKID_BUFFER):

        # Get/Check Name.
        name = f"m_axil{len(self.m_axils)}" if name is None else name
        if name in self.m_axils.keys():
            raise ValueError # FIXME: Add error message.

        # Add Master.
        assert isinstance(m_axil, AXILiteInterface)
        assert origin is not None
        assert size   is not None
        m_axil = AXILiteCrossbarInterface(
            axi    = m_axil,
            origin = origin,
            size   = size,
            aw_reg = aw_reg,
            w_reg  = w_reg,
            b_reg  = b_reg,
            ar_reg = ar_reg,
            r_reg  = r_reg
        )
        self.m_axils[name] = m_axil

        # Info.
        self.logger.info(f"Add AXI-Lite Master {name} interface.")
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
        axil_ifs = {**self.s_axils, **self.m_axils}
        axils    = [axil_if.axi for name, axil_if in axil_ifs.items()]

        # Clock Domain.
        self.clock_domain = clock_domain = axils[0].clock_domain
        for i, axi in enumerate(axils):
            if i == 0:
                continue
            else:
                if axi.clock_domain != clock_domain:
                    self.logger.error("{} on {} ({}: {} / {}: {}), should be {}.".format(
                        colorer("Different Clock Domain", color="red"),
                        colorer("AXI-Lite interfaces."),
                        self.get_if_name(axils[0]),
                        colorer(clock_domain),
                        self.get_if_name(axi),
                        colorer(axi.clock_domain),
                        colorer("the same")))
                    raise AXIError()
        if show:
            self.logger.info(f"Clock Domain: {colorer(clock_domain)}")

        # Address width.
        self.address_width = address_width = len(axils[0].aw.addr)
        for i, axi in enumerate(axils):
            if i == 0:
                continue
            else:
                if len(axi.aw.addr) != address_width:
                    self.logger.error("{} on {} ({}: {} / {}: {}), should be {}.".format(
                        colorer("Different Address Width", color="red"),
                        colorer("AXI-Lite interfaces."),
                        self.get_if_name(axils[0]),
                        colorer(address_width),
                        self.get_if_name(axi),
                        colorer(len(axi.aw.addr)),
                        colorer("the same")))
                    raise AXIError()
        if show:
            self.logger.info(f"Address Width: {colorer(address_width)}")

        # Data width.
        self.data_width = data_width = len(axils[0].w.data)
        for i, axi in enumerate(axils):
            if i == 0:
                continue
            else:
                if len(axi.w.data) != data_width:
                    self.logger.error("{} on {} ({}: {} / {}: {}), should be {}.".format(
                        colorer("Different Data Width", color="red"),
                        colorer("AXI-Lite interfaces."),
                        self.get_if_name(axils[0]),
                        colorer(data_width),
                        self.get_if_name(axi),
                        colorer(len(axi.w.data)),
                        colorer("the same")))
                    raise AXIError()
        if show:
            self.logger.info(f"Data Width: {colorer(address_width)}")

    def do_finalize(self):
        # Get/Check Parameters.
        # ---------------------
        self.get_check_parameters()


        # Get/Check Parameters.
        # ---------------------
        self.logger.info(f"Finalized {len(self.s_axils)}X{len(self.m_axils)} Crossbar:")
        self.logger.info(f"  Slaves:")
        for s_name, s_axil in self.s_axils.items():
            self.logger.info(f"  - {s_name}.")
        self.logger.info(f"  Masters:")
        for m_name, m_axil in self.m_axils.items():
            self.logger.info(f"  - {m_name}, Origin: 0x{m_axil.origin:08x}, Size: 0x{m_axil.size:0x}.")


        # Module instance.
        # ----------------

        s_axils   = [axil_if.axi                       for axil_if in self.s_axils.values()]
        m_axils   = [axil_if.axi                       for axil_if in self.m_axils.values()]
        m_origins = [axil_if.origin                    for axil_if in self.m_axils.values()]
        m_widths  = [math.ceil(math.log2(axil_if.size)) for axil_if in self.m_axils.values()]

        def format_m_params(params, width):
            value = 0
            for param in reversed(params):
                value <<= width
                value |= param
            return Constant(value, len(params)*width)

        self.specials += Instance("axil_crossbar",
            # Parameters.
            # -----------
            p_S_COUNT    = len(s_axils),
            p_M_COUNT    = len(m_axils),
            p_DATA_WIDTH = self.data_width,
            p_ADDR_WIDTH = self.address_width,

            # Slave Registers.
            p_S_AW_REG_TYPE = format_m_params([axil_if.aw_reg for axil_if in self.s_axils.values()], 2),
            p_S_W_REG_TYPE  = format_m_params([axil_if.w_reg  for axil_if in self.s_axils.values()], 2),
            p_S_B_REG_TYPE  = format_m_params([axil_if.b_reg  for axil_if in self.s_axils.values()], 2),
            p_S_AR_REG_TYPE = format_m_params([axil_if.ar_reg for axil_if in self.s_axils.values()], 2),
            p_S_R_REG_TYPE  = format_m_params([axil_if.r_reg  for axil_if in self.s_axils.values()], 2),

            # Masters Origin/Size.
            p_M_BASE_ADDR  = format_m_params(m_origins, self.address_width),
            p_M_ADDR_WIDTH = format_m_params(m_widths,  32),

            # Master Registers.
            p_M_AW_REG_TYPE = format_m_params([axil_if.aw_reg for axil_if in self.m_axils.values()], 2),
            p_M_W_REG_TYPE  = format_m_params([axil_if.w_reg  for axil_if in self.m_axils.values()], 2),
            p_M_B_REG_TYPE  = format_m_params([axil_if.b_reg  for axil_if in self.m_axils.values()], 2),
            p_M_AR_REG_TYPE = format_m_params([axil_if.ar_reg for axil_if in self.m_axils.values()], 2),
            p_M_R_REG_TYPE  = format_m_params([axil_if.r_reg  for axil_if in self.m_axils.values()], 2),

            # FIXME: Expose other parameters.

            # Clk / Rst.
            # ----------
            i_clk = ClockSignal(self.clock_domain),
            i_rst = ResetSignal(self.clock_domain),

            # AXI-Lite Slave Interfaces.
            # --------------------------
            # AW.
            i_s_axil_awaddr   = Cat(*[s_axil.aw.addr  for s_axil in s_axils]),
            i_s_axil_awprot   = Cat(*[Constant(0, 3)  for s_axil in s_axils]), # CHECKME.
            i_s_axil_awvalid  = Cat(*[s_axil.aw.valid for s_axil in s_axils]),
            o_s_axil_awready  = Cat(*[s_axil.aw.ready for s_axil in s_axils]),

            # W.
            i_s_axil_wdata    = Cat(*[s_axil.w.data   for s_axil in s_axils]),
            i_s_axil_wstrb    = Cat(*[s_axil.w.strb   for s_axil in s_axils]),
            i_s_axil_wvalid   = Cat(*[s_axil.w.valid  for s_axil in s_axils]),
            o_s_axil_wready   = Cat(*[s_axil.w.ready  for s_axil in s_axils]),

            # B.
            o_s_axil_bresp    = Cat(*[s_axil.b.resp   for s_axil in s_axils]),
            o_s_axil_bvalid   = Cat(*[s_axil.b.valid  for s_axil in s_axils]),
            i_s_axil_bready   = Cat(*[s_axil.b.ready  for s_axil in s_axils]),

            # AR.
            i_s_axil_araddr   = Cat(*[s_axil.ar.addr  for s_axil in s_axils]),
            i_s_axil_arprot   = Cat(*[Constant(0, 3)  for s_axil in s_axils]), # CHECKME.
            i_s_axil_arvalid  = Cat(*[s_axil.ar.valid for s_axil in s_axils]),
            o_s_axil_arready  = Cat(*[s_axil.ar.ready for s_axil in s_axils]),

            # R.
            o_s_axil_rdata    = Cat(*[s_axil.r.data   for s_axil in s_axils]),
            o_s_axil_rresp    = Cat(*[s_axil.r.resp   for s_axil in s_axils]),
            o_s_axil_rvalid   = Cat(*[s_axil.r.valid  for s_axil in s_axils]),
            i_s_axil_rready   = Cat(*[s_axil.r.ready  for s_axil in s_axils]),

            # AXI-Lite Master Interfaces.
            # ---------------------------
            # AW.
            o_m_axil_awaddr   = Cat(*[m_axil.aw.addr  for m_axil in m_axils]),
            o_m_axil_awprot   = Cat(*[Signal(3)      for m_axil in m_axils]),
            o_m_axil_awvalid  = Cat(*[m_axil.aw.valid for m_axil in m_axils]),
            i_m_axil_awready  = Cat(*[m_axil.aw.ready for m_axil in m_axils]),

            # W.
            o_m_axil_wdata    = Cat(*[m_axil.w.data   for m_axil in m_axils]),
            o_m_axil_wstrb    = Cat(*[m_axil.w.strb   for m_axil in m_axils]),
            o_m_axil_wvalid   = Cat(*[m_axil.w.valid  for m_axil in m_axils]),
            i_m_axil_wready   = Cat(*[m_axil.w.ready  for m_axil in m_axils]),

            # B.
            i_m_axil_bresp    = Cat(*[m_axil.b.resp   for m_axil in m_axils]),
            i_m_axil_bvalid   = Cat(*[m_axil.b.valid  for m_axil in m_axils]),
            o_m_axil_bready   = Cat(*[m_axil.b.ready  for m_axil in m_axils]),

            # AR.
            o_m_axil_araddr   = Cat(*[m_axil.ar.addr  for m_axil in m_axils]),
            o_m_axil_arprot   = Cat(*[Signal(3)      for m_axil in m_axils]),
            o_m_axil_arvalid  = Cat(*[m_axil.ar.valid for m_axil in m_axils]),
            i_m_axil_arready  = Cat(*[m_axil.ar.ready for m_axil in m_axils]),

            # R.
            i_m_axil_rdata    = Cat(*[m_axil.r.data   for m_axil in m_axils]),
            i_m_axil_rresp    = Cat(*[m_axil.r.resp   for m_axil in m_axils]),
            i_m_axil_rvalid   = Cat(*[m_axil.r.valid  for m_axil in m_axils]),
            o_m_axil_rready   = Cat(*[m_axil.r.ready  for m_axil in m_axils]),
        )

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "verilog-axi", "rtl")
        platform.add_source(os.path.join(rtl_dir, "arbiter.v"))
        platform.add_source(os.path.join(rtl_dir, "priority_encoder.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_crossbar.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_crossbar_wr.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_crossbar_rd.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_crossbar_addr.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_register.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_register_rd.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_register_wr.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_reg_if.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_reg_if_rd.v"))
        platform.add_source(os.path.join(rtl_dir, "axil_reg_if_wr.v"))
