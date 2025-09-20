#!/usr/bin/env python3

from migen import *
from migen.genlib.cdc import *

from litex.build.generic_platform import *
from litex.build.xilinx import XilinxPlatform
from litex.build.sim import SimPlatform

# IOs ----------------------------------------------------------------------------------------------

_io = [
    ("aclk", 0, Pins(1)),
    ("aclk_reset_n", 0, Pins(1)),

    # Mbox signals
    ("mbox", 0,
        Subsignal("w_dat", Pins(32)),
        Subsignal("w_valid", Pins(1)),
        Subsignal("w_ready", Pins(1)),
        Subsignal("w_done", Pins(1)),
        Subsignal("r_dat", Pins(32)),
        Subsignal("r_valid", Pins(1)),
        Subsignal("r_ready", Pins(1)),
        Subsignal("r_done", Pins(1)),
        Subsignal("w_abort", Pins(1)),
        Subsignal("r_abort", Pins(1)),
    ),

    # AHB register signals - this clock domain may be much slower
    ("pclk", 0, Pins(1)),
    ("pclk_reset_n", 0, Pins(1)),
    ("sfr", 0,
        Subsignal("cr_wdata", Pins(32)),
        Subsignal("cr_wdata_written", Pins(1)), # pulse if CR written
        Subsignal("sr_rdata", Pins(32)),
        Subsignal("sr_rdata_read", Pins(1)), # pulse if SR read
        Subsignal("int_available", Pins(1)),
        Subsignal("int_abort_init", Pins(1)),
        Subsignal("int_abort_done", Pins(1)),
        Subsignal("int_error", Pins(1)),
        Subsignal("sr_read", Pins(1)), # pulse if SR read
        Subsignal("sr_rx_avail", Pins(1)),
        Subsignal("sr_tx_free", Pins(1)),
        Subsignal("sr_abort_in_progress", Pins(1)),
        Subsignal("sr_abort_ack", Pins(1)),
        Subsignal("sr_rx_err", Pins(1)),
        Subsignal("sr_tx_err", Pins(1)),
        Subsignal("ar_abort", Pins(1)), # pulse
        Subsignal("ar_done", Pins(1)), # pulse
    )
]

# Platform -----------------------------------------------------------------------------------------

class Platform(GenericPlatform):
    default_clk_name   = "clk100"
    default_clk_period = 1e9/100e6

    def __init__(self):
        GenericPlatform.__init__(self, "generic", _io)# (self, "xc7a100t-csg324-1", _io, toolchain="vivado")

    def build(self, fragment, build_dir, build_name, **kwargs):
        os.makedirs(build_dir, exist_ok=True)
        os.chdir(build_dir)
        conv_output = self.get_verilog(fragment, name=build_name, regs_init=False)
        conv_output.write(f"{build_name}.v")

# Design -------------------------------------------------------------------------------------------

# Create our platform (fpga interface)
platform = Platform()


class MultiRegImpl(Module):
    def __init__(self, i, o, odomain, n, reset=0):
        self.i = i
        self.o = o
        self.odomain = odomain

        w, signed = value_bits_sign(self.i)
        self.regs = [Signal((w, signed), reset=reset, reset_less=True)
                for i in range(n)]

        ###

        sd = getattr(self.sync, self.odomain)
        src = self.i
        for reg in self.regs:
            sd += reg.eq(src)
            src = reg
        self.comb += self.o.eq(src)
        for reg in self.regs:
            reg.attr.add("no_retiming")

class MultiReg(Special):
    def __init__(self, i, o, odomain="sys", n=2, reset=0):
        Special.__init__(self)
        self.i = wrap(i)
        self.o = wrap(o)
        self.odomain = odomain
        self.n = n
        self.reset = reset

    def iter_expressions(self):
        yield self, "i", SPECIAL_INPUT
        yield self, "o", SPECIAL_OUTPUT

    def rename_clock_domain(self, old, new):
        Special.rename_clock_domain(self, old, new)
        if self.odomain == old:
            self.odomain = new

    def list_clock_domains(self):
        r = Special.list_clock_domains(self)
        r.add(self.odomain)
        return r

    @staticmethod
    def lower(dr):
        return MultiRegImpl(dr.i, dr.o, dr.odomain, dr.n, dr.reset)


class PulseSynchronizer(Module):
    def __init__(self, idomain, odomain):
        self.i = Signal()
        self.o = Signal()

        ###

        toggle_i = Signal(reset_less=False)
        toggle_o = Signal()  # registered reset_less by MultiReg
        toggle_o_r = Signal(reset_less=True)

        sync_i = getattr(self.sync, idomain)
        sync_o = getattr(self.sync, odomain)

        sync_i += If(self.i, toggle_i.eq(~toggle_i))
        self.specials += MultiReg(toggle_i, toggle_o, odomain)
        sync_o += toggle_o_r.eq(toggle_o)
        self.comb += self.o.eq(toggle_o ^ toggle_o_r)


