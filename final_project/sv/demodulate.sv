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

typedef enum logic [2:0] {READ,MULTIPLICATION,SEND_QARCTAN,WAITING,OUTPUT} state_t;
state_t state, next_state;

logic [DATA_SIZE-1:0] real_curr, real_curr_c;
logic [DATA_SIZE-1:0] imag_curr, imag_curr_c;
logic [DATA_SIZE-1:0] real_prev, real_prev_c;
logic [DATA_SIZE-1:0] imag_prev, imag_prev_c;

// Wire to hold qarctan output
logic [DATA_SIZE-1:0] qarctan_out;

logic [DATA_SIZE-1:0] real_prev_real_product, real_prev_real_product_c;
logic [DATA_SIZE-1:0] imag_prev_imag_product, imag_prev_imag_product_c;
logic [DATA_SIZE-1:0] real_prev_imag_product, real_prev_imag_product_c;
logic [DATA_SIZE-1:0] imag_prev_real_product, imag_prev_real_product_c;
logic [DATA_SIZE-1:0] qarctan_real, qarctan_imag;
logic [DATA_SIZE-1:0] demod_temp, demod_temp_c;

// Handshaking signals from demod to qarctan
logic qarctan_done;
logic demod_data_valid;

qarctan qarctan_inst (
    .clk(clk), 
    .reset(reset),
    .demod_data_valid(demod_data_valid),
    .x(qarctan_real),
    .y(qarctan_imag),
    .data_out(qarctan_out),
    .qarctan_done(qarctan_done)
);

always_ff @(posedge clk or posedge reset) begin
    if (reset == 1'b1) begin
        state <= READ;
        real_curr <= '0;
        imag_curr <= '0;
        real_prev <= '0;
        imag_prev <= '0;
        demod_temp <= '0;
        real_prev_real_product <= '0;
        imag_prev_imag_product <= '0;
        real_prev_imag_product <= '0;
        imag_prev_real_product <= '0;
    end else begin
        state <= next_state; 
        real_curr <= real_curr_c; 
        imag_curr <= imag_curr_c;
        real_prev <= real_prev_c;
        imag_prev <= imag_prev_c;
        demod_temp <= demod_temp_c;
        real_prev_real_product <= real_prev_real_product_c;
        imag_prev_imag_product <= imag_prev_imag_product_c;
        real_prev_imag_product <= real_prev_imag_product_c;
        imag_prev_real_product <= imag_prev_real_product_c;
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
    demod_temp_c = demod_temp;
    real_prev_real_product_c = real_prev_real_product;
    imag_prev_imag_product_c = imag_prev_imag_product;
    real_prev_imag_product_c = real_prev_imag_product;
    imag_prev_real_product_c = imag_prev_real_product;

    // demod_out is always assigned here
    demod_out = demod_temp;

    demod_data_valid = 1'b0;

    case(state)

        READ: begin
            if (real_empty == 1'b0 && imag_empty == 1'b0) begin
                real_rd_en = 1'b1;
                imag_rd_en = 1'b1;
                // Read in real and imag inputs from FIFOs
                real_curr_c = real_in;
                imag_curr_c = imag_in;
                real_prev_c = real_curr;
                imag_prev_c = imag_curr;
                next_state = MULTIPLICATION;
            end else
                next_state = READ;
        end

        MULTIPLICATION: begin 
            // Do combinational multiplications
            real_prev_real_product_c = ($signed(real_prev) * $signed(real_curr));
            imag_prev_imag_product_c = (-$signed(imag_prev) * $signed(imag_curr));
            real_prev_imag_product_c = ($signed(real_prev) * $signed(imag_curr));
            imag_prev_real_product_c = (-$signed(imag_prev) * $signed(real_curr));
            next_state = SEND_QARCTAN;
        end

        SEND_QARCTAN: begin
            // Finish computation for quartan inputs and start qarctan calculation
            qarctan_real = DEQUANTIZE(real_prev_real_product) - DEQUANTIZE(imag_prev_imag_product);
            qarctan_imag = DEQUANTIZE(real_prev_imag_product) + DEQUANTIZE(imag_prev_real_product);
            // Start qarctan calculation by asserteding demod_data_valid
            demod_data_valid = 1'b1;
            next_state = WAITING;
        end

        WAITING: begin
            // Wait for qarctan_done to be 1 which means our qarctan calculation has finished
            if (qarctan_done == 1'b1) begin
                // Calculate demod_out
                demod_temp_c = ($signed(qarctan_out) * $signed(gain));
                next_state = OUTPUT;
            end else
                // Keep waiting for qarctan
                next_state = WAITING;
        end

        OUTPUT: begin
            // Write out demod output
            if (out_fifo_full == 1'b0) begin
                wr_en_out = 1'b1;
                demod_out = DEQUANTIZE(demod_temp);
                next_state = READ;
            end
        end

        default: begin
            wr_en_out = 1'b1;
            demod_out = '0;
            real_rd_en = 1'b0;
            imag_rd_en = 1'b0;
            real_curr_c = 'X;
            imag_curr_c = 'X;
            real_prev_c = 'X;
            imag_prev_c = 'X;
            demod_temp_c = 'X;
            real_prev_real_product_c = 'X;
            imag_prev_imag_product_c = 'X;
            real_prev_imag_product_c = 'X;
            imag_prev_real_product_c = 'X;
            demod_data_valid = 1'b0;
        end

    endcase
end

endmodule