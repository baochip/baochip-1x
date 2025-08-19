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

`ifndef _IO_INTERFACE_DEFINE

interface ioif();

    wire            po       ;
    wire            oe       ;
    wire            pu       ;
    wire            pi       ;

  modport drive (
    input   pi      ,
    output  po      ,
    output  oe      ,
    output  pu
    );

  modport load(
    input   pu      ,
    input   po      ,
    input   oe      ,
    output  pi
    );

  modport loadin(
    input   pu      ,
    input   po      ,
    input   oe
    );

endinterface


//
// nulls

    module ioifdrv_nulls #(parameter IOC = 1)(ioif.drive ioifdrv [0:IOC-1]);
    genvar i;
    generate
        for ( i = 0; i < IOC; i++) begin: gen0
            assign ioifdrv[i].po = '1;
            assign ioifdrv[i].oe = '0;
            assign ioifdrv[i].pu = '1;
        end
    endgenerate
    endmodule : ioifdrv_nulls


    module ioifld_nulls #(parameter IOC = 1)(ioif.load ioifld [0:IOC-1]);
    genvar i;
    generate
        for ( i = 0; i < IOC; i++) begin: gen0
            assign ioifld[i].pi = '1;
        end
    endgenerate
    endmodule : ioifld_nulls


    module ioifdrv_null (ioif.drive ioifdrv);
            assign ioifdrv.po = '1;
            assign ioifdrv.oe = '0;
            assign ioifdrv.pu = '1;
    endmodule : ioifdrv_null

    module ioifld_null (ioif.load ioifld);
            assign ioifld.pi = '1;
    endmodule : ioifld_null

//
//  trans 2 wire

    module wire2ioif #(
        parameter IOC = 1)
    (
        input logic [IOC-1:0]   ioout,
        input logic [IOC-1:0]  iooe,
        input logic [IOC-1:0]  iopu,
        output logic [IOC-1:0]  ioin,
        ioif.drive ioifdrv [IOC-1:0]
        );

    genvar i;
    generate
        for ( i = 0; i < IOC; i++) begin: gen0
            assign ioifdrv[i].po = ioout[i];
            assign ioifdrv[i].oe = iooe[i];
            assign ioifdrv[i].pu = iopu[i];
            assign ioin[i] = ioifdrv[i].pi;
        end
    endgenerate

    endmodule : wire2ioif


    module wire2ioif_rev #(
        parameter IOC = 1)
    (
        input logic [0:IOC-1] ioout,
        input logic [0:IOC-1]iooe,
        input logic [0:IOC-1]iopu,
        output logic [0:IOC-1]ioin,
        ioif.drive ioifdrv [0:IOC-1]
        );

    genvar i;
    generate
        for ( i = 0; i < IOC; i++) begin: gen0
            assign ioifdrv[i].po = ioout[i];
            assign ioifdrv[i].oe = iooe[i];
            assign ioifdrv[i].pu = iopu[i];
            assign ioin[i] = ioifdrv[i].pi;
        end
    endgenerate

    endmodule : wire2ioif_rev


    module ioif2wire #(
        parameter IOC = 1)
    (
        output logic [0:IOC-1] ioout,
        output logic [0:IOC-1]iooe,
        output logic [0:IOC-1]iopu,
        input logic [0:IOC-1]ioin,
        ioif.load ioifld [0:IOC-1]
        );

    genvar i;
    generate
        for ( i = 0; i < IOC; i++) begin: gen0
            assign ioout[i] = ioifld[i].po;
            assign iooe[i] = ioifld[i].oe;
            assign iopu[i] = ioifld[i].pu;
            assign ioifld[i].pi = ioin[i];
        end
    endgenerate

    endmodule : ioif2wire

    module iothru (
        ioif.load ioload,
        ioif.drive iodrv
    );
        assign iodrv.po = ioload.po;
        assign iodrv.oe = ioload.oe;
        assign iodrv.pu = ioload.pu;
        assign ioload.pi = iodrv.pi;
    endmodule

    module iothrus #(
        parameter IOC = 16
    )
    (
        ioif.load ioload[0:IOC-1],
        ioif.drive iodrv[0:IOC-1]
    );

    genvar i;
    generate
        for ( i = 0; i < IOC; i++) begin: gen0
                iothru u0(.iodrv(iodrv[i]), .ioload(ioload[i]));
        end
    endgenerate
    endmodule : iothrus

    module dummytb_ioif();

        ioif ioload[0:15]();
        ioif iodrv[0:15]();
        logic ioout, iooe, iopu, ioin;
        ioif ioifdrv[0:0](), ioifld[0:0](), iot();
        ioifdrv_nulls u3(ioifdrv);
        ioifld_nulls  u4(ioifld);
        ioifdrv_null u5(iot);
        ioifld_null  u6(iot);
        wire2ioif u1(.*, .ioifdrv(ioifdrv));
        ioif2wire u2(.*, .ioifld(ioifld));
        iothrus u7(.iodrv(iodrv), .ioload(ioload));
    endmodule

    module dummytb_ioif_rev();

        ioif ioload[0:15]();
        ioif iodrv[0:15]();
        logic ioout, iooe, iopu, ioin;
        ioif ioifdrv[0:0](), ioifld[0:0](), iot();
        ioifdrv_nulls u3(ioifdrv);
        ioifld_nulls  u4(ioifld);
        ioifdrv_null u5(iot);
        ioifld_null  u6(iot);
        wire2ioif_rev u1(.*, .ioifdrv(ioifdrv));
        ioif2wire u2(.*, .ioifld(ioifld));
        iothrus u7(.iodrv(iodrv), .ioload(ioload));
    endmodule

package pad_pkg;

    typedef struct packed {
//        bit         pullen    ;
//        bit         pullsel   ;
        bit         schmsel   ;
        bit         anamode   ;
        bit         slewslow  ;
        bit [1:0]   drvsel    ;
    }padcfg_arm_t;


endpackage : pad_pkg

import pad_pkg::*;

`endif //`ifndef _INTERFACE_DEFINE

`define _IO_INTERFACE_DEFINE

