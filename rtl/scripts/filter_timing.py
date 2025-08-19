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

import re
from collections import defaultdict
import csv

def extract_timing_violations(file_path):
    violations = defaultdict(int)
    current_entry = None

    with open(file_path, 'r') as file:
        for line in file:
            match = re.match(r'(".*?"), (\d+): Timing violation in (.+)', line)
            if match:
                # Extract the timing violation entry
                file_path, line_number, violation_info = match.groups()
                current_entry = f'{file_path}, {line_number}: Timing violation in {violation_info}'
                violations[current_entry] += 1

    return violations

def main():
    file_path = "sim.log"  # Update with your actual file path
    violations = extract_timing_violations(file_path)
    output_file = "errs.csv"

    with open(output_file, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["Timing Violation Entry", "Count"])  # Header row

        # Print unique violations with their counts
        for entry, count in violations.items():
            if count > 1:
                writer.writerow([entry, f'{count} repeats'])
            else:
                writer.writerow([entry])

if __name__ == "__main__":
    main()
