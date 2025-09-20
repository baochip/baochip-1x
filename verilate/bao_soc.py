#!/usr/bin/env python3
#
# Copyright (c) 2022 Cramium Labs, Inc.
# Derived from litex_soc_gen.py:
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

# sim dependencies:
# verilator (from source), libevent-dev, libjson-c-dev

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../deps/migen/migen"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../deps/migen/litex"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../deps"))

from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect import stream

from litex.build.generic_platform import *
from litex.build.sim import SimPlatform
from litex.build.sim.config import SimConfig

from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *

from litex.build.xilinx import XilinxPlatform, VivadoProgrammer
from litex.soc.cores.clock import S7MMCM, S7IDELAYCTRL
from migen.genlib.resetsync import AsyncResetSynchronizer
from litex.soc.interconnect.csr import *

from litex.soc.cores import uart
from litex.soc.integration.doc import AutoDoc, ModuleDoc

from litex.soc.interconnect.axi import AXIInterface
from soc_oss.axi_ram import AXIRAM

from bao_common import CramSoC
from bao_udma import CramSoCUdma

import shutil

VEX_VERILOG_PATH = "../VexRiscv/VexRiscv_CramSoC.v"

# IOs ----------------------------------------------------------------------------------------------

_io = [
    # specific to Xsim env
    ("lpclk", 0, Pins(1),),
    ("clk12", 0, Pins(1),),
    ("reset", 0, Pins(1)),

    # Clk / Rst.
    ("sys_clk", 0, Pins(1)),
    ("p_clk", 0, Pins(1)),
    ("h_clk", 0, Pins(1)),
    ("pio_clk", 0, Pins(1)),
    ("bio_clk", 0, Pins(1)),
    # ("sys_reset", 0, Pins(1)),

    ("jtag", 0,
         Subsignal("tck", Pins("U11"), IOStandard("LVCMOS18")),
         Subsignal("tms", Pins("P6"), IOStandard("LVCMOS18")),
         Subsignal("tdi", Pins("P7"), IOStandard("LVCMOS18")),
         Subsignal("tdo", Pins("R6"), IOStandard("LVCMOS18")),
    ),

    # mapped to GPIOs 0-4
    ("jtag_cpu", 0,
         Subsignal("tck", Pins("F14"), IOStandard("LVCMOS33")),
         Subsignal("tms", Pins("F15"), IOStandard("LVCMOS33")),
         Subsignal("tdi", Pins("E16"), IOStandard("LVCMOS33")),
         Subsignal("tdo", Pins("G15"), IOStandard("LVCMOS33")),
         Subsignal("trst_n", Pins("H15"), IOStandard("LVCMOS33")),
         Misc("SLEW=SLOW"),
    ),

    ("serial", 0, # wired to the RPi
        Subsignal("tx", Pins("V6")),
        Subsignal("rx", Pins("V7"), Misc("PULLUP True")),
        IOStandard("LVCMOS18"),
        Misc("SLEW=SLOW"),
    ),

    # Simulation UART log
    ("sim_uart", 0,
        Subsignal("kernel", Pins(8)),
        Subsignal("kernel_valid", Pins(1)),
        Subsignal("log", Pins(8)),
        Subsignal("log_valid", Pins(1)),
        Subsignal("app", Pins(8)),
        Subsignal("app_valid", Pins(1)),
    ),

    ("duart", 0,
        Subsignal("tx", Pins(1)),
    ),
    ("pio", 0,
        Subsignal("gpio", Pins(32)),
    ),

    # LCD interface
    ("lcd", 0,
        Subsignal("sclk", Pins("H17")), # DVT
        Subsignal("scs",  Pins("G17")), # DVT
        Subsignal("si",   Pins("H18")), # DVT
        IOStandard("LVCMOS33"),
        Misc("SLEW=SLOW"),
        Misc("DRIVE=4"),
     ),

     # Simulation "I/O"
     ("simio", 0,
        Subsignal("success", Pins(1)),
        Subsignal("done", Pins(1)),
        Subsignal("report", Pins(32)),
        Subsignal("coreuser", Pins(8)),
        Subsignal("sysclk", Pins(1)),
     ),

    # Trimming bits
     ("trimming", 0,
        Subsignal("reset", Pins(32)),
        Subsignal("reset_ena", Pins(1)),
     )
]

