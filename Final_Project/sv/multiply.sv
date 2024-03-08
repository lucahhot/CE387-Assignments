`include "globals.sv"

module multiply (
    input   logic                           clock,
    input   logic                           reset,
    output  logic                           x_in_rd_en,
    output  logic                           y_in_rd_en,
    input   logic                           x_in_empty,
    input   logic                           y_in_empty,
    output  logic                           out_wr_en,
    input   logic                           out_full,
    input   logic signed [DATA_SIZE - 1:0]  x,
    input   logic signed [DATA_SIZE - 1:0]  y,
    output  logic signed [DATA_SIZE - 1:0]  dout
);

typedef enum logic [1:0] {READ,MULTIPLY,OUTPUT} state_types;
state_types state, next_state;

logic signed [DATA_SIZE-1:0] calc, calc_c;
logic signed [DATA_SIZE-1:0] a, a_c, b, b_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= READ;
        calc <= '0;
        a <= '0;
        b <= '0;
    end else begin
        state <= next_state;
        calc <= calc_c;
        a <= a_c;
        b <= b_c;
    end
end

always_comb begin
    calc_c = calc;
    next_state = state;
    x_in_rd_en = 1'b0;
    y_in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    a_c = '0;
    b_c = '0;

    case (state) 
        READ: begin
            if (x_in_empty == 1'b0 && y_in_empty == 1'b0) begin
                next_state = MULTIPLY;
                x_in_rd_en = 1'b1;
                y_in_rd_en = 1'b1;
                a_c = x;
                b_c = y;
            end else begin
                next_state = READ;
            end
        end

        MULTIPLY: begin
            calc_c = $signed(a) * $signed(b);
            next_state = OUTPUT;
        end

        OUTPUT: begin
            if (out_full == 1'b0) begin
                dout = DEQUANTIZE(calc);
                out_wr_en = 1'b1;
                next_state = READ;
            end else 
                next_state = OUTPUT;
        end

        default: begin
            dout = '0;
            x_in_rd_en = 1'b0;
            y_in_rd_en = 1'b0;
            out_wr_en = 1'b0;
            calc_c = '0;
            a_c = '0;
            b_c = '0;
        end
    endcase

end


endmodule