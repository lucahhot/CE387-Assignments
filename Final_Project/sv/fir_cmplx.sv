`include "globals.sv" 

module fir_cmplx #(
    parameter NUM_TAPS = 20,
    parameter DECIMATION = 10,
    parameter logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] CHANNEL_COEFFS_REAL = '{default: '{default: 0}},
    parameter logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] CHANNEL_COEFFS_IMAG = '{default: '{default: 0}},
    parameter UNROLL_FACTOR = 32
) (
    input   logic clock,
    input   logic reset,
    input   logic [DATA_SIZE-1:0] xreal_in_dout,   
    input   logic xreal_in_empty,
    output  logic xreal_in_rd_en,
    input   logic [DATA_SIZE-1:0] ximag_in_dout,
    input   logic ximag_in_empty,
    input   logic ximag_in_rd_en,

    output  logic yreal_out_wr_en,
    input   logic yreal_out_full,
    output  logic [DATA_SIZE-1:0] yreal_out_din,  
    output  logic yimag_out_wr_en,
    input   logic yimag_out_full,
    output  logic [DATA_SIZE-1:0] yimag_out_din
);

typedef enum logic [1:0] {S0, S1, S2, S3} state_types;
state_types state, next_state;

logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] realshift_reg;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] realshift_reg_c;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] imagshift_reg;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] imagshift_reg_c;
logic [$clog2(DECIMATION)-1:0] decimation_counter, decimation_counter_c;
logic [$clog2(NUM_TAPS)-1:0] taps_counter, taps_counter_c;
logic [DATA_SIZE-1:0] yreal_sum, yreal_sum_c; 
logic [DATA_SIZE-1:0] yimag_sum, yimag_sum_c; 
logic [$clog2(NUM_TAPS)-1:0] unroll_counter, unroll_counter_c;

// Register to hold all the products of x_in and coefficients so they can be calculated in parallel
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] real_products;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] real_products_c;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] imag_products;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] imag_products_c;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] realimag_products;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] realimag_products_c;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] imagreal_products;
logic [DATA_SIZE-1:0] [0:NUM_TAPS-1] imagreal_products_c;


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        realshift_reg <= '{default: '{default: 0}};
        imag_shift_reg <= '{default: '{default: 0}};
        decimation_counter <= '0;
        taps_counter <= '0;
        yreal_sum <= '0;
        yimag_sum <= '0;
        real_products <= '{default: '{default: 0}};
        imag_products <= '{default: '{default: 0}};
        realimag_products <= '{default: '{default: 0}};
        imagreal_products <= '{default: '{default: 0}};
        unroll_counter <= '0;
    end else begin
        state <= next_state;
        realshift_reg <= realshift_reg_c;
        imagshift_reg <= imagshift_reg_c;
        decimation_counter <= decimation_counter_c;
        taps_counter <= taps_counter_c;
        yreal_sum <= yreal_sum_c;
        yimag_sum <= yimag_sum_c;
        real_products <= real_products_c;
        imag_products <= imag_products_c;
        realimag_products <= realimag_products_c;
        imagreal_products <= imagreal_products_c;
        unroll_counter <= unroll_counter_c;
    end
end

always_comb begin
    next_state = state;
    xreal_in_rd_en = 1'b0;
    ximag_in_rd_en = 1'b0;
    yreal_out_wr_en = 1'b0;
    yimag_out_wr_en = 1'b0;
    decimation_counter_c = decimation_counter;
    realshift_reg_c = realshift_reg;
    imagshift_reg_c = imagshift_reg;
    taps_counter_c = taps_counter;
    yreal_sum_c = yreal_sum;
    yimag_sum_c = yimag_sum;
    real_products_c = real_products;
    imag_products_c = imag_products;
    realimag_products_c = realimag_products;
    imagreal_products_c = imagreal_products;
    unroll_counter_c = unroll_counter;

    case(state)

        S0: begin
            if (xreal_in_empty == 1'b0 && ximag_in_empty) begin
                // Shift in data into shift register and adjust for decimation (take 1 sample in DECIMATION samples)
                xreal_in_rd_en = 1'b1;
                ximag_in_rd_en = 1'b1;
                realshift_reg_c[NUM_TAPS-1:1] = realshift_reg[NUM_TAPS-2:0];
                realshift_reg_c[0] = xreal_in_dout;
                imagshift_reg_c[NUM_TAPS-1:1] = imagshift_reg[NUM_TAPS-2:0];
                imagshift_reg_c[0] = ximag_in_dout;
                decimation_counter_c = decimation_counter + 1'b1;
            end
            if (decimation_counter == DECIMATION - 1) 
                next_state = S1;
            else
                next_state = S0;
        end

        S1: begin
            // Multiply in parallel according to UNROLL_FACTOR
            // Eg: If UNROLL_FACTOR == 2, then if NUM_TAPS == 32, we would do 2 multiplications in parallel at once over 16 cycles
            for (int i = unroll_counter; i < (unroll_counter + UNROLL_FACTOR); i++) begin
                real_products_c[i] = MULTIPLY_ROUNDING(realshift_reg[i],CHANNEL_COEFFS_REAL[i]);
                imag_products_c[i] = MULTIPLY_ROUNDING(imagshift_reg[i],CHANNEL_COEFFS_IMAG[i]);
                realimag_products_c[i] = MULTIPLY_ROUNDING(CHANNEL_COEFFS_REAL[i],imagshift_reg[i]);
                imagreal_products_c[i] = MULTIPLY_ROUNDING(CHANNEL_COEFFS_IMAG[i],realshift_reg[i]);
            end
            unroll_counter_c = unroll_counter + UNROLL_FACTOR;
            if (unroll_counter == NUM_TAPS - UNROLL_FACTOR)
                next_state = S2;
            else
                next_state = S1;
        end

        S2: begin
            // Accumulate state: Do all the additions and subtractions in 1 cycle
            for (int i = 0; i < NUM_TAPS; i++) begin
                yreal_sum_c = yreal_sum_c + (real_products[i] - imag_products[i]);
                yimag_sum_c = yimag_sum_c + (realimag_products[i] - imagreal_products[i]);
            end
            next_state = S3;
        end

        S3: begin
            if (yreal_out_full == 1'b0 && yimag_out_full == 1'b0) begin
                // Write sum values to FIFO
                yreal_out_wr_en = 1'b1;
                yimag_out_wr_en = 1'b1;
                yreal_out_din = yreal_sum;
                yimag_out_din = yimag_sum;
                // Reset all the values for the next set of data
                taps_counter_c = '0;
                decimation_counter_c = '0;
                yreal_sum_c = '0;
                yimag_sum_c = '0;
                next_state = S0;
            end
        end

        default: begin
            next_state = S0;
            xreal_in_rd_en = 1'b0;
            ximag_in_rd_en = 1'b0;
            yreal_out_wr_en = 1'b0;
            yimag_out_wr_en = 1'b0;
            yreal_out_din = '0;
            yimag_out_din = '0;
            decimation_counter_c = 'X;
            taps_counter_c = 'X;
            yreal_sum_c = 'X;
            yimag_sum_c = 'X;
            realshift_reg_c = '{default: '{default : 0}};
            imagshift_reg_c = '{default: '{default : 0}};
            real_products_c = '{default: '{default : 0}};
            imag_products_c = '{default: '{default : 0}};
            realimag_products_c = '{default: '{default : 0}};
            imagreal_products_c = '{default: '{default : 0}};
            unroll_counter_c = 'X;
        end
    endcase
end


endmodule