#!/usr/bin/env python3
# (c) Copyright 2025 Baochip, Inc.
#
# SPDX-FileCopyrightText: 2025 Baochip, Inc.
# SPDX-License-Identifier: BSD-2-Clause
#
# You may redistribute and modify this documentation under the terms of the
# License. This documentation and source code is distributed WITHOUT ANY EXPRESS
# OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
# PARTICULAR PURPOSE. Please see the License for the specific language governing
# permissions and limitations under the License.

#
# Incorporates CSR, header, and SVD generators from LiteX with the following copyrights:
#
# This file is Copyright (c) 2013-2014 Sebastien Bourdeauducq <sb@m-labs.hk>
# This file is Copyright (c) 2014-2019 Florent Kermarrec <florent@enjoy-digital.fr>
# This file is Copyright (c) 2018 Dolu1990 <charles.papon.90@gmail.com>
# This file is Copyright (c) 2019 Gabriel L. Somlo <gsomlo@gmail.com>
# This file is Copyright (c) 2018 Jean-François Nguyen <jf@lambdaconcept.fr>
# This file is Copyright (c) 2019 Antmicro <www.antmicro.com>
# This file is Copyright (c) 2013 Robert Jordens <jordens@gmail.com>
# This file is Copyright (c) 2018 Sean Cross <sean@xobs.io>
# This file is Copyright (c) 2018 Sergiusz Bazanski <q3k@q3k.org>
# This file is Copyright (c) 2018-2016 Tim 'mithro' Ansell <me@mith.ro>
# This file is Copyright (c) 2015 whitequark <whitequark@whitequark.org>
# This file is Copyright (c) 2018 William D. Jones <thor0505@comcast.net>
# This file is Copyright (c) 2020 Piotr Esden-Tempski <piotr@esden.net>
# This file is Copyright (c) 2022 Franck Jullien <franck.jullien@collshade.fr>
# This file is Copyright (c) 2022 Cramium Labs, Inc.
# This file is Copyright (c) 2025 Baochip, Inc.
#
# SPDX-License-Identifier: BSD-2-Clause

from pathlib import Path
import argparse
import textwrap
import datetime
import time
import logging
from math import log2
import sys
import subprocess
import os
import pathlib
import random

from litex.soc.doc.csr import DocumentedCSRRegion
from litex.soc.interconnect.csr import _CompoundCSR, CSRStorage, CSRStatus, CSRField

from litex.soc.doc.module import gather_submodules, ModuleNotDocumented, DocumentedModule, DocumentedInterrupts
from litex.soc.doc.rst import reflow
from litex.soc.doc import default_sphinx_configuration

import re
import ast
import operator as op
import pprint
from math import log2
import shutil

URL_PREFIX='file:///F:/code/cram-nto/'
# SVD patch for PL230 DMA

def patch_pl230(svd_string, pl230_base_address):
    pl230_dma_svd = f"""
    <peripheral>
      <name>PL230</name>
      <description>PL230 DMA Controller Core</description>
      <baseAddress>{pl230_base_address}</baseAddress>
      <addressBlock>
        <offset>0x0</offset>
        <size>0x40</size>
        <usage>registers</usage>
      </addressBlock>
      <addressBlock>
        <offset>0x40</offset>
        <size>0xc</size>
        <usage>reserved</usage>
      </addressBlock>
      <addressBlock>
        <offset>0x4c</offset>
        <size>0x4</size>
        <usage>registers</usage>
      </addressBlock>
      <registers>
        <register>
          <name>STATUS</name>
          <description>DMA Status Register</description>
          <addressOffset>0x00</addressOffset>
          <size>32</size>
          <access>read-only</access>
          <resetValue>0x101f0000</resetValue>
          <resetMask>0xffffff0f</resetMask>
          <fields>
            <field>
                <name>TEST_STATUS</name>
                <description>Test status configuration</description>
                <bitOffset>28</bitOffset>
                <bitWidth>4</bitWidth>
                <access>read-only</access>
            </field>
            <field>
                <name>CHNLS_MINUS1</name>
                <description>Number of available DMA channels minus 1</description>
                <bitOffset>16</bitOffset>
                <bitWidth>5</bitWidth>
                <access>read-only</access>
            </field>
            <field>
                <name>STATE</name>
                <description>Current state of the control machine</description>
                <bitOffset>4</bitOffset>
                <bitWidth>4</bitWidth>
                <access>read-only</access>
            </field>
            <field>
              <name>MASTER_ENABLE</name>
              <description>Master enable status</description>
              <bitOffset>0</bitOffset>
              <bitWidth>1</bitWidth>
              <access>read-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CFG</name>
          <description>DMA Configuration Register</description>
          <addressOffset>0x04</addressOffset>
          <size>32</size>
          <access>write-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0x00000000</resetMask>
          <fields>
            <field>
                <name>CHNL_PROT_CTRL</name>
                <description>Set AHB-Lite configuration</description>
                <bitOffset>5</bitOffset>
                <bitWidth>3</bitWidth>
                <access>read-only</access>
            </field>
            <field>
              <name>MASTER_ENABLE</name>
              <description>MASTER_ENABLE</description>
              <bitOffset>0</bitOffset>
              <bitWidth>1</bitWidth>
              <access>write-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CTRLBASEPTR</name>
          <description>DMA Control Data Base Pointer Register</description>
          <addressOffset>0x08</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>CTRL_BASE_PTR</name>
              <description>CTRL_BASE_PTR</description>
              <bitOffset>8</bitOffset>
              <bitWidth>24</bitWidth>
              <access>read-write</access>
            </field>
          </fields>
        </register>
        <register>
          <name>ALTCTRLBASEPTR</name>
          <description>DMA Channel Alternate Control Data Base Pointer Register</description>
          <addressOffset>0x0C</addressOffset>
          <size>32</size>
          <access>read-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>ALT_CTRL_BASE_PTR</name>
              <description>ALT_CTRL_BASE_PTR</description>
              <bitOffset>0</bitOffset>
              <bitWidth>32</bitWidth>
              <access>read-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>DMA_WAITONREQ_STATUS</name>
          <description>Channel wait on request status</description>
          <addressOffset>0x10</addressOffset>
          <size>32</size>
          <access>read-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>DMA_WAITONREQ_STATUS</name>
              <description>Wait on request status, one bit per channel</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>read-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLSWREQUEST</name>
          <description>DMA Channel Software Request Register</description>
          <addressOffset>0x14</addressOffset>
          <size>32</size>
          <access>write-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0x00000000</resetMask>
          <fields>
            <field>
              <name>CHNL_SW_REQUEST</name>
              <description>CHNL_SW_REQUEST</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>write-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLUSEBURSTSET</name>
          <description>DMA Channel Useburst Set Register</description>
          <addressOffset>0x18</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>CHNL_USEBURST_SET</name>
              <description>CHNL_USEBURST_SET</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>read-write</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLUSEBURSTCLR</name>
          <description>DMA Channel Useburst Clear Register</description>
          <addressOffset>0x1C</addressOffset>
          <size>32</size>
          <access>write-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0x00000000</resetMask>
          <fields>
            <field>
              <name>CHNL_USEBURST_CLR</name>
              <description>CHNL_USEBURST_CLR</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>write-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLREQMASKSET</name>
          <description>DMA Channel Request Mask Set Register</description>
          <addressOffset>0x20</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>CHNL_REQ_MASK_SET</name>
              <description>CHNL_REQ_MASK_SET</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>read-write</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLREQMASKCLR</name>
          <description>DMA Channel Request Mask Clear Register</description>
          <addressOffset>0x24</addressOffset>
          <size>32</size>
          <access>write-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0x00000000</resetMask>
          <fields>
            <field>
              <name>CHNL_REQ_MASK_CLR</name>
              <description>CHNL_REQ_MASK_CLR</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>write-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLENABLESET</name>
          <description>DMA Channel Enable Set Register</description>
          <addressOffset>0x28</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>CHNL_ENABLE_SET</name>
              <description>CHNL_ENABLE_SET</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>read-write</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLENABLECLR</name>
          <description>DMA Channel Enable Clear Register</description>
          <addressOffset>0x2C</addressOffset>
          <size>32</size>
          <access>write-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0x00000000</resetMask>
          <fields>
            <field>
              <name>CHNL_ENABLE_CLR</name>
              <description>CHNL_ENABLE_CLR</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>write-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLPRIALTSET</name>
          <description>DMA Channel Primary-Alternate Set Register</description>
          <addressOffset>0x30</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>CHNL_PRI_ALT_SET</name>
              <description>CHNL_PRI_ALT_SET</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>read-write</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLPRIALTCLR</name>
          <description>DMA Channel Primary-Alternate Clear Register</description>
          <addressOffset>0x34</addressOffset>
          <size>32</size>
          <access>write-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0x00000000</resetMask>
          <fields>
            <field>
              <name>CHNL_PRI_ALT_CLR</name>
              <description>CHNL_PRI_ALT_CLR</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>write-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLPRIORITYSET</name>
          <description>DMA Channel Priority Set Register</description>
          <addressOffset>0x38</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>CHNL_PRIORITY_SET</name>
              <description>CHNL_PRIORITY_SET</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>read-write</access>
            </field>
          </fields>
        </register>
        <register>
          <name>CHNLPRIORITYCLR</name>
          <description>DMA Channel Priority Clear Register</description>
          <addressOffset>0x3C</addressOffset>
          <size>32</size>
          <access>write-only</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0x00000000</resetMask>
          <fields>
            <field>
              <name>CHNL_PRIORITY_CLR</name>
              <description>CHNL_PRIORITY_CLR</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>write-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>ERRCLR</name>
          <description>DMA Bus Error Clear Register</description>
          <addressOffset>0x4C</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>ERR_CLR</name>
              <description>ERR_CLR</description>
              <bitOffset>0</bitOffset>
              <bitWidth>1</bitWidth>
              <access>read-write</access>
            </field>
          </fields>
        </register>
        <register>
          <name>PERIPH_ID_0</name>
          <description>Peripheral ID byte 0</description>
          <addressOffset>0xFE0</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>PART_NUMBER_LSB</name>
              <description>Identifies the part number</description>
              <bitOffset>0</bitOffset>
              <bitWidth>8</bitWidth>
              <access>read-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>PERIPH_ID_1</name>
          <description>Peripheral ID byte 1</description>
          <addressOffset>0xFE4</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>PART_NUMBER_MSB</name>
              <description>Identifies the part number</description>
              <bitOffset>0</bitOffset>
              <bitWidth>4</bitWidth>
              <access>read-only</access>
            </field>
            <field>
              <name>JEP106_LSB</name>
              <description>Designer ID LSB</description>
              <bitOffset>4</bitOffset>
              <bitWidth>3</bitWidth>
              <access>read-only</access>
            </field>
          </fields>
        </register>
        <register>
          <name>PERIPH_ID_2</name>
          <description>Peripheral ID byte 2</description>
          <addressOffset>0xFE8</addressOffset>
          <size>32</size>
          <access>read-write</access>
          <resetValue>0x00000000</resetValue>
          <resetMask>0xffffffff</resetMask>
          <fields>
            <field>
              <name>JEP106_MSB</name>
              <description>Designer ID MSB</description>
              <bitOffset>0</bitOffset>
              <bitWidth>3</bitWidth>
              <access>read-only</access>
            </field>
            <field>
              <name>JEDEC_USED</name>
              <description>Identifies if JP106 ID code is used</description>
              <bitOffset>3</bitOffset>
              <bitWidth>1</bitWidth>
              <access>read-only</access>
            </field>
            <field>
              <name>REVISION</name>
              <description>Identifies revision number of peripheral</description>
              <bitOffset>4</bitOffset>
              <bitWidth>4</bitWidth>
              <access>read-only</access>
            </field>
          </fields>
        </register>
      </registers>
    </peripheral>
"""
    retfile = ""
    for line in svd_string.splitlines(keepends=True):
        if "peripherals" in line:
            retfile += line
            retfile += pl230_dma_svd
        else:
            retfile += line
    return retfile

# VENDORED CODE -- modifications off main branch exist specific to this application.
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

def log2_int(n, need_pow2=True):
    if n == 0:
        return 0
    r = (n - 1).bit_length()
    if need_pow2 and (1 << r) != n:
        raise ValueError("Not a power of 2")
    return r

class SoCCSRRegion:
    def __init__(self, origin, busword, obj):
        self.origin  = origin
        self.busword = busword
        self.obj     = obj

class SoCError(Exception):
    def __init__(self):
        sys.stderr = None # Error already described, avoid traceback/exception.

# SoCRegion ----------------------------------------------------------------------------------------

