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

module sync_pulse #(
	parameter REGC = 2,
	parameter REGOUT = 0
	 )(
	input logic 	clka,
	input logic 	resetn,
	input logic 	pulsea,
	input logic 	clkb,
	output logic 	pulseb
);

	 logic toga, pulseb0, pulseb1;
	 logic [REGC:0] togbregs;

`theregfull(clka, resetn, toga, '0) <= toga ^ pulsea;
`theregfull(clkb, resetn, togbregs, '0) <= { togbregs, toga };
assign pulseb0 = togbregs[REGC] ^ togbregs[REGC-1];
`theregfull(clkb, resetn, pulseb1, '0) <= pulseb0;

assign pulseb = REGOUT ? pulseb1 : pulseb0;

endmodule




`ifdef SIMSYNCP

module synctb();

    bit                    clk;
    bit                    resetn;

    bit [4:0] clks,p,s;

    `genclk( clks[0],   10 );   // osc
    `genclk( clks[1],   21 );   // osc
    `genclk( clks[2],   23 );   // osc
    `genclk( clks[3],   31 );   // osc
    `genclk( clks[3],   13 );   // osc

generate
	for (genvar gvi = 0; gvi < 4; gvi++) begin
 		sync_pulse dut(
 			.clka(clks[gvi]),
 			.resetn(resetn),
 			.pulsea(p[gvi]),
 			.clkb(clks[gvi+1]),
 			.pulseb(p[gvi+1])
 			);
    edge_propagator dut2
    (
        .clk_tx_i ( clks[gvi] ),
        .rstn_tx_i( resetn    ),
        .edge_i   ( s[gvi] ),
        .clk_rx_i ( clks[gvi+1] ),
        .rstn_rx_i( resetn    ),
        .edge_o   ( s[gvi+1] )
    );
	end
endgenerate

	assign clk = clks[0];
    assign s[0] = p[0];

   `ifndef NOFSDB
    initial begin 
        #(10 `MS); `maintestend
    `endif 


    bit [7:0] rndnum;
    `thereg( p[0] ) <= p[0] ? '0 : rndnum < 30;
    `thereg( rndnum ) <= $urandom();

    `maintest( synctb, synctb )
        #( 1`US ); #100 resetn = 1;

        #( 10 `MS );
    `maintestend

endmodule


`include "ips/common_cells/src/deprecated/pulp_sync.sv"
`include "ips/common_cells/src/edge_propagator_rx.sv"
`include "ips/common_cells/src/edge_propagator.sv"
`include "ips/common_cells/src/edge_propagator_tx.sv"
`include "ips/common_cells/src/edge_propagator_ack.sv"
`include "ips/common_cells/src/onehot_to_bin.sv"
`include "ips/common_cells/src/deprecated/pulp_sync_wedge.sv"
`include "ips/tech_cells_generic/src/deprecated/pulp_clock_gating_async.sv"
`include "ips/tech_cells_generic/src/deprecated/pulp_clk_cells.sv"
`endif

