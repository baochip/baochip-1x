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

from pathlib import Path
import argparse

def process_file(file_path):
    with open(file_path, 'r') as f:
      modified_content = ''
      modified = False

      search_text = [
          '$display("%s contention: write B partially, read A partially in %m at %0t",ASSERT_PREFIX, $time);',
          '$display("%s contention: write B succeeds, read A fails in %m at %0t",ASSERT_PREFIX, $time);'
      ]

      for line in f:
         matched = False
         for text in search_text:
            if text in line:
                modified_content += "`ifndef NOWARN_READUNDERWRITE\n"
                modified_content += line
                modified_content += "`endif\n"
                modified = True
                matched = True
         if not matched:
             modified_content += line

    if modified:
        with open(file_path, 'w') as f:
          f.write(modified_content)
    return modified

def search_and_modify(directory):
    patchlist = [
        'rdram128x22.v',
        'rdram1kx32.v',
        'rdram32x16.v',
        'rdram512x64.v'
    ]
    path = Path(directory)
    for file_path in path.rglob("*.v"):  # Recursively find all .v files
        for patch in patchlist:
            if patch in str(file_path):
                if process_file(file_path):
                    print(f"Modified: {file_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Modify SRAM files to suppress spurious warnings")
    parser.add_argument(
        "--dir", required=True, help="Root directory to start the search", type=str
    )
    args = parser.parse_args()
    
    search_and_modify(args.dir)
