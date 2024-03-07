`include "globals.sv" 

module fir_cmplx #(
    parameter NUM_TAPS = 20,
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
logic [$clog2(NUM_TAPS)-1:0] taps_counter, taps_counter_c; // Always going to need 5 bits
logic [DATA_SIZE-1:0] yreal_sum, yreal_sum_c; 
logic [DATA_SIZE-1:0] yimag_sum, yimag_sum_c;

// Tap values
logic [DATA_SIZE-1:0] realtap_value, realtap_value_c;
logic [DATA_SIZE-1:0] imagtap_value, imagtap_value_c;

// Registers to hold product value from multiplication to accumulate stage
logic [DATA_SIZE_2-1:0] real_product, real_product_c;
logic [DATA_SIZE_2-1:0] imag_product, imag_product_c;
logic [DATA_SIZE_2-1:0] realimag_product, realimag_product_c;
logic [DATA_SIZE_2-1:0] imagreal_product, imagreal_product_c;

// Last cycle flag to indicate when we should be doing the last accumulation for the MAC pipeline
logic last_cycle, last_cycle_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        realshift_reg <= '{default: '{default: 0}};
        imagshift_reg <= '{default: '{default: 0}};
        taps_counter <= '0;
        yreal_sum <= '0;
        yimag_sum <= '0;
        realtap_value <= '0;
        imagtap_value <= '0;
        real_product <= '0;
        imag_product <= '0;
        realimag_product <= '0;
        imagreal_product <= '0;
        last_cycle <= '0;
    end else begin
        state <= next_state;
        realshift_reg <= realshift_reg_c;
        imagshift_reg <= imagshift_reg_c;
        taps_counter <= taps_counter_c;
        yreal_sum <= yreal_sum_c;
        yimag_sum <= yimag_sum_c;
        realtap_value <= realtap_value_c;
        imagtap_value <= imagtap_value_c;
        real_product <= real_product_c;
        imag_product <= imag_product_c;
        realimag_product <= realimag_product_c;
        imagreal_product <= imagreal_product_c;
        last_cycle <= last_cycle_c;
    end
end

always_comb begin
    next_state = state;
    xreal_in_rd_en = 1'b0;
    ximag_in_rd_en = 1'b0;
    yreal_out_wr_en = 1'b0;
    yimag_out_wr_en = 1'b0;
    realshift_reg_c = realshift_reg;
    imagshift_reg_c = imagshift_reg;
    taps_counter_c = taps_counter;
    yreal_sum_c = yreal_sum;
    yimag_sum_c = yimag_sum;
    realtap_value_c = realtap_value;
    imagtap_value_c = imagtap_value;
    real_product_c = real_product;
    imag_product_c = imag_product;
    realimag_product_c = realimag_product;
    imagreal_product_c = imagreal_product;
    last_cycle_c = last_cycle;

    case(state)

        S0: begin
            if (xreal_in_empty == 1'b0 && ximag_in_empty == 1'b0) begin
                // Shift in data into shift register (NO DECIMATION because DECIMAITON == 1)
                xreal_in_rd_en = 1'b1;
                ximag_in_rd_en = 1'b1;
                realshift_reg_c[1:NUM_TAPS-1] = realshift_reg[0:NUM_TAPS-2];
                realshift_reg_c[0] = xreal_in_dout;
                imagshift_reg_c[1:NUM_TAPS-1] = imagshift_reg[0:NUM_TAPS-2];
                imagshift_reg_c[0] = ximag_in_dout;

                next_state = S1;
                // Assign first tap value to pipeline fetching of shift_reg value and MAC operation
                realtap_value_c = xreal_in_dout;
                imagtap_value_c = ximag_in_dout;
                // Increment taps_counter_c starting here so we always get the right value in S1
                taps_counter_c = taps_counter + 1'b1;
            end
        end

        S1: begin
            // This stage does both the multiplication and the dequantization + accumulation but pipelined to save cycles
            if (last_cycle == 1'b0) begin
                // If not on last cycle, perform everything
                real_product_c = $signed(realtap_value) * $signed(COEFFICIENTS_REAL[taps_counter-1]);
                imag_product_c = $signed(imagtap_value) * $signed(COEFFICIENTS_IMAG[taps_counter-1]);
                realimag_product_c = $signed(COEFFICIENTS_REAL[taps_counter-1]) * $signed(imagtap_value);
                imagreal_product_c = $signed(COEFFICIENTS_IMAG[taps_counter-1]) * $signed(realtap_value);
                // Perform accumulation operation (including the subtraction)
                if (taps_counter != 1'b1) begin
                    // Don't perform acculumation in the first cycle since the first product is being calculatied in this current cycle
                    yreal_sum_c = $signed(yreal_sum) + DEQUANTIZE($signed(real_product) - $signed(imag_product));
                    yimag_sum_c = $signed(yimag_sum) + DEQUANTIZE($signed(realimag_product) - $signed(imagreal_product));
                end
                taps_counter_c = taps_counter + 1'b1;
                realtap_value_c = realshift_reg[taps_counter];
                imagtap_value_c = imagshift_reg[taps_counter];
                // Trigger last_cycle flag when taps_counter has overflowed or is equal to NUM_TAPS
                if (taps_counter == NUM_TAPS)
                    last_cycle_c = 1'b1;
            end else begin
                // If on last cycle, we only need to perform the accumulation (for the last cycle's products)
                yreal_sum_c = $signed(yreal_sum) + DEQUANTIZE($signed(real_product) - $signed(imag_product));
                yimag_sum_c = $signed(yimag_sum) + DEQUANTIZE($signed(realimag_product) - $signed(imagreal_product));
                last_cycle_c = 1'b0;
                next_state = S2;
            end
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
            taps_counter_c = 'X;
            yreal_sum_c = 'X;
            yimag_sum_c = 'X;
            realtap_value_c = 'X;
            imagtap_value_c = 'X;
            real_product_c = 'X;
            imag_product_c = 'X;
            realimag_product_c = 'X;
            imagreal_product_c = 'X;
            last_cycle_c = 'X;
        end
    endcase
end


endmodule