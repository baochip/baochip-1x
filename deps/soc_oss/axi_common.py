#
# This file is part of LiteX-Verilog-AXI-Test
#
# Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

import sys
import logging

from enum import IntEnum

from migen import *

logging.basicConfig(level=logging.INFO)

# Helpers ------------------------------------------------------------------------------------------

class Open(Signal): pass

def colorer(s, color="bright"):
    header  = {
        "bright": "\x1b[1m",
        "green":  "\x1b[32m",
        "cyan":   "\x1b[36m",
        "red":    "\x1b[31m",
        "yellow": "\x1b[33m",
        "underline": "\x1b[4m"}[color]
    trailer = "\x1b[0m"
    return header + str(s) + trailer

# AXI Register Type --------------------------------------------------------------------------------

class AXIRegister(IntEnum):
    BYPASS        = 0
    SIMPLE_BUFFER = 1
    SKID_BUFFER   = 2

# AXI Error ----------------------------------------------------------------------------------------

class AXIError(Exception):
    def __init__(self):
        sys.stderr = None # Error already described, avoid traceback/exception.

# AXI Debug ----------------------------------------------------------------------------------------

class AXIAWDebug(Module):
    def __init__(self, axi, name=""):
        sync = getattr(self.sync, axi.clock_domain)
        sync += If(axi.aw.valid & axi.aw.ready,
            Display(f"AXI AW {name}: Addr: 0x%08x, Burst: %d, Len: %d",
                axi.aw.addr,
                axi.aw.burst,
                axi.aw.len
            ),
        )

class AXIWDebug(Module):
    def __init__(self, axi, name=""):
        sync = getattr(self.sync, axi.clock_domain)
        sync += If(axi.w.valid & axi.w.ready,
            Display(f"AXI W {name}: Data: 0x%x, Strb: %x, Last: %d",
                axi.w.data,
                axi.w.strb,
                axi.w.last
            ),
        )

class AXIARDebug(Module):
    def __init__(self, axi, name=""):
        sync = getattr(self.sync, axi.clock_domain)
        sync += If(axi.ar.valid & axi.ar.ready,
            Display(f"AXI AR {name}: Addr: 0x%08x, Burst: %d, Len: %d",
                axi.ar.addr,
                axi.ar.burst,
                axi.ar.len
            ),
        )

class AXIRDebug(Module):
    def __init__(self, axi, name=""):
        sync = getattr(self.sync, axi.clock_domain)
        sync += If(axi.r.valid & axi.r.ready,
            Display(f"AXI R {name}: Data: 0x%x, Last: %d",
                axi.r.data,
                axi.r.last
            ),
        )
