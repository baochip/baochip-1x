#!/bin/python3
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

"""
"""


import struct
import copy

"""
    Bit assignments for ACRAM:

    assign datacfg = haddr_reg[5] ? acram_rdata[63:32] : acram_rdata[31:0];
    assign keycfg = haddr_reg[5] ? acram_rdata[63:32] : acram_rdata[31:0];
    assign acram_addr = ( brfsm == 4 ) ? {bridx_acv,acram_idx} :
                            acram_wrbusy ? {haddr_reg[13:5],acram_idx} :        //write acram, when bist read initial and amba write configure to rram. 
                            acram_rdbusy ? haddr_reg[16:6] : 11'h0;             //read acram, when axi access data/key region, look-up-table for access control.
    // keysel & datasel is sensitive to [16:6]

    assign core_rd_dis_k = keycfg[0]; // cpu rd disable in not machine mode
    assign core_wr_dis_k = keycfg[1]; // cpu wr disable in not machine mode
    assign sce_rd_dis_k = keycfg[2];
    assign sce_wr_dis_k = keycfg[3];
    assign keytype_k = keycfg[15:8];
    assign userid_k = keycfg[23:16]; // matches coreuser
    assign akeyid = keycfg[27:24];

    assign core_rd_dis_d = datacfg[0]; // cpu rd disable in not machine mode
    assign core_wr_dis_d = datacfg[1]; // cpu wr disable in not machine mode
    assign sce_rd_dis_d = datacfg[2];
    assign sce_wr_dis_d = datacfg[3];
    assign keytype_d = datacfg[15:8];
    assign userid_d = datacfg[23:16]; // matches coreuser
    assign wrmode_d = datacfg[24]; // when cleared, should block all writing on a data region

    ACRAM is 2048 rows x 64 bits wide
    This is flattened to RRAM at 512 rows x 256 bits wide

    Data region is from 0x603E_0000 : 0x603F_0000
      - Data regions are divided into the 2048 consecutive 32-byte (256-bit) regions, and are controlled by the first 2048 32-bit entries in ACRAM
    Key region is from 0x603F_0000 : 0x6040_0000
      - Key regions are divided into 2048 consecutive 32-byte (256-bit) regions, and controlled by the next 2048 32-bit entries in ACRAM
"""

key_schema = {
    "core_rd_dis" : False,
    "core_wr_dis" : False,
    "sce_rd_dis" : False,
    "sce_wr_dis" : False,
    "keytype" : 0,
    "userid" : 0,
    "akeyid" : 0,
}

data_schema = {
    "core_rd_dis" : False,
    "core_wr_dis" : False,
    "sce_rd_dis" : False,
    "sce_wr_dis" : False,
    "keytype" : 0,
    "userid" : 0,
    "write_ena" : False,
}

key_access = [copy.deepcopy(key_schema) for _ in range(2048)]
data_access = [copy.deepcopy(data_schema) for _ in range(2048)]

# Test cases:
#   - Four coreuser possibilities
#   - Four read/write access possibilities
#   - Two write enable possibilities
# 4 * 4 * 2 = 32 case combinations

# Generate key cases
for wrena_case in range(2):
    for rw_case in range(4):
        for coreuser_case in range(4):
            # set key access cases - this repeats twice identically
            key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["userid"] = ((1 << (coreuser_case & 0xFF)) << 4)
            if rw_case == 0:
                key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_rd_dis"] = False
                key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_wr_dis"] = False
            elif rw_case == 1:
                key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_rd_dis"] = True
                key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_wr_dis"] = False
            elif rw_case == 2:
                key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_rd_dis"] = False
                key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_wr_dis"] = True
            elif rw_case == 3:
                key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_rd_dis"] = True
                key_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_wr_dis"] = True

            # set data access cases
            data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["userid"] = ((1 << (coreuser_case & 0xFF)) << 4)
            if rw_case == 0:
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_rd_dis"] = False
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_wr_dis"] = False
            elif rw_case == 1:
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_rd_dis"] = True
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_wr_dis"] = False
            elif rw_case == 2:
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_rd_dis"] = False
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_wr_dis"] = True
            elif rw_case == 3:
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_rd_dis"] = True
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["core_wr_dis"] = True
            if wrena_case == 0:
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["write_ena"] = False
            else:
                data_access[coreuser_case + rw_case * 4 + wrena_case * 16]["write_ena"] = True

with open('acram.bin', "wb") as f:
    for case in data_access:
        word = 0
        if case["core_rd_dis"]:
            word |= 1
        if case["core_wr_dis"]:
            word |= 2
        word |= (case["userid"] << 16)
        if case["write_ena"]:
            word |= (1 << 24)
        f.write(struct.pack("<I", word))

    for case in key_access:
        word = 0
        if case["core_rd_dis"]:
            word |= 1
        if case["core_wr_dis"]:
            word |= 2
        word |= (case["userid"] << 16)
        # < is little endian
        # Q means unsigned 64 bit
        # I means unsigned 32 bit
        f.write(struct.pack("<I", word))
