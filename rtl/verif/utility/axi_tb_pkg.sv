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

//  Description : AXI Testbench package
//                Contains all necessary type definitions, constants, and
//                generally useful functions.
//
/////////////////////////////////////////////////////////////////////////// 

package axi_tb_pkg;
    import tb_util_pkg::*;
    /// AXI Transaction Burst Width.
  parameter int unsigned BurstWidth  = 32'd2;
  /// AXI Transaction Response Width.
  parameter int unsigned RespWidth   = 32'd2;
  /// AXI Transaction Cacheability Width.
  parameter int unsigned CacheWidth  = 32'd4;
  /// AXI Transaction Protection Width.
  parameter int unsigned ProtWidth   = 32'd3;
  /// AXI Transaction Quality of Service Width.
  parameter int unsigned QosWidth    = 32'd4;
  /// AXI Transaction Region Width.
  parameter int unsigned RegionWidth = 32'd4;
  /// AXI Transaction Length Width.
  parameter int unsigned LenWidth    = 32'd8;
  /// AXI Transaction Size Width.
  parameter int unsigned SizeWidth   = 32'd3;
  /// AXI Lock Width.
  parameter int unsigned LockWidth   = 32'd1;
  /// AXI5 Atomic Operation Width.
  parameter int unsigned AtopWidth   = 32'd6;
  /// AXI5 Non-Secure Address Identifier.
  parameter int unsigned NsaidWidth  = 32'd4;

  /// AXI Transaction Burst Width.
  typedef logic [1:0]  burst_t;
  /// AXI Transaction Response Type.
  typedef logic [1:0]   resp_t;
  /// AXI Transaction Cacheability Type.
  typedef logic [3:0]  cache_t;
  /// AXI Transaction Protection Type.
  typedef logic [2:0]   prot_t;
  /// AXI Transaction Quality of Service Type.
  typedef logic [3:0]    qos_t;
  /// AXI Transaction Region Type.
  typedef logic [3:0] region_t;
  /// AXI Transaction Length Type.
  typedef logic [7:0]    len_t;
  /// AXI Transaction Size Type.
  typedef logic [2:0]   size_t;
  /// AXI5 Atomic Operation Type.
  typedef logic [5:0]   atop_t; // atomic operations
  /// AXI5 Non-Secure Address Identifier.
  typedef logic [3:0]  nsaid_t;

  /// In a fixed burst:
  /// - The address is the same for every transfer in the burst.
  /// - The byte lanes that are valid are constant for all beats in the burst.  However, within
  ///   those byte lanes, the actual bytes that have `wstrb` asserted can differ for each beat in
  ///   the burst.
  /// This burst type is used for repeated accesses to the same location such as when loading or
  /// emptying a FIFO.
  localparam BURST_FIXED = 2'b00;
  /// In an incrementing burst, the address for each transfer in the burst is an increment of the
  /// address for the previous transfer.  The increment value depends on the size of the transfer.
  /// For example, the address for each transfer in a burst with a size of 4 bytes is the previous
  /// address plus four.
  /// This burst type is used for accesses to normal sequential memory.
  localparam BURST_INCR  = 2'b01;
  /// A wrapping burst is similar to an incrementing burst, except that the address wraps around to
  /// a lower address if an upper address limit is reached.
  /// The following restrictions apply to wrapping bursts:
  /// - The start address must be aligned to the size of each transfer.
  /// - The length of the burst must be 2, 4, 8, or 16 transfers.
  localparam BURST_WRAP  = 2'b10;

  /// Normal access success.  Indicates that a normal access has been successful. Can also indicate
  /// that an exclusive access has failed.
  localparam RESP_OKAY   = 2'b00;
  /// Exclusive access okay.  Indicates that either the read or write portion of an exclusive access
  /// has been successful.
  localparam RESP_EXOKAY = 2'b01;
  /// Slave error.  Used when the access has reached the slave successfully, but the slave wishes to
  /// return an error condition to the originating master.
  localparam RESP_SLVERR = 2'b10;
  /// Decode error.  Generated, typically by an interconnect component, to indicate that there is no
  /// slave at the transaction address.
  localparam RESP_DECERR = 2'b11;

  /// When this bit is asserted, the interconnect, or any component, can delay the transaction
  /// reaching its final destination for any number of cycles.
  localparam CACHE_BUFFERABLE = 4'b0001;
  /// When HIGH, Modifiable indicates that the characteristics of the transaction can be modified.
  /// When Modifiable is LOW, the transaction is Non-modifiable.
  localparam CACHE_MODIFIABLE = 4'b0010;
  /// When this bit is asserted, read allocation of the transaction is recommended but is not
  /// mandatory.
  localparam CACHE_RD_ALLOC   = 4'b0100;
  /// When this bit is asserted, write allocation of the transaction is recommended but is not
  /// mandatory.
  localparam CACHE_WR_ALLOC   = 4'b1000;

  /// Maximum number of bytes per burst, as specified by `size` (see Table A3-2).
  function automatic shortint unsigned num_bytes(size_t size);
    return 1 << size;
  endfunction

  /// An overly long address type.
  /// It lets us define functions that work generically for shorter addresses.  We rely on the
  /// synthesizer to optimize the unused bits away.
  typedef logic [127:0] largest_addr_t;

  /// Aligned address of burst (see A3-51).
  function automatic largest_addr_t aligned_addr(largest_addr_t addr, size_t size);
    return (addr >> size) << size;
  endfunction

  /// Warp boundary of a `BURST_WRAP` transfer (see A3-51).
  /// This is the lowest address accessed within a wrapping burst.
  /// This address is aligned to the size and length of the burst.
  /// The length of a `BURST_WRAP` has to be 2, 4, 8, or 16 transfers.
  function automatic largest_addr_t wrap_boundary (largest_addr_t addr, size_t size, len_t len);
    largest_addr_t wrap_addr;

    // pragma translate_off
    `ifndef VERILATOR
      assume (len == len_t'(4'b1) || len == len_t'(4'b11) || len == len_t'(4'b111) ||
          len == len_t'(4'b1111)) else
        $error("AXI BURST_WRAP with not allowed len of: %0h", len);
    `endif
    // pragma translate_on

    // In A3-51 the wrap boundary is defined as:
    // `Wrap_Boundary = (INT(Start_Address / (Number_Bytes × Burst_Length))) ×
    //    (Number_Bytes × Burst_Length)`
    // Whereas the aligned address is defined as:
    // `Aligned_Address = (INT(Start_Address / Number_Bytes)) × Number_Bytes`
    // This leads to the wrap boundary using the same calculation as the aligned address, difference
    // being the additional dependency on the burst length. The addition in the case statement
    // is equal to the multiplication with `Burst_Length` as a shift (used by `aligned_addr`) is
    // equivalent with multiplication and division by a power of two, which conveniently are the
    // only allowed values for `len` of a `BURST_WRAP`.
    unique case (len)
      4'b1    : wrap_addr = (addr >> (unsigned'(size) + 1)) << (unsigned'(size) + 1); // multiply `Number_Bytes` by `2`
      4'b11   : wrap_addr = (addr >> (unsigned'(size) + 2)) << (unsigned'(size) + 2); // multiply `Number_Bytes` by `4`
      4'b111  : wrap_addr = (addr >> (unsigned'(size) + 3)) << (unsigned'(size) + 3); // multiply `Number_Bytes` by `8`
      4'b1111 : wrap_addr = (addr >> (unsigned'(size) + 4)) << (unsigned'(size) + 4); // multiply `Number_Bytes` by `16`
      default : wrap_addr = '0;
    endcase
    return wrap_addr;
  endfunction

  /// Address of beat (see A3-51).
  function automatic largest_addr_t
  beat_addr(largest_addr_t addr, size_t size, len_t len, burst_t burst, shortint unsigned i_beat);
    largest_addr_t ret_addr = addr;
    largest_addr_t wrp_bond = '0;
    if (burst == BURST_WRAP) begin
      // do not trigger the function if there is no wrapping burst, to prevent assumptions firing
      wrp_bond = wrap_boundary(addr, size, len);
    end
    if (i_beat != 0 && burst != BURST_FIXED) begin
      // From A3-51:
      // For an INCR burst, and for a WRAP burst for which the address has not wrapped, this
      // equation determines the address of any transfer after the first transfer in a burst:
      // `Address_N = Aligned_Address + (N – 1) × Number_Bytes` (N counts from 1 to len!)
      ret_addr = aligned_addr(addr, size) + i_beat * num_bytes(size);
      // From A3-51:
      // For a WRAP burst, if Address_N = Wrap_Boundary + (Number_Bytes × Burst_Length), then:
      // * Use this equation for the current transfer:
      //     `Address_N = Wrap_Boundary`
      // * Use this equation for any subsequent transfers:
      //     `Address_N = Start_Address + ((N – 1) × Number_Bytes) – (Number_Bytes × Burst_Length)`
      // This means that the address calculation of a `BURST_WRAP` fundamentally works the same
      // as for a `BURST_INC`, the difference is when the calculated address increments
      // over the wrap threshold, the address wraps around by subtracting the accessed address
      // space from the normal `BURST_INCR` address. The lower wrap boundary is equivalent to
      // The wrap trigger condition minus the container size (`num_bytes(size) * (len + 1)`).
      if (burst == BURST_WRAP && ret_addr >= wrp_bond + (num_bytes(size) * (len + 1))) begin
        ret_addr = ret_addr - (num_bytes(size) * (len + 1));
      end
    end
    return ret_addr;
  endfunction

  /// Index of lowest byte in beat (see A3-51).
  function automatic shortint unsigned
  beat_lower_byte(largest_addr_t addr, size_t size, len_t len, burst_t burst,
      shortint unsigned strobe_width, shortint unsigned i_beat);
    largest_addr_t _addr = beat_addr(addr, size, len, burst, i_beat);
    return shortint'(_addr - (_addr / strobe_width) * strobe_width);
  endfunction

  /// Index of highest byte in beat (see A3-51).
  function automatic shortint unsigned
  beat_upper_byte(largest_addr_t addr, size_t size, len_t len, burst_t burst,
      shortint unsigned strobe_width, shortint unsigned i_beat);
    if (i_beat == 0) begin
      return aligned_addr(addr, size) + (num_bytes(size) - 1) - (addr / strobe_width) * strobe_width;
    end else begin
      return beat_lower_byte(addr, size, len, burst, strobe_width, i_beat) + num_bytes(size) - 1;
    end
  endfunction

  /// Is the bufferable bit set?
  function automatic logic bufferable(cache_t cache);
    return |(cache & CACHE_BUFFERABLE);
  endfunction

  /// Is the modifiable bit set?
  function automatic logic modifiable(cache_t cache);
    return |(cache & CACHE_MODIFIABLE);
  endfunction

  /// Memory Type.
  typedef enum logic [3:0] {
    DEVICE_NONBUFFERABLE,
    DEVICE_BUFFERABLE,
    NORMAL_NONCACHEABLE_NONBUFFERABLE,
    NORMAL_NONCACHEABLE_BUFFERABLE,
    WTHRU_NOALLOCATE,
    WTHRU_RALLOCATE,
    WTHRU_WALLOCATE,
    WTHRU_RWALLOCATE,
    WBACK_NOALLOCATE,
    WBACK_RALLOCATE,
    WBACK_WALLOCATE,
    WBACK_RWALLOCATE
  } mem_type_t;

  /// Create an `AR_CACHE` field from a `mem_type_t` type.
  function automatic logic [3:0] get_arcache(mem_type_t mtype);
    unique case (mtype)
      DEVICE_NONBUFFERABLE              : return 4'b0000;
      DEVICE_BUFFERABLE                 : return 4'b0001;
      NORMAL_NONCACHEABLE_NONBUFFERABLE : return 4'b0010;
      NORMAL_NONCACHEABLE_BUFFERABLE    : return 4'b0011;
      WTHRU_NOALLOCATE                  : return 4'b1010;
      WTHRU_RALLOCATE                   : return 4'b1110;
      WTHRU_WALLOCATE                   : return 4'b1010;
      WTHRU_RWALLOCATE                  : return 4'b1110;
      WBACK_NOALLOCATE                  : return 4'b1011;
      WBACK_RALLOCATE                   : return 4'b1111;
      WBACK_WALLOCATE                   : return 4'b1011;
      WBACK_RWALLOCATE                  : return 4'b1111;
    endcase // mtype
  endfunction

  /// Create an `AW_CACHE` field from a `mem_type_t` type.
  function automatic logic [3:0] get_awcache(mem_type_t mtype);
    unique case (mtype)
      DEVICE_NONBUFFERABLE              : return 4'b0000;
      DEVICE_BUFFERABLE                 : return 4'b0001;
      NORMAL_NONCACHEABLE_NONBUFFERABLE : return 4'b0010;
      NORMAL_NONCACHEABLE_BUFFERABLE    : return 4'b0011;
      WTHRU_NOALLOCATE                  : return 4'b0110;
      WTHRU_RALLOCATE                   : return 4'b0110;
      WTHRU_WALLOCATE                   : return 4'b1110;
      WTHRU_RWALLOCATE                  : return 4'b1110;
      WBACK_NOALLOCATE                  : return 4'b0111;
      WBACK_RALLOCATE                   : return 4'b0111;
      WBACK_WALLOCATE                   : return 4'b1111;
      WBACK_RWALLOCATE                  : return 4'b1111;
    endcase // mtype
  endfunction

  /// RESP precedence: DECERR > SLVERR > OKAY > EXOKAY.  This is not defined in the AXI standard but
  /// depends on the implementation.  We consistently use the precedence above.  Rationale:
  /// - EXOKAY means an exclusive access was successful, whereas OKAY means it was not.  Thus, if
  ///   OKAY and EXOKAY are to be merged, OKAY precedes because the exclusive access was not fully
  ///   successful.
  /// - Both DECERR and SLVERR mean (part of) a transaction were unsuccessful, whereas OKAY means an
  ///   entire transaction was successful.  Thus both DECERR and SLVERR precede OKAY.
  /// - DECERR means (part of) a transactions could not be routed to a slave component, whereas
  ///   SLVERR means the transaction reached a slave component but lead to an error condition there.
  ///   Thus DECERR precedes SLVERR because DECERR happens earlier in the handling of a transaction.
  function automatic resp_t resp_precedence(resp_t resp_a, resp_t resp_b);
    unique case (resp_a)
      RESP_OKAY: begin
        // Any response except EXOKAY precedes OKAY.
        if (resp_b == RESP_EXOKAY) begin
          return resp_a;
        end else begin
          return resp_b;
        end
      end
      RESP_EXOKAY: begin
        // Any response precedes EXOKAY.
        return resp_b;
      end
      RESP_SLVERR: begin
        // Only DECERR precedes SLVERR.
        if (resp_b == RESP_DECERR) begin
          return resp_b;
        end else begin
          return resp_a;
        end
      end
      RESP_DECERR: begin
        // No response precedes DECERR.
        return resp_a;
      end
    endcase
  endfunction

  /// AW Width: Returns the width of the AW channel payload
  function automatic int unsigned aw_width(int unsigned addr_width, int unsigned id_width,
                                           int unsigned user_width );
    // Sum the individual bit widths of the signals
    return (id_width + addr_width + LenWidth + SizeWidth + BurstWidth + LockWidth + CacheWidth +
            ProtWidth + QosWidth + RegionWidth + AtopWidth + user_width );
  endfunction

  /// W Width: Returns the width of the W channel payload
  function automatic int unsigned w_width(int unsigned data_width, int unsigned user_width );
    // Sum the individual bit widths of the signals
    return (data_width + data_width / 32'd8 + 32'd1 + user_width);
    //                   ^- StrobeWidth       ^- LastWidth
  endfunction

  /// B Width: Returns the width of the B channel payload
  function automatic int unsigned b_width(int unsigned id_width, int unsigned user_width );
    // Sum the individual bit widths of the signals
    return (id_width + RespWidth + user_width);
  endfunction

  /// AR Width: Returns the width of the AR channel payload
  function automatic int unsigned ar_width(int unsigned addr_width, int unsigned id_width,
                                           int unsigned user_width );
    // Sum the individual bit widths of the signals
    return (id_width + addr_width + LenWidth + SizeWidth + BurstWidth + LockWidth + CacheWidth +
            ProtWidth + QosWidth + RegionWidth + user_width );
  endfunction

  /// R Width: Returns the width of the R channel payload
  function automatic int unsigned r_width(int unsigned data_width, int unsigned id_width,
                                          int unsigned user_width );
    // Sum the individual bit widths of the signals
    return (id_width + data_width + RespWidth + 32'd1 + user_width);
    //                                          ^- LastWidth
  endfunction

  /// Request Width: Returns the width of the request channel
  function automatic int unsigned req_width(int unsigned addr_width,    int unsigned data_width,
                                            int unsigned id_width,      int unsigned aw_user_width,
                                            int unsigned ar_user_width, int unsigned w_user_width   );
    // Sum the individual bit widths of the signals and their handshakes
    //                                                      v- valids
    return (aw_width(addr_width, id_width, aw_user_width) + 32'd1 +
            w_width(data_width, w_user_width)             + 32'd1 +
            ar_width(addr_width, id_width, ar_user_width) + 32'd1 + 32'd1 + 32'd1 );
    //                                                              ^- R,   ^- B ready
  endfunction

  /// Response Width: Returns the width of the response channel
  function automatic int unsigned rsp_width(int unsigned data_width,   int unsigned id_width,
                                            int unsigned r_user_width, int unsigned b_user_width );
    // Sum the individual bit widths of the signals and their handshakes
    //                                                    v- valids
    return (r_width(data_width, id_width, r_user_width) + 32'd1 +
            b_width(id_width, b_user_width)             + 32'd1 + 32'd1 + 32'd1 + 32'd1);
    //                                                            ^- AW,  ^- AR,  ^- W ready
  endfunction

  // ATOP[5:0]
  /// - Sends a single data value with an address.
  /// - The target swaps the value at the addressed location with the data value that is supplied in
  ///   the transaction.
  /// - The original data value at the addressed location is returned.
  /// - Outbound data size is 1, 2, 4, or 8 bytes.
  /// - Inbound data size is the same as the outbound data size.
  localparam ATOP_ATOMICSWAP  = 6'b110000;
  /// - Sends two data values, the compare value and the swap value, to the addressed location.
  ///   The compare and swap values are of equal size.
  /// - The data value at the addressed location is checked against the compare value:
  ///   - If the values match, the swap value is written to the addressed location.
  ///   - If the values do not match, the swap value is not written to the addressed location.
  /// - The original data value at the addressed location is returned.
  /// - Outbound data size is 2, 4, 8, 16, or 32 bytes.
  /// - Inbound data size is half of the outbound data size because the outbound data contains both
  ///   compare and swap values, whereas the inbound data has only the original data value.
  localparam ATOP_ATOMICCMP   = 6'b110001;
  // ATOP[5:4]
  /// Perform no atomic operation.
  localparam ATOP_NONE        = 2'b00;
  /// - Sends a single data value with an address and the atomic operation to be performed.
  /// - The target performs the operation using the sent data and value at the addressed location as
  ///   operands.
  /// - The result is stored in the address location.
  /// - A single response is given without data.
  /// - Outbound data size is 1, 2, 4, or 8 bytes.
  localparam ATOP_ATOMICSTORE = 2'b01;
  /// Sends a single data value with an address and the atomic operation to be performed.
  /// - The original data value at the addressed location is returned.
  /// - The target performs the operation using the sent data and value at the addressed location as
  ///   operands.
  /// - The result is stored in the address location.
  /// - Outbound data size is 1, 2, 4, or 8 bytes.
  /// - Inbound data size is the same as the outbound data size.
  localparam ATOP_ATOMICLOAD  = 2'b10;
  // ATOP[3]
  /// For AtomicStore and AtomicLoad transactions `AWATOP[3]` indicates the endianness that is
  /// required for the atomic operation.  The value of `AWATOP[3]` applies to arithmetic operations
  /// only and is ignored for bitwise logical operations.
  /// When deasserted, this bit indicates that the operation is little-endian.
  localparam ATOP_LITTLE_END  = 1'b0;
  /// When asserted, this bit indicates that the operation is big-endian.
  localparam ATOP_BIG_END     = 1'b1;
  // ATOP[2:0]
  /// The value in memory is added to the sent data and the result stored in memory.
  localparam ATOP_ADD   = 3'b000;
  /// Every set bit in the sent data clears the corresponding bit of the data in memory.
  localparam ATOP_CLR   = 3'b001;
  /// Bitwise exclusive OR of the sent data and value in memory.
  localparam ATOP_EOR   = 3'b010;
  /// Every set bit in the sent data sets the corresponding bit of the data in memory.
  localparam ATOP_SET   = 3'b011;
  /// The value stored in memory is the maximum of the existing value and sent data. This operation
  /// assumes signed data.
  localparam ATOP_SMAX  = 3'b100;
  /// The value stored in memory is the minimum of the existing value and sent data. This operation
  /// assumes signed data.
  localparam ATOP_SMIN  = 3'b101;
  /// The value stored in memory is the maximum of the existing value and sent data. This operation
  /// assumes unsigned data.
  localparam ATOP_UMAX  = 3'b110;
  /// The value stored in memory is the minimum of the existing value and sent data. This operation
  /// assumes unsigned data.
  localparam ATOP_UMIN  = 3'b111;
  // ATOP[5] == 1'b1 indicated that an atomic transaction has a read response
  // Ussage eg: if (req_i.aw.atop[axi_tb_pkg::ATOP_R_RESP]) begin
  localparam ATOP_R_RESP = 32'd5;

  // `xbar_latency_e` and `xbar_cfg_t` are documented in `doc/axi_xbar.md`.
  /// Slice on Demux AW channel.
  localparam bit [9:0] DemuxAw = (1 << 9);
  /// Slice on Demux W channel.
  localparam bit [9:0] DemuxW  = (1 << 8);
  /// Slice on Demux B channel.
  localparam bit [9:0] DemuxB  = (1 << 7);
  /// Slice on Demux AR channel.
  localparam bit [9:0] DemuxAr = (1 << 6);
  /// Slice on Demux R channel.
  localparam bit [9:0] DemuxR  = (1 << 5);
  /// Slice on Mux AW channel.
  localparam bit [9:0] MuxAw   = (1 << 4);
  /// Slice on Mux W channel.
  localparam bit [9:0] MuxW    = (1 << 3);
  /// Slice on Mux B channel.
  localparam bit [9:0] MuxB    = (1 << 2);
  /// Slice on Mux AR channel.
  localparam bit [9:0] MuxAr   = (1 << 1);
  /// Slice on Mux R channel.
  localparam bit [9:0] MuxR    = (1 << 0);
  /// Latency configuration for `axi_xbar`.
  typedef enum bit [9:0] {
    NO_LATENCY    = 10'b000_00_000_00,
    CUT_SLV_AX    = DemuxAw | DemuxAr,
    CUT_MST_AX    = MuxAw | MuxAr,
    CUT_ALL_AX    = DemuxAw | DemuxAr | MuxAw | MuxAr,
    CUT_SLV_PORTS = DemuxAw | DemuxW | DemuxB | DemuxAr | DemuxR,
    CUT_MST_PORTS = MuxAw | MuxW | MuxB | MuxAr | MuxR,
    CUT_ALL_PORTS = 10'b111_11_111_11
  } xbar_latency_e;

  /// Configuration for `axi_xbar`.
  typedef struct packed {
    /// Number of slave ports of the crossbar.
    /// This many master modules are connected to it.
    int unsigned   NoSlvPorts;
    /// Number of master ports of the crossbar.
    /// This many slave modules are connected to it.
    int unsigned   NoMstPorts;
    /// Maximum number of open transactions each master connected to the crossbar can have in
    /// flight at the same time.
    int unsigned   MaxMstTrans;
    /// Maximum number of open transactions each slave connected to the crossbar can have in
    /// flight at the same time.
    int unsigned   MaxSlvTrans;
    /// Determine if the internal FIFOs of the crossbar are instantiated in fallthrough mode.
    /// 0: No fallthrough
    /// 1: Fallthrough
    bit            FallThrough;
    /// The Latency mode of the xbar. This determines if the channels on the ports have
    /// a spill register instantiated.
    /// Example configurations are provided with the enum `xbar_latency_e`.
    bit [9:0]      LatencyMode;
    /// This is the number of `axi_multicut` stages instantiated in the line cross of the channels.
    /// Having multiple stages can potentially add a large number of FFs!
    int unsigned   PipelineStages;
    /// AXI ID width of the salve ports. The ID width of the master ports is determined
    /// Automatically. See `axi_mux` for details.
    int unsigned   AxiIdWidthSlvPorts;
    /// The used ID portion to determine if a different salve is used for the same ID.
    /// See `axi_demux` for details.
    int unsigned   AxiIdUsedSlvPorts;
    /// Are IDs unique?
    bit            UniqueIds;
    /// AXI4+ATOP address field width.
    int unsigned   AxiAddrWidth;
    /// AXI4+ATOP data field width.
    int unsigned   AxiDataWidth;
    /// The number of address rules defined for routing of the transactions.
    /// Each master port can have multiple rules, should have however at least one.
    /// If a transaction can not be routed the xbar will answer with an `axi_tb_pkg::RESP_DECERR`.
    int unsigned   NoAddrRules;
  } xbar_cfg_t;

  /// Commonly used rule types for `axi_xbar` (64-bit addresses).
  typedef struct packed {
    int unsigned idx;
    logic [63:0] start_addr;
    logic [63:0] end_addr;
  } xbar_rule_64_t;

  /// Commonly used rule types for `axi_xbar` (32-bit addresses).
  typedef struct packed {
    int unsigned idx;
    logic [31:0] start_addr;
    logic [31:0] end_addr;
  } xbar_rule_32_t;

/*! \typedef burst_size_t */
/** \brief Size of beat in bytes. (How many bytes of the data bus are used each beat(clk).
*/
typedef enum logic [2:0] {e_1BYTE    = 3'b000, /**< Transfer 1 byte per beat (regardless of bus width) */
                          e_2BYTES   = 3'b001, /**< Transfer 2 bytes per beat (regardles of bus width). Bus must be at least 2-bytes wide */
                          e_4BYTES   = 3'b010, /**< Transfer 4 bytes per beat (regardles of bus width). Bus must be at least 4-bytes wide */
                          e_8BYTES   = 3'b011, /**< Transfer 8 bytes per beat (regardles of bus width). Bus must be at least 8-bytes wide */
                          e_16BYTES  = 3'b100, /**< Transfer 16 bytes per beat (regardles of bus width). Bus must be at least 16-bytes wide */
                          e_32BYTES  = 3'b101, /**< Transfer 32 bytes per beat (regardles of bus width). Bus must be at least 32-bytes wide */
                          e_64BYTES  = 3'b110, /**< Transfer 64 bytes per beat (regardles of bus width). Bus must be at least 64-bytes wide */
                          e_128BYTES = 3'b111 /**< Transfer 128 bytes per beat (regardles of bus width). Bus must be at least 128-bytes wide */
                         } burst_size_t;

/*! \typedef burst_type_t */
/** \brief Does the address stay fixed, increment, or wrap during the burst?
*/
typedef enum logic [1:0] {e_FIXED    = 2'b00, /**< The address doesn't change during the burst. Example: burstin to fifo */
                          e_INCR     = 2'b01, /**< The address increments during the burst. Example: bursting to memmory */
                          e_WRAP     = 2'b10, /**< The address wraps to a lower address once it hits the higher address. Refer to AXI Spec section A3.4.1 for details.  Example:  cache line accesses */
                          e_RESERVED = 2'b11
                         } burst_type_t;

/*! \typedef response_type_t */
/** \brief Write response values
*/
typedef enum logic [1:0] {e_OKAY    = 2'b00, /**< Normal access success. */
                          e_EXOKAY  = 2'b01, /**< Exlusive access okay. */
                          e_SLVERR  = 2'b10, /**< Slave error. Slave received data successfully but wants to return error condition */
                          e_DECERR  = 2'b11  /**< Decode error.  Generated typically by interconnect to signify no slave at that address */
                         } response_type_t;


/*! \struct axi_seq_item_aw_vector_s
 *  \brief This packed struct is used to send write address channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [AXI_ID_WIDTH-1:0]	 awid;  /*!< Write address ID tag - A matching write response ID, bid, will be expected */
  logic [AXI_ADDR_WIDTH-1:0]   awaddr; /*!< Starting burst address */
  logic                          awvalid; /*!< Values on write address channel are valid and won't change until awready is recieved */
  logic                          awready; /*!< Slave is ready to receive write address channel information */
  logic [AXI_LEN_WIDTH-1:0]    awlen;   /*!< Length, in beats/clks, of the matching write data burst */
  logic [2:0]                    awsize;  /*!< beat size.  How many bytes wide are the beats in the write data transfer */
  logic [1:0]                    awburst; /*!< address burst mode.  fixed, incrementing, or wrap */
  logic [0:0]                    awlock; /*!< Used for locked transactions in AXI3 */
  logic [3:0]                    awcache; /*!< Memory type. See AXI spec Memory Type A4-65 */
  logic [2:0]                    awprot; /*!< Protected transaction.  AXI4 only */
  logic [3:0]                    awqos; /*!< Quality of service. AXI4 only */

} axi_seq_item_aw_vector_s;

localparam int AXI_SEQ_ITEM_AW_NUM_BITS = $bits(axi_seq_item_aw_vector_s); /*!< Used to calculate the length of the bit vector
                                                                             containing the packed write address struct  */

/** \brief Bit vector containing packed write address channel values */
typedef bit[AXI_SEQ_ITEM_AW_NUM_BITS-1:0] axi_seq_item_aw_vector_t;


/*! \struct axi_seq_item_w_vector_s
 *  \brief This packed struct is used to send write data channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [AXI_DATA_WIDTH-1:0]   wdata; /*!< Write Data    */
  logic [AXI_DATA_WIDTH/8-1:0] wstrb;  /*!< Write strobe.  Indicates which byte lanes hold valid data.    */
  logic                          wlast;/*!<  Write last.  Indicates last beat in a write burst.   */
  logic                          wvalid;/*!<  Write valid.  Values on write data channel are valid and won't change until wready is recieved   */
  logic [AXI_ID_WIDTH-1:0]     wid;/*!<  Write ID tag.  AXI3 only   */

} axi_seq_item_w_vector_s;

localparam int AXI_SEQ_ITEM_W_NUM_BITS = $bits(axi_seq_item_w_vector_s);  /*!< Used to calculate the length of the bit vector
                                                                               containing the packed write data struct */

/** \brief Bit vector containing packed write data channel values */
typedef bit[AXI_SEQ_ITEM_W_NUM_BITS-1:0] axi_seq_item_w_vector_t;


/*! \struct axi_seq_item_b_vector_s
 *  \brief This packed struct is used to send write response channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [AXI_ID_WIDTH-1:0]     bid; /*!< Write Response ID tag    */
  logic [1:0]                    bresp; /*!< Write Response.Indicates status of the write data transaction.    */
} axi_seq_item_b_vector_s;

