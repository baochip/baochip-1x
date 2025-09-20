#
# Adapt PIO to LiteX native bus interface
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
from litex.soc.interconnect import ahb
from soc_oss.axi_common import *
from .apb import *
from litex.soc.interconnect.csr import *

# AHB to APB to BIO --------------------------------------------------------------------------

class BioAdapter(Module):
    def __init__(self, platform, s_ahb, pads, irq, base = 0x12_4000,
        address_width = 13, sim=False,
    ):
        self.logger = logging.getLogger("BioAdapter")

        apb = APBInterface(address_width=address_width)
        self.submodules += AHB2APB(s_ahb, apb, base=base)

        gpio_i = Signal(32)
        gpio_o = Signal(32)
        gpio_oe = Signal(32)
        if sim:
            self.i2c = Signal()
            self.force = Signal()
            self.loop_oe = Signal()
            self.invert = Signal()
            self.force_val = Signal(16)

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
                i2c_sda_controller_drive_low.eq(~i2c_dout[7])
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

            self.comb += [
                i2c_sda.eq(~(i2c_sda_controller_drive_low | gpio_oe[2] | i2c_sda_peripheral_drive_low)), # fake I2C wire-OR
            ]
        for i in range(32):
            self.gpio = TSTriple()
            self.specials += self.gpio.get_tristate(pads.gpio[i])
            self.comb += [
                self.gpio.o.eq(gpio_o[i]),
                self.gpio.oe.eq(gpio_oe[i]),
            ]
            if sim:
                if (i == 2): # SDA
                    self.comb += [
                        If(self.i2c,
                            gpio_i[i].eq(i2c_sda)
                        ).Else(
                            If(self.force,
                                gpio_i[i].eq(self.force_val[i - 16]),
                            ).Elif(self.loop_oe,
                                gpio_i[i].eq(gpio_oe[i]) # loopback oe
                            ).Else(
                                gpio_i[i].eq(gpio_o[i] ^ self.invert) # loopback o for testing
                            )
                        )
                    ]
                    # self.comb += gpio_i[i].eq(0) # for NAK testing
                elif (i == 3): # SCL
                    self.comb += [
                        If(self.i2c,
                            gpio_i[i].eq(~gpio_oe[i]), # funky setup to try and "fake" some I2C-ish pullups
                            i2c_scl.eq(~gpio_oe[i])
                        ).Else(
                            If(self.force,
                                gpio_i[i].eq(self.force_val[i - 16]),
                            ).Elif(self.loop_oe,
                                gpio_i[i].eq(gpio_oe[i]) # loopback oe
                            ).Else(
                                gpio_i[i].eq(gpio_o[i] ^ self.invert) # loopback o for testing
                            )
                        )
                    ]
                elif (i < 16):
                    self.comb += [
                        If(self.loop_oe,
                            gpio_i[i].eq(gpio_oe[i]) # loopback oe
                        ).Else(
                            gpio_i[i].eq(gpio_o[i] ^ self.invert) # loopback o for testing
                        )
                    ]
                else:
                    self.comb += [
                        If(self.force,
                            gpio_i[i].eq(self.force_val[i - 16]),
                        ).Elif(self.loop_oe,
                            gpio_i[i].eq(gpio_oe[i]) # loopback oe
                        ).Else(
                            gpio_i[i].eq(gpio_o[i] ^ self.invert) # loopback o for testing
                        )
                    ]
            else:
                self.comb += gpio_i[i].eq(self.gpio.i)

        self.specials += Instance("bio_apb",
            # Parameters.
            # -----------
            p_AW = 13,

            # Clk / Rst.
            # ----------
            i_fclk = ClockSignal("bio"),
            i_pclk = ClockSignal(),
            i_resetn = ~ResetSignal(),
            i_cmatpg = Open(),
            i_cmbist = Open(),

            # AHB Slave interface
            # --------------------------
            i_PADDR                = apb.paddr,
            i_PENABLE              = apb.penable,
            i_PWRITE               = apb.pwrite,
            i_PSTRB                = apb.pstrb,
            i_PPROT                = apb.pprot,
            i_PWDATA               = apb.pwdata,
            i_PSEL                 = apb.psel,
            i_APBACTIVE            = apb.pactive,
            o_PRDATA               = apb.prdata,
            o_PREADY               = apb.pready,
            o_PSLVERR              = apb.pslverr,

            # gpio interfaces
            i_gpio_in              = gpio_i,
            o_gpio_out             = gpio_o,
            o_gpio_dir             = gpio_oe, # 1 is output

            # irq interfaces
            o_irq                  = irq,
        )

        # Add Sources.
        # ------------
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "ips", "axi-master", "src")
        platform.add_source(os.path.join(rtl_dir, "axi_pkg.sv"))
        platform.add_source(os.path.join(rtl_dir, "axi_intf.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "common", "rtl")
        platform.add_source(os.path.join(rtl_dir, "amba_interface_def.sv"))
        platform.add_source(os.path.join(rtl_dir, "io_interface_def.sv"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "model", "rtl")
        platform.add_source(os.path.join(rtl_dir, "icg.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "bio_bdma", "rtl")
        platform.add_source(os.path.join(rtl_dir, "bio_wrapper.sv"))
        platform.add_source(os.path.join(rtl_dir, "bio.sv"))
        platform.add_source(os.path.join(rtl_dir, "picorv32.v"))
        platform.add_source(os.path.join(rtl_dir, "pio_divider.v"))
        platform.add_source(os.path.join(rtl_dir, "ram_1w_4rs.sv"))
        platform.add_source(os.path.join(rtl_dir, "regfifo.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "verilate", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "cdc_blinded.v"))
