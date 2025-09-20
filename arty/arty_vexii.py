#!/usr/bin/env python3

#
# This file is part of LiteX-Boards.
#
# Copyright (c) 2015-2019 Florent Kermarrec <florent@enjoy-digital.fr>
# Copyright (c) 2020 Antmicro <www.antmicro.com>
# Copyright (c) 2022 Victor Suarez Rovere <suarezvictor@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause

# Note: For now with --toolchain=yosys+nextpnr:
# - DDR3 should be disabled: ex --integrated-main-ram-size=8192
# - Clk Freq should be lowered: ex --sys-clk-freq=50e6

# Complied with: --build --no-uart --cpu-reset-address 0x40000000 --cpu-variant imac+debug --integrated-rom-size 0
# Sim config: "--sim --no-compile-software --no-uart --cpu-type vexiiriscv --cpu-variant standard --integrated-rom-size 65536 --integrated-sram-size 8192 --integrated-main-ram-size 131072"

from migen import *

from litex.gen import *

import digilent_arty

from litex.soc.cores.clock import *
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.cores.led import LedChaser
from litex.soc.cores.gpio import GPIOIn, GPIOTristate
from litex.soc.cores.xadc import XADC
from litex.soc.cores.dna  import DNA

from litex.soc.interconnect.csr import *

from litedram.modules import MT41K128M16
from litedram.phy import s7ddrphy
from liteeth.phy.mii import LiteEthPHYMII

import multiprocessing
VEX_CPU_PATH="VexiiRiscv/VexiiRiscv.sv"
# VEX_CPU_PATH="VexRiscv_BetrustedSoC.v"
from pathlib import Path
import shutil
import shlex
import subprocess
# This changes depending on the Vivado version on the host!
VIVADO_PATH = 'C:\\Xilinx\\Vivado\\2022.2\\bin\\'
from elftools.elf.elffile import ELFFile
import io

from functools import reduce
from operator import or_

from litex.soc.interconnect.wishbone import CTI_BURST_INCREMENTING, CTI_BURST_END
from litex.soc.interconnect import wishbone

# CRG ----------------------------------------------------------------------------------------------

class _CRG(LiteXModule):
    def __init__(self, platform, sys_clk_freq, with_dram=True, with_rst=True):
        self.rst    = Signal()
        self.cd_sys = ClockDomain()
        # self.cd_eth = ClockDomain()
        if with_dram:
            self.cd_sys4x     = ClockDomain()
            self.cd_sys4x_dqs = ClockDomain()
            self.cd_idelay    = ClockDomain()

        # # #
        self.cd_p   = ClockDomain()
        # self.cd_h_clk = ClockDomain()
        self.cd_bio = ClockDomain()

        # Clk/Rst.
        clk100 = platform.request("clk100")
        rst    = ~platform.request("cpu_reset") if with_rst else 0

        # PLL.
        self.pll = pll = S7PLL(speedgrade=-1)
        self.comb += pll.reset.eq(rst | self.rst)
        pll.register_clkin(clk100, 100e6)
        pll.create_clkout(self.cd_sys, sys_clk_freq)
        # pll.create_clkout(self.cd_eth, 25e6)
        pll.create_clkout(self.cd_p, sys_clk_freq)
        # pll.create_clkout(self.cd_h_clk, sys_clk_freq)
        pll.create_clkout(self.cd_bio, 2*sys_clk_freq)

        # self.comb += platform.request("eth_ref_clk").eq(self.cd_eth.clk)
        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.
        if with_dram:
            pll.create_clkout(self.cd_sys4x,     4*sys_clk_freq)
            pll.create_clkout(self.cd_sys4x_dqs, 4*sys_clk_freq, phase=90)
            pll.create_clkout(self.cd_idelay,    200e6)

        # IdelayCtrl.
        if with_dram:
            self.idelayctrl = S7IDELAYCTRL(self.cd_idelay)

class RGBLEDBank(Module, AutoCSR):
    def __init__(self, pads):
        # 3 bits per LED x 4 LEDs = 12 bits
        self._out = CSRStorage(12)
        self.comb += [
            pads[0].r.eq(self._out.storage[0]),
            pads[0].g.eq(self._out.storage[1]),
            pads[0].b.eq(self._out.storage[2]),
            pads[1].r.eq(self._out.storage[3]),
            pads[1].g.eq(self._out.storage[4]),
            pads[1].b.eq(self._out.storage[5]),
            pads[2].r.eq(self._out.storage[6]),
            pads[2].g.eq(self._out.storage[7]),
            pads[2].b.eq(self._out.storage[8]),
            pads[3].r.eq(self._out.storage[9]),
            pads[3].g.eq(self._out.storage[10]),
            pads[3].b.eq(self._out.storage[11]),
        ]

