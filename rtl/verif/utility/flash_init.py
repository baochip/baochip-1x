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

# Parameters
output_file = "memory.hex"
start_address = 0x1000
initial_value = 0xface_8000
num_zeros = start_address
increment_pattern_count = 0x1000

# Generate the hex file
with open(output_file, "w") as f:
    # Write 0x1000 bytes of zeros
    for addr in range(0, num_zeros, 4):
        f.write("00 00 00 00\n")

    # Write incrementing pattern in little-endian format
    for i in range(increment_pattern_count):
        value = initial_value + i
        # Convert to little-endian
        bytes_le = [value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF]
        f.write(" ".join(f"{byte:02X}" for byte in bytes_le) + "\n")

print(f"Hex file '{output_file}' generated successfully!")
