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
import os.path
import sys
import subprocess


def _make_test_method(name, foldername):
    def test_method(self):
        filename = name + ".py"
        example_path = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", "..", "examples"))
        filepath = os.path.join(example_path, foldername, filename)
        subprocess.check_call(
            [sys.executable, filepath],
            stdout=subprocess.DEVNULL
        )

    return test_method


class TestExamplesSim(unittest.TestCase):
    pass

for name in ("basic1",
              "basic2",
              # skip "fir" as it depends on SciPy
              # "fir",
              "memory"):
    setattr(TestExamplesSim, "test_" + name,
            _make_test_method(name, "sim"))


class TestExamplesBasic(unittest.TestCase):
    pass

for name in ("arrays",
              "fsm",
              "graycounter",
              "local_cd",
              "memory",
              "namer",
              "psync",
              "record",
              "reslice",
              "tristate",
              "two_dividers"):
    setattr(TestExamplesBasic, "test_" + name,
            _make_test_method(name, "basic"))

