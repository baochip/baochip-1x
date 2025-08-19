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


def _same_slices(a, b):
    return a.value is b.value and a.start == b.start and a.stop == b.stop


class SignalSizeCase(unittest.TestCase):
    def setUp(self):
        self.i = C(0xaa)
        self.j = C(-127)
        self.s = Signal((13, True))

    def test_len(self):
        self.assertEqual(len(self.s), 13)
        self.assertEqual(len(self.i), 8)
        self.assertEqual(len(self.j), 8)
