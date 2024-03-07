`include "globals.sv"

module gain #(
    parameter DATA_SIZE,
    parameter BITS
) (
    input   logic                           clock,
    input   logic                           reset,
    output  logic                           in_rd_en,
    input   logic                           in_empty,
    input   logic                           out_full,
    output  logic                           out_wr_en,
    output  logic signed [DATA_SIZE-1:0]    dout,
    input   logic signed [DATA_SIZE-1:0]    din,
    input   logic signed [DATA_SIZE-1:0]    volume
);

logic signed [DATA_SIZE-1:0] temp_in_c, temp_in;
logic signed [DATA_SIZE-1:0] vol, vol_c;

typedef enum logic [0:0] {READ, CALC_OUT} state_types;
state_types state, next_state;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= READ;
        vol <= '0;
        temp_in <= '0;
    end else begin
        state <= next_state;
        vol <= vol_c;
        temp_in <= temp_in_c;
    end
end

always_comb begin
    temp_in_c = temp_in;
    vol_c = vol;

    case (state)
        READ: begin
            out_wr_en = 1'b0;
            if (in_empty == 1'b0) begin
                in_rd_en = 1'b1;
                vol_c = volume;
                temp_in_c = din;
                next_state = CALC_OUT;
            end else begin
                next_state = READ;
            end
        end

        CALC_OUT: begin
            if (out_full == 1'b0) begin
                dout = DEQUANTIZE(temp_in * vol) << (14-BITS);
                in_rd_en = 1'b0;
                out_wr_en = 1'b1;
                next_state = READ;
            end else begin
                next_state = CALC_OUT;
            end
        end

        default: begin
            in_rd_en = 1'b0;
            out_wr_en = 1'b0;
            next_state = READ;
        end
    endcase
end

endmodule