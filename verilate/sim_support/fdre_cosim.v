module fdre_cosim(
    output wire Q,
    input wire R,
    input wire C,
    input wire CE,
    input wire D
);

    reg inner_Q;
    // force the asic synthesis tool to infer an async, active-low reset FF
    always @(posedge C or posedge R) begin
        if(R) begin
            inner_Q <= 0;
        end else begin
            if(CE) begin
                inner_Q <= D;
            end else begin
                inner_Q <= Q;
            end
        end
    end
    assign Q = inner_Q;

endmodule