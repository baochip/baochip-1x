#!/usr/bin/env python3
#
# Copyright (c) 2022 Cramium Labs, Inc.
# Derived from litex_soc_gen.py:
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

import argparse
import litex.soc.doc as lxsocdoc

from migen import *

from litex.build.generic_platform import *

from litex.soc.integration.soc_core import *
from litex.soc.integration.soc import SoCRegion, SoCIORegion
from litex.soc.integration.builder import *
from litex.soc.interconnect import wishbone
from litex.soc.interconnect import axi
from litex.soc.interconnect import ahb
from litex.soc.interconnect.csr import *
from litex.soc.integration.soc import SoCBusHandler
from litex.soc.integration.doc import AutoDoc,ModuleDoc

from litex.soc.interconnect.csr_eventmanager import *
from litex.soc.interconnect.csr_eventmanager import _EventSource

from migen.genlib.fifo import _FIFOInterface, _inc
from migen.genlib.cdc import BlindTransfer, BusSynchronizer, MultiReg

# Interrupt emulator -------------------------------------------------------------------------------

class InterruptBank(Module, AutoCSR):
    def __init__(self):
        self.submodules.ev = EventManager()

# IOs/Interfaces -----------------------------------------------------------------------------------
IRQ_BANKS=20
IRQS_PER_BANK=16

def get_common_ios():
    ios = [
        # Clk/Rst.
        ("aclk", 0, Pins(1)),
        ("rst", 0, Pins(1)),
        ("vexsramtrm", 0, Pins(3)),
        # `always_on` is an `aclk` replica that is running even when the core `aclk` is stopped.
        # if power management is not supported, tie this directly to `aclk`
        ("always_on", 0, Pins(1)),
        # trimming_reset is a reset vector, specified by the trimming bits. Only loaded if trimming_reset_ena is set.
        ("trimming_reset", 0, Pins(32)),
        ("trimming_reset_ena", 0, Pins(1)),
        # coreuser signal
        ("coreuser_vex", 0, Pins(8)),
        ("vex_mm", 0, Pins(1)),
        ("default_user", 0, Pins(2)),
        ("default_mm", 0, Pins(1)),
        # sleep request: wfi active signal gated with interrupt status
        # when high, stop aclk, but leave "always_on" on
        ("sleep_req", 0, Pins(1)),
        # BIST signals
        ("cmbist", 0, Pins(1)),
        ("cmatpg", 0, Pins(1)),
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
        # Signals for facilitating design testing
        ("test", 0, Pins(32))
    ]
    irqs = ["irqarray", 0]
    for bank in range(IRQ_BANKS):
        irqs += [Subsignal("bank{}".format(bank), Pins(IRQS_PER_BANK))]
    ios += [tuple(irqs)]
    return ios

def get_debug_ios():
    return [
        ("jtag", 0,
            Subsignal("tdi",Pins(1)),
            Subsignal("tdo",Pins(1)),
            Subsignal("tms",Pins(1)),
            Subsignal("tck",Pins(1)),
            Subsignal("trst_n",Pins(1)),
        )
    ]

# Platform -----------------------------------------------------------------------------------------

class Platform(GenericPlatform):
    def build(self, fragment, build_dir, build_name, **kwargs):
        os.makedirs(build_dir, exist_ok=True)
        os.chdir(build_dir)
        conv_output = self.get_verilog(fragment, name=build_name, regs_init=False)
        conv_output.write(f"{build_name}.v")