class VexLegacyInt(Module, AutoCSR):
    def __init__(self, mach_int, super_int):
        self.interrupts = Signal(32)
        self.interrupts_sync = Signal(32)
        self.mach_mask = CSRStorage(size=32, name="mach_mask", description="Machine IRQ mask")
        self.mach_pending = CSRStatus(size=32, name="mach_pending", description="Machine IRQ pending")
        self.super_mask = CSRStorage(size=32, name="super_mask", description="Supervisor IRQ mask")
        self.super_pending = CSRStatus(size=32, name="super_pending", description="Supervisor IRQ pending")
        extint_mach = Signal(32)
        extint_super = Signal(32)
        self.sync += self.interrupts_sync.eq(self.interrupts)
        self.comb += [
            extint_mach.eq(self.interrupts_sync & self.mach_mask.storage),
            extint_super.eq(self.interrupts_sync & self.super_mask.storage),
            mach_int.eq(reduce(or_, [extint_mach[i] for i in range(32)])),
            super_int.eq(reduce(or_, [extint_super[i] for i in range(32)])),
            self.mach_pending.status.eq(extint_mach),
            self.super_pending.status.eq(extint_super),
        ]

class CsrTest(Module, AutoCSR, AutoDoc):
    def __init__(self):
        self.csr_wtest = CSRStorage(32, name="wtest", description="Write test data here")
        self.csr_rtest = CSRStatus(32, name="rtest", description="Read test data here")
        self.comb += [
            self.csr_rtest.status.eq(self.csr_wtest.storage + 0x1000_0000)
        ]

# Wishbone SRAM ------------------------------------------------------------------------------------

