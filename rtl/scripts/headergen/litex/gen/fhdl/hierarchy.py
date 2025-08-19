# (c) Copyright 2024 CrossBar, Inc.
#
# SPDX-FileCopyrightText: 2024 CrossBar, Inc.
# SPDX-License-Identifier: BSD-2-Clause
#
# This file may have been modified and is redistributed by CrossBar, Inc.
#
# You may redistribute and modify this documentation under the terms of the
# License. This documentation and source code is distributed WITHOUT ANY EXPRESS
# OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
# PARTICULAR PURPOSE. Please see the License for the specific language governing
# permissions and limitations under the License.

#
# This file is part of LiteX.
#
# This file is Copyright (c) 2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

from migen import *

from litex.gen import *

# LiteX Hierarchy Explorer -------------------------------------------------------------------------

class LiteXHierarchyExplorer:
    tree_ident      = "│    "
    tree_entry      = "└─── "

    def __init__(self, top, depth=None):
        self.top   = top
        self.depth = depth

    def get_tree(self, module, ident=0, with_modules=True, with_instances=True):
        r = ""
        names = set()
        names.add(None)
        # Modules / SubModules.
        for name, mod in module._submodules:
            if name is None:
                n = 0
                while name in names:
                    name = mod.__class__.__name__.lower() + f"_{n}*"
                    n += 1
            names.add(name)
            if with_modules:
                r += f"{self.tree_ident*ident}{self.tree_entry}{colorer(name, 'cyan')} ({mod.__class__.__name__})\n"
            if (self.depth is None) or (ident < self.depth):
                r += self.get_tree(mod, ident + 1)

        # Instances.
        for s in module._fragment.specials:
            if (self.depth is None) or (ident <= self.depth):
                if isinstance(s, Instance):
                    show = with_instances
                    for k, v in module._submodules:
                        if s in v._fragment.specials:
                            show = False
                    if show:
                        r +=  f"{self.tree_ident*ident}{self.tree_entry}{colorer(f'[{s.of}]', 'yellow')}\n"
        return r

    def __repr__(self):
        r = "\n"
        r += f"{colorer(self.top.__class__.__name__, 'underline')}\n"
        r += self.get_tree(self.top)
        r += f"{colorer('* ', 'cyan')}: Generated name.\n"
        r += f"{colorer('[]', 'yellow')}: BlackBox.\n"
        return r