localparam int AXI_SEQ_ITEM_B_NUM_BITS = $bits(axi_seq_item_b_vector_s); /*!< Used to calculate the length of the bit vector
                                                                              containing the packed write response struct */

/** \brief Bit vector containing packed write response channel values */
typedef bit[AXI_SEQ_ITEM_B_NUM_BITS-1:0] axi_seq_item_b_vector_t;

/*! \struct axi_seq_item_ar_vector_s
 *  \brief This packed struct is used to send read address channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [AXI_ID_WIDTH-1:0]	 arid; /*!< Read address ID tag - A matching read data ID, rid, will be expected */
  logic [AXI_ADDR_WIDTH-1:0]   araddr; /*!< Starting burst address */
  logic                          arvalid;/*!< Values on read address channel are valid and won't change until arready is recieved */
  logic                          arready;/*!< Slave is ready to receive read address channel information */
  logic [AXI_LEN_WIDTH-1:0]    arlen;/*!< Length, in beats/clks, of the matching read data burst */
  logic [2:0]  arsize;/*!< beat size.  How many bytes wide are the beats in the write data transfer */
  logic [1:0]  arburst;/*!< address burst mode.  fixed, incrementing, or wrap */
  logic [0:0]                    arlock; /*!< Used for locked transactions in AXI3 */
  logic [3:0]                    arcache;/*!< Memory type. See AXI spec Memory Type A4-65 */
  logic [2:0]                    arprot;/*!< Protected transaction.  AXI4 only */
  logic [3:0]                    arqos;/*!< Quality of service. AXI4 only */

} axi_seq_item_ar_vector_s;

