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

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(builder.get_bitstream_filename(mode="sram"))

    if args.flash:
        prog = soc.platform.create_programmer()
        prog.flash(0, builder.get_bitstream_filename(mode="flash"))

if __name__ == "__main__":
    main()