# Simulation UART ----------------------------------------------------------------------------------
class SimUartPhy(Module, AutoCSR):
    def __init__(self, data_in, data_in_valid, data_in_ready, data_out, data_out_valid, clk_freq, baudrate=115200, with_dynamic_baudrate=False):
        tuning_word = int((baudrate/clk_freq)*2**32)
        if with_dynamic_baudrate:
            self._tuning_word  = CSRStorage(32, reset=tuning_word)
            tuning_word = self._tuning_word.storage
        self.submodules.tx = SimPhyTx(data_out, data_out_valid)
        self.submodules.rx = SimPhyRx(data_in, data_in_valid, data_in_ready)
        self.sink, self.source = self.tx.sink, self.rx.source

# Simulation CRG -----------------------------------------------------------------------------------
class SimCRG(Module):
    def __init__(self, clk, p_clk, pio_clk, bio_clk, h_clk, rst, sleep_req):
        self.clock_domains.cd_sys = ClockDomain()
        self.clock_domains.cd_por = ClockDomain(reset_less=True)
        self.clock_domains.cd_p = ClockDomain()
        self.clock_domains.cd_pio = ClockDomain()
        self.clock_domains.cd_bio = ClockDomain()
        self.clock_domains.cd_sys_always_on = ClockDomain()
        self.clock_domains.cd_h_clk = ClockDomain()

        # Power on Reset (vendor agnostic)
        int_rst = Signal(reset=1)
        self.sync.por += int_rst.eq(rst)
        self.comb += [
            self.cd_sys.clk.eq(clk & ~sleep_req),
            self.cd_por.clk.eq(clk),
            self.cd_sys.rst.eq(int_rst),
            self.cd_p.clk.eq(p_clk),
            self.cd_p.rst.eq(int_rst),
            self.cd_pio.clk.eq(pio_clk),
            self.cd_pio.rst.eq(int_rst),
            self.cd_bio.clk.eq(bio_clk),
            self.cd_bio.rst.eq(int_rst),
            self.cd_sys_always_on.clk.eq(clk),
            self.cd_h_clk.clk.eq(h_clk),
            self.cd_h_clk.rst.eq(int_rst),
        ]

# XsimCRG ------------------------------------------------------------------------------------------

