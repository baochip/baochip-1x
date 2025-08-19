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
//`include "ram_interface_def_v0.2.sv"
module gnrl_sramc
#(
    parameter sram_pkg::sramcfg_t thecfg=sram_pkg::samplecfg
)(

    input logic        		clk,
    input logic       		resetn,
    input logic				cmsatpg,
    input logic				cmsbist,
    input logic				scmben,
    input logic             even,
    input logic [thecfg.KW-1:0]	scmbkey,
    output logic            prerr,
    output logic            verifyerr,

    ramif.slave  			ramslave,
    ramif.master 			rammaster
);

//    localparam DWW = $clog2(DW);
//    localparam WRW = DW/8;

    localparam AW   = thecfg.AW   ; // 8,
    localparam DW   = thecfg.DW   ; // 32,
    localparam KW   = thecfg.KW   ; // DW,
    localparam PW   = thecfg.PW   ; // DW/8,     // parity: 8->1 bit
    localparam WCNT = thecfg.WCNT ; // 2**AW,
    localparam isBWEN = thecfg.isBWEN ; // 1'b1      // byte write enable
    localparam isSCMB = thecfg.isSCMB ; // 1'b1      // byte write enable
    localparam isPRT  = thecfg.isPRT  ; // 1'b1      // byte write enable

    bit                 busrd0, buswr0, busrd, buswr, busreq, verifyrd, verifywr, verifyreq, verifyreqpl1, verifywrpl1, verifyrdpl1;
    bit                 busrdreg, buswrreg;
    bit [AW-1:0]        xaddr, xaddrpl1, verifyaddr;
    bit [DW-1:0]        xwdat0;
    bit [DW/8-1:0]      busstb0, busstb, busstbreg, busstbreg2, ipstb, evstb;
    bit [PW-1:0]        verifywrerrs;
    bit                 verifywrerr, verifyrderr ;

    bit                 evenable, evupdate, evrd, evwr, evreq;
    bit [AW-1:0]        evaddrin, evaddr;

    bit [1:0]           ipstartreg;
    bit                 ipstart, ipstall, ipbusy, ipdone, iprd, ipwr, ipreq;
    bit [AW-1:0]        ipaddr;

    bit [DW+PW-1:0]     xwdat, xrdat, verifydat, ipwdat, iprdatreg;

    bit                 prerr0;
    bit [1:0]           ipdonereg;
    bit                 rammrdpl1;

    genvar gvi;

// addr permutation
// dat enc/dec
// ==

    gnrl_sramc_scramble
    #(
        .thecfg (thecfg)
    )datscmb(
    /*    input logic             */    .clk            (clk),
    /*    input logic             */    .resetn         (resetn),
    /*    input logic [AW-1]      */    .addrin         (ramslave.ramaddr),
    /*    output logic [AW-1]     */    .addrout        (xaddr),
    /*    input logic             */    .scmben         (scmben),
    /*    input logic [KW-1:0]    */    .scmbkey        (scmbkey),
    /*    input  logic [DW-1:0]   */    .wdatin         (xwdat0),
    /*    output logic [DW+PW-1:0]*/    .wdatout        (xwdat),
    /*    input  logic [DW+PW-1:0]*/    .rdatin         (xrdat),
    /*    output logic [DW-1:0]   */    .rdatout        (ramslave.ramrdata),
    /*    output                  */    .prerr          (prerr0)
    );

    `theregrn( prerr ) <= ipdonereg[0] & prerr0 & rammrdpl1;
    assign ramslave.ramready = rammaster.ramready ;
    assign xrdat = rammaster.ramrdata;

    generate
        for(gvi=0; gvi<DW/8; gvi++) begin : genxwdat
//            assign xwdat0[gvi*8+:8] = busstb[gvi] ? ramslave.ramwdata[gvi*8+:8] :  ramslave.ramrdata[gvi*8+:8];
            assign xwdat0[gvi*8+:8] = ramslave.ramwdata[gvi*8+:8] ;
        end
    endgenerate

	assign busrd0  = ramslave.ramcs & ramslave.ramen &  ( ramslave.ramwr == 0 ) & ramslave.ramready;
	assign buswr0  = ramslave.ramcs & ramslave.ramen & ~( ramslave.ramwr == 0 ) & ramslave.ramready;
    assign busstb0 = ramslave.ramcs & ramslave.ramen ? ramslave.ramwr : 0;

    assign { busrd, buswr } = { busrd0, buswr0 };
    assign busreq = busrd | buswr;
    assign busstb = busstb0;

    `theregrn( busrdreg  ) <= rammaster.ramready ? busrd  : busrdreg;
    `theregrn( buswrreg  ) <= rammaster.ramready ? buswr  : buswrreg;
    `theregrn( busstbreg ) <= rammaster.ramready ? busstb : busstbreg;
    `theregrn( busstbreg2 ) <= rammaster.ramready ? busstbreg : busstbreg2;

    `theregrn( xaddrpl1 ) <= rammaster.ramready & busreq ? xaddr : xaddrpl1;