localparam int AXI_SEQ_ITEM_AR_NUM_BITS = $bits(axi_seq_item_ar_vector_s);    /*!< Used to calculate the length of the bit vector
                                                                                   containing the packed read address struct */

/** \brief Bit vector containing packed read address channel values */
typedef bit[AXI_SEQ_ITEM_AR_NUM_BITS-1:0] axi_seq_item_ar_vector_t;


/*! \struct axi_seq_item_r_vector_s
 *  \brief This packed struct is used to send read data channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [AXI_DATA_WIDTH-1:0]   rdata; /*!< Write Data  */
  logic [1:0]                    rresp; /*!< Read Response.Indicates status of the read data transfer (of the same beat). */
  logic                          rlast; /*!< Read last.  Indicates last beat in a read burst. */
  logic                          rvalid; /*!< Write valid.  Values on read data channel are valid and won't change until rready is recieved*/
  logic [AXI_ID_WIDTH-1:0]     rid; /*!< Read ID tag. */

} axi_seq_item_r_vector_s;

localparam int AXI_SEQ_ITEM_R_NUM_BITS = $bits(axi_seq_item_r_vector_s);     /*!< Used to calculate the length of the bit vector
                                                                                  containing the packed read data struct */

/** \brief Bit vector containing packed read data channel values */
typedef bit[AXI_SEQ_ITEM_R_NUM_BITS-1:0] axi_seq_item_r_vector_t;