class XsimCRG(Module):
    def __init__(self, platform, sys_clk_freq, spinor_edge_delay_ns=2.5, sim=False):
        self.warm_reset = Signal()
        self.power_down = Signal()
        self.crypto_on = Signal()

        self.clock_domains.cd_sys   = ClockDomain()
        self.clock_domains.cd_spi   = ClockDomain()
        self.clock_domains.cd_lpclk = ClockDomain()
        self.clock_domains.cd_spinor = ClockDomain()
        self.clock_domains.cd_clk200 = ClockDomain()
        self.clock_domains.cd_clk50 = ClockDomain()
        self.clock_domains.cd_usb_48 = ClockDomain()
        self.clock_domains.cd_usb_12 = ClockDomain()
        self.clock_domains.cd_raw_12 = ClockDomain()

        self.clock_domains.cd_clk200_crypto = ClockDomain()
        self.clock_domains.cd_sys_crypto = ClockDomain()
        self.clock_domains.cd_sys_always_on = ClockDomain()
        self.clock_domains.cd_clk50_always_on = ClockDomain()

        # # #

        sysclk_ns = 1e9 / sys_clk_freq
        # convert delay request in ns to degrees, where 360 degrees is one whole clock period
        phase_f = (spinor_edge_delay_ns / sysclk_ns) * 360
        # round phase to the nearest multiple of 7.5 (needs to be a multiple of 45 / CLKOUT2_DIVIDE = 45 / 6 = 7.5
        # note that CLKOUT2_DIVIDE is automatically calculated by mmcm.create_clkout() below
        phase = round(phase_f / 7.5) * 7.5

        clk32khz = platform.request("lpclk")
        self.specials += Instance("BUFG", i_I=clk32khz, o_O=self.cd_lpclk.clk)
        platform.add_platform_command("create_clock -name lpclk -period {:0.3f} [get_nets lpclk]".format(1e9 / 32.768e3))

        clk12 = platform.request("clk12")
        # Note: below feature cannot be used because Litex appends this *after* platform commands! This causes the generated
        # clock derived constraints immediately below to fail, because .xdc file is parsed in-order, and the main clock needs
        # to be created before the derived clocks. Instead, we use the line afterwards.
        # platform.add_period_constraint(clk12, 1e9 / 12e6)
        platform.add_platform_command("create_clock -name clk12 -period {:0.3f} [get_nets clk12]".format(1e9 / 12e6))
        # The above constraint must strictly proceed the below create_generated_clock constraints in the .XDC file

        # This allows PLLs/MMCMEs to be placed anywhere and reference the input clock
        self.clk12_bufg = Signal()
        self.specials += Instance("BUFG", i_I=clk12, o_O=self.clk12_bufg)
        self.comb += self.cd_raw_12.clk.eq(self.clk12_bufg)

        self.submodules.mmcm = mmcm = S7MMCM(speedgrade=-1)
        mmcm.register_clkin(self.clk12_bufg, 12e6)
        # we count on clocks being assigned to the MMCME2_ADV in order. If we make more MMCME2 or shift ordering, these constraints must change.
        mmcm.create_clkout(self.cd_usb_48, 48e6, with_reset=False, buf="bufgce", ce=mmcm.locked) # 48 MHz for USB; always-on
        platform.add_platform_command("create_generated_clock -name usb_48 [get_pins MMCME2_ADV/CLKOUT0]")

        mmcm.create_clkout(self.cd_spi, 20e6, with_reset=False, buf="bufgce", ce=mmcm.locked & ~self.power_down)
        platform.add_platform_command("create_generated_clock -name spi_clk [get_pins MMCME2_ADV/CLKOUT1]")

        mmcm.create_clkout(self.cd_spinor, sys_clk_freq, phase=phase, with_reset=False, buf="bufgce", ce=mmcm.locked & ~self.power_down)  # delayed version for SPINOR cclk (different from COM SPI above)
        platform.add_platform_command("create_generated_clock -name spinor [get_pins MMCME2_ADV/CLKOUT2]")

        # clk200 does not gate off because we want to keep the IDELAYCTRL block "warm"
        mmcm.create_clkout(self.cd_clk200, 200e6, with_reset=False, buf="bufg",
            gated_replicas={self.cd_clk200_crypto : (mmcm.locked & (~self.power_down | self.crypto_on))}) # 200MHz always-on required for IDELAYCTL
        platform.add_platform_command("create_generated_clock -name clk200 [get_pins MMCME2_ADV/CLKOUT3]")

        # clk50 is explicitly for the crypto unit, so it doesn't have the _crypto suffix, consfusingly...
        mmcm.create_clkout(self.cd_clk50, 50e6, with_reset=False, buf="bufgce", ce=(mmcm.locked & (~self.power_down | self.crypto_on)),
            gated_replicas={self.cd_clk50_always_on: mmcm.locked}) # 50MHz for ChaCha conditioner, attached to the always-on TRNG
        platform.add_platform_command("create_generated_clock -name clk50 [get_pins MMCME2_ADV/CLKOUT4]")

        mmcm.create_clkout(self.cd_usb_12, 12e6, with_reset=False, buf="bufgce", ce=mmcm.locked) # 12 MHz for USB; always-on
        platform.add_platform_command("create_generated_clock -name usb_12 [get_pins MMCME2_ADV/CLKOUT5]")

        # needs to be exactly 100MHz hence margin=0
        mmcm.create_clkout(self.cd_sys, sys_clk_freq, margin=0, with_reset=False, buf="bufgce", ce=(~self.power_down & mmcm.locked),
            gated_replicas={self.cd_sys_crypto : (mmcm.locked & (~self.power_down | self.crypto_on)), self.cd_sys_always_on : mmcm.locked})
        platform.add_platform_command("create_generated_clock -name sys_clk [get_pins MMCME2_ADV/CLKOUT6]")

        # timing to the "S" pins is not sensitive because we don't care if there is an extra clock pulse relative
        # to the gating. Glitch-free operation is guaranteed regardless!
        platform.add_platform_command('set_false_path -through [get_pins BUFGCTRL*/S*]')
        # platform.add_platform_command('set_false_path -through [get_nets vns_rst_meta*]') # fixes for a later version of vivado

        self.ignore_locked = Signal()
        reset_combo = Signal()
        if sim:
            self.comb += reset_combo.eq(self.warm_reset | (~mmcm.locked & ~self.ignore_locked) | platform.request("reset"))
        else:
            self.comb += reset_combo.eq(self.warm_reset | (~mmcm.locked & ~self.ignore_locked))
        # See https://forums.xilinx.com/t5/Other-FPGA-Architecture/MMCM-Behavior-After-Its-PWRDWN-Port-Is-Asserted-and-Then/td-p/792324
        # "The DRP functional logic itself does not behave differently for PWRDWN or RST.
        # The "registers" programmed previously through the DRP (or any other once) are not affected either
        # way because they are configuration cells and are only overwritten if you re-program the part or
        # by another DRP operation. Typically, from an application perspective, PWRDWN and RST are identical.
        # The difference is obviously that in the PWRDWN case the MMCM completely shuts down for an extended period
        # of time even if asserted only briefly. Takes a while to bring back the regulators vs simply reset.
        # In addition, since power is turned of, it takes longer to reacquire LOCK vs RST because the VCO starts from scratch."
        #self.comb += mmcm.reset.eq(self.power_down)
        #self.comb += mmcm.power_down.eq(self.power_down)
        self.specials += [
            AsyncResetSynchronizer(self.cd_usb_48, reset_combo),
            AsyncResetSynchronizer(self.cd_spi, reset_combo),
            AsyncResetSynchronizer(self.cd_spinor, reset_combo),
            AsyncResetSynchronizer(self.cd_clk200, reset_combo),
            AsyncResetSynchronizer(self.cd_clk50, reset_combo),
            AsyncResetSynchronizer(self.cd_usb_12, reset_combo),
            AsyncResetSynchronizer(self.cd_sys, reset_combo),

            AsyncResetSynchronizer(self.cd_clk200_crypto, reset_combo),
            AsyncResetSynchronizer(self.cd_sys_crypto, reset_combo),

            AsyncResetSynchronizer(self.cd_sys_always_on, reset_combo),
            AsyncResetSynchronizer(self.cd_clk50_always_on, reset_combo),
        ]

        # Add an IDELAYCTRL primitive for the SpiOpi block
        self.submodules += S7IDELAYCTRL(self.cd_clk200, reset_cycles=32) # 155ns @ 200MHz, min 59.28ns

