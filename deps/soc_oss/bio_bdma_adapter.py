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

class BioBdmaAdapter(Module):
    def __init__(self, platform, s_ahb, imem_apb, fifo_apb, dma_ahb, dma_axi, pads, irq, base = 0x12_8000,
        address_width = 12, sim=False,
    ):
        self.logger = logging.getLogger("BioAdapter")

        apb = APBInterface(address_width=address_width)
        self.submodules += AHB2APB(s_ahb, apb, base=base)

        apb_imem = [None, None, None, None]
        for i in range(4):
            apb_imem[i] = APBInterface(address_width=address_width)
            self.submodules += AHB2APB(imem_apb[i], apb_imem[i], base=(base + 0x1000 * (i+1)))

        apb_fifo = [None, None, None, None]
        for i in range(4):
            apb_fifo[i] = APBInterface(address_width=address_width)
            self.submodules += AHB2APB(fifo_apb[i], apb_fifo[i], base=(base + 0x4000 + 0x1000 * (i+1)))

        gpio_i = Signal(32)
        gpio_o = Signal(32)
        gpio_oe = Signal(32)
        if sim:
            self.i2c = Signal()
            self.force = Signal()
            # self.loop_oe = Signal()
            # self.invert = Signal()
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
                                gpio_i[i].eq(self.force_val[i]),
                            ).Else(
                                gpio_i[i].eq(gpio_o[i])
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
                                gpio_i[i].eq(self.force_val[i]),
                            ).Else(
                                gpio_i[i].eq(gpio_o[i])
                            )
                        )
                    ]
                elif (i < 16):
                    self.comb += [
                        If(self.force,
                            gpio_i[i].eq(self.force_val[i]) # loopback oe
                        ).Else(
                            gpio_i[i].eq(gpio_o[i])
                        )
                    ]
                else:
                    self.comb += [
                        If(self.force,
                            gpio_i[i].eq(~self.force_val[i - 16]),
                        ).Else(
                            gpio_i[i].eq(gpio_o[i])
                        )
                    ]
            else:
                self.comb += gpio_i[i].eq(self.gpio.i)

        self.specials += Instance("bio_bdma_wrapper",
            # Parameters.
            # -----------
            p_APW = address_width,

            # Clk / Rst.
            # ----------
            i_fclk = ClockSignal("bio"),
            i_pclk = ClockSignal(),
            i_hclk = ClockSignal("h_clk"),
            i_resetn = ~ResetSignal(),
            i_cmatpg = 0,
            i_cmbist = 0,
            i_sramtrm = 0,

            # APB Slave interface
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

            i_IM0_PADDR                = apb_imem[0].paddr,
            i_IM0_PENABLE              = apb_imem[0].penable,
            i_IM0_PWRITE               = apb_imem[0].pwrite,
            i_IM0_PSTRB                = apb_imem[0].pstrb,
            i_IM0_PPROT                = apb_imem[0].pprot,
            i_IM0_PWDATA               = apb_imem[0].pwdata,
            i_IM0_PSEL                 = apb_imem[0].psel,
            i_IM0_APBACTIVE            = apb_imem[0].pactive,
            o_IM0_PRDATA               = apb_imem[0].prdata,
            o_IM0_PREADY               = apb_imem[0].pready,
            o_IM0_PSLVERR              = apb_imem[0].pslverr,

            i_IM1_PADDR                = apb_imem[1].paddr,
            i_IM1_PENABLE              = apb_imem[1].penable,
            i_IM1_PWRITE               = apb_imem[1].pwrite,
            i_IM1_PSTRB                = apb_imem[1].pstrb,
            i_IM1_PPROT                = apb_imem[1].pprot,
            i_IM1_PWDATA               = apb_imem[1].pwdata,
            i_IM1_PSEL                 = apb_imem[1].psel,
            i_IM1_APBACTIVE            = apb_imem[1].pactive,
            o_IM1_PRDATA               = apb_imem[1].prdata,
            o_IM1_PREADY               = apb_imem[1].pready,
            o_IM1_PSLVERR              = apb_imem[1].pslverr,

            i_IM2_PADDR                = apb_imem[2].paddr,
            i_IM2_PENABLE              = apb_imem[2].penable,
            i_IM2_PWRITE               = apb_imem[2].pwrite,
            i_IM2_PSTRB                = apb_imem[2].pstrb,
            i_IM2_PPROT                = apb_imem[2].pprot,
            i_IM2_PWDATA               = apb_imem[2].pwdata,
            i_IM2_PSEL                 = apb_imem[2].psel,
            i_IM2_APBACTIVE            = apb_imem[2].pactive,
            o_IM2_PRDATA               = apb_imem[2].prdata,
            o_IM2_PREADY               = apb_imem[2].pready,
            o_IM2_PSLVERR              = apb_imem[2].pslverr,

            i_IM3_PADDR                = apb_imem[3].paddr,
            i_IM3_PENABLE              = apb_imem[3].penable,
            i_IM3_PWRITE               = apb_imem[3].pwrite,
            i_IM3_PSTRB                = apb_imem[3].pstrb,
            i_IM3_PPROT                = apb_imem[3].pprot,
            i_IM3_PWDATA               = apb_imem[3].pwdata,
            i_IM3_PSEL                 = apb_imem[3].psel,
            i_IM3_APBACTIVE            = apb_imem[3].pactive,
            o_IM3_PRDATA               = apb_imem[3].prdata,
            o_IM3_PREADY               = apb_imem[3].pready,
            o_IM3_PSLVERR              = apb_imem[3].pslverr,

            i_FP0_PADDR                = apb_fifo[0].paddr,
            i_FP0_PENABLE              = apb_fifo[0].penable,
            i_FP0_PWRITE               = apb_fifo[0].pwrite,
            i_FP0_PSTRB                = apb_fifo[0].pstrb,
            i_FP0_PPROT                = apb_fifo[0].pprot,
            i_FP0_PWDATA               = apb_fifo[0].pwdata,
            i_FP0_PSEL                 = apb_fifo[0].psel,
            i_FP0_APBACTIVE            = apb_fifo[0].pactive,
            o_FP0_PRDATA               = apb_fifo[0].prdata,
            o_FP0_PREADY               = apb_fifo[0].pready,
            o_FP0_PSLVERR              = apb_fifo[0].pslverr,

            i_FP1_PADDR                = apb_fifo[1].paddr,
            i_FP1_PENABLE              = apb_fifo[1].penable,
            i_FP1_PWRITE               = apb_fifo[1].pwrite,
            i_FP1_PSTRB                = apb_fifo[1].pstrb,
            i_FP1_PPROT                = apb_fifo[1].pprot,
            i_FP1_PWDATA               = apb_fifo[1].pwdata,
            i_FP1_PSEL                 = apb_fifo[1].psel,
            i_FP1_APBACTIVE            = apb_fifo[1].pactive,
            o_FP1_PRDATA               = apb_fifo[1].prdata,
            o_FP1_PREADY               = apb_fifo[1].pready,
            o_FP1_PSLVERR              = apb_fifo[1].pslverr,

            i_FP2_PADDR                = apb_fifo[2].paddr,
            i_FP2_PENABLE              = apb_fifo[2].penable,
            i_FP2_PWRITE               = apb_fifo[2].pwrite,
            i_FP2_PSTRB                = apb_fifo[2].pstrb,
            i_FP2_PPROT                = apb_fifo[2].pprot,
            i_FP2_PWDATA               = apb_fifo[2].pwdata,
            i_FP2_PSEL                 = apb_fifo[2].psel,
            i_FP2_APBACTIVE            = apb_fifo[2].pactive,
            o_FP2_PRDATA               = apb_fifo[2].prdata,
            o_FP2_PREADY               = apb_fifo[2].pready,
            o_FP2_PSLVERR              = apb_fifo[2].pslverr,

            i_FP3_PADDR                = apb_fifo[3].paddr,
            i_FP3_PENABLE              = apb_fifo[3].penable,
            i_FP3_PWRITE               = apb_fifo[3].pwrite,
            i_FP3_PSTRB                = apb_fifo[3].pstrb,
            i_FP3_PPROT                = apb_fifo[3].pprot,
            i_FP3_PWDATA               = apb_fifo[3].pwdata,
            i_FP3_PSEL                 = apb_fifo[3].psel,
            i_FP3_APBACTIVE            = apb_fifo[3].pactive,
            o_FP3_PRDATA               = apb_fifo[3].prdata,
            o_FP3_PREADY               = apb_fifo[3].pready,
            o_FP3_PSLVERR              = apb_fifo[3].pslverr,

            # gpio interfaces
            i_gpio_in              = gpio_i,
            o_gpio_out             = gpio_o,
            o_gpio_dir             = gpio_oe, # 1 is output

            # irq interfaces
            o_irq                  = irq,

            # AHB Master interface (for peripheral range)
            o_htrans               = dma_ahb.trans,         # Transfer type
            o_hwrite               = dma_ahb.write,         # Transfer direction
            o_haddr                = dma_ahb.addr,          # Address bus
            o_hsize                = dma_ahb.size,          # Transfer size
            o_hburst               = dma_ahb.burst,         # Burst type
            o_hmasterlock          = dma_ahb.mastlock,      # Locked Sequence
            o_hwdata               = dma_ahb.wdata,         # Write data

            i_hrdata               = dma_ahb.rdata,         # Read data bus
            i_hready               = dma_ahb.readyout,      # HREADY feedback
            i_hresp                = dma_ahb.resp,          # Transfer response
            i_hruser               = 0,

            # AHB NC wires
            o_hsel                 = Open(),         # Slave Select
            o_hprot                = Open(),         # Protection control
            o_hmaster              = Open(),         # Master select
            i_hreadym              = Open(),         # Transfer done
            o_hauser               = Open(),
            o_hwuser               = Open(),

            # AXI Master interface (for main memory range)
            o_aw_id        = dma_axi.aw.id,
            o_aw_addr      = dma_axi.aw.addr,
            o_aw_len       = dma_axi.aw.len,
            o_aw_size      = dma_axi.aw.size,
            o_aw_burst     = dma_axi.aw.burst,
            o_aw_lock      = dma_axi.aw.lock,
            o_aw_cache     = dma_axi.aw.cache,
            o_aw_prot      = dma_axi.aw.prot,
            o_aw_qos       = dma_axi.aw.qos,
            o_aw_region    = dma_axi.aw.region,
            # o_aw_atop      = dma_axi.aw.atop,
            o_aw_user      = dma_axi.aw.user,
            o_aw_valid     = dma_axi.aw.valid,
            i_aw_ready     = dma_axi.aw.ready,

            o_w_data       = dma_axi.w.data   ,
            o_w_strb       = dma_axi.w.strb   ,
            o_w_last       = dma_axi.w.last   ,
            o_w_user       = dma_axi.w.user   ,
            o_w_valid      = dma_axi.w.valid  ,
            i_w_ready      = dma_axi.w.ready  ,

            i_b_id         = dma_axi.b.id     ,
            i_b_resp       = dma_axi.b.resp   ,
            i_b_user       = dma_axi.b.user   ,
            i_b_valid      = dma_axi.b.valid  ,
            o_b_ready      = dma_axi.b.ready  ,

            o_ar_id        = dma_axi.ar.id    ,
            o_ar_addr      = dma_axi.ar.addr  ,
            o_ar_len       = dma_axi.ar.len   ,
            o_ar_size      = dma_axi.ar.size  ,
            o_ar_burst     = dma_axi.ar.burst ,
            o_ar_lock      = dma_axi.ar.lock  ,
            o_ar_cache     = dma_axi.ar.cache ,
            o_ar_prot      = dma_axi.ar.prot  ,
            o_ar_qos       = dma_axi.ar.qos   ,
            o_ar_region    = dma_axi.ar.region,
            o_ar_user      = dma_axi.ar.user  ,
            o_ar_valid     = dma_axi.ar.valid ,
            i_ar_ready     = dma_axi.ar.ready ,

            i_r_id         = dma_axi.r.id     ,
            i_r_data       = dma_axi.r.data   ,
            i_r_resp       = dma_axi.r.resp   ,
            i_r_last       = dma_axi.r.last   ,
            i_r_user       = dma_axi.r.user   ,
            i_r_valid      = dma_axi.r.valid  ,
            o_r_ready      = dma_axi.r.ready  ,
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
        platform.add_source(os.path.join(rtl_dir, "gnrl_sramc_pkg.sv"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "model", "rtl")
        platform.add_source(os.path.join(rtl_dir, "icg.v"))
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "amba", "rtl")
        platform.add_source(os.path.join(rtl_dir, "amba_components.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "asic_top", "rtl")
        platform.add_source(os.path.join(rtl_dir, "daric_cfg_pkg.sv"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "rtl", "modules", "bio_bdma", "rtl")
        platform.add_source(os.path.join(rtl_dir, "bio_bdma_wrapper.sv"))
        platform.add_source(os.path.join(rtl_dir, "bio_bdma.sv"))
        platform.add_source(os.path.join(rtl_dir, "picorv32.v"))
        platform.add_source(os.path.join(rtl_dir, "pio_divider.v"))
        platform.add_source(os.path.join(rtl_dir, "ram_1rw_s.sv"))
        platform.add_source(os.path.join(rtl_dir, "regfifo.v"))

        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "..", "verilate", "sim_support")
        platform.add_source(os.path.join(rtl_dir, "cdc_blinded.v"))
        platform.add_source(os.path.join(rtl_dir, "cdc_level_to_pulse.sv"))
        platform.add_source(os.path.join(rtl_dir, "bioram1kx32.v"))
