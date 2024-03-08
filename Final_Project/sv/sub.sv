`include "globals.sv" 

module sub (
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

logic [DATA_SIZE-1:0] diff, diff_c; 

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0;
        diff <= '0;
    end else begin
        state <= next_state;
        diff <= diff_c;
    end
end

always_comb begin
    x_in_rd_en = 1'b0;
    y_in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    next_state = state;
    diff_c = diff;
    out_din ='0;

    case(state)

    S0: begin
        if (x_in_empty == 1'b0 && y_in_empty == 1'b0) begin
            x_in_rd_en = 1'b1;
            y_in_rd_en = 1'b1;
            diff_c = $signed(x_in_dout) - $signed(y_in_dout);
            next_state = S1;
        end
    end

    S1: begin
        if (out_full == 1'b0) begin
            out_wr_en = 1'b1;
            out_din = diff;
            next_state = S0;
        end
    end

    default: begin
        next_state = S0;
        x_in_rd_en = 1'b0;
        y_in_rd_en = 1'b0;
        out_wr_en = 1'b0;
        diff_c = 'X;
        out_din = 'X;
    end
    
    endcase
end

endmodule