def common_extensions(self):
    # Add crossbar ports for memory
    reram_axi = AXIInterface(data_width=64, address_width=32, id_width=6, bursting=True)
    self.submodules.axi_reram = AXIRAM(
        self.platform, reram_axi, size=self.axi_mem_map["reram"][1], name="reram", init=self.bios_data)
    sram_axi = AXIInterface(data_width=64, address_width=32, id_width=6, bursting=True)
    self.submodules.axi_sram = AXIRAM(self.platform, sram_axi, size=self.axi_mem_map["sram"][1], name="sram")
    xip_axi = AXIInterface(data_width=64, address_width=32, id_width=6, bursting=True)
    self.submodules.xip_sram = AXIRAM(self.platform, xip_axi, size=65536, name="xip") # just a small amount of RAM for testing
    # vex debug is internal to the core, no interface to build

    self.mbus.add_master(name = "reram", m_axi=reram_axi, origin=self.axi_mem_map["reram"][0], size=self.axi_mem_map["reram"][1])
    self.mbus.add_master(name = "sram",  m_axi=sram_axi,  origin=self.axi_mem_map["sram"][0],  size=self.axi_mem_map["sram"][1])
    self.mbus.add_master(name = "xip",  m_axi=xip_axi,  origin=self.axi_mem_map["xip"][0],  size=self.axi_mem_map["sram"][1])

    # Simulation framework I/O ----------------------------------------------------------------------
    self.sim = sim = self.platform.request("simio")
    self.comb += [
        sim.report.eq(self.test),
        sim.success.eq(0),
        sim.done.eq(self.sim_done.storage),
        sim.coreuser.eq(self.coreuser),
    ]

    self.specials += Instance("finisher",
        i_report=self.test,
        i_done=self.sim.done,
        i_clk = ClockSignal(),
    )
    self.platform.add_source("sim_support/finisher.v")