/** \brief calculate burst_size aligned address
 *
 * The AXI function to calculate aligned address is:
 * Aligned_Address = (Address/(2**burst_size)*(2**burst_size)
 * Zeroing out the bottom burst_size bits does the same thing
 * which is much more eaily synthesizable.
 * @param address - starting address
 * @param burst_size - how many bytes wide is the beat
 * @returns the burst_size aligned address
*/
function bit [AXI_ADDR_WIDTH-1:0] calculate_burst_aligned_address(
  input bit [AXI_ADDR_WIDTH-1:0] address,
  input bit [2:0]                  burst_size);


  bit [AXI_ADDR_WIDTH-1:0] aligned_address;

  // This can be done in a nice function, but this case
  // is immediatly understandable.
  aligned_address = address;
  case (burst_size)
    e_1BYTE    : aligned_address      = address;
    e_2BYTES   : aligned_address[0]   = 1'b0;
    e_4BYTES   : aligned_address[1:0] = 2'b00;
    e_8BYTES   : aligned_address[2:0] = 3'b000;
    e_16BYTES  : aligned_address[3:0] = 4'b0000;
    e_32BYTES  : aligned_address[4:0] = 5'b0_0000;
    e_64BYTES  : aligned_address[5:0] = 6'b00_0000;
    e_128BYTES : aligned_address[6:0] = 7'b000_0000;
  endcase

  //`uvm_info("axi_pkg::calculatate-aligned_adress",
  //          $sformatf("address: 0x%0x burst_size:%0d alignedaddress: 0x%0x",
  //                    address, burst_size, aligned_address),
  //          UVM_HIGH)
  $display("axi_pkg::calculatate-aligned_adress",
           $sformatf("address: 0x%0x burst_size:%0d alignedaddress: 0x%0x",
                      address, burst_size, aligned_address));

  return aligned_address;

endfunction : calculate_burst_aligned_address


/** \brief calculate bus-siz aligned address
 *
 * The AXI function to calculate aligned address is:
 * Aligned_Address = (Address/(2**bus_size)*(2**bus_sze)
 * Zeroing out the bottom burst_size bits does the same thing
 * which is much more eaily synthesizable.
 * @param addr - starting address
 * @param bus_size - how many bytes wide is the bus
 * @returns the bus_size aligned address
 * \todo: bus_size could be byte instead of int?
*/
function bit [AXI_ADDR_WIDTH-1:0] calculate_bus_aligned_address(
  input bit [AXI_ADDR_WIDTH-1:0] addr,
  input int                       bus_size);

  bit [AXI_ADDR_WIDTH-1:0] aligned_address;

  string msg_s;

  aligned_address = addr;

  case (bus_size)
    2**e_1BYTE    : aligned_address      = addr;
    2**e_2BYTES   : aligned_address[0]   = 1'b0;
    2**e_4BYTES   : aligned_address[1:0] = 2'b00;
    2**e_8BYTES   : aligned_address[2:0] = 3'b000;
    2**e_16BYTES  : aligned_address[3:0] = 4'b0000;
    2**e_32BYTES  : aligned_address[4:0] = 5'b0_0000;
    2**e_64BYTES  : aligned_address[5:0] = 6'b00_0000;
    2**e_128BYTES : aligned_address[6:0] = 7'b000_0000;
  endcase


  msg_s="";
  $sformat(msg_s, "%s addr: 0x%0x", msg_s, addr);
  $sformat(msg_s, "%s aligned_address: 0x%0x", msg_s, aligned_address);
  $sformat(msg_s, "%s bus_size: 0x%0x", msg_s, bus_size);


  //`uvm_info("calculate_bus_aligned_address", msg_s,UVM_HIGH)

  return aligned_address;

endfunction : calculate_bus_aligned_address


/** \brief calculate awlen or arlen
 *
 *  Calculate the number of beats -1
 * for a burst.  Subtract one because
 * awlen and arlen are one less than
 * the transfer count.  awlen=0,
 * means 1 beat.
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @param burst_length - how many bytes long is the burst
 * @returns the burst_size aligned address
*/
function bit [AXI_LEN_WIDTH-1:0] calculate_axlen(
  input bit [AXI_ADDR_WIDTH-1:0] addr,
  input bit [2:0]                  burst_size,
  input shortint                   burst_length);


  byte unalignment_offset;
  shortint total_length;
  shortint shifter;
  shortint ishifter;
  bit [AXI_LEN_WIDTH-1:0] beats;

  string msg_s;

  unalignment_offset = calculate_unalignment_offset(
                            .addr(addr),
                            .burst_size(burst_size));

  total_length=burst_length + unalignment_offset;

  shifter = shortint'(total_length/(2**burst_size));

  ishifter = shifter*(2**burst_size);

  if (ishifter != total_length) begin
    shifter += 1;
  end

  beats = shifter - 1;


  msg_s="";
  $sformat(msg_s, "%s addr: 0x%0x",     msg_s, addr);
  $sformat(msg_s, "%s burst_size: %0d", msg_s, burst_size);
  $sformat(msg_s, "%s unalignment_offset: %0d", msg_s, unalignment_offset);
  $sformat(msg_s, "%s burst_length: %0d", msg_s, burst_length);
  $sformat(msg_s, "%s total_length: %0d", msg_s, total_length);
  $sformat(msg_s, "%s shifter: %0d", msg_s, shifter);
  $sformat(msg_s, "%s ishifter: %0d", msg_s, ishifter);

  //`uvm_info("axi_pkg::calculate_beats",
  //          msg_s,
  //          UVM_HIGH)

  return beats;

endfunction : calculate_axlen

