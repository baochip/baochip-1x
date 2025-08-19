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

from migen.fhdl.structure import *
from migen.fhdl.specials import Special


__all__ = ["AsyncResetSynchronizer"]


class AsyncResetSynchronizer(Special):
    def __init__(self, cd, async_reset):
        Special.__init__(self)
        self.cd = cd
        self.async_reset = wrap(async_reset)

    def iter_expressions(self):
        yield self.cd, "clk", SPECIAL_INPUT
        yield self.cd, "rst", SPECIAL_OUTPUT
        yield self, "async_reset", SPECIAL_INPUT

    @staticmethod
    def lower(dr):
        raise NotImplementedError("Attempted to use a reset synchronizer, but platform does not support them")
