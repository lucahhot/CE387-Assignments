module comparator #(
    parameter DATA_SIZE_2
) (
    input logic [DATA_SIZE_2-1:0] divisor,      // dinr
    input logic [DATA_SIZE_2:0] dividend,       // dinl
    output logic [DATA_SIZE_2-1:0] d_out,
    output logic isGreaterEq
);

always_comb begin
    if (dividend >= divisor) begin
        d_out = dividend - divisor;
        isGreaterEq = 1'b1;
    end else begin
        d_out = dividend;
        isGreaterEq = 1'b0;
    end
end

endmodule