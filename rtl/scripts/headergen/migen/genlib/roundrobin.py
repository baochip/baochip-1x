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
from migen.fhdl.module import Module


(SP_WITHDRAW, SP_CE) = range(2)


class RoundRobin(Module):
    def __init__(self, n, switch_policy=SP_WITHDRAW):
        self.request = Signal(n)
        self.grant = Signal(max=max(2, n))
        self.switch_policy = switch_policy
        if self.switch_policy == SP_CE:
            self.ce = Signal()

        ###

        if n > 1:
            cases = {}
            for i in range(n):
                switch = []
                for j in reversed(range(i+1, i+n)):
                    t = j % n
                    switch = [
                        If(self.request[t],
                            self.grant.eq(t)
                        ).Else(
                            *switch
                        )
                    ]
                if self.switch_policy == SP_WITHDRAW:
                    case = [If(~self.request[i], *switch)]
                else:
                    case = switch
                cases[i] = case
            statement = Case(self.grant, cases)
            if self.switch_policy == SP_CE:
                statement = If(self.ce, statement)
            self.sync += statement
        else:
            self.comb += self.grant.eq(0)
