#!/usr/bin/env python3

from migen import *
from migen.genlib.cdc import *

from litex.build.generic_platform import *
from litex.build.xilinx import XilinxPlatform
from litex.build.sim import SimPlatform

# IOs ----------------------------------------------------------------------------------------------

_io = [
    ("clk",  0, Pins(1)),
    ("reset", 0, Pins(1)),
    ("gpio",  0, Pins(32)),
    ("test", 0, Pins(32)),
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
class Tb(Module):
    def __init__(self, platform):
        self.clock_domains.cd_sys = ClockDomain()
        reset = platform.request("reset")
        self.comb += [
            self.cd_sys.clk.eq(platform.request("clk")),
            self.cd_sys.rst.eq(reset),
        ]

        self.i2c = Signal()
        self.force = Signal()
        self.invert = Signal()
        self.force_val = Signal(16)

        test = platform.request("test")
        self.comb += [
            self.i2c.eq(test[0]),
            self.force.eq(test[1]),
            self.force_val.eq(test[16:]),
        ]

        FAILING_ADDRESS = 0x17
        i2c_scl = Signal()
        i2c_sda = Signal()
        i2c_scl_d = Signal()
        i2c_sda_d = Signal()
        i2c_ctr = Signal(4)
        i2c_adr_in = Signal(8)
        i2c_dout = Signal(8)
        zero = Signal()
        self.sync += [
            i2c_sda_d.eq(i2c_sda),
            i2c_scl_d.eq(i2c_scl),
        ]
        i2c_sda_controller_drive_low = Signal()
        i2c_sda_peripheral_drive_low = Signal()
        # crappy I2C peripheral emulator just for testing purposes. Because it was faster
        # to write this than try to find a verilog model and adapt it into this purpose.
        # Note: this would never work in any real situation because it doesn't handle noise, spurious edges, etc.
        self.submodules.i2c_peri = i2c_p = FSM(reset_state="IDLE")
        i2c_p.act("IDLE",
            If(i2c_sda_d & ~i2c_sda & i2c_scl & i2c_scl_d, # start condition
                NextValue(i2c_ctr, 8),
                NextState("START_A")
            )
        )
        i2c_p.act("START_A",
            If(i2c_sda_d & ~i2c_sda & i2c_scl & i2c_scl_d, # start condition
                NextValue(i2c_ctr, 8),
                NextState("START_A")
            ).Elif(~i2c_sda_d & i2c_sda & i2c_scl & i2c_scl_d, # stop condition
                NextState("IDLE")
            ).Elif(i2c_scl & ~i2c_scl_d, # rising edge
                NextValue(i2c_ctr, i2c_ctr - 1),
                If(i2c_ctr != 0,
                    NextValue(i2c_adr_in, Cat(i2c_sda, i2c_adr_in[:-1]))
                )
            ).Elif(~i2c_scl & i2c_scl_d, # falling edge
                If(i2c_ctr == 0,
                    NextState("ACK_A")
                )
            )
        )
        i2c_p.act("ACK_A",
            If(i2c_adr_in != FAILING_ADDRESS, # simulate a failure to ACK on the failing address
                i2c_sda_peripheral_drive_low.eq(1),
            ),
            If(~i2c_sda_d & i2c_sda & i2c_scl & i2c_scl_d, # stop condition
                NextState("IDLE")
            ).Elif(~i2c_scl & i2c_scl_d, # falling edge
                NextValue(i2c_dout, ~i2c_adr_in), # reflect the inverse of the address back for testing
                If(i2c_adr_in != FAILING_ADDRESS,
                    NextValue(i2c_ctr, 8),
                    If(i2c_adr_in[0],
                        NextState("RESP_D"),
                    ).Else(
                        NextState("START_A"),
                    )
                ).Else(
                    # on the failing case, just go back to idle because the cycle aborts here
                    NextState("IDLE")
                )
            )
        )
        i2c_p.act("RESP_D",
            If(~i2c_sda_d & i2c_sda & i2c_scl & i2c_scl_d, # stop condition
                NextState("IDLE")
            ).Elif(~i2c_scl & i2c_scl_d, # falling edge
                NextValue(i2c_ctr, i2c_ctr - 1),
                If(i2c_ctr != 0,
                    NextValue(i2c_dout, Cat(zero, i2c_dout[:-1]))
                )
            ).Elif(i2c_scl & ~i2c_scl_d, # rising edge
                If(i2c_ctr == 0,
                    NextState("ACK_D")
                )
            ),
            i2c_sda_controller_drive_low.eq(~i2c_dout[7] & (i2c_ctr != 0))
        )
        i2c_p.act("ACK_D",
            If(~i2c_sda_d & i2c_sda & i2c_scl & i2c_scl_d, # stop condition
                NextState("IDLE")
            ).Elif(~i2c_scl & i2c_scl_d, # falling edge
                NextState("IDLE")
            ),
            # host drives it here
            # i2c_sda_peripheral_drive_low.eq(1),
        )

        self.gpio = platform.request("gpio")
        gpio_o = Signal(32)
        gpio_i = Signal(32)
        gpio_oe = Signal(32)
        for i in range(32):
            self.gpio_ts = TSTriple()
            self.specials += self.gpio_ts.get_tristate(self.gpio[i])
            self.comb += [
                gpio_i[i].eq(self.gpio_ts.i),
                self.gpio_ts.oe.eq(gpio_oe[i]),
                self.gpio_ts.o.eq(gpio_o[i]),
            ]

        for i in range(32):
            if (i == 2): # SDA
                self.comb += [
                    If(self.i2c,
                        i2c_sda.eq(gpio_i[i]),
                        gpio_o[i].eq(0),
                        gpio_oe[i].eq(i2c_sda_controller_drive_low | i2c_sda_peripheral_drive_low),
                    ).Else(
                        If(self.force,
                            gpio_oe[i].eq(1),
                            gpio_o[i].eq(self.force_val[i]),
                        ).Else(
                            gpio_oe[i].eq(0)
                        )
                    )
                ]
                # self.comb += gpio_i[i].eq(0) # for NAK testing
            elif (i == 3): # SCL
                self.comb += [
                    If(self.i2c,
                        i2c_scl.eq(gpio_i[i]),
                    ).Else(
                        If(self.force,
                            gpio_o[i].eq(self.force_val[i]),
                            gpio_oe[i].eq(1),
                        ).Else(
                            gpio_oe[i].eq(0),
                        )
                    )
                ]
            elif (i < 16):
                self.comb += [
                    If(self.force,
                        gpio_o[i].eq(self.force_val[i]),
                        gpio_oe[i].eq(1),
                    ).Else(
                        gpio_oe[i].eq(0),
                        gpio_o[i].eq(0)
                    )
                ]
            else:
                self.comb += [
                    If(self.force,
                        gpio_o[i].eq(~self.force_val[i - 16]),
                        gpio_oe[i].eq(1)
                    ).Else(
                        gpio_oe[i].eq(0)
                    )
                ]

tb = Tb(platform)

# Build --------------------------------------------------------------------------------------------

platform.build(tb, build_dir="../sim_support", build_name="bio_tb")