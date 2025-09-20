#!/usr/bin/env python3

#
# This file is part of LiteX.
#
# Copyright (c) 2015-2020 Florent Kermarrec <florent@enjoy-digital.fr>
# Copyright (c) 2016 Tim 'mithro' Ansell <mithro@mithis.com>
# SPDX-License-Identifier: BSD-2-Clause

import os
import time
import threading
import argparse
import socket

from litex.tools.remote.etherbone import EtherbonePacket, EtherboneRecord
from litex.tools.remote.etherbone import EtherboneReads, EtherboneWrites
from litex.tools.remote.etherbone import EtherboneIPC
from litex.tools.remote.csr_builder import CSRBuilder

# Remote Client ------------------------------------------------------------------------------------

class LocalClient(CSRBuilder):
    def __init__(self, comm, base_address=0, csr_csv=None, csr_data_width=None, debug=False):
        # If csr_csv set to None and local csr.csv file exists, use it.
        if csr_csv is None and os.path.exists("csr.csv"):
            csr_csv = "csr.csv"
        # If valid csr_csv file found, build the CSRs.
        if csr_csv is not None:
            CSRBuilder.__init__(self, self, csr_csv, csr_data_width)
        # Else if csr_data_width set to None, force to csr_data_width 32-bit.
        elif csr_data_width is None:
            csr_data_width = 32
        self.debug        = debug
        self.binded       = False
        self.base_address = base_address if base_address is not None else 0
        self.comm = comm

    def read(self, addr, length=None, burst="incr"):
        datas = []
        if length:
            datas += self.comm.read(addr, length, burst)
        else:
            datas += [self.comm.read(addr, length, burst)]
        if self.debug:
            for i, data in enumerate(datas):
                print("read 0x{:08x} @ 0x{:08x}".format(data, self.base_address + addr + 4*i))
        return datas[0] if length is None else datas

    def write(self, addr, datas):
        self.comm.write(addr, datas)
        if self.debug:
            for i, data in enumerate(datas):
                print("write 0x{:08x} @ 0x{:08x}".format(data, self.base_address + addr + 4*i))

# Utils --------------------------------------------------------------------------------------------
def dump_identifier(bus):
    fpga_identifier = ""

    for i in range(256):
        c = chr(bus.read(bus.bases.identifier_mem + 4*i) & 0xff)
        fpga_identifier += c
        if c == "\0":
            break

    print(fpga_identifier)

def dump_registers(bus, filter=None, binary=False):
    for name, register in bus.regs.__dict__.items():
        if (filter is None) or filter in name:
            register_value = {
                True  : f"{register.read():032b}",
                False : f"{register.read():08x}",
            }[binary]
            print("0x{:08x} : 0x{} {}".format(register.addr, register_value, name))


def read_memory(bus, addr, length):
    for offset in range(length//4):
        print(f"0x{addr + 4*offset:08x} : 0x{bus.read(addr + 4*offset):08x}")

def write_memory(bus, addr, data):
    bus.write(addr, data)

def reg2addr(host, reg):
    if hasattr(host.regs, reg):
        return getattr(host.regs, reg).addr
    else:
        raise ValueError(f"Register {reg} not present, exiting.")

import struct
def bytes_to_int32_list(byte_data):
    # Pad to multiple of 4 bytes
    padded_len = (len(byte_data) + 3) & ~3
    byte_data += b'\x00' * (padded_len - len(byte_data))

    # Unpack as little-endian 32-bit integers
    return list(struct.unpack('<' + 'I' * (len(byte_data) // 4), byte_data))

# Run ----------------------------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="BIO Loader.", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--csr-csv", default="csr.csv",     help="CSR configuration file")
    parser.add_argument("--ident",   action="store_true",   help="Dump SoC identifier.")
    parser.add_argument("--regs",    action="store_true",   help="Dump SoC registers.")
    parser.add_argument("--binary",  action="store_true",   help="Use binary format for displayed values.")
    parser.add_argument("--filter",  default=None,          help="Registers filter (to be used with --regs).")
    parser.add_argument("--read",    default=None,          help="Do a MMAP Read to SoC bus (--read addr/reg).")
    parser.add_argument("--write",   default=None, nargs=2, help="Do a MMAP Write to SoC bus (--write addr/reg data).")
    parser.add_argument("--file",    default=None, nargs=2, metavar=('ADDR', 'FILENAME'), help="[offset] [file] Loads file into offset")
    parser.add_argument("--length",  default="4",           help="MMAP access length.")

    # UART arguments
    parser.add_argument("--uart-port",       default=None,           help="Set UART port.", required=True)
    parser.add_argument("--uart-baudrate",   default=1000000,         help="Set UART baudrate.")
    parser.add_argument("--debug",           action="store_true",    help="Enable debug.")

    args = parser.parse_args()
    from litex.tools.remote.comm_uart import CommUART
    if args.uart_port is None:
        print("Need to specify --uart-port, exiting.")
        exit()
    uart_port = args.uart_port
    uart_baudrate = int(float(args.uart_baudrate))
    print("[CommUART] port: {} / baudrate: {} / ".format(uart_port, uart_baudrate), end="")
    comm = CommUART(uart_port, uart_baudrate, debug=args.debug)
    host = LocalClient(comm, csr_csv=args.csr_csv)
    time.sleep(0.5)

    if args.ident:
        dump_identifier(
            host,
        )

    if args.regs:
        dump_registers(
            host,
            filter  = args.filter,
            binary  = args.binary,
        )

    if args.read:
        try:
           addr = int(args.read, 0)
        except ValueError:
            addr = reg2addr(host, args.read)
        read_memory(
            host,
            addr    = addr,
            length  = int(args.length, 0),
        )

    if args.write:
        try:
           addr = int(args.write[0], 0)
        except ValueError:
            addr = reg2addr(host, args.write[0])
        write_memory(
            host,
            addr    = addr,
            data    = int(args.write[1], 0),
        )

    if args.file:
        addr_str, filename = args.file
        address = int(addr_str, 16)  # Convert hex string to int
        print(f"Address: {address:#x}, File: {filename}")
        with open(filename, 'rb') as f:
            data = f.read()
            words = bytes_to_int32_list(data)
            STEP = 128
            for chunk_index in range(0, len(words), STEP):
                if chunk_index + STEP < len(words):
                    end_index = chunk_index + STEP
                else:
                    end_index = len(words)
                write_memory(
                    host,
                    addr    = address + chunk_index * 4,
                    data    = words[chunk_index:end_index],
                )
        comm._flush()
        time.sleep(0.5)
        write_memory(host, reg2addr(host, "ctrl_reset"), 1)

if __name__ == "__main__":
    main()