// read/wr verify

    assign verifyrd = busrdreg & ~busreq & rammaster.ramready;
    assign verifywr = buswrreg & ~busreq & rammaster.ramready;

    assign verifyreq = verifyrd | verifywr;

    assign verifyaddr = xaddrpl1;
//    assign verifywdat = xwdatpl1;

    `theregrn( verifyreqpl1 ) <= rammaster.ramready ? verifyreq : verifyreqpl1 ;
    `theregrn( verifywrpl1  ) <= rammaster.ramready ? verifywr  : verifywrpl1  ;
    `theregrn( verifyrdpl1  ) <= rammaster.ramready ? verifyrd  : verifyrdpl1  ;

    `theregrn( verifydat ) <= rammaster.ramready & buswr    ? xwdat :
                              rammaster.ramready & busrdreg ? xrdat : verifydat;

    generate
        for(gvi=0; gvi<DW/8; gvi++) begin : genverify
            `theregrn( verifywrerrs[gvi] ) <= verifywrpl1 & busstbreg2[gvi] & rammaster.ramready & ( xrdat[gvi*9+:9] != verifydat[gvi*9+:9] );
        end
    endgenerate

    `theregrn( verifywrerr ) <= |verifywrerrs;
    `theregrn( verifyrderr ) <= verifyrdpl1 & rammaster.ramready & ( xrdat != verifydat );
    assign verifyerr = verifywrerr | verifyrderr;

// ext read
// ==

    gnrl_sramc_extverify #(
        .thecfg (thecfg)
    )ev(
        .clk,
        .resetn,
        .enable     (evenable   ),
        .update     (evupdate   ),
        .addrin     (evaddrin   ),
        .ramready   (rammaster.ramready     ),
        .ramaddr    (evaddr     ),
        .ramrd      (evrd       ),
        .ramwr      (evwr       )
    );

    assign evenable = ipdone & even;
    assign evupdate = verifyreq;
    assign evaddrin = verifyaddr;
    assign evreq = ( evrd | evwr ) & rammaster.ramready & ipdone;

//  initial parity
//  ==
    logic iprddp;

    `theregrn( ipstartreg ) <= ( ipstartreg == 3 ) ? ipstartreg : ipstartreg + 1;
    assign ipstart = ( ipstartreg == 2 );
    assign ipstall = busreq | verifyreq;// | ~rammaster.ramready;

    gnrl_sramc_initprt #(
        .thecfg (thecfg)
    )ip(
        .clk,
        .resetn,
        .start      (ipstart    ),
        .stall      (ipstall    ),
        .busy       (ipbusy     ),
        .ramready   (rammaster.ramready),
        .ipdone     (ipdone     ),
        .ramaddr    (ipaddr     ),
        .ramrd      (iprd       ),
        .ramrddp    (iprddp     ),
        .ramwr      (ipwr       )
    );
    `theregrn( ipdonereg ) <= rammaster.ramready ? {ipdonereg, ipdone } : ipdonereg;
    assign ipreq = iprd | ipwr;

    `theregrn( iprdatreg ) <= iprddp ? rammaster.ramrdata : iprdatreg;
    generate
        for(gvi=0; gvi<DW/8; gvi++) begin : genipwdat
            assign ipwdat[gvi*9+8:gvi*9] = {iprdatreg[gvi*9+8:gvi*9+1], ^iprdatreg[gvi*9+8:gvi*9+1]};
        end
    endgenerate

