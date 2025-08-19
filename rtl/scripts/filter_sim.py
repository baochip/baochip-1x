#!/usr/bin/env python3
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


import sys
import threading
from queue import Queue
import signal
import os

# Define the list of key phrases to suppress
SUPPRESS_PHRASES = [
    "contention: write B partially, read A partially",
    "contention: write B succeeds, read A fails",
]

stop_filtering = threading.Event()

def should_suppress(line):
    """Check if the line contains any of the suppress phrases."""
    return any(phrase in line for phrase in SUPPRESS_PHRASES)

def process_stream(input_stream, output_stream, filtered_file, queue):
    """Process a stream (stdin or stderr), filter lines, and send to output or log."""
    try:
        for line in input_stream:
            if stop_filtering.is_set():
                break
            if should_suppress(line):
                filtered_file.write(line)
            else:
                queue.put(line)
        queue.put(None)  # Signal that the stream has ended
    except BrokenPipeError:
        pass

def write_stream(queue, output_stream):
    """Write lines from the queue to the output stream."""
    while True:
        line = queue.get()
        if line is None:  # End of stream
            break
        output_stream.write(line)
        output_stream.flush()

def handle_interrupt(signal_num, frame):
    """Handle SIGINT (Control+C) and forward it to the originating process."""
    stop_filtering.set()  # Stop filtering
    os.kill(os.getpid(), signal.SIGINT)  # Re-emit the signal to terminate

def open_log_file():
    """Try to open the log file in the preferred location, with fallback."""
    preferred_path = "sim/filtered-warnings.log"
    fallback_path = "filtered-warnings.log"
    
    try:
        os.makedirs(os.path.dirname(preferred_path), exist_ok=True)
        return open(preferred_path, "w")
    except (IOError, OSError):
        print(f"Warning: Could not open {preferred_path}, using {fallback_path} instead.", file=sys.stderr)
        return open(fallback_path, "w")

def main():
    # Queue for inter-thread communication
    stdout_queue = Queue()

    # Set up signal handler
    signal.signal(signal.SIGINT, handle_interrupt)

    # Open the filtered log file
    filtered_file = open_log_file()

    with filtered_file:
        # Start threads for processing stdin
        stdin_thread = threading.Thread(
            target=process_stream, args=(sys.stdin, sys.stdout, filtered_file, stdout_queue)
        )
        stdin_thread.start()

        # Write processed lines to stdout
        try:
            write_stream(stdout_queue, sys.stdout)
        except BrokenPipeError:
            pass

        # Wait for the stdin thread to complete
        stdin_thread.join()

if __name__ == "__main__":
    main()
