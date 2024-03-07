module comparator #(
    parameter DATA_SIZE_2
) (
    input logic [DATA_SIZE_2-1:0] dinr,      // dinr
    input logic [DATA_SIZE_2-1:0] dinl,       // dinl
    output logic [DATA_SIZE_2-1:0] d_out,
    output logic isGreaterEq
);

always_comb begin
    if (dinl >= dinr) begin
        d_out = dinl - dinr;
        isGreaterEq = 1'b1;
    end else begin
        d_out = dinl;
        isGreaterEq = 1'b0;
    end
end

endmodule