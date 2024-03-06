//`include "macro.svh"
module demodulate (
    input   logic           clk,
    input   logic           reset,
    input   logic           input_fifos_empty,
    output  logic           input_rd_en,
    input   logic [31:0]    real_in,
    input   logic [31:0]    imag_in,
    output  logic [31:0]    demod_out,
    output  logic           wr_en_out,
    input   logic           out_fifo_full
);

import macros::*;

const logic [31:0] gain = 32'h000002f6;

typedef enum logic [2:0] {EDGE_1, EDGE_2, IDLE, WAITING, OUTPUT} state_t;
state_t state, state_c;

logic [31:0] real_curr, real_curr_c, imag_curr, imag_curr_c, real_prev, real_prev_c, imag_prev, imag_prev_c, qarctan_out, qarctan_out_times_gain;
logic [63:0] real_prev_times_curr, imag_prev_times_curr, neg_imag_prev_times_imag, neg_imag_prev_times_real;
logic [31:0] short_real, short_imag;
logic [31:0] demod_temp, demod_temp_c;
logic qarctan_ready, qarctan_done;
logic demod_data_valid, demod_data_valid_c;

qarctan qarctan_inst (
    .clk(clk), 
    .reset(reset),
    .demod_data_valid(demod_data_valid),
    .divider_ready(qarctan_ready),
    .x(short_real),
    .y(short_imag),
    .data_out(qarctan_out),
    .qarctan_done(qarctan_done)
);

always_ff @(posedge clk or posedge reset) begin
    if (reset == 1'b1) begin
        state <= EDGE_1;
        real_curr <= '0;
        imag_curr <= '0;
        real_prev <= '0;
        imag_prev <= '0;
        demod_temp <= '0;
        demod_data_valid <= '0;
    end else begin
        state <= state_c;
        real_curr <= real_curr_c;
        imag_curr <= imag_curr_c;
        real_prev <= real_prev_c;
        imag_prev <= imag_prev_c;
        demod_temp <= demod_temp_c;
        demod_data_valid <= demod_data_valid_c;
    end
end

always_comb begin
    real_curr_c = real_curr;
    imag_curr_c = imag_curr;
    real_prev_c = real_prev;
    imag_prev_c = imag_prev;
    input_rd_en = 1'b0;
    wr_en_out = 1'b0;
    qarctan_out_times_gain = '0;
    demod_temp_c = demod_temp;
    demod_out = demod_temp;
    demod_data_valid_c = '0;
    case(state)
        EDGE_1: begin
            demod_temp_c = 32'h4a6;
            wr_en_out = 1'b0;
            input_rd_en = 1'b0;
            state_c = EDGE_2;
        end
        EDGE_2: begin
            demod_temp_c = 32'h4a6;
            if (input_fifos_empty == 1'b0) begin
                wr_en_out = 1'b1;
                state_c = IDLE;
                input_rd_en = 1'b1;
                real_curr_c = real_in;
                imag_curr_c = imag_in;
                real_prev_c = real_curr;
                imag_prev_c = imag_curr;
            end else begin
                state_c = EDGE_2;
                wr_en_out = 1'b0;
                input_rd_en = 1'b0;
            end
        end
        IDLE: begin
            wr_en_out = 1'b0;
            if (input_fifos_empty == 1'b0) begin
                state_c = WAITING;
                input_rd_en = 1'b1;
                demod_data_valid_c = 1'b1;
                real_curr_c = real_in;
                imag_curr_c = imag_in;
                real_prev_c = real_curr;
                imag_prev_c = imag_curr;
            end else begin
                state_c = IDLE;
            end
        end
        WAITING: begin
            if (qarctan_done == 1'b1) begin
                state_c = OUTPUT;
                wr_en_out = 1'b0;
                qarctan_out_times_gain = qarctan_out * gain;
                demod_temp_c = DEQUANTIZE(qarctan_out_times_gain[31:0]);
            end else begin
                state_c = WAITING;
            end
        end
        OUTPUT: begin
            if (out_fifo_full == 1'b0) begin
                wr_en_out = 1'b1;
                state_c = IDLE;
            end else begin
                state_c = OUTPUT;
            end
        end
    endcase
end

    
always_comb begin
    real_prev_times_curr = $signed(real_prev) * $signed(real_curr);
    imag_prev_times_curr = $signed(real_prev) * $signed(imag_curr);
    neg_imag_prev_times_imag = -$signed(imag_prev) * $signed(imag_curr);
    neg_imag_prev_times_real = -$signed(imag_prev) * $signed(real_curr);
    short_real = DEQUANTIZE(real_prev_times_curr[31:0]) - DEQUANTIZE(neg_imag_prev_times_imag);
    short_imag = DEQUANTIZE(imag_prev_times_curr[31:0]) + DEQUANTIZE(neg_imag_prev_times_real);
end

endmodule
