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


project = 'Cramium SoC'
copyright = '2025, Cramium, Inc.'
author = 'Cramium, Inc.'
extensions = [
    'sphinx.ext.autosectionlabel',
    'sphinxcontrib.wavedrom',
]
templates_path = ['_templates']
exclude_patterns = []
offline_skin_js_path = "https://wavedrom.com/skins/default.js"
offline_wavedrom_js_path = "https://wavedrom.com/WaveDrom.js"
html_theme = 'alabaster'
html_static_path = ['_static']
master_doc = 'index'


