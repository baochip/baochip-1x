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

#
# This file is part of LiteX.
#
# Copyright (c) 2018-2022 Florent Kermarrec <florent@enjoy-digital.fr>
# Copyright (c) 2020 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: BSD-2-Clause

"""AXI4-Full/Lite support for LiteX"""

from migen import *

from litex.soc.interconnect.axi.axi_common import *
from litex.soc.interconnect.axi.axi_lite import *
from litex.soc.interconnect.axi.axi_full_to_axi_lite import *
from litex.soc.interconnect.axi.axi_lite_to_wishbone import *

# AXI to Wishbone ----------------------------------------------------------------------------------

class AXI2Wishbone(Module):
    def __init__(self, axi, wishbone, base_address=0x00000000):
        axi_lite          = AXILiteInterface(axi.data_width, axi.address_width)
        axi2axi_lite      = AXI2AXILite(axi, axi_lite)
        axi_lite2wishbone = AXILite2Wishbone(axi_lite, wishbone, base_address)
        self.submodules += axi2axi_lite, axi_lite2wishbone

# Wishbone to AXI ----------------------------------------------------------------------------------

class Wishbone2AXI(Module):
    def __init__(self, wishbone, axi, base_address=0x00000000):
        axi_lite          = AXILiteInterface(axi.data_width, axi.address_width)
        wishbone2axi_lite = Wishbone2AXILite(wishbone, axi_lite, base_address)
        axi_lite2axi      = AXILite2AXI(axi_lite, axi)
        self.submodules += wishbone2axi_lite, axi_lite2axi
