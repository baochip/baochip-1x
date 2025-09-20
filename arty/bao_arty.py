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

from pathlib import Path

from migen import *

from litex.gen import *

import digilent_arty

from litex.soc.cores.clock import *
from litex.soc.integration.soc import SoCRegion, SoCIORegion
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.cores.led import LedChaser
from litex.soc.cores.gpio import GPIOIn, GPIOTristate

from litedram.modules import MT41K128M16
from litedram.phy import s7ddrphy

from litex.soc.interconnect.csr import *
from litex.soc.integration.doc import AutoDoc, ModuleDoc
from litex.soc.cores import uart

from litex.soc.interconnect.axi import AXIInterface

from litex.build.generic_platform import *

from cram_common import CramSoC

# CRG ----------------------------------------------------------------------------------------------

class _CRG(LiteXModule):
    def __init__(self, platform, sys_clk_freq, with_dram=True, with_rst=True, sleep_req=None):
        self.rst    = Signal()
        self.cd_sys = ClockDomain()
        self.cd_sys_always_on = ClockDomain()
        self.cd_p   = ClockDomain()
        self.cd_pio = ClockDomain()
        self.cd_h_clk = ClockDomain()
        if with_dram:
            self.cd_sys4x     = ClockDomain()
            self.cd_sys4x_dqs = ClockDomain()
            self.cd_idelay    = ClockDomain()

        # # #

        # Clk/Rst.
        clk100 = platform.request("clk100")
        rst    = ~platform.request("cpu_reset") if with_rst else 0

        # PLL.
        self.pll = pll = S7PLL(speedgrade=-1)
        self.comb += pll.reset.eq(rst | self.rst)
        pll.register_clkin(clk100, 100e6)
        pll.create_clkout(self.cd_sys, sys_clk_freq, buf="bufgce", ce=(pll.locked & ~sleep_req))
        pll.create_clkout(self.cd_sys_always_on, sys_clk_freq)
        pll.create_clkout(self.cd_p, 25e6)
        pll.create_clkout(self.cd_h_clk, 100e6)
        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.
        if with_dram:
            pll.create_clkout(self.cd_sys4x,     4*sys_clk_freq)
            pll.create_clkout(self.cd_sys4x_dqs, 4*sys_clk_freq, phase=90)
            pll.create_clkout(self.cd_idelay,    200e6)

        # IdelayCtrl.
        if with_dram:
            self.idelayctrl = S7IDELAYCTRL(self.cd_idelay)

# CramSoC ------------------------------------------------------------------------------------------

