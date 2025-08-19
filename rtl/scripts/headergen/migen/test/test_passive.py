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


class PassiveCase(unittest.TestCase):
    def test_terminates_correctly(self):
        n = 5

        count = 0
        @passive
        def counter():
            nonlocal count
            while True:
                yield
                count += 1

        def terminator():
            for i in range(n):
                yield

        run_simulation(Module(), [counter(), terminator()])
        self.assertEqual(count, n)
