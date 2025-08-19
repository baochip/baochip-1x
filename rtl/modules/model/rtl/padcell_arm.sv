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

//import pad_pkg::*;


module padcell_io #(
    parameter bit H = '1,
    parameter bit ANA = '0,
    parameter bit TESTPU = '1
)(
    input wire [1:0] rtosns,
    inout wire pad,
    input wire cmsatpg,
    input  wire testpo,
    input  wire testoe,
    output wire testpi,
    input padcfg_arm_t thecfg,
    output wire ai,
    ioif.load   pio
);

    padcfg_arm_t thecfgt;
    padcfg_arm_t thecfg0;
    logic pio_pi, pio_po, pio_oe, pio_pu;

    assign thecfgt.schmsel  = '0 ;
    assign thecfgt.anamode  = '0 ;
    assign thecfgt.slewslow = '0 ;
    assign thecfgt.drvsel   = '0 ;

    assign testpi = cmsatpg & pio_pi;
    assign pio_pu = cmsatpg ? TESTPU : pio.pu;
    assign pio_oe = cmsatpg ? testoe : pio.oe;
    assign pio_po = cmsatpg ? testpo : pio.po;


    assign thecfg0 = cmsatpg ? thecfgt : thecfg;


    `ifdef FPGA
        assign pad = pio.oe ? pio.po : 1'bZ;
        assign pio.pi = pad;
//        PULLUP pu ( pad );
    `else

    assign pio.pi = cmsatpg ? 1'b1 : pio_pi;

    generate
        if( ~ANA && H )begin:ghd
            PBIDIR_33_33_FS_DR_H p(
                .PAD    (pad),
                .Y      (pio_pi),
                .IE     ('1),
                .IS     (thecfg0.schmsel),
                .PE     (pio_pu),
                .PS     ('1),
                .A      (pio_po),
                .OE     (pio_oe),
                .DS0    (thecfg0.drvsel[0]),
                .DS1    (thecfg0.drvsel[1]),
                .SR     (thecfg0.slewslow),
                .PO     (),     //useless
                .POE    ('0),   //useless
                .RTO    (rtosns[1]),
                .SNS    (rtosns[0])
             );
        end
        if( ~ANA && ~H ) begin:gvd
            PBIDIR_33_33_FS_DR_V p(
                .PAD    (pad),
                .Y      (pio_pi),
                .IE     ('1),
                .IS     (thecfg0.schmsel),
                .PE     (pio_pu),
                .PS     ('1),
                .A      (pio_po),
                .OE     (pio_oe),
                .DS0    (thecfg0.drvsel[0]),
                .DS1    (thecfg0.drvsel[1]),
                .SR     (thecfg0.slewslow),
                .PO     (),     //useless
                .POE    ('0),   //useless
                .RTO    (rtosns[1]),
                .SNS    (rtosns[0])
             );
        end
        if( ANA && H )begin:gha
            PBIDIRANAC_33_50_FS_DR_H p(
                .PAD    (pad),
                .Y      (pio_pi),
                .IE     ('1),
                .IS     (thecfg0.schmsel),
                .PE     (pio_pu),
                .PS     ('1),
                .A      (pio_po),
                .OE     (pio_oe),
                .DS0    (thecfg0.drvsel[0]),
                .DS1    (thecfg0.drvsel[1]),
                .SR     (thecfg0.slewslow),
                .MODE   (thecfg0.anamode),
                .Y_IOV  (ai),
                .PO     (),     //useless
                .POE    ('0),   //useless
                .RTO    (rtosns[1]),
                .SNS    (rtosns[0])
             );
        end
        if( ANA && ~H )begin:gva
            PBIDIRANAC_33_50_FS_DR_V p(
                .PAD    (pad),
                .Y      (pio_pi),
                .IE     ('1),
                .IS     (thecfg0.schmsel),
                .PE     (pio_pu),
                .PS     ('1),
                .A      (pio_po),
                .OE     (pio_oe),
                .DS0    (thecfg0.drvsel[0]),
                .DS1    (thecfg0.drvsel[1]),
                .SR     (thecfg0.slewslow),
                .MODE   (thecfg0.anamode),
                .Y_IOV  (ai),
                .PO     (),     //useless
                .POE    ('0),   //useless
                .RTO    (rtosns[1]),
                .SNS    (rtosns[0])
             );
        end
    endgenerate
    `endif

endmodule



module padcell_i #(
    parameter pu = 1,
    parameter pd = 0,
    parameter H = 1
)(
    input wire [1:0] rtosns,
    input wire pad,
    input padcfg_arm_t thecfg,
    output logic pi
);

    `ifdef FPGA
        assign pi = pad;
        /*
    generate
        if(pu) begin: genpu
            PULLUP  pu ( pad );
        end
        else begin : genpd
            PULLDOWN pd ( pad );
        end
    endgenerate
    */
    `else

    generate
        if(H)begin:gh
            PINCRS_33_33_NT_DR_H p(
                .PAD    (pad),
                .Y      (pi),
                .PO     (),
                .IE     ('1),
                .IS     (thecfg.schmsel),
                .POE    ('0),
                .PE     (pu[0]|pd[0]),
                .PS     (pu[0]),
                .RTO    (rtosns[1]),
                .SNS    (rtosns[0])
             );
        end
        else begin:gv
            PINCRS_33_33_NT_DR_V p(
                .PAD    (pad),
                .Y      (pi),
                .PO     (),
                .IE     ('1),
                .IS     (thecfg.schmsel),
                .POE    ('0),
                .PE     (pu[0]|pd[0]),
                .PS     (pu[0]),
                .RTO    (rtosns[1]),
                .SNS    (rtosns[0])
             );
        end
    endgenerate

    `endif

endmodule

module padcell_o #(
    parameter pu = 1,
    parameter H = 1
)(
    input wire [1:0] rtosns,
    input wire cmsatpg,
    output wire pad,
    input  padcfg_arm_t thecfg,
    input  logic po
);

//    assign thecfg.schmsel = '0;
//    assign thecfg.anamode = '0;
//    assign thecfg.slewslow = '0;
//    assign thecfg.drvsel = '0;

    ioif pio();
    assign pio.po = po;
    assign pio.pu = '1;
    assign pio.oe = '1;

    padcell_io #(.H(H))p(

        .cmsatpg,
        .testpo('0),
        .testoe('0),
        .testpi(),
        .rtosns,
        .pad,
        .thecfg,
        .ai(),
        .pio
    );

endmodule

module padcell_xtal #(
    parameter H    = 1,
    parameter X33k = 0
)(
    input wire [1:0] rtosns,
    input wire padxin,
    inout wire padxout,
    input bit sleep,
    input padcfg_arm_t thecfg,
    output wire pc
);

    `ifdef FPGA
        assign pc = padxin;
    `else
    generate

        if( X33k ) begin: g33k
            if( H )begin:gh
                POSC1_33_33_NT_DR_H p(
                    .CK(pc),
                    .CK_IOV(),
                    .PO(),
                    .PADO(padxout),
                    .PADI(padxin),
                    .E0(~sleep),
                    .POE('0),
                    .RTO(rtosns[1]),
                    .SNS(rtosns[0]),
                    .TE('0),
                    .DS ()
                 );
            end
            else begin:gv
                POSC1_33_33_NT_DR_V p(
                    .CK(pc),
                    .CK_IOV(),
                    .PO(),
                    .PADO(padxout),
                    .PADI(padxin),
                    .E0(~sleep),
                    .POE('0),
                    .RTO(rtosns[1]),
                    .SNS(rtosns[0]),
                    .TE('0),
                    .DS ()
                 );
            end
        end
        else begin: gelse
            if( H )begin:gh
                POSCP_33_33_NT_DR_H p(
                    .CK(pc),
                    .CK_IOV(),
                    .PO(),
                    .PADO(padxout),
                    .PADI(padxin),
                    .E0(~sleep),
                    .POE('0),
                    .SF0(thecfg.drvsel[0]),
                    .SF1(thecfg.drvsel[1]),
                    .RTO(rtosns[1]),
                    .SNS(rtosns[0]),
                    .SP(),
                    .TE('0)
                 );
            end
            else begin:gv
                POSCP_33_33_NT_DR_V p(
                    .CK(pc),
                    .CK_IOV(),
                    .PO(),
                    .PADO(padxout),
                    .PADI(padxin),
                    .E0(~sleep),
                    .POE('0),
                    .SF0(thecfg.drvsel[0]),
                    .SF1(thecfg.drvsel[1]),
                    .RTO(rtosns[1]),
                    .SNS(rtosns[0]),
                    .SP(),
                    .TE('0)
                 );
            end
        end
    endgenerate
    `endif

endmodule



