module apb_wire2ifm #(
    parameter AW=16,
    parameter DW=32
    )(
    apbif.master            apbmaster,
    input  logic            psel         ,
    input  logic [AW-1:0]   paddr        ,
    input  logic            penable      ,
    input  logic            pwrite       ,
    input  logic [3:0]      pstrb        ,
    input  logic [2:0]      pprot        ,
    input  logic [31:0]     pwdata       ,
    input  logic            apbactive    ,
    output logic [DW-1:0]   prdata       ,
    output logic            pready       ,
    output logic            pslverr
);

    assign apbmaster.psel      = psel          ;
    assign apbmaster.paddr     = paddr         ;
    assign apbmaster.penable   = penable       ;
    assign apbmaster.pwrite    = pwrite        ;
    assign apbmaster.pstrb     = pstrb         ;
    assign apbmaster.pprot     = pprot         ;
    assign apbmaster.pwdata    = pwdata        ;
    assign apbmaster.apbactive = apbactive     ;
    assign prdata       = apbmaster.prdata       ;
    assign pready       = apbmaster.pready       ;
    assign pslverr      = apbmaster.pslverr      ;

endmodule

// sv-to-v adapter
module duart_top #(
    parameter AW = 12,
    parameter INITETU = 'd32

)
(
    input logic     clk,
    input logic     sclk,
    input logic     resetn,

    input  wire        [AW-1:0] PADDR,     // APB Address
    input  wire                 PENABLE,   // APB Enable
    input  wire                 PWRITE,    // APB Write
    input  wire           [3:0] PSTRB,     // APB Byte Strobe
    input  wire           [2:0] PPROT,     // APB Prot
    input  wire          [31:0] PWDATA,    // APB write data
    input  wire                 PSEL,      // APB Select
    input  wire                 APBACTIVE, // APB bus is active, for clock gating
                                           // of APB bus
                                           // APB Input
    output wire          [31:0] PRDATA,    // Read data for each APB slave
    output wire                 PREADY,    // Ready for each APB slave
    output wire                 PSLVERR,   // Error state for each APB slave

    output logic                txd

);

    apbif #(.PAW(AW)) theapb();

    apb_wire2ifm #(
      .AW(AW)
     )apbtrans(
        .apbmaster    (theapb),
        .psel         (PSEL),
        .paddr        (PADDR),
        .penable      (PENABLE),
        .pwrite       (PWRITE),
        .pstrb        (PSTRB),
        .pprot        (PPROT),
        .pwdata       (PWDATA),
        .apbactive    (APBACTIVE),
        .prdata       (PRDATA),
        .pready       (PREADY),
        .pslverr      (PSLVERR)
    );

    duart #(
     )u(
        .clk     ,
        .sclk    ,
        .resetn  ,
        .apbs    (theapb),
        .apbx    (theapb),
        .txd
    );

endmodule