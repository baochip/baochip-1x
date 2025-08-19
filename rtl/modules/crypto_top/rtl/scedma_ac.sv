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

import scedma_pkg::*;

module scedma_ac #(
    parameter CHNLCNT = scedma_pkg::CHNLACCNT,
    parameter accessrule_t [0:scedma_pkg::SEGCNT-1] ACRULEs = scedma_pkg::ACRULEs
)(
    input   logic                   clk,
    input   logic                   resetn,
    input   logic                   acenable,
    input   logic [31:0][0:7]       nvracrules   ,
    input   chnlreq_t [0:CHNLCNT-1] chnlinreq   ,
    output  chnlres_t [0:CHNLCNT-1] chnlinres   ,
    output  chnlreq_t [0:CHNLCNT-1] chnloutreq  ,
    input   chnlres_t [0:CHNLCNT-1] chnloutres  ,
    output  logic [0:CHNLCNT-1]             acerr
);

    logic [0:CHNLCNT-1][7:0]    chnlinsegid;
    logic [0:CHNLCNT-1]         chnlac;
    logic [0:CHNLCNT-1]         errsr, errsw;
    logic [0:scedma_pkg::SEGCNT-1][0:scedma_pkg::CHNLACCNT-1] chnlacrules;
    logic nvrrule_enable;
    assign nvrrule_enable = (nvracrules[29] == 8'h5a);

generate
    for(genvar i = 0; i < CHNLCNT; i++) begin: genac
        logic chnlacrule;
        assign chnlinsegid[i] = chnlinreq[i].segcfg.segid;
        assign chnlacrule = chnlacrules[chnlinsegid[i]][i] ;
        assign chnlac[i] = acenable ? chnlacrule : '1;

        assign chnloutreq[i].segcfg    = chnlinreq[i].segcfg    ;
        assign chnloutreq[i].segaddr   = chnlinreq[i].segaddr   ;
        assign chnloutreq[i].segptr    = chnlinreq[i].segptr    ;
        assign chnloutreq[i].segrd     = chnlinreq[i].segrd  & chnlac[i]   ;
        assign chnloutreq[i].segwr     = chnlinreq[i].segwr  & chnlac[i]   ;
        assign chnloutreq[i].segwdat   = chnlinreq[i].segwdat   ;
        assign chnloutreq[i].porttype  = chnlinreq[i].porttype  ;

        assign chnlinres[i].segready   = chnlac[i] ? chnloutres[i].segready   : '1 ;
        assign chnlinres[i].segrdat    = chnlac[i] ? chnloutres[i].segrdat    : '0 ;
        assign chnlinres[i].segrdatvld = chnlac[i] ? chnloutres[i].segrdatvld : '1 ;

        `theregrn( errsr[i] ) <= chnloutreq[i].segrd & ~chnlac[i];
        `theregrn( errsw[i] ) <= chnloutreq[i].segwr & ~chnlac[i];
    end

    for (genvar j = 0; j < scedma_pkg::SEGCNT; j++) begin: gacrule
        assign chnlacrules[j] = nvrrule_enable ? nvracrules[j] : ACRULEs[j].accessrule;
    end

endgenerate

    assign acerr = errsr | errsw;

endmodule : scedma_ac
