#!/usr/bin/env python3

from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect import stream

from litex.build.generic_platform import *
from litex.build.sim import SimPlatform
from litex.build.sim.config import SimConfig

from litex.soc.integration.soc_core import *
from litex.soc.integration.soc import SoCRegion, SoCIORegion
from litex.soc.integration.builder import *
from litex.soc.interconnect import wishbone
from litex.soc.interconnect import axi

from litex.build.xilinx import XilinxPlatform, VivadoProgrammer
from litex.soc.cores.clock import S7MMCM, S7IDELAYCTRL
from migen.genlib.resetsync import AsyncResetSynchronizer
from litex.soc.interconnect.csr import *

from litex.soc.interconnect.axi import AXIInterface, AXILiteInterface
from litex.soc.integration.soc import SoCBusHandler
from litex.soc.cores import uart
from litex.soc.integration.doc import AutoDoc, ModuleDoc

from soc_oss.axi_crossbar import AXICrossbar
from soc_oss.axi_adapter import AXIAdapter
from soc_oss.axi_ram import AXIRAM
from soc_oss.axil_ram import AXILiteRAM
from soc_oss.axil_crossbar import AXILiteCrossbar
from soc_oss.axil_cdc import AXILiteCDC
from soc_oss.axi_common import *

from soc_oss.axil_ahb_adapter import AXILite2AHBAdapter
from litex.soc.interconnect import ahb
from soc_oss.ahb_axi_adapter import AHB2AxiAdapter
from soc_oss.axi_axil_adapter import AXI2AXILiteAdapter
from soc_oss.axil_axi_adapter import AXILite2AXIAdapter

from math import ceil, log2

VEX_VERILOG_PATH = "../VexRiscv/VexRiscv_CramSoC.v"
# CramSoC testing wrapper -----------------------------------------------------------------------