# Tune the common platform for verilator --------------------------------------------------------
def verilator_extensions(self, nosave=False):
    if self.sim_debug:
        self.platform.add_debug(self, reset=1 if self.trace_reset_on else 0)
    else:
        # Enable waveform dumping (slows down simulation a bit)
        # Can set to zero for a much faster sim, but no waveforms are saved.
        if nosave:
            self.comb += self.platform.trace.eq(0)
        else:
            self.comb += self.platform.trace.eq(1)

    # Clockgen cluster -------------------------------------------------------------------------
    reset_cycles = 64
    reset_counter = Signal(log2_int(reset_cycles), reset=reset_cycles - 1)
    ic_reset      = Signal(reset=1)
    self.sync.por += \
        If(reset_counter != 0,
            reset_counter.eq(reset_counter - 1),
            If(reset_counter > reset_cycles // 2,
               # start with reset de-asserted so we can capture the rising edge of reset
               # to correctly reset async reset logic that needs an assertion transition to work properly.
               ic_reset.eq(0)
            ).Else(
                ic_reset.eq(1)
            )
        ).Else(
            ic_reset.eq(0)
        )
    self.crg = SimCRG(
        self.platform.request("sys_clk"),
        self.platform.request("p_clk"),
        self.platform.request("pio_clk"),
        self.platform.request("bio_clk"),
        self.platform.request("h_clk"),
        ic_reset, self.sleep_req)

    # Add SoC memory regions
    for (name, region) in self.axi_mem_map.items():
        self.add_memory_region(name=name, origin=region[0], length=region[1])


# Tune the common platform for xsim ------------------------------------------------------------
def xsim_extensions(self):
    # Clockgen cluster -------------------------------------------------------------------------
    warm_reset = Signal()
    self.submodules.crg = XsimCRG(self.platform, self.sys_clk_freq, spinor_edge_delay_ns=2.5, sim=True)
    self.comb += self.crg.warm_reset.eq(warm_reset) # mirror signal here to hit the Async reset injectors
    # Connect "pclk" to "sysclk"
    self.clock_domains.cd_p      = ClockDomain()
    self.comb += self.cd_p.clk.eq(ClockSignal())
    # Connect "pio" to "clk50"
    self.clock_domains.cd_pio    = ClockDomain()
    self.comb += self.cd_pio.clk.eq(ClockSignal("clk50"))
    self.specials += [
        AsyncResetSynchronizer(self.cd_p, ResetSignal()),
        AsyncResetSynchronizer(self.cd_pio, ResetSignal()),
    ]

    # Add SoC memory regions
    for (name, region) in self.axi_mem_map.items():
        self.add_memory_region(name=name, origin=region[0], length=region[1])

    # Internal reset ---------------------------------------------------------------------------
    gsr = Signal()
    self.specials += MultiReg(warm_reset, gsr)
    self.specials += [
        # De-activate the CCLK interface, parallel it with a GPIO
        Instance("STARTUPE2",
            i_CLK       = 0,
            i_GSR       = gsr,
            i_GTS       = 0,
            i_KEYCLEARB = 1,
            i_PACK      = 0,
            i_USRDONEO  = 1,
            i_USRDONETS = 1,
            i_USRCCLKO  = 0,
            i_USRCCLKTS = 1,  # Force to tristate
            # o_CFGMCLK   = self.cfgmclk,
        ),
    ]

# Platform -----------------------------------------------------------------------------------------

class Platform(SimPlatform):
    def __init__(self):
        SimPlatform.__init__(self, "SIM", _io)

def keep_only(axi_group, names=[]):
    sig_list = axi_group.layout
    ret = []
    for signal in sig_list:
        if signal[0] in names:
            ret += [getattr(axi_group, signal[0])]
        if signal[0] == "payload":
            for subsignal in signal[1]:
                if subsignal[0] in names:
                    ret += [getattr(axi_group.payload, subsignal[0])]
    return ret

# Platform -----------------------------------------------------------------------------------------

class XsimPlatform(XilinxPlatform):
    def __init__(self, io, toolchain="vivado", programmer="vivado"):
        part = "xc7a100t-csg324-1"
        XilinxPlatform.__init__(self, part, io, toolchain=toolchain)

        self.add_platform_command(
            "set_property CONFIG_VOLTAGE 3.3 [current_design]")
        self.add_platform_command(
            "set_property CFGBVS GND [current_design]")
        self.add_platform_command(
            "set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]")
        self.add_platform_command(
            "set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]")
        self.toolchain.bitstream_commands = [
            "set_property CONFIG_VOLTAGE 3.3 [current_design]",
            "set_property CFGBVS GND [current_design]",
            "set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]",
            "set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]",
        ]
    def do_finalize(self, fragment):
        XilinxPlatform.do_finalize(self, fragment)