// ram mux
// ==

    assign evstb = evwr ? '1 : '0;
    assign ipstb = ipwr ? '1 : '0;

    assign rammaster.ramen = 1'b1;
    assign rammaster.ramcs = ( busreq | verifyreq | evreq | ipreq ) & rammaster.ramready;
    assign rammaster.ramwr = rammaster.ramready ? ( busstb |  evstb | ipstb ) : 0 ;
    assign rammaster.ramaddr = busreq ? xaddr : verifyreq ? xaddrpl1 : ipbusy ? ipaddr : evaddr;
    assign rammaster.ramwdata = ipwr ? ipwdat : xwdat ;

    `theregrn( rammrdpl1 ) <= rammaster.ramcs & ( rammaster.ramwr == '0 ) ? 1'b1 :
                              ~(rammaster.ramcs & ( rammaster.ramwr == '0 )) & rammaster.ramready ? 1'b0 : rammrdpl1 ;


endmodule : gnrl_sramc


module gnrl_sramc_initprt #(
    parameter sram_pkg::sramcfg_t thecfg=sram_pkg::samplecfg
)(
    input  logic            clk,
    input  logic            resetn,
    input  logic            start,
    input  logic            stall,
    output logic            busy,
    output logic            ipdone,

    input logic             ramready,
    output logic [thecfg.AW-1:0]   ramaddr,
    output logic            ramrd,
    output logic            ramrddp,
    output logic            ramwr
    );

    localparam AW   = thecfg.AW   ; // 8,
    localparam DW   = thecfg.DW   ; // 32,
    localparam KW   = thecfg.KW   ; // DW,
    localparam PW   = thecfg.PW   ; // DW/8,     // parity: 8->1 bit
    localparam WCNT = thecfg.WCNT ; // 2**AW,
    localparam isBWEN = thecfg.isBWEN ; // 1'b1      // byte write enable
    localparam isSCMB = thecfg.isSCMB ; // 1'b1      // byte write enable
    localparam isPRT  = thecfg.isPRT  ; // 1'b1      // byte write enable


    bit [AW-1:0]            ipptr;
    bit [3:0]               wipfsm;
    bit                     wipdone;
    bit                     done;

// ip ptr

    `theregrn( ipptr ) <= start & ramready ? '0 : wipdone & ramready ? ipptr + 1 : ipptr;
    `theregrn( busy ) <= start ? '1 : done & ramready ? '0 : busy;
    assign done = ( ipptr == ( WCNT - 1 )) & wipdone ;
    `theregrn( ipdone ) <= ( done  & ramready | ipdone ) ;