def arty_extensions(self,
                    l2_cache_size = 8192,
                    with_led_chaser = True,
                    with_buttons = True,
                    with_jtagbone = False,
                    with_spi_flash = False,
                    with_pmod_gpio = False,
                    ):
    # weird syntax needed otherwise somehow this gets added as a tuple instead of as an integer...
    self.mem_map = {**self.mem_map, **{
        "emu_ram" : self.axi_mem_map["reram"][0]
    }}

    # CRG --------------------------------------------------------------------------------------
    rtl_dir = os.path.join(os.path.dirname(__file__), "VexRiscv")
    self.platform.add_source(rtl_dir, "VexRiscv/memory_AesZknPlugin_rom_storage_Rom_1rs.v")
    self.crg  = _CRG(self.platform, self.sys_clk_freq, False, sleep_req=self.sleep_req)

    # Various other I/Os
    self.comb += self.platform.request("rgb_led", number=0).g.eq(self.coreuser)

    # Local RAM option for faster bringup (but less capacity)
    from soc_oss.axi_ram import AXIRAM
    # size overrides for the default region sizes because we can't fit the whole thing on an A100
    RERAM_SIZE=64*1024
    SRAM_SIZE=128*1024
    XIP_SIZE=4*1024

    reram_axi = AXIInterface(data_width=64, address_width=32, id_width=2, bursting=True)
    sram_axi = AXIInterface(data_width=64, address_width=32, id_width=2, bursting=True)
    xip_axi = AXIInterface(data_width=64, address_width=32, id_width=2, bursting=True)
    self.submodules.axi_sram = AXIRAM(
        self.platform, sram_axi, size=SRAM_SIZE, name="sram")
    self.submodules.axi_reram = AXIRAM(
        self.platform, reram_axi, size=RERAM_SIZE, name="reram", init=self.bios_data)
    self.submodules.xip_sram = AXIRAM(
        self.platform, xip_axi, size=4096, name="xip") # just a small amount of RAM for testing

    # vex debug is internal to the core, no interface to build

    self.mbus.add_master(name = "reram", m_axi=reram_axi, origin=self.axi_mem_map["reram"][0], size=RERAM_SIZE)
    self.mbus.add_master(name = "sram",  m_axi=sram_axi,  origin=self.axi_mem_map["sram"][0],  size=SRAM_SIZE)
    self.mbus.add_master(name = "xip",  m_axi=xip_axi,  origin=self.axi_mem_map["xip"][0],  size=XIP_SIZE)

    # Add SoC memory regions
    self.add_memory_region(name="reram", origin=self.axi_mem_map["reram"][0], length=RERAM_SIZE)
    self.add_memory_region(name="sram", origin=self.axi_mem_map["sram"][0], length=SRAM_SIZE)
    self.add_memory_region(name="xip", origin=self.axi_mem_map["xip"][0], length=XIP_SIZE)

    # DDR3 SDRAM -------------------------------------------------------------------------------
    # dram_axi = AXIInterface(data_width=64, address_width=32, id_width=2, bursting=True)
    # self.mbus.add_master(name = "reram", m_axi=dram_axi,
    #                         origin=self.axi_mem_map["reram"][0], size=0x0100_0000 * 2) # maps both ReRAM and SRAM

    # self.ddrphy = s7ddrphy.A7DDRPHY(self.platform.request("ddram"),
    #     memtype        = "DDR3",
    #     nphases        = 4,
    #     sys_clk_freq   = self.sys_clk_freq)
    # self.add_sdram_emu("sdram",
    #     mem_bus       = dram_axi,
    #     phy           = self.ddrphy,
    #     module        = MT41K128M16(self.sys_clk_freq, "1:4"),
    #     l2_cache_size = l2_cache_size,
    # )

    # Secondary serial -------------------------------------------------------------------------
    # Imports.
    from litex.soc.cores.uart import UART, UARTCrossover
    from litex.soc.cores.uart import UARTPHY
    uart_pads      = self.platform.request("serial", loose=True)
    uart_kwargs    = {
        "tx_fifo_depth": 16,
        "rx_fifo_depth": 16,
    }
    uart_phy  = ClockDomainsRenamer({"sys": "sys_always_on"})(UARTPHY(uart_pads, clk_freq=self.sys_clk_freq, baudrate=115200))
    uart      = ClockDomainsRenamer({"sys": "sys_always_on"})(UART(uart_phy, **uart_kwargs))
    # Add PHY/UART.
    self.add_module(name="uart_phy", module=uart_phy)
    self.add_module(name="uart", module=uart)
    # IRQ.
    self.irq.add("uart", use_loc_if_exists=True)

    # Jtagbone ---------------------------------------------------------------------------------
    if with_jtagbone:
        self.add_jtagbone()

    # SPI Flash --------------------------------------------------------------------------------
    if with_spi_flash:
        from litespi.modules import S25FL128L
        from litespi.opcodes import SpiNorFlashOpCodes as Codes
        self.add_spi_flash(mode="4x", module=S25FL128L(Codes.READ_1_1_4), rate="1:2", with_master=True)

    # Leds -------------------------------------------------------------------------------------
    if with_led_chaser:
        self.leds = LedChaser(
            pads         = self.platform.request_all("user_led"),
            sys_clk_freq = self.sys_clk_freq,
        )

    # Buttons ----------------------------------------------------------------------------------
    if with_buttons:
        self.buttons = GPIOIn(
            pads     = self.platform.request("user_btn", 1),
            with_irq = self.irq.enabled
        )

    # GPIOs ------------------------------------------------------------------------------------
    if with_pmod_gpio:
        self.platform.add_extension(digilent_arty.raw_pmod_io("pmoda"))
        self.gpio = GPIOTristate(
            pads     = self.platform.request("pmoda"),
            with_irq = self.irq.enabled
        )

# Build --------------------------------------------------------------------------------------------
def auto_int(x):
    return int(x, 0)

