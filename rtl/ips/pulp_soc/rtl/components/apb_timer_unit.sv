// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


`define CFG_REG_LO         6'h0
`define CFG_REG_HI         6'h4
`define TIMER_VAL_LO       6'h8
`define TIMER_VAL_HI       6'hC
`define TIMER_CMP_LO       6'h10
`define TIMER_CMP_HI       6'h14
`define TIMER_START_LO     6'h18
`define TIMER_START_HI     6'h1C
`define TIMER_RESET_LO     6'h20
`define TIMER_RESET_HI     6'h24


`define ENABLE_BIT          'd0
`define RESET_BIT           'd1
`define IRQ_BIT             'd2
`define IEM_BIT             'd3
`define CMP_CLR_BIT         'd4
`define ONE_SHOT_BIT        'd5
`define PRESCALER_EN_BIT    'd6
`define REF_CLK_EN_BIT      'd7
`define PRESCALER_START_BIT 'd8
`define PRESCALER_STOP_BIT  'd15
`define MODE_64_BIT         'd31

module apb_timer_unit
  #(
    parameter APB_ADDR_WIDTH = 12
    )
   (
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    input logic                       ref_clk_i,

    input  logic                      event_lo_i,
    input  logic                      event_hi_i,

    output logic                      irq_lo_o,
    output logic                      irq_hi_o,

    output logic                      busy_o
    );

    logic        s_req,s_wen;
    logic [31:0] s_addr;

    logic        s_write_counter_lo, s_write_counter_hi;
    logic        s_start_timer_lo,s_start_timer_hi,s_reset_timer_lo,s_reset_timer_hi;

    logic        s_ref_clk0, s_ref_clk1, s_ref_clk2, s_ref_clk3, s_ref_clk_edge, s_ref_clk_edge_del;

    logic [31:0] s_cfg_lo, s_cfg_lo_reg;
    logic [31:0] s_cfg_hi, s_cfg_hi_reg;
    logic [31:0] s_timer_val_lo;
    logic [31:0] s_timer_val_hi;
    logic [31:0] s_timer_cmp_lo, s_timer_cmp_lo_reg;
    logic [31:0] s_timer_cmp_hi, s_timer_cmp_hi_reg;

    logic        s_enable_count_lo,s_enable_count_hi,s_enable_count_prescaler_lo,s_enable_count_prescaler_hi;
    logic        s_reset_count_lo,s_reset_count_hi,s_reset_count_prescaler_lo,s_reset_count_prescaler_hi;
    logic        s_target_reached_lo,s_target_reached_hi,s_target_reached_prescaler_lo, s_target_reached_prescaler_hi;



    //**********************************************************
    //*************** PERIPHS INTERFACE ************************
    //**********************************************************

    // register write logic
    always_comb
    begin
        s_cfg_lo           = s_cfg_lo_reg;
        s_cfg_hi           = s_cfg_hi_reg;
        s_timer_cmp_lo     = s_timer_cmp_lo_reg;
        s_timer_cmp_hi     = s_timer_cmp_hi_reg;
        s_write_counter_lo = 1'b0;
        s_write_counter_hi = 1'b0;
        s_start_timer_lo   = 1'b0;
        s_start_timer_hi   = 1'b0;
        s_reset_timer_lo   = 1'b0;
        s_reset_timer_hi   = 1'b0;

        // APERIPH BUS: LOWER PRIORITY
        if (PSEL && PENABLE && PWRITE)
        begin
            case (PADDR[5:0])
                `CFG_REG_LO:
                    s_cfg_lo           = PWDATA;
                `CFG_REG_HI:
                    s_cfg_hi           = PWDATA;
                `TIMER_VAL_LO:
                    s_write_counter_lo = 1'b1;
                `TIMER_VAL_HI:
                    s_write_counter_hi = 1'b1;
                `TIMER_CMP_LO:
                    s_timer_cmp_lo     = PWDATA;
                `TIMER_CMP_HI:
                    s_timer_cmp_hi     = PWDATA;
                `TIMER_START_LO:
                    s_start_timer_lo   = 1'b1;
                `TIMER_START_HI:
                    s_start_timer_hi   = 1'b1;
                `TIMER_RESET_LO:
                    s_reset_timer_lo   = 1'b1;
                `TIMER_RESET_HI:
                    s_reset_timer_hi   = 1'b1;
            endcase
        end

        // INPUT EVENTS: HIGHER PRIORITY
        if (event_lo_i | s_start_timer_lo)
            s_cfg_lo[`ENABLE_BIT] = 1;
        else
        begin
            if (!s_cfg_lo_reg[`MODE_64_BIT]) // 32 BIT MODE
            begin
                if (s_cfg_lo[`ONE_SHOT_BIT] && s_target_reached_lo) // ONE SHOT FEATURE: DISABLES TIMER ONCE THE TARGET IS REACHED
                    s_cfg_lo[`ENABLE_BIT] = 0;
            end
            else
            begin
                if (s_cfg_lo[`ONE_SHOT_BIT] && s_target_reached_lo && s_target_reached_hi) // ONE SHOT FEATURE: DISABLES TIMER ONCE LOW COUNTER REACHES 0xFFFFFFFF and HI COUNTER TARGET IS REACHED
                    s_cfg_lo[`ENABLE_BIT] = 0;
            end
        end

        // INPUT EVENTS: HIGHER PRIORITY
        if (event_hi_i | s_start_timer_hi)
            s_cfg_hi[`ENABLE_BIT] = 1;
        else
        begin
            if ((!s_cfg_hi_reg[`MODE_64_BIT]) && s_cfg_hi[`ONE_SHOT_BIT] && s_target_reached_hi) // ONE SHOT FEATURE: DISABLES TIMER ONCE THE TARGET IS REACHED IN 32 BIT MODE
            begin
                s_cfg_hi[`ENABLE_BIT] = 0;
            end
            else
            begin
                if (s_cfg_lo[`ONE_SHOT_BIT] && s_target_reached_lo && s_target_reached_hi)
                    s_cfg_hi[`ENABLE_BIT] = 0;
            end
        end

        // RESET LO
        if (s_reset_count_lo)
            s_cfg_lo[`RESET_BIT] = 1'b0;

        // RESET HI
        if (s_reset_count_hi)
            s_cfg_hi[`RESET_BIT] = 1'b0;
    end

    // sequential part
    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if (~HRESETn)
        begin
            s_cfg_lo_reg       <= 0;
            s_cfg_hi_reg       <= 0;
            s_timer_cmp_lo_reg <= 0;
            s_timer_cmp_hi_reg <= 0;
        end
        else
        begin
            s_cfg_lo_reg       <= s_cfg_lo;
            s_cfg_hi_reg       <= s_cfg_hi;
            s_timer_cmp_lo_reg <= s_timer_cmp_lo;
            s_timer_cmp_hi_reg <= s_timer_cmp_hi;
        end
    end

    assign PSLVERR = 1'b0;
    assign PREADY  = PSEL & PENABLE;
    // APB register read logic
    always_comb
    begin
        PRDATA  = 'b0;

        if (PSEL && PENABLE && !PWRITE)
        begin
            case (PADDR[5:0])
                `CFG_REG_LO:
                    PRDATA = s_cfg_lo_reg;
                `CFG_REG_HI:
                    PRDATA = s_cfg_hi_reg;
                `TIMER_VAL_LO:
                    PRDATA = s_timer_val_lo;
                `TIMER_VAL_HI:
                    PRDATA = s_timer_val_hi;
                `TIMER_CMP_LO:
                    PRDATA = s_timer_cmp_lo_reg;
                `TIMER_CMP_HI:
                    PRDATA = s_timer_cmp_hi_reg;
            endcase
        end
    end

    //**********************************************************
    //*************** CONTROL **********************************
    //**********************************************************

    // RESET COUNT SIGNAL GENERATION
    always_comb
    begin
        s_reset_count_lo           = 1'b0;
        s_reset_count_hi           = 1'b0;
        s_reset_count_prescaler_lo = 1'b0;
        s_reset_count_prescaler_hi = 1'b0;

        if (s_cfg_lo_reg[`RESET_BIT] | s_reset_timer_lo)
        begin
             s_reset_count_lo           = 1'b1;
             s_reset_count_prescaler_lo = 1'b1;
        end
        else
        begin
            if (!s_cfg_lo_reg[`MODE_64_BIT]) // 32-bit mode
            begin
                if (s_cfg_lo_reg[`CMP_CLR_BIT] && s_target_reached_lo) // if compare and clear feature is enabled the counter is resetted when the target is reached
                begin
                    s_reset_count_lo = 1;
                end
            end
            else // 64-bit mode
            begin
                if (s_cfg_lo_reg[`CMP_CLR_BIT] && s_target_reached_lo  && s_target_reached_hi) // if compare and clear feature is enabled the counter is resetted when the target is reached
                begin
                    s_reset_count_lo = 1;
                end
            end
        end

        if (s_cfg_hi_reg[`RESET_BIT] | s_reset_timer_hi)
        begin
             s_reset_count_hi           = 1'b1;
             s_reset_count_prescaler_hi = 1'b1;
        end
        else
        begin
            if (!s_cfg_lo_reg[`MODE_64_BIT]) // 32-bit mode
            begin
                if (s_cfg_hi_reg[`CMP_CLR_BIT] && s_target_reached_hi) // if compare and clear feature is enabled the counter is resetted when the target is reached
                begin
                    s_reset_count_hi = 1;
                end
            end
            else // 64-bit mode
            begin
                if (s_cfg_lo_reg[`CMP_CLR_BIT] && s_target_reached_lo && s_target_reached_hi) // if compare and clear feature is enabled the counter is resetted when the target is reached
                begin
                    s_reset_count_hi = 1;
                end
            end
        end

        if (s_cfg_lo_reg[`PRESCALER_EN_BIT] && s_target_reached_prescaler_lo)
        begin
            s_reset_count_prescaler_lo = 1'b1;
        end
        
        if (s_cfg_hi_reg[`PRESCALER_EN_BIT] && s_target_reached_prescaler_hi)
        begin
            s_reset_count_prescaler_hi = 1'b1;
        end
    end

    // ENABLE SIGNALS GENERATION
    always_comb
    begin
        s_enable_count_lo           = 1'b0;
        s_enable_count_hi           = 1'b0;
        s_enable_count_prescaler_lo = 1'b0;
        s_enable_count_prescaler_hi = 1'b0;

        // 32 bit mode lo counter
        if (!s_cfg_lo_reg[`MODE_64_BIT] && s_cfg_lo_reg[`ENABLE_BIT])
        begin
            if (!s_cfg_lo_reg[`PRESCALER_EN_BIT] && (!s_cfg_lo_reg[`REF_CLK_EN_BIT])) // prescaler disabled, ref clock disabled
            begin
                s_enable_count_lo = 1'b1;
            end
            else if (!s_cfg_lo_reg[`PRESCALER_EN_BIT] && s_cfg_lo_reg[`REF_CLK_EN_BIT]) // prescaler disabled, ref clock enabled
            begin
                s_enable_count_lo = s_ref_clk_edge;
            end
            else if (s_cfg_lo_reg[`PRESCALER_EN_BIT] && s_cfg_lo_reg[`REF_CLK_EN_BIT]) // prescaler enabled, ref clock enabled
            begin
                s_enable_count_prescaler_lo = s_ref_clk_edge;
                s_enable_count_lo           = s_ref_clk_edge_del & s_target_reached_prescaler_lo;
            end
            else // prescaler enabled, ref clock disabled
            begin
                s_enable_count_prescaler_lo = 1'b1;
                s_enable_count_lo           = s_target_reached_prescaler_lo;
            end
        end

        // 32 bit mode hi counter
        if (!s_cfg_lo_reg[`MODE_64_BIT] && s_cfg_hi_reg[`ENABLE_BIT]) // counter hi enabled
        begin
            if (!s_cfg_hi_reg[`PRESCALER_EN_BIT] && (!s_cfg_hi_reg[`REF_CLK_EN_BIT])) // prescaler disabled, ref clock disabled
            begin
                s_enable_count_hi = 1'b1;
            end
            else if (!s_cfg_hi_reg[`PRESCALER_EN_BIT] && s_cfg_hi_reg[`REF_CLK_EN_BIT]) // prescaler disabled, ref clock enabled
            begin
                s_enable_count_hi = s_ref_clk_edge;
            end
            else if (s_cfg_hi_reg[`PRESCALER_EN_BIT] && s_cfg_hi_reg[`REF_CLK_EN_BIT]) // prescaler enabled, ref clock enabled
            begin
                s_enable_count_prescaler_hi = s_ref_clk_edge;
                s_enable_count_hi           = s_ref_clk_edge_del & s_target_reached_prescaler_hi;
            end
            else // prescaler enabled, ref clock disabled
            begin
                s_enable_count_prescaler_hi = 1'b1;
                s_enable_count_hi           = s_target_reached_prescaler_hi;
            end
        end

        // 64-bit mode
        if (s_cfg_lo_reg[`MODE_64_BIT] && s_cfg_lo_reg[`ENABLE_BIT]) // timer enabled,  64-bit mode
        begin
            if (!s_cfg_lo_reg[`PRESCALER_EN_BIT] && (!s_cfg_lo_reg[`REF_CLK_EN_BIT])) // prescaler disabled, ref clock disabled
            begin
                s_enable_count_lo = 1'b1;
                s_enable_count_hi = (s_timer_val_lo == 32'hFFFFFFFF);
            end
            else if (!s_cfg_lo_reg[`PRESCALER_EN_BIT] && s_cfg_lo_reg[`REF_CLK_EN_BIT]) // prescaler disabled, ref clock enabled
            begin
                s_enable_count_lo = s_ref_clk_edge;
                s_enable_count_hi = s_ref_clk_edge_del & (s_timer_val_lo == 32'hFFFFFFFF);
            end
            else if (s_cfg_lo_reg[`PRESCALER_EN_BIT] && s_cfg_lo_reg[`REF_CLK_EN_BIT]) // prescaler enabled, ref clock enabled
            begin
                s_enable_count_prescaler_lo = s_ref_clk_edge;

                s_enable_count_lo = s_ref_clk_edge_del & s_target_reached_prescaler_lo;
                s_enable_count_hi = s_target_reached_prescaler_lo & s_ref_clk_edge_del & (s_timer_val_lo == 32'hFFFFFFFF);
            end
            else  // prescaler enabled, ref clock disabled
            begin
                s_enable_count_prescaler_lo = 1'b1;

                s_enable_count_lo = s_target_reached_prescaler_lo;
                s_enable_count_hi = s_target_reached_prescaler_lo & (s_timer_val_lo == 32'hFFFFFFFF);
            end
        end
    end

    // IRQ SIGNALS GENERATION
    always_comb
    begin
        irq_lo_o = 1'b0;
        irq_hi_o = 1'b0;

        if (!s_cfg_lo_reg[`MODE_64_BIT])
        begin
            irq_lo_o = s_target_reached_lo & s_cfg_lo_reg[`IRQ_BIT] & s_cfg_lo_reg[`ENABLE_BIT];
            irq_hi_o = s_target_reached_hi & s_cfg_hi_reg[`IRQ_BIT] & s_cfg_hi_reg[`ENABLE_BIT];
        end
        else
        begin
            irq_lo_o = s_target_reached_lo & s_target_reached_hi & s_cfg_lo_reg[`IRQ_BIT] & s_cfg_lo_reg[`ENABLE_BIT];
        end
    end

   //**********************************************************
   //*************** EDGE DETECTOR FOR REF CLOCK **************
   //**********************************************************

    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            s_ref_clk0 <= 1'b0;
            s_ref_clk1 <= 1'b0;
            s_ref_clk2 <= 1'b0;
            s_ref_clk3 <= 1'b0;
        end
        else
        begin
            s_ref_clk0 <= ref_clk_i;
            s_ref_clk1 <= s_ref_clk0;
            s_ref_clk2 <= s_ref_clk1;
            s_ref_clk3 <= s_ref_clk2;
        end
    end

    assign s_ref_clk_edge     = s_ref_clk1 & (~s_ref_clk2);
    assign s_ref_clk_edge_del = s_ref_clk2 & (~s_ref_clk3);

    //**********************************************************
    //*************** COUNTERS *********************************
    //**********************************************************

    timer_unit_counter prescaler_lo_i
    (
        .clk_i(HCLK),
        .rst_ni(HRESETn),

        .write_counter_i(1'b0),
        .counter_value_i(32'h0),

        .enable_count_i(s_enable_count_prescaler_lo),
        .reset_count_i(s_reset_count_prescaler_lo),
        .compare_value_i({24'd0,s_cfg_lo_reg[`PRESCALER_STOP_BIT:`PRESCALER_START_BIT]}),

        .counter_value_o(),
        .target_reached_o(s_target_reached_prescaler_lo)
    );

    timer_unit_counter prescaler_hi_i
    (
        .clk_i(HCLK),
        .rst_ni(HRESETn),

        .write_counter_i(1'b0),
        .counter_value_i(32'h0),

        .enable_count_i(s_enable_count_prescaler_hi),
        .reset_count_i(s_reset_count_prescaler_hi),
        .compare_value_i({24'd0,s_cfg_hi_reg[`PRESCALER_STOP_BIT:`PRESCALER_START_BIT]}),

        .counter_value_o(),
        .target_reached_o(s_target_reached_prescaler_hi)
    );

    timer_unit_counter counter_lo_i
    (
        .clk_i(HCLK),
        .rst_ni(HRESETn),

        .write_counter_i(s_write_counter_lo),
        .counter_value_i(PWDATA),

        .enable_count_i(s_enable_count_lo),
        .reset_count_i(s_reset_count_lo),
        .compare_value_i(s_timer_cmp_lo_reg),

        .counter_value_o(s_timer_val_lo),
        .target_reached_o(s_target_reached_lo)
    );

    timer_unit_counter counter_hi_i
    (
        .clk_i(HCLK),
        .rst_ni(HRESETn),

        .write_counter_i(s_write_counter_hi),
        .counter_value_i(PWDATA),

        .enable_count_i(s_enable_count_hi),
        .reset_count_i(s_reset_count_hi),
        .compare_value_i(s_timer_cmp_hi_reg),

        .counter_value_o(s_timer_val_hi),
        .target_reached_o(s_target_reached_hi)
    );

    assign busy_o = s_cfg_hi_reg[`ENABLE_BIT] | s_cfg_lo_reg[`ENABLE_BIT];

endmodule
