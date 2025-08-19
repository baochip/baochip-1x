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

`include "udma_i2c_defines.sv"
module udma_i2c_bus_ctrl
(
    input  logic            clk_i,      // system clock
    input  logic            rstn_i,     // asynchronous active low reset
    input  logic            ena_i,      // core enable signal

    input  logic            sw_rst_i,   // SW reset signal used to abort the ongoing transfer and cleas busy and arbitration lost signals

    input  logic     [15:0] clk_cnt_i,  // clock prescale value

    input  logic     [ 2:0] cmd_i,      // command (from byte controller)
    input  logic            cmd_valid_i,// command valid signal
    output logic            cmd_ack_o,  // command complete acknowledge
    output logic            busy_o,     // i2c bus busy
    output logic            al_o,       // i2c bus arbitration lost

    input  logic            din_i,
    output logic            dout_o,

    input  logic            scl_i,      // i2c clock line input
    output logic            scl_o,      // i2c clock line output
    output logic            scl_oen,     // i2c clock line output enable (active low)
    input  logic            sda_i,      // i2c data line input
    output logic            sda_o,      // i2c data line output
    output logic            sda_oen      // i2c data line output enable (active low)
);

    typedef logic [13:0] logic_14;

    //
    // variable declarations
    //

    logic [ 1:0] r_sync_scl;      // SCL synchronizer
    logic [ 1:0] r_sync_sda;      // SDA synchronizer

    logic [ 2:0] r_filter_scl, r_filter_sda;      // SCL and SDA filter inputs
    logic        sSCL, sSDA;      // filtered and synchronized SCL and SDA inputs
    logic        dSCL, dSDA;      // delayed versions of sSCL and sSDA
    logic        dscl_oen;        // delayed scl_oen
    logic        sda_chk;         // check SDA output (Multi-master arbitration)
    logic        clk_en;          // clock generation signals
    logic        slave_wait;      // slave inserts wait states
    logic [15:0] cnt;             // clock divider counter (synthesis)
    logic [13:0] r_filter_cnt;    // clock divider for filter


    // state machine variable
    logic        scl_sync;

    logic r_start;
    logic r_stop;

    logic r_cmd_stop;

    enum logic [4:0] {S_IDLE,
                      S_START_PHASE1,
                      S_START_PHASE2,
                      S_START_PHASE3,
                      S_START_PHASE4,
                      S_STOP_PHASE1,
                      S_STOP_PHASE2,
                      S_STOP_PHASE3,
                      S_STOP_PHASE4,
                      S_RD_PHASE1,
                      S_RD_PHASE2,
                      S_RD_PHASE3,
                      S_RD_PHASE4,
                      S_WAIT_PHASE1,
                      S_WAIT_PHASE2,
                      S_WAIT_PHASE3,
                      S_WAIT_PHASE4,
                      S_WR_PHASE1,
                      S_WR_PHASE2,
                      S_WR_PHASE3,
                      S_WR_PHASE4} CS;

    // Open collector. Never drives SCL and SDA high.
    assign scl_o = 1'b0;
    assign sda_o = 1'b0;

    // whenever the slave is not ready it can delay the cycle by pulling SCL low
    // delay scl_oen
    always @(posedge clk_i, negedge rstn_i)
    begin
      if(rstn_i == 1'b0)
        dscl_oen <= 1'b1;  //FIXME ANTONIO; PLEASE CHECK THAT RESET VALUE IS OK
      else
        dscl_oen <= scl_oen;
    end

    // slave_wait is asserted when master wants to drive SCL high, but the slave pulls it low
    // slave_wait remains asserted until the slave releases SCL
    always @(posedge clk_i or negedge rstn_i)
      if (!rstn_i)
        slave_wait <= 1'b0;
      else
        if (sw_rst_i)
          slave_wait <= 1'b0;
        else
          slave_wait <= (scl_oen & ~dscl_oen & ~sSCL) | (slave_wait & ~sSCL);

    // master drives SCL high, but another master pulls it low
    // master start counting down its low cycle now (clock synchronization)
    assign scl_sync   = dSCL & ~sSCL & scl_oen;


    // generate clk_i enable signal
    always @(posedge clk_i or negedge rstn_i)
      if (~rstn_i)
      begin
          cnt    <= 16'h0;
          clk_en <= 1'b1;
      end
        else if (sw_rst_i)
        begin
            cnt    <= 16'h0;
            clk_en <= 1'b1;
        end
        else if (~|cnt || !ena_i || scl_sync)
        begin
            cnt    <= clk_cnt_i;
            clk_en <= 1'b1;
        end
        else if (slave_wait)
        begin
            cnt    <= cnt;
            clk_en <= 1'b0;
        end
        else
        begin
            cnt    <= cnt - 16'h1;
            clk_en <= 1'b0;
        end


    // generate bus status controller

    // SDA and SCL synchronizer
    always @(posedge clk_i or negedge rstn_i)
      if (!rstn_i)
      begin
          r_sync_scl <= 2'b00;
          r_sync_sda <= 2'b00;
      end
      else
      begin
        if (sw_rst_i)
        begin
          r_sync_scl <= 2'b00;
          r_sync_sda <= 2'b00;
        end
        else
        begin
          r_sync_scl <= {r_sync_scl[0],scl_i};
          r_sync_sda <= {r_sync_sda[0],sda_i};
        end
      end


    // filter counter used to sample SCL and SDA at higher freq(16x I2C freq)
    always @(posedge clk_i or negedge rstn_i)
      if (!rstn_i)
        r_filter_cnt <= 'h0;
      else if (!ena_i || sw_rst_i)
        r_filter_cnt <= 'h0;
      else if (r_filter_cnt == 'h0)
        r_filter_cnt <= logic_14'(clk_cnt_i >> 2); //16x I2C bus frequency // FIXME ANTONIO PLEASE CHECK IF THE CASTING IS OK: RHS 16 bit LHS 14bit
      else
        r_filter_cnt <= r_filter_cnt -1;


    always @(posedge clk_i or negedge rstn_i)
      if (!rstn_i)
      begin
          r_filter_scl <= 3'b111;
          r_filter_sda <= 3'b111;
      end
      else
      if (sw_rst_i)
      begin
          r_filter_scl <= 3'b111;
          r_filter_sda <= 3'b111;
      end
      else if (r_filter_cnt == 'h0)
      begin
          r_filter_scl <= {r_filter_scl[1:0],r_sync_scl[1]};
          r_filter_sda <= {r_filter_sda[1:0],r_sync_sda[1]};
      end


    // generate filtered SCL and SDA signals. Use majority voting
    always @(posedge clk_i or negedge rstn_i)
      if (~rstn_i)
      begin
          sSCL <= 1'b1;
          sSDA <= 1'b1;

          dSCL <= 1'b1;
          dSDA <= 1'b1;
      end
      else
      begin
        if (sw_rst_i)
        begin
          sSCL <= 1'b1;
          sSDA <= 1'b1;

          dSCL <= 1'b1;
          dSDA <= 1'b1;
        end
        else
        begin
          sSCL <= &r_filter_scl[2:1] | &r_filter_scl[1:0] | (r_filter_scl[2] & r_filter_scl[0]);
          sSDA <= &r_filter_sda[2:1] | &r_filter_sda[1:0] | (r_filter_sda[2] & r_filter_sda[0]);

          dSCL <= sSCL;
          dSDA <= sSDA;
        end
      end

    //start/stop condition detector
    always @(posedge clk_i or negedge rstn_i)
      if (~rstn_i)
      begin
        r_start <= 1'b0;
        r_stop  <= 1'b0;
      end
      else
      begin
        if (sw_rst_i)
        begin
          r_start <= 1'b0;
          r_stop  <= 1'b0;
        end
        else
        begin
          r_start <= ~sSDA &  dSDA & sSCL; //falling edge on SDA while SCL high
          r_stop  <=  sSDA & ~dSDA & sSCL; //rising edge on SDA while SCL high
        end
      end


    // generate i2c bus busy signal
    always @(posedge clk_i or negedge rstn_i)
      if      (!rstn_i)
        busy_o <= 1'b0;
      else
        if (sw_rst_i)
          busy_o <= 1'b0;
        else
          busy_o <= (r_start | busy_o) & ~r_stop;


    // generate arbitration lost signal
    // aribitration lost when:
    // 1) master drives SDA high, but the i2c bus is low
    // 2) stop detected while not requested
    always @(posedge clk_i or negedge rstn_i)
      if (~rstn_i)
          r_cmd_stop <= 1'b0;
      else
      begin
        if (sw_rst_i)
          r_cmd_stop <= 1'b0;
        else if (cmd_valid_i)
          r_cmd_stop <= cmd_i == `BUS_CMD_STOP;
      end

    always @(posedge clk_i or negedge rstn_i)
      if (~rstn_i)
          al_o <= 1'b0;
      else
      begin
        if (sw_rst_i)
          al_o <= 1'b0;
        else
          al_o <= (sda_chk & ~sSDA & sda_oen) | ((CS != S_IDLE) & r_stop & ~r_cmd_stop);
      end


    // generate dout signal (store SDA on rising edge of SCL)
    always @(posedge clk_i, negedge rstn_i)
    begin
      if(rstn_i == 1'b0)
      begin
        dout_o <= 1'b1;
      end
      else
      begin
        if (sSCL & ~dSCL)
          dout_o <= sSDA;
      end
    end

    always @(posedge clk_i or negedge rstn_i)
      if (!rstn_i)
      begin
          CS <= S_IDLE;
          cmd_ack_o <= 1'b0;
          scl_oen   <= 1'b1;
          sda_oen   <= 1'b1;
          sda_chk   <= 1'b0;
      end
      else if (al_o || sw_rst_i)
      begin
          CS <= S_IDLE;
          cmd_ack_o <= 1'b0;
          scl_oen   <= 1'b1;
          sda_oen   <= 1'b1;
          sda_chk   <= 1'b0;
      end
      else
      begin
              case (CS) // synopsys full_case parallel_case
                    // S_IDLE state
                    S_IDLE:
                    begin
                      if (cmd_valid_i)
                      begin
                        case (cmd_i) // synopsys full_case parallel_case
                             `BUS_CMD_START: CS <= S_START_PHASE1;
                             `BUS_CMD_STOP:  CS <= S_STOP_PHASE1;
                             `BUS_CMD_WRITE: CS <= S_WR_PHASE1;
                             `BUS_CMD_READ:  CS <= S_RD_PHASE1;
                             `BUS_CMD_WAIT:  CS <= S_WAIT_PHASE1;
                             default:        CS <= S_IDLE;
                        endcase
                      end
                      scl_oen <= scl_oen; // keep SCL in same state
                      sda_oen <= sda_oen; // keep SDA in same state
                      sda_chk <= 1'b0;    // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_WAIT_PHASE1:
                    begin
                      if (clk_en)
                        CS <= S_WAIT_PHASE2;
                      scl_oen <= 1'b1;    // keep SCL in same state
                      sda_oen <= 1'b1;    // keep SDA in the same state
                      sda_chk <= 1'b0;    // don't check SDA output
                      cmd_ack_o <= 1'b0;  // default no command acknowledge
                    end

                    S_WAIT_PHASE2:
                    begin
                      if (clk_en)
                        CS <= S_WAIT_PHASE3;
                      scl_oen <= 1'b1;    // keep SCL in same state
                      sda_oen <= 1'b1;    // keep SDA in the same state
                      sda_chk <= 1'b0;    // don't check SDA output
                      cmd_ack_o <= 1'b0;  // default no command acknowledge
                    end

                    S_WAIT_PHASE3:
                    begin
                      if (clk_en)
                        CS <= S_WAIT_PHASE4;
                      scl_oen <= 1'b1;    // keep SCL in same state
                      sda_oen <= 1'b1;    // keep SDA in the same state
                      sda_chk <= 1'b0;    // don't check SDA output
                      cmd_ack_o <= 1'b0;  // default no command acknowledge
                    end

                    S_WAIT_PHASE4:
                    begin
                      if (clk_en)
                      begin
                        CS <= S_IDLE;
                        cmd_ack_o <= 1'b1;
                      end
                      else
                        cmd_ack_o <= 1'b0;    // default no command acknowledge
                      scl_oen <= 1'b1;    // keep SCL in same state
                      sda_oen <= 1'b1;    // keep SDA in the same state
                      sda_chk <= 1'b0;    // don't check SDA output
                    end

                    // start
                    S_START_PHASE1:
                    begin
                      if (clk_en)
                        CS <= S_START_PHASE2;
                      scl_oen <= scl_oen; // keep SCL in same state
                      sda_oen <= 1'b1;    // set SDA high
                      sda_chk <= 1'b0;    // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_START_PHASE2:
                    begin
                      if (clk_en)
                        CS <= S_START_PHASE3;
                      scl_oen <= 1'b1; // set SCL high
                      sda_oen <= 1'b1; // keep SDA high
                      sda_chk <= 1'b0; // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_START_PHASE3:
                    begin
                      if (clk_en)
                        CS <= S_START_PHASE4;
                      scl_oen <= 1'b1; // keep SCL high
                      sda_oen <= 1'b0; // set SDA low
                      sda_chk <= 1'b0; // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_START_PHASE4:
                    begin
                      if (clk_en)
                      begin
                        CS <= S_IDLE;
                        cmd_ack_o <= 1'b1;
                      end
                      else
                        cmd_ack_o <= 1'b0;    // default no command acknowledge
                      scl_oen <= 1'b0; // set SCL low
                      sda_oen <= 1'b0; // keep SDA low
                      sda_chk <= 1'b0; // don't check SDA output
                    end

                    // stop
                    S_STOP_PHASE1:
                    begin
                      if (clk_en)
                        CS <= S_STOP_PHASE2;
                      scl_oen <= 1'b0; // keep SCL low
                      sda_oen <= 1'b0; // set SDA low
                      sda_chk <= 1'b0; // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_STOP_PHASE2:
                    begin
                      if (clk_en)
                        CS <= S_STOP_PHASE3;
                      scl_oen <= 1'b1; // set SCL high
                      sda_oen <= 1'b0; // keep SDA low
                      sda_chk <= 1'b0; // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_STOP_PHASE3:
                    begin
                      if (clk_en)
                        CS <= S_STOP_PHASE4;
                      scl_oen <= 1'b1; // keep SCL high
                      sda_oen <= 1'b0; // keep SDA low
                      sda_chk <= 1'b0; // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_STOP_PHASE4:
                    begin
                      if (clk_en)
                      begin
                        CS <= S_IDLE;
                        cmd_ack_o <= 1'b1;
                      end
                      else
                        cmd_ack_o <= 1'b0;    // default no command acknowledge
                      scl_oen <= 1'b1; // keep SCL high
                      sda_oen <= 1'b1; // set SDA high
                      sda_chk <= 1'b0; // don't check SDA output
                    end

                    // read
                    S_RD_PHASE1:
                    begin
                      if (clk_en)
                        CS <= S_RD_PHASE2;
                      scl_oen <= 1'b0; // keep SCL low
                      sda_oen <= 1'b1; // tri-state SDA
                      sda_chk <= 1'b0; // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_RD_PHASE2:
                    begin
                      if (clk_en)
                        CS <= S_RD_PHASE3;
                        scl_oen <= 1'b1; // set SCL high
                        sda_oen <= 1'b1; // keep SDA tri-stated
                        sda_chk <= 1'b0; // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_RD_PHASE3:
                    begin
                      if (clk_en)
                        CS <= S_RD_PHASE4;
                      scl_oen <= 1'b1; // keep SCL high
                      sda_oen <= 1'b1; // keep SDA tri-stated
                      sda_chk <= 1'b0; // don't check SDA output
                      cmd_ack_o <= 1'b0;    // default no command acknowledge
                    end

                    S_RD_PHASE4:
                    begin
                      if (clk_en)
                      begin
                        CS <= S_IDLE;
                        cmd_ack_o <= 1'b1;
                      end
                      else
                        cmd_ack_o <= 1'b0;
                      scl_oen <= 1'b0; // set SCL low
                      sda_oen <= 1'b1; // keep SDA tri-stated
                      sda_chk <= 1'b0; // don't check SDA output
                    end

                    // write
                    S_WR_PHASE1:
                    begin
                      if (clk_en)
                        CS <= S_WR_PHASE2;
                      scl_oen <= 1'b0; // keep SCL low
                      sda_oen <= din_i;  // set SDA
                      sda_chk <= 1'b0; // don't check SDA output (SCL low)
                      cmd_ack_o <= 1'b0;
                    end

                    S_WR_PHASE2:
                    begin
                      if (clk_en)
                        CS <= S_WR_PHASE3;
                      scl_oen <= 1'b1; // set SCL high
                      sda_oen <= din_i;  // keep SDA
                      sda_chk <= 1'b0; // don't check SDA output yet
                                            // allow some time for SDA and SCL to settle
                      cmd_ack_o <= 1'b0;
                    end

                    S_WR_PHASE3:
                    begin
                      if (clk_en)
                        CS <= S_WR_PHASE4;
                      scl_oen <= 1'b1; // keep SCL high
                      sda_oen <= din_i;
                      sda_chk <= 1'b1; // check SDA output
                      cmd_ack_o <= 1'b0;
                    end

                    S_WR_PHASE4:
                    begin
                      if (clk_en)
                      begin
                        CS <= S_IDLE;
                        cmd_ack_o <= 1'b1;
                      end
                      else
                        cmd_ack_o <= 1'b0;
                      scl_oen <= 1'b0; // set SCL low
                      sda_oen <= din_i;
                      sda_chk <= 1'b0; // don't check SDA output (SCL low)
                    end

                    default:
                    begin
                      CS <= S_IDLE;
                      cmd_ack_o <= 1'b0;
                      scl_oen   <= 1'b1; // set SCL low
                      sda_oen   <= 1'b1;
                      sda_chk   <= 1'b0; // don't check SDA output (SCL low)
                    end

              endcase
      end


endmodule
