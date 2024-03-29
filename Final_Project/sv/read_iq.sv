`include "globals.sv"

module read_iq (
    input   logic                           clock,
    input   logic                           reset,
    input   logic                           in_empty,
    output  logic                           in_rd_en,
    input   logic                           i_out_full,
    input   logic                           q_out_full,
    output  logic                           out_wr_en,
    input   logic unsigned [BYTE_SIZE-1:0]       data_in,
    output  logic signed [DATA_SIZE-1:0]    i_out,
    output  logic signed [DATA_SIZE-1:0]    q_out
);

logic signed [CHAR_SIZE-1:0] i_temp, q_temp;
logic [CHAR_SIZE-1:0] i_temp_c, q_temp_c;
logic [BYTE_SIZE-1:0] i_buff, q_buff;
logic [1:0] count, count_c;

typedef enum logic [0:0] {READ, WRITE} state_types;
state_types state, next_state;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        i_temp <= '0;
        q_temp <= '0;
        state <= READ;
        count <= '0;
    end else begin
        i_temp <= i_temp_c;
        q_temp <= q_temp_c;
        state <= next_state;
        count <= count_c;
    end 
end

always_comb begin
    in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    i_temp_c = i_temp;
    q_temp_c = q_temp;
    count_c = count;

    case (state) 
        READ: begin
            if (in_empty == 1'b0) begin
                in_rd_en = 1'b1;
                if (count == 2'b00) begin
                    i_buff = data_in;
                    next_state = READ;
                    count_c++;
                end else if (count == 2'b01) begin
                    i_temp_c = {data_in, i_buff};
                    next_state = READ;
                    count_c++;
                end else if (count == 2'b10) begin
                    q_buff = data_in;
                    next_state = READ;
                    count_c++;
                end else begin
                    q_temp_c = {data_in, q_buff};
                    next_state = WRITE;
                    count_c++;
                end
            end else begin
                next_state = READ;
            end
        end

        WRITE: begin
            if (i_out_full == 1'b0 && q_out_full == 1'b0) begin
                out_wr_en = 1'b1;
                in_rd_en = 1'b0;
                i_out = QUANTIZE(i_temp);    // quantize
                q_out = QUANTIZE(q_temp);    // quantize
                next_state = READ;
            end else begin
                next_state = WRITE;
            end
        end

        default: begin
            i_temp_c = '0;
            q_temp_c = '0;
            in_rd_en = 1'b0;
            out_wr_en = 1'b0;
            next_state = READ;
        end
    endcase
end

endmodule