class CsrTest(Module, AutoCSR, AutoDoc):
    def __init__(self):
        self.csr_wtest = CSRStorage(32, name="wtest", description="Write test data here")
        self.csr_rtest = CSRStatus(32, name="rtest", description="Read test data here")
        self.comb += [
            self.csr_rtest.status.eq(self.csr_wtest.storage + 0x1000_0000)
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

# Mailbox ------------------------------------------------------------------------------------------
class SyncFIFOMacro(Module, _FIFOInterface):
    """Synchronous FIFO (first in, first out)

    Read and write interfaces are accessed from the same clock domain.
    If different clock domains are needed, use :class:`AsyncFIFO`.

    {interface}
    level : out
        Number of unread entries.
    replace : in
        Replaces the last entry written into the FIFO with `din`. Does nothing
        if that entry has already been read (i.e. the FIFO is empty).
        Assert in conjunction with `we`.
    """
    __doc__ = __doc__.format(interface=_FIFOInterface.__doc__)

    def __init__(self, width, depth, fwft=True):
        _FIFOInterface.__init__(self, width, depth)

        self.cmbist = Signal()
        self.cmatpg = Signal()
        self.vexsramtrm = Signal(3)
        self.level = Signal(max=depth+1)
        self.replace = 0

        ###

        produce = Signal(max=depth)
        consume = Signal(max=depth)

        wrport_adr = Signal(max=depth)
        wrport_dat_w = Signal(width)
        wrport_we = Signal()
        rdport_adr = Signal(max=depth)
        rdport_re = Signal()
        rdport_dat_r = Signal(width)
        self.specials += Instance(
            "Ram_1w_1rs",
            p_ramname="RAM_DP_{}_{}".format(depth, width),
            p_wordCount=depth,
            p_wordWidth=width,
            p_clockCrossing=0,
            p_wrAddressWidth=log2_int(depth),
            p_wrDataWidth=width,
            p_wrMaskEnable=0,
            p_rdAddressWidth=log2_int(depth),
            p_rdDataWidth=width,
            i_wr_clk = ClockSignal(),
            i_wr_en = wrport_we,
            i_wr_mask = 0,
            i_wr_addr = wrport_adr,
            i_wr_data = wrport_dat_w,
            i_rd_clk = ClockSignal(),
            i_rd_en = rdport_re,
            i_rd_addr = rdport_adr,
            o_rd_data = rdport_dat_r,
            i_CMBIST = self.cmbist,
            i_CMATPG = self.cmatpg,
            i_sramtrm = self.vexsramtrm,
        )

        self.comb += [
            If(self.replace,
                wrport_adr.eq(produce-1)
            ).Else(
                wrport_adr.eq(produce)
            ),
            wrport_dat_w.eq(self.din),
            wrport_we.eq(self.we & (self.writable | self.replace))
        ]
        self.sync += If(self.we & self.writable & ~self.replace,
            _inc(produce, depth))

        do_read = Signal()
        self.comb += do_read.eq(self.readable & self.re)

        self.comb += [
            rdport_adr.eq(consume),
            self.dout.eq(rdport_dat_r)
        ]
        if not fwft:
            self.comb += rdport_re.eq(do_read)
        else:
            self.comb += rdport_re.eq(1)
        self.sync += If(do_read, _inc(consume, depth))

        self.sync += \
            If(self.we & self.writable & ~self.replace,
                If(~do_read, self.level.eq(self.level + 1))
            ).Elif(do_read,
                self.level.eq(self.level - 1)
            )
        self.comb += [
            self.writable.eq(self.level != depth),
            self.readable.eq(self.level != 0)
        ]


class SyncFIFOBufferedMacro(Module, _FIFOInterface):
    """Has an interface compatible with SyncFIFO with fwft=True,
    but does not use asynchronous RAM reads that are not compatible
    with block RAMs. Increases latency by one cycle."""
    def __init__(self, width, depth):
        _FIFOInterface.__init__(self, width, depth)
        self.cmbist = Signal()
        self.cmatpg = Signal()
        self.vexsramtrm = Signal(3)
        self.submodules.fifo = fifo = SyncFIFOMacro(width, depth, False)
        self.comb += [
            self.fifo.cmbist.eq(self.cmbist),
            self.fifo.cmatpg.eq(self.cmatpg),
            self.fifo.vexsramtrm.eq(self.vexsramtrm),
        ]

        self.writable = fifo.writable
        self.din = fifo.din
        self.we = fifo.we
        self.dout = fifo.dout
        self.level = Signal(max=depth+2)

        ###

        self.comb += fifo.re.eq(fifo.readable & (~self.readable | self.re))
        self.sync += \
            If(fifo.re,
                self.readable.eq(1),
            ).Elif(self.re,
                self.readable.eq(0),
            )
        self.comb += self.level.eq(fifo.level + self.readable)

class StickyBit(Module):
    def __init__(self):
        self.flag = Signal()
        self.bit = Signal()
        self.clear = Signal()

        self.sync += [
            If(self.clear,
                self.bit.eq(0)
            ).Else(
                If(self.flag,
                    self.bit.eq(1)
                ).Else(
                    self.bit.eq(self.bit)
                )
            )
        ]
class Mailbox(Module, AutoCSR, AutoDoc):
    def __init__(self, fifo_depth=1024):
        self.intro = ModuleDoc("""Mailbox: An inter-CPU mailbox
The `Mailbox` is a bi-directional, inter-CPU mailbox for delivering messages between CPUs
without requiring shared memory.

A single message consists of a packet up to {} words long, where each word is 32 bits in length.

Both CPUs are considered as "peers"; each can initiate a packet at-will.

The bus signal layout is as follows::

    layout = [
        # data going to the peer. `valid` indicates data is ready to be written;
        # `ready` acknowledges the current write
        ("w_dat", 32, DIR_M_TO_S),
        ("w_valid", 1, DIR_M_TO_S),
        ("w_ready", 1, DIR_S_TO_M),
        # Interrupt signal to peer.
        # A single pulse used to indicate when the full packet is in the FIFO.
        ("w_done", 1, DIR_M_TO_S),
        # data coming from the peer
        ("r_dat", 32, DIR_S_TO_M),
        ("r_valid", 1, DIR_S_TO_M),
        ("r_ready", 1, DIR_M_TO_S),
        # Interrupt signal from peer.
        # A single pulse used to indicate when the full packet is in the FIFO.
        ("r_done", 1, DIR_S_TO_M),
        # Bi-directional sync signal. This can be used at any time to recover the protocol
        # to a known state.
        # The signal is cross-wired, e.g. `w_abort` on one peer connects to `r_abort` on
        # the other. Either peer can assert `w_abort`, and it must stay asserted until
        # `r_abort` is pulsed to acknowledge the abort.
        # Asserting `w_abort` immediately clears the sender's FIFO, and blocks new data
        # from being loaded until `r_abort` is asserted.
        # In the case that both happen to simultaneously assert `w_abort`,
        # the protocol completes in one cycle.
        ("w_abort", 1, DIR_M_TO_S),
        ("r_abort", 1, DIR_S_TO_M),
    ]

""".format(fifo_depth))
        self.data_transfer = ModuleDoc("""Data Transfer Protocol
The protocol has two levels, one at a MAC level, and one at an APP level.

The MAC level protocol controls synchronization of data transfer, and the transfer of single, fully-formed
packets between the devices. The MAC protocol is implemented by this hardware block.

The APP protocol is managed by the operating system, and can be considered advisory as
just one of many ways to use this system to communicate between CPUs. However, it helps to ground
the protocol in an APP framework as some details of the MAC impact the APP framework, especially
around synchronization and conflict avoidance.

Each peer has a channel to write data to the other peer, using 32 bits `dat`, one `valid` to
indicate when data is available, and `ready` to indicate when the data has been latched by
the corresponding peer's hardware FIFO. Generally, `valid`/`ready` is managed exclusively by
hardware state machines and the host CPUs are not aware of these signals; they mainly exist
to avoid overflowing the FIFO in the case that one is pipelining multiple packets through
the interface.

There is an additional `done` signal which is asserted for exactly one cycle, and it indicates
to the other peer that the sender has finished writing all the data for a given packet. The `done`
signal is provided so that the corresponding peer does not need to busy-monitor the FIFO depth.

    .. wavedrom::
        :caption: Sending four words of data, followed by a `done`.

        { "signal" : [
            {"name": "clk",       "wave": "p........" },
            {"name": "dat",       "wave": "x=.x===xx", "data" : ["D0", "D1", "D2", "D3", "D4"]},
            {"name": "valid",     "wave": "01.01..0."},
            {"name": "ready",     "wave": "0.101..0."},
            {"name": "done",      "wave": "0......10"},
        ]}

The above example shows a packet with a length of four words being transmitted. The first word
takes an extra cycle to be acknowledged; the remaining three are immediately accepted. The `done`
signal could come as early as simultaneously with the last `ready`, but in practice it comes a couple
cycles later since it would be triggered by a write from the CPU to the `done` register.

The data transfer protocol is symmetric across the peers.
        """)
        self.abort_doc = ModuleDoc("""Abort Protocol
The abort protocol is used to recover the protocol to a known state: all FIFOs empty, and both hosts
state machines in an idle state. This is accomplished by cross-wiring `w_abort` on the sending
peer to `r_abort` on the corresponding peer. Either peer can assert `w_abort`, and it must stay asserted
until `r_abort` is pulsed to acknowledged the abort condition. At the conclusion of the protocol,
both FIFOs are empty and their protocol state machines are idle.

    .. wavedrom::
        :caption: Normal abort

        { "config": {skin : "default"},
        "signal" : [
            {"name": "clk",          "wave": "p.....|......."},
            {"name": "w_cpu_op",     "wave": "=.=...........", "node": "...........", "data" : ["initiate abort", "XXX"]},
          {"name": "w_abort_done_int", "wave": "0.........10..", "node": "..........g"},
            {"name": "w_abort",      "wave": "0.1...|...0...", "node": "..a........"},
            {"name": "r_abort",      "wave": "0.....|..10...", "node": ".........e."},
            {},
            {"name": "w_state",      "wave": "=.=...|...=...", "data" : ["XXX", "REQ    ", "IDLE"]},
            {"name": "w_fifo",       "wave": "x..=..|.......", "node": "...b.....", "data" : ["EMPTY        "]},
            {},
            {"name": "r_cpu_op",     "wave": "=.....|.==....", "node": "...........", "data" : ["XXX", "ack", "XXX"]},
            {"name": "r_state",      "wave": "=...=.|...=...", "data" : ["XXX", "ACK", "IDLE"], "node": "....d..."},
            {"name": "r_fifo",       "wave": "x.....|...=...", "data" : ["EMPTY"], "node": "..........f.."},
            {"name": "r_abort_int",  "wave": "0..10.|.......", "node": "...c......"},
        ],
          "edge" : ['a->b hw enforced', 'a->c', 'c->d ', 'd~->e IRQ handler latency', 'e->f hw enforced', 'e->g ']}

In the diagram above, the initiating peer is the `w_` signal set, and the corresponding peer is the `r_` signal
set. Here, the `w_` CPU issues a write operation by writing `1` to the `control` CSR's `abort` bit. This
results in `w_abort` being asserted and held, while simultaneously both the receive and send FIFOs
being cleared and refusing to accept any further data. The assertion of `w_abort` is received by the
corresponding peer, which triggers an interrupt (rendered as a single pulse `r_abort_int`; but the `pending` bit
is sticky until cleared).

The link stays in this state until the receiver's main loop or IRQ handler
runs and acknowledges the abort condition by writing to its `control` CSR `abort` bit. Note that the
IRQ handler has to be written such that any in-progress operation is truly aborted. Thus, a peer's
FIFO interaction code should probably be written as follows:

#. Main loop decides it needs to interact with the FIFO
#. Disable abort response IRQ
#. Interact with the FIFO
#. Re-enable abort response IRQ; at which point an IRQ would fire triggering the abort response
#. Inside the abort response IRQ, side-effect any state machine variables back to an initial state
#. Resume main loop code, which should now check & handle any residual clean-up from an abort

At this point, both sides drop their `abort` signals, both state machines return to an `IDLE` state, and
all FIFOs are empty. An `abort_done` interrupt is triggered for the initiator (one is not necessary for
the responder, because it already has to acknowledge to the abort by asserting abort in response),
but it may be masked and polled if the initiating CPU prefers to monitor the abort by polling.

In order to make the case work where both peers attempt to initiate an abort at the same time, the
initiator guarantees that on asserting `w_abort` it is immediately ready to act on an `r_abort` pulse.
This means the hardware guarantees two things:

- All FIFOs are cleared by the request
- The incoming `abort` response line is prevented from generating an interrupt

    .. wavedrom::
        :caption: Edge case: simultaneous abort

        { "config": {skin : "default"},
        "signal" : [
            {"name": "clk",          "wave": "p....."},
            {"name": "w_abort",      "wave": "0.10.."},
            {"name": "r_abort",      "wave": "0.10.."},
            {},
            {"name": "w_cpu_op",     "wave": "=.=...", "data" : ["initiate abort", "XXX"]},
            {"name": "w_abort_done_int", "wave": "0..10."},
            {"name": "w_abort_int",  "wave": "0....."},
            {"name": "w_state",      "wave": "=.==..", "data" : ["XXX", "REQ", "IDLE"]},
            {"name": "w_fifo",       "wave": "x..=..", "data" : ["EMPTY"]},
            {},
            {"name": "r_cpu_op",     "wave": "=.=...", "data" : ["initiate abort", "XXX"]},
            {"name": "r_abort_done_int", "wave": "0..10."},
            {"name": "r_abort_int",  "wave": "0....."},
            {"name": "r_state",      "wave": "=.==..", "data" : ["XXX", "REQ", "IDLE"]},
            {"name": "r_fifo",       "wave": "x..=..", "data" : ["EMPTY"]},
        ]}

Above is the rare edge case of a cycle-perfect simultaneous abort request. It "just works", and
both devices immediately transition from `REQ` -> `IDLE`, without either going through `ACK`.

    .. wavedrom::
        :caption: Edge case: semi-simultaneous abort

        { "config": {skin : "default"},
        "signal" : [
            {"name": "clk",          "wave": "p.......|.."},
            {"name": "w_abort",      "wave": "0.1...0.|.."},
            {"name": "r_abort",      "wave": "0....10.|.."},
            {},
          {"name": "w_cpu_op",     "wave": "==......|..", "data" : ["initiate", "XXX"], "node" : ".a"},
            {"name": "w_abort_done_int", "wave": "0.....10|.."},
            {"name": "w_abort_int",  "wave": "0.......|.."},
            {"name": "w_abort_ack",  "wave": "x.0.....|.."},
            {"name": "w_state",      "wave": "=..=..=.|..", "data" : ["XXX", "REQ", "IDLE"]},
            {"name": "w_fifo",       "wave": "x..=....|..", "data" : ["EMPTY"]},
            {},
            {"name": "r_cpu_op",     "wave": "=.=..=..|..", "data" : ["XXX", "initiate", "XXX"], "node" : "..c"},
            {"name": "r_abort_done_int", "wave": "0.....10|.."},
            {"name": "r_abort_int",  "wave": "0.10....|..", "node" : "..b"},
            {"name": "r_abort_ack",  "wave": "x....1..|..", "node" : "..........e"},
          {"name": "r_state",      "wave": "=..=..=.|=.", "data" : ["XXX", "ACK", "IDLE", "HANDLER"], "node" : ".........d"},
            {"name": "r_fifo",       "wave": "x....=..|..", "data" : ["EMPTY"]},
        ], "edge" : ['a->b race condition', 'a-~>c ', "d-~>e "]}

Above is the more common edge case where one peer has initiated an abort, and the other
is preparing to initiate at the same time, but is perhaps a cycle or two later. In this case,
the late peer would have an interrupt initiated simultaneously with an abort initiation, which
would result in the `HANDLER` code running, in this case, the **abort initiator** handler
code (not the **abort done** handler).

A naive implementation would re-issue the `abort` bit, triggering the first peer to respond,
and the two could ping-pong back and forth in an infinite cycle.

In order to break the cycle, an additional "abort acknowledged" (`abort_ack`) signal is
provided, which is set in the case that the respective peer is responding to
a request (thus, it would be set for both peers in the above case of the "perfectly aligned"
abort request; but more typically it is cleared by the first initiator, and set for the later
initiator). The abort handler thus shall always check the `abort_ack` signal, and in the case
that it is set, it will not re-acknowledge a previously acknowledged abort, and avoiding
an abort storm.
        """)

        self.app_doc = ModuleDoc("""Application Protocol

The application protocol wraps a packet format around each packet. The general format of
a packet is as follows:

* Word 0

  * Bit 31 - set if a response; cleared if initiating
  * Bit 30:16 - sequence number
  * Bit 15:10 - tag
  * Bit 9:0 - length in words of the packet, excluding word 0

The sequence number allows responses to occur out of order with respect to requests.

The tag encodes the operation intended by the packet. Within the tag, further meaning
may be ascribed to later fields in the packet. As an example, a `tag` of 0 could indicate
an RPC, and in this case `word 1` would encode the desired system call, and then
the subsequent words would encode arguments to that system call. After processing the data,
the response to this system call would be returned to the corresponding peer, using the same
`tag` and `sequence number`, but with the `response` bit set.

Further definition of the protocol would extend from here, for example, a `send` of data
could use a tag of `1`, and the response would be with the same tag
and sequence number to acknowledge that the sent data was accepted, with the length
field specifying the number of words that were accepted.
""")
        # self-test signals
        self.cmatpg = Signal()
        self.cmbist = Signal()
        self.vexsramtrm = Signal(3)

        depth_bits = log2_int(fifo_depth)
        # data going from us to them
        self.w_dat = Signal(32)
        self.w_valid = Signal()
        self.w_ready = Signal()
        self.w_done = Signal()
        # data going from them to us
        self.r_dat = Signal(32)
        self.r_valid = Signal()
        self.r_ready = Signal()
        self.r_done = Signal()
        # cross-wired abort signals
        self.w_abort = Signal()
        self.r_abort = Signal()
        # hardware reset signal. active low, because SoC
        self.reset_n = Signal()

        self.wdata = CSRStorage(32, name="wdata", description="Write data to outgoing FIFO.")
        self.rdata = CSRStatus(32, name="rdata", description="Read data from incoming FIFO.")
        self.submodules.ev = ev = EventManager()
        self.ev.available = EventSourcePulse(name="available", description="Triggers when the `done` signal was asserted by the corresponding peer")
        self.ev.abort_init = EventSourceProcess(name="abort_init", description="Triggers when abort is asserted by the peer, and there is currently no abort in progress", edge="rising")
        self.ev.abort_done = EventSourceProcess(name="abort_done", description="Triggers when a previously initiated abort is acknowledged by peer", edge="rising")
        self.ev.error = EventSourceProcess(name="error", description="Triggers if either `tx_err` or `rx_err` are asserted", edge="rising")
        self.ev.finalize()
        self.status = CSRStatus(fields=[
            CSRField(name="rx_words", size=depth_bits + 1, description="Number of words available to read"),
            CSRField(name="tx_words", size=depth_bits + 1, description="Number of words pending in write FIFO. Free space is {} - `tx_avail`".format(fifo_depth)),
            CSRField(name="abort_in_progress", size=1, description="This bit is set if an `aborting` event was initiated and is still in progress."),
            CSRField(name="abort_ack", size=1,
            description="""This bit is set by the peer that acknowledged the incoming abort
(the later of the two, in case of an imperfect race condition). The abort response handler should
check this bit; if it is set, no new acknowledgement shall be issued. The bit is cleared
when an initiator initiates a new abort. The initiator shall also ignore the state of this
bit if it is intending to initiate a new abort cycle."""),
            CSRField(name="tx_err", size=1, description="Set if the write FIFO overflowed because we wrote too much data. Cleared on register read."),
            CSRField(name="rx_err", size=1, description="Set if read FIFO underflowed because we read too much data. Cleared on register read."),
        ])
        self.control = CSRStorage(fields=[
            CSRField(name="abort", size=1, description=
            """Write `1` to this field to both initiate and acknowledge an abort.
Empties both FIFOs, asserts `aborting`, and prevents an interrupt from being generated by
an incoming abort request. New reads & writes are ignored until `aborted` is asserted
from the peer.""", pulse=True)
        ])
        self.done = CSRStorage(fields=[
            CSRField(
                size=1, name="done", pulse=True,
                description="Writing a `1` to this field indicates to the corresponding peer that a full packet is done loading. There is no need to clear this register after writing.")
        ])
        self.loopback = CSRStorage(fields=[
            CSRField(
                size=1, name="loopback",
                description="Writing a `1` to this field indicates that the mailbox should loopback to the local client. `0` connects it to the external core."
            )
        ])
        abort_in_progress = Signal()
        abort_ack = Signal()
        self.comb += self.ev.error.trigger.eq(self.status.fields.tx_err | self.status.fields.rx_err)

        # build the outgoing fifo
        self.submodules.w_over = StickyBit()
        self.submodules.w_fifo = w_fifo = ResetInserter(["sys"])(SyncFIFOBufferedMacro(32, fifo_depth))
        self.comb += self.w_fifo.reset_sys.eq(~self.reset_n | self.control.fields.abort)
        self.comb += [
            self.status.fields.tx_words.eq(self.w_fifo.level),
            self.status.fields.tx_err.eq(self.w_over.bit),
            If(self.wdata.re & ~w_fifo.writable, # .re must strictly assert for exactly 1 cycle per CSR spec
                self.w_over.flag.eq(1),
            ).Else(
                If(~abort_in_progress,
                    w_fifo.we.eq(self.wdata.re),
                )
            ),
            self.w_over.clear.eq(self.status.we),
            w_fifo.din.eq(self.wdata.storage),
            self.w_dat.eq(w_fifo.dout),
            self.w_valid.eq(w_fifo.readable),
            w_fifo.re.eq(self.w_ready),
            self.w_done.eq(self.done.fields.done), # this will pulse exactly 1 cycle because `pulse=True` in the field spec

            self.w_fifo.cmbist.eq(self.cmbist),
            self.w_fifo.cmatpg.eq(self.cmatpg),
            self.w_fifo.vexsramtrm.eq(self.vexsramtrm),
        ]

        # build the incoming fifo
        self.submodules.r_over = StickyBit()
        self.submodules.r_fifo = r_fifo = ResetInserter(["sys"])(SyncFIFOBufferedMacro(32, fifo_depth))
        self.comb += self.r_fifo.reset_sys.eq(~self.reset_n | self.control.fields.abort)
        self.comb += [
            self.status.fields.rx_words.eq(self.r_fifo.level),
            self.status.fields.rx_err.eq(self.r_over.bit),
            If(self.rdata.we & ~r_fifo.readable, # .we must strictly assert for exactly 1 cycle per CSR spec
                self.r_over.flag.eq(1),
            ).Else(
                r_fifo.re.eq(self.rdata.we),
            ),
            self.r_over.clear.eq(self.status.we),
            r_fifo.din.eq(self.r_dat),
            self.rdata.status.eq(r_fifo.dout),
            self.r_ready.eq(r_fifo.writable & self.r_valid),
            r_fifo.we.eq(self.r_valid & r_fifo.writable & ~abort_in_progress),
            self.ev.available.trigger.eq(self.r_done),

            self.r_fifo.cmbist.eq(self.cmbist),
            self.r_fifo.cmatpg.eq(self.cmatpg),
            self.r_fifo.vexsramtrm.eq(self.vexsramtrm),
        ]

        self.comb += [
            self.status.fields.abort_in_progress.eq(abort_in_progress),
            self.status.fields.abort_ack.eq(abort_ack),
        ]

        # build the abort logic
        fsm = FSM(reset_state="IDLE")
        self.submodules += fsm
        fsm.act("IDLE",
            If(self.control.fields.abort & ~self.r_abort,
                NextState("REQ"),
                NextValue(abort_ack, 0),
                NextValue(abort_in_progress, 1),
                NextValue(self.w_abort, 1),
            ).Elif(self.control.fields.abort & self.r_abort, # simultaneous abort case
                NextState("IDLE"),
                NextValue(abort_ack, 1),
                NextValue(self.w_abort, 1),
            ).Elif(~self.control.fields.abort & self.r_abort,
                NextState("WAIT-ACK"),
                NextValue(abort_in_progress, 1),
                self.ev.abort_init.trigger.eq(1), # pulse this on entering the ACK state
                NextValue(self.w_abort, 0),
            ).Else(
                NextValue(self.w_abort, 0),
            )
        )
        fsm.act("REQ",
            If(self.r_abort,
                NextState("IDLE"),
                NextValue(abort_in_progress, 0),
                self.ev.abort_done.trigger.eq(1), # pulse this on leaving the REQ state
                NextValue(self.w_abort, 0),
            ).Else(
                NextValue(self.w_abort, 1),
            )
        )
        fsm.act("WAIT-ACK",
            If(self.control.fields.abort, # leave on the abort being ack'd with an abort of our own
                NextState("ACK"),
                NextValue(abort_in_progress, 0),
                NextValue(abort_ack, 1),
                NextValue(self.w_abort, 1),
            )
        )
        fsm.act("ACK",
            NextState("IDLE"),
            NextValue(self.w_abort, 0),
        )

class MailboxClient(Module, AutoCSR, AutoDoc):
    def __init__(self):
        self.intro = ModuleDoc("""Thin Mailbox Client
This is a "minimal" mailbox client which has no FIFO of its own. It relies
entirely on the other side's FIFO for the protocol to be efficient.
        """)
        # data going from us to them
        self.w_dat = Signal(32)
        self.w_valid = Signal()
        self.w_ready = Signal()
        self.w_done = Signal()
        # data going from them to us
        self.r_dat = Signal(32)
        self.r_valid = Signal()
        self.r_ready = Signal()
        self.r_done = Signal()
        # cross-wired abort signals
        self.w_abort = Signal()
        self.r_abort = Signal()
        # hardware reset signal. active low, because SoC
        self.reset_n = Signal()

        self.wdata = CSRStorage(32, name="wdata", description="Write data to outgoing FIFO.")
        self.rdata = CSRStatus(32, name="rdata", description="Read data from incoming FIFO.")
        self.status = CSRStatus(fields=[
            CSRField(name="rx_avail", size = 1, description="Rx data is available"),
            CSRField(name="tx_free", size = 1, description="Tx register can be written"),
            CSRField(name="abort_in_progress", size=1, description="This bit is set if an `aborting` event was initiated and is still in progress."),
            CSRField(name="abort_ack", size=1,
            description="""This bit is set by the peer that acknowledged the incoming abort
(the later of the two, in case of an imperfect race condition). The abort response handler should
check this bit; if it is set, no new acknowledgement shall be issued. The bit is cleared
when an initiator initiates a new abort. The initiator shall also ignore the state of this
bit if it is intending to initiate a new abort cycle."""),
            CSRField(name="tx_err", size=1, description="Set if the recipient was not ready for the data. Cleared on read."),
            CSRField(name="rx_err", size=1, description="Set if the recipient didn't have data available for a read. Cleared on read.")
        ])

        # Place these so they overlap with the event manager register layout
        self.submodules.ev = ev = EventManager()
        self.ev.available = EventSourcePulse(name="available", description="Triggers when the `done` signal was asserted by the corresponding peer")
        self.ev.abort_init = EventSourceProcess(name="abort_init", description="Triggers when abort is asserted by the peer, and there is currently no abort in progress", edge="rising")
        self.ev.abort_done = EventSourceProcess(name="abort_done", description="Triggers when a previously initiated abort is acknowledged by peer", edge="rising")
        self.ev.error = EventSourceProcess(name="error", description="Triggers if either `tx_err` or `rx_err` are asserted", edge="rising")
        self.ev.finalize()

        self.control = CSRStorage(fields=[
            CSRField(name="abort", size=1, description=
            """Write `1` to this field to both initiate and acknowledge an abort.
Empties both FIFOs, asserts `aborting`, and prevents an interrupt from being generated by
an incoming abort request. New reads & writes are ignored until `aborted` is asserted
from the peer.""", pulse=True)
        ])
        self.done = CSRStorage(fields=[
            CSRField(
                size=1, name="done", pulse=True,
                description="Writing a `1` to this field indicates to the corresponding peer that a full packet is done loading. There is no need to clear this register after writing.")
        ])
        abort_in_progress = Signal()
        abort_ack = Signal()
        self.comb += self.ev.error.trigger.eq(self.status.fields.tx_err | self.status.fields.rx_err)
        w_pending = Signal()

        # build the outgoing datapath
        self.comb += [
            self.w_dat.eq(self.wdata.storage),
            self.w_valid.eq(self.wdata.re | w_pending),
            self.w_done.eq(self.done.fields.done),
            self.status.fields.tx_free.eq(
                ~(self.w_valid | w_pending)
            ),
        ]
        self.sync += [
            If(self.wdata.re & ~self.w_ready,
                w_pending.eq(1)
            ).Elif(
                    self.w_ready # if the other side acks
                    | (self.status.fields.tx_err & self.status.we) , # we're in an error state and the error bit has been read, discard the write
                w_pending.eq(0)
            ).Else(
                w_pending.eq(w_pending)
            ),
            If(self.status.we,
                self.status.fields.tx_err.eq(0),
            ).Else(
                If(self.wdata.re & ~self.w_ready & w_pending,
                    self.status.fields.tx_err.eq(1),
                ).Else(
                    self.status.fields.tx_err.eq(self.status.fields.tx_err),
                )
            ),
        ]

        # build the incoming datapath
        self.comb += [
            self.rdata.status.eq(self.r_dat),
            self.r_ready.eq(self.rdata.we), # pulse when we're read
            self.ev.available.trigger.eq(self.r_done),
            self.status.fields.rx_avail.eq(self.r_valid),
        ]
        self.sync += [
            If(self.status.we,
                self.status.fields.rx_err.eq(0),
            ).Else(
                If(self.rdata.we & ~self.r_valid,
                    self.status.fields.rx_err.eq(1),
                ).Else(
                    self.status.fields.rx_err.eq(self.status.fields.rx_err),
                )
            )
        ]

        self.comb += [
            self.status.fields.abort_in_progress.eq(abort_in_progress),
            self.status.fields.abort_ack.eq(abort_ack),
        ]
        # build the abort logic
        fsm = FSM(reset_state="IDLE")
        self.submodules += fsm
        fsm.act("IDLE",
            If(self.control.fields.abort & ~self.r_abort,
                NextState("REQ"),
                NextValue(abort_ack, 0),
                NextValue(abort_in_progress, 1),
                NextValue(self.w_abort, 1),
            ).Elif(self.control.fields.abort & self.r_abort, # simultaneous abort case
                NextState("IDLE"),
                NextValue(abort_ack, 1),
                NextValue(self.w_abort, 1),
            ).Elif(~self.control.fields.abort & self.r_abort,
                NextState("WAIT-ACK"),
                NextValue(abort_in_progress, 1),
                self.ev.abort_init.trigger.eq(1), # pulse this on entering the ACK state
                NextValue(self.w_abort, 0),
            ).Else(
                NextValue(self.w_abort, 0),
            )
        )
        fsm.act("REQ",
            If(self.r_abort,
                NextState("IDLE"),
                NextValue(abort_in_progress, 0),
                self.ev.abort_done.trigger.eq(1), # pulse this on leaving the REQ state
                NextValue(self.w_abort, 0),
            ).Else(
                NextValue(self.w_abort, 1),
            )
        )
        fsm.act("WAIT-ACK",
            If(self.control.fields.abort, # leave on the abort being ack'd with an abort of our own
                NextState("ACK"),
                NextValue(abort_in_progress, 0),
                NextValue(abort_ack, 1),
                NextValue(self.w_abort, 1),
            )
        )
        fsm.act("ACK",
            NextState("IDLE"),
            NextValue(self.w_abort, 0),
        )


# Deterministic timeout ---------------------------------------------------------------------------

class D11cTime(Module, AutoDoc, AutoCSR):
    def __init__(self, count=400_000, sys_clk_freq=100e6):
        self.intro = ModuleDoc("""Deterministic Timeout
        This module creates a heartbeat that is deterministic. If used correctly, it can help reduce
        timing side channels on secure processes by giving them an independent, coarse source of
        time. The idea is that a secure process may handle a request, and then wait for a heartbeat
        from the D11cTime module to change polarity, which occurs at a regular interval,
        before returning the result.

        There is a trade-off on how frequent the heartbeat is versus information leakage versus
        overall throughput of the secure module's responses. If the heartbeat is faster than the
        maximum time to complete a computation, then information leakage will occur; if it is much
        slower than the maximum time to complete a computation, then performance is reduced. Deterministic
        timeout is not the end-all solution; adding noise and computational confounders are also
        countermeasures to be considered, but this is one of the simpler approaches, and it is relatively
        hardware-efficient.

        This block has been configured to default to {}ms period, assuming ACLK is {}MHz.
        """.format( 2 * (count / sys_clk_freq) * 1000.0 , sys_clk_freq / 1e6))

        self.control = CSRStorage(32, fields = [
            CSRField("count", size=32, description="Number of ACLK ticks before creating a heart beat", reset=count),
        ])
        self.heartbeat = CSRStatus(1, fields = [
            CSRField("beat", description="Set to `1` at the next `count` interval rollover since `clear` was set."),
        ])

        counter = Signal(32, reset=count)
        heartbeat = Signal(reset=0)
        self.sync += [
            If(counter == 0,
                counter.eq(self.control.fields.count),
                heartbeat.eq(~heartbeat),
            ).Else(
                counter.eq(counter - 1),
            )
        ]
        self.comb += [
            self.heartbeat.fields.beat.eq(heartbeat)
        ]

# Suspend/Resume ---------------------------------------------------------------------------------

class SusRes(Module, AutoDoc, AutoCSR):
    def __init__(self, bits=64):
        self.intro = ModuleDoc("""Suspend/Resume Helper
        This module is a utility module that assists with suspend and
        resume functions. It has the ability to 'reach into' the Ticktimer space to help coordinate
        a clean, monatomic shut down from a suspend/resume manager that exists in a different,
        isolated process space from the TickTimer.

        It also contains a register which tracks the current resume state. The bootloader controls
        the kernel's behavior by setting this bit prior to resuming operation.
        """)

        self.control = CSRStorage(2, fields=[
            CSRField("pause", description="Write a `1` to this field to request a pause to counting, 0 for free-run. Count pauses on the next tick quanta."),
            CSRField("load", description="If paused, write a `1` to this bit to load a resume value to the timer. If not paused, this bit is ignored.", pulse=True),
        ])
        self.resume_time = CSRStorage(bits, name="resume_time", description="Elapsed time to load. Loaded upon writing `1` to the load bit in the control register. This will immediately affect the msleep extension.")
        self.time = CSRStatus(bits, name="time", description="""Cycle-accurate mirror copy of time in systicks, from the TickTimer""")
        self.status = CSRStatus(1, fields=[
            CSRField("paused", description="When set, indicates that the counter has been paused")
        ])
        self.state = CSRStorage(2, fields=[
            CSRField("resume", description="Used to transfer the resume state information from the loader to Xous. If set, indicates we are on the resume half of a suspend/resume."),
            CSRField("was_forced", description="Used by the bootloader to indicate to the kernel if the current resume was from a forced suspend (e.g. a timeout happened and a server may be unclean."),
        ])
        self.resume = Signal()
        self.comb += self.resume.eq(self.state.fields.resume)

        # These signals aren't valid on the Cramium platform
        #self.powerdown = CSRStorage(1, fields=[
        #    CSRField("powerdown", description="Write a `1` to force an immediate powerdown. Use with care.", reset=0)
        #])
        #self.powerdown_override = Signal()
        #self.comb += self.powerdown_override.eq(self.powerdown.fields.powerdown)

        #self.wfi = CSRStorage(1, fields=[
        #    CSRField("override", description="Write a `1` to this register to disable WFI (used to make sure the suspend/resume is not interrupted by a CPU sleep cal)")
        #])
        #self.wfi_override = Signal()
        #self.comb += self.wfi_override.eq(self.wfi.fields.override)

        self.interrupt = CSRStorage(1, fields=[
            CSRField("interrupt", size = 1, pulse=True,
                description="Writing this causes an interrupt to fire. Used by Xous to initiate suspend/resume from an interrupt context."
            )
        ])
        self.submodules.ev = EventManager()
        self.ev.soft_int = EventSourceProcess()
        self.kernel_resume_interrupt = Signal()
        self.comb += self.ev.soft_int.trigger.eq(self.interrupt.fields.interrupt | self.kernel_resume_interrupt)
        self.ev.finalize()

# Interrupts ------------------------------------------------------------------------------------
class EventSourceFlex(Module, _EventSource):
    def __init__(self, trigger, soft_trigger, edge_triggered, polarity, name=None, description=None):
        _EventSource.__init__(self, name, description)
        self.trigger = trigger
        trigger_d = Signal()
        self.sync += trigger_d.eq(trigger)
        trigger_filtered = Signal()
        self.comb += [
            If(edge_triggered,
               If(polarity,
                  trigger_filtered.eq(self.trigger & ~trigger_d) # rising
               ).Else(
                  trigger_filtered.eq(~self.trigger & trigger_d) # falling
               )
            ).Else(
                trigger_filtered.eq(self.trigger)
            )
        ]
        self.soft_trigger = soft_trigger
        self.comb += [
            # status reports the raw, unfiltered hardware trigger status
            self.status.eq(self.trigger | self.soft_trigger),
        ]
        self.sync += [
            # to clear a soft trigger, first de-assert the soft_trigger bit, and then write the pending bit.
            # otherwise, the trigger will persist.
            If(trigger_filtered | self.soft_trigger,
                self.pending.eq(1)
            ).Elif(self.clear,
                self.pending.eq(0)
            ).Else(
                self.pending.eq(self.pending)
            ),
        ]
        self.edge_triggered = edge_triggered
        self.polarity = polarity

class IrqArray(Module, AutoCSR, AutoDoc):
    """Interrupt Array Handler"""
    def __init__(self, bank, pins, names):
        self.intro = ModuleDoc("""
`IrqArray` provides a large bank of interrupts for SoC integration. It is different from e.g. the NVIC
or CLINT in that the register bank is structured along page boundaries, so that the interrupt handler CSRs
can be owned by a specific virtual memory process, instead of bouncing through a common handler
and forcing an inter-process message to be generated to route interrupts to their final destination.

The incoming interrupt signals are assumed to be synchronized to `aclk`.

Priorities are enforced entirely through software; the handler must read the `pending` bits and
decide which ones should be handled first.

The `EventSource` is an `EventSourceFlex` which can handle pulses and levels, as well as software triggers.

The interrupt pending bit is latched when the trigger goes high, and stays high
until software clears the event. The trigger takes precedence over clearing, so
if the interrupt source is not cleared prior to clearing the interrupt pending bit,
the interrupt will trigger again.

`status` reflects the instantaneous value of the trigger.

A separate input line is provided so that software can induce an interrupt by
writing to a soft-trigger bit.
        """)
        ints_per_bank = len(pins)
        self.submodules.ev = ev = EventManager()
        self.interrupts = interrupts = Signal(ints_per_bank)
        self.comb += self.interrupts.eq(pins)
        setattr(self, 'bank{}_ints'.format(bank), interrupts)
        soft = CSRStorage(
            size=ints_per_bank,
            description="""Software interrupt trigger register.
        )

Bits set to `1` will trigger an interrupt. Interrupts trigger on write, but the
value will persist in the register, allowing software to determine if a software
interrupt was triggered by reading back the register.

Software is responsible for clearing the register to 0.

Repeated `1` writes without clearing will still trigger an interrupt.""",
            fields=[
                CSRField("trigger", size=ints_per_bank, pulse=True)
            ])
        edge_triggered = CSRStorage(
           size=ints_per_bank,
           description="If a bit is set to 1, then the hardware trigger is edge-triggered",
           fields=[
               CSRField("use_edge", size=ints_per_bank)
           ]
        )
        polarity = CSRStorage(
            size=ints_per_bank,
            description="If a bit is set to 1, then the polarity is rising edge triggered; 0 is falling edge triggered. Bit is ignored if `edge_triggered` is 0.",
            fields=[
                CSRField("rising", size=ints_per_bank)
            ]
        )
        for i in range(ints_per_bank):
            bit_int = EventSourceFlex(
                trigger=interrupts[i],
                edge_triggered=edge_triggered.fields.use_edge[i],
                polarity=polarity.fields.rising[i],
                soft_trigger=soft.fields.trigger[i],
                name=names[i], #'source{}'.format(i),
                description=f'`1` when a "{names[i]}" event occurs. This event uses an `EventSourceFlex` form of triggering'
            )
            setattr(ev, 'source{}'.format(i), bit_int)

        ev.soft = soft
        ev.edge_triggered = edge_triggered
        ev.polarity = polarity
        ev.finalize()
        # setattr(self, 'evm{}'.format(bank), ev)

# Handle duplicating IRQs from the system set to unused/free banks to accelerate OS functions.
# Independent banks that can be mapped into a driver's process space will run much faster than
# an IRQ that has to bounce off of a generic handler in a different process space
#
# Args:
#   - pins is a list of pin signal vectors, each signal vector is 16 signals wide
#   - the 'comb' object so we can do assignments
#
# TODO: export this to a file so that daric_to_svd.py can generate IRQ field accessors for us automatically
def dupe_irqs(pins, comb):
    # check that we have 20 signal vectors
    assert(len(pins) == IRQ_BANKS)
    # check that each signal vector is 16 long
    for pin in pins:
        assert(pin.nbits == IRQS_PER_BANK)

    # define constants that map IRQS, extracted manually from source files :-P
    irq_padding = 16 # offset applied to IRQ banks due to vex_irq wiring quirk in soc_coresub_v0.2sv
    # ev_map[0] is MSB
    # ev_map[1] is LSB
    # ev_map[2] is a list of IRQ names
    ev_map = {
         # banks 1-2
        'coresubev': [31, 0, [
            '', '', '', '',   '', '', '', '', # unmapped
            '', '', '', '',   '', '', '', '', # unmapped
            'qfcirq', 'mdmairq', 'mbox_irq_available', 'mbox_irq_abort_init', 'mbox_irq_done', 'mbox_irq_error', '', '',
            '', '', '', '',   '', '', '', 'aowkupint',
        ]],
        # banks 3-4
        'sceev' : [63, 32, [
            'trng_done', 'aes_done', 'pke_done', 'hash_done', 'alu_done', 'sdma_ichdone', 'sdma_schdone', 'sdma_xchdone',
            '', '', '', '',   '', '', '', '',
            '', '', '', '',   '', '', '', '',
            '', '', '', '',   '', '', '', '',
        ]],
        # banks 5-12
        'ifsubev' : [191, 64, [
            # bank
            'uart0_rx', 'uart0_tx', 'uart0_rx_char', 'uart0_err',
            'uart1_rx', 'uart1_tx', 'uart1_rx_char', 'uart1_err',
            'uart2_rx', 'uart2_tx', 'uart2_rx_char', 'uart2_err',
            'uart3_rx', 'uart3_tx', 'uart3_rx_char', 'uart3_err',
            # bank
            'spim0_rx', 'spim0_tx', 'spim0_cmd',     'spim0_eot',
            'spim1_rx', 'spim1_tx', 'spim1_cmd',     'spim1_eot',
            'spim2_rx', 'spim2_tx', 'spim2_cmd',     'spim2_eot',
            'spim3_rx', 'spim3_tx', 'spim3_cmd',     'spim3_eot',
            # bank
            'i2c0_rx',  'i2c0_tx',  'i2c0_cmd',      'i2c0_eot',
            'i2c1_rx',  'i2c1_tx',  'i2c1_cmd',      'i2c1_eot',
            'i2c2_rx',  'i2c2_tx',  'i2c2_cmd',      'i2c2_eot',
            'i2c3_rx',  'i2c3_tx',  'i2c3_cmd',      'i2c3_eot',
            # bank
            'sdio_rx',  'sdio_tx',  'sdio_eot',      'sdio_err',
            'i2s_rx',   'i2s_tx',   '',              '',
            'cam_rx',   'adc_rx',   '',              '',
            'filter_eot','filter_act', '',           '',
            # bank
            'scif_rx',  'scif_tx',  'scif_rx_char',  'scif_err',
            'spis0_rx', 'spis0_tx', 'spis0_eot',     '',
            'spis1_rx', 'spis1_tx', 'spis1_eot',     '',
            # 76-79
            'pwm0_ev',  'pwm1_ev',  'pwm2_ev',       'pwm3_ev',
            # bank
            # 80
            'ioxirq',   'usbc',     'sddcirq',       'pioirq[0]',
            'pioirq[1]','pioirq[2]','pioirq[3]',     '',
            # 88
            '', '', '', '', '', '', '', '',
            # bank
            '', '', '', '', '', '', '', '',
            '', '', '', '', '', '', '', '',
            '', '', '', '', '', '', '', '',
            # 120
            'i2c0_nack', 'i2c1_nack', 'i2c2_nack', 'i2c3_nack',
            'i2c0_err',  'i2c1_err',  'i2c2_err',  'i2c3_err',
        ]],
        # banks 13-14
        'errirq' : [223, 192, [
            'coresuberr', 'sceerr', 'ifsuberr', 'secirq', '', '', '', '',
            '', '', '', '', '', '', '', '',
            '', '', '', '', '', '', '', '',
            '', '', '', '', '', '', '', '',
        ]],
        # bank 15
        'secirq' : [239, 224, [
            'sec0', 'sec1', 'sec2', 'sec3', 'sec4', 'sec5', 'sec6', 'sec7',
            '', '', '', '', '', '', '', '',
        ]],
    }
    # spot checks on manual extraction
    assert(len(ev_map['ifsubev'][2]) == 128)
    assert(ev_map['ifsubev'][2][64] == 'scif_rx')
    assert(ev_map['ifsubev'][2][80] == 'ioxirq')
    # check that all the records have the correct length
    for item in ev_map.values():
        assert(len(item[2]) % 16 == 0)

    # list of interrupts that are copied, and where to
    dupes = {
        # 'signal_name' : (target irq bank, target bit)
        (19, 0)   : 'mbox_irq_available'   , # mapped here fo soc/fpga "local" variants as well
        (19, 1)   : 'mbox_irq_abort_init'  ,
        (19, 2)   : 'mbox_irq_done'        ,
        (19, 3)   : 'mbox_irq_error'       ,
        (19, 4)   : 'pioirq[0]'            ,
        (19, 5)   : 'pioirq[1]'            ,
        (19, 6)   : 'pioirq[2]'            ,
        (19, 7)   : 'pioirq[3]'            ,
        (19, 8)   : 'sdio_rx'              ,
        (19, 9)   : 'sdio_tx'              ,
        (19, 10)  : 'sdio_eot'             ,
        (19, 11)  : 'sdio_err'             ,
        # rest are reserved for software interrupt use

        (18, 0)   : 'pioirq[0]'               ,
        (18, 1)   : 'pioirq[1]'               ,
        (18, 2)   : 'pioirq[2]'               ,
        (18, 3)   : 'pioirq[3]'               ,
        (18, 4)   : 'i2c2_rx'                 ,
        (18, 5)   : 'i2c2_tx'                 ,
        (18, 6)   : 'i2c2_cmd'                ,
        (18, 7)   : 'i2c2_eot'                ,
        (18, 8)   : 'i2c0_nack'               ,
        (18, 9)   : 'i2c1_nack'               ,
        (18, 10)  : 'i2c2_nack'               ,
        (18, 11)  : 'i2c0_err'                ,
        (18, 12)  : 'i2c1_err'                ,
        (18, 13)  : 'i2c2_err'                ,
        (18, 14)  : 'ioxirq'                  ,
        (18, 15)  : 'cam_rx'                  ,

        (0, 0)    : 'mdmairq'                 ,  # unused 0-bank
        (0, 4)   : 'pioirq[0]'               ,
        (0, 5)   : 'pioirq[1]'               ,
        (0, 6)   : 'pioirq[2]'               ,
        (0, 7)   : 'pioirq[3]'               ,
        (1, 0)    : 'usbc'                    ,   # unused bottom half of coresub
        (11, 0)   : 'i2s_rx'                  ,   # unused bank in ifsubev
        (11, 1)   : 'i2s_tx'                  ,   # unused bank in ifsubev

        # alias of SCE to unused bank
        (4, 0)    : 'trng_done'               ,
        (4, 1)    : 'aes_done'                ,
        (4, 2)    : 'pke_done'                ,
        (4, 3)    : 'hash_done'               ,
        (4, 4)    : 'alu_done'                ,
        (4, 5)    : 'sdma_ichdone'            ,
        (4, 6)    : 'sdma_schdone'            ,
        (4, 7)    : 'sdma_xchdone'            ,

        (14, 0)   : 'uart2_rx'                ,  # replicas so the kernel can have its own secure UART routine
        (14, 1)   : 'uart2_tx'                ,
        (14, 2)   : 'uart2_rx_char'           ,
        (14, 3)   : 'uart2_err'               ,
        (14, 4)   : 'uart3_rx'                ,
        (14, 5)   : 'uart3_tx'                ,
        (14, 6)   : 'uart3_rx_char'           ,
        (14, 7)   : 'uart3_err'               ,
        (14, 8)   : 'trng_done'               ,

        (16, 0)   : 'cam_rx'                  ,
        (16, 1)   : 'i2s_rx'                  ,
        (16, 2)   : 'i2s_tx'                  ,
        (16, 4)   : 'spim1_rx'                ,
        (16, 5)   : 'spim1_tx'                ,
        (16, 6)   : 'spim1_cmd'               ,
        (16, 7)   : 'spim1_eot'               ,
        (16, 8)   : 'spim2_rx'                ,
        (16, 9)   : 'spim2_tx'                ,
        (16, 10)  : 'spim2_cmd'               ,
        (16, 11)  : 'spim2_eot'               ,
        (16, 12)  : 'i2c0_rx'                 ,
        (16, 13)  : 'i2c0_tx'                 ,
        (16, 14)  : 'i2c0_cmd'                ,
        (16, 15)  : 'i2c0_eot'                ,

        (17, 0)   : 'i2c1_rx'                 ,
        (17, 1)   : 'i2c1_tx'                 ,
        (17, 2)   : 'i2c1_cmd'                ,
        (17, 3)   : 'i2c1_eot'                ,
        (17, 4)   : 'pioirq[0]'               ,
        (17, 5)   : 'pioirq[1]'               ,
        (17, 6)   : 'pioirq[2]'               ,
        (17, 7)   : 'pioirq[3]'               ,
        (17, 8)   : 'qfcirq'                  ,
        (17, 9)   : 'adc_rx'                  ,
        (17, 10)  : 'ioxirq'                  ,
        (17, 11)  : 'sddcirq'                 ,
        # rest are reserved for software interrupt use
    }
    dupes_mapped = 0

    dupe_pins = []
    dupe_names = []
    flattened_map = {}
    for i, bank in enumerate(range(IRQ_BANKS)):
        irq_remap = Signal(IRQS_PER_BANK)
        dupe_pins += [irq_remap]
        names = []
        for j in range(IRQS_PER_BANK):
            names += [f'nc_b{i}s{j}']
        dupe_names += [names]

    for bank in range(IRQ_BANKS):
        for pin in range(IRQS_PER_BANK):
            abs_offset = bank * IRQS_PER_BANK + pin
            # check to see if the current pin has a mapping
            cur_pin_name = None
            evmap_offset = abs_offset - irq_padding # this is the "native" index system of ev_map
            if evmap_offset >= 0 and evmap_offset <= ev_map['secirq'][1]: # the MSB of the highest mapped grouping
                for group in ev_map.values():
                    if evmap_offset <= group[0] and evmap_offset >= group[1]:
                        cur_pin_name = group[2][evmap_offset - group[1]]
                        break
                assert(cur_pin_name is not None) # all mapped pins must have a value, even if it is '' (the empty string)

            found = False
            # search and see if the current pin has a match to a dupe mapping; if so, wire it to the dupe mapping
            for ((d_bank, d_pin), name) in dupes.items():
                if d_bank == bank and d_pin == pin:
                    # check that the pin isn't actually used
                    assert(cur_pin_name == '' or cur_pin_name == None)
                    # resolve the name to a bank and pin number
                    for group in ev_map.values():
                        if name in group[2]:
                            assert(found == False)
                            found = True # we iterate through everything to make sure we don't have duplicate names
                            index = group[2].index(name)
                            source_abs_offset = index + group[1] + irq_padding
                            comb += [
                                dupe_pins[bank][pin].eq(
                                    pins[int(source_abs_offset / IRQS_PER_BANK)][source_abs_offset % IRQS_PER_BANK]
                                )
                            ]
                            dupe_names[bank][pin] = f"{name.replace('[','').replace(']','')}_dupe" # _b{d_bank}s{d_pin}
                            dupes_mapped += 1
            if found is False:
                # just pass the wiring through
                comb += [
                    dupe_pins[bank][pin].eq(pins[bank][pin])
                ]
                if cur_pin_name is not None and cur_pin_name != '':
                    dupe_names[bank][pin] = f"{cur_pin_name.replace('[','').replace(']','')}" # _b{bank}_s{pin}
                    # the +16 is just a quirk of the implementation -- all the offsets are pushed by 16,
                    # I think the bottom 16 were originally meant to be reserved for something else but
                    # it never actually got used?
                    flattened_map[evmap_offset + 16] = f"{cur_pin_name.replace('[','').replace(']','')}"
    # check that all dupes got mapped
    assert(dupes_mapped == len(dupes))
    return dupe_pins, dupe_names, flattened_map

# ResetValue ----------------------------------------------------------------------------------

class ResetValue(Module, AutoCSR, AutoDoc):
    """Actual reset value"""
    def __init__(self, default_value, trimming_reset, trimming_reset_ena):
        self.intro = ModuleDoc("""
`ResetValue` captures the actual reset value present at a reset event. The reason this is
necessary is because the reset value could either be that built into the silicon, or it could
come from a "trimming value" that is programmed via ReRAM bits. This vector can be read back to
confirm that the reset vector is, in fact, where we expected it to be.

`default_value` specifies what the value would be if the `trimming_reset` ReRAM bits are not
enabled with `trimming_reset_ena`.
        """)
        self.reset_value = CSRStatus(32, name="pc", description="Latched value for PC on reset")
        latched_value = Signal(32, reset_less=True)
        self.sync += [
            If(ResetSignal(),
                If(trimming_reset_ena,
                    latched_value.eq(trimming_reset)
                ).Else(
                    latched_value.eq(default_value)
                )
            ).Else(
                latched_value.eq(latched_value)
            )
        ]
        self.comb += self.reset_value.status.eq(latched_value)

# CoreUserLite --------------------------------------------------------------------------------
class CoreUserLite(Module, AutoCSR, AutoDoc):
    """Core User computation logic"""
    def __init__(self, cpu, coreuser, mm, default_user, default_mm):
        self.intro = ModuleDoc(
"""
`CoreUser` is a hardware signal that indicates that the code executing is in a highly trusted
piece of code. This is determined by examining a configurable combination of the SATP's ASID,
PPN values, and/or privilege bits from `$mstatus.mpp`, allowing the OS to target certain virtual
memory spaces as more trusted than others. `CoreUser` can only be fully computed when the RISC-V core
is in Sv32 mode (that is, virtual memory has been enabled).

`$mstatus.mpp` encodes the machine mode as following:
  - 0b11: machine mode. The most privileged mode, and the mode the loader runs in. It is not
    achievable after switching into Xous.
  - 0b10: reserved
  - 0b01: supervisor mode. This is the mode the kernel runs in.
  - 0b00: user mode. This is the least privileged mode and the mode of all user code.

The output of this block needs to be as follows:

`coreuser_vex[7:0]` is a one-hot encoded bus with the following mapping:
  - Bits [3:0] are 0
  - Bits [7:4] are 1-hot encoded according to the following:
    - Bit 7: fw1
    - Bit 6: fw0
    - Bit 5: boot1
    - Bit 4: boot0

The default power on state should be `boot0`.

`vex_mm` is a bit that indicates a heightened privelege state while in the user mapping.
`1` means more privileged. On boot, this should be `1`. Note that during Xous runtime,
a *user* process gets exclusive access to fuse bits, and so, the privelege level sense
is inverted compared to boot time.
        """)

        self.control = CSRStorage(fields=[
            CSRField("enable", size=1, description="When set to `1`, mappings are enabled. When `0`, the `CoreUser` value is fixed to 0b0001_0000, and the `vex_mm` bit is set to '`1`."),
            CSRField("invert_priv", size=1, description="When set to `1` inverts the sense of the privilege bit"),
        ])
        self.status = CSRStatus(fields=[
            CSRField("coreuser", size=8, description="Computed value of the `CoreUser` signal as passed on to the SoC. For debugging."),
            CSRField("mm", size=1, description="Computed value of the `mm` signal passed on to the SoC."),
        ])
        self.map_lo = CSRStorage(fields=[
            CSRField("lut0", size=8, description="Mapping of `CoreUser` ASID to coreuser dense conding bit 0"),
            CSRField("lut1", size=8, description="Mapping of `CoreUser` ASID to coreuser dense conding bit 0"),
            CSRField("lut2", size=8, description="Mapping of `CoreUser` ASID to coreuser dense conding bit 0"),
            CSRField("lut3", size=8, description="Mapping of `CoreUser` ASID to coreuser dense conding bit 0"),
        ])
        self.map_hi = CSRStorage(fields=[
            CSRField("lut4", size=8, description="Mapping of `CoreUser` ASID to coreuser dense coding bit 1"),
            CSRField("lut5", size=8, description="Mapping of `CoreUser` ASID to coreuser dense coding bit 1"),
            CSRField("lut6", size=8, description="Mapping of `CoreUser` ASID to coreuser dense coding bit 1"),
            CSRField("lut7", size=8, description="Mapping of `CoreUser` ASID to coreuser dense coding bit 1"),
        ])
        self.uservalue = CSRStorage(fields=[
            CSRField("user0", size=2, description="Value of `CoreUser` for lut0 match"),
            CSRField("user1", size=2, description="Value of `CoreUser` for lut1 match"),
            CSRField("user2", size=2, description="Value of `CoreUser` for lut2 match"),
            CSRField("user3", size=2, description="Value of `CoreUser` for lut3 match"),
            CSRField("user4", size=2, description="Value of `CoreUser` for lut4 match"),
            CSRField("user5", size=2, description="Value of `CoreUser` for lut5 match"),
            CSRField("user6", size=2, description="Value of `CoreUser` for lut6 match"),
            CSRField("user7", size=2, description="Value of `CoreUser` for lut7 match"),
            CSRField("default", size=2, description="Default value of `CoreUser`, for when none of the others match"),
        ])
        self.protect = CSRStorage(size=1, description="Writing `1` to this bit prevents any further updates to CoreUser configuration status. Can only be reversed with a system reset.");

        # one-way door for protecting block from updates
        protect = Signal()
        # instantiate as an explicitly reset FF since this signal *must* have a defined reset behavior
        self.specials += Instance(
            "fdre_cosim",
            i_C=ClockSignal(),
            i_D=1,
            i_R=ResetSignal(),
            o_Q=protect,
            i_CE=self.protect.storage,
        )

        enable = Signal()
        invert_priv = Signal()
        lut0 = Signal(8)
        lut1 = Signal(8)
        lut2 = Signal(8)
        lut3 = Signal(8)
        lut4 = Signal(8)
        lut5 = Signal(8)
        lut6 = Signal(8)
        lut7 = Signal(8)
        user0 = Signal(2)
        user1 = Signal(2)
        user2 = Signal(2)
        user3 = Signal(2)
        user4 = Signal(2)
        user5 = Signal(2)
        user6 = Signal(2)
        user7 = Signal(2)
        user_default = Signal(2)
        self.sync += [
            If(protect,
                enable.eq(enable),
                invert_priv.eq(invert_priv),
                lut0.eq(lut0),
                lut1.eq(lut1),
                lut2.eq(lut2),
                lut3.eq(lut3),
                lut4.eq(lut4),
                lut5.eq(lut5),
                lut6.eq(lut6),
                lut7.eq(lut7),
                user0.eq(user0),
                user1.eq(user1),
                user2.eq(user2),
                user3.eq(user3),
                user4.eq(user4),
                user5.eq(user5),
                user6.eq(user6),
                user7.eq(user7),
                user_default.eq(user_default),
            ).Else(
                enable.eq(self.control.fields.enable),
                invert_priv.eq(self.control.fields.invert_priv),
                lut0.eq(self.map_lo.fields.lut0),
                lut1.eq(self.map_lo.fields.lut1),
                lut2.eq(self.map_lo.fields.lut2),
                lut3.eq(self.map_lo.fields.lut3),
                lut4.eq(self.map_hi.fields.lut4),
                lut5.eq(self.map_hi.fields.lut5),
                lut6.eq(self.map_hi.fields.lut6),
                lut7.eq(self.map_hi.fields.lut7),
                user0.eq(self.uservalue.fields.user0),
                user1.eq(self.uservalue.fields.user1),
                user2.eq(self.uservalue.fields.user2),
                user3.eq(self.uservalue.fields.user3),
                user4.eq(self.uservalue.fields.user4),
                user5.eq(self.uservalue.fields.user5),
                user6.eq(self.uservalue.fields.user6),
                user7.eq(self.uservalue.fields.user7),
                user_default.eq(self.uservalue.fields.default),
            )
        ]
        self.sync += [
            self.status.fields.coreuser.eq(coreuser),
            self.status.fields.mm.eq(mm),
        ]

        spoiler = cpu.satp_asid[8]
        coreuser_2bit = Signal(2)
        self.comb += [
            If(cpu.satp_asid == Cat(lut0, 0),
                coreuser_2bit.eq(user0),
            ).Elif(cpu.satp_asid == Cat(lut1, 0),
                coreuser_2bit.eq(user1),
            ).Elif(cpu.satp_asid == Cat(lut2, 0),
                coreuser_2bit.eq(user2),
            ).Elif(cpu.satp_asid == Cat(lut3, 0),
                coreuser_2bit.eq(user3),
            ).Elif(cpu.satp_asid == Cat(lut4, 0),
                coreuser_2bit.eq(user4),
            ).Elif(cpu.satp_asid == Cat(lut5, 0),
                coreuser_2bit.eq(user5),
            ).Elif(cpu.satp_asid == Cat(lut6, 0),
                coreuser_2bit.eq(user6),
            ).Elif(cpu.satp_asid == Cat(lut7, 0),
                coreuser_2bit.eq(user7),
            ).Else(
                coreuser_2bit.eq(user_default)
            )
        ]
        coreuser_4bit = Signal(4)
        coreuser_cases = {}
        for i in range(4):
            coreuser_cases[i] = coreuser_4bit.eq(1 << i)
        self.comb += [
            If(enable,
               Case(
                   coreuser_2bit,
                   coreuser_cases,
               )
            ).Else(
                Case(
                    default_user,
                    coreuser_cases,
                )
            )
        ]
        self.sync += [
            coreuser[4:].eq(coreuser_4bit),
            coreuser[:4].eq(Cat(coreuser_4bit[3], coreuser_4bit[2], coreuser_4bit[1], coreuser_4bit[0])),
            If(enable,
               mm.eq((cpu.privilege[0] | cpu.privilege[1]) ^ invert_priv)
            ).Else(
               mm.eq(default_mm)
            )
        ]

# CoreUser ------------------------------------------------------------------------------------

class CoreUser(Module, AutoCSR, AutoDoc):
    """Core User computation logic"""
    def __init__(self, cpu, coreuser):
        self.intro = ModuleDoc("""
`CoreUser` is a hardware signal that indicates that the code executing is in a highly trusted
piece of code. This is determined by examining a configurable combination of the SATP's ASID,
PPN values, and/or privilege bits from `$mstatus.mpp`, allowing the OS to target certain virtual
memory spaces as more trusted than others. `CoreUser` can only be computed when the RISC-V core
is in Sv32 mode (that is, virtual memory has been enabled).

When specifying PPN values, two windows are provided, `a` and `b`. The windows are
computed independently, and then OR'd together. The `a` and `b` windows should be non-overlapping.
If they overlap, or the windows are poorly-specified, the behavior is not guaranteed. The intention
of having two windows is not so that the OS can specify only two processes as `CoreUser`. Rather,
the OS should design to allocate all CoreUser processes within a single range that is protected
by a single window. The alternate window is provided only so that the OS can have a scratch space to
re-organize or shuffle around process spaces at a higher level.

When specifying privilege, one specifies the state that must match for `coreuser` to be active.
For a microkernel, one would specify a non-elevated permission level, as secure access is always
delegated to a userland service. For a monokernel, one would specify an elevated permission level.

The `CoreUser` signal is not cycle-precise; it will assert roughly 2 cycles after the `satp` is updated.
Furthermore, the `satp` ASID field is an advisory field that isn't used by CPU hardware to enforce
page access. You can think of `coreuser` as a signal that the kernel can control to indicate if the
context we are swapping into should be trusted. Fortunately, any update to `satp` in a virtual memory OS
should be followed by an `sfence` instruction (to invalidate TLB mappings etc.), which gives time for
the `coreuser` signal to propagate through the pipeline.

Thus in practice by the time the first instruction of user code runs, `coreuser` should be set properly.
However, from  a security audit perspective, it is important to keep in mind that there is a race condition between
the `satp` setting and user code execution.
        """)
        self.cmbist = Signal()
        self.cmatpg = Signal()
        self.vexsramtrm = Signal(3)
        self.set_asid = CSRStorage(fields=[
            CSRField("asid", size=9, description="ASID to set. Writing to this register commits the value in `trusted` to the specified `asid` value"),
            CSRField("trusted", size=1, description="Set to `1` if the ASID is trusted"),
        ])
        self.get_asid_addr = CSRStorage(fields=[
            CSRField("asid", size=9, description="ASID to read back.")
        ])
        self.get_asid_value = CSRStatus(fields=[
            CSRField("value", size=1, description="Value corresponding to the ASID specified in `get_asid_addr`. `1` means trusted"),
        ])
        self.set_privilege = CSRStorage(fields=[
            CSRField("mpp", size=2, description="Value of `mpp` bit from `mstatus` that must match for code to be trusted"),
        ])
        self.control = CSRStorage(fields=[
            CSRField("enable", size=1, description="Enable `CoreUser` computation. When set to `1`, the settings are applied; when cleared to `0`, the `CoreUser` signal is always valid. Defaults to `0`."),
            CSRField("asid", size=1, description="When `1`, requires the ASID mapping to be trusted to assert `CoreUser`"),
            CSRField("ppn_a", size=1, description="When set to `1`, requires the `a` `ppn` window to be trusted to assert `CoreUser`"),
            CSRField("ppn_b", size=1, description="When set to `1`, requires the `b` `ppn` window to be trusted to assert `CoreUser`"),
            CSRField("privilege", size=1, description="When set to `1`, requires the current privilege state to match that specified in `set_privilege.mpp`"),
        ])
        self.protect = CSRStorage(size=1, description="Writing `1` to this bit prevents any further updates to CoreUser configuration status. Can only be reversed with a system reset.");
        self.window_al = CSRStorage(fields=[
            CSRField("ppn", size=22, description="PPN match value, `a` window lower bound. Matches if ppn is greater than or equal to this value"),
        ])
        self.window_ah = CSRStorage(fields=[
            CSRField("ppn", size=22, description="PPN match value, `a` window upper bound. Matches if ppn is less than or equal to this value (so a value of 255 would match everything from 0 to 255; resulting in 256 total locations"),
        ])
        self.window_bl = CSRStorage(fields=[
            CSRField("ppn", size=22, description="PPN match value, `b` window lower bound. Matches if ppn is greater than or equal to this value"),
        ])
        self.window_bh = CSRStorage(fields=[
            CSRField("ppn", size=22, description="PPN match value, `b` window upper bound. Matches if ppn is less than or equal to this value (so a value of 255 would match everything from 0 to 255; resulting in 256 total locations"),
        ])
        # one-way door for protecting block from updates
        protect = Signal()
        # instantiate as an explicitly reset FF since this signal *must* have a defined reset behavior
        self.specials += Instance(
            "fdre_cosim",
            i_C=ClockSignal(),
            i_D=1,
            i_R=ResetSignal(),
            o_Q=protect,
            i_CE=self.protect.storage,
        )

        enable = Signal()
        require_asid = Signal()
        require_ppn_a = Signal()
        require_ppn_b = Signal()
        require_priv = Signal()
        privilege = Signal(2)
        self.sync += [
            If(protect,
                enable.eq(enable),
                require_asid.eq(require_asid),
                require_ppn_a.eq(require_ppn_a),
                require_ppn_b.eq(require_ppn_b),
                require_priv.eq(require_priv),
                privilege.eq(privilege),
            ).Else(
                enable.eq(self.control.fields.enable),
                require_asid.eq(self.control.fields.asid),
                require_ppn_a.eq(self.control.fields.ppn_a),
                require_ppn_b.eq(self.control.fields.ppn_b),
                require_priv.eq(self.control.fields.privilege),
                privilege.eq(self.set_privilege.fields.mpp),
            )
        ]

        asid_rd_adr = Signal(9)
        asid_rd_dat = Signal()
        asid_rd_dat_mux = Signal(16)
        asid_wr_adr = Signal(9)
        asid_wr_dat = Signal()
        asid_wr_dat_demux = Signal(16)
        asid_wr_mask_demux = Signal(16)
        asid_wr_we = Signal()
        # storage used in ASID translation
        self.specials += Instance(
            "Ram_1w_1rs",
            p_ramname="RAM_DP_32_16_WM",
            p_wordCount=32,
            p_wordWidth=16,
            p_clockCrossing=0,
            p_wrAddressWidth=5,
            p_wrDataWidth=16,
            p_wrMaskEnable=1,
            p_wrMaskWidth=16,
            p_rdAddressWidth=5,
            p_rdDataWidth=16,
            i_wr_clk = ClockSignal(),
            i_wr_en = asid_wr_we,
            i_wr_mask = asid_wr_mask_demux,
            i_wr_addr = asid_wr_adr[4:],
            i_wr_data = asid_wr_dat_demux,
            i_rd_clk = ClockSignal(),
            i_rd_en = 1,
            i_rd_addr = asid_rd_adr[4:],
            o_rd_data = asid_rd_dat_mux,
            i_CMBIST = self.cmbist,
            i_CMATPG = self.cmatpg,
            i_sramtrm = self.vexsramtrm,
        )
        demux_mask_cases = {}
        demux_data_cases = {}
        for i in range(16):
            demux_mask_cases[i] = asid_wr_mask_demux.eq(1 << i)
            demux_data_cases[i] = asid_wr_dat_demux.eq(asid_wr_dat << i)
        coreuser_mux_delay = Signal(4) # line up the mux address with the data output
        self.sync += coreuser_mux_delay.eq(asid_rd_adr[:4])
        self.comb += [
            asid_rd_dat.eq(asid_rd_dat_mux >> coreuser_mux_delay),
            Case(
                asid_wr_adr[:4],
                demux_mask_cases,
            ),
            Case(
                asid_wr_adr[:4],
                demux_data_cases,
            )
        ]
        # storage used for readback checking
        readback_rd_dat_mux = Signal(16)
        self.specials += Instance(
            "Ram_1w_1rs",
            p_ramname="RAM_DP_32_16_MM",
            p_wordCount=32,
            p_wordWidth=16,
            p_clockCrossing=0,
            p_wrAddressWidth=5,
            p_wrDataWidth=16,
            p_wrMaskEnable=1,
            p_wrMaskWidth=16,
            p_rdAddressWidth=5,
            p_rdDataWidth=16,
            i_wr_clk = ClockSignal(),
            i_wr_en = asid_wr_we, # gang write
            i_wr_mask = asid_wr_mask_demux,
            i_wr_addr = asid_wr_adr[4:],
            i_wr_data = asid_wr_dat_demux,
            i_rd_clk = ClockSignal(),
            i_rd_en = 1,
            i_rd_addr = self.get_asid_addr.fields.asid[4:],
            o_rd_data = readback_rd_dat_mux,
            i_CMBIST = self.cmbist,
            i_CMATPG = self.cmatpg,
            i_sramtrm = self.vexsramtrm,
        )
        readback_shift_delay = Signal(4)
        self.sync += readback_shift_delay.eq(self.get_asid_addr.fields.asid[:4])
        self.comb += [
            self.get_asid_value.fields.value.eq(readback_rd_dat_mux >> readback_shift_delay)
        ]

        coreuser_asid = Signal()

        self.comb += [
            asid_rd_adr.eq(cpu.satp_asid),
            coreuser_asid.eq(asid_rd_dat),
            asid_wr_adr.eq(self.set_asid.fields.asid),
            asid_wr_dat.eq(self.set_asid.fields.trusted),
            asid_wr_we.eq(~protect & self.set_asid.re),
        ]
        window_al = Signal(22)
        window_ah = Signal(22)
        window_bl = Signal(22)
        window_bh = Signal(22)

        self.sync += [
            If(protect,
                window_al.eq(window_al),
                window_ah.eq(window_ah),
                window_bl.eq(window_bh),
                window_bh.eq(window_bh)
            ).Else(
                window_al.eq(self.window_al.fields.ppn),
                window_ah.eq(self.window_ah.fields.ppn),
                window_bl.eq(self.window_bl.fields.ppn),
                window_bh.eq(self.window_bh.fields.ppn),
            ),
            coreuser.eq(
                # always trusted if we're not in Sv32 mode
                ~cpu.satp_mode |
                # always trusted if this check is disabled
                ~enable |
                # ASID-based check
                (coreuser_asid | ~require_asid) &
                # PPN window A check
                (~require_ppn_a | (
                    (cpu.satp_ppn >= window_al) &
                    (cpu.satp_ppn <= window_ah)
                )) &
                # PPN window B check
                (~require_ppn_b | (
                    (cpu.satp_ppn >= window_bl) &
                    (cpu.satp_ppn <= window_bh)
                )) &
                (~require_priv | (cpu.privilege == privilege))
            )
        ]

# TickTimer (configurable) -------------------------------------------------------------------------

class TickTimer(Module, AutoCSR, AutoDoc):
    """Millisecond timer"""
    def __init__(self, clkspertick, clkfreq, bits=64):
        clkspertick = int(clkfreq/ clkspertick)
        self.clkspertick = Signal(32, reset = clkspertick)

        self.intro = ModuleDoc("""TickTimer: A practical systick timer.

        TIMER0 in the system gives a high-resolution, sysclk-speed timer which overflows
        very quickly and requires OS overhead to convert it into a practically usable time source
        which counts off in systicks, instead of sysclks.

        The hardware parameter to the block is the divisor of sysclk, and sysclk. So if
        the divisor is 1000, then the increment for a tick is 1ms. If the divisor is 2000,
        the increment for a tick is 0.5ms.

        Note to self: substantial area savings could be hand by being smarter about the
        synchronization between the always-on and the TickTimer domains. Right now about 1.8%
        of the chip is eaten up by ~1100 synchronization registers to cross the 64-bit values
        between the clock domains. Since the values move rarely, a slightly smarter method
        would be to create a lock-out around a read pulse and then create some false_path
        rules around the datapaths to keep the place/route from getting distracted by the
        cross-domain clocks.
        """)

        resolution_in_ms = 1000 * (clkspertick / clkfreq)
        self.note = ModuleDoc(title="Configuration",
            body="This timer was configured with defaults of {} bits, which rolls over in {:.2f} years, with each bit giving {}ms resolution".format(
                bits, (2**bits / (60*60*24*365)) * (clkspertick / clkfreq), resolution_in_ms))

        prescaler = Signal(32, reset=clkspertick)
        timer = Signal(bits)

        # cross-process domain signals. Broken out to a different CSR so it can be on a different virtual memory page.
        self.pause = Signal()
        pause = Signal()
        self.specials += MultiReg(self.pause, pause, "always_on")

        self.load = Signal()
        self.submodules.load_xfer = BlindTransfer("sys", "always_on")
        self.comb += self.load_xfer.i.eq(self.load)

        self.paused = Signal()
        paused = Signal()
        self.specials += MultiReg(paused, self.paused)

        self.timer = Signal(bits)
        self.submodules.timer_sync = BusSynchronizer(bits, "always_on", "sys")
        self.comb += [
            self.timer_sync.i.eq(timer),
            self.timer.eq(self.timer_sync.o)
        ]
        self.resume_time = Signal(bits)
        self.submodules.resume_sync = BusSynchronizer(bits, "sys", "always_on")
        self.comb += [
            self.resume_sync.i.eq(self.resume_time)
        ]

        self.control = CSRStorage(fields=[
            CSRField("reset", description="Write a `1` to this bit to reset the count to 0. This bit has priority over all other requests.", pulse=True),
        ])
        self.time = CSRStatus(bits, name="time", description="""Elapsed time in systicks""")
        self.comb += self.time.status.eq(self.timer_sync.o)

        self.submodules.reset_xfer = BlindTransfer("sys", "always_on")
        self.comb += [
            self.reset_xfer.i.eq(self.control.fields.reset),
        ]

        self.sync.always_on += [
            If(self.reset_xfer.o,
                timer.eq(0),
                prescaler.eq(self.clkspertick),
            ).Elif(self.load_xfer.o,
                prescaler.eq(self.clkspertick),
                timer.eq(self.resume_sync.o),
            ).Else(
                If(prescaler == 0,
                   prescaler.eq(self.clkspertick),

                   If(pause == 0,
                       timer.eq(timer + 1),
                       paused.eq(0)
                   ).Else(
                       timer.eq(timer),
                       paused.eq(1)
                   )
                ).Else(
                   prescaler.eq(prescaler - 1),
                )
            )
        ]

        self.msleep = ModuleDoc("""msleep extension

        The msleep extension is a Xous-specific add-on to aid the implementation of the msleep server.

        msleep fires an interrupt when the requested time is less than or equal to the current elapsed time in
        systicks. The interrupt remains active until a new target is set, or masked.

        There is a slight slip in time (~200ns) from when the msleep timer is set before it can take effect.
        This is because it takes many CPU clock cycles to transfer this data into the always-on clock
        domain, which runs at a much slower rate than the CPU clock.
        """)
        self.msleep_target = CSRStorage(size=bits, description="Target time in {}ms ticks".format(resolution_in_ms))
        self.submodules.ev = EventManager()
        self.ev.alarm = EventSourceLevel()
        # sys-domain alarm is computed using sys-domain time view, so that the trigger condition
        # corresponds tightly to the setting of the target time
        alarm_trigger = Signal()
        self.comb += self.ev.alarm.trigger.eq(alarm_trigger)
        self.ev.finalize()

        # always_on domain gets a delayed copy of msleep_target
        # thus its output may not match that of the sys-domain alarm
        # in particular, it takes time for msleep_target update to propagate through
        # the bus synchronizers; however, the "trigger" enable for the system is handled
        # in the sys-domain, and can be set *before* the bus synchronizers have passed the
        # data through. This causes the alarm to glitch prematurely.

        # if we seem to be errantly aborting WFI's that are entered shortly after
        # setting an msleep target, this race condition is likely the culprit.

        # the circuit below locks out alarms for the duration of time that it takes for
        # msleep_target to propagate to its target, and back again
        self.submodules.ping = BlindTransfer("sys", "always_on")
        self.comb += self.ping.i.eq(self.msleep_target.re)
        self.submodules.pong = BlindTransfer("always_on", "sys")
        self.comb += self.pong.i.eq(self.ping.o)
        lockout_alarm = Signal()
        self.comb += [
            If(lockout_alarm,
                alarm_trigger.eq(0)
            ).Else (
                alarm_trigger.eq(self.msleep_target.storage <= self.timer_sync.o)
            )
        ]
        self.sync += [
            If(self.msleep_target.re,
                lockout_alarm.eq(1)
            ).Elif(self.pong.o,
                lockout_alarm.eq(0)
            ).Else(
                lockout_alarm.eq(lockout_alarm)
            )
        ]

        # re-compute the alarm signal in the "always on" domain -- so that this can trigger even when the CPU clock is stopped
        alarm = Signal()
        self.submodules.target_xfer = BusSynchronizer(bits, "sys", "always_on")
        self.comb += self.target_xfer.i.eq(self.msleep_target.storage)
        self.sync.always_on += alarm.eq(self.target_xfer.o <= timer)

        self.alarm_always_on = Signal()
        self.comb += self.alarm_always_on.eq(alarm)

        self.clocks_per_tick = CSRStorage(size=32, description="Clocks per tick, defaults to {}".format(clkspertick), reset=clkspertick)
        self.comb += self.clkspertick.eq(self.clocks_per_tick.storage)


# cramSoC -------------------------------------------------------------------------------------

class cramSoC(SoCCore):
    # I/O range: 0x80000000-0xfffffffff (not cacheable)
    SoCCore.mem_map = {
        "reram"     : 0x6000_0000, # +3M
        "sram"      : 0x6100_0000, # +2M
        "p_axi"     : 0x4000_0000, # +256M  # this is an IO region
        "vexriscv_debug": 0xefff_0000,
        "csr"       : 0x5800_0000,
    }

    def __init__(self, sys_clk_freq=int(100e6),
                 bios_path='boot/boot.bin',
                 coreuser_compression=False,
                 **kwargs):
        global bios_size

        # Platform ---------------------------------------------------------------------------------
        platform = Platform(device="", io=get_common_ios())
        platform.name = "litex_soc"

        # CRG --------------------------------------------------------------------------------------
        self.clock_domains.cd_sys = ClockDomain()
        self.comb += [
            self.cd_sys.clk.eq(platform.request("aclk")),
            self.cd_sys.rst.eq(platform.request("rst")),
        ]
        self.clock_domains.cd_always_on = ClockDomain()
        self.comb += [
            self.cd_always_on.clk.eq(platform.request("always_on")),
            self.cd_always_on.rst.eq(ResetSignal()),
        ]

        # SoCMini ----------------------------------------------------------------------------------
        reset_address = self.mem_map["reram"]
        SoCMini.__init__(self, platform, sys_clk_freq,
            cpu_type             = "vexiiriscv_cramsoc",
            csr_paging           = 4096,  # increase paging to 1 page size
            csr_address_width    = 16,    # increase to accommodate larger page size
            cpu_reset_address    = reset_address,
            cpu_custom_memory    = True,
            bus_standard         = "axi-lite",
            bus_interconnect     = "crossbar",
            # bus_timeout          = None,
            with_ctrl            = False,
            with_timer           = True,
            io_regions           = {
                # Origin, Length.
                0x4000_0000 : 0x2000_0000,
                0xa000_0000 : 0x6000_0000,
            },
            **kwargs)

        self.csr.locs = {
            'd11ctime': 0,
            'susres': 1,
            'coreuser': 2,
            'csrtest': 3,
            'irqarray0': 4,
            'irqarray1': 5,
            'irqarray10': 6,
            'irqarray11': 7,
            'irqarray12': 8,
            'irqarray13': 9,
            'irqarray14': 10,
            'irqarray15': 11,
            'irqarray16': 12,
            'irqarray17': 13,
            'irqarray18': 14,
            'irqarray19': 15,
            'irqarray2': 16,
            'irqarray3': 17,
            'irqarray4': 18,
            'irqarray5': 19,
            'irqarray6': 20,
            'irqarray7': 21,
            'irqarray8': 22,
            'irqarray9': 23,
            'mailbox': 24,
            'mb_client': 25,
            'resetvalue': 26,
            'ticktimer': 27,
            'timer0': 28,
            'legacy_int' : 29,
        }

        self.irq.locs['timer0'] = 30 # fix the IRQ so we don't stomp on MPW compat
        self.cpu.use_external_variant("VexiiRiscv/VexiiRiscv-cramsoc.sv")
        self.cpu.add_debug()
        # self.cpu.set_reset_address(reset_address)
        self.cpu.disable_reset_address_check()
        trimming_reset = Signal(32)
        trimming_reset_ena = Signal()
        self.submodules.resetvalue = ResetValue(reset_address, trimming_reset, trimming_reset_ena)
        self.comb += [
            trimming_reset.eq(platform.request("trimming_reset")),
            trimming_reset_ena.eq(platform.request("trimming_reset_ena")),
            self.cpu.trimming_reset.eq(trimming_reset),
            self.cpu.trimming_reset_ena.eq(trimming_reset_ena),
        ]

        # Break out custom busses to pads ----------------------------------------------------------
        # All appear as "memory", to avoid triggering interference from the bushandler automation
        for mem_bus in self.cpu.memory_buses:
            if 'ibus' in mem_bus:
                ibus = mem_bus[1]
                if True:
                    ibus_ios = ibus.get_ios("ibus_axi")
                else: # aborted attempt to filter what gets connected out
                    suppress = [
                        'awvalid',
                        'awready',
                        'awaddr',
                        'awburst',
                        'awcache',
                        'awlen',
                        'awlock',
                        'awprot',
                        'awsize',
                        'awqos',
                        'awid',
                        'awregion',
                        'wvalid',
                        'wready',
                        'wlast',
                        'wstrb',
                        'wdata',
                        'wid',
                        'bvalid',
                        'bready',
                        'bresp',
                        'bid',
                    ]
                    ibus_ios_all = ibus.get_ios("ibus_axi")
                    subsignals = []
                    for s in ibus_ios_all[0]:
                        if type(s) is Subsignal:
                            if s.name not in suppress:
                                subsignals += [s]
                        else:
                            subsignals += [s]
                    subsignals = tuple(subsignals)
                    ibus_ios = [subsignals]

                #ibus_region =  SoCRegion(origin=self.mem_map["reram"], size=3 * 1024 * 1024, cached=True)
                #self.bus.add_slave(name="ibus", slave=ibus, region=ibus_region)
                platform.add_extension(ibus_ios)
                ibus_pads = platform.request("ibus_axi")
                self.comb += ibus.connect_to_pads(ibus_pads, mode="master")
            elif 'dbus' in mem_bus:
                dbus = mem_bus[1]
                #dbus_region =  SoCRegion(origin=self.mem_map["sram"], size=2 * 1024 * 1024, cached=True)
                #self.bus.add_slave(name="dbus", slave=dbus, region=dbus_region)
                platform.add_extension(dbus.get_ios("dbus_axi"))
                dbus_pads = platform.request("dbus_axi")
                self.comb += dbus.connect_to_pads(dbus_pads, mode="master")
            elif 'pbus' in mem_bus:
                p_bus = mem_bus[1]
                platform.add_extension(p_bus.get_ios("p_axi"))
                p_pads = platform.request("p_axi")
                self.comb += p_bus.connect_to_pads(p_pads, mode="master")
            else:
                print("Unhandled AXI bus from CPU core: {}".format(mem_bus))

        # Debug ------------------------------------------------------------------------------------
        platform.add_extension(get_debug_ios())
        jtag_pads = platform.request("jtag")
        self.cpu.add_jtag(jtag_pads)

        # Self test breakout -----------------------------------------------------------------------
        cmbist = platform.request("cmbist")
        cmatpg = platform.request("cmatpg")
        vexsramtrm = platform.request("vexsramtrm")
        self.comb += [
            self.cpu.cmbist.eq(cmbist),
            self.cpu.cmatpg.eq(cmatpg),
            self.cpu.vexsramtrm.eq(vexsramtrm),
        ]

        # CoreUser computation ---------------------------------------------------------------------
        if coreuser_compression:
            self.submodules.coreuser = CoreUser(self.cpu, platform.request("coreuser_vex"))
            self.comb += [
                self.coreuser.cmbist.eq(cmbist),
                self.coreuser.cmatpg.eq(cmatpg),
                self.coreuser.vexsramtrm.eq(vexsramtrm),
            ]
        else:
            self.submodules.coreuser = CoreUserLite(
                self.cpu,
                platform.request("coreuser_vex"),
                platform.request("vex_mm"),
                platform.request("default_user"),
                platform.request("default_mm"),
            )

        # WFI breakout -----------------------------------------------------------------------------
        sleep_req = platform.request("sleep_req")
        cpu_int_active = Signal()
        self.sync.always_on += cpu_int_active.eq(self.cpu.interrupt == Cat(
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0))
        axi_active = Signal()
        ibus_r_active = Signal()
        dbus_r_active = Signal()
        dbus_w_active = Signal()
        pbus_r_active = Signal()
        pbus_w_active = Signal()
        AXI_WFI_TIMEOUT=64
        active_timeout = Signal(max=AXI_WFI_TIMEOUT+1)
        self.sync += [
            If(ibus.ar.valid,
               ibus_r_active.eq(1)
            ).Elif(ibus.r.valid & ibus.r.ready & ibus.r.last,
               ibus_r_active.eq(0)
            ),
            If(dbus.ar.valid,
               dbus_r_active.eq(1)
            ).Elif(dbus.r.valid & dbus.r.ready & dbus.r.last,
               dbus_r_active.eq(0)
            ),
            If(dbus.aw.valid,
               dbus_w_active.eq(1)
            ).Elif(dbus.b.valid & dbus.b.ready,
               dbus_w_active.eq(0)
            ),
            If(p_bus.ar.valid,
               pbus_r_active.eq(1)
            ).Elif(p_bus.r.valid & p_bus.r.ready, # PBUS does not support bursts
               pbus_r_active.eq(0)
            ),
            If(p_bus.aw.valid,
               pbus_w_active.eq(1)
            ).Elif(p_bus.b.valid & p_bus.b.ready,
               pbus_w_active.eq(0)
            ),
            If(axi_active,
               active_timeout.eq(AXI_WFI_TIMEOUT)
            ).Elif(active_timeout > 0,
                active_timeout.eq(active_timeout - 1)
            ).Else(
                active_timeout.eq(active_timeout)
            )
        ]
        self.comb += axi_active.eq(
            ibus.ar.valid | ibus.r.valid
            | dbus.aw.valid | dbus.w.valid | dbus.b.valid | dbus.ar.valid | dbus.r.valid
            | p_bus.aw.valid | p_bus.w.valid | p_bus.b.valid | p_bus.ar.valid | p_bus.r.valid
            | ibus_r_active | dbus_r_active | dbus_w_active | pbus_r_active | pbus_w_active
        )
        # TODO: detect when aw -> b, and ar -> ar is pending...
        self.comb += sleep_req.eq(self.cpu.wfi_active & cpu_int_active & ~axi_active & (active_timeout == 0))

        # Interrupt Array --------------------------------------------------------------------------
        irqpins = platform.request("irqarray")
        pins = []
        for bank in range(IRQ_BANKS):
            pins += [getattr(irqpins, 'bank{}'.format(bank))]

        duped_pins, duped_names, ev_map = dupe_irqs(pins, self.comb)
        for bank in range(IRQ_BANKS):
            setattr(self.submodules, 'irqarray{}'.format(bank),
                    ClockDomainsRenamer({"sys":"always_on"})(IrqArray(bank, duped_pins[bank], duped_names[bank])))
            self.irq.add("irqarray{}".format(bank))
        for index, name in ev_map.items():
            self.add_constant(f'IFSUB_EV_{name}', index)

        # Ticktimer --------------------------------------------------------------------------------
        self.submodules.ticktimer = ClockDomainsRenamer({"sys":"always_on"})(TickTimer(1000, sys_clk_freq))
        self.irq.add("ticktimer")

        # Deterministic timeout helper ---------------------------------------------------------------
        self.submodules.d11ctime = ClockDomainsRenamer({"sys":"always_on"})(D11cTime(count=400_000, sys_clk_freq=sys_clk_freq))

        # Suspend/resume ---------------------------------------------------------------------------
        self.submodules.susres = ClockDomainsRenamer({"sys":"always_on"})(SusRes(bits=64))
        self.irq.add("susres")
        # wire up signals that cross from the ticktimer's CSR space to the susres CSR space. Allows for virtual memory process isolation
        # between the ticktimer and the suspend resume server, while allowing for cycle-accurate timing on suspend and resume.
        self.comb += [
            self.susres.time.status.eq(self.ticktimer.timer),
            self.susres.status.fields.paused.eq(self.ticktimer.paused),
            self.ticktimer.resume_time.eq(self.susres.resume_time.storage),
            self.ticktimer.pause.eq(self.susres.control.fields.pause),
            self.ticktimer.load.eq(self.susres.control.fields.load),
        ]

        # Mailbox ----------------------------------------------------------------------------------
        self.submodules.mailbox = Mailbox(fifo_depth=1024)
        self.irq.add("mailbox")
        self.comb += [
            self.mailbox.cmatpg.eq(cmatpg),
            self.mailbox.cmbist.eq(cmbist),
            self.mailbox.vexsramtrm.eq(vexsramtrm),
        ]

        # Mailbox Thin Client ----------------------------------------------------------------------
        self.submodules.mb_client = MailboxClient()
        self.irq.add("mb_client")

        # Cross-wire the mailbox and its client
        loopback = Signal()
        self.comb += loopback.eq(self.mailbox.loopback.fields.loopback)

        w_dat = Signal(32)
        w_valid = Signal()
        w_ready = Signal()
        w_done = Signal()

        r_dat = Signal(32)
        r_valid = Signal()
        r_ready = Signal()
        r_done = Signal()

        w_abort = Signal()
        r_abort = Signal()

        mbox_ext = platform.request("mbox")

        self.comb += [
            self.mailbox.reset_n.eq(~ResetSignal()),
            w_dat.eq(self.mailbox.w_dat),
            w_valid.eq(self.mailbox.w_valid),
            w_done.eq(self.mailbox.w_done),
            self.mailbox.w_ready.eq(w_ready),

            self.mailbox.r_dat.eq(r_dat),
            self.mailbox.r_valid.eq(r_valid),
            self.mailbox.r_done.eq(r_done),
            r_ready.eq(self.mailbox.r_ready),

            self.mailbox.r_abort.eq(r_abort),
            w_abort.eq(self.mailbox.w_abort),

            If(loopback,
                self.mb_client.reset_n.eq(~ResetSignal()),
                r_dat.eq(self.mb_client.w_dat),
                r_valid.eq(self.mb_client.w_valid),
                r_done.eq(self.mb_client.w_done),
                w_ready.eq(self.mb_client.r_ready),
                r_abort.eq(self.mb_client.w_abort),
            ).Else(
                r_dat.eq(mbox_ext.w_dat),
                r_valid.eq(mbox_ext.w_valid),
                r_done.eq(mbox_ext.w_done),
                w_ready.eq(mbox_ext.r_ready),
                r_abort.eq(mbox_ext.w_abort),
            ),
            self.mb_client.w_ready.eq(r_ready),
            self.mb_client.r_dat.eq(w_dat),
            self.mb_client.r_valid.eq(w_valid),
            self.mb_client.r_done.eq(w_done),
            self.mb_client.r_abort.eq(w_abort),

            mbox_ext.w_ready.eq(r_ready),
            mbox_ext.r_dat.eq(w_dat),
            mbox_ext.r_valid.eq(w_valid),
            mbox_ext.r_done.eq(w_done),
            mbox_ext.r_abort.eq(w_abort),
        ]

        # CSR bus test loopback register -----------------------------------------------------------
        self.submodules.csrtest = CsrTest()
        self.comb += [
            self.platform.request("test").eq(self.csrtest.csr_wtest.storage)
        ]

        # Legacy interrupt manager -----------------------------------------------------------------
        self.legacy_int = VexLegacyInt(self.cpu.m_ext, self.cpu.s_ext)
        self.comb += [
            self.legacy_int.interrupts.eq(self.cpu.interrupt)
        ]

# Build --------------------------------------------------------------------------------------------
def main():
    # Arguments.
    from litex.soc.integration.soc import LiteXSoCArgumentParser
    parser = LiteXSoCArgumentParser(description="LiteX standalone SoC generator")
    target_group = parser.add_argument_group(title="Generator options")
    target_group.add_argument("--name",          default="cram_vexii", help="SoC Name.")
    target_group.add_argument("--build",         action="store_true", help="Build SoC.")
    target_group.add_argument("--sys-clk-freq",  default=int(800e6),   help="System clock frequency.")
    parser.add_argument(
        "-D", "--document-only", default=False, action="store_true", help="dummy arg to be consistent with cram_soc"
    )
    parser.add_argument(
        "-S", "--sim", default=False, action="store_true", help="Run simulation. Changes `comb` description style slightly for improved simulator compatibility."
    )
    args = parser.parse_args()

    # TODO: add SBT run to generate core whenever this is invoked, to ensure that docs are
    # consistent with the source code.

    # Generate the SoC
    if args.sim:
        sys_clk_freq = 100e6
    else:
        sys_clk_freq = args.sys_clk_freq
    soc = cramSoC(
        name         = args.name,
        sys_clk_freq = int(sys_clk_freq),
    )
    builder = Builder(soc, output_dir="build", csr_csv="build/csr.csv", csr_svd="build/software/core.svd",
        compile_software=False, compile_gateware=False)
    builder.software_packages=[] # necessary to bypass Meson dependency checks required by Litex libc
    # turn off regular_comb for simulation. Can't just use ~ because Python.
    if args.sim:
        rc=False
    else:
        rc=True
    vns = builder.build(build_name=args.name, run=False, regular_comb=rc)

    soc.do_exit(vns)
    lxsocdoc.generate_docs(
        soc, "build/documentation", note_pulses=True,
        sphinx_extensions=['sphinx_math_dollar', 'sphinx.ext.mathjax'],
        project_name="Cramium SoC (RISC-V Core Complex)",
        author="Cramium, Inc.",
            sphinx_extra_config=r"""
mathjax_config = {
   'tex2jax': {
       'inlineMath': [ ["\\(","\\)"] ],
       'displayMath': [["\\[","\\]"] ],
   },
}""")
    print("LIES! The command is `sphinx-build -M html build/gateware/build/documentation/ build/gateware/build/documentation/_build`")

if __name__ == "__main__":
    main()
