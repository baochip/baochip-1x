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
from random import randrange

from migen import *
from migen.genlib.sort import *

from migen.test.support import SimCase


class BitonicCase(SimCase, unittest.TestCase):
    class TestBench(Module):
        def __init__(self):
            self.submodules.dut = BitonicSort(8, 4, ascending=True)

    def test_sizes(self):
        self.assertEqual(len(self.tb.dut.i), 8)
        self.assertEqual(len(self.tb.dut.o), 8)
        for i in range(8):
            self.assertEqual(len(self.tb.dut.i[i]), 4)
            self.assertEqual(len(self.tb.dut.o[i]), 4)

    def test_sort(self):
        def gen():
            for repeat in range(20):
                for i in self.tb.dut.i:
                    yield i.eq(randrange(1<<len(i)))
                yield
                self.assertEqual(sorted((yield self.tb.dut.i)),
                                 (yield self.tb.dut.o))
        self.run_with(gen())
