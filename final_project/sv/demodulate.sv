`include "globals.sv" 

module demodulate (
    input   logic                   clk,
    input   logic                   reset,
    output  logic                   real_rd_en,
    input   logic                   real_empty,
    input   logic [DATA_SIZE-1:0]   real_in,
    output  logic                   imag_rd_en,
    input   logic                   imag_empty,
    input   logic [DATA_SIZE-1:0]   imag_in,
    output  logic [DATA_SIZE-1:0]   demod_out,
    output  logic                   wr_en_out,
    input   logic                   out_fifo_full
);

const logic [DATA_SIZE-1:0] gain = 32'h000002f6;

typedef enum logic [2:0] {EDGE_1, EDGE_2, IDLE, WAITING, WAITING2, OUTPUT} state_t;
state_t state, next_state;

logic [DATA_SIZE-1:0] real_curr, real_curr_c;
logic [DATA_SIZE-1:0] imag_curr, imag_curr_c;
logic [DATA_SIZE-1:0] real_prev, real_prev_c;
logic [DATA_SIZE-1:0] imag_prev, imag_prev_c;

// Wire to hold qarctan output
logic [DATA_SIZE-1:0] qarctan_out;

// Register to hold qarctan * gain product
logic [DATA_SIZE-1:0] qarctan_gain_product, qarctan_gain_product_c;


logic [DATA_SIZE_2-1:0] real_prev_times_curr, imag_prev_times_curr, neg_imag_prev_times_imag, neg_imag_prev_times_real;
logic [DATA_SIZE-1:0] short_real, short_imag;
logic [DATA_SIZE-1:0] demod_temp, demod_temp_c;
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
        qarctan_gain_product <= '0;
    end else begin
        state <= next_state; 
        real_curr <= real_curr_c; 
        imag_curr <= imag_curr_c;
        real_prev <= real_prev_c;
        imag_prev <= imag_prev_c;
        demod_temp <= demod_temp_c;
        demod_data_valid <= demod_data_valid_c;
        qarctan_gain_product <= qarctan_gain_product_c;
    end
end

always_comb begin
    real_curr_c = real_curr;
    imag_curr_c = imag_curr;
    real_prev_c = real_prev;
    imag_prev_c = imag_prev;
    real_rd_en = 1'b0;
    imag_rd_en = 1'b0;
    wr_en_out = 1'b0;
    qarctan_gain_product_c = qarctan_gain_product;
    demod_temp_c = demod_temp;
    demod_data_valid_c = '0;
    // demod_out is always assigned here
    demod_out = demod_temp;

    case(state)
        EDGE_1: begin
            demod_temp_c = 32'h4a6;
            wr_en_out = 1'b0;
            real_rd_en = 1'b0;
            imag_rd_en = 1'b0;
            next_state = EDGE_2;
        end
        EDGE_2: begin
            demod_temp_c = 32'h4a6;
            if (real_empty == 1'b0 && imag_empty == 1'b0) begin
                wr_en_out = 1'b1;
                real_rd_en = 1'b1;
                imag_rd_en = 1'b1;
                real_curr_c = real_in;
                imag_curr_c = imag_in;
                real_prev_c = real_curr;
                imag_prev_c = imag_curr;
                next_state = IDLE;
            end else begin
                next_state = EDGE_2;
                real_rd_en = 1'b0;
                imag_rd_en = 1'b0;
            end
        end
        IDLE: begin
            if (real_empty == 1'b0 && imag_empty == 1'b0) begin
                next_state = WAITING;
                real_rd_en = 1'b1;
                imag_rd_en = 1'b1;
                // This is where we start the qarctan calculation
                demod_data_valid_c = 1'b1;
                real_curr_c = real_in;
                imag_curr_c = imag_in;
                real_prev_c = real_curr;
                imag_prev_c = imag_curr;
            end else begin
                next_state = IDLE;
            end
        end
        WAITING: begin
            if (qarctan_done == 1'b1) begin
                qarctan_gain_product_c = qarctan_out * gain;
                demod_temp_c = DEQUANTIZE(qarctan_gain_product_c[DATA_SIZE-1:0]);
                next_state = OUTPUT;
            end else begin
                next_state = WAITING;
            end
        end
        
        OUTPUT: begin
            if (out_fifo_full == 1'b0) begin
                wr_en_out = 1'b1;
                next_state = IDLE;
            end else begin
                next_state = OUTPUT;
            end
        end
    endcase
end

always_comb begin
    real_prev_times_curr = $signed(real_prev) * $signed(real_curr);
    imag_prev_times_curr = $signed(real_prev) * $signed(imag_curr);
    neg_imag_prev_times_imag = -$signed(imag_prev) * $signed(imag_curr);
    neg_imag_prev_times_real = -$signed(imag_prev) * $signed(real_curr);
    short_real = DEQUANTIZE(real_prev_times_curr[DATA_SIZE-1:0]) - DEQUANTIZE(neg_imag_prev_times_imag);
    short_imag = DEQUANTIZE(imag_prev_times_curr[DATA_SIZE-1:0]) + DEQUANTIZE(neg_imag_prev_times_real);
end

endmodule