/** \brief calculate how unaligned the address is from the burst size
 *
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @returns how many bytes the address is unaligned from the burst_size
*/
function byte calculate_unalignment_offset(
  input bit [AXI_ADDR_WIDTH-1:0] addr,
  input byte                  burst_size);

  byte unalignment_offset;

    case (burst_size)
      e_1BYTE    : unalignment_offset = 0;
      e_2BYTES   : unalignment_offset = byte'(addr[0]);
      e_4BYTES   : unalignment_offset = byte'(addr[1:0]);
      e_8BYTES   : unalignment_offset = byte'(addr[2:0]);
      e_16BYTES  : unalignment_offset = byte'(addr[3:0]);
      e_32BYTES  : unalignment_offset = byte'(addr[4:0]);
      e_64BYTES  : unalignment_offset = byte'(addr[5:0]);
      e_128BYTES : unalignment_offset = byte'(addr[6:0]);
  endcase

  return unalignment_offset;


endfunction : calculate_unalignment_offset


/** \brief calculate the wrap boundaries for a given burst
 *
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @param burst_length - how many bytes is the burst
 * @return Lower_Wrap_Boundary - Lower Wrap Boundary Address
 * @return Upper_Wrap_Boundary - Upper Wrap Boundary Address
 * \todo: simplify the logic needed for the math in this function
*/
function void calculate_wrap_boundary(
  input bit [AXI_ADDR_WIDTH-1:0] addr,
  input bit [2:0]                  burst_size,
  input shortint                   burst_length,
  output bit [AXI_ADDR_WIDTH-1:0] Lower_Wrap_Boundary,
  output bit [AXI_ADDR_WIDTH-1:0] Upper_Wrap_Boundary);


  int max_beat_cnt;
  int dtsize;
  bit [AXI_ADDR_WIDTH-1:0] Aligned_Address;

  max_beat_cnt = calculate_axlen(.addr         (addr),
                                 .burst_size   (burst_size),
                                 .burst_length (burst_length)) + 1;

  Aligned_Address=calculate_burst_aligned_address(.address(addr),
                                            .burst_size(burst_size));


  dtsize = (2**burst_size) * max_beat_cnt;

  Lower_Wrap_Boundary = (int'(Aligned_Address/dtsize) * dtsize);
  Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;

endfunction : calculate_wrap_boundary


/*! \brief Get next address for reading/writing to memory
 *
 * Takes into account burst_type. IE: e_FIXED, e_INCR, e_WRAP
 * This function is stateful.  When called it updates an internal variable that holds the current address.
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @param burst_length - how many bytes is the burst
 * @param burst_type - Fixed, Incrementing or Wrap
 * @param beat_cnt - beat count the memory address corresponds to. Used with lane.
 * @param lane - lane thememory address correspons to. Usedwith beat_cnt
 * @param data_bus_bytes - how wide is the bus?
 * @return memory address that corresponds to the addr + beat_cnt/lane byte
 */
function bit[AXI_ADDR_WIDTH-1:0] get_next_address(
  input bit [AXI_ADDR_WIDTH-1:0] addr,
  input bit [2:0]                  burst_size,
  input shortint                   burst_length,
  input bit [1:0]                  burst_type,
  input int beat_cnt,
  input int lane,
  input int data_bus_bytes);

  bit [AXI_ADDR_WIDTH-1:0] tmp_addr;

  int Lower_Byte_Lane;
  int Upper_Byte_Lane;
  int data_offset;
  int Lower_Wrap_Boundary;
  int Upper_Wrap_Boundary;
  string s;
  string msg_s;


  calculate_wrap_boundary(.addr                (addr),
                          .burst_size          (burst_size),
                          .burst_length        (burst_length),
                          .Lower_Wrap_Boundary (Lower_Wrap_Boundary),
                          .Upper_Wrap_Boundary (Upper_Wrap_Boundary));

  get_beat_N_byte_lanes(.addr         (addr),
                        .burst_size   (burst_size),
                        .burst_length (burst_length),
                        .burst_type   (burst_type),
                        .beat_cnt     (beat_cnt),
                        .data_bus_bytes(data_bus_bytes),
                        .Lower_Byte_Lane(Lower_Byte_Lane),
                        .Upper_Byte_Lane(Upper_Byte_Lane),
                        .offset(data_offset));

  if (burst_type == e_FIXED) begin
    tmp_addr=addr+(lane - Lower_Byte_Lane);
  end else if (burst_type == e_INCR) begin
    tmp_addr=addr+data_offset+(lane - Lower_Byte_Lane);

  end else if (burst_type == e_WRAP) begin

        tmp_addr=addr+data_offset+(lane - Lower_Byte_Lane);

    if (tmp_addr >= Upper_Wrap_Boundary) begin
      tmp_addr = Lower_Wrap_Boundary+(tmp_addr-Upper_Wrap_Boundary);
    end
// \todo:do we have to worry about double-wrap?
  end else begin
    //`uvm_error("AXI_PKG::get_next_address", $sformatf("Unknown burst_type: %0d", burst_type))
  end

  msg_s="";

  $sformat(msg_s, "%s beat_cnt:%0d",              msg_s, beat_cnt);
 // $sformat(msg_s, "%s max_beat_cnt:%0d",          msg_s, max_beat_cnt);
  $sformat(msg_s, "%s lane:%0d",                  msg_s, lane);
  $sformat(msg_s, "%s Lower_Byte_Lane:%0d",       msg_s, Lower_Byte_Lane);
  $sformat(msg_s, "%s Upper_Byte_Lane:%0d",       msg_s, Upper_Byte_Lane);
  $sformat(msg_s, "%s Lower_Wrap_Boundary:%0d(0x%0x)", msg_s, Lower_Wrap_Boundary, Lower_Wrap_Boundary);
  $sformat(msg_s, "%s Upper_Wrap_Boundary:%0d(0x%0x)", msg_s, Upper_Wrap_Boundary, Upper_Wrap_Boundary);
  $sformat(msg_s, "%s number_bytes:%0d",          msg_s, (2**burst_size));
  $sformat(msg_s, "%s data_offset:%0d",           msg_s, data_offset);
  $sformat(msg_s, "%s tmp_addr:%0d(0x%0x)",       msg_s, tmp_addr, tmp_addr);

  //`uvm_info("axi_seq_item::get_next_address", msg_s, UVM_HIGH)

  return tmp_addr;

endfunction : get_next_address;


 /*! \brief return byte lanes that contain valid data
 *
 * given the beat number and how wide the bus is, return
 * which lanes to get data from and also what offset from start address
 * to write to.
 *
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @param burst_length - how many bytes is the burst
 * @param burst_type - Fixed, Incrementing or Wrap
 * @param beat_cnt which beat in the burst, starting at 0.
 * @param data_bus_bytes - how wide is the bus (the driver/responder can get this from the interface
 * @param Lower_Byte_Lane - Lower valid byte lane
 * @param Upper_Byte_Lane - Upper valid byte lane
 * @param offset - offset from Start_Address.  Can be used to write to memory.
 */
function void get_beat_N_byte_lanes(
  input bit       [AXI_ADDR_WIDTH-1:0] addr,
  input bit [2:0] burst_size,
  input shortint  burst_length,
  input bit [1:0]                  burst_type,
  input  int beat_cnt,
  input  int data_bus_bytes,
  output int Lower_Byte_Lane,
  output int Upper_Byte_Lane,
  output int offset);


   bit [63:0] Aligned_Start_Address;
  bit [63:0] Address_N;
  bit [63:0] Bus_Aligned_Address;
  bit [63:0] Bus_Aligned_Address_N;

  string s;
  string msg_s;

  int a;
  int b;

  Aligned_Start_Address=calculate_burst_aligned_address(.address(addr),
                                                  .burst_size(burst_size));
  Address_N = Aligned_Start_Address+(beat_cnt*(2**burst_size));


  // **********************
 // a = int'(addr/data_bus_bytes) * data_bus_bytes;
  Bus_Aligned_Address = calculate_bus_aligned_address(.addr(addr),
                                                  .bus_size(data_bus_bytes));
  Bus_Aligned_Address_N = calculate_bus_aligned_address(.addr(Address_N),
                                                  .bus_size(data_bus_bytes));


    // Adjust Lower_Byte_lane up if unaligned.
      if (burst_type == e_FIXED) begin
      //  if (beat_cnt==0) begin
           Lower_Byte_Lane = addr - Bus_Aligned_Address;
           Upper_Byte_Lane = Aligned_Start_Address + (2**burst_size) - 1 -
                             Bus_Aligned_Address;

           offset = beat_cnt*(2**burst_size);


      end  else begin

        if (beat_cnt==0) begin
           Lower_Byte_Lane = addr - Bus_Aligned_Address;
           Upper_Byte_Lane = Aligned_Start_Address + (2**burst_size) - 1 -
                             Bus_Aligned_Address;

           offset = 0;

        end else begin
           Lower_Byte_Lane = Address_N - Bus_Aligned_Address_N;
           Upper_Byte_Lane = Lower_Byte_Lane + (2**burst_size) - 1;

           offset = Address_N - addr;
        end
      end

      msg_s="";
      $sformat(msg_s, "%s beat_cnt:%0d",        msg_s, beat_cnt);
      $sformat(msg_s, "%s data_bus_bytes:%0d",  msg_s, data_bus_bytes);
      $sformat(msg_s, "%s NumberBytes (2**burst_size):%0d",  msg_s, (2**burst_size));

      $sformat(msg_s, "%s addr:%0d",            msg_s, addr);
      $sformat(msg_s, "%s Aligned_Start_Address:%0d",  msg_s, Aligned_Start_Address);
      $sformat(msg_s, "%s Address_N:%0d",  msg_s, Address_N);
      $sformat(msg_s, "%s Lower_Byte_Lane:%0d", msg_s, Lower_Byte_Lane);
      $sformat(msg_s, "%s Upper_Byte_Lane:%0d", msg_s, Upper_Byte_Lane);
      $sformat(msg_s, "%s offset:%0d",          msg_s, offset);

  //`uvm_info("axi_seq_item::get_beat_N_byte_lanes", msg_s, UVM_HIGH)


endfunction : get_beat_N_byte_lanes


  /****************
   *  BASE CLASS  *
   ****************/

  class axi_dw_monitor #(
      parameter AXI_ID_WIDTH,
      parameter AXI_ADDR_WIDTH,
      parameter AXI_DATA_WIDTH,
      parameter AXI_LEN_WIDTH,
      parameter int unsigned AxiUserWidth       ,
      parameter bit verbose,
      parameter time TimeTest
    );
    localparam AxiAddrWidth = AXI_ADDR_WIDTH;
    localparam AxiSlvPortDataWidth = AXI_DATA_WIDTH;
    localparam AxiMstPortDataWidth = AXI_DATA_WIDTH;
    localparam AxiIdWidth = AXI_ID_WIDTH;
    localparam AxiSlvPortStrbWidth = AxiSlvPortDataWidth / 8;
    localparam AxiMstPortStrbWidth = AxiMstPortDataWidth / 8;

    localparam AxiSlvPortMaxSize = $clog2(AxiSlvPortStrbWidth);
    localparam AxiMstPortMaxSize = $clog2(AxiMstPortStrbWidth);

    typedef logic [AxiIdWidth-1:0] axi_id_t    ;
    typedef logic [AxiAddrWidth-1:0] axi_addr_t;

    typedef logic [AxiMstPortDataWidth-1:0] port_data_t;
    typedef logic [AxiMstPortStrbWidth-1:0] port_strb_t;

    /// Has to be `TbAxiIdWidthMasters >= TbAxiIdUsed`.
    parameter int unsigned TbAxiIdUsed         = 32'd3;
    parameter int unsigned TbPipeline          = 32'd1; 
    /// Restrict to only unique IDs         
    parameter bit TbUniqueIds                  = 1'b0;
    typedef xbar_rule_32_t         rule_t; // Has to be the same width as axi addr 
    // Each slave has its own address range:
    parameter int unsigned TbAxiUserWidth        = 8;
    localparam time TestTime =  8ns;

  string msg_s;
  typedef logic [AxiAddrWidth:0] addr_t;     
  typedef logic [AxiIdWidth-1:0] id_t    ;
  /// The data transferred on a beat on the AW/AR channels.
  class ax_transfer;
    rand id_t           id  = '0;
    rand addr_t           addr  = '0;
    rand len_t   len   = '0;
    rand size_t  size  = '0;
    rand burst_t burst = '0;
    rand prot_t  prot  = '0;
  endclass : ax_transfer
    /// The data transferred on a beat on the R/W channel.
  class ax_data_packet #(
    parameter DW = AXI_DATA_WIDTH,
    parameter IW = AXI_ID_WIDTH ,
    parameter UW = 1
  );
    rand logic [IW-1:0] id   = '0;
    rand logic [DW-1:0] data = '0;
    resp_t     resp = '0;
    logic               last = '0;
    rand logic [UW-1:0] user = '0;
  endclass : ax_data_packet

 
    typedef struct packed {
      axi_id_t axi_id;
      logic axi_last ;
    } exp_b_t;
    typedef struct packed {
      axi_id_t axi_id         ;
      port_data_t axi_data;
      port_strb_t axi_strb;
      logic axi_last          ;
    } exp_rw_t;
    typedef struct packed {
      axi_id_t axi_id    ;
      axi_addr_t axi_addr;
      len_t  axi_len      ;
      burst_t axi_burst  ;
      size_t axi_size    ;
      cache_t axi_cache  ;
    } exp_ax_t;

    // typedef rand_id_queue_pkg::rand_id_queue #(
    //   .data_t  (exp_ax_t  ),
    //   .ID_WIDTH(AxiIdWidth)
    // ) ax_queue_t;
    // typedef rand_id_queue_pkg::rand_id_queue #(
    //   .data_t  (exp_b_t   ),
    //   .ID_WIDTH(AxiIdWidth)
    // ) b_queue_t;
    // typedef rand_id_queue_pkg::rand_id_queue #(
    //   .data_t  (exp_rw_t ),
    //   .ID_WIDTH(AxiIdWidth   )
    // ) r_queue_t;

    /**********************
     *  Helper functions  *
     **********************/

    // Returns a byte mask corresponding to the size of the AXI transaction
    function automatic axi_addr_t size_mask(size_t size);
      return (axi_addr_t'(1) << size) - 1;
    endfunction

    /**
     * Returns the conversion rate between tgt_size and src_size.
     * @return ceil(num_bytes(tgt_size)/num_bytes(src_size))
     */
    function automatic int unsigned conv_ratio(size_t tgt_size, size_t src_size)         ;
      return (num_bytes(tgt_size) + num_bytes(src_size) - 1)/num_bytes(src_size);
    endfunction: conv_ratio

    /************************
     *  Virtual Interfaces  *
     ************************/

    //virtual AXI_BUS_DV #(
    virtual axi_if_bfm #(
      .AXI_ID_WIDTH      (AXI_ID_WIDTH),
      .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
      .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),                                                                        
      .AXI_LEN_WIDTH  (AXI_LEN_WIDTH)
    ) port_axi;


    /*****************
     *  Bookkeeping  *
     *****************/

    longint unsigned tests_expected;
    longint unsigned tests_conducted;
    longint unsigned tests_failed;
    semaphore        cnt_sem;

    // Queues and FIFOs to hold the expected AXIDs

    // Write transactions
    // ax_queue_t   exp_port_aw_queue;
    exp_ax_t     act_port_aw_queue [$];
    exp_rw_t     exp_port_w_queue [$];
    exp_rw_t     act_port_w_queue [$];
    // b_queue_t    exp_port_b_queue;

    // Read transactions
    // ax_queue_t    exp_port_ar_queue;
    // ax_queue_t    act_port_ar_queue;
    exp_rw_t      act_port_r_queue [$];
    // r_queue_t     exp_port_r_queue;
    axi_seq_item_w_vector_s act_w_packet_queue [$];
    axi_seq_item_r_vector_s act_r_packet_queue [$];
    axi_seq_item_ar_vector_s act_ar_packet_queue [$];
    axi_seq_item_aw_vector_s act_aw_packet_queue [$];


    /*****************
     *  Constructor  *
     *****************/

    function new (
        virtual axi_if_bfm #(
               .AXI_ID_WIDTH      (AXI_ID_WIDTH),
               .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
               .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
               .AXI_LEN_WIDTH  (AXI_LEN_WIDTH)
        ) port_vif
      );
      begin
        this.port_axi          = port_vif;
        this.tests_expected        = 0           ;
        this.tests_conducted       = 0           ;
        this.tests_failed          = 0           ;
        // this.exp_port_b_queue  = new         ;
        // this.exp_port_r_queue  = new         ;
        // this.exp_port_aw_queue = new         ;
        // this.exp_port_ar_queue = new         ;
        // this.act_port_ar_queue = new         ;
        // this.act_port_ar_queue = new         ;
        this.cnt_sem               = new(1)      ;
      end
    endfunction

    task cycle_start;
      #TimeTest;
    endtask: cycle_start

    port_data_t r_data_d1;
    task cycle_end;
      @(posedge port_axi.clk);
      r_data_d1 <= port_axi.r_data;
    endtask: cycle_end

    /**************
     *  Monitors  *
     **************/
    ax_transfer ax_beat;
    ax_data_packet  ax_data;

  function automatic void print_ax (string msg_s, ax_transfer ax);
    $display("%t -- %m:: INFO :: AX transfer with:", $time);
    if (ax.prot[0]) $sformat(msg_s, "%s; AxPROT[0] = %0b: Privileged", msg_s, ax.prot[0]);
    else $sformat(msg_s, "%s; AxPROT[0] = %0b: Unprivileged", msg_s, ax.prot[0]);
    if (ax.prot[1]) $sformat(msg_s, "%s; AxPROT[1] = %0b: Non-secure access", msg_s, ax.prot[1]);
    else $sformat(msg_s, "%s; AxPROT[1] = %0b: Secure access", msg_s, ax.prot[1]);
    if (ax.prot[2]) $sformat(msg_s, "%s; AxPROT[2] = %0b: Instruction access", msg_s, ax.prot[2]);
    else $sformat(msg_s, "%s; AxPROT[2] = %0b: Data access", msg_s, ax.prot[2]);
    $sformat(msg_s, "%s; ID: %0h", msg_s, ax.id);
    case (ax.burst)
      BURST_FIXED: $sformat(msg_s, "%s; BURST: BURST_FIXED", msg_s);
      BURST_INCR:  $sformat(msg_s, "%s; BURST: BURST_INCR", msg_s);
      BURST_WRAP:  $sformat(msg_s, "%s; BURST: BURST_WRAP", msg_s);
      default : $error("TYPE: NOT_DEFINED");
    endcase
    $sformat(msg_s, "%s; ADDR: %0h", msg_s, ax.addr);
    $sformat(msg_s, "%s; SIZE: %0h", msg_s, ax.size);
    $sformat(msg_s, "%s; LEN:  %0h", msg_s, ax.len);
    $display("%t -- [AX_BUS]:: %s", $time, msg_s);
  endfunction : print_ax

  function automatic void print_d (string msg_s, ax_data_packet ax_data);
    $display("%t -- %m:: INFO :: RW Data Packet with:", $time);
    $sformat(msg_s, "%s, DATA: %0h", msg_s, ax_data.data);
    $display("%t -- [AX_BUS]:: %s", $time, msg_s);
  endfunction : print_d