def main():
    from litex.build.parser import LiteXArgumentParser
    parser = LiteXArgumentParser(platform=digilent_arty.Platform, description="LiteX SoC on Arty A7.")
    parser.add_target_argument("--flash",        action="store_true",       help="Flash bitstream.")
    parser.add_target_argument("--variant",      default="a7-100",           help="Board variant (a7-35 or a7-100).")
    parser.add_target_argument("--sys-clk-freq", default=100e6, type=float, help="System clock frequency.")
    parser.add_target_argument("--with-xadc",    action="store_true",       help="Enable 7-Series XADC.")
    parser.add_target_argument("--with-dna",     action="store_true",       help="Enable 7-Series DNA.")
    ethopts = parser.target_group.add_mutually_exclusive_group()
    ethopts.add_argument("--with-ethernet",        action="store_true",    help="Enable Ethernet support.")
    ethopts.add_argument("--with-etherbone",       action="store_true",    help="Enable Etherbone support.")
    parser.add_target_argument("--eth-ip",         default="192.168.1.50", help="Ethernet/Etherbone IP address.")
    parser.add_target_argument("--eth-dynamic-ip", action="store_true",    help="Enable dynamic Ethernet IP addresses setting.")
    sdopts = parser.target_group.add_mutually_exclusive_group()
    sdopts.add_argument("--with-spi-sdcard",       action="store_true", help="Enable SPI-mode SDCard support.")
    sdopts.add_argument("--with-sdcard",           action="store_true", help="Enable SDCard support.")
    parser.add_target_argument("--sdcard-adapter",                      help="SDCard PMOD adapter (digilent or numato).")
    parser.add_target_argument("--with-jtagbone",  action="store_true", help="Enable JTAGbone support.")
    parser.add_target_argument("--with-spi-flash", action="store_true", help="Enable SPI Flash (MMAPed).")
    parser.add_target_argument("--with-pmod-gpio", action="store_true", help="Enable GPIOs through PMOD.") # FIXME: Temporary test.
    # specify test BIOS path
    parser.add_argument("--bios", type=str, default='.{}boot{}boot.bin'.format(os.path.sep, os.path.sep), help="Override default BIOS location")
    parser.add_argument("--boot-offset", type=auto_int, default=0)

    # Build just the SVDs
    parser.add_argument("--svd-only",             action="store_true",     help="Just build the SVDs for the OS build")
    args = parser.parse_args()

    bios_path = args.bios

    assert not (args.with_etherbone and args.eth_dynamic_ip)

    platform = digilent_arty.Platform(variant=args.variant, toolchain=args.toolchain)
    pathroot = Path(__file__).parent
    platform.verilog_include_paths = [
        str(pathroot / "soc_oss/rtl/common"),
    ]

    # add various platform I/O extensions
    pio = [
        ("pio", 0,
            Subsignal("gpio", Pins(" ".join([f"ck_io:ck_io{i:d}" for i in range(32)]))),
            IOStandard("LVCMOS33"),
        )
    ]
    platform.add_extension(pio)
    duart = [
        ("duart", 0,
            Subsignal("tx", Pins("ck_io:ck_io40")),
            Subsignal("rx", Pins("ck_io:ck_io41")),
            IOStandard("LVCMOS33"),
        )
    ]
    platform.add_extension(duart)
    jtag_pins = [
        ("jtag_cpu", 0,
            # Subsignal("tck",  Pins("ck_io:ck_io33")),
            # Subsignal("tms",  Pins("ck_io:ck_io34")),
            # Subsignal("tdi",  Pins("ck_io:ck_io35")),
            # Subsignal("tdo",  Pins("ck_io:ck_io36")),
            # Subsignal("trst_n", Pins("ck_io:ck_io37")),

            Subsignal("tck",  Pins("pmodd:4")),   # rpi 26
            Subsignal("tms",  Pins("pmodd:5")),   # rpi 13
            Subsignal("tdi",  Pins("pmodd:7")),   # rpi 20
            Subsignal("tdo",  Pins("pmodd:6")),   # rpi 19
            Subsignal("trst_n", Pins("pmodd:2")), # rpi 16

            Misc("SLEW=SLOW"),
            IOStandard("LVCMOS33"),
        )
    ]
    platform.add_extension(jtag_pins)
    #         rp  pm(lx)(lx)pm  rp
    # E2  tck  6  7(4)   (0)1   12
    # D2  tms 13  8(5)   (1)2   G
    # H2  tdo 19  9(6)   (2)3   16 trst_n F4
    # G2  tdi 26 10(7)   (3)4   20
    #          G 11         5   21
    #            12 VCC VCC 6
    platform.add_platform_command("create_clock -name jtag_cpu_tck -period {:0.3f} [get_nets jtag_cpu_tck]".format(1e9 / 2e6))
    platform.add_platform_command("set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets sys_clk]")
    platform.add_platform_command('set_false_path -through [get_nets *_rst]')

    soc = CramSoC(
        platform,
        sys_clk_freq   = args.sys_clk_freq,
        variant        = args.variant,
        bios_path      = bios_path,
        boot_offset    = args.boot_offset,
        vivado         = True,
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

    CramSoC.arty_extensions = arty_extensions
    soc.arty_extensions(
        l2_cache_size  = 32768,
        with_led_chaser= True,
        with_buttons   = True,
        with_jtagbone  = args.with_jtagbone,
        with_spi_flash = args.with_spi_flash,
        with_pmod_gpio = args.with_pmod_gpio,
    )
    soc.platform.toolchain.project_commands.add(r'set_property VERILOG_DEFINE {{{{FPGA USE_OSS_BRIDGE}}}} [get_filesets sources_1]')

    builder = Builder(
        soc,
        csr_csv="build/csr.csv",
        csr_svd="build/software/soc.svd",
        # **parser.builder_argdict
    )
    builder.software_packages = []
    # weird overrides because parser.builder_argdict somehow makes arguments...
    # read-only and set only by command line?? wtf yo....
    builder.output_dir = "build"
    builder.gateware_dir = "build/gateware"
    builder.software_dir = "build/software"
    builder.generated_dir = "build/software"
    builder.include_dir = "build/software"
    builder.csr_svd = "build/software/soc.svd"
    builder.csr_csv = "build/csr.csv"
    if args.build:
        builder.build(regular_comb=False, **parser.toolchain_argdict)
    else:
        builder.build(run=False, regular_comb=False, **parser.toolchain_argdict)

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(builder.get_bitstream_filename(mode="sram"))

    if args.flash:
        prog = soc.platform.create_programmer()
        prog.flash(0, builder.get_bitstream_filename(mode="flash"))

if __name__ == "__main__":
    main()