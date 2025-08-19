// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// This documentation and source code is licensed under the CERN Open Hardware
// License Version 2 – Weakly Reciprocal (http://ohwr.org/cernohl; the
// “License”). Your use of any source code herein is governed by the License.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

`include "template.sv"

package sram_pkg;
/*
    parameter AW = 8,
    parameter DW = 32,
    parameter KW = DW,
    parameter PW = DW/8,
    parameter WCNT = 2**AW,
    parameter BWEN = 1'b1 // byte write enable
*/

    typedef struct packed {
        int     AW;
        int     DW;
        int     KW;
        int     PW;
        int     WCNT;

        int     AWX;

        bit     isBWEN;
        bit     isSCMB;
        bit     isPRT;
        int     EVITVL;

    }sramcfg_t;

    localparam sramcfg_t samplecfg = '{
        AW: 10,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 1024,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };

endpackage : sram_pkg