// 1 word init parity (wip)

    localparam PM_wipfsmcnt = 3;

    `theregrn( wipfsm ) <=  ~ramready ? wipfsm : ( start | stall | wipdone | ~busy ) ? 0 : wipfsm + 1;
    assign wipdone = ( wipfsm == PM_wipfsmcnt ) & ~stall;

// ram interface
    assign ramaddr = ipptr;
    assign ramrd = ( wipfsm == 1 ) & ramready & ~stall;
    assign ramrddp = ( wipfsm == 2 ) & ramready & ~stall;
    assign ramwr = ( wipfsm == 3 ) & ramready & ~stall;

endmodule: gnrl_sramc_initprt


module gnrl_sramc_scramble
#(
    parameter sram_pkg::sramcfg_t thecfg=sram_pkg::samplecfg
)(

    input logic             clk,
    input logic             resetn,
//    input logic             cmsatpg,
//    input logic             cmsbist,

    input logic [thecfg.AW-1:0]      addrin,
    output logic [thecfg.AW-1:0]     addrout,
    input logic             scmben,
    input logic [thecfg.KW-1:0]    scmbkey,

    input  logic [thecfg.DW-1:0]       wdatin,
    output logic [thecfg.DW+thecfg.PW-1:0]    wdatout,

    input  logic [thecfg.DW+thecfg.PW-1:0]    rdatin,
    output logic [thecfg.DW-1:0]       rdatout,

    output logic                 prerr
);
    localparam AW   = thecfg.AW   ; // 8,
    localparam DW   = thecfg.DW   ; // 32,
    localparam KW   = thecfg.KW   ; // DW,
    localparam PW   = thecfg.PW   ; // DW/8,     // parity: 8->1 bit
    localparam WCNT = thecfg.WCNT ; // 2**AW,
    localparam isBWEN = thecfg.isBWEN ; // 1'b1      // byte write enable
    localparam isSCMB = thecfg.isSCMB ; // 1'b1      // byte write enable
    localparam isPRT  = thecfg.isPRT  ; // 1'b1      // byte write enable

    logic [PW-1:0]        pwbit, prbit, prbit0, prerr0, prbitreg ;
    genvar gvi;

// addr permutation

    logic [DW-1:0] xrdat, xwdat, xrdatreg;

    assign addrout = scmben ? ~addrin : addrin;
    assign rdatout = scmben ? ~xrdat  : xrdat;
    assign xwdat   = scmben ? ~wdatin : wdatin;

// parity
// ==

// input xrdat / xwdat / ramslave.ramrdata / ramslave.ramwdata

    generate
        for(gvi=0; gvi<DW/8; gvi++) begin : genpwbit

        // gen wdat parity bit
            assign pwbit[gvi] = ^xwdat[gvi*8+7:gvi*8];
            assign wdatout[gvi*9+8:gvi*9] = { xwdat[gvi*8+7:gvi*8], pwbit[gvi] };

        // gen rdat parity bit, and compare
            assign { xrdat[gvi*8+7:gvi*8], prbit[gvi] } = rdatin[gvi*9+8:gvi*9];
//          assign prbit0[gvi] = ^xrdat[gvi*8+7:gvi*8];

            assign prbit0[gvi] = ^xrdatreg[gvi*8+7:gvi*8];
            `theregrn( prbitreg[gvi] ) <= prbit[gvi] ;
            `theregrn( prerr0[gvi] ) <= prbit0[gvi] ^ prbitreg[gvi];
        end
    endgenerate

    `theregrn( xrdatreg ) <= xrdat;

//    `theregrn( prerr ) <= |prerr0;

    assign prerr = |prerr0;

endmodule : gnrl_sramc_scramble