function void read_ar(output axi_seq_item_ar_vector_s s);                                                                            

     s.arvalid = port_axi.arvalid;
     s.arid    = port_axi.arid;
     s.araddr  = port_axi.araddr;
     s.arlen   = port_axi.arlen;
     s.arsize  = port_axi.arsize;
     s.arburst = port_axi.arburst;
     s.arlock  = port_axi.arlock;
     s.arcache = port_axi.arcache;
     s.arprot  = port_axi.arprot;
     s.arqos   = port_axi.arqos;

endfunction : read_ar
function void read_r(output axi_seq_item_r_vector_s  s);                                                                             

    s.rvalid = port_axi.rvalid_d1;
    s.rdata  = port_axi.rdata_d1;
    s.rlast  = port_axi.rlast_d1;
    s.rid    = port_axi.rid_d1;
    s.rresp  = port_axi.rresp_d1;

endfunction : read_r
function void read_aw(output axi_seq_item_aw_vector_s s);                                                                            

     s.awvalid = port_axi.awvalid;
     s.awid    = port_axi.awid;
     s.awaddr  = port_axi.awaddr;
     s.awlen   = port_axi.awlen;
    s.awsize   = port_axi.awsize;
    s.awburst  = port_axi.awburst;
     s.awlock  = port_axi.awlock;
     s.awcache = port_axi.awcache;
     s.awprot  = port_axi.awprot;
     s.awqos   = port_axi.awqos;