class CramSoCSce(SoCCore):
    def __init__(self,
        platform,
        crg=None,
        variant = "sim",
        bios_path=None,
        boot_offset=0,
        sys_clk_freq=800e6,
        production_models=False,
        sim_debug=False,
        trace_reset_on=False,
        vivado=False,
        # bogus arg handlers - we are doing SoCMini, but the simulator passes args for a full SoC
        bus_standard=None,
        bus_data_width=None,
        bus_address_width=None,
        bus_timeout=None,
        bus_bursting=None,
        bus_interconnect=None,
        cpu_type                 = None,
        cpu_reset_address        = None,
        cpu_variant              = None,
        cpu_cfu                  = None,
        cfu_filename             = None,
        csr_data_width           = None,
        csr_address_width        = None,
        csr_paging               = None,
        csr_ordering             = None,
        integrated_rom_size      = None,
        integrated_rom_mode      = None,
        integrated_rom_init      = None,
        integrated_sram_size     = None,
        integrated_sram_init     = None,
        integrated_main_ram_size = None,
        integrated_main_ram_init = None,
        irq_n_irqs               = None,
        ident                    = None,
        ident_version            = None,
        with_uart                = None,
        uart_name                = None,
        uart_baudrate            = None,
        uart_fifo_depth          = None,
        with_timer               = None,
        timer_uptime             = None,
        with_ctrl                = None,
        l2_size                  = None,
    ):
        self.variant = variant
        self.platform = platform
        self.sys_clk_freq = sys_clk_freq
        self.sim_debug = sim_debug
        self.trace_reset_on = trace_reset_on

        self.axi_mem_map = {
            "reram"          : [0x6000_0000, 4 * 1024 * 1024], # +4M
            "sram"           : [0x6100_0000, 2 * 1024 * 1024], # +2M
            "xip"            : [0x7000_0000, 128 * 1024 * 1024], # up to 128MiB of XIP
            "vexriscv_debug" : [0xefff_0000, 0x1000],
        }
        # Firmware note:
        #    - entire region from 0x4000_0000 through 0x4010_0000 is VM-mapped in test bench
        #    - entire region from 0x5012_0000 through 0x5013_0000 is VM-mapped in test bench
        self.axi_peri_map = {
            "testbench"   : [0x4008_0000, 0x1_0000], # 64k
            "duart"       : [0x4004_2000, 0x0_1000],
            # "mbox_apb"    : [0x4001_3000, 0x0_1000],
            # "pio"       : [0x5012_3000, 0x0_1000],
            # "bio"       : [0x5012_4000, 0x0_2000],
            "sce"         : [0x4002_0000, 0x1_0000], # this absorbs all the SCE blocks
            # "bio_bdma"    : [0x5012_4000, 0x0_1000], # also infers 8x pages in addition to the control page
            # "iox"         : [0x5012_f000, 0x0_1000], # dummy so tests don't crash when writing here
            # "ifram0"      : [0x5000_0000, 128 * 1024],
            # "ifram1"      : [0x5002_0000, 128 * 1024],
        }
        self.mem_map = {**SoCCore.mem_map, **{
            "csr": self.axi_peri_map["testbench"][0], # save bottom 0x10_0000 for compatibility with Cramium native registers
        }}

        # Add standalone SoC sources.
        platform.add_source("build/gateware/cram_axi.v")
        platform.add_source(VEX_VERILOG_PATH)
        platform.add_source("sim_support/ram_1w_1ra.v")
        # platform.add_source("sim_support/prims.v")
        platform.add_source("sim_support/fdre_cosim.v")
        if production_models:
            platform.add_source("do_not_checkin/ram/vexram_v0.1.sv")
            platform.add_source("do_not_checkin/ram/icg_v0.2.v")
        else:
            platform.add_source("sim_support/ram_1w_1rs.v")

        # this must be pulled in manually because it's instantiated in the core design, but not in the SoC design
        rtl_dir = os.path.join(os.path.dirname(__file__), "..", "deps", "verilog-axi", "rtl")
        platform.add_source(os.path.join(rtl_dir, "axi_axil_adapter.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_axil_adapter_wr.v"))
        platform.add_source(os.path.join(rtl_dir, "axi_axil_adapter_rd.v"))

        # SoCMini ----------------------------------------------------------------------------------
        SoCMini.__init__(self, platform, clk_freq=int(sys_clk_freq),
            csr_paging           = 4096,  # increase paging to 1 page size
            csr_address_width    = 16,    # increase to accommodate larger page size
            bus_standard         = "axi-lite",
            # bus_timeout          = None,         # use this if regular_comb=True on the builder
            ident                = "Cramium SoC OSS version",
            with_ctrl            = False,
            io_regions           = {
                # Origin, Length.
                0x4000_0000 : 0x2000_0000,
                0xa000_0000 : 0x6000_0000,
            },
        )
        # Wire up peripheral SoC busses
        jtag_cpu = platform.request("jtag_cpu")

        # Add simulation "output pins" -----------------------------------------------------
        self.sim_done = CSRStorage(1, name ="done", description="Set to `1` if the simulation should auto-terminate")
        self.test = Signal(32)

        # Add AXI RAM to SoC (Through AXI Crossbar).
        # ------------------------------------------

        # 1) Create AXI interface and connect it to SoC.
        dbus_axi = AXIInterface(data_width=32, address_width=32, id_width=4, bursting=True)
        dbus64_axi = AXIInterface(data_width=64, address_width=32, id_width=4, bursting=True)
        self.submodules += AXIAdapter(platform, s_axi = dbus_axi, m_axi = dbus64_axi, convert_burst=True, convert_narrow_burst=True)
        ibus64_axi = AXIInterface(data_width=64, address_width=32, id_width=4, bursting=True)

        sce_axi0_p = AXIInterface(clock_domain="p", data_width=32, address_width=32, id_width=4, bursting=True)
        sce_axil0_p = AXILiteInterface(clock_domain="p", name = "sce_axil0_p", bursting = False)
        self.submodules += ClockDomainsRenamer({"sys" : "p"})(
            AXI2AXILiteAdapter(platform, sce_axi0_p, sce_axil0_p)
        )
        # CDC on axilite domain
        sce_axil0_sys = AXILiteInterface(name = "sce_axil0_sys", bursting = False)
        self.submodules += AXILiteCDC(platform, sce_axil0_p, sce_axil0_sys)

        # sce_axil0_sys -> sce_axi0 adapter
        sce_axi0 = AXIInterface(data_width=32, address_width=32, id_width=4, bursting=False)
        self.submodules += AXILite2AXIAdapter(platform, sce_axi0, sce_axil0_sys, axi_id=4) # AMBAID4_SCES; AMBAID4_SCEA = 4

        sce_axi0_64 = AXIInterface(data_width=64, address_width=32, id_width=4, bursting=True)
        self.submodules += AXIAdapter(platform, s_axi = sce_axi0, m_axi = sce_axi0_64, convert_burst=True, convert_narrow_burst=True)

        # AXI in pclk domain to SCE
        sce_axi1_p = AXIInterface(clock_domain="p", data_width=32, address_width=32, id_width=4, bursting=False)
        sce_axil1_p = AXILiteInterface(clock_domain="p", name = "sce_axil1_p", bursting = False)
        self.submodules += ClockDomainsRenamer({"sys" : "p"})(
            AXI2AXILiteAdapter(platform, sce_axi1_p, sce_axil1_p)
        )
        # CDC on axilite domain
        sce_axil1_sys = AXILiteInterface(name = "sce_axil1_sys", bursting = False)
        self.submodules += AXILiteCDC(platform, sce_axil1_p, sce_axil1_sys)

        # sce_axil1_sys -> sce_axi1 adapter
        sce_axi1 = AXIInterface(data_width=32, address_width=32, id_width=4, bursting=False)
        self.submodules += AXILite2AXIAdapter(platform, sce_axi1, sce_axil1_sys, axi_id=6) # AMBAID4_SCES; AMBAID4_SCEA = 4

        sce_axi1_64 = AXIInterface(data_width=64, address_width=32, id_width=4, bursting=False)
        self.submodules += AXIAdapter(platform, s_axi = sce_axi1, m_axi = sce_axi1_64, convert_burst=False, convert_narrow_burst=False)

        # 2) Add 2 X AXILiteSRAM to emulate ReRAM and SRAM; much smaller now just for testing
        if bios_path is not None:
            with open(bios_path, 'rb') as bios:
                self.bios_data = bytearray(boot_offset)
                self.bios_data += bytearray(bios.read())
        else:
            self.bios_data = []

        # 3) Add AXICrossbar  (2 Slave / 2 Master).
        # Crossbar slaves (from CPU master) -- common to all platforms
        self.submodules.mbus = mbus = AXICrossbar(platform=platform)
        if vivado:
            mbus.vivado_only = True
        mbus.add_slave(name = "dbus", s_axi=dbus64_axi,
            aw_reg = AXIRegister.BYPASS,
            w_reg  = AXIRegister.BYPASS,
            b_reg  = AXIRegister.BYPASS,
            ar_reg = AXIRegister.BYPASS,
            r_reg  = AXIRegister.BYPASS,
        )
        mbus.add_slave(name = "ibus", s_axi=ibus64_axi,
            aw_reg = AXIRegister.BYPASS,
            w_reg  = AXIRegister.BYPASS,
            b_reg  = AXIRegister.BYPASS,
            ar_reg = AXIRegister.BYPASS,
            r_reg  = AXIRegister.BYPASS,
        )
        mbus.add_slave(name = "sce0", s_axi=sce_axi0_64,
        )
        mbus.add_slave(name = "sce1", s_axi=sce_axi1_64,
            aw_reg = AXIRegister.SIMPLE_BUFFER,
            w_reg  = AXIRegister.SIMPLE_BUFFER,
            b_reg  = AXIRegister.SIMPLE_BUFFER,
            ar_reg = AXIRegister.SIMPLE_BUFFER,
            r_reg  = AXIRegister.SIMPLE_BUFFER,
        )
        # Crossbar masters (from crossbar to RAM) -- added by platform extensions method

        # 4) Add peripherals
        # build the controller port for the peripheral crossbar
        self.submodules.pxbar = pxbar = AXILiteCrossbar(platform)
        p_axil = AXILiteInterface(name="pbus", bursting = False)
        pxbar.add_slave(
            name = "p_axil", s_axil = p_axil,
        )
        # Define the interrupt signals; if they aren't used, they will just stay at 0 and be harmless
        # But we need to define them so we don't have an explosion of SoC wiring options down below
        pio_irq0 = Signal()
        pio_irq1 = Signal()
        bio_irq = Signal(4)
        irq_available = Signal()
        irq_abort_init = Signal()
        irq_abort_done = Signal()
        irq_error = Signal()
        mbox_layout = [
            ("w_dat",  32, DIR_M_TO_S),
            ("w_valid", 1, DIR_M_TO_S),
            ("w_ready", 1, DIR_S_TO_M),
            ("w_done",  1, DIR_M_TO_S),
            ("r_dat",  32, DIR_S_TO_M),
            ("r_valid", 1, DIR_S_TO_M),
            ("r_ready", 1, DIR_M_TO_S),
            ("r_done",  1, DIR_S_TO_M),
            ("w_abort", 1, DIR_M_TO_S),
            ("r_abort", 1, DIR_S_TO_M),
        ]
        mbox = Record(mbox_layout)

        # This region is used for testbench elements (e.g., does not appear in the final SoC):
        # these are peripherals that are inferred by LiteX in this module such as the UART to facilitate debug
        for (name, region) in self.axi_peri_map.items():
            setattr(self, name + "_region", SoCIORegion(region[0], region[1], mode="rw", cached=False))
            setattr(self, name + "_axil", AXILiteInterface(name=name + "_axil"))
            pxbar.add_master(
                name = name,
                m_axil = getattr(self, name + "_axil"),
                origin = region[0],
                size = region[1],
            )
            if name == "testbench":
                # connect the testbench master
                self.bus.add_master(name="pbus", master=self.testbench_axil)
            else:
                # connect the SoC via AHB adapters
                setattr(self, name + "_slower_axil", AXILiteInterface(clock_domain="p", name=name + "_slower_axil"))
                setattr(self.submodules, name + "_slower_axi",
                        AXILiteCDC(platform,
                                getattr(self, name + "_axil"),
                                getattr(self, name + "_slower_axil"),
                        ))
                setattr(self, name + "_ahb", ahb.AHBInterface())
                self.submodules += ClockDomainsRenamer({"sys" : "p"})(
                    AXILite2AHBAdapter(platform,
                                    getattr(self, name + "_slower_axil"),
                                    getattr(self, name + "_ahb")
                ))

                if name == "duart":
                    from soc_oss.duart_adapter import DuartAdapter
                    self.submodules += ClockDomainsRenamer({"sys" : "p"})(DuartAdapter(platform,
                        getattr(self, name + "_ahb"), pads=platform.request("duart"),
                        base=(region[0] & 0xFF_FFFF), address_width=log2_int(region[1], need_pow2=True),
                    ))
                elif name == "mbox_apb":
                    from soc_oss.mbox_adapter import MboxAdapter
                    clock_remap = {"pclk" : "p"}
                    self.submodules += ClockDomainsRenamer(clock_remap)(MboxAdapter(platform,
                        getattr(self, name +"_ahb"), mbox, irq_available, irq_abort_init, irq_abort_done, irq_error,
                        base=(region[0] & 0xFF_FFFF), address_width=log2_int(region[1], need_pow2=True),
                        sim=(variant=="sim")
                    ))
                elif name == "sce":
                    from soc_oss.sce_adapter import SceAdapter
                    clock_remap = {"pclk" : "p"}
                    self.submodules += ClockDomainsRenamer(clock_remap)(SceAdapter(platform,
                        getattr(self, name +"_ahb"), sce_axi0_p, sce_axi1_p),
                    )

                else:
                    print("Missing binding for peripheral block {}".format(name))
                    exit(1)

        # add interrupt handler
        interrupt = Signal(32)
        self.cpu.interrupt = interrupt
        self.irq.enable()

        # Cramium platform -------------------------------------------------------------------------
        self.sleep_req = Signal()
        self.uart_irq = Signal()
        self.coreuser = Signal()

        zero_irq = Signal(16)
        irq0_wire_or = Signal(16)
        self.comb += [
            irq0_wire_or[0].eq(self.uart_irq)
        ]
        self.irqtest0 = CSRStorage(fields=[
            CSRField(
                name = "trigger", size=16, description="Triggers for interrupt testing bank 0", pulse=False
            )
        ])
        trimming_reset = Signal(32, reset=(0x6000_0000 + boot_offset))

        # Pull in DUT IP ---------------------------------------------------------------------------
        # remap the IDs to match system params
        self.comb += [
            ibus64_axi.aw.id.eq(3),
            ibus64_axi.ar.id.eq(3),
            dbus_axi.aw.id.eq(4),
            dbus_axi.ar.id.eq(4),
            dbus_axi.w.id.eq(4),
        ]
        self.specials += Instance("cram_axi",
            i_aclk                = ClockSignal("sys"),
            i_rst                 = ResetSignal("sys"),
            i_always_on           = ClockSignal("sys_always_on"),
            i_cmatpg             = 0,
            i_cmbist             = 0,
            i_trimming_reset      = trimming_reset,
            i_trimming_reset_ena  = 1,
            o_p_axi_awvalid       = p_axil.aw.valid,
            i_p_axi_awready       = p_axil.aw.ready,
            o_p_axi_awaddr        = p_axil.aw.addr ,
            o_p_axi_awprot        = p_axil.aw.prot ,
            o_p_axi_wvalid        = p_axil.w.valid ,
            i_p_axi_wready        = p_axil.w.ready ,
            o_p_axi_wdata         = p_axil.w.data  ,
            o_p_axi_wstrb         = p_axil.w.strb  ,
            i_p_axi_bvalid        = p_axil.b.valid ,
            o_p_axi_bready        = p_axil.b.ready ,
            i_p_axi_bresp         = p_axil.b.resp  ,
            o_p_axi_arvalid       = p_axil.ar.valid,
            i_p_axi_arready       = p_axil.ar.ready,
            o_p_axi_araddr        = p_axil.ar.addr ,
            o_p_axi_arprot        = p_axil.ar.prot ,
            i_p_axi_rvalid        = p_axil.r.valid ,
            o_p_axi_rready        = p_axil.r.ready ,
            i_p_axi_rresp         = p_axil.r.resp  ,
            i_p_axi_rdata         = p_axil.r.data  ,
            o_ibus_axi_awvalid    = ibus64_axi.aw.valid ,
            i_ibus_axi_awready    = ibus64_axi.aw.ready ,
            o_ibus_axi_awaddr     = ibus64_axi.aw.addr  ,
            o_ibus_axi_awburst    = ibus64_axi.aw.burst ,
            o_ibus_axi_awlen      = ibus64_axi.aw.len   ,
            o_ibus_axi_awsize     = ibus64_axi.aw.size  ,
            o_ibus_axi_awlock     = ibus64_axi.aw.lock  ,
            o_ibus_axi_awprot     = ibus64_axi.aw.prot  ,
            o_ibus_axi_awcache    = ibus64_axi.aw.cache ,
            o_ibus_axi_awqos      = ibus64_axi.aw.qos   ,
            o_ibus_axi_awregion   = ibus64_axi.aw.region,
            # *simulation override* o_ibus_axi_awid       = ibus64_axi.aw.id    ,
            #o_ibus_axi_awdest     = ibus64_axi.aw.dest  ,
            o_ibus_axi_awuser     = ibus64_axi.aw.user  ,
            o_ibus_axi_wvalid     = ibus64_axi.w.valid  ,
            i_ibus_axi_wready     = ibus64_axi.w.ready  ,
            o_ibus_axi_wlast      = ibus64_axi.w.last   ,
            o_ibus_axi_wdata      = ibus64_axi.w.data   ,
            o_ibus_axi_wstrb      = ibus64_axi.w.strb   ,
            #o_ibus_axi_wid        = ibus64_axi.w.id     ,
            #o_ibus_axi_wdest      = ibus64_axi.w.dest   ,
            o_ibus_axi_wuser      = ibus64_axi.w.user   ,
            i_ibus_axi_bvalid     = ibus64_axi.b.valid  ,
            o_ibus_axi_bready     = ibus64_axi.b.ready  ,
            i_ibus_axi_bresp      = ibus64_axi.b.resp   ,
            i_ibus_axi_bid        = ibus64_axi.b.id     ,
            #i_ibus_axi_bdest      = ibus64_axi.b.dest   ,
            i_ibus_axi_buser      = ibus64_axi.b.user   ,
            o_ibus_axi_arvalid    = ibus64_axi.ar.valid ,
            i_ibus_axi_arready    = ibus64_axi.ar.ready ,
            o_ibus_axi_araddr     = ibus64_axi.ar.addr  ,
            o_ibus_axi_arburst    = ibus64_axi.ar.burst ,
            o_ibus_axi_arlen      = ibus64_axi.ar.len   ,
            o_ibus_axi_arsize     = ibus64_axi.ar.size  ,
            o_ibus_axi_arlock     = ibus64_axi.ar.lock  ,
            o_ibus_axi_arprot     = ibus64_axi.ar.prot  ,
            o_ibus_axi_arcache    = ibus64_axi.ar.cache ,
            o_ibus_axi_arqos      = ibus64_axi.ar.qos   ,
            o_ibus_axi_arregion   = ibus64_axi.ar.region,
            # *simulation override* o_ibus_axi_arid       = ibus64_axi.ar.id    ,
            #o_ibus_axi_ardest     = ibus64_axi.ar.dest  ,
            o_ibus_axi_aruser     = ibus64_axi.ar.user  ,
            i_ibus_axi_rvalid     = ibus64_axi.r.valid  ,
            o_ibus_axi_rready     = ibus64_axi.r.ready  ,
            i_ibus_axi_rlast      = ibus64_axi.r.last   ,
            i_ibus_axi_rresp      = ibus64_axi.r.resp   ,
            i_ibus_axi_rdata      = ibus64_axi.r.data   ,
            i_ibus_axi_rid        = ibus64_axi.r.id     ,
            #i_ibus_axi_rdest      = ibus64_axi.r.dest   ,
            i_ibus_axi_ruser      = ibus64_axi.r.user   ,
            o_dbus_axi_awvalid    = dbus_axi.aw.valid ,
            i_dbus_axi_awready    = dbus_axi.aw.ready ,
            o_dbus_axi_awaddr     = dbus_axi.aw.addr  ,
            o_dbus_axi_awburst    = dbus_axi.aw.burst ,
            o_dbus_axi_awlen      = dbus_axi.aw.len   ,
            o_dbus_axi_awsize     = dbus_axi.aw.size  ,
            o_dbus_axi_awlock     = dbus_axi.aw.lock  ,
            o_dbus_axi_awprot     = dbus_axi.aw.prot  ,
            o_dbus_axi_awcache    = dbus_axi.aw.cache ,
            o_dbus_axi_awqos      = dbus_axi.aw.qos   ,
            o_dbus_axi_awregion   = dbus_axi.aw.region,
            # *simulation override* o_dbus_axi_awid       = dbus_axi.aw.id    ,
            #o_dbus_axi_awdest     = dbus_axi.aw.dest  ,
            o_dbus_axi_awuser     = dbus_axi.aw.user  ,
            o_dbus_axi_wvalid     = dbus_axi.w.valid  ,
            i_dbus_axi_wready     = dbus_axi.w.ready  ,
            o_dbus_axi_wlast      = dbus_axi.w.last   ,
            o_dbus_axi_wdata      = dbus_axi.w.data   ,
            o_dbus_axi_wstrb      = dbus_axi.w.strb   ,
            # *simulation override* o_dbus_axi_wid        = dbus_axi.w.id     ,
            #o_dbus_axi_wdest      = dbus_axi.w.dest  ,
            o_dbus_axi_wuser      = dbus_axi.w.user  ,
            i_dbus_axi_bvalid     = dbus_axi.b.valid  ,
            o_dbus_axi_bready     = dbus_axi.b.ready  ,
            i_dbus_axi_bresp      = dbus_axi.b.resp   ,
            i_dbus_axi_bid        = dbus_axi.b.id     ,
            #i_dbus_axi_bdest      = dbus_axi.b.dest  ,
            i_dbus_axi_buser      = dbus_axi.b.user  ,
            o_dbus_axi_arvalid    = dbus_axi.ar.valid ,
            i_dbus_axi_arready    = dbus_axi.ar.ready ,
            o_dbus_axi_araddr     = dbus_axi.ar.addr  ,
            o_dbus_axi_arburst    = dbus_axi.ar.burst ,
            o_dbus_axi_arlen      = dbus_axi.ar.len   ,
            o_dbus_axi_arsize     = dbus_axi.ar.size  ,
            o_dbus_axi_arlock     = dbus_axi.ar.lock  ,
            o_dbus_axi_arprot     = dbus_axi.ar.prot  ,
            o_dbus_axi_arcache    = dbus_axi.ar.cache ,
            o_dbus_axi_arqos      = dbus_axi.ar.qos   ,
            o_dbus_axi_arregion   = dbus_axi.ar.region,
            # *simulation override* o_dbus_axi_arid       = dbus_axi.ar.id    ,
            #o_dbus_axi_ardest     = dbus_axi.ar.dest  ,
            o_dbus_axi_aruser     = dbus_axi.ar.user  ,
            i_dbus_axi_rvalid     = dbus_axi.r.valid  ,
            o_dbus_axi_rready     = dbus_axi.r.ready  ,
            i_dbus_axi_rlast      = dbus_axi.r.last   ,
            i_dbus_axi_rresp      = dbus_axi.r.resp   ,
            i_dbus_axi_rdata      = dbus_axi.r.data   ,
            i_dbus_axi_rid        = dbus_axi.r.id     ,
            #i_dbus_axi_rdest      = dbus_axi.r.dest  ,
            i_dbus_axi_ruser      = dbus_axi.r.user  ,
            i_jtag_tdi            = jtag_cpu.tdi      ,
            o_jtag_tdo            = jtag_cpu.tdo      ,
            i_jtag_tms            = jtag_cpu.tms      ,
            i_jtag_tck            = jtag_cpu.tck      ,
            i_jtag_trst_n         = jtag_cpu.trst_n   ,

            o_coreuser_vex        = self.coreuser     ,
            i_default_user        = 0,
            i_default_mm          = 1,
            i_irqarray_bank0      = zero_irq,
            i_irqarray_bank1      = zero_irq,
            i_irqarray_bank2      = Cat(zero_irq[:2], irq_available, irq_abort_init, irq_abort_done, irq_error, zero_irq[6:]),
            i_irqarray_bank3      = zero_irq,
            i_irqarray_bank4      = zero_irq,
            i_irqarray_bank5      = zero_irq,
            i_irqarray_bank6      = zero_irq,
            i_irqarray_bank7      = zero_irq,
            i_irqarray_bank8      = zero_irq,
            i_irqarray_bank9      = zero_irq,
            i_irqarray_bank10      = Cat(zero_irq[:3], pio_irq0, pio_irq1, bio_irq[2:4], zero_irq[7:]),
            i_irqarray_bank11      = zero_irq,
            i_irqarray_bank12      = zero_irq,
            i_irqarray_bank13      = zero_irq,
            i_irqarray_bank14      = zero_irq,
            i_irqarray_bank15      = zero_irq,
            i_irqarray_bank16      = zero_irq,
            i_irqarray_bank17      = zero_irq,
            i_irqarray_bank18      = Cat(pio_irq0, pio_irq1, bio_irq[2:4], self.irqtest0.fields.trigger, zero_irq[0]),
            i_irqarray_bank19      = Cat(irq_available, irq_abort_init, irq_abort_done, irq_error, zero_irq[4:]),

            i_mbox_w_dat           = mbox.w_dat,
            i_mbox_w_valid         = mbox.w_valid,
            o_mbox_w_ready         = mbox.w_ready,
            i_mbox_w_done          = mbox.w_done,
            o_mbox_r_dat           = mbox.r_dat,
            o_mbox_r_valid         = mbox.r_valid,
            i_mbox_r_ready         = mbox.r_ready,
            o_mbox_r_done          = mbox.r_done,
            i_mbox_w_abort         = mbox.w_abort,
            o_mbox_r_abort         = mbox.r_abort,

            o_sleep_req            = self.sleep_req,
            o_test                 = self.test,
        )

    def add_sdram_emu(self, name="sdram", mem_bus=None, phy=None, module=None, origin=None, size=None,
        l2_cache_size           = 8192,
        l2_cache_min_data_width = 128,
        l2_cache_reverse        = False,
        l2_cache_full_memory_we = True,
        **kwargs):

        # Imports.
        from litedram.common import LiteDRAMNativePort
        from litedram.core import LiteDRAMCore
        from litedram.frontend.wishbone import LiteDRAMWishbone2Native
        from litex.soc.interconnect import wishbone

        # LiteDRAM core.
        self.check_if_exists(name)
        sdram = LiteDRAMCore(
            phy             = phy,
            geom_settings   = module.geom_settings,
            timing_settings = module.timing_settings,
            clk_freq        = self.sys_clk_freq,
            **kwargs)
        self.add_module(name=name, module=sdram)

        # Save SPD data to be able to verify it at runtime.
        if hasattr(module, "_spd_data"):
            # Pack the data into words of bus width.
            bytes_per_word = self.bus.data_width // 8
            mem = [0] * ceil(len(module._spd_data) / bytes_per_word)
            for i in range(len(mem)):
                for offset in range(bytes_per_word):
                    mem[i] <<= 8
                    if self.cpu.endianness == "little":
                        offset = bytes_per_word - 1 - offset
                    spd_byte = i * bytes_per_word + offset
                    if spd_byte < len(module._spd_data):
                        mem[i] |= module._spd_data[spd_byte]
            self.add_rom(
                name     = f"{name}_spd",
                origin   = self.mem_map.get(f"{name}_spd", None),
                size     = len(module._spd_data),
                contents = mem,
            )

        # Compute/Check SDRAM size.
        sdram_size = 2**(module.geom_settings.bankbits +
                         module.geom_settings.rowbits +
                         module.geom_settings.colbits)*phy.settings.nranks*phy.settings.databits//8
        if size is not None:
            sdram_size = min(sdram_size, size)

        # Add SDRAM region.
        main_ram_region = SoCRegion(
            origin = self.mem_map.get("emu_ram", origin),
            size   = sdram_size,
            mode   = "rwx")
        self.bus.add_region("emu_ram", main_ram_region)

        # Down-convert width by going through a wishbone interface. also gets us a cache maybe?
        mem_wb  = wishbone.Interface(
            data_width = mem_bus.data_width,
            adr_width  = 32-log2_int(mem_bus.data_width//8))
        mem_a2w = axi.AXI2Wishbone(
            axi          = mem_bus,
            wishbone     = mem_wb,
            base_address = 0)
        self.submodules += mem_a2w

        # Insert L2 cache inbetween Wishbone bus and LiteDRAM
        l2_cache_size = max(l2_cache_size, int(2*mem_bus.data_width/8)) # Use minimal size if lower
        l2_cache_size = 2**int(log2(l2_cache_size))                  # Round to nearest power of 2
        l2_cache_data_width = max(mem_bus.data_width, l2_cache_min_data_width)
        l2_cache = wishbone.Cache(
            cachesize = l2_cache_size//4,
            master    = mem_wb,
            slave     = wishbone.Interface(l2_cache_data_width),
            reverse   = l2_cache_reverse)
        if l2_cache_full_memory_we:
            l2_cache = FullMemoryWE()(l2_cache)
        self.l2_cache = l2_cache
        litedram_wb = self.l2_cache.slave
        self.add_config("L2_SIZE", l2_cache_size)

        # Request a LiteDRAM native port.
        port = sdram.crossbar.get_port()
        self.submodules += LiteDRAMWishbone2Native(
            wishbone     = litedram_wb,
            port         = port,
            base_address = self.bus.regions["emu_ram"].origin)