module gnrl_sramc_extverify #(
    parameter sram_pkg::sramcfg_t thecfg=sram_pkg::samplecfg
    )(
        input logic             clk,
        input logic             resetn,
        input logic             enable,
        input logic             update,
        input  logic [thecfg.AW-1:0]     addrin,
        input  logic            ramready,
        output logic [thecfg.AW-1:0]     ramaddr,
        output logic            ramrd,
        output logic            ramwr
    );
    localparam AW   = thecfg.AW   ; // 8,
    localparam DW   = thecfg.DW   ; // 32,
    localparam KW   = thecfg.KW   ; // DW,
    localparam PW   = thecfg.PW   ; // DW/8,     // parity: 8->1 bit
    localparam WCNT = thecfg.WCNT ; // 2**AW,
    localparam isBWEN = thecfg.isBWEN ; // 1'b1      // byte write enable
    localparam isSCMB = thecfg.isSCMB ; // 1'b1      // byte write enable
    localparam isPRT  = thecfg.isPRT  ; // 1'b1      // byte write enable

    bit [AW-1:0]      ramaddrnext, ramaddrnext0, ramaddrnext1, ramaddrnextx;
    logic           evfsmhit0;
    bit [7:0]       evfsm0;
    bit evx;

    `theregrn( ramaddr ) <= ~enable ? '0 : ramready & update ? addrin : ramrd ? ramaddrnext : ramaddr;

//    assign ramaddrnext = evx ? ramaddrnextx : ramaddrnext0;
    assign ramaddrnext = ramaddrnext0;

    assign ramaddrnext0 = ( ramaddr == WCNT - 1 ) ? '0 : ramaddr + 1;
    assign ramaddrnext1 = ( ramaddr == WCNT - 1 ) ? '0 : ramaddr + 1;

    assign ramwr = '0;
    assign ramrd = enable & evfsmhit0;

    `theregrn( evfsm0 ) <= ramready ? ( evfsmhit0 ? '0 : evfsm0+1 ) : evfsm0;
    assign evfsmhit0 = ( evfsm0 == thecfg.EVITVL );

endmodule : gnrl_sramc_extverify

module dummytb_sramc();

    localparam sram_pkg::sramcfg_t thecfg = sram_pkg::samplecfg;

    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW))rams();
    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW+thecfg.PW))ramm();
    gnrl_sramc u1(
        .clk      ('0),
        .resetn   ('0),
        .cmsatpg  ('0),
        .cmsbist  ('0),
        .scmben   ('0),
        .scmbkey  ('0),
        .even     ('0),
        .prerr    (),
        .verifyerr(),
        .ramslave (rams),
        .rammaster(ramm)
        );
endmodule

`ifdef SIMRAMC

module gnrl_sramc_tb (
);

    localparam AW = 12;

    localparam sram_pkg::sramcfg_t testcfg = {
        AW: AW,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 2**AW,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL: 15
    };

    logic             clk=0;
    logic             resetn=0;
    logic             cmsatpg=0;
    logic             cmsbist=0;
    logic             scmben=1'b0;
    logic [testcfg.KW-1:0] scmbkey=0;
    logic             prerr;

    bit                    ramm_ramen    ;
    bit                    ramm_ramcs    ;
    bit   [testcfg.AW-1:0]  ramm_ramaddr  ;
    bit   [3:0]                 ramm_ramwr    ;
    bit   [testcfg.DW-1:0]  ramm_ramwdata ;
    bit   [testcfg.DW-1:0]  ramm_ramrdata ;
    bit                    ramm_ramready ;
    ramif #(.RAW(testcfg.AW))        rams() ;

    bit                         rams_ramen    ;
    bit                         rams_ramcs    ;
    bit   [testcfg.AW-1:0]     rams_ramaddr  ;
    bit    [3:0]                      rams_ramwr    ;
    bit   [testcfg.DW+testcfg.PW-1:0]    rams_ramwdata ;
    bit   [testcfg.DW+testcfg.PW-1:0]    rams_ramrdata, rams_ramrdata0, rams_ramrdata2 ;
    bit                      rams_ramready;
    ramif #(.RAW(testcfg.AW),.BW(9),.DW(testcfg.DW+testcfg.PW))        ramm();
    bit verifyerr;

//    bit clk,resetn;
    integer i, j, k, errcnt=0, warncnt=0;


  //
  //  dut
  //  ==

    gnrl_sramc #(.thecfg(testcfg))dut
    (
        .clk,
        .resetn,
        .cmsatpg,
        .cmsbist,
        .scmben,
        .scmbkey,
        .prerr,
        .verifyerr,
        .ramslave(rams),
        .rammaster(ramm)
    );

    wire2ramm #(.AW(testcfg.AW),.DW(testcfg.DW)) RM(.ramm(rams),.*);
    rams2wire #(.AW(testcfg.AW),.DW(testcfg.DW+testcfg.PW)) RS(.rams(ramm),.*);

    `theregrn( rams_ramready ) <= rams_ramcs ? '0 : '1;

    simram #(.AW(testcfg.AW),.DW(testcfg.DW+testcfg.PW)) simram(
        .clk, .resetn,
        .ramaddr    (rams_ramaddr),
        .ramrdat    (rams_ramrdata0),
        .ramwr      (rams_ramwr[0]),
        .ramrd      (rams_ramcs & ~rams_ramwr[0]),
        .ramwdat    (rams_ramwdata ^ 'h0)
    );
/*
    simram2 #(.AW(testcfg.AW),.DW(testcfg.DW+testcfg.PW)) simram2(
        .clk, .resetn,
        .ramaddr    (rams_ramaddr),
        .ramrdat    (rams_ramrdata2),
        .ramwr      (rams_ramwr[0]),
//        .ramrd      (rams_ramcs & ~rams_ramwr[0]),
        .ramwdat    (rams_ramwdata ^ 'h0)
    );
*/
//    assign rams_ramrdata = rams_ramready ? rams_ramrdata2 : '0;
    assign rams_ramrdata =  rams_ramrdata0 ;

  //
  //  monitor and clk
  //  ==

    `genclk( clk, 100 )
    `timemarker2




  //
  //  subtitle
  //  ==

    `maintest(gnrl_sramc_tb,gnrl_sramc_tb)
        #105 resetn = 1;

`ifdef NOFSDB
        for(i=1;i>0;i=i)begin
        #(10 `MS);
        end
`endif
        #(50 `MS);
    `maintestend

    bit [31:0]  r32a, r32b, r32c;

    assign ramm_ramen = '1;

    always@(posedge clk)
    if(resetn & ramm_ramready) begin
        r32a <= $urandom() & $urandom();
        r32b <= $urandom();
        r32c <= $urandom();
        ramm_ramcs <= r32a[0];
        ramm_ramwr <= {4{&r32a[1:0]}};
        ramm_ramaddr <= r32b;
        ramm_ramwdata <= r32b;
    end

// rdcheck

    bit rdcheck, rdcheck0;
    bit [3:0][8:0] therdata36;
    bit [3:0][7:0] therdata;
    bit rderror;

    assign therdata[0] = therdata36[0]/2;
    assign therdata[1] = therdata36[1]/2;
    assign therdata[2] = therdata36[2]/2;
    assign therdata[3] = therdata36[3]/2;



    `theregrn( rdcheck0 ) <= ramm_ramready ? ramm_ramcs & ~ramm_ramwr[0] : rdcheck0;

    always@(posedge clk)begin
        if( ramm_ramcs & ~ramm_ramwr[0] & ramm_ramready ) begin
            therdata36 <= simram.ramdat[ramm_ramaddr];
        end
    end
    assign rdcheck = rdcheck0 & ramm_ramready;
    `theregrn( rderror ) <= rdcheck & ~( therdata == ramm_ramrdata );

// wrcheck

    bit wrcheck0, wrcheck, wrerror;
    bit [testcfg.AW-1:0] ramm_ramaddrreg;
    bit [31:0] wdat32a, wdat32b;
    bit [35:0] wdat36;

    `thereg( simram.ramdat32[ramm_ramaddr] ) <= ramm_ramcs  & ramm_ramwr[0] & ramm_ramready ? ramm_ramwdata : simram.ramdat32[ramm_ramaddr];
    `thereg( wrcheck0 ) <= ramm_ramready ? ramm_ramcs & ramm_ramwr[0] : wrcheck0;
    `thereg( ramm_ramaddrreg ) <= ramm_ramready & ramm_ramcs & ramm_ramwr[0] ? ramm_ramaddr : ramm_ramaddrreg;

    assign wrcheck = wrcheck0 & ramm_ramready;
    `theregrn( wrerror ) <= wrcheck & ~( simram.ramdat32[ramm_ramaddrreg] ==
                        {simram.ramdat[ramm_ramaddrreg][35:28],simram.ramdat[ramm_ramaddrreg][26:19],simram.ramdat[ramm_ramaddrreg][17:10],simram.ramdat[ramm_ramaddrreg][8:1]} );

    assign wdat32a =    simram.ramdat32[ramm_ramaddrreg];
    assign wdat36 =    simram.ramdat[ramm_ramaddrreg];
    assign wdat32b  = { simram.ramdat[ramm_ramaddrreg][35:28],
                        simram.ramdat[ramm_ramaddrreg][26:19],
                        simram.ramdat[ramm_ramaddrreg][17:10],
                        simram.ramdat[ramm_ramaddrreg][ 8: 1]}   ;

    bit wdat32check;
    `theregrn( wdat32check ) <= wdat32a == wdat32b;

    `thereg( errcnt ) <= errcnt + rderror + wrerror + dut.prerr + dut.verifyerr;


integer x;
    initial begin
        for(x=1;x>0;x=x)begin
            #(10 `MS);
            resetn = 0;
            #(751);
            resetn = 1;
        end

    end

endmodule


module simram #(
    parameter AW = 10,
    parameter string INITFILE="",
    parameter bit RANDOMIZE=1'b1,
    parameter DW = 36

)(
    input   bit             clk,    // Clock
    input   bit             resetn,  // Asynchronous reset active low

    input bit   [AW-1:0]    ramaddr,
    output  bit [DW-1:0]    ramrdat,
    input bit               ramwr,
    input bit               ramrd,
    input bit   [DW-1:0]    ramwdat
);

    bit [DW-1:0]    ramdat[0:2**AW-1];
    bit [DW-1:0]    ramdat0[0:2**AW-1];
    bit [31:0]    ramdat32[0:2**AW-1];
    bit [31:0]    ramdat32b[0:2**AW-1];
    bit [0:2**AW-1][DW-1:0]    vramdat;
    integer i;

    integer errcnt = 0;

    bit [35:0] tmp36;
    bit [2:0] resetnregs;
    bit resetfall;

    always@(posedge clk)  resetnregs <= { resetnregs, resetn };
    assign resetfall = resetnregs[2] & ~resetnregs[1] ;

    always@(negedge clk)  begin
        if(resetfall)begin
        errcnt = 0;
            for(i=0;i<2**AW;i++)begin
                if ( ramdat32[i] != {ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]} ) errcnt = errcnt + 1;
                tmp36 = $urandom() * 8'ha5;
//                ramdat[i]=tmp36;
                ramdat[i]=tmp36;//$urandom()*8'ha5;
                ramdat32[i]={ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]};
            end
        $display("@ram data scan check: %d", errcnt);
        end
    end

    initial begin
        if(INITFILE!="")$readmemh(INITFILE, ramdat);

        if(INITFILE=="" &&RANDOMIZE)begin
            for(i=0;i<2**AW;i++)begin
                ramdat[i]=$urandom()*8'ha5;
                ramdat32[i]={ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]};
            end
        end

    end

    bit [DW-1:0] ramrdat0;

    always@(posedge clk) if(ramwr) ramdat[ramaddr] <= ramwdat;
    always@(posedge clk) ramrdat0 <= ramdat[ramaddr];
    always@(posedge clk) ramrdat <= ramrdat0;

    genvar gvi;
    generate
        for(gvi=0;gvi<2**AW;gvi++)begin
        assign vramdat[gvi] = ramdat[gvi];
        assign ramdat32b[gvi] = {ramdat[gvi][35:28],ramdat[gvi][26:19],ramdat[gvi][17:10],ramdat[gvi][8:1]};
    end
    endgenerate


endmodule : simram


/*
module simram2 #(
    parameter AW = 10,
//
    parameter string INITFILE="",
    parameter bit RANDOMIZE=1'b1,
    parameter DW = 32

)(
    input   bit             clk,    // Clock
    input   bit             resetn,  // Asynchronous reset active low

    input bit   [AW-1:0]    ramaddr,
    output  bit [DW-1:0]    ramrdat,
    input bit               ramwr,
    input bit   [DW-1:0]    ramwdat
);

    bit [DW-1:0]    ramdat[0:2**AW-1];
    bit [31:0]    ramdat32[0:2**AW-1];
    bit [31:0]    ramdat32b[0:2**AW-1];
    integer i;

//    initial $readmemh(INITFILE, ramdat);

    always@(posedge clk) if(ramwr) ramdat[ramaddr] <= ramwdat;
    always@(posedge clk) ramrdat <= ramdat[ramaddr];



    integer errcnt;
    bit [35:0] tmp36;
    always@(negedge resetn)  begin
        errcnt = 0;
            for(i=0;i<2**AW;i++)begin
                if ( ramdat32[i] != {ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]} ) errcnt = errcnt + 1;
                tmp36 = $urandom() * 8'ha5;
                ramdat[i]=tmp36;//$urandom()*8'ha5;
                ramdat32[i]={ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]};
            end
        $display("@ram data scan check: %d", errcnt);
    end

    initial begin
        if(INITFILE!="")$readmemh(INITFILE, ramdat);

        if(INITFILE=="" &&RANDOMIZE)begin
            for(i=0;i<2**AW;i++)begin
                ramdat[i]=$urandom()*8'ha5;
                ramdat32[i]={ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]};
            end
        end

    end

endmodule : simram2

*/

`endif