class CoherencyTest(Module, AutoCSR, AutoDoc):
    def __init__(self, mem_or_size, read_only=None, init=None, bus=None, name=None):
        self.seed = CSRStorage(32, name="seed", description="Seed for test data")
        self.length = CSRStorage(16, name="length", description="Length to run")
        self.start = CSRStorage(16, name="start", description="Start of region to overwrite")
        self.control = CSRStorage(fields=[
            CSRField("go", size = 1, description="Write `1` to start overwriting", pulse=True)
        ])
        self.stat = CSRStatus(fields=[
            CSRField("done", size=1, description="Indicates that a run is finished. Reset when `go` is pulsed")
        ])
        done = Signal()
        self.comb += [
            self.stat.fields.done.eq(done),
        ]
        init = mem_or_size * [0]

        if bus is None:
            print("not supported")
            exit(1)
        self.bus = bus
        bus_data_width = len(self.bus.dat_r)
        if isinstance(mem_or_size, Memory):
            assert(mem_or_size.width <= bus_data_width)
            self.mem = mem_or_size
        else:
            self.mem = Memory(bus_data_width, mem_or_size//(bus_data_width//8), init=init, name=name)

        if read_only is None:
            if hasattr(self.mem, "bus_read_only"):
                read_only = self.mem.bus_read_only
            else:
                read_only = False

        # # #

        adr_burst = Signal()

        # Burst support.
        # --------------

        if self.bus.bursting:
            adr_wrap_mask = Array((0b0000, 0b0011, 0b0111, 0b1111))
            adr_wrap_max  = adr_wrap_mask[-1].bit_length()

            adr_burst_wrap = Signal()
            adr_latched    = Signal()

            adr_counter        = Signal(len(self.bus.adr))
            adr_counter_base   = Signal(len(self.bus.adr))
            adr_counter_offset = Signal(adr_wrap_max)
            adr_offset_lsb     = Signal(adr_wrap_max)
            adr_offset_msb     = Signal(len(self.bus.adr))

            adr_next = Signal(len(self.bus.adr))

            # Only Incrementing Burts are supported.
            self.comb += [
                Case(self.bus.cti, {
                    # incrementing address burst cycle
                    CTI_BURST_INCREMENTING: adr_burst.eq(1),
                    # end current burst cycle
                    CTI_BURST_END: adr_burst.eq(0),
                    # unsupported burst cycle
                    "default": adr_burst.eq(0)
                }),
                adr_burst_wrap.eq(self.bus.bte[0] | self.bus.bte[1]),
                adr_counter_base.eq(
                    Cat(self.bus.adr & ~adr_wrap_mask[self.bus.bte],
                       self.bus.adr[adr_wrap_max:]
                    )
                )
            ]

            # Latch initial address (without wrapping bits and wrap offset).
            self.sync += [
                If(self.bus.cyc & self.bus.stb & adr_burst,
                    adr_latched.eq(1),
                    # Latch initial address, then increment it every clock cycle
                    If(adr_latched,
                        adr_counter.eq(adr_counter + 1)
                    ).Else(
                        adr_counter_offset.eq(self.bus.adr & adr_wrap_mask[self.bus.bte]),
                        adr_counter.eq(adr_counter_base +
                            Cat(~self.bus.we, Replicate(0, len(adr_counter)-1))
                        )
                    ),
                    If(self.bus.cti == CTI_BURST_END,
                        adr_latched.eq(0),
                        adr_counter.eq(0),
                        adr_counter_offset.eq(0)
                    )
                ).Else(
                    adr_latched.eq(0),
                    adr_counter.eq(0),
                    adr_counter_offset.eq(0)
                ),
            ]

            # Next Address = counter value without wrapped bits + wrapped counter bits with offset.
            self.comb += [
                adr_offset_lsb.eq((adr_counter + adr_counter_offset) & adr_wrap_mask[self.bus.bte]),
                adr_offset_msb.eq(adr_counter & ~adr_wrap_mask[self.bus.bte]),
                adr_next.eq(adr_offset_msb + adr_offset_lsb)
            ]

        # # #

        # Memory.
        # -------
        port = self.mem.get_port(write_capable=not read_only, we_granularity=8,
            mode=READ_FIRST if read_only else WRITE_FIRST)
        self.specials += self.mem, port
        # Generate write enable signal
        if not read_only:
            self.comb += [port.we[i].eq(self.bus.cyc & self.bus.stb & self.bus.we & self.bus.sel[i])
                for i in range(bus_data_width//8)]
        # Address and data
        self.comb += port.adr.eq(self.bus.adr[:len(port.adr)])
        if self.bus.bursting:
            self.comb += If(adr_burst & adr_latched,
                port.adr.eq(adr_next[:len(port.adr)]),
            )
        self.comb += [
            self.bus.dat_r.eq(port.dat_r)
        ]
        if not read_only:
            self.comb += port.dat_w.eq(self.bus.dat_w),

        # Generate Ack.
        self.sync += [
            self.bus.ack.eq(0),
            If(self.bus.cyc & self.bus.stb & (~self.bus.ack | adr_burst), self.bus.ack.eq(1))
        ]

        testport = self.mem.get_port(write_capable=True, we_granularity=32, mode=WRITE_FIRST)
        self.specials += testport
        self.submodules.test_ram_fsm = fsm = FSM(reset_state="IDLE")
        count = Signal(32)
        stop = Signal(32)
        value = Signal(32)
        self.comb += [
            testport.adr.eq(count),
            testport.dat_w.eq(value),
            stop.eq(self.start.storage + self.length.storage),
        ]
        fsm.act("IDLE",
            testport.we.eq(0),
            If(self.control.fields.go,
                NextValue(count, self.start.storage),
                NextValue(value, self.seed.storage),
                NextState("RUN"),
                NextValue(done, 0),
            ).Else(
                NextValue(count, self.start.storage),
                NextValue(value, self.seed.storage),
                NextState("IDLE")
            )
        )
        fsm.act("RUN",
            testport.we.eq(0xf),
            NextValue(count, count + 1),
            NextValue(value, value + 1),
            If(count == stop - 1,
                NextState("IDLE"),
                NextValue(done, 1),
            ).Else(
                NextState("RUN")
            )
        )

# BaseSoC ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, variant="a7-35", toolchain="vivado", sys_clk_freq=100e6,
        with_xadc       = False,
        with_dna        = False,
        with_ethernet   = False,
        with_etherbone  = False,
        eth_ip          = "192.168.1.50",
        remote_ip       = None,
        eth_dynamic_ip  = False,
        with_usb        = False,
        with_led_chaser = True,
        with_spi_flash  = False,
        with_buttons    = False,
        with_pmod_gpio  = False,
        with_can        = False,
        sim             = False,
        **kwargs):
        platform = digilent_arty.Platform(variant=variant, toolchain=toolchain)

        # CRG --------------------------------------------------------------------------------------
        with_dram = (kwargs.get("integrated_main_ram_size", 0) == 0)
        self.crg  = _CRG(platform, sys_clk_freq, with_dram)

        # SoCCore ----------------------------------------------------------------------------------
        SoCCore.__init__(self,
                         platform,
                         sys_clk_freq,
                         # cpu_reset_address=0x6000_0000,
                         # cpu_variant="imac+debug",
                         ident="BIO on Arty A7", **kwargs
                    )
        if True:
            self.legacy_int = VexLegacyInt(self.cpu.m_ext, self.cpu.s_ext)
            self.comb += [
                self.legacy_int.interrupts.eq(self.cpu.interrupt)
            ]
        else:
            # dummy block just for code compatibility
            self.m_ext = Signal()
            self.s_ext = Signal()
            self.legacy_int = VexLegacyInt(self.m_ext, self.s_ext)
            self.cpu.set_reset_address(0x8000_0000)

        self.add_csr("legacy_int")

        # self.add_ram("betrusted_ram", 0x4000_0000, 131072)
        from litex.soc.integration.soc import SoCRegion
        test_bus = wishbone.Interface(data_width=self.bus.data_width, address_width=self.bus.address_width, bursting=self.bus.bursting)
        test_ram = CoherencyTest(0x1_0000, bus=test_bus, init=[], read_only=False, name="test_ram")
        test_region = SoCRegion(origin=0x5000_0000, size=0x1_0000, mode="rwx")
        self.bus.add_slave("test_ram", test_ram.bus, test_region)
        self.add_module(name="test_ram", module=test_ram)
        self.add_config("test_ram_INIT", 1)

        # XADC -------------------------------------------------------------------------------------
        if with_xadc:
            self.xadc = XADC()

        # DNA --------------------------------------------------------------------------------------
        if with_dna:
            self.dna = DNA()
            self.dna.add_timing_constraints(platform, sys_clk_freq, self.crg.cd_sys.clk)

        # DDR3 SDRAM -------------------------------------------------------------------------------
        if not self.integrated_main_ram_size:
            self.ddrphy = s7ddrphy.A7DDRPHY(platform.request("ddram"),
                memtype        = "DDR3",
                nphases        = 4,
                sys_clk_freq   = sys_clk_freq)
            self.add_sdram("sdram",
                phy           = self.ddrphy,
                module        = MT41K128M16(sys_clk_freq, "1:4"),
                l2_cache_size = kwargs.get("l2_size", 8192)
            )

        # Ethernet / Etherbone ---------------------------------------------------------------------
        if with_ethernet or with_etherbone:
            self.ethphy = LiteEthPHYMII(
                clock_pads = self.platform.request("eth_clocks"),
                pads       = self.platform.request("eth"))
            if with_etherbone:
                self.add_etherbone(phy=self.ethphy, ip_address=eth_ip)
            elif with_ethernet:
                self.add_ethernet(phy=self.ethphy, dynamic_ip=eth_dynamic_ip, local_ip=eth_ip, remote_ip=remote_ip)

        # SPI Flash --------------------------------------------------------------------------------
        if with_spi_flash:
            from litespi.modules import S25FL128L
            from litespi.opcodes import SpiNorFlashOpCodes as Codes
            self.add_spi_flash(mode="4x", module=S25FL128L(Codes.READ_1_1_4), rate="1:2", with_master=True)

        # USB-OHCI ---------------------------------------------------------------------------------
        if with_usb:
            from litex.soc.cores.usb_ohci import USBOHCI
            from litex.build.generic_platform import Subsignal, Pins, IOStandard

            self.crg.cd_usb = ClockDomain()
            self.crg.pll.create_clkout(self.crg.cd_usb, 48e6, margin=0)

            # Machdyne PMOD (https://github.com/machdyne/usb_host_dual_socket_pmod)
            _usb_pmod_ios = [
                ("usb_pmoda", 0, # USB1 (top socket)
                    Subsignal("dp", Pins("pmoda:2")),
                    Subsignal("dm", Pins("pmoda:3")),
                    IOStandard("LVCMOS33"),
                ),
                ("usb_pmoda", 1, # USB2 (bottom socket)
                    Subsignal("dp", Pins("pmoda:0")),
                    Subsignal("dm", Pins("pmoda:1")),
                    IOStandard("LVCMOS33"),
                )
            ]
            self.platform.add_extension(_usb_pmod_ios)

            self.submodules.usb_ohci = USBOHCI(self.platform, self.platform.request("usb_pmoda", 0), usb_clk_freq=int(48e6))
            self.mem_map["usb_ohci"] = 0xc0000000
            self.bus.add_slave("usb_ohci_ctrl", self.usb_ohci.wb_ctrl, region=SoCRegion(origin=self.mem_map["usb_ohci"], size=0x100000, cached=False)) # FIXME: Mapping.
            self.dma_bus.add_master("usb_ohci_dma", master=self.usb_ohci.wb_dma)

            self.comb += self.cpu.interrupt[16].eq(self.usb_ohci.interrupt)

        # Leds -------------------------------------------------------------------------------------
        if with_led_chaser:
            self.leds = LedChaser(
                pads         = platform.request_all("user_led"),
                sys_clk_freq = sys_clk_freq,
            )
        pads = [platform.request("rgb_led", i) for i in range(4)]
        self.submodules.rgb = RGBLEDBank(pads)
        self.add_csr("rgb")

        # Buttons ----------------------------------------------------------------------------------
        if with_buttons:
            self.buttons = GPIOIn(
                pads     = platform.request_all("user_btn"),
                with_irq = self.irq.enabled
            )

        # GPIOs ------------------------------------------------------------------------------------
        if with_pmod_gpio:
            platform.add_extension(digilent_arty.raw_pmod_io("pmoda"))
            self.gpio = GPIOTristate(
                pads     = platform.request("pmoda"),
                with_irq = self.irq.enabled
            )

        # CAN --------------------------------------------------------------------------------------
        if with_can:
            from litex.soc.cores.can.ctu_can_fd import CTUCANFD
            self.platform.add_extension(digilent_arty.can_pmod_io("pmodc", 0))
            self.can0 = CTUCANFD(platform, platform.request("can", 0))
            self.bus.add_slave("can0", self.can0.bus, SoCRegion(origin=0xb0010000, size=0x10000, mode="rw", cached=False))
            self.irq.add("can0")

        self.add_uartbone(name="serial", baudrate=1_000_000)

        # UART -------------------------------------------------------------------------------------
        if True:
            from litex.build.generic_platform import Subsignal, Pins, IOStandard
            if sim:
                sim_uart = [
                    ("serial", 0,
                        Subsignal("source_valid", Pins(1)),
                        Subsignal("source_ready", Pins(1)),
                        Subsignal("sink_ready", Pins(1)),
                        Subsignal("sink_valid", Pins(1)),
                        Subsignal("source_data", Pins(8)),
                        Subsignal("sink_data", Pins(8)),
                    )
                ]
                self.platform.add_extension(sim_uart)
                self.add_uart("uart", "sim", 1_000_000)
            else:
                duart = [
                    ("duart", 0,
                        Subsignal("tx", Pins("ck_io:ck_io40")),
                        Subsignal("rx", Pins("ck_io:ck_io41")),
                        IOStandard("LVCMOS33"),
                    )
                ]
                self.platform.add_extension(duart)
                self.add_uart("uart", "duart", 115200)

        # BIO --------------------------------------------------------------------------------------
        if True:
            from litex.soc.integration.soc import SoCRegion, SoCIORegion
            from litex.soc.interconnect.axi import AXIInterface, AXILiteInterface
            from soc_oss.axil_ahb_adapter import AXILite2AHBAdapter
            from soc_oss.axil_crossbar import AXILiteCrossbar
            from soc_oss.axil_cdc import AXILiteCDC
            from litex.soc.interconnect import ahb
            from soc_oss.ahb_axi_adapter import AHB2AxiAdapter
            from soc_oss.axi_adapter import AXIAdapter
            from soc_oss.axi_axil_adapter import AXI2AXILiteAdapter
            from litex.build.generic_platform import Subsignal, Pins, IOStandard

            self.platform.add_platform_command("set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets bio_clk]")
            self.platform.add_platform_command('set_false_path -through [get_nets *_rst]')

            pio = [
                ("pio", 0,
                    Subsignal("gpio", Pins(" ".join([f"ck_io:ck_io{i:d}" for i in range(32)]))),
                    IOStandard("LVCMOS33"),
                )
            ]
            self.platform.add_extension(pio)
            rtl_dir = os.path.join(os.path.dirname(__file__), "deps", "bio", "soc")
            self.platform.add_source(os.path.join(rtl_dir, "template.sv"))
            self.platform.add_source(os.path.join(rtl_dir, "apb_sfr_v0.1.sv"))
            self.platform.add_source(os.path.join(rtl_dir, "amba_components_v0.2.sv"))

            rtl_dir = os.path.join(os.path.dirname(__file__), "deps", "verilog-axi", "rtl")
            platform.add_source(os.path.join(rtl_dir, "axil_cdc_wr.v"))
            platform.add_source(os.path.join(rtl_dir, "axil_cdc_rd.v"))
            platform.add_source(os.path.join(rtl_dir, "axil_cdc.v"))

            name = "bio_bdma"
            bio_irq = Signal(4) # TODO: wire this up.

            region = [0x9000_0000, 0x0_1000]
            self.submodules.pxbar = pxbar = AXILiteCrossbar(platform)

            p_axil = AXILiteInterface(name="pbus", bursting = False)
            pxbar.add_slave(
                name = "p_axil", s_axil = p_axil,
            )
            self.bus.add_slave("bio", p_axil, SoCRegion(origin=0x9000_0000, size=0x1_0000, mode="rw", cached=False))

            # Convert to 64-bits for the main memory crossbar
            dma_axi = AXIInterface(data_width=32, address_width=32, id_width=4, bursting=False)
            self.bus.add_master(name="biobdma", master=dma_axi)

            # convert AHB to AXIL for peripheral integration
            ahb_from_dma = ahb.AHBInterface(data_width=32, address_width=32)
            axi_from_dma = AXIInterface(data_width=32, address_width=32, id_width=1, bursting=True)
            ahb2axi = AHB2AxiAdapter(platform, m_axi=axi_from_dma, s_ahb=ahb_from_dma)
            self.submodules += ahb2axi

            dma_axil = AXILiteInterface(name="dma_pbus", bursting = False)
            self.submodules += AXI2AXILiteAdapter(platform, axi_from_dma, dma_axil)
            pxbar.add_slave(
                name = "dma_axil", s_axil = dma_axil,
            )

            setattr(self, name + "_region", SoCIORegion(region[0], region[1], mode="rw", cached=False))
            setattr(self, name + "_axil", AXILiteInterface(name=name + "_axil"))
            pxbar.add_master(
                name = name,
                m_axil = getattr(self, name + "_axil"),
                origin = region[0],
                size = region[1],
            )
            setattr(self, name + "_ahb", ahb.AHBInterface())
            self.submodules += AXILite2AHBAdapter(platform,
                            getattr(self, name + "_axil"),
                            getattr(self, name + "_ahb")
            )

            # build subordinate page mapping list
            bdma_imem = []
            for i in range(4):
                imem_name = f'bio_bdma_imem{i}'
                setattr(self, imem_name + "_region", SoCIORegion(region[0] + (i + 1) * 0x1000, region[1], mode="rw", cached=False))
                setattr(self, imem_name + "_axil", AXILiteInterface(name=f'bio_bdma_imem{i}' + "_axil"))
                pxbar.add_master(
                    name = imem_name,
                    m_axil = getattr(self, imem_name + "_axil"),
                    origin = region[0] + (i + 1) * 0x1000,
                    size = region[1],
                )
                setattr(self, imem_name + "_ahb", ahb.AHBInterface())
                self.submodules += AXILite2AHBAdapter(platform,
                    getattr(self, imem_name + "_axil"),
                    getattr(self, imem_name + "_ahb")
                )
                bdma_imem += [getattr(self, imem_name + "_ahb")]
            # build fifo page mapping list
            bdma_fifo = []
            for i in range(4):
                fifo_name = f'bio_bdma_fifo{i}'
                setattr(self, fifo_name + "_region", SoCIORegion(region[0] + 0x4000 + (i + 1) * 0x1000, region[1], mode="rw", cached=False))
                setattr(self, fifo_name + "_axil", AXILiteInterface(name=f'bio_bdma_fifo{i}' + "_axil"))
                pxbar.add_master(
                    name = fifo_name,
                    m_axil = getattr(self, fifo_name + "_axil"),
                    origin = region[0] + 0x4000 + (i + 1) * 0x1000,
                    size = region[1],
                )
                setattr(self, fifo_name + "_ahb", ahb.AHBInterface())
                self.submodules += AXILite2AHBAdapter(platform,
                    getattr(self, fifo_name + "_axil"),
                    getattr(self, fifo_name + "_ahb")
                )
                bdma_fifo += [getattr(self, fifo_name + "_ahb")]

            from soc_oss.bio_bdma_adapter import BioBdmaAdapter
            clock_remap = {"h_clk" : "sys"}
            self.submodules.bioadapter = ClockDomainsRenamer(clock_remap)(BioBdmaAdapter(platform,
                getattr(self, name + "_ahb"),
                bdma_imem,
                bdma_fifo,
                ahb_from_dma,
                dma_axi,
                platform.request("pio"), bio_irq,
                base=(region[0] & 0xFF_FFFF), address_width=log2_int(region[1], need_pow2=True),
                sim=False
            ))
            if False:
                self.comb += [
                    pio_irq0.eq(bio_irq[0]),
                    pio_irq1.eq(bio_irq[1]),
                ]
                if variant == "sim":
                    self.comb += [
                        self.bioadapter.i2c.eq(self.test[0]),
                        self.bioadapter.force.eq(self.test[1]),
                        # self.bioadapter.loop_oe.eq(self.test[2]),
                        # self.bioadapter.invert.eq(self.test[3]),
                        self.bioadapter.force_val.eq(self.test[16:]),
                    ]

        self.submodules.csrtest = CsrTest()


def run_xvlog(cmd):
    subprocess.run(cmd, check=True, cwd="run"),

class SimRunner():
    def __init__(self, vex_verilog_path=VEX_CPU_PATH, tb='top_tb', vivado_path=VIVADO_PATH, os_cmds = []):
        # Ensure 'run/' directory exists (won't fail if it already does)
        target_dir = Path("run")
        target_dir.mkdir(parents=True, exist_ok=True)

        # Delete 'run/xsim.dir' if it exists
        xsim_dir = target_dir / "xsim.dir"
        shutil.rmtree(xsim_dir, ignore_errors=True)

        # List of source files from arbitrary locations
        source_files = [
            Path("sim_support/prims.v"),
            Path("sim_support/glbl.v"),
            Path("sim_support/top_tb.v"),
            Path(vex_verilog_path),
            Path("deps/bio/bio_bdma_wrapper.sv"),
            Path("deps/bio/bio_bdma.sv"),
            Path("deps/bio/picorv32.v"),
            Path("deps/bio/pio_divider.v"),
            Path("deps/bio/ram_1rw_s.sv"),
            Path("deps/bio/regfifo.v"),
            Path("soc_oss/ahb_to_axi4.sv"),
            Path("soc_oss/rtl/rbist_intf.sv"),
            Path("sim_support/cdc_blinded.v"),
            Path("sim_support/cdc_level_to_pulse.sv"),
            Path("sim_support/bioram1kx32.v"),
        ]
        # Define source globs (modify as needed)
        glob_patterns = [
            "build/digilent_arty/gateware/*.v",
            "build/digilent_arty/gateware/*.sv",
            "deps/verilog-axi/rtl/*.v",
            "deps/bio/soc/*.sv",
            "deps/axi2ahb/*.v",
        ]
        headers = [
            (Path("deps/bio/soc/axi"), Path("run/axi"))
        ]
        inits = [
            Path("build/digilent_arty/gateware/digilent_arty_test_ram.init"),
        ]

        # Expand globs to actual Path objects
        for pattern in glob_patterns:
            source_files.extend(Path().glob(pattern) if not Path(pattern).is_absolute()
                                else Path(pattern).parent.glob(Path(pattern).name))

        # Optional exec prefix (adjust as needed)
        exec_prefix = Path(vivado_path)

        # Copy files and collect destination paths
        copied_files = []
        for src in source_files:
            dest = target_dir / src.name
            shutil.copy2(src, dest)
            copied_files.append(src.name)
        # copy the inits
        for src in inits:
            dest = target_dir / src.name
            shutil.copy2(src, dest)

        # Copy headers
        for src_header, dst_header in headers:
            shutil.copytree(src_header, dst_header, dirs_exist_ok=True)

        commands = []
        for file in copied_files:
            commands += [
                [str(exec_prefix / "xvlog.bat"),
                 "-sv", str(file),
                 "--define", "FPGA",
                 "--define", "XVLOG",
                 "--define", "USE_OSS_BRIDGE",
                 ]]

        if False:
            for command in commands:
                print(command)
                run_xvlog(command)
        else:
            # Use multiprocessing Pool to run in parallel
            with multiprocessing.Pool(12) as pool:
                pool.map(run_xvlog, commands)
            pool.close()

        # run user dependencies
        for cmd in os_cmds:
            cmd_list = shlex.split(cmd)
            subprocess.run(cmd_list, check=True)

        # Print PYTHONPATH
        print("Using PYTHONPATH: {}".format(os.environ["PYTHONPATH"]))

        # Define variables
        run_dir = Path("run")
        xsimdir = os.environ.get("xsimdir", "")  # Ensure xsimdir is defined

        # Construct xelab command
        xelab_cmd = [
            str(Path(vivado_path) / "xelab.bat"),
            "-debug", "drivers",
            tb, "glbl",
            "-s", f"{tb}_sim",
            "-L", "unisims_ver",
            "-L", "unimacro_ver",
            "-L", "SIMPRIM_VER",
            "-L", "secureip",
            "-L", f"{xsimdir}/xil_defaultlib",
            "-timescale", "1ns/1ps"
        ]

        # Run xelab
        subprocess.run(xelab_cmd, cwd=run_dir, check=True)

        # Run xsim
        xsim_cmd = [str(Path(vivado_path) / "xsim.bat"), f"{tb}_sim", "-gui"]
        subprocess.run(xsim_cmd, cwd=run_dir, check=True)

import struct
def bytes_to_int32_list(byte_data):
    # Pad to multiple of 4 bytes
    padded_len = (len(byte_data) + 3) & ~3
    byte_data += b'\x00' * (padded_len - len(byte_data))

    # Unpack as little-endian 32-bit integers
    return list(struct.unpack('<' + 'I' * (len(byte_data) // 4), byte_data))

# packs an ELF into a footprint that is suitable for direct run out of RAM
def load_elf(filename, outfile, ramfile):
    buf = io.BytesIO()
    rambuf = io.BytesIO()
    # assemble data into buf
    with open(filename, 'rb') as f:
        elf = ELFFile(f)
        for name in ['.data', '.bss', '.rodata', '.text']:
            section = elf.get_section_by_name(name)
            if section:
                offset = section['sh_offset']
                # strip out the bank address at top
                addr = section['sh_addr'] & 0x0FFF_FFFF
                size = section['sh_size']

                print(f"Section: {name}")
                print(f"  File offset : 0x{offset:08x}")
                print(f"  Load address: 0x{addr:08x}")
                print(f"  Length      : 0x{size:08x}")

                f.seek(offset)
                if name == '.bss':
                    # this section is just an area to be zero'd and not in file
                    data = bytes(size)
                    if size > 4096:
                        print("WARNING: BSS > 4096, breaks memory layout assumptions")
                else:
                    data = f.read(size)
                if name in ['.data', '.bss']:
                    rambuf.seek(addr)
                    rambuf.write(data)
                else:
                    buf.seek(addr)
                    buf.write(data)
            else:
                print(f"Section {name} not found")

    # write buf out to a .init file
    bufbytes = buf.getvalue()
    with open(outfile, 'w') as of:
        length = len(bufbytes)
        i = 0
        while i < length:
            chunk = bufbytes[i:i+4]
            if len(chunk) < 4:
                chunk += b'\x00' * (4 - len(chunk))  # pad with zeros
            word = int.from_bytes(chunk, 'little')
            of.write(f'{word:08X}\n')
            i += 4

    # write rambuf out to a .init file
    bufbytes = rambuf.getvalue()
    with open(ramfile, 'w') as of:
        length = len(bufbytes)
        i = 0
        while i < length:
            chunk = bufbytes[i:i+4]
            if len(chunk) < 4:
                chunk += b'\x00' * (4 - len(chunk))  # pad with zeros
            word = int.from_bytes(chunk, 'little')
            of.write(f'{word:08X}\n')
            i += 4

# Build --------------------------------------------------------------------------------------------

def main():
    from litex.build.parser import LiteXArgumentParser
    parser = LiteXArgumentParser(platform=digilent_arty.Platform, description="LiteX SoC on Arty A7.")
    parser.add_target_argument("--flash",          action="store_true",       help="Flash bitstream.")
    parser.add_target_argument("--variant",        default="a7-100",           help="Board variant (a7-35 or a7-100).")
    parser.add_target_argument("--sys-clk-freq",   default=40e6, type=float, help="System clock frequency.")
    parser.add_target_argument("--with-xadc",      action="store_true",       help="Enable 7-Series XADC.")
    parser.add_target_argument("--with-dna",       action="store_true",       help="Enable 7-Series DNA.")
    parser.add_target_argument("--with-usb",       action="store_true",       help="Enable USB Host.")
    parser.add_target_argument("--with-ethernet",  action="store_true",       help="Enable Ethernet support.")
    parser.add_target_argument("--with-etherbone", action="store_true",       help="Enable Etherbone support.")
    parser.add_target_argument("--eth-ip",         default="192.168.1.50",    help="Ethernet/Etherbone IP address.")
    parser.add_target_argument("--remote-ip",      default="192.168.1.100",   help="Remote IP address of TFTP server.")
    parser.add_target_argument("--eth-dynamic-ip", action="store_true",       help="Enable dynamic Ethernet IP addresses setting.")
    sdopts = parser.target_group.add_mutually_exclusive_group()
    sdopts.add_argument("--with-spi-sdcard",       action="store_true",       help="Enable SPI-mode SDCard support.")
    sdopts.add_argument("--with-sdcard",           action="store_true",       help="Enable SDCard support.")
    parser.add_target_argument("--sdcard-adapter",                            help="SDCard PMOD adapter (digilent or numato).")
    parser.add_target_argument("--with-jtagbone",  action="store_true",       help="Enable JTAGbone support.")
    parser.add_target_argument("--with-spi-flash", action="store_true",       help="Enable SPI Flash (MMAPed).")
    parser.add_target_argument("--with-pmod-gpio", action="store_true",       help="Enable GPIOs through PMOD.") # FIXME: Temporary test.
    parser.add_target_argument("--with-can",       action="store_true",       help="Enable CAN support (Through CTU-CAN-FD Core and SN65HVD230 'PMOD'.")
    parser.add_target_argument("--sim",            action="store_true",       help="Run Xsim")
    args = parser.parse_args()

    assert not (args.with_etherbone and args.eth_dynamic_ip)

    soc = BaseSoC(
        variant        = args.variant,
        toolchain      = args.toolchain,
        sys_clk_freq   = args.sys_clk_freq,
        with_xadc      = args.with_xadc,
        with_dna       = args.with_dna,
        with_ethernet  = args.with_ethernet,
        with_etherbone = args.with_etherbone,
        eth_ip         = args.eth_ip,
        remote_ip      = args.remote_ip,
        eth_dynamic_ip = args.eth_dynamic_ip,
        with_usb       = args.with_usb,
        with_spi_flash = args.with_spi_flash,
        with_pmod_gpio = args.with_pmod_gpio,
        with_can       = args.with_can,
        sim            = args.sim,
        **parser.soc_argdict
    )

    if args.sdcard_adapter == "numato":
        soc.platform.add_extension(digilent_arty._numato_sdcard_pmod_io)
    else:
        soc.platform.add_extension(digilent_arty._sdcard_pmod_io)
    if args.with_spi_sdcard:
        soc.add_spi_sdcard()
    if args.with_sdcard:
        soc.add_sdcard()

    if args.with_jtagbone:
        soc.add_jtagbone()

    builder = Builder(soc, **parser.builder_argdict)
    # Set `defines that establish the correct verilog environment
    # Quadruple parenthesis are needed because {{}} is stripped by two successive .format() calls in this chain {{{{FPGA USE_OSS_BRIDGE}}}}
    soc.platform.toolchain.project_commands.add(r'set_property VERILOG_DEFINE {{{{FPGA USE_OSS_BRIDGE}}}} [get_filesets sources_1]')

    builder.csr_csv = "build/csr.csv"
    builder.csr_svd = "build/software/soc.svd"
    if args.build:
        builder.compile_software = False
        builder.build(**parser.toolchain_argdict)

    if args.sim:
        builder.compile_software = False
        builder.compile_gateware = False # update .v model, but don't compile
        builder.build(regular_comb=False, **parser.toolchain_argdict)
        # build test software
        if False:
            subprocess.run(["cargo", "xtask", "baremetal-artyvexii"], cwd="../xous-core", check=True)
        else:
            subprocess.run([
            "cargo",
                "+nightly",
                "build",
                "--release", "--target",  "riscv32imac-unknown-none-elf",
                "--package", "baremetal",
                "--no-default-features", "--features", "artyvexii", "--features", "utralib/artyvexii"
            ], cwd="../xous-core", check=True)
        load_elf("../xous-core/target/riscv32imac-unknown-none-elf/release/baremetal", "run/digilent_arty_rom.init", "run/digilent_arty_main_ram.init")
        # run the simulator
        SimRunner()

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(builder.get_bitstream_filename(mode="sram"))

    if args.flash:
        prog = soc.platform.create_programmer()
        prog.flash(0, builder.get_bitstream_filename(mode="flash"))

if __name__ == "__main__":
    main()