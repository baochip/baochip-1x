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

from migen import *
from migen.test.support import SimCase


class SignedCase(SimCase, unittest.TestCase):
    class TestBench(Module):
        def __init__(self):
            self.a = Signal((3, True))
            self.b = Signal((4, True))
            comps = [
                lambda p, q: p > q,
                lambda p, q: p >= q,
                lambda p, q: p < q,
                lambda p, q: p <= q,
                lambda p, q: p == q,
                lambda p, q: p != q,
            ]
            self.vals = []
            for asign in 1, -1:
                for bsign in 1, -1:
                    for f in comps:
                        r = Signal()
                        r0 = f(asign*self.a, bsign*self.b)
                        self.comb += r.eq(r0)
                        self.vals.append((asign, bsign, f, r, r0.op))

    def test_comparisons(self):
        def gen():
            for i in range(-4, 4):
                yield self.tb.a.eq(i)
                yield self.tb.b.eq(i)
                a = yield self.tb.a
                b = yield self.tb.b
                for asign, bsign, f, r, op in self.tb.vals:
                    r, r0 = (yield r), f(asign*a, bsign*b)
                    self.assertEqual(r, int(r0),
                            "got {}, want {}*{} {} {}*{} = {}".format(
                                r, asign, a, op, bsign, b, r0))
                yield
        self.run_with(gen())