# Build --------------------------------------------------------------------------------------------
def generate_gtkw_savefile(builder, vns, trace_fst=False):
    from litex.build.sim import gtkwave as gtkw
    dumpfile = os.path.join(builder.gateware_dir, "sim.{}".format("fst" if trace_fst else "vcd"))
    savefile = os.path.join(builder.gateware_dir, "sim.gtkw")
    soc = builder.soc

    with gtkw.GTKWSave(vns, savefile=savefile, dumpfile=dumpfile) as save:
        save.clocks()
        save.fsm_states(soc)

        ar_rec = keep_only(soc.mbus.s_axis["dbus"].axi.ar, ["addr", "burst", "id", "len", "valid", "ready"])
        for s in ar_rec:
            save.add(s, mappers=[gtkw.axi_ar_sorter(), gtkw.axi_ar_colorer()])

        #save.add(soc.mbus.s_axis["dbus"].axi.aw, mappers=[gtkw.axi_sorter(), gtkw.axi_colorer()])
        #save.add(soc.mbus.s_axis["dbus"].axi.b, mappers=[gtkw.axi_sorter(), gtkw.axi_colorer()])
        #save.add(soc.mbus.s_axis["dbus"].axi.r, mappers=[gtkw.axi_sorter(), gtkw.axi_colorer()])
        #save.add(soc.mbus.s_axis["dbus"].axi.w, mappers=[gtkw.axi_sorter(), gtkw.axi_colorer()])

def auto_int(x):
    return int(x, 0)

def sim_args(parser):
    # Speed. In reality, just selects whether we save a waveform, or not.
    parser.add_argument("--speed",                type=str, default="normal",
                        choices=['normal', 'fast'],
                        help="Run at `normal` or `fast` speed. Fast runs do not save waveform data. Only valid with `verilator` simulator option.")

    parser.add_argument("--simulator",            type=str, default="verilator",
                        choices=['verilator', 'xsim'],
                        help="Switch between `verilator` or `xsim`")

    # Trigger CI mode for Xsim. Not valid for verilator.
    parser.add_argument(
        "-c", "--ci", default=False, action="store_true", help="Run simulation in non-interactive mode. Only for Xsim."
    )

    # Analyzer.
    parser.add_argument("--with-analyzer",        action="store_true",     help="Enable Analyzer support.")

    # Debug/Waveform.
    parser.add_argument("--sim-debug",            action="store_true",     help="Add simulation debugging modules.")
    parser.add_argument("--gtkwave-savefile",     action="store_true",     help="Generate GTKWave savefile.")
    parser.add_argument("--non-interactive",      action="store_true",     help="Run simulation without user input.")

    # Build just the SVDs
    parser.add_argument("--svd-only",             action="store_true",     help="Just build the SVDs for the OS build")

    # specify BIOS path
    parser.add_argument("--bios", type=str, help="Override default BIOS location")
    parser.add_argument("--boot-offset", type=auto_int, default=0)

    # compatibility with demo scripts
    parser.add_argument("--build",                action="store_true",     help="compatibility flag, ignored by this script")

    # UDMA simulation variant
    parser.add_argument("--udma",                 action="store_true",     help="use UDMA variant of SoC")

    parser.add_argument("--vextype",              type=str, default="vexi", choices=['vexi', 'vexii'],  help="Select Vex variant")

