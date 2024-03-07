`include "globals.sv"

module multiply #(
    parameter DATA_SIZE
)(
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

typedef enum logic [0:0] {READ, WRITE} state_types;
state_types state, next_state;

logic signed [DATA_SIZE-1:0] in1, in1_c;
logic signed [DATA_SIZE-1:0] in2, in2_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= READ;
        in1 <= '0;
        in2 <= '0;
    end else begin
        state <= next_state;
        in1 <= in1_c;
        in2 <= in2_c;
    end
end

always_comb begin
    in1_c = in1;
    in2_c = in2;
    next_state = state;

    case (state) 
        READ: begin
            out_wr_en = 1'b0;
            if (x_in_empty == 1'b0 && y_in_empty == 1'b0) begin
                next_state = WRITE;
                x_in_rd_en = 1'b1;
                y_in_rd_en = 1'b1;
                in1_c = x;
                in2_c = y;
            end else begin
                x_in_rd_en = 1'b0;
                y_in_rd_en = 1'b0;
                next_state = READ;
            end
        end

        WRITE: begin
            x_in_rd_en = 1'b0;
            y_in_rd_en = 1'b0;
            if (out_full == 1'b0) begin
                dout = DEQUANTIZE(in1 * in2);
                out_wr_en = 1'b1;
                next_state = READ;
            end else begin
                next_state = WRITE;
                out_wr_en = 1'b0;
            end
        end

        default: begin
            dout = '0;
            x_in_rd_en = 1'b0;
            y_in_rd_en = 1'b0;
            out_wr_en = 1'b0;
            in1_c = '0;
            in2_c = '0;
        end
    endcase

end


endmodule