class BlindTransfer(Module):
    """
    PulseSynchronizer but with the input "blinded" until the pulse
    is received in the destination domain.

    This avoids situations where two pulses in the input domain
    at a short interval (shorter than the destination domain clock
    period) causes two toggles of the internal PulseSynchronizer
    signal and no output pulse being emitted.

    With this module, any activity in the input domain will generate
    at least one pulse at the output.

    An optional data word can be transferred with each registered pulse.
    """
    def __init__(self, idomain, odomain, data_width=0):
        self.i = Signal()
        self.o = Signal()
        if data_width:
            self.data_i = Signal(data_width)
            self.data_o = Signal(data_width, reset_less=True)

        # # #

        ps = PulseSynchronizer(idomain, odomain)
        ps_ack = PulseSynchronizer(odomain, idomain)
        self.submodules += ps, ps_ack
        blind = Signal()
        isync = getattr(self.sync, idomain)
        isync += [
            If(self.i, blind.eq(1)),
            If(ps_ack.o, blind.eq(0))
        ]
        self.comb += [
            ps.i.eq(self.i & ~blind),
            ps_ack.i.eq(ps.o),
            self.o.eq(ps.o)
        ]

        if data_width:
            bxfer_data = Signal(data_width, reset_less=True)
            isync += If(ps.i, bxfer_data.eq(self.data_i))
            bxfer_data.attr.add("no_retiming")
            self.specials += MultiReg(bxfer_data, self.data_o,
                                      odomain=odomain)


