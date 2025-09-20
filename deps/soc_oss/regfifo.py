#!/usr/bin/env python3

from migen import *
from migen.genlib.cdc import *
from migen.genlib import fifo

from litex.build.generic_platform import *
from litex.build.xilinx import XilinxPlatform
from litex.build.sim import SimPlatform

# IOs ----------------------------------------------------------------------------------------------

_io = [
    ("aclk",  0, Pins(1)),
    ("reset", 0, Pins(1)),
    ("wdata", 0, Pins(32)),
    ("we", 0, Pins(1)),
    ("writable", 0, Pins(1)),
    ("re", 0, Pins(1)),
    ("readable", 0, Pins(1)),
    ("rdata", 0, Pins(32)),
    ("level", 0, Pins(4)),
]

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
class RegFifo(Module):
    def __init__(self, platform, depth=8):
        self.clock_domains.cd_aclk = ClockDomain()
        reset = platform.request("reset")
        self.comb += [
            self.cd_aclk.clk.eq(platform.request("aclk")),
            self.cd_aclk.rst.eq(reset),
        ]

        self.submodules.fifo = f = ClockDomainsRenamer(
            cd_remapping={"sys":"aclk"})(
                fifo.SyncFIFOBuffered(width=32, depth=depth)
            )
        self.wdata = platform.request("wdata")
        self.we = platform.request("we")
        self.writable = platform.request("writable")
        self.re = platform.request("re")
        self.readable = platform.request("readable")
        self.rdata = platform.request("rdata")
        self.level = platform.request("level")

        self.comb += [
            f.din.eq(self.wdata),
            f.we.eq(self.we),
            self.writable.eq(f.writable),

            self.rdata.eq(f.dout),
            f.re.eq(self.re),
            self.readable.eq(f.readable),

            self.level.eq(f.level),
        ]

cdc = RegFifo(platform)

# Build --------------------------------------------------------------------------------------------

platform.build(cdc, build_dir="../deps/bio", build_name="regfifo")