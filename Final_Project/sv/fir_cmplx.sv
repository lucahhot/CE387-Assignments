`include "globals.sv" 

module fir_cmplx #(
    parameter NUM_TAPS = 20,
    parameter DECIMATION = 1,
    parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0] COEFFICIENTS_REAL = '{default: '{default: 0}},
    parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0] COEFFICIENTS_IMAG = '{default: '{default: 0}}
) (
    input   logic clock,
    input   logic reset,
    input   logic [DATA_SIZE-1:0] xreal_in_dout,   
    input   logic xreal_in_empty,
    output  logic xreal_in_rd_en,
    input   logic [DATA_SIZE-1:0] ximag_in_dout,
    input   logic ximag_in_empty,
    output  logic ximag_in_rd_en,

    output  logic yreal_out_wr_en,
    input   logic yreal_out_full,
    output  logic [DATA_SIZE-1:0] yreal_out_din,  
    output  logic yimag_out_wr_en,
    input   logic yimag_out_full,
    output  logic [DATA_SIZE-1:0] yimag_out_din
);

typedef enum logic [1:0] {S0, S1, S2} state_types;
state_types state, next_state;

logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] realshift_reg;
logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] realshift_reg_c;
logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] imagshift_reg;
logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] imagshift_reg_c;
logic [$clog2(DECIMATION)-1:0] decimation_counter, decimation_counter_c;
logic [$clog2(NUM_TAPS)-1:0] taps_counter, taps_counter_c;
logic [DATA_SIZE_2-1:0] yreal_sum, yreal_sum_c; 
logic [DATA_SIZE_2-1:0] yimag_sum, yimag_sum_c;

// Tap values
logic [DATA_SIZE-1:0] realtap_value, realtap_value_c;
logic [DATA_SIZE-1:0] imagtap_value, imagtap_value_c;

// Wires for more readable code in MAC operation
logic [DATA_SIZE_2-1:0] real_product;
logic [DATA_SIZE_2-1:0] imag_product;
logic [DATA_SIZE_2-1:0] realimag_product;
logic [DATA_SIZE_2-1:0] imagreal_product;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        realshift_reg <= '{default: '{default: 0}};
        imagshift_reg <= '{default: '{default: 0}};
        decimation_counter <= '0;
        taps_counter <= '0;
        yreal_sum <= '0;
        yimag_sum <= '0;
        realtap_value <= '0;
        imagtap_value <= '0;
    end else begin
        state <= next_state;
        realshift_reg <= realshift_reg_c;
        imagshift_reg <= imagshift_reg_c;
        decimation_counter <= decimation_counter_c;
        taps_counter <= taps_counter_c;
        yreal_sum <= yreal_sum_c;
        yimag_sum <= yimag_sum_c;
        realtap_value <= realtap_value_c;
        imagtap_value <= imagtap_value_c;
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
    realtap_value_c = realtap_value;
    imagtap_value_c = imagtap_value;

    case(state)

        S0: begin
            if (xreal_in_empty == 1'b0 && ximag_in_empty == 1'b0) begin
                // Shift in data into shift register and adjust for decimation (take 1 sample in DECIMATION samples)
                xreal_in_rd_en = 1'b1;
                ximag_in_rd_en = 1'b1;
                realshift_reg_c[1:NUM_TAPS-1] = realshift_reg[0:NUM_TAPS-2];
                realshift_reg_c[0] = xreal_in_dout;
                imagshift_reg_c[1:NUM_TAPS-1] = imagshift_reg[0:NUM_TAPS-2];
                imagshift_reg_c[0] = ximag_in_dout;
                decimation_counter_c = decimation_counter + 1'b1;
            end
            if (decimation_counter_c == DECIMATION) begin
                next_state = S1;
                // Assign first tap value to pipeline fetching of shift_reg value and MAC operation
                realtap_value_c = xreal_in_dout;
                imagtap_value_c = ximag_in_dout;
                // Increment taps_counter_c starting here so we always get the right value in S1
                taps_counter_c = taps_counter + 1'b1;
            end
            else
                next_state = S0;
        end

        S1: begin
            // Perform multiplications (using MULTIPLY_ROUNDING)
            // real_product = MULTIPLY_ROUNDING_NODEQUANTIZE(realtap_value,COEFFICIENTS_REAL[taps_counter]);
            // imag_product = MULTIPLY_ROUNDING_NODEQUANTIZE(imagtap_value,COEFFICIENTS_IMAG[taps_counter]);
            // realimag_product = MULTIPLY_ROUNDING_NODEQUANTIZE(COEFFICIENTS_REAL[taps_counter],imagtap_value);
            // imagreal_product = MULTIPLY_ROUNDING_NODEQUANTIZE(COEFFICIENTS_IMAG[taps_counter],realtap_value);
            // Using normal * since it's error free
            // Need to account for taps_value potentially overflowing depending on the value of NUM_TAPS (necessary to be able to pipeline fetching of values from the shift registers)
            if (taps_counter == 0) begin
                real_product = $signed(realtap_value) * $signed(COEFFICIENTS_REAL[NUM_TAPS-1]);
                imag_product = $signed(imagtap_value) * $signed(COEFFICIENTS_IMAG[NUM_TAPS-1]);
                realimag_product = $signed(COEFFICIENTS_REAL[NUM_TAPS-1]) * $signed(imagtap_value);
                imagreal_product = $signed(COEFFICIENTS_IMAG[NUM_TAPS-1]) * $signed(realtap_value);
            end else begin
                real_product = $signed(realtap_value) * $signed(COEFFICIENTS_REAL[taps_counter-1]);
                imag_product = $signed(imagtap_value) * $signed(COEFFICIENTS_IMAG[taps_counter-1]);
                realimag_product = $signed(COEFFICIENTS_REAL[taps_counter-1]) * $signed(imagtap_value);
                imagreal_product = $signed(COEFFICIENTS_IMAG[taps_counter-1]) * $signed(realtap_value);
            end
            // Perform accumulation operation (including the subtraction)
            yreal_sum_c = $signed(yreal_sum) + DEQUANTIZE($signed(real_product) - $signed(imag_product));
            yimag_sum_c = $signed(yimag_sum) + DEQUANTIZE($signed(realimag_product) - $signed(imagreal_product));
            taps_counter_c = taps_counter + 1'b1;
            realtap_value_c = realshift_reg[taps_counter];
            imagtap_value_c = imagshift_reg[taps_counter];
            // Change state when taps_counter has overflowed or is equal to NUM_TAPS
            if (taps_counter == NUM_TAPS || taps_counter == 0)
                next_state = S2;
            else
                next_state = S1;
        end

        S2: begin
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
            realtap_value_c = 'X;
            imagtap_value_c = 'X;
        end
    endcase
end


endmodule