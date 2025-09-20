#!/usr/bin/env python3

from migen import *
from migen.genlib.cdc import *

from litex.build.generic_platform import *
from litex.build.xilinx import XilinxPlatform
from litex.build.sim import SimPlatform

# IOs ----------------------------------------------------------------------------------------------

_io = [
    ("clk_a",  0, Pins("H17"), IOStandard("LVCMOS33")),

    ("clk_b",  0, Pins("J15"), IOStandard("LVCMOS33")),

    ("in_a", 0, Pins("N17"), IOStandard("LVCMOS33")),
    #("data_a", 0, Pins(16)),

    ("out_b", 0, Pins("E3"), IOStandard("LVCMOS33")),
    #("data_b", 0, Pins(16)),

    ("reset", 0, Pins("C12"), IOStandard("LVCMOS33")),
]

class PulseSynchronizer(Module):
    def __init__(self, idomain, odomain):
        self.i = Signal()
        self.o = Signal()

        ###

        toggle_i = Signal(reset_less=True)
        toggle_o = Signal()  # registered reset_less by MultiReg
        toggle_o_r = Signal(reset_less=True)

        sync_i = getattr(self.sync, idomain)
        sync_o = getattr(self.sync, odomain)

        sync_i += If(self.i, toggle_i.eq(~toggle_i))
        # sync_o += toggle_o.eq(toggle_i) # Require that clocks are mesochronous, e.g., edges aligned but not same rate
        self.specials += MultiReg(toggle_i, toggle_o, odomain, n=1)
        sync_o += toggle_o_r.eq(toggle_o)
        self.comb += self.o.eq(toggle_o ^ toggle_o_r)

# Platform -----------------------------------------------------------------------------------------

class Platform(SimPlatform):
    default_clk_name   = "clk100"
    default_clk_period = 1e9/100e6

    def __init__(self):
        SimPlatform.__init__(self, "generic", _io)# (self, "xc7a100t-csg324-1", _io, toolchain="vivado")

    def build(self, fragment, build_dir, build_name, **kwargs):
        os.makedirs(build_dir, exist_ok=True)
        os.chdir(build_dir)
        conv_output = self.get_verilog(fragment, name=build_name, asic=True)
        conv_output.write(f"{build_name}.v")

# Design -------------------------------------------------------------------------------------------

# Create our platform (fpga interface)
platform = Platform()

# Create our module (fpga description)
class Cdc(Module):
    def __init__(self, platform):
        self.clock_domains.cd_a = ClockDomain()
        self.clock_domains.cd_b = ClockDomain()
        reset = platform.request("reset")
        self.comb += [
            self.cd_a.clk.eq(platform.request("clk_a")),
            self.cd_a.rst.eq(reset),
            self.cd_b.clk.eq(platform.request("clk_b")),
            self.cd_b.rst.eq(reset),
        ]
        in_a = platform.request("in_a")
        out_b = platform.request("out_b")
        self.submodules.xfer = xfer = PulseSynchronizer("a", "b") # was BlindTransfer, but latency is too large for DMA
        self.comb += [
            xfer.i.eq(in_a),
            out_b.eq(xfer.o),
            #xfer.data_i.eq(platform.request("data_a")),
            #platform.request("data_b").eq(xfer.data_o),
        ]

cdc = Cdc(platform)

# Build --------------------------------------------------------------------------------------------

platform.build(cdc, build_dir="sim_support", build_name="cdc_pulse")