endfunction : read_aw
function void read_w(output axi_seq_item_w_vector_s  s);

    s.wvalid = port_axi.wvalid;
    s.wdata  = port_axi.wdata;
    s.wstrb  = port_axi.wstrb;
    s.wlast  = port_axi.wlast;

endfunction : read_w                                                                                                                 

    /*
     * You need to override this task. Use it to push the expected AW requests on
     * the slave side, and the B and R responses expected on the master side.
     */
    virtual task automatic mon_port_aw ()    ;
        axi_seq_item_aw_vector_s s;
            if (port_axi.aw_valid && port_axi.aw_ready) begin
                read_aw(.s(s));
                act_aw_packet_queue.push_back(s);
                if (verbose) begin
                    $display("%t -- %m:: INFO :: got axi_aw valid and ready", $time);
                    ax_beat = new;
                    msg_s = "mon_port_aw";
                    ax_beat.id   =  s.awid;
                    ax_beat.addr =  s.awaddr;
                    ax_beat.len =   s.awlen;
                    ax_beat.size =  s.awsize;
                    ax_beat.burst = s.awburst;
                    ax_beat.prot  = s.awprot;
                    print_ax(msg_s, ax_beat);
                end
            end
    endtask : mon_port_aw


    /*
     * You need to override this task. Use it to push the expected W requests on
     * the slave side.
     */
    virtual task automatic mon_port_w ()     ;
        axi_seq_item_w_vector_s s;
            if (port_axi.w_valid && port_axi.w_ready) begin
                read_w(.s(s));
                act_w_packet_queue.push_back(s);
                if (verbose) begin
                    $display("%t -- %m:: INFO :: got axi_w valid and ready", $time);
                    ax_data = new;
                    msg_s = "mon_port_w";
                    ax_data.data = s.wdata;
                    print_d(msg_s, ax_data);
                    mon_port_aw_fetch_w();
                end
            end
    endtask : mon_port_w

    virtual task automatic mon_port_aw_fetch_w ()     ;
      axi_seq_item_aw_vector_s aw_packet;
      axi_seq_item_w_vector_s w_packet;
      axi_addr_t wr_addr; 
      len_t wr_len;
      port_data_t wr_data;
      int index;
          if (port_axi.wlast) begin
              // get the write_address from act_aw_packet_queue
              aw_packet = act_aw_packet_queue.pop_front();
              wr_addr = aw_packet.awaddr;
              wr_len = aw_packet.awlen;
              $display("%t -- %m :: INFO :: write_packet: get write_addr = %h", $time, wr_addr);
              if (act_w_packet_queue.size >= (wr_len+1)) begin
                  for (index = 0; index < (wr_len+1); index++) begin
                      w_packet = act_w_packet_queue.pop_front();
                      wr_data = w_packet.wdata;
                      $display("%t -- %m :: INFO :: index = %d, read_data = %h", $time, index, wr_data);
                  end
              end
          end
    endtask : mon_port_aw_fetch_w
    /*
     * This task does the R channel monitoring on a slave port. It compares the last flags,
     * which are determined by the sequence of previously sent AR vectors.
     */
    virtual task automatic mon_port_r ()     ;
        axi_seq_item_r_vector_s s;
            if (port_axi.rvalid_d1 && port_axi.rready_d1) begin
                read_r(.s(s));
                act_r_packet_queue.push_back(s);
                if (verbose) begin
                    $display("%t -- %m:: INFO :: got axi_r valid and ready", $time);
                    ax_data = new;
                    msg_s = "mon_port_r";
                    ax_data.data = port_axi.rdata_d1;
                    print_d(msg_s, ax_data);
                    mon_port_ar_fetch_r();
                end
            end
    endtask : mon_port_r

    virtual task automatic mon_port_ar_fetch_r ()     ;
      exp_rw_t exp_r;
      axi_seq_item_ar_vector_s ar_packet;
      axi_seq_item_r_vector_s r_packet;
      axi_addr_t rd_addr; 
      len_t rd_len;
      port_data_t rd_data;
      int index;
          if (port_axi.rlast_d1) begin
              // get the read_address from act_port_aw_queue
              ar_packet = act_ar_packet_queue.pop_front();
              rd_addr = ar_packet.araddr;
              rd_len = ar_packet.arlen;
              $display("%t -- %m :: INFO :: read_packet: get read_addr = %h", $time, rd_addr);
              if (act_r_packet_queue.size >= (rd_len+1)) begin
                  for (index = 0; index < (rd_len+1); index++) begin
                      r_packet = act_r_packet_queue.pop_front();
                      rd_data = r_packet.rdata;
                      $display("%t -- %m :: INFO :: index = %d, read_data = %h", $time, index, rd_data);
                  end
              end
          end
    endtask : mon_port_ar_fetch_r


    /*
     * You need to override this task. Use it to push the expected AR requests on
     * the slave side, and the R responses expected on the master side.
     */
    virtual task automatic mon_port_ar ()    ;
        axi_seq_item_ar_vector_s s;
            if (port_axi.ar_valid && port_axi.ar_ready) begin
                read_ar(.s(s));
                act_ar_packet_queue.push_back(s);
                if (verbose) begin
                    $display("%t -- %m:: INFO :: got axi_ar valid and ready", $time);
                    ax_beat = new;
                    msg_s = "mon_port_ar";
                    ax_beat.id   =  s.arid;
                    ax_beat.addr =  s.araddr;
                    ax_beat.len =   s.arlen;
                    ax_beat.size =  s.arsize;
                    ax_beat.burst = s.arburst;
                    ax_beat.prot  = s.arprot;
                    print_ax(msg_s, ax_beat);
                end
            end
    endtask : mon_port_ar

    /*
     * This tasks stores the beats seen by the AR, AW and W channels
     * into the respective queues.
     */
    // virtual task automatic store_channels ();
    // if (port_axi.ar_valid && port_axi.ar_ready) begin
    //     act_port_ar_queue.push(port_axi.ar_id,
    //       '{
    //         axi_id   : port_axi.ar_id   ,
    //         axi_burst: port_axi.ar_burst,
    //         axi_size : port_axi.ar_size ,
    //         axi_addr : port_axi.ar_addr ,
    //         axi_len  : port_axi.ar_len  ,
    //         axi_cache: port_axi.ar_cache
    //       });
    //   end
    //   if (port_axi.aw_valid && port_axi.aw_ready) begin
    //     act_port_aw_queue.push_back('{
    //         axi_id   : port_axi.aw_id   ,
    //         axi_burst: port_axi.aw_burst,
    //         axi_size : port_axi.aw_size ,
    //         axi_addr : port_axi.aw_addr ,
    //         axi_len  : port_axi.aw_len  ,
    //         axi_cache: port_axi.aw_cache
    //       });

    //     // This request generates an R response.
    //     // Push this to the AR queue.
    //     if (port_axi.aw_atop[ATOP_R_RESP])
    //       act_port_ar_queue.push(port_axi.aw_id,
    //         '{
    //           axi_id   : port_axi.aw_id   ,
    //           axi_burst: port_axi.aw_burst,
    //           axi_size : port_axi.aw_size ,
    //           axi_addr : port_axi.aw_addr ,
    //           axi_len  : port_axi.aw_len  ,
    //           axi_cache: port_axi.aw_cache
    //         });
    //   end

    //   if (port_axi.w_valid && port_axi.w_ready)
    //     this.act_port_w_queue.push_back('{
    //         axi_id  : {AxiIdWidth{1'b?}} ,
    //         axi_data: port_axi.w_data,
    //         axi_strb: port_axi.w_strb,
    //         axi_last: port_axi.w_last
    //       });

    //       if (port_axi.rvalid_d1 && port_axi.rready_d1) begin
    //     this.act_port_r_queue.push_back('{
    //         axi_id  : port_axi.rid_d1          ,
    //         axi_data: port_axi.rdata_d1        ,
    //         axi_strb: {AxiSlvPortStrbWidth{1'b?}},
    //         axi_last: port_axi.rlast_d1
    //       });
    //   end


    //   if (port_axi.ar_valid && port_axi.ar_ready)
    //     act_port_ar_queue.push(port_axi.ar_id,
    //       '{
    //         axi_id   : port_axi.ar_id   ,
    //         axi_burst: port_axi.ar_burst,
    //         axi_size : port_axi.ar_size ,
    //         axi_addr : port_axi.ar_addr ,
    //         axi_len  : port_axi.ar_len  ,
    //         axi_cache: port_axi.ar_cache
    //       });

    //   if (port_axi.aw_valid && port_axi.aw_ready) begin
    //     act_port_aw_queue.push_back('{
    //         axi_id   : port_axi.aw_id   ,
    //         axi_burst: port_axi.aw_burst,
    //         axi_size : port_axi.aw_size ,
    //         axi_addr : port_axi.aw_addr ,
    //         axi_len  : port_axi.aw_len  ,
    //         axi_cache: port_axi.aw_cache
    //       });

    //     // This request generates an R response.
    //     // Push this to the AR queue.
    //     if (port_axi.aw_atop[ATOP_R_RESP])
    //       act_port_ar_queue.push(port_axi.aw_id,
    //         '{
    //           axi_id   : port_axi.aw_id   ,
    //           axi_burst: port_axi.aw_burst,
    //           axi_size : port_axi.aw_size ,
    //           axi_addr : port_axi.aw_addr ,
    //           axi_len  : port_axi.aw_len  ,
    //           axi_cache: port_axi.aw_cache
    //         });
    //   end

    //   if (port_axi.w_valid && port_axi.w_ready)
    //     this.act_port_w_queue.push_back('{
    //         axi_id  : {AxiIdWidth{1'b?}} ,
    //         axi_data: port_axi.w_data,
    //         axi_strb: port_axi.w_strb,
    //         axi_last: port_axi.w_last
    //       });
    // endtask

    /*
     * This task monitors the master port of the DW converter. Every time it gets an AW transaction,
     * it gets checked for its contents against the expected beat on the `exp_aw_queue`.
     */
    // task automatic mon_port_aw_check ();
    //   exp_ax_t exp_aw;
    //   if (port_axi.aw_valid && port_axi.aw_ready) begin
    //     // Test if the AW beat was expected
    //     exp_aw = this.exp_port_aw_queue.pop_id(port_axi.aw_id);
    //     if (exp_aw.axi_id != port_axi.aw_id) begin
    //       incr_failed_tests(1)                                            ;
    //       $warning("Slave: Unexpected AW with ID: %b", port_axi.aw_id);
    //     end
    //     if (exp_aw.axi_addr != port_axi.aw_addr) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AW with ID: %b and ADDR: %h, exp: %h",
    //         port_axi.aw_id, port_axi.aw_addr, exp_aw.axi_addr);
    //     end
    //     if (exp_aw.axi_len != port_axi.aw_len) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AW with ID: %b and LEN: %h, exp: %h",
    //         port_axi.aw_id, port_axi.aw_len, exp_aw.axi_len);
    //     end
    //     if (exp_aw.axi_burst != port_axi.aw_burst) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AW with ID: %b and BURST: %h, exp: %h",
    //         port_axi.aw_id, port_axi.aw_burst, exp_aw.axi_burst);
    //     end
    //     if (exp_aw.axi_size != port_axi.aw_size) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AW with ID: %b and SIZE: %h, exp: %h",
    //         port_axi.aw_id, port_axi.aw_size, exp_aw.axi_size);
    //     end
    //     if (exp_aw.axi_cache != port_axi.aw_cache) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AW with ID: %b and CACHE: %b, exp: %b",
    //         port_axi.aw_id, port_axi.aw_cache, exp_aw.axi_cache);
    //     end
    //     incr_conducted_tests(6);
    //   end
    // endtask : mon_port_aw_check

    /*
     * This task compares the expected and actual W beats on the master port.
     */
    task automatic mon_port_w_check ();
      exp_rw_t exp_w, act_w;
      while (this.exp_port_w_queue.size() != 0 && this.act_port_w_queue.size() != 0) begin
        exp_w = this.exp_port_w_queue.pop_front();
        act_w = this.act_port_w_queue.pop_front();
        // Do the checks
        if (exp_w.axi_data != act_w.axi_data) begin
          incr_failed_tests(1);
          $warning("Slave: Unexpected W with DATA: %h, exp: %h",
            act_w.axi_data, exp_w.axi_data);
        end
        if (exp_w.axi_strb != act_w.axi_strb) begin
          incr_failed_tests(1);
          $warning("Slave: Unexpected W with STRB: %h, exp: %h",
            act_w.axi_strb, exp_w.axi_strb);
        end
        if (exp_w.axi_last != act_w.axi_last) begin
          incr_failed_tests(1);
          $warning("Slave: Unexpected W with LAST: %b, exp: %b",
            act_w.axi_last, exp_w.axi_last);
        end
        incr_conducted_tests(3);
      end
    endtask : mon_port_w_check

    /*
     * This task checks if a B response is allowed on a slave port of the DW converter.
     */
    // task automatic mon_port_b ();
    //   exp_b_t  exp_b;
    //   axi_id_t axi_b_id;
    //   if (port_axi.b_valid && port_axi.b_ready) begin
    //     incr_conducted_tests(1);
    //     axi_b_id = port_axi.b_id;
    //     //$display("%0tns > Master: Got last B with ID: %b", $time, axi_b_id);
    //     if (this.exp_port_b_queue.empty()) begin
    //       incr_failed_tests(1)                                                 ;
    //       $warning("Master: unexpected B beat with ID: %b detected!", axi_b_id);
    //     end else begin
    //       exp_b = this.exp_port_b_queue.pop_id(axi_b_id);
    //       if (axi_b_id != exp_b.axi_id) begin
    //         incr_failed_tests(1)                                      ;
    //         $warning("Master: got unexpected B with ID: %b", axi_b_id);
    //       end
    //     end
    //   end
    // endtask : mon_port_b

    /*
     * This task monitors a the master port of the DW converter and checks
     * if the AR beats were all expected.
     */
    // task automatic mon_port_ar_check ();
    //   exp_ax_t exp_ar;
    //   if (port_axi.ar_valid && port_axi.ar_ready) begin
    //     // Test if the AR beat was expected
    //     exp_ar = this.exp_port_ar_queue.pop_id(port_axi.ar_id);
    //     if (exp_ar.axi_id != port_axi.ar_id) begin
    //       incr_failed_tests(1)                                            ;
    //       $warning("Slave: Unexpected AR with ID: %b", port_axi.ar_id);
    //     end
    //     if (exp_ar.axi_addr != port_axi.ar_addr) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AR with ID: %b and ADDR: %h, exp: %h",
    //         port_axi.ar_id, port_axi.ar_addr, exp_ar.axi_addr);
    //     end
    //     if (exp_ar.axi_len != port_axi.ar_len) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AR with ID: %b and LEN: %h, exp: %h",
    //         port_axi.ar_id, port_axi.ar_len, exp_ar.axi_len);
    //     end
    //     if (exp_ar.axi_burst != port_axi.ar_burst) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AR with ID: %b and BURST: %h, exp: %h",
    //         port_axi.ar_id, port_axi.ar_burst, exp_ar.axi_burst);
    //     end
    //     if (exp_ar.axi_size != port_axi.ar_size) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AR with ID: %b and SIZE: %h, exp: %h",
    //         port_axi.ar_id, port_axi.ar_size, exp_ar.axi_size);
    //     end
    //     if (exp_ar.axi_cache != port_axi.ar_cache) begin
    //       incr_failed_tests(1);
    //       $warning("Slave: Unexpected AR with ID: %b and CACHE: %b, exp: %b",
    //         port_axi.ar_id, port_axi.ar_cache, exp_ar.axi_cache);
    //     end
    //     incr_conducted_tests(6);
    //   end
    // endtask : mon_port_ar_check

    /*
     * This task does the R channel monitoring on a slave port. It compares the last flags,
     * which are determined by the sequence of previously sent AR vectors.
     */
    // task automatic mon_port_r_check ();
    //   exp_rw_t exp_r;
    //   if (act_port_r_queue.size() != 0) begin
    //     exp_rw_t act_r = act_port_r_queue[0] ;
    //     if (exp_port_r_queue.queues[act_r.axi_id].size() != 0) begin
    //       exp_r = exp_port_r_queue.pop_id(act_r.axi_id);
    //       void'(act_port_r_queue.pop_front());

    //       // Do the checks
    //       if (exp_r.axi_id != act_r.axi_id) begin
    //         incr_failed_tests(1);
    //         $warning("Slave: Unexpected R with ID: %b",
    //           act_r.axi_id);
    //       end
    //       if (exp_r.axi_last != act_r.axi_last) begin
    //         incr_failed_tests(1);
    //         $warning("Slave: Unexpected R with ID: %b and LAST: %b, exp: %b",
    //           act_r.axi_id, act_r.axi_last, exp_r.axi_last);
    //       end
    //       if (exp_r.axi_data != act_r.axi_data) begin
    //         incr_failed_tests(1);
    //         $warning("Slave: Unexpected R with ID: %b and DATA: %h, exp: %h",
    //           act_r.axi_id, act_r.axi_data, exp_r.axi_data);
    //       end
    //       incr_conducted_tests(3);
    //     end
    //   end
    // endtask : mon_port_r_check

    // Some tasks to manage bookkeeping of the tests conducted.
    task incr_expected_tests(input int unsigned times);
      cnt_sem.get()               ;
      this.tests_expected += times;
      cnt_sem.put()               ;
    endtask : incr_expected_tests

    task incr_conducted_tests(input int unsigned times);
      cnt_sem.get()                ;
      this.tests_conducted += times;
      cnt_sem.put()                ;
    endtask : incr_conducted_tests

    task incr_failed_tests(input int unsigned times);
      cnt_sem.get()             ;
      this.tests_failed += times;
      cnt_sem.put()             ;
    endtask : incr_failed_tests

    /*
     * This task invokes the various monitoring tasks. First, all processes that only
     * push something in the FIFOs are invoked. After they are finished, the processes
     * that pop something from them are invoked.
     */
    task run();
      forever begin
        // At every cycle, spawn some monitoring processes.
        cycle_start();

        // Execute all processes that push something into the queues
        PushMon: fork
          //proc_store_channel: store_channels() ;
          proc_aw       : mon_port_aw();
          proc_ar       : mon_port_ar();
          proc_w        : mon_port_w() ;
          proc_r        : mon_port_r() ;
        join: PushMon

        // These only pop something from the queues
        //PopMon: fork
        //  proc_aw: mon_port_aw();
        //  //proc_b : mon_port_b() ;
        //  proc_ar: mon_port_ar();
        //  proc_r : mon_port_r() ;
        //join : PopMon

        // Check the slave W FIFOs last
        // proc_check_w: mon_port_w_check();

        cycle_end();
      end
    endtask : run

    task print_result()                                    ;
      $info("Simulation has ended!")                       ;
      $display("Tests Expected:  %d", this.tests_expected) ;
      $display("Tests Conducted: %d", this.tests_conducted);
      $display("Tests Failed:    %d", this.tests_failed)   ;
      if (tests_failed > 0) begin
        $error("Simulation encountered unexpected transactions!");
      end
    endtask : print_result

  endclass : axi_dw_monitor

endpackage