class SoCRegion:
    def __init__(self, origin=None, size=None, mode="rw", cached=True, linker=False, decode=True):
        self.logger    = logging.getLogger("SoCRegion")
        self.origin    = origin
        self.decode    = decode
        self.size      = size
        if size != 2**log2_int(size, False):
            self.logger.info("Region size {} internally from {} to {}.".format(
                colorer("rounded", color="cyan"),
                colorer("0x{:08x}".format(size)),
                colorer("0x{:08x}".format(2**log2_int(size, False)))))
        self.size_pow2 = 2**log2_int(size, False)
        self.mode      = mode
        self.cached    = cached
        self.linker    = linker

    def decoder(self, bus):
        origin = self.origin
        size   = self.size_pow2
        if (origin & (size - 1)) != 0:
            self.logger.error("Origin needs to be aligned on size:")
            self.logger.error(self)
            raise SoCError()
        if not self.decode or (origin == 0) and (size == 2**bus.address_width):
            return lambda a: True
        origin >>= int(log2(bus.data_width//8)) # bytes to words aligned.
        size   >>= int(log2(bus.data_width//8)) # bytes to words aligned.
        return lambda a: (a[log2_int(size):] == (origin >> log2_int(size)))

    def __str__(self):
        r = ""
        if self.origin is not None:
            r += "Origin: {}, ".format(colorer("0x{:08x}".format(self.origin)))
        if self.size is not None:
            r += "Size: {}, ".format(colorer("0x{:08x}".format(self.size)))
        r += "Mode: {}, ".format(colorer(self.mode.upper()))
        r += "Cached: {} ".format(colorer(self.cached))
        r += "Linker: {}".format(colorer(self.linker))
        return r

class SoCIORegion(SoCRegion): pass

def pad_first_line_if_necessary(s):
    if not isinstance(s, str):
        return s
    lines = s.split("\n")

    # If there aren't at least two lines, don't do anything
    if len(lines) < 2:
        return s

    # If the first line is blank, don't do anything
    if lines[0].strip() == "":
        return s

    # If the pading on line 1 is greater than line 2, pad line 1
    # and return the result
    line_0_padding = len(lines[0]) - len(lines[0].lstrip(' '))
    line_1_padding = len(lines[1]) - len(lines[1].lstrip(' '))
    if (line_1_padding > 0) and (line_1_padding > line_0_padding):
        lines[0] = " " * (line_1_padding - line_0_padding) + lines[0]
        return "\n".join(lines)
    return s

def reflow(s, width=80):
    """Reflow the jagged text that gets generated as part
    of this Python comment.

    In this comment, the first line would be indented relative
    to the rest.  Additionally, the width of this block would
    be limited to the original text width.

    To reflow text, break it along \n\n, then dedent and reflow
    each line individually.

    Finally, append it to a new string to be returned.
    """
    if not isinstance(s, str):
        return s
    out = []
    s = pad_first_line_if_necessary(s)
    for piece in textwrap.dedent(s).split("\n\n"):
        trimmed_piece = textwrap.fill(textwrap.dedent(piece).strip(), width=width)
        out.append(trimmed_piece)
    return "\n\n".join(out)


# C Export -----------------------------------------------------------------------------------------

def get_git_header():
    from litex.build.tools import get_litex_git_revision
    r = generated_banner("//")
    r += "#ifndef __GENERATED_GIT_H\n#define __GENERATED_GIT_H\n\n"
    r += f"#define LITEX_GIT_SHA1 \"{get_litex_git_revision()}\"\n"
    r += "#endif\n"
    return r

def get_mem_header(regions):
    r = generated_banner("//")
    r += "#ifndef __GENERATED_MEM_H\n#define __GENERATED_MEM_H\n\n"
    for name, region in regions.items():
        r += f"#ifndef {name.upper()}_BASE\n"
        r += f"#define {name.upper()}_BASE 0x{region.origin:08x}L\n"
        r += f"#define {name.upper()}_SIZE 0x{region.size:08x}\n"
        r += "#endif\n\n"

    r += "#ifndef MEM_REGIONS\n"
    r += "#define MEM_REGIONS \"";
    name_length = max([len(name) for name in regions.keys()])
    for name, region in regions.items():
        r += f"{name.upper()} {' '*(name_length-len(name))} 0x{region.origin:08x} 0x{region.size:x} \\n"
    r = r[:-2]
    r += "\"\n"
    r += "#endif\n"

    r += "#endif\n"
    return r

def get_soc_header(constants, with_access_functions=True):
    r = generated_banner("//")
    r += "#ifndef __GENERATED_SOC_H\n#define __GENERATED_SOC_H\n"
    funcs = ""

    for name, value in constants.items():
        if value is None:
            r += "#define "+name+"\n"
            continue
        if isinstance(value, str):
            value = "\"" + value + "\""
            ctype = "const char *"
        else:
            value = str(value)
            ctype = "int"
        r += "#define "+name+" "+value+"\n"
        if with_access_functions:
            funcs += "static inline "+ctype+" "+name.lower()+"_read(void) {\n"
            funcs += "\treturn "+value+";\n}\n"

    if with_access_functions:
        r += "\n#ifndef __ASSEMBLER__\n"
        r += funcs
        r += "#endif // !__ASSEMBLER__\n"

    r += "\n#endif\n"
    return r

def _get_csr_addr(csr_base, addr, with_csr_base_define=True):
    if with_csr_base_define:
        return f"(CSR_BASE + {hex(addr)}L)"
    else:
        return f"{hex(csr_base + addr)}L"

def _get_rw_functions_c(reg_name, reg_base, nwords, busword, alignment, read_only, csr_base, with_csr_base_define, with_access_functions):
    r = ""

    addr_str = f"CSR_{reg_name.upper()}_ADDR"
    size_str = f"CSR_{reg_name.upper()}_SIZE"
    r += f"#define {addr_str} {_get_csr_addr(csr_base, reg_base, with_csr_base_define)}\n"

    r += f"#define {size_str} {nwords}\n"

    size = nwords*busword//8
    if size > 8:
        # Downstream should select appropriate `csr_[rd|wr]_buf_uintX()` pair!
        return r
    elif size > 4:
        ctype = "uint64_t"
    elif size > 2:
        ctype = "uint32_t"
    elif size > 1:
        ctype = "uint16_t"
    else:
        ctype = "uint8_t"

    stride = alignment//8;
    if with_access_functions:
        r += f"static inline {ctype} {reg_name}_read(void) {{\n"
        if nwords > 1:
            r += f"\t{ctype} r = csr_read_simple({_get_csr_addr(csr_base, reg_base, with_csr_base_define)});\n"
            for sub in range(1, nwords):
                r += f"\tr <<= {busword};\n"
                r += f"\tr |= csr_read_simple({_get_csr_addr(csr_base, reg_base+sub*stride, with_csr_base_define)});\n"
            r += "\treturn r;\n}\n"
        else:
            r += f"\treturn csr_read_simple({_get_csr_addr(csr_base, reg_base, with_csr_base_define)});\n}}\n"

        if not read_only:
            r += f"static inline void {reg_name}_write({ctype} v) {{\n"
            for sub in range(nwords):
                shift = (nwords-sub-1)*busword
                if shift:
                    v_shift = "v >> {}".format(shift)
                else:
                    v_shift = "v"
                r += f"\tcsr_write_simple({v_shift}, {_get_csr_addr(csr_base, reg_base+sub*stride, with_csr_base_define)});\n"
            r += "}\n"
    return r

def get_litex_git_revision():
    # import litex
    # d = os.getcwd()
    # os.chdir(os.path.dirname(litex.__file__))
    try:
        r = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"],
                stderr=subprocess.DEVNULL)[:-1].decode("utf-8")
    except:
        r = "--------"
    # os.chdir(d)
    return r

def generated_banner(line_comment="//"):
    r = line_comment + "-"*80 + "\n"
    r += line_comment + " Auto-generated by daric_to_svd (derived from LiteX) ({}) on ".format(get_litex_git_revision())
    r += "{}\n".format(datetime.datetime.fromtimestamp(time.time()).strftime("%Y-%m-%d %H:%M:%S"))
    r += line_comment + "-"*80 + "\n"
    return r


def get_csr_header(regions, constants, csr_base=None, with_csr_base_define=True, with_access_functions=True):
    alignment = constants.get("CONFIG_CSR_ALIGNMENT", 32)
    r = generated_banner("//")
    if with_access_functions: # FIXME
        r += "#include <generated/soc.h>\n"
    r += "#ifndef __GENERATED_CSR_H\n#define __GENERATED_CSR_H\n"
    if with_access_functions:
        r += "#include <stdint.h>\n"
        r += "#include <system.h>\n"
        r += "#ifndef CSR_ACCESSORS_DEFINED\n"
        r += "#include <hw/common.h>\n"
        r += "#endif /* ! CSR_ACCESSORS_DEFINED */\n"
    csr_base = csr_base if csr_base is not None else regions[next(iter(regions))].origin
    if with_csr_base_define:
        r += "#ifndef CSR_BASE\n"
        r += f"#define CSR_BASE {hex(csr_base)}L\n"
        r += "#endif\n"
    for name, region in regions.items():
        origin = region.origin - csr_base
        r += "\n/* "+name+" */\n"
        r += f"#define CSR_{name.upper()}_BASE {_get_csr_addr(csr_base, origin, with_csr_base_define)}\n"
        #if not isinstance(region.obj, Memory):
        for csr in region.obj:
            nr = (csr.size + region.busword - 1)//region.busword
            if 'reserved' not in csr.name:
                r += _get_rw_functions_c(
                    reg_name              = name + "_" + csr.name,
                    reg_base              = origin,
                    nwords                = nr,
                    busword               = region.busword,
                    alignment             = alignment,
                    read_only             = getattr(csr, "read_only", False),
                    csr_base              = csr_base,
                    with_csr_base_define  = with_csr_base_define,
                    with_access_functions = with_access_functions,
                )
            origin += alignment//8*nr
            if hasattr(csr, "fields"):
                for field in csr.fields.fields:
                    offset = str(field.offset)
                    size = str(field.size)
                    r += f"#define CSR_{name.upper()}_{csr.name.upper()}_{field.name.upper()}_OFFSET {offset}\n"
                    r += f"#define CSR_{name.upper()}_{csr.name.upper()}_{field.name.upper()}_SIZE {size}\n"
                    if with_access_functions and csr.size <= 32: # FIXME: Implement extract/read functions for csr.size > 32-bit.
                        reg_name   = name + "_" + csr.name.lower()
                        field_name = reg_name + "_" + field.name.lower()
                        r += "static inline uint32_t " + field_name + "_extract(uint32_t oldword) {\n"
                        r += f"\tuint32_t mask = 0x{(1<<int(size))-1:x};\n"
                        r += "\treturn ( (oldword >> " + offset + ") & mask );\n}\n"
                        r += "static inline uint32_t " + field_name + "_read(void) {\n"
                        r += "\tuint32_t word = " + reg_name + "_read();\n"
                        r += "\treturn " + field_name + "_extract(word);\n"
                        r += "}\n"
                        if not getattr(csr, "read_only", False):
                            r += "static inline uint32_t " + field_name + "_replace(uint32_t oldword, uint32_t plain_value) {\n"
                            r += f"\tuint32_t mask = 0x{(1<<int(size))-1:x};\n"
                            r += "\treturn (oldword & (~(mask << " + offset + "))) | (mask & plain_value)<< " + offset + " ;\n}\n"
                            r += "static inline void " + field_name + "_write(uint32_t plain_value) {\n"
                            r += "\tuint32_t oldword = " + reg_name + "_read();\n"
                            r += "\tuint32_t newword = " + field_name + "_replace(oldword, plain_value);\n"
                            r += "\t" + reg_name + "_write(newword);\n"
                            r += "}\n"

    r += "\n#endif\n"
    return r

# SVD Export --------------------------------------------------------------------------------------

def get_csr_svd(soc, vendor="litex", name="soc", description=None):
    def sub_csr_bit_range(busword, csr, offset):
        nwords = (csr.size + busword - 1)//busword
        i = nwords - offset - 1
        nbits = min(csr.size - i*busword, busword) - 1
        name = (csr.name + str(i) if nwords > 1 else csr.name).upper()
        origin = i*busword
        return (origin, nbits, name)

    def print_svd_register(csr, csr_address, description, length, svd, suppress_reserved=True):
        if suppress_reserved and ('reserved' in csr.short_numbered_name.lower()):
            return
        svd.append('                <register>')
        svd.append('                    <name>{}</name>'.format(csr.short_numbered_name))
        if description is not None:
            svd.append('                    <description><![CDATA[{}]]></description>'.format(description))
        svd.append('                    <addressOffset>0x{:04x}</addressOffset>'.format(csr_address))
        svd.append('                    <resetValue>0x{:02x}</resetValue>'.format(csr.reset_value))
        svd.append('                    <size>{}</size>'.format(length))
        # svd.append('                    <access>{}</access>'.format(csr.access))  # 'access' is a lie: "read-only" registers can legitimately change state based on a write, and is in fact used to handle the "pending" field in events
        csr_address = csr_address + 4
        svd.append('                    <fields>')
        if hasattr(csr, "fields") and len(csr.fields) > 0:
            for field in csr.fields:
                svd.append('                        <field>')
                svd.append('                            <name>{}</name>'.format(field.name))
                svd.append('                            <msb>{}</msb>'.format(field.offset +
                                                                         field.size - 1))
                svd.append('                            <bitRange>[{}:{}]</bitRange>'.format(
                    field.offset + field.size - 1, field.offset))
                svd.append('                            <lsb>{}</lsb>'.format(field.offset))
                svd.append('                            <description><![CDATA[{}]]></description>'.format(
                    reflow(field.description)))
                svd.append('                        </field>')
        else:
            field_size = csr.size
            field_name = csr.short_name.lower()
            # Strip off "ev_" from eventmanager fields
            if field_name == "ev_enable":
                field_name = "enable"
            elif field_name == "ev_pending":
                field_name = "pending"
            elif field_name == "ev_status":
                field_name = "status"
            svd.append('                        <field>')
            svd.append('                            <name>{}</name>'.format(field_name))
            svd.append('                            <msb>{}</msb>'.format(field_size - 1))
            svd.append('                            <bitRange>[{}:{}]</bitRange>'.format(field_size - 1, 0))
            svd.append('                            <lsb>{}</lsb>'.format(0))
            svd.append('                        </field>')
        svd.append('                    </fields>')
        svd.append('                </register>')

    interrupts = {}
    for csr, irq in sorted(soc.irq.locs.items()):
        interrupts[csr] = irq

    documented_regions = []
    for region_name, region in soc.csr.regions.items():
        documented_regions.append(DocumentedCSRRegion(
            name           = region_name,
            region         = region,
            csr_data_width = soc.csr.data_width)
        )

    svd = []
    svd.append('<?xml version="1.0" encoding="utf-8"?>')
    svd.append('')
    svd.append('<device schemaVersion="1.1" xmlns:xs="http://www.w3.org/2001/XMLSchema-instance" xs:noNamespaceSchemaLocation="CMSIS-SVD.xsd" >')
    svd.append('    <vendor>{}</vendor>'.format(vendor))
    svd.append('    <name>{}</name>'.format(name.upper()))
    if description is not None:
        svd.append('    <description><![CDATA[{}]]></description>'.format(reflow(description)))
    else:
        fmt = "%Y-%m-%d %H:%M:%S"
        build_time = datetime.datetime.fromtimestamp(time.time()).strftime(fmt)
        svd.append('    <description><![CDATA[{}]]></description>'.format(reflow("Litex SoC " + build_time)))
    svd.append('')
    svd.append('    <addressUnitBits>8</addressUnitBits>')
    svd.append('    <width>32</width>')
    svd.append('    <size>32</size>')
    svd.append('    <access>read-write</access>')
    svd.append('    <resetValue>0x00000000</resetValue>') # this is not correct
    svd.append('    <resetMask>0xFFFFFFFF</resetMask>')
    svd.append('')
    svd.append('    <peripherals>')

    for region in documented_regions:
        csr_address = 0
        svd.append('        <peripheral>')
        svd.append('            <name>{}</name>'.format(region.name.upper()))
        svd.append('            <baseAddress>0x{:08X}</baseAddress>'.format(region.origin))
        svd.append('            <groupName>{}</groupName>'.format(region.name.upper()))
        if len(region.sections) > 0:
            svd.append('            <description><![CDATA[{}]]></description>'.format(
                reflow(region.sections[0].body())))
        svd.append('            <registers>')
        for csr in region.csrs:
            description = None
            if hasattr(csr, "description"):
                description = csr.description
            if isinstance(csr, _CompoundCSR) and len(csr.simple_csrs) > 1:
                is_first = True
                for i in range(len(csr.simple_csrs)):
                    (start, length, name) = sub_csr_bit_range(
                        region.busword, csr, i)
                    if length > 0:
                        bits_str = "Bits {}-{} of `{}`.".format(
                            start, start+length, csr.name)
                    else:
                        bits_str = "Bit {} of `{}`.".format(
                            start, csr.name)
                    if is_first:
                        if description is not None:
                            print_svd_register(
                                csr.simple_csrs[i], csr_address, bits_str + " " + description, length, svd)
                        else:
                            print_svd_register(
                                csr.simple_csrs[i], csr_address, bits_str, length, svd)
                        is_first = False
                    else:
                        print_svd_register(
                            csr.simple_csrs[i], csr_address, bits_str, length, svd)
                    csr_address = csr_address + 4
            else:
                length = ((csr.size + region.busword - 1) //
                            region.busword) * region.busword
                print_svd_register(
                    csr, csr_address, description, length, svd)
                csr_address = csr_address + 4
        svd.append('            </registers>')
        svd.append('            <addressBlock>')
        svd.append('                <offset>0</offset>')
        svd.append('                <size>0x{:x}</size>'.format(csr_address))
        svd.append('                <usage>registers</usage>')
        svd.append('            </addressBlock>')
        if region.name in interrupts:
            svd.append('            <interrupt>')
            svd.append('                <name>{}</name>'.format(region.name))
            svd.append('                <value>{}</value>'.format(interrupts[region.name]))
            svd.append('            </interrupt>')
        svd.append('        </peripheral>')
    svd.append('    </peripherals>')
    svd.append('    <vendorExtensions>')

    if len(soc.mem_regions) > 0:
        svd.append('        <memoryRegions>')
        for region_name, region in soc.mem_regions.items():
            svd.append('            <memoryRegion>')
            svd.append('                <name>{}</name>'.format(region_name.upper()))
            svd.append('                <baseAddress>0x{:08X}</baseAddress>'.format(region.origin))
            svd.append('                <size>0x{:08X}</size>'.format(region.size))
            svd.append('            </memoryRegion>')
        svd.append('        </memoryRegions>')

    svd.append('        <constants>')
    for name, value in soc.constants.items():
        svd.append('            <constant name="{}" value="{}" />'.format(name, value))
    svd.append('        </constants>')

    svd.append('    </vendorExtensions>')
    svd.append('</device>')
    return "\n".join(svd)

class DocIrq():
    def __init__(self):
        self.locs = {
            # "test": 1
        }

class DocCsr():
    def __init__(self):
        self.regions = {
            # "test_reg" : SoCCSRRegion(
            #     0x4000_0000,
            #     32,
            #     [
            #         CSRStatus(
            #             name="fifo_status",
            #             fields=[
            #             CSRField(name="rx_words", size=11, description="Number of words available to read"),
            #             CSRField(name="tx_words", size=11, description="Number of words pending in write FIFO. Free space is {} - `tx_avail`".format(10)),
            #             CSRField(name="abort_in_progress", size=1, description="This bit is set if an `aborting` event was initiated and is still in progress."),
            #             CSRField(name="abort_ack", size=1,
            #             description="""This bit is set by the peer that acknowledged the incoming abort
            # (the later of the two, in case of an imperfect race condition). The abort response handler should
            # check this bit; if it is set, no new acknowledgement shall be issued. The bit is cleared
            # when an initiator initiates a new abort. The initiator shall also ignore the state of this
            # bit if it is intending to initiate a new abort cycle."""),
            #             CSRField(name="tx_err", size=1, description="Set if the write FIFO overflowed because we wrote too much data. Cleared on register read."),
            #             CSRField(name="rx_err", size=1, description="Set if read FIFO underflowed because we read too much data. Cleared on register read."),
            #         ]),
            #         CSRStorage(
            #             name="abort",
            #             fields=[
            #                 CSRField(name="abort", size=1, description=
            #                 """Write `1` to this field to both initiate and acknowledge an abort.
            #     Empties both FIFOs, asserts `aborting`, and prevents an interrupt from being generated by
            #     an incoming abort request. New reads & writes are ignored until `aborted` is asserted
            #     from the peer.""", pulse=True)
            #         ])
            #     ]
            # )
        }
        self.data_width = 32

class DocSoc():
    def __init__(self):
        self.irq = DocIrq()
        self.csr = DocCsr()
        self.constants = {
            # "ACLK" : 800_000_000
        }
        self.mem_regions = {
            # "sram" : SoCRegion(
            #     origin=0x6000_0000,
            #     size = 0x100_0000,
            #     mode="rw",
            #     cached=True
            # )
        }
        self._submodules = {}

# Vendored in because we want to suppres the generation of RESERVED registers
def generate_docs(soc, base_dir,
    project_name          = "LiteX SoC Project",
    author                = "Anonymous",
    sphinx_extensions     = [],
    quiet                 = False,
    note_pulses           = False,
    from_scratch          = True,
    sphinx_extra_config   = ""):
    """Possible extra extensions:
        [
            'm2r',
            'recommonmark',
            'sphinx_rtd_theme',
            'sphinx_autodoc_typehints',
        ]
    """

    # Ensure the target directory is a full path
    if base_dir[-1] != '/':
        base_dir = base_dir + '/'

    # Ensure the output directory exists
    pathlib.Path(base_dir + "/_static").mkdir(parents=True, exist_ok=True)

    # Create the sphinx configuration file if the user has requested,
    # or if it doesn't exist already.
    if from_scratch or not os.path.isfile(base_dir + "conf.py"):
        with open(base_dir + "conf.py", "w", encoding="utf-8") as conf:
            year = datetime.datetime.now().year
            sphinx_ext_str = ""
            for ext in sphinx_extensions:
                sphinx_ext_str += "\n    \"{}\",".format(ext)
            print(default_sphinx_configuration.format(project_name, year,
                                                      author, author, sphinx_ext_str), file=conf)
            print(sphinx_extra_config, file=conf)

    if not quiet:
        print("Generate the documentation by running `sphinx-build -M html {} {}_build`".format(base_dir, base_dir))

    # Gather all interrupts so we can easily map IRQ numbers to CSR sections
    interrupts = {}
    for csr, irq in sorted(soc.irq.locs.items()):
        interrupts[csr] = irq

    # Convert each CSR region into a DocumentedCSRRegion.
    # This process will also expand each CSR into a DocumentedCSR,
    # which means that CompoundCSRs (such as CSRStorage and CSRStatus)
    # that are larger than the buswidth will be turned into multiple
    # DocumentedCSRs.
    documented_regions = []
    seen_modules       = set()
    for name, region in soc.csr.regions.items():
        module = None
        if hasattr(soc, name):
            module = getattr(soc, name)
            seen_modules.add(module)
        submodules = gather_submodules(module)
        documented_region = DocumentedCSRRegion(
            name           = name,
            region         = region,
            module         = module,
            submodules     = submodules,
            csr_data_width = soc.csr.data_width)
        compressed_csrs = [csr for csr in documented_region.csrs if 'RESERVED' not in csr.name]
        if len(compressed_csrs) > 0:
            documented_region.csrs = compressed_csrs
        if documented_region.name in interrupts:
            documented_region.document_interrupt(
                soc, submodules, interrupts[documented_region.name])
        documented_regions.append(documented_region)

    # Document any modules that are not CSRs.
    # TODO: Add memory maps here.
    additional_modules = [
        DocumentedInterrupts(interrupts),
    ]
    for (mod_name, mod) in soc._submodules:
        if mod not in seen_modules:
            try:
                additional_modules.append(DocumentedModule(mod_name, mod))
            except ModuleNotDocumented:
                pass

    # Create index.rst containing links to all of the generated files.
    # If the user has set `from_scratch=False`, then skip this step.
    if from_scratch or not os.path.isfile(base_dir + "index.rst"):
        with open(base_dir + "index.rst", "w", encoding="utf-8") as index:
            print("""
Documentation for {}
{}

""".format(project_name, "="*len("Documentation for " + project_name)), file=index)

            if len(additional_modules) > 0:
                print("""
Modules
=======

.. toctree::
    :maxdepth: 1
""", file=index)
                for module in additional_modules:
                    print("    {}".format(module.name), file=index)

            if len(documented_regions) > 0:
                print("""
Register Groups
===============

.. toctree::
    :maxdepth: 1
""", file=index)
                for region in documented_regions:
                    print("    {}".format(region.name), file=index)

            print("""
Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
""", file=index)

    # Create a Region file for each of the documented CSR regions.
    for region in documented_regions:
        with open(base_dir + region.name + ".rst", "w", encoding="utf-8") as outfile:
            region.print_region(outfile, base_dir, note_pulses)

    # Create a Region file for each additional non-CSR module
    for region in additional_modules:
        with open(base_dir + region.name + ".rst", "w", encoding="utf-8") as outfile:
            region.print_region(outfile, base_dir, note_pulses)

    # Copy over wavedrom javascript and configuration files
    with open(Path(os.path.dirname(__file__)) / Path("WaveDrom.js"), "r") as wd_in:
        with open(base_dir + "/_static/WaveDrom.js", "w") as wd_out:
            wd_out.write(wd_in.read())
    with open(Path(os.path.dirname(__file__)) / Path("default.js"), "r") as wd_in:
        with open(base_dir + "/_static/default.js", "w") as wd_out:
            wd_out.write(wd_in.read())


# --------------------------------------------------------------------------------------------------
# End vendored code - below is the application code unique to this script.
# --------------------------------------------------------------------------------------------------


# from https://stackoverflow.com/questions/2319019/using-regex-to-remove-comments-from-source-files
def remove_comments(string):
    pattern = r"(\".*?\"|\'.*?\')|(/\*.*?\*/|//[^\r\n]*$)"
    # first group captures quoted strings (double or single)
    # second group captures comments (//single-line or /* multi-line */)
    regex = re.compile(pattern, re.MULTILINE|re.DOTALL)
    def _replacer(match):
        # if the 2nd group (capturing comments) is not None,
        # it means we have captured a non-quoted (real) comment string.
        if match.group(2) is not None:
            return "" # so we will return empty to remove the comment
        else: # otherwise, we will return the 1st group
            return match.group(1) # captured quoted-string
    return regex.sub(_replacer, string)

# cleans up comma separated entities inside braced expressions. Assumes they are all in one line.
# (awful special case handling of parameter list expansion, does not generalize well)
def cleanup_braces(expr):
    output = []
    signal_list = ''
    for e in expr:
        if '{' in e:
            signal_list += e
            continue
        elif '}' in e:
            signal_list += ', ' + e
            output += [signal_list]
            signal_list = ''
        else:
            if signal_list != '':
                signal_list += ', ' + e
            else:
                output += [e]
    if signal_list != '':
        logging.error(f"Curly brace list did not resolve within a single line, case is not handled: {expr}")
    return output

def try_convert_numeric(element: str):
    if type(element) is int:
        return element
    if type(element) is float:
        if not element.is_integer():
            logging.warning("Rounding {} to {}".format(element, int(element)))
        return int(element)

    if type(element) is not str:
        return None
    if "'" in element:
        element = element.replace('_', '') # remove _ separators
        s = element.split("'")
        # hex check first, so that the hex digit 'd' can be disambiguated from the decimal specifier 'd'
        if 'h'in s[1]:
            return int(s[1].lstrip('h'), base=16)
        elif 'd' in s[1]:
            return int(s[1].lstrip('d'))
        elif 'b' in s[1]:
            return int(s[1].lstrip('b'), base=2)
        else:
            try:
                return int(s[1])
            except ValueError:
                return None
    else:
        try:
            return int(element)
        except ValueError:
            return None

# ------ mini-math evaluator -------
# from https://stackoverflow.com/questions/2371436/evaluating-a-mathematical-expression-in-a-string
# supported operators
operators = {ast.Add: op.add, ast.Sub: op.sub, ast.Mult: op.mul,
            ast.Div: op.truediv, ast.Pow: op.pow, ast.USub: op.neg}

def eval_expr(expr):
    """
    >>> eval_expr('2^6')
    4
    >>> eval_expr('2**6')
    64
    >>> eval_expr('1 + 2*3**(4^5) / (6 + -7)')
    -5.0
    """
    return eval_(ast.parse(expr, mode='eval').body)

def eval_(node):
    if isinstance(node, ast.Num): # <number>
        return node.n
    elif isinstance(node, ast.BinOp): # <left> <operator> <right>
        return operators[type(node.op)](eval_(node.left), eval_(node.right))
    elif isinstance(node, ast.UnaryOp): # <operator> <operand> e.g., -1
        return operators[type(node.op)](eval_(node.operand))
    else:
        raise TypeError(node)

class Expr():
    # this takes an expression 'e' which is just a string value, and stores it for later evaluation
    # once the full file has been read in
    def __init__(self, e):
        self.expression = e
        self.evaluated = False
        self.eval_result = -1
        self.tokens = re.findall(r"(\$?[\w:']*[\.]?[\w:']+\b|[\(\)\+\*\-\/])", self.expression.strip())
        self.unhandled_case = False

    def is_fully_expanded(self):
        for t in self.tokens:
            if type(t) == int:
                continue
            else:
                if t == '+' or t == '-' or t == '/' or t == '*' or t == '**':
                    continue
                elif type(t) == str and 'clog2' not in t:
                    continue
                else:
                    # if an unhandled case is found, eval aborts by saying it is full expanded, when it may not actually be.
                    return self.unhandled_case
        return True

    # this should take the schema, expand the string into tokens, and evaluate any expression to an integer value
    def eval(self, schema, module):
        if self.evaluated:
            return self.eval_result

        if '{' in self.expression:
            logging.debug(f"Not expanding braced expression: {self.expression}")
            self.evaluated = True
            self.eval_result = self.expression
            return self.eval_result
        for (index, t) in enumerate(self.tokens):
            num = try_convert_numeric(t)
            if num is not None:
                self.tokens[index] = num
            else:
                if t == '+' or t == '-' or t == '/' or t == '*' or t == '**':
                    pass # these are handled later
                else:
                    if 'clog2' in t:
                        # find paren locations. This code will fail if there are nested parens.
                        eval_str = ''
                        if '(' in self.tokens:
                            # expanded version
                            open_paren = self.tokens.index('(')
                            close_paren = self.tokens.index(')')
                            for c in self.tokens[open_paren+1:close_paren]:
                                if type(c) is int:
                                    eval_str += str(c)
                                    eval_str += ' '
                                else:
                                    eval_str += c
                                    eval_str += ' '
                        else:
                            # unexpanded version
                            open_paren = t.index('(')
                            close_paren = t.index(')')
                            for c in t[open_paren+1:close_paren]:
                                eval_str += c
                            # this will cause the patching routine to "do nothing"
                            open_paren = index+1
                            close_paren = index
                        try:
                            inner_e = Expr(eval_str)
                            inner_e.eval(schema, module)
                            clog2val = int(log2(inner_e.eval_result))
                            # print(clog2val)
                            # replace clog2 token with the value of the inner expression with clog2 applied
                            self.tokens[index] = clog2val
                            # patch out the original expression
                            for i in range(open_paren,close_paren+1):
                                self.tokens[i] = ''
                            t = str(clog2val)
                        except:
                            # a lot of these expressions are used in areas not related to SFRs, let's just skip them.
                            logging.debug("couldn't evaluate clog2 inner: {}".format(eval_str))
                            self.unhandled_case = True

                    # must be an identifier. Resolve the identifier.
                    ident_path = t.split('::')
                    # could do this recursively, but in practice there's only two cases: it's local, or in one other package.
                    if len(ident_path) == 1:
                        # local identifier
                        # check if it's in the param dict; if not, then return as a token
                        if ident_path[0] in schema[module]['localparam']:
                            expansion = schema[module]['localparam'][ident_path[0]]
                        else:
                            expansion = ident_path[0]
                        # if it's an expression, recurse and expand more
                        if type(expansion) is Expr:
                            self.tokens[index] = expansion.eval(schema, module)
                        else:
                            self.tokens[index] = expansion
                    else:
                        assert(len(ident_path) == 2)
                        # check for out-of-scope packages
                        if ident_path[0] not in schema:
                            logging.warning(f"Package not in scope: {ident_path[0]}, cannot expand")
                            self.tokens[index] = f"Unavailable: {ident_path[0]}::{ident_path[1]}"
                            continue
                        # check if we've reached a terminus
                        if ident_path[1] in schema[ident_path[0]]['localparam']:
                            expansion = schema[ident_path[0]]['localparam'][ident_path[1]]
                        else:
                            expansion = ident_path[1]
                        # recurse if necessary
                        if type(expansion) is Expr:
                            self.tokens[index] = expansion.eval(schema, ident_path[0])
                        else:
                            self.tokens[index] = expansion
        if self.is_fully_expanded():
            # condense tokens into a string again
            eval_str = ''
            for t in self.tokens:
                if type(t) is int:
                    eval_str += str(t)
                    eval_str += ' '
                else:
                    eval_str += t
                    eval_str += ' '
            try:
                # if it's a numerical expression, reduce it
                self.eval_result = eval_expr(eval_str)
                self.evaluated = True
                return self.eval_result
            except:
                # logging.error(f"Couldn't evaluate expression:\n  {self.expression}\ntoken tree:\n  {self.tokens}")
                # it's a string that represents a token of some type. The result is that string.
                self.evaluated = True
                self.eval_result = self.expression
                return self.eval_result
        else:
            self.eval(schema, module)

    def as_str(self):
        if self.evaluated:
            return str(self.eval_result)
        else:
            return self.expression

# localparam format notes:
# localparam <[array_size]> <type> <[bit_width]> ident = expr;
#  - if only one bracketed expression, ignore
#  - if no bracketed expression, it's just ident = expr
#  - bitwidth can generally be ignored
def extract_localparam(schema, module, code_line):
    # this matcher keys off of '=', allows zero or more whitespaces to create the last two groups
    # the tricky bit is getting rid of all the type information before the lhs. We do this with the
    # '\s([\S]+)' match group pulling in ' ' as part of the group. Thus, there *must* be a space before
    # the lhs token and any type definition.
    # So this would not work: "localparam foo [7:0]bogus = bar;" because it's missing a space after the ']'
    # TODO: revise this to use \b, "word boundary" instead of the explicit \s

    # sometimes multiple params are put on one line, this handles that case
    plist = code_line.rstrip().rstrip(';').split(';')
    for p in plist:
        matcher = re.compile('localparam(.*)\s([\S]+)\s*=\s*(.*)')
        maybe_match = matcher.match(p.lstrip())
        if maybe_match is None:
            if p != '': # sometimes we have trailing space after the ;, don't flag an error on this
                logging.error(f"localparameter did not extract: {p}")
            return
        groups = maybe_match.groups()
        if len(groups) != 3:
            logging.error(f"localparameter didn't get expected number of groups (got {len(groups)}): {p}")
            return
        lhs = groups[1]
        rhs = groups[2]
        logging.debug(f"localparam extract lhs {lhs} | rhs {rhs}")
        schema[module]['localparam'][lhs] = Expr(rhs)

def extract_parameter(schema, module, code_line):
    matcher = re.compile('parameter(.*)\s([\S]+)\s*=\s*(.*)')
    code_line = code_line.rstrip(',') # don't care about the trailing comma
    maybe_match = matcher.match(code_line)
    if maybe_match is None:
        logging.error(f"Parameter did not extract: {code_line}")
        return
    groups = maybe_match.groups()
    if len(groups) != 3:
        logging.error(f"Parameter didn't get expected number of groups (got {len(groups)}): {code_line}")
        return
    lhs = groups[1]
    rhs = groups[2]
    logging.debug(f"parameter extract lhs {lhs} | rhs {rhs}")
    schema[module]['localparam'][lhs] = Expr(rhs)

def expand_param_list(params):
        arg_re = re.compile('[.](.+?)\((.+)\)')
        expanded_params = {}
        for param in params:
            exprs = arg_re.match(param)
            if exprs is None:
                if param != '.prdata32()' and param != '.*' and param != '.hrdata32()':
                    logging.error(f"Error parsing argument expression {param}, ignoring!!")
                continue
            p_name = exprs.group(1)
            p_expr = Expr(exprs.group(2))
            expanded_params[p_name] = p_expr
        return expanded_params

def extract_bitwidth(schema, module, code_line):
    if module == 'rp_pio':
        code_line = code_line.replace('[0:NUM_MACHINES-1]', '') # FIXME: hack to ignore machine index. Works for this specific module only!
        code_line = code_line.replace('[NUM_MACHINES-1:0]', '')
    if module == 'bio':
        code_line = code_line.replace('[NUM_MACH]', '') # FIXME: hack to ignore machine index. Works for this specific module only!
        code_line = code_line.replace('[NUM_MACH-1:0]', '')
    if module == 'bio_dma':
        code_line = code_line.replace('[NUM_MACH]', '') # FIXME: hack to ignore machine index. Works for this specific module only!
        code_line = code_line.replace('[NUM_MACH-1:0]', '')

    bw_re = re.compile('[\s]*(bit|logic|reg|wire)[\s]*(\[.*\])*(.*)')
    matches = bw_re.search(code_line.strip(';'))
    if matches is not None:
        bw = matches.group(2)
        names = matches.group(3).split(',')
        if bw is None:
            for name in names:
                schema[module]['localparam'][name.strip()] = 1
        else:
            bracket_re = re.compile('\[(.*):(.*)\]')
            bracket_matches = bracket_re.search(bw)
            if bracket_matches is not None:
                try:
                    # FIXME: hack to deal with parameterized NUM_MACHINES-1 in bit widths.
                    width = int(bracket_matches.group(1).replace('NUM_MACHINES-1', '3')) - int(bracket_matches.group(2)) + 1
                    for name in names:
                        schema[module]['localparam'][name.strip()] = width
                except:
                    logging.debug(f"bit expression not handled: {bw}, not creating an entry")


def add_reg(schema, module, code_line, source_file=None):
    REGEX = '(apb_[cfas2hfinbur]+[rnf])\s+#\((.+)\)\s(.+)\s\((.+)\);'
    line_matcher = re.match(REGEX, code_line)
    if line_matcher is None:
        if 'apb_sfr2' not in code_line and 'apb_sfrop2' not in code_line: # exceptions for the SFR definitions at the end of the file
            logging.error('Regex match error (this is a script bug, regex needs to be fixed)')
            logging.error(f'Line:  {code_line}')
            logging.error(f'regex: {REGEX}')
    else:
        apb_type = line_matcher.group(1).strip()
        # create a list by mapping 'str.strip' onto the result of splitting the line_matcher's respective group on the ',' character
        # 'it made sense at the time' :-P
        params = cleanup_braces(list(map(str.strip, line_matcher.group(2).split(','))))
        reg_name = line_matcher.group(3).strip()
        args = cleanup_braces(list(map(str.strip, line_matcher.group(4).split(','))))
        #if module == 'aes':
        #    print(f'type: {apb_type}, params: {params}, reg_name: {reg_name}, args: {args}')
        if apb_type != 'apb_cr' and apb_type != 'apb_fr' and apb_type != 'apb_sr' \
            and apb_type != 'apb_ar' and apb_type != 'apb_asr' and apb_type != 'apb_acr' \
                and apb_type != 'apb_ac2r' and apb_type != 'apb_ascr' and apb_type != 'apb_shfin' \
                    and apb_type != 'apb_buf' and apb_type != 'apb_sfr':
            logging.error(f"Parse error extracting APB register type: unrecognized register macro {apb_type}, ignoring!!!")
            return
        schema[module][apb_type][reg_name] = {
            'params' : expand_param_list(params),
            'args': expand_param_list(args),
        }
        if source_file is not None:
            schema[module][apb_type][reg_name]['src'] = source_file

def is_m_or_p_empty(m_or_p):
    # we don't evaluate 'sfr_bank' because that's dependent on the apb_* not being empty
    if len(m_or_p['localparam']) == 0 \
        and len(m_or_p['apb_cr']) == 0 \
        and len(m_or_p['apb_sr']) == 0 \
        and len(m_or_p['apb_fr']) == 0 \
        and len(m_or_p['apb_ar']) == 0:
        return True
    else:
        return False

def is_tree_used(tree):
    for key in tree.keys():
        if 'sfr' in key:
            return True
    if 'apb_cr' not in tree:
        return False
    if 'apb_sr' not in tree:
        return False
    if 'apb_fr' not in tree:
        return False
    if 'apb_ar' not in tree:
        return False
    if len(tree['apb_cr']) == 0 and len(tree['apb_sr']) == 0 and len(tree['apb_fr']) == 0 and len(tree['apb_ar']) == 0:
        return False
    return True

def eval_tree(tree, schema, module, level=0, do_print=False):
    if type(tree) is dict:
        for (k, v) in tree.items():
            #if k == 'localparam':
            #    continue
            if type(v) is dict:
                if len(v) == 0:
                    continue
                if do_print:
                    print(' ' * level + f'{k}:')
                eval_tree(v, schema, module, level + 2, do_print)
            else:
                if isinstance(v, Expr):
                    v.eval(schema, module)
                    if do_print:
                        print(' ' * level + f'{k}:{v.as_str()}')
                else:
                    if do_print:
                        print(' ' * level + f'{k}:{v}')

    else:
        if isinstance(tree, Expr):
            tree.eval(schema, module)
            if do_print:
                print(' ' * level + f'{tree.as_str()}')
        else:
            if do_print:
                print(' ' * level + f'{tree}')

def create_csrs(doc_soc, schema, module, banks, orphans, ctrl_offset=0x4002_8000, bio_aliases={}):
    regtypes = ['cr', 'sr', 'fr', 'ar', 'asr', 'acr', 'ascr', 'ac2r', 'shfin', 'buf', 'sfr']
    regdescs = {
        'cr': ' read/write control register',
        'sr': ' read only status register',
        'ar': ' performs action on write of value: ',
        'fr': ' flag register. `1` means event happened, write back `1` in respective bit position to clear the flag',
        'asr': 'status register which triggers an action on read',
        'acr': 'control register which triggers an action on write',
        'ac2r': 'control register which triggers an action on write, with a special case self-clearing bank of bits',
        'ascr': 'combination control/status register which can also trigger an action',
        'shfin' : 'write-only shift-in register; 8 deep',
        'buf' : 'write/read shift register; 8-deep',
        'sfr' : 'read/write control register',
    }
    regfuncs = {
        'cr': CSRStorage,
        'sr': CSRStatus,
        'ar': CSRStorage,
        'fr': CSRStatus,
        'asr': CSRStatus,
        'acr': CSRStorage,
        'ac2r': CSRStorage,
        'ascr': CSRStatus,
        'shfin': CSRStorage,
        'buf': CSRStatus,
        'sfr': CSRStorage,
    }
    if module in banks:
        csrs = []
        for (bank, leaves) in schema[module].items():
            for rtype in regtypes:
                if bank == 'apb_' + rtype:
                    for (leaf_name, leaf_desc) in leaves.items():
                        if 'apbs' in leaf_desc['args']:
                            # don't generate entries for aliased register banks in BIO-BDMA, just note the alias
                            bio_aliases[leaf_desc['params']['A'].eval_result] = leaf_name
                            continue
                        if 'sfrs' in leaf_desc:
                            the_arg = leaf_desc['args'][rtype]
                            sfr_dict = leaf_desc['sfrs']
                            for (sfr_name, sfr_offset) in sfr_dict.items():
                                if type(the_arg.eval_result) is int:
                                    fname = leaf_name
                                else:
                                    # clean up strings to be valid python identifiers
                                    fname = the_arg.as_str().replace('.', '_').strip() # . is not valid in identifiers, nor are trailing spaces
                                    if '[' in fname:
                                        fname = fname.split('[')[0]
                                assert(rtype != 'ar') # we don't handle 'ar' type with SFRCNT idiom
                                sfr_name = sfr_name.replace('[', '_').replace(']', '_').replace(':', '_').strip() # remove invalid identifies from bracketed expressions
                                fields = [
                                    CSRField(
                                        name= sfr_name,
                                        size= leaf_desc['params']['DW'].eval_result,
                                        description= fname + regdescs[rtype],
                                    )
                                ]
                                if isinstance(sfr_offset, Expr):
                                    offset = sfr_offset.eval_result
                                else:
                                    offset = sfr_offset
                                if 'src' in leaf_desc:
                                    csrs += [regfuncs[rtype](
                                        name=leaf_name + '_' + sfr_name,
                                        n=int((leaf_desc['params']['A'].eval_result / 4) + offset),
                                        fields=fields,
                                        description = f'See {URL_PREFIX + leaf_desc["src"]}'
                                    )]
                                else:
                                    csrs += [regfuncs[rtype](
                                        name=leaf_name + '_' + sfr_name,
                                        n=int((leaf_desc['params']['A'].eval_result / 4) + offset),
                                        fields=fields,
                                    )]
                        else:
                            # fixup compound-action type registers
                            if rtype == 'asr':
                                rtype_fixup = 'sr'
                            elif rtype == 'acr':
                                rtype_fixup = 'cr'
                            elif rtype == 'ac2r':
                                rtype_fixup = 'cr'
                            elif rtype == 'ascr':
                                rtype_fixup = 'cr'
                            elif rtype == 'sfr':
                                rtype_fixup = 'cr'
                            # special case for TRNG shift-in registers
                            # link the 'dr' field to the relevant standard template field for codegen
                            elif rtype == 'shfin' or rtype == 'buf':
                                if rtype == 'shfin':
                                    rtype_fixup = 'cr'
                                    leaf_desc['args']['cr'] = leaf_desc['args']['dr']
                                if rtype == 'buf':
                                    rtype_fixup = 'sr'
                                    if 'sr' not in leaf_desc['args']:
                                        leaf_desc['args']['sr'] = Expr('32') # default to 32 bits if no argument given
                            else:
                                rtype_fixup = rtype

                            try:
                                the_arg = leaf_desc['args'][rtype_fixup]
                            except:
                                logging.error(f"Couldn't extract CSR for {leaf_name} - manual creation will be necessary")
                                continue
                            fields = []
                            constant_counter = 0
                            if '{' in the_arg.as_str():
                                base_str = the_arg.as_str().replace('{', '').replace('}', '')
                                bitfields = base_str.split(',')
                                for bf in reversed(bitfields):
                                    bf = bf.strip()
                                    if module == 'rp_pio' or module == 'bio' or module == 'bio_bdma':
                                        # FIXME: special case hack to remove index from all bitfields except for the [r,t]x_level series
                                        if '_level' not in bf:
                                            bf = bf.split('[')[0]
                                        # FIXME: restore bit width to signals that are aggregate across all machines but
                                        # consolidated into a single register
                                        if 'clkdiv_restart' == bf or 'restart' == bf or 'en' == bf:
                                            bitwidth = 4
                                        elif bf in schema[module]['localparam']:
                                            bitwidth = schema[module]['localparam'][bf]
                                        else:
                                            # FIXME: special case the rx/tx level entries
                                            if 'rx_level' in bf or 'tx_level' in bf:
                                                bitwidth = 3
                                            else:
                                                if "'d" not in bf: # we do handle 'd constant fields, just below...
                                                    if 'fifo_event_level' in bf:
                                                        logging.warning(f"{bf} assigned width = 4 through special case")
                                                        bitwidth = 4
                                                    elif 'regfifo_level' in bf:
                                                        logging.warning(f"{bf} assigned width = 4 through special case")
                                                        bitwidth = 4
                                                    else:
                                                        logging.warning(f"{bf} can't be found, assuming width=1. Manual check is necessary!")
                                                        bitwidth = 1
                                    else:
                                        if bf in schema[module]['localparam']:
                                            bitwidth = schema[module]['localparam'][bf]
                                        else:
                                            logging.warning(f"{bf} can't be found, assuming width=1. Manual check is necessary!")
                                            bitwidth = 1
                                    assert(rtype_fixup != 'ar') # we don't expect multi-bit ar defs
                                    if "'d" in bf: # this is a constant field
                                        bf_sub = bf.split("'d")
                                        bitwidth = int(bf_sub[0])
                                        fields += [
                                            CSRField(
                                                name=f"constant{constant_counter}",
                                                size= bitwidth,
                                                description= "constant value of {}".format(bf_sub[1]),
                                            )
                                        ]
                                        constant_counter += 1
                                    else:
                                        fields += [
                                            CSRField(
                                                name= bf.replace('[', '').replace(']', '').replace('.', '_').replace(':', '_').strip(),
                                                size= bitwidth,
                                                description= bf + regdescs[rtype_fixup],
                                            )
                                        ]
                            else:
                                if type(the_arg.eval_result) is int:
                                    fname = leaf_name
                                else:
                                    # clean up strings to be valid python identifiers
                                    fname = the_arg.as_str().replace('.', '_').strip() # . is not valid in identifiers, nor are trailing spaces
                                    if '[' in fname:
                                        fname = fname.split('[')[0]
                                if rtype_fixup == 'ar':
                                    if 'DW' in leaf_desc['params']:
                                        ar_size = leaf_desc['params']['DW'].eval_result
                                    else:
                                        ar_size = 32
                                    raw_action = leaf_desc['params']['AR'].eval_result
                                    if type(raw_action) is int:
                                        action = hex(raw_action)
                                    else:
                                        action = raw_action
                                    fields += [
                                        CSRField(
                                            name= fname,
                                            size= ar_size,
                                            description= fname + regdescs[rtype_fixup] + action,
                                            pulse=True
                                        )
                                    ]
                                else:
                                    fname = fname.replace("| 32'h0", "").strip() # remove bit-extenders
                                    fields += [
                                        CSRField(
                                            name= fname,
                                            size= int(leaf_desc['params']['DW'].eval_result),
                                            description= fname + regdescs[rtype_fixup],
                                        )
                                    ]
                            if 'src' in leaf_desc:
                                csrs += [regfuncs[rtype_fixup](
                                    name=leaf_name,
                                    n=int(leaf_desc['params']['A'].eval_result / 4),
                                    fields=fields,
                                    description=f'See {URL_PREFIX + leaf_desc["src"]}'
                                )]
                            else:
                                csrs += [regfuncs[rtype_fixup](
                                    name=leaf_name,
                                    n=int(leaf_desc['params']['A'].eval_result / 4),
                                    fields=fields,
                                )]
        doc_soc.csr.regions[module] = SoCCSRRegion(
            ctrl_offset + banks[module] * 0x1000,
            32,
            csrs
        )
    else:
        count = 0
        for rtype in regtypes:
            for (bank, leaves) in schema[module].items():
                if bank == 'apb_' + rtype:
                    count += len(leaves)
        if count != 0:
            logging.debug(f"Registers were discovered that do not have a top-level address mapping: {module}, {count} total orphaned registers")
            if module in orphans:
                orphans[module] += 1
            else:
                orphans[module] = 1

def generate_rust_test(doc_soc, file):
    random.seed(10)

    file.write(
"""
// use crate::daric_generated::*;

pub fn singlecheck(title: &str, addr: *mut u32, data: u32) {
    let mut uart = crate::debug::Uart {};

    uart.tiny_write_str(title);
    uart.tiny_write_str("::  [");
    uart.print_hex_word(addr as u32);
    uart.tiny_write_str("] wr:");
    uart.print_hex_word(data as u32);
    uart.tiny_write_str(" | rd:");

    unsafe{addr.write_volatile(data)};
    let r = unsafe{addr.read_volatile()};

    uart.print_hex_word(r);
    uart.tiny_write_str(" ");
    if r != data {
        uart.tiny_write_str("----[x!]");
        if r == 0 {
            uart.tiny_write_str("[0!]");
        }
    }
    uart.tiny_write_str("\\n")
}

pub fn singlecheckread(title: &str, addr: *const u32) {
    let mut uart = crate::debug::Uart {};
    uart.tiny_write_str(title);
    uart.tiny_write_str("::  [");
    uart.print_hex_word(addr as u32);
    uart.tiny_write_str("] wr:-------- | rd:");
    let r = unsafe{addr.read_volatile()};
    uart.print_hex_word(r);
    uart.tiny_write_str(" \\n");
}

pub fn apb_test() {
    let mut uart = crate::debug::Uart {};
    crate::snap_ticks("scan bus:: ");

"""
    )
    documented_regions = []
    for region_name, region in doc_soc.csr.regions.items():
        documented_regions.append(DocumentedCSRRegion(
            name           = region_name,
            region         = region,
            csr_data_width = doc_soc.csr.data_width)
        )
    skip_list = [
        # 'aes', 'combohash', 'pke', 'scedma', 'sce_glbsfr',
        'trng', 'alu',
        # 'evc',
        'sysctrl',
    ]
    for region in reversed(documented_regions):
        if region.name in skip_list:
            continue
        # extract pretty-printing data
        max_width = 0
        for csr in region.csrs:
            if len(csr.name) > max_width:
                max_width = len(csr.name)

        # now do the code gen
        file.write("    crate::snap_ticks(\"{}:: \");\n".format(region.name))
        for csr in region.csrs:
            if not 'reserved' in csr.name.lower():
                # print(csr.short_numbered_name)
                file.write(
                    "    singlecheck({}, 0x{:08x} as *mut u32, 0x{:08x});\n".format(
                        '"' + csr.name.ljust(max_width) + '"',
                        csr.address,
                        random.randint(0, 0xFFFF_FFFF)
                    )
                )

    udc_addrs = [
        0x50202000,
        0x50202004,
        0x502020fc,
        0x50202084,
        0x50202400,
        0x50202410,
        0x50202414,
        0x502024fc,
        0x50202484,
    ]
    for addr in udc_addrs:
        file.write(
            "    singlecheckread({}, 0x{:08x} as *const u32);\n".format(
                '"udc            "',
                addr,
            )
        )

    file.write(
"""
    loop {
        uart.tiny_write_str("scan done\\n");
    }
}
""")

def convert_verilog_integer(expression):
    expression = expression.strip()  # Remove leading/trailing whitespaces
    base = 10  # Default base is decimal

    if "'b" in expression:
        base = 2
        expression = expression.split("'b")[1]
    elif "'o" in expression:
        base = 8
        expression = expression.split("'o")[1]
    elif "'h" in expression:
        base = 16
        expression = expression.split("'h")[1]

    try:
        return int(expression, base)
    except ValueError:
        raise ValueError("Invalid Verilog-style integer expression")

def process_pulp(doc_soc, pulp_reg_files, schema, path, top_regions):
    reg_addrs = {}
    reg_rd_fields = {} # dictionary of fields storing a tuple of (msb,lsb)
    reg_wr_fields = {}
    reg_srcs = {}
    for basename in pulp_reg_files:
        (file, vers) = pulp_reg_files[basename]

        # SPECIAL CASE: fixup inconsistencies in code forked from the pulpino source
        if 'udma_scif_reg' == basename:
            basename = 'udma_scif_reg_if'
        if 'udma_spis_reg' == basename:
            basename = 'udma_spis_reg_if'

        if 'rtl2' in str(file):
            file = Path(str(file).replace('rtl2', 'rtl')) # patch out a backup directory

        with open(file, "r", encoding='utf-8') as pulp_file:
            # set up the records for a given file
            fname = Path(pulp_file.name).name
            if fname.startswith('udma_'):
                prefix = fname.split('_')[1].split('.')[0]
            else:
                if 'adv_timer' not in fname:
                    prefix = fname.split('.')[0].split('_')[0] # drops a .sv suffix if it's there
                else:
                    prefix = 'pwm'
            if prefix not in reg_addrs:
                reg_addrs[prefix] = {}
                reg_rd_fields[prefix] = {}
                reg_wr_fields[prefix] = {}
                reg_srcs[prefix] = Path(file).as_posix() # .split(path)[1]

            # extract the register address offsets, and setup fields placeholders
            includes = []
            for line in pulp_file:
                if 'define'in line and 'REG' in line: # pulp code is very good about keeping with this format.
                    tokens = line.split()
                    reg_addrs[prefix][tokens[1]] = convert_verilog_integer(tokens[2]) * 4
                    reg_rd_fields[prefix][tokens[1]] = {}
                    reg_wr_fields[prefix][tokens[1]] = {}
                if '`include' in line:
                    includes += [re.search(r'"([^"]+)"', line).group(1)]
            # now add any includes we found along the way
            for inc in includes:
                if inc == 'udma_i2c_defines.sv':
                    # why is this in a weird place?
                    fname = path / Path('ips/incdir') / inc
                else:
                    fname = Path(file).parent / inc
                with open(fname, "r", encoding='utf-8') as def_file:
                    for line in def_file:
                        if 'define'in line and 'REG' in line: # pulp code is very good about keeping with this format.
                            tokens = line.split()
                            reg_addrs[prefix][tokens[1]] = convert_verilog_integer(tokens[2]) * 4
                            reg_rd_fields[prefix][tokens[1]] = {}
                            reg_wr_fields[prefix][tokens[1]] = {}

            # extract register fields
            read_or_write = None
            in_reg = None
            extract = False
            pulp_file.seek(0)
            if 'i2s' in str(file):
                print("b")
            lines = consolidate_lines(file, skip_directives=False)
            for line in lines:
                if 'case' in line and 's_wr_addr' in line:
                    extract = True
                    read_or_write = 'write'
                elif 'case' in line and 's_rd_addr' in line:
                    extract = True
                    read_or_write = 'read'
                # PWM special case
                elif 'case' in line and 's_apb_addr' in line:
                    extract = True
                    read_or_write = 'either'
                elif 'endcase' in line or 'default:' in line:
                    extract = False
                if extract:
                    if line.strip().startswith('`'):
                        in_reg = line.strip().strip('`').strip(':')
                    if in_reg is not None:
                        # Translate PWM special case into UDMA handler cases
                        if read_or_write == 'either':
                            if 'PWDATA' in line:
                                read_or_write = 'write'
                            elif 'PRDATA' in line:
                                read_or_write = 'read'

                        if read_or_write == 'write':
                            delimiter = '<='
                        elif read_or_write == 'read':
                            delimiter = '='
                        elif read_or_write == 'either':
                            # loop to discover what our mode, which should be on the next line
                            continue
                        else:
                            logging.error(f"invalid value for delimiter: {delimiter}, should be one of read or write")
                            exit(1)
                        if delimiter in line:
                            lhs = line.split(delimiter)[0].strip()
                            rhs = line.split(delimiter)[1].strip().strip(';')
                            if read_or_write == 'write':
                                # lhs is the register field name
                                # the rhs going to be cfg_data_i[expr], where expr may be an integer or range
                                rhs_bracket = r"\[([^\]]+)\]"
                                matches = re.findall(rhs_bracket, rhs)
                                if prefix == 'ctrl' and in_reg == 'REG_CFG_EVT' and 'r_cmp_evt' in lhs:
                                    # handle special case of 2-D array in udma_ctrl
                                    ss_index = re.findall(r"\[([^\]]+)\]", lhs)
                                    lhs = 'r_cmp_evt_' + str(ss_index[0])
                                    msb = int(ss_index[0]) * 8 + 7
                                    lsb = int(ss_index[0]) * 8
                                    reg_wr_fields[prefix][in_reg][lhs] = (msb, lsb)
                                else:
                                    # swap out any bit targets on lhs to underscores so they are documented
                                    lhs = lhs.replace('[', '_')
                                    lhs = lhs.replace(']', '')
                                    lhs = lhs.replace(':', '_')
                                    if len(matches) == 1:
                                        maybe_range = matches[0].split(':')
                                        if len(maybe_range) == 1: # it's not a range, it's an index
                                            reg_wr_fields[prefix][in_reg][lhs] = (int(maybe_range[0]), int(maybe_range[0]))
                                        else:
                                            msb = Expr(maybe_range[0]).eval(schema, basename)
                                            lsb = Expr(maybe_range[1]).eval(schema, basename)
                                            reg_wr_fields[prefix][in_reg][lhs] = (msb, lsb)
                                    else: # no bracketed expression, assume whole field length
                                        assert(len(matches) == 0) # if not, we had *multiple* bracketed expressions, and we don't handle that
                                        # SPECIAL CASE: if statement in sdio to do single-bit clears on writes.
                                        if prefix == 'sdio' and in_reg == 'REG_STATUS':
                                            if 'r_eot' in lhs:
                                                reg_wr_fields[prefix][in_reg][lhs] = (0, 0)
                                            elif 'r_err' in lhs:
                                                reg_wr_fields[prefix][in_reg][lhs] = (1, 1)
                            elif read_or_write == 'read':
                                rhs = rhs.replace(" | '0", "") # SPECIAL CASE: swap out PX's different style from PULP for ensuring extra bits are 0 :P
                                if 'cfg_data_o' not in line:
                                    continue # skip assertions for clearing bits-on-read
                                # lhs is the width of data to read back (either name or name[range
                                # rhs is the data itself; it can either be a simple variable, or a braced expression
                                lhs_bracket = r"\[([^\]]+)\]"
                                matches = re.findall(lhs_bracket, lhs)
                                msb = None
                                lsb = None
                                if len(matches) == 1:
                                    maybe_range = matches[0].split(':')
                                    if len(maybe_range) == 1: # it's not a range, it's an index
                                        msb = int(maybe_range[0])
                                        lsb = int(maybe_range[0])
                                    else:
                                        msb = Expr(maybe_range[0]).eval(schema, basename)
                                        lsb = Expr(maybe_range[1]).eval(schema, basename)
                                else:
                                    assert(len(matches) == 0)
                                    msb = 31
                                    lsb = 0

                                rhs_braced = r"\{(.*)\}"
                                matches = re.findall(rhs_braced, rhs)
                                if len(matches) == 0:
                                    # replace any range notations with underscores directly so the range shows up in the docs
                                    rhs = rhs.replace('[', '_')
                                    rhs = rhs.replace(']', '')
                                    rhs = rhs.replace(':', '_')
                                    reg_rd_fields[prefix][in_reg][rhs] = (msb, lsb)
                                else:
                                    assert(len(matches) == 1)
                                    bitfields = matches[0].split(',')
                                    # iterate in reverse order on bitfields, from lsb to msb
                                    bitpos = 0
                                    fieldlen = 1
                                    # bitfield can be a simple expression, a bit-width 0, or a range
                                    for bf in reversed(bitfields):
                                        if "'" in bf: # bit-width 0
                                            skip = int(bf.split("'")[0])
                                            bitpos += skip
                                            # don't add a register
                                        else:
                                            if bf.strip() == 'r_err':
                                                print("b")
                                            rhs_bracket = r"\[([^\]]+)\]"
                                            expr_matches = re.findall(rhs_bracket, bf)
                                            if len(expr_matches) == 1:
                                                maybe_range = expr_matches[0].split(':')
                                                if len(maybe_range) == 1: # it's not a range, it's an index
                                                    fieldlen = 1
                                                    name = bf.split('[')[0]
                                                    if prefix == 'ctrl' and in_reg == 'REG_CFG_EVT' and name == 'r_cmp_evt':
                                                        fieldlen = 8 # special case of 2-D array in this one block
                                                    if name in reg_rd_fields[prefix][in_reg]:
                                                        name = name + '_' + str(bitpos)
                                                else:
                                                    fieldlen = \
                                                        Expr(maybe_range[0]).eval(schema, basename) \
                                                      - Expr(maybe_range[1]).eval(schema, basename)
                                                    name = bf.split('[')[0]
                                            else:
                                                # it's just a single register name
                                                try:
                                                    fieldlen = schema[basename]['localparam'][bf.strip()]
                                                except:
                                                    logging.warning(f"Signal {bf} in {basename} not extracted, guessing bit length of 1")
                                                    fieldlen = 1
                                                name = bf

                                            reg_rd_fields[prefix][in_reg][name] = (bitpos + fieldlen - 1, bitpos)
                                            bitpos += fieldlen
                                    # sanity-check that we filled out the whole length
                                    if bitpos < msb:
                                        logging.warning(f"Register underflow in UDMA: {prefix} {in_reg} {name} has {bitpos + 1} bits")
                                    if bitpos > msb:
                                        logging.warning(f"Register overflow in UDMA: {prefix} {in_reg} {name} has {bitpos + 1} bits")

    only_peripherals = {}
    for param in schema['udma_sub']['localparam']:
        if 'PER_ID' in param:
            only_peripherals[param.replace('PER_ID_', '')] = schema['udma_sub']['localparam'][param].eval(schema, 'udma_sub')

    # extract the full range of PER_IDs and iterate through the list generating register entries
    # for the given pulp-ID peripheral
    only_peripherals = sorted(only_peripherals.items(), key=lambda item: item[1]) # ensure it is sorted
    # now insert the base control on the list
    peripherals = [('CTRL', 0)]
    for p in only_peripherals:
        (n, o) = p # extract name, offset
        if n == 'CAM':
            n = 'CAMERA'
        if n == 'EXT_PER':
            continue # remove this, it's not an actual configured peripheral
        peripherals += [(n, o + 1)] # add one to offset because we inserted the 'ctrl' at 0

    UDMA_BASE = 0x5010_0000
    def add_banks(peripherals, base_addr):
        udma_index = 0
        for index, p in enumerate(peripherals):
            use_prefix = True
            (base_name, base_offset) = p
            # if base_name == 'SDIO':
            #     continue # work around suppressed SDIO block in current source tree
            # prefer to use next index as a marker for count of peripheral, as it is a more
            # reliable extraction
            if len(peripherals) > index + 1:
                (_unused_name, end_index) = peripherals[index + 1]
            else:
                try:
                    end_index = schema['udma_sub']['localparam']['N_' + base_name].eval(schema, 'udma_sub') + udma_index
                except:
                    print("couldn't determine # of peripherals in last peripheral edge case. Assuming this is a lone bank!")
                    end_index = 1
                    use_prefix = False
            if end_index - udma_index > 1:
                use_suffix = True
            else:
                use_suffix = False

            base_name = base_name.lower()
            for sub_i in range(end_index - udma_index):
                csrs = []
                for rf_name in reg_rd_fields[base_name]:
                    rf_fields = reg_rd_fields[base_name][rf_name]
                    if len(rf_fields) == 0:
                        continue
                    fields = []
                    sorted_fields = sorted(rf_fields, key= lambda item: reg_rd_fields[base_name][rf_name][item][1])
                    for field in sorted_fields:
                        (msb, lsb) = reg_rd_fields[base_name][rf_name][field]
                        fields += [CSRField(
                            name = field.strip(),
                            offset = lsb,
                            size = msb - lsb + 1,
                            description = field,
                        )]
                    csrs += [
                        CSRStatus(
                            name= rf_name,
                            n = reg_addrs[base_name][rf_name] / 4,
                            fields = fields,
                            description=f'See {URL_PREFIX + reg_srcs[base_name]}'
                        )
                    ]
                for rf_name in reg_wr_fields[base_name]:
                    rf_fields = reg_wr_fields[base_name][rf_name]
                    if len(rf_fields) == 0:
                        continue
                    fields = []
                    sorted_fields = sorted(rf_fields, key= lambda item: reg_wr_fields[base_name][rf_name][item][1])
                    for field in sorted_fields:
                        (msb, lsb) = reg_wr_fields[base_name][rf_name][field]
                        fields += [CSRField(
                            name = field.strip(),
                            offset = lsb,
                            size = msb - lsb + 1,
                            description = field,
                        )]
                    csrs += [
                        CSRStorage(
                            name= rf_name.strip(),
                            n = reg_addrs[base_name][rf_name] / 4,
                            fields = fields,
                            description=f'See {URL_PREFIX + reg_srcs[base_name]}'
                        )
                    ]
                # add a suffix if we have a bank of identical peripheral
                if use_suffix:
                    suffix = '_' + str(sub_i)
                else:
                    suffix = ''
                if use_prefix:
                    prefix = 'udma_'
                else:
                    prefix = ''
                doc_soc.csr.regions[prefix + base_name + suffix] = SoCCSRRegion(
                    base_addr + 0x1000 * udma_index,
                    32,
                    csrs
                )
                udma_index += 1

    add_banks(peripherals, UDMA_BASE)
    # manually add this special case
    add_banks([('PWM', 0)], top_regions['soc_ifsub']['banks']['pwm'] * 0x1000 + top_regions['soc_ifsub']['socregion'].origin)

def check_file(x):
    try:
        if x.is_file():
            return True
        else:
            return False
    except:
        return False

def consolidate_lines(file, skip_directives = True):
    with open(file, "r", encoding='utf-8') as sv_file:
        if True:
            condensed = ''
            multi_line = ''
            trigger = False
            for line in sv_file.readlines():
                line = remove_comments(line.strip()).lstrip()
                if line.startswith("`") and skip_directives:
                    continue

                # handle a case where there is a typo in PX's code and he doesn't start a `define'd keyword on a newline after an end in udma subsystem
                if skip_directives is False:
                    if "`" in line and not line.startswith("`"):
                        line = line.replace("`", "\n`")

                if 'apb_' in line or 'cfg_data_o' in line:
                    trigger = True

                if trigger:
                    if line.strip().endswith(';') or line.strip().endswith('module') or line.strip().endswith(':') or 'case' in line:
                        # condense and add as a single line
                        multi_line += ' ' + line
                        condensed += multi_line
                        condensed += '\n'
                        multi_line = ''
                        trigger = False
                    else:
                        multi_line += line
                else:
                    condensed += line
                    condensed += '\n'
            return condensed.split('\n')
        else:
            return sv_file.readlines()

def main():
    parser = argparse.ArgumentParser(description="Extract SVD from Daric design")
    parser.add_argument(
        "--path", required=False, help="Path to Daric data", type=str, default=".")
    parser.add_argument(
        "--loglevel", required=False, help="set logging level (INFO/DEBUG/WARNING/ERROR)", type=str, default="INFO",
    )
    parser.add_argument(
        "--outdir", required=False, help="Path to output files", type=str, default="output/"
    )
    args = parser.parse_args()
    numeric_level = getattr(logging, args.loglevel.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError('Invalid log level: %s' % args.loglevel)
    logging.basicConfig(level=numeric_level)

    if not Path(args.path).exists():
        logging.error("Design directory not found. Script should be invoked from project root as python3 ./codegen/daric_to_svd.py!")
        exit(0)

    pp = pprint.PrettyPrinter(indent=2, sort_dicts=False)

    doc_soc = DocSoc()

    versioned_files = {}
    search_path = ['/modules', '/asic_top/rtl']

    for spath in search_path:
        module_path = Path(args.path + spath).glob('**/*')
        module_files = [x for x in module_path if check_file(x)]

        ### file versioning is no longer a thing, now that we're using git
        for file in module_files:
            if file.name.endswith('sv'):
                if not ('testcases' in str(file)):
                    versioned_files[file.stem] = (file, 0)

    # extract the Pulpino files
    pulp_path = Path(args.path + '/ips/udma').glob('**/*')
    pulp_files = [x for x in pulp_path if check_file(x)]
    pulp_reg_files = [x for x in pulp_files if 'reg' in str(x) or 'udma_ctrl' in str(x)]
    pulp_versioned_files = {}
    # add versioned files from the main repo
    for name in versioned_files:
        if 'reg' in name and 'udma' in name:
            pulp_versioned_files[name] = versioned_files[name]
    for p in pulp_reg_files:
        pulp_versioned_files[p.stem] = (str(p), 0)
        versioned_files[p.stem] = (str(p), 0)
    # add the special case of adv_timer_apb_if - this is a PULP ecosystem file but integrated through a one-off interface
    pulp_versioned_files['pwm'] = (Path(args.path + '/ips/apb/apb_adv_timer/rtl/adv_timer_apb_if.sv'), 0)

    logging.info("Using the following sources based on version numbering:")
    for (k, v) in versioned_files.items():
        logging.info('  - {}:{}'.format(k, v))

    # ------- extract the general schema of the code ----------
    schema = {}
    for (_file_root, (file, _version)) in versioned_files.items():
            lines = consolidate_lines(file)
            mod_or_pkg = ''
            multi_line_param = ''
            state = 'IDLE'
            for line in lines:
                if state == 'IDLE':
                    # TODO: handle 'typedef enum' case and extract as localparam
                    if line.lstrip().startswith('module') or line.lstrip().startswith('package'):
                        # names are "dirty" if there isn't a space following the mod or package decl
                        # but in practice the ones we care about are well-formed, so we leave this issue hanging.
                        try:
                            base = line.split()[1].strip()
                            mod_or_pkg = re.split('[\(\)\;\#]', base)[0]
                        except:
                            continue
                        state = 'ACTIVE'
                        if mod_or_pkg not in schema:
                            schema[mod_or_pkg] = {
                                'localparam' : {},
                                'apb_cr' : {},
                                'apb_sr' : {},
                                'apb_fr' : {},
                                'apb_ar' : {},
                                'apb_asr': {},
                                'apb_acr': {},
                                'apb_ac2r': {},
                                'apb_ascr': {},
                                'apb_shfin': {},
                                'apb_buf': {},
                                'apb_sfr': {},
                            }
                elif state == 'ACTIVE':
                    if line.lstrip().startswith('endmodule') or line.lstrip().startswith('endpackage'):
                        state = 'IDLE'
                        mod_or_pkg = ''
                    else:
                        code_line = remove_comments(line.strip()).lstrip()
                        if re.match('^a[ph]b_[csfa2hfinbur]+[rnf]', code_line):
                            code_line = code_line.replace('ahb', 'apb') # generalize the code to AHB as well
                            add_reg(schema, mod_or_pkg, code_line, str(file))
                        elif code_line.startswith('localparam'):
                            # simple one line case
                            if code_line.strip().endswith(';'):
                                extract_localparam(schema, mod_or_pkg, code_line)
                            else:
                                state = 'PARAM'
                                multi_line_param += code_line
                        elif code_line.startswith('parameter'):
                            extract_parameter(schema, mod_or_pkg, code_line)
                        elif code_line.startswith('logic') or code_line.startswith('bit') or code_line.startswith('reg') or code_line.startswith('wire'):
                            extract_bitwidth(schema, mod_or_pkg, code_line)
                elif state == 'PARAM':
                    code_line = remove_comments(line.strip()).lstrip()
                    if code_line.strip().endswith(';'):
                        multi_line_param += code_line
                        extract_localparam(schema, mod_or_pkg, multi_line_param)
                        multi_line_param = ''
                        state = 'ACTIVE'
                    else:
                        multi_line_param += code_line

    # --------- SPECIAL CASE: propgate overrides for UDMA that come all the way from top-level
    # these overrides come from rtl/ifsub/soc_ifsub_v0.2.sv lines 44-51
    schema['udma_sub']['localparam']['N_I2C'] = Expr('4')
    schema['udma_sub']['localparam']['N_SPIS'] = Expr('2')

    # This is a bug, I think, in the parameter extraction code -- but paper over it for now, need to get
    # on with other work.
    if schema['iox']['localparam']['IOC'].eval_result != 96:
        logging.warning(f"Detected error in parameter evaluation, iox IOC is not 96! Overriding...")
        schema['iox']['localparam']['IOC'].eval_result = 96
        schema['iox']['localparam']['IOC'].evaluated = True
        schema['iox']['localparam']['GPIOSFRC'].eval_result = 96 / 16
        schema['iox']['localparam']['GPIOSFRC'].evaluated = True

    # --------- extract SFRCNT from files that contain SFRCNT record ---------
    for (module, leaves) in schema.items():
        sfr_count = 0
        sfr_name = ''
        sfr_module = ''
        sfrcnt_types = [('apb_cr', 'cr'), ('apb_sr', 'sr')]
        for (sfr_rootname, sfr_shortname) in sfrcnt_types:
            for (cr_name, cr_defs) in leaves[sfr_rootname].items():
                if 'params' in cr_defs:
                    if 'SFRCNT' in cr_defs['params']:
                        sfr_count = cr_defs['params']['SFRCNT'].eval(schema, module)
                        if sfr_count is None:
                            # it can take a second pass on eval to fully chase down some expressions :-/
                            sfr_count = cr_defs['params']['SFRCNT'].eval(schema, module)
                        sfr_name = cr_defs['args'][sfr_shortname].eval(schema, module)
                        if type(sfr_name) is int:
                            sfr_name = cr_defs['args'][sfr_shortname].expression.strip()
                        sfr_module = module

                        print(f"Banked SFR found, {sfr_module}:{sfr_name}[{sfr_count}]")
                         # handle special case exception in file naming. I guess some names got 'a' added to them?
                        if sfr_module == 'combohash':
                            sfr_module = 'combohasha'
                        if sfr_module == 'sce_glbsfr':
                            sfr_module = 'sce_glbsfra'
                        (sfr_file, _version) = versioned_files[sfr_module]
                        re_pattern = sfr_name + '\[(.*)\]'
                        sfr_re = re.compile(re_pattern)
                        cr_defs['sfrs'] = {}
                        sfr_f = consolidate_lines(sfr_file)
                        defs_found = False
                        for line in sfr_f:
                            matches = sfr_re.search(line)
                            if matches is not None:
                                sfr_item = matches.group(1)
                                try:
                                    cr_defs['sfrs'][sfr_item] = leaves['localparam'][sfr_item]
                                    defs_found = True
                                except:
                                    pass
                        if defs_found is False:
                            if sfr_count:
                                # include some dummy stand-in defs not based on signal names but just count
                                for i in range(int(sfr_count)):
                                    cr_defs['sfrs'][sfr_name.strip() + str(i)] = i

    # define the top-level regions. This is extracted from the spec directly.
    top_regions = {
        'sce' :
            {
                'socregion' : SoCRegion(
                                origin=0x4002_8000,
                                size=0x8000,
                                mode='rw',
                                cached=False
                            ),
                'banks' : {},
                'display_name' : 'sce',
            },
        'soc_top' :
            {
                'socregion' : SoCRegion(
                            origin=0x4004_0000,
                            size=0x1_0000,
                            mode='rw',
                            cached=False
                        ),
                'banks' : {},
                'display_name' : 'sysctrl',
            },
        'soc_ifsub' :
            {
                'socregion' : SoCRegion(
                            origin=0x5012_0000,
                            size=0x3000,
                            mode='rw',
                            cached=False
                        ),
                'banks' : {},
                'display_name' : 'ifsub',
            },
        'soc_coresub' :
            {
                'socregion' : SoCRegion(
                            origin=0x4001_0000,
                            size=0x1_0000,
                            mode='rw',
                            cached=False
                        ),
                'banks' : {},
                'display_name' : 'coresub',
            },
        'rrc' :
            {
                'socregion' : SoCRegion(
                            origin=0x4000_0000,
                            size=0x1_0000,
                            mode='rw',
                            cached=False
                        ),
                'banks' : {
                    'rrc' : 0,
                },
                'display_name' : 'rrc',
            },
        'secsub' :
            {
                'socregion' : SoCRegion(
                            origin=0x4005_0000,
                            size=0x1_0000,
                            mode='rw',
                            cached=False
                        ),
                'banks' : {},
                'display_name' : 'secsub',
            },
        # The address in soc_ifsub needs to be changed here as well!!!
        'bio_bdma' :
            {
                'socregion' : SoCRegion(
                            origin=0x5012_4000,
                            size=0x1000,
                            mode='rw',
                            cached=False
                        ),
                'banks' : {},
                'display_name' : 'bio_bdma',
            },
        'ao_top' :
            {
                'socregion' : SoCRegion(
                            origin=0x4006_0000,
                            size=0x1_0000,
                            mode='rw',
                            cached=False
                        ),
                'banks' : {},
                'display_name' : 'ao',
            },
        'aoperi' :
            {
                'socregion' : SoCRegion(
                            origin=0x4006_1000,
                            size=0x3000,
                            mode='rw',
                            cached=False
                        ),
                'banks' : {},
                'display_name' : 'aoperi',
            },
        # Not included in NTO
        # 'sddc' :
        #     {
        #         'socregion' : SoCRegion(
        #                     origin=0x5014_0000,
        #                     size=0x1000,
        #                     mode='rw',
        #                     cached=False
        #                 ),
        #         'banks' : {
        #             'sddc' : 0,
        #         },
        #         'display_name' : 'sddc',
        #     },
    }
    # --------- extract bank numbers for each region, so we can fix the addresses of various registers ---------
    for (region, attrs) in top_regions.items():
        (top_file, _version) = versioned_files[region]
        # SCE defines banks by attaching them to an abps mux. Open the top-level file and look for
        # the apbs mux index and infer the region for register banks from that.
        with open(top_file, 'r', encoding='utf-8') as top:
            multi_line_expr = ''
            for line in top:
                code_line = remove_comments(line.strip()).lstrip()
                split_at_semi = code_line.strip().split(';')
                if len(split_at_semi) == 1 and 'endgenerate' not in code_line:
                    multi_line_expr += code_line
                    multi_line_expr += ' '
                else:
                    multi_line_expr += split_at_semi[0]
                    # process the expression
                    multi_line_expr = multi_line_expr.strip()
                    if region == 'sce':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbs\[([0-9]+)\]")
                    elif region == 'soc_top':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbsys\[([0-9]+)\]")
                    elif region == 'soc_ifsub':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbper\[([0-9]+)\]")
                    elif region == 'soc_coresub':
                        apbs_re = re.compile(r"\.apbs(\s*?)\(.*?coresubapbs\[([0-9]+)\]")
                    elif region == 'secsub':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbsec\[([0-9]+)\]")
                    elif region == 'ao_top':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbaos\[([0-9:]+)\]")
                    elif region == 'aoperi':
                        apbs_re = re.compile(r"\.PENABLE(.*?)\(.*?apbs\[([0-9:]+)\]")
                    elif region == 'rrc':
                        apbs_re = re.compile(r"\.ahbs(.*?)\(.*?coreahbmux\[([0-9:]+)\]")
                    elif region == 'rp_pio':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbs\[([0-9]+)\]") # ignored, actually: rp_pio address is explicitly called out
                    elif region == 'bio':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbs\[([0-9]+)\]") # ignored, actually: bio address is explicitly called out
                    elif region == 'bio_bdma':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbs\[([0-9]+)\]") # ignored, actually: bio_bdma address is explicitly called out
                    elif region == 'sysctrl':
                        apbs_re = re.compile(r"\.apbs(.*?)\(.*?apbs\[([0-9]+)\]") # ignored, actually: address is explicitly called out
                    else:
                        print(f"unknown region! {region}")
                        exit(0)
                    # print(multi_line_expr)
                    matches = apbs_re.search(multi_line_expr)
                    if matches is not None:
                        # print(multi_line_expr)
                        bank = matches.group(2)
                        if '#' in multi_line_expr:
                            name = multi_line_expr.split('#')[0].rstrip().split(' ')[-1]
                        else:
                            name = multi_line_expr.split(' ')[0].split('#')[0]
                        # print(f'{name} is at {bank}')
                        if ':' in bank:
                            rng = bank.split(':')
                            for (i, j) in enumerate(range(int(rng[0]), int(rng[1]) + 1)):
                                attrs['banks'][name + str(i)] = j
                        else:
                            attrs['banks'][name] = int(bank)
                    # now reset the search
                    if len(split_at_semi) > 1:
                        multi_line_expr = split_at_semi[1]
                    else:
                        multi_line_expr = ''

        # --------- SPECIAL CASES - each module has quirks
        if region == 'sce':
            # check `generate` for SFR ar inside sce_glbsfr
            module = 'sce_glbsfr'
            leaves = schema[module]
            for (sr_name, sr_defs) in leaves['apb_sr'].items():
                if 'params' in sr_defs:
                    if 'SFRCNT' in sr_defs['params']:
                        sfr_count = sr_defs['params']['SFRCNT'].eval(schema, module)
                        sfr_name = sr_defs['args']['sr'].eval(schema, module)
                        sfr_module = module
                        if sr_name != 'sfr_ffcnt':
                            logging.error("Manual fixup for sfr_ffclr has failed. Check code carefully!")
                        sr_defs['sfrs'] = {}
                        for i in range(int(sfr_count)):
                            sr_defs['sfrs'][sfr_name + str(i)] = i

        elif region == 'soc_top':
            pass

        elif region == 'soc_coresub':
            # insert a placeholder entry for the PL230 registers, which use a different description format
            #attrs['banks']['pl230'] = 17
            #schema['pl230'] = {}
            # schema['pl230']['apb_cr'] = {
            #     'pl230' :
            #     {
            #         'params' : {'A' : Expr('0'), 'DW': Expr('32')},
            #         'args' : {'cr': Expr('placeholder')},
            #     }
            # }
            # schema['pl230']['localparam'] = {}
            pass

        elif region == 'ao_peri':
            # TODO: make manual descriptions of these peripherals
            logging.info("Rtc, cmsdk_apb_watchdog, and apb_timer_unit require manual SVD merge")

        print(f"{region} register banks discovered:")
        pp.pprint(attrs['banks'])

    print("done parsing")
    # ---------- evaluate all expressions in the schema tree
    for (module, leaves) in schema.items():
        if module == 'udma_sub':
            continue # HACK: skip evaluating this module because it breaks recursion limit. However, no SFRs seem to be in here.
        eval_tree(leaves, schema, module, level=2, do_print=False)

    # ---------- Go through each region and extract the CSRs
    bio_aliases = {}
    orphans = {}
    for (region, attrs) in top_regions.items():
        doc_soc.mem_regions[attrs['display_name']] = attrs['socregion']
        for (module, leaves) in schema.items():
            if region == 'soc_ifsub' and module == 'bio_bdma':
                print('here')
            create_csrs(doc_soc, schema, module, attrs['banks'], orphans, ctrl_offset=doc_soc.mem_regions[attrs['display_name']].origin, bio_aliases=bio_aliases)
    for name, count in orphans.items():
        if count >= len(top_regions):
            # was orphaned in as many times as there were regions -- nobody adopted it
            logging.warning(f"Orphaned bank: {name}")

    # --------- process the subsystems derived from PULP code
    schema['udma_sub']['localparam']['PER_ID_UART'] # lookup path for data on IDs for mapping regions
    process_pulp(doc_soc, pulp_versioned_files, schema, args.path + '/', top_regions)

    # ---------- SPECIAL CASE - extract SCERAM offsets from source code
    sceram_origin = 0x4002_0000
    for k in schema['scedma_pkg']['localparam'].keys():
        if k.startswith('SEG_'):
            suffix = k.split('_')[1]
            doc_soc.mem_regions[k] = SoCRegion(
                origin=sceram_origin + int(schema['scedma_pkg']['localparam']['SEGADDR_' + suffix].eval_result) * 4,
                size=int(schema['scedma_pkg']['localparam']['SEGSIZE_' + suffix].eval_result) * 4,
                mode='rw',
                cached=False
            )
    # ---------- SPECIAL CASE - add ifsub placeholder regions
    doc_soc.mem_regions['ifram0'] = SoCRegion(
        origin=0x5000_0000,
        size=0x2_0000,
        mode='rw', cached=False
    )
    doc_soc.mem_regions['ifram1'] = SoCRegion(
        origin=0x5002_0000,
        size=0x2_0000,
        mode='rw', cached=False
    )
    doc_soc.mem_regions['null'] = SoCRegion(
        origin=0x5004_0000,
        size=0x1_0000,
        mode='rw', cached=False
    )
    doc_soc.mem_regions['udma'] = SoCRegion(
        origin=0x5010_0000,
        size=0x2_0000,
        mode='rw', cached=False
    )
    doc_soc.mem_regions['udp'] = SoCRegion(
        origin=0x5012_2000,
        size=0x1000,
        mode='rw', cached=False
    )
    doc_soc.mem_regions['sddc_dat'] = SoCRegion(
        origin=0x5014_0000,
        size=0x1_0000,
        mode='rw', cached=False
    )
    doc_soc.mem_regions['udc'] = SoCRegion(
        origin=0x5020_0000,
        size=0x1_0000,
        mode='rw', cached=False
    )
    # ---------- SPECIAL CASE - add core memory regions
    doc_soc.mem_regions['sram'] = SoCRegion(
        origin=0x6100_0000,
        size=1024*1024 * 2,
        mode='rw', cached=True
    )
    doc_soc.mem_regions['reram'] = SoCRegion(
        origin=0x6000_0000,
        size=1024*1024 * 4,
        mode='rw', cached=True
    )
    doc_soc.mem_regions['xip'] = SoCRegion(
        origin=0x7000_0000,
        size=1024*1024 * 64, # can be up to 128M in size, revised down to save RPT tracking space
        mode='rw', cached=True
    )
    # ---------- SPECIAL CASE - add PL230 memory region
    doc_soc.mem_regions['pl230'] = SoCRegion(
        origin=0x4001_1000,
        size=0x1000,
        mode='rw', cached=False
    )
    doc_soc.mem_regions['mdma'] = SoCRegion(
        origin=0x4001_2000,
        size=0x1000,
        mode='rw', cached=False
    )
    doc_soc.mem_regions['mbox_apb'] = SoCRegion(
        origin=0x4001_3000,
        size=0x1000,
        mode='rw', cached=False
    )
    # ---------- SPECIAL CASE - add I/O regions
    doc_soc.mem_regions['iox'] = SoCRegion(
        origin=0x5012_F000,
        size=0x1000,
        mode='rw', cached=False
    )
    # ---------- SPECIAL CASE - add BIO memory
    for i in range(4):
        doc_soc.mem_regions[f'bio_imem{i}'] = SoCRegion(
            origin=0x5012_5000 + i * 0x1000,
            size=0x1000,
            mode='rw', cached=False
        )
    # ---------- SPECIAL CASE - add BIO FIFO Aliases
    for i in range(4):
        doc_soc.mem_regions[f'bio_fifo{i}'] = SoCRegion(
            origin=0x5012_5000 + 0x4000 + i * 0x1000,
            size=0x1000,
            mode='rw', cached=False
        )
    # copy the aliased registers - feeling a bit lazy, so just hard-coding this now.
    for i in range(4):
        csrs = []
        for (n, name) in bio_aliases.items():
            # patch up the complicated generate expression. totally relies on the code formatting being
            # identical to this search string :-O
            if type(n) == str:
                if "'h10" in n:
                    n = 0x10+4*i
                elif "'h20" in n:
                    n = 0x20+4*i
            index = n / 4
            # find the CSR to copy in the bio-bdma regions list
            for csr in doc_soc.csr.regions['bio_bdma'].obj:
                if csr.n == index:
                    csrs += [csr]
                    break
        doc_soc.csr.regions[f'bio_fifo{i}'] = SoCCSRRegion(
            0x5012_5000 + 0x4000 + i * 0x1000,
            32,
            csrs
        )

    # ---------- boilerplate tail to convert the extracted database into Rust code
    # sort the CSR objects according to their 'n' so they appear in the correct locations in the generated files
    from litex.soc.interconnect.csr import _sort_gathered_items
    from litex.soc.interconnect.csr import CSR
    for region in doc_soc.csr.regions.values():
        csr_list = []
        unsorted_csrs = region.obj
        # find max n
        n = 0
        for item in unsorted_csrs:
            if item.n > n:
                n = int(item.n)
        # build a list of "reserved" CSRs
        for i in range(n+1):
            csr_list += [CSR(name=f"reserved{i}")]
        # displace the reserved items with allocated items
        for item in unsorted_csrs:
            csr_list[int(item.n)] = item
        # convert to dictionary
        region.obj = csr_list

    # generate SVD
    with open(args.outdir + 'bao1x_peri.svd', 'w') as svd_f:
        svd = get_csr_svd(doc_soc, vendor="baochip", name="soc", description="Baochip-1x SoC")
        svd = patch_pl230(svd, doc_soc.mem_regions['pl230'].origin)
        svd_f.write(svd)

    # generate C header
    with open(args.outdir + 'bao1x_peri.h', 'w') as header_f:
        reg_header = get_csr_header(doc_soc.csr.regions, doc_soc.constants)
        header_f.write(reg_header)
        mem_header = get_mem_header(doc_soc.mem_regions)
        header_f.write(mem_header)
        const_header = get_soc_header(doc_soc.constants)
        header_f.write(const_header)

    # generate Rust test file
    with open(args.outdir + 'apb_check.rs', 'w') as rust_f:
        generate_rust_test(doc_soc, rust_f)

    subprocess.run(['cargo', 'run', str('../' + args.outdir + 'bao1x_peri.svd'), str('../' + args.outdir + 'bao1x_peri.rs')], cwd=Path(args.outdir) / '../svd2utra')

    # generate the C CMSIS file. Requires 'svdconv' which, unfortunately, is not open source but it is freely
    # downloadable (see https://arm-software.github.io/CMSIS_5/SVD/html/svd_SVDConv_pg.html or https://developer.arm.com/documentation/107778/5-43-0/MDK-Version-5-38a)
    if shutil.which("svdconv"):
        subprocess.run(['svdconv', '-o', 'c', '--generate=header', '--fields=struct', 'bao1x_peri.svd'], cwd=Path(args.outdir))

    doc_dir = args.outdir + 'doc/'
    generate_docs(doc_soc, doc_dir, project_name="Baochip-1x SoC", author="Baochip, Inc.")
    subprocess.run(['sphinx-build', '-M', 'html', doc_dir, doc_dir + '/_build'])

if __name__ == "__main__":
    main()
    exit(0)

# just for documentation, no other purpose.
# Note that all leaf arguments are now expected to be of type Expr(), unlike what is shown here.
module_schema = {
    'aes' : {
        'localparam' : {
            'AF_ENC': Expr('1'),
            'AF_DEC': Expr('2'),
            # other params
            'PTRID_IV' : 0,
            'PTRID_AKEY' : 0,
        },
        'apb_cr' : {
            'sfr_crfunc' : {
                'params' : {
                    'A' : 0x0,
                    'DW' : 8,
                },
                'args' : {
                    'cr' : 'cr_func',
                    'prdata32' : '',
                }
            },
            'sfr_segptr' : {
                'params' : {
                    'A' : 0x30,
                    'DW' : ['scedma_pkg', 'AW'], # paths are turned into lists
                    'SFRCNT': 4,
                },
                'cr' : 'cr_segptrstart',
                'prdata32' : '',
            }
        },
        # other apb types
        # ...
        # sfr_bank is an entry for banked SFR tables. This is made every time a 'SFRCNT' record is encountered, and the key is the corresponding 'cr' name
        'sfr_bank' : {
            'cr_segptrstart' : {
                ['PTRID_AKEY', 'PTRID_AIB', 'PTRID_IV', 'PTRID_AOB']
            }
        }
    },
    'scedma_pkg' : {
        'localparam' : {
            'SEGID_LKEY', Expr('0x0'),
            'SEGID_KEY', Expr("SEGID_LKEY + 'd1"),
        }
    }
}