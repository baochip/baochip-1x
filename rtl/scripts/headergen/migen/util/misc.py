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

from math import gcd
import collections.abc


def flat_iteration(l):
    for element in l:
        if isinstance(element, collections.abc.Iterable):
            for element2 in flat_iteration(element):
                yield element2
        else:
            yield element


def xdir(obj, return_values=False):
    for attr in dir(obj):
        if attr[:2] != "__" and attr[-2:] != "__":
            if return_values:
                yield attr, getattr(obj, attr)
            else:
                yield attr


def gcd_multiple(numbers):
    l = len(numbers)
    if l == 1:
        return numbers[0]
    else:
        s = l//2
        return gcd(gcd_multiple(numbers[:s]), gcd_multiple(numbers[s:]))