# Create our module (fpga description)
class MboxClient(Module):
    def __init__(self, platform):
        self.clock_domains.cd_sys = ClockDomain()
        self.clock_domains.cd_pclk = ClockDomain()
        reset = ~platform.request("aclk_reset_n")
        reset_pclk = ~platform.request("pclk_reset_n")
        self.comb += [
            self.cd_sys.clk.eq(platform.request("aclk")),
            self.cd_sys.rst.eq(reset),
            self.cd_pclk.clk.eq(platform.request("pclk")),
            self.cd_pclk.rst.eq(reset_pclk),
        ]

        mbox_ext = platform.request("mbox")
        sfr = platform.request("sfr")

        # cross-domain syncs
        cr_wdata_written_aclk = Signal()
        sr_rdata_read_aclk = Signal()
        sr_read_aclk = Signal()
        ar_abort_aclk = Signal()
        ar_done_aclk = Signal()
        int_available_aclk = Signal()
        int_abort_init_aclk = Signal()
        int_abort_done_aclk = Signal()

        self.submodules.wdata_sync = BlindTransfer("pclk", "sys")
        self.submodules.rdata_sync = BlindTransfer("pclk", "sys")
        self.submodules.read_sync = BlindTransfer("pclk", "sys")
        self.submodules.abort_sync = BlindTransfer("pclk", "sys")
        self.submodules.done_sync = BlindTransfer("pclk", "sys")
        self.submodules.int_available_sync = BlindTransfer("sys", "pclk")
        self.submodules.int_abort_init_sync = BlindTransfer("sys", "pclk")
        self.submodules.int_abort_done_sync = BlindTransfer("sys", "pclk")
        self.comb += [
            self.wdata_sync.i.eq(sfr.cr_wdata_written),
            cr_wdata_written_aclk.eq(self.wdata_sync.o),
            self.rdata_sync.i.eq(sfr.sr_rdata_read), # data is read
            sr_rdata_read_aclk.eq(self.rdata_sync.o),
            self.read_sync.i.eq(sfr.sr_read), # status register is read
            sr_read_aclk.eq(self.read_sync.o),
            self.abort_sync.i.eq(sfr.ar_abort),
            ar_abort_aclk.eq(self.abort_sync.o),
            self.done_sync.i.eq(sfr.ar_done),
            ar_done_aclk.eq(self.done_sync.o),

            sfr.int_available.eq(self.int_available_sync.o),
            self.int_available_sync.i.eq(int_available_aclk),
            sfr.int_abort_init.eq(self.int_abort_init_sync.o),
            self.int_abort_init_sync.i.eq(int_abort_init_aclk),
            sfr.int_abort_done.eq(self.int_abort_done_sync.o),
            self.int_abort_done_sync.i.eq(int_abort_done_aclk),
        ]

        # wire up aborts
        abort_in_progress = Signal()
        abort_ack = Signal()
        self.comb += sfr.int_error.eq(sfr.sr_tx_err | sfr.sr_rx_err) # goes through an edge-trigger filter on the interrupt processing side
        w_pending = Signal()

        # build the outgoing datapath
        w_valid_r = Signal()
        ar_done_r = Signal()
        ar_abort_r = Signal()

        self.sync += [
            w_valid_r.eq(cr_wdata_written_aclk),
            ar_done_r.eq(ar_done_aclk),
            ar_abort_r.eq(ar_abort_aclk),
        ]
        self.comb += [
            mbox_ext.w_dat.eq(sfr.cr_wdata),
            mbox_ext.w_valid.eq(cr_wdata_written_aclk & ~w_valid_r | w_pending), # edge detect in our fast clock domain + hold-high in case mbox is full
            mbox_ext.w_done.eq(ar_done_aclk & ~ar_done_r), # edge
            sfr.sr_tx_free.eq(
                ~(mbox_ext.w_valid | w_pending)
            ),
        ]
        sr_read_r = Signal()
        self.sync += [
            If(cr_wdata_written_aclk & ~w_valid_r & ~mbox_ext.w_ready,
                w_pending.eq(1)
            ).Elif(
                    mbox_ext.w_ready  # if the other side acks
                    | (sfr.sr_tx_err & sr_read_aclk & ~sr_read_r), # or if we're in an error state, and the error bit has been read, discard the write
                w_pending.eq(0)
            ).Else(
                w_pending.eq(w_pending)
            ),
            sr_read_r.eq(sr_read_aclk),
            If(sr_read_aclk & ~sr_read_r,
                sfr.sr_tx_err.eq(0),
            ).Else(
                If(mbox_ext.w_valid & ~mbox_ext.w_ready & w_pending,
                    sfr.sr_tx_err.eq(1),
                ).Else(
                    sfr.sr_tx_err.eq(sfr.sr_tx_err),
                )
            ),
        ]

        # build the incoming datapath
        rdata_read_r = Signal()
        self.sync += [
            rdata_read_r.eq(sr_rdata_read_aclk)
        ]
        self.comb += [
            sfr.sr_rdata.eq(mbox_ext.r_dat),
            mbox_ext.r_ready.eq(sr_rdata_read_aclk & ~rdata_read_r), # pulse when we're read
            int_available_aclk.eq(mbox_ext.r_done),
            sfr.sr_rx_avail.eq(mbox_ext.r_valid),
        ]
        self.sync += [
            If(sr_read_aclk & ~sr_read_r,
                sfr.sr_rx_err.eq(0),
            ).Else(
                If(mbox_ext.r_ready & ~mbox_ext.r_valid,
                    sfr.sr_rx_err.eq(1),
                ).Else(
                    sfr.sr_rx_err.eq(sfr.sr_rx_err),
                )
            )
        ]

        self.comb += [
            sfr.sr_abort_in_progress.eq(abort_in_progress),
            sfr.sr_abort_ack.eq(abort_ack),
        ]
        # build the abort logic
        fsm = FSM(reset_state="IDLE")
        self.submodules += fsm
        fsm.act("IDLE",
            If((ar_abort_aclk & ~ar_abort_r) & ~mbox_ext.r_abort,
                NextState("REQ"),
                NextValue(abort_ack, 0),
                NextValue(abort_in_progress, 1),
                NextValue(mbox_ext.w_abort, 1),
            ).Elif((ar_abort_aclk & ~ar_abort_r) & mbox_ext.r_abort, # simultaneous abort case
                NextState("IDLE"),
                NextValue(abort_ack, 1),
                NextValue(mbox_ext.w_abort, 1),
            ).Elif(~(ar_abort_aclk & ~ar_abort_r) & mbox_ext.r_abort,
                NextState("WAIT-ACK"),
                NextValue(abort_in_progress, 1),
                int_abort_init_aclk.eq(1), # pulse this on entering the ACK state
                NextValue(mbox_ext.w_abort, 0),
            ).Else(
                NextValue(mbox_ext.w_abort, 0),
            )
        )
        fsm.act("REQ",
            If(mbox_ext.r_abort,
                NextState("IDLE"),
                NextValue(abort_in_progress, 0),
                int_abort_done_aclk.eq(1), # pulse this on leaving the REQ state
                NextValue(mbox_ext.w_abort, 0),
            ).Else(
                NextValue(mbox_ext.w_abort, 1),
            )
        )
        fsm.act("WAIT-ACK",
            If((ar_abort_aclk & ~ar_abort_r), # leave on the abort being ack'd with an abort of our own
                NextState("ACK"),
                NextValue(abort_in_progress, 0),
                NextValue(abort_ack, 1),
                NextValue(mbox_ext.w_abort, 1),
            )
        )
        fsm.act("ACK",
                NextState("IDLE"),
                NextValue(mbox_ext.w_abort, 0),
        )


mbc = MboxClient(platform)

# Build --------------------------------------------------------------------------------------------

platform.build(mbc, regular_comb=True, build_dir="../sim_support", build_name="mbox_client")