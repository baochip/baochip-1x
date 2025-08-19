# (c) Copyright 2024 CrossBar, Inc.
#
# SPDX-FileCopyrightText: 2024 CrossBar, Inc.
# SPDX-License-Identifier: CERN-OHL-W-2.0
#
# This documentation and source code is licensed under the CERN Open Hardware
# License Version 2 – Weakly Reciprocal (http://ohwr.org/cernohl; the
# “License”). Your use of any source code herein is governed by the License.
#
# You may redistribute and modify this documentation under the terms of the
# License. This documentation and source code is distributed WITHOUT ANY EXPRESS
# OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
# PARTICULAR PURPOSE. Please see the License for the specific language governing
# permissions and limitations under the License.

import unittest
from itertools import count

from migen import *
from migen.genlib.fifo import SyncFIFO

from migen.test.support import SimCase


class SyncFIFOCase(SimCase, unittest.TestCase):
    class TestBench(Module):
        def __init__(self):
            self.submodules.dut = SyncFIFO(64, 2)

            self.sync += [
                If(self.dut.we & self.dut.writable,
                    self.dut.din[:32].eq(self.dut.din[:32] + 1),
                    self.dut.din[32:].eq(self.dut.din[32:] + 2)
                )
            ]

    def test_run_sequence(self):
        seq = list(range(20))
        def gen():
            for cycle in count():
                # fire re and we at "random"
                yield self.tb.dut.we.eq(cycle % 2 == 0)
                yield self.tb.dut.re.eq(cycle % 3 == 0)
                # the output if valid must be correct
                if (yield self.tb.dut.readable) and (yield self.tb.dut.re):
                    try:
                        i = seq.pop(0)
                    except IndexError:
                        break
                    self.assertEqual((yield self.tb.dut.dout[:32]), i)
                    self.assertEqual((yield self.tb.dut.dout[32:]), i*2)
                yield
        self.run_with(gen())

    def test_replace(self):
        seq = [x for x in range(20) if x % 5]
        def gen():
            for cycle in count():
                yield self.tb.dut.we.eq(cycle % 2 == 0)
                yield self.tb.dut.re.eq(cycle % 7 == 0)
                yield self.tb.dut.replace.eq(
                    (yield self.tb.dut.din[:32]) % 5 == 1)
                if (yield self.tb.dut.readable) and (yield self.tb.dut.re):
                    try:
                        i = seq.pop(0)
                    except IndexError:
                        break
                    self.assertEqual((yield self.tb.dut.dout[:32]), i)
                    self.assertEqual((yield self.tb.dut.dout[32:]), i*2)
                yield
        self.run_with(gen())