def main():
    from litex.build.parser import LiteXArgumentParser
    parser = LiteXArgumentParser(description="LiteX SoC Simulation utility")
    parser.set_platform(SimPlatform)
    sim_args(parser)
    args = parser.parse_args()

    soc_kwargs = soc_core_argdict(args)
    if args.simulator == 'xsim':
        simulator = 'xsim'
        production_models = True
    else:
        simulator = 'verilator'
        production_models = False

    if simulator == 'verilator':
        sys_clk_freq = int(800e6)
        realistic = True # turn of realism for faster prints, etc. useful when debugging CPU bugs, not peripheral bugs
        # Also: turning of realism may introduce some timing errors in peripherals; in particular reads on APB (PCLK)
        # domain may not succeed because not enough time elapses for them to be filled.
        if realistic:
            p_clk = 100e6
            pio_clk = 200e6
        else:
            p_clk = 400e6 # turbocharge for faster prints; unrealistic in actual system
            pio_clk = 400e6
    else:
        sys_clk_freq = int(100e6)
        # these are the "system realistic" settings
        p_clk = 100e6
        pio_clk = 200e6
    sim_config   = SimConfig()
    sim_config.add_clocker("sys_clk", freq_hz=sys_clk_freq)
    sim_config.add_clocker("p_clk", freq_hz=p_clk) # simulated down to 50MHz, but left at 100MHz to speed up simulations
    sim_config.add_clocker("pio_clk", freq_hz=pio_clk)
    sim_config.add_clocker("bio_clk", freq_hz=sys_clk_freq)
    sim_config.add_clocker("h_clk", freq_hz=p_clk)

    bios_path = args.bios

    if simulator == "verilator":
        platform = Platform()
    else:
        platform = XsimPlatform(_io)

    if args.udma:
        soc = CramSoCUdma(
            platform,
            variant="sim",
            bios_path=bios_path,
            boot_offset=args.boot_offset,
            sys_clk_freq=sys_clk_freq,
            sim_debug          = args.sim_debug,
            trace_reset_on     = False,
            production_models  = production_models,
            **soc_kwargs
        )
        if args.speed == "fast":
            nosave = True
        else:
            nosave = False

        # Add extensions for each simulator --------------------------------------------------------
        CramSoCUdma.common_extensions = common_extensions
        soc.common_extensions()

        if simulator == 'verilator':
            CramSoCUdma.sim_extensions = verilator_extensions
            soc.sim_extensions(nosave)

            def pre_run_callback(vns):
                generate_gtkw_savefile(builder, vns)
        else:
            CramSoCUdma.xsim_extensions = xsim_extensions
            soc.xsim_extensions()
    else:
        soc = CramSoC(
            platform,
            variant="sim",
            bios_path=bios_path,
            boot_offset=args.boot_offset,
            sys_clk_freq=sys_clk_freq,
            sim_debug          = args.sim_debug,
            trace_reset_on     = False,
            production_models  = production_models,
            vextype            = args.vextype,
            **soc_kwargs
        )
        if args.speed == "fast":
            nosave = True
        else:
            nosave = False

        # Add extensions for each simulator --------------------------------------------------------
        CramSoC.common_extensions = common_extensions
        soc.common_extensions()

        if simulator == 'verilator':
            CramSoC.sim_extensions = verilator_extensions
            soc.sim_extensions(nosave)

            def pre_run_callback(vns):
                generate_gtkw_savefile(builder, vns)
        else:
            CramSoC.xsim_extensions = xsim_extensions
            soc.xsim_extensions()

    # turn off regular_comb for simulation
    rc=True

    if simulator == 'verilator':
        # Setup the builder and run it --------------------------------------------------------------
        builder = Builder(soc,
            csr_csv="build/csr.csv",
            csr_svd="build/software/soc.svd",
        )
        builder.software_packages=[] # necessary to bypass Meson dependency checks required by Litex libc

        if args.svd_only:
            builder.build(run=False, regular_comb=rc)
        else:
            destdir = './build/sim/gateware/'
            shutil.copy('./build/gateware/reram_mem.init', destdir)
            shutil.copy('../VexRiscv/memory_AesZknPlugin_rom_storage_Rom_1rs.v', destdir)
            shutil.copy('../rtl/modules/common/rtl/template.sv', destdir)
            shutil.copytree("sim_support/axi", destdir, dirs_exist_ok=True)
            if args.vextype == 'vexii':
                shutil.copy('../VexiiRiscv/VexiiRiscv-cramsoc.sv', destdir + 'VexiiRiscv.sv')
                shutil.copy('../VexiiRiscv/early0_AesZknPlugin_logic_onData_rom_storage.v', destdir)
                shutil.copy('./build/gateware/cram_vexii.v', destdir)

            # this runs the sim
            builder.build(
                sim_config       = sim_config,
                interactive      = not args.non_interactive,
                pre_run_callback = pre_run_callback,
                regular_comb     = rc,
                **parser.toolchain_argdict,
            )
    else:
        builder = Builder(soc, output_dir="build",
            csr_csv="build/csr.csv", csr_svd="build/software/soc.svd",
            compile_software=False, compile_gateware=False)

        builder.build(run=False, regular_comb=rc)

        if args.svd_only is False:
            from sim_support.sim_bench import SimRunner
            SimRunner(args.ci, [], vex_verilog_path=VEX_VERILOG_PATH, tb='top_tb_xsim',
                        production_models=production_models)

if __name__ == "__main__":
    from datetime import datetime
    start = datetime.now()
    ret = main()
    print("Run completed in {}".format(datetime.now()-start))

    sys.exit(ret)
