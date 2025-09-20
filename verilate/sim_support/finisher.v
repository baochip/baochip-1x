`timescale 1ns / 1ps
// `define XOUS 1

// contains "cosim" models that encapsulate some key differences between ASIC/FPGA behaviors
// particularly around reset conditions.

module finisher(
    input wire [31:0] report,
    input wire done,
    input wire clk
);

reg [31:0] rep_state;
reg kprint_trigger = 0;
reg kprint_trigger_d = 0;
reg kprint_done = 0;

always @(report) begin
    if (report != rep_state) begin
        rep_state <= report;
        $display("Report update: %h", report);
    end
end

always @(*) begin
    if (kprint_done == 1'b1) begin
        $dumpflush;
        $dumpoff;
        $finish;
    end
end

// This block waits for `done` to rise; then, it triggers an 'r' into the kernel
// so that the RAM usage dump gets printed. Finally, the simulation termination
// signal `kprint_done` is triggered when the '.' character is seen in the kernel log.
always @(posedge clk) begin
    // make the trigger "sticky" and one-way
    if (done == 1'b1) begin
`ifndef XOUS
        $dumpflush;
        $dumpoff;
        $finish;
`endif
    end
end

// make sure we eventually stop
// initial #750_000_000 $finish;

endmodule
