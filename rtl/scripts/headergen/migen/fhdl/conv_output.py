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

from operator import itemgetter


class ConvOutput:
    def __init__(self):
        self.main_source = ""
        self.data_files = dict()

    def set_main_source(self, src):
        self.main_source = src

    def add_data_file(self, filename_base, content):
        filename = filename_base
        i = 1
        while filename in self.data_files:
            parts = filename_base.split(".", maxsplit=1)
            parts[0] += "_" + str(i)
            filename = ".".join(parts)
            i += 1
        self.data_files[filename] = content
        return filename

    def __str__(self):
        r = self.main_source + "\n"
        for filename, content in sorted(self.data_files.items(),
                                        key=itemgetter(0)):
            r += filename + ":\n" + content
        return r

    def write(self, main_filename):
        with open(main_filename, "w") as f:
            f.write(self.main_source)
        for filename, content in self.data_files.items():
            with open(filename, "w") as f:
                f.write(content)
