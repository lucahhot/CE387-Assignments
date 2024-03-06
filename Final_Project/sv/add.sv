`include "globals.sv" 

module add (
    input   logic clock,
    input   logic reset,
    input   logic [DATA_SIZE-1:0] x_in_dout,   
    input   logic x_in_empty,
    output  logic x_in_rd_en,
    input   logic [DATA_SIZE-1:0] y_in_dout,   
    input   logic y_in_empty,
    output  logic y_in_rd_en,
    output  logic out_wr_en,
    input   logic out_full,
    output  logic [DATA_SIZE-1:0] out_din  
);

always_comb begin
    x_in_rd_en = 1'b0;
    y_in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    // Reading values and writing them directly
    if (x_in_empty == 1'b0 && y_in_empty == 1'b0 && out_full == 1'b0) begin
        x_in_rd_en = 1'b1;
        y_in_rd_en = 1'b1;
        out_wr_en = 1'b1;
        out_din = $signed(x_in_dout) + $signed(y_in_dout);
    end
end

endmodule