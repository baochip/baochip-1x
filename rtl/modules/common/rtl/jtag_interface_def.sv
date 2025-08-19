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

`ifndef JTAG_INTERFACE_DEFINE

interface jtagif ();
 	wire tdi  ;
 	wire tdo  ;
 	wire tms  ;
 	wire tck  ;
 	wire trst ;

  modport master ( 
    output  tdi,
    input   tdo,
    output  tms,
    output  tck,
    output  trst
    );

  modport slave ( 
    input  tdi,
    output tdo,
    input  tms,
    input  tck,
    input  trst
    );

endinterface


module jtagm_null ( jtagif.master jtagm);
	assign jtagm.tdi = '0;
	assign jtagm.tms = '0;
	assign jtagm.tck = '0;
	assign jtagm.trst = '1;
endmodule

module jtags_null ( jtagif.slave jtags);
	assign jtags.tdo = 0;
endmodule

module jtag2io ( 
    input logic jtagen,
    ioif.drive io_JTCK,
    ioif.drive io_JTMS,
    ioif.drive io_JTDI,
    ioif.drive io_JTDO,
    ioif.drive io_JTRST,
    jtagif.master jtagm
);

    assign jtagm.tck = io_JTCK.pi & jtagen;
    assign io_JTCK.po = '0;
    assign io_JTCK.oe = '0;
    assign io_JTCK.pu = '1;

    assign jtagm.tms = io_JTMS.pi & jtagen;
    assign io_JTMS.po = '0;
    assign io_JTMS.oe = '0;
    assign io_JTMS.pu = '1;

    assign jtagm.tdi = io_JTDI.pi & jtagen;
    assign io_JTDI.po = '0;
    assign io_JTDI.oe = '0;
    assign io_JTDI.pu = '1;

    assign jtagm.trst = io_JTRST.pi & jtagen;
    assign io_JTRST.po = '0;
    assign io_JTRST.oe = '0;
    assign io_JTRST.pu = '1;

    assign io_JTRST.po = jtagm.tdo & jtagen;
    assign io_JTRST.oe = jtagen;
    assign io_JTRST.pu = '1;

endmodule




module dummytb_jtagif ();

	jtagif thejtag();

	jtagm_null u0(.jtagm(thejtag));
	jtags_null u1(.jtags(thejtag));

    logic jtagen;
    ioif io_JTCK();
    ioif io_JTMS();
    ioif io_JTDI();
    ioif io_JTDO();
    ioif io_JTRST();
    jtagif jtagm();

    jtag2io u2(.*);

endmodule



`endif //`ifndef JTAG_INTERFACE_DEFINE

`define JTAG_INTERFACE_DEFINE
