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

typedef enum logic {S0, S1} state_types;
state_types state, next_state;

logic [DATA_SIZE-1:0] sum, sum_c; 

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0;
        sum <= '0;
    end else begin
        state <= next_state;
        sum <= sum_c;
    end
end

always_comb begin
    x_in_rd_en = 1'b0;
    y_in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    next_state <= state;
    sum_c <= sum;

    case(state)

    S0: begin
        if (x_in_empty == 1'b0 && y_in_empty == 1'b0) begin
            x_in_rd_en = 1'b1;
            y_in_rd_en = 1'b1;
            sum_c = $signed(x_in_dout) + $signed(y_in_dout);
        end
    end

    S1: begin
        if (out_full == 1'b0) begin
            out_wr_en = 1'b1;
            out_din = sum;
        end
    end

    default: begin
        x_in_rd_en = 1'b0;
        y_in_rd_en = 1'b0;
        out_wr_en = 1'b0;
        sum_c = 'X;
        out_din = 'X;
    end
    
    endcase
end

endmodule