#!/usr/bin/env python3

import argparse
import curses
from curses.textpad import Textbox, rectangle
import socket
import select
import time

def main(stdscr):
    # The GTKwave branch is at https://github.com/buncram/gtkwave/commits/udp-send
    parser = argparse.ArgumentParser(description="Daemon that listens to a patched GTKWave to display code disassembly listings")
    parser.add_argument(
        "--file", required=False, help="The file to zoom around", type=str, default="./listings/load.lst"
    )
    parser.add_argument(
        "--kernel", required=False, help="The kernel to zoom around", type=str, default="../listings/xous-kernel.lst"
    )
    parser.add_argument(
        "--port", required=False, help="The port to listen on", type=int, default=6502
    )
    args = parser.parse_args()

    curses.noecho()
    curses.cbreak()
    stdscr.keypad(True)
    stdscr.nodelay(True)

    udp_socket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    udp_socket.bind(("127.0.0.1", args.port))

    files = {}
    with open(args.file, 'r') as file_handle:
        text = file_handle.readlines()
        files['user'] = text

    with open(args.kernel, 'r') as kernel_handle:
        kernel = kernel_handle.readlines()
        files['kernel'] = kernel

    rows, cols = stdscr.getmaxyx()

    text_offset = 0
    stdscr.addstr(0, 0, "listening")
    stdscr.refresh()
    time.sleep(1)

    while True:
        readable, _writeable, _exceptional = select.select([udp_socket], [], [], 0.1)
        if len(readable) > 0:
            data = readable[0].recv(64)
            if data[0] == 2: # value type
                strlen = data[1]
                string = data[2:2+strlen].decode('utf-8')
                try:
                    offset = int(string, 16)
                    if offset >= 0xfd00_0000:
                        region = 'kernel'
                    else:
                        region = 'user'
                    string = hex(offset).lstrip('0x')
                except ValueError:
                    pass

                text = files[region]
                # now find the line number that contains this string
                for index, line in enumerate(text):
                    if line.lower().lstrip().startswith(string.lower()):
                        text_offset = index
                        break
                # center the line number on the screen
                if text_offset > rows // 2:
                    start_line = text_offset - rows // 2
                else:
                    start_line = 0

                stdscr.clear()
                for i in range(rows - 1):
                    if start_line + i == text_offset:
                        if start_line + i < len(text):
                            try:
                                stdscr.addstr(i, 0, text[start_line + i].rstrip(), curses.A_REVERSE)
                            except:
                                pass
                    else:
                        if start_line + i < len(text):
                            try:
                                stdscr.addstr(i, 0, text[start_line + i].rstrip())
                            except:
                                pass
                stdscr.addstr(rows - 1, 0, "Region: {}".format(region), curses.A_REVERSE)

        stdscr.refresh()
        try:
            key = stdscr.getkey()
            if key == 'q':
                break
        except:
            pass

if __name__ == "__main__":
    stdscr = curses.initscr()
    main(stdscr)

    stdscr.nodelay(False)
    curses.nocbreak()
    stdscr.keypad(False)
    curses.echo()
    curses.endwin()
    exit(0)
