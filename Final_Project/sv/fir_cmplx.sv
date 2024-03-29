`include "globals.sv" 

module fir_cmplx #(
    UNROLL = 4
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

parameter CHANNEL_COEFF_TAPS = 20;

parameter logic signed [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0] CHANNEL_COEFFICIENTS_REAL = '{
    32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
    32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
    32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001};

parameter logic signed [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0]  CHANNEL_COEFFICIENTS_IMAG = '{
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};

typedef enum logic [1:0] {S0, S1, S2} state_types;
state_types state, next_state;

logic [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0] realshift_reg;
logic [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0] realshift_reg_c;
logic [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0] imagshift_reg;
logic [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0] imagshift_reg_c;
logic [$clog2(CHANNEL_COEFF_TAPS)-1:0] taps_counter, taps_counter_c; // Always going to need 5 bits
logic [0:UNROLL-1][DATA_SIZE-1:0] yreal_sum, yreal_sum_c; 
logic [0:UNROLL-1][DATA_SIZE-1:0] yimag_sum, yimag_sum_c;

// Tap values
logic [0:UNROLL-1][DATA_SIZE-1:0] realtap_value, realtap_value_c;
logic [0:UNROLL-1][DATA_SIZE-1:0] imagtap_value, imagtap_value_c;

// Registers to hold product value from multiplication to accumulate stage
logic signed [0:UNROLL-1][DATA_SIZE_2-1:0] real_product, real_product_c;
logic signed [0:UNROLL-1][DATA_SIZE_2-1:0] imag_product, imag_product_c;
logic signed [0:UNROLL-1][DATA_SIZE_2-1:0] realimag_product, realimag_product_c;
logic signed [0:UNROLL-1][DATA_SIZE_2-1:0] imagreal_product, imagreal_product_c;

// Last cycle flag to indicate when we should be doing the last accumulation for the MAC pipeline
logic last_cycle, last_cycle_c;

// Total sum to sum up all the partial y_sums
logic [DATA_SIZE-1:0] total_realsum, total_imagsum;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        realshift_reg <= '{default: '{default: 0}};
        imagshift_reg <= '{default: '{default: 0}};
        taps_counter <= '0;
        yreal_sum <= '{default: '{default: 0}};
        yimag_sum <= '{default: '{default: 0}};
        realtap_value <= '{default: '{default: 0}};
        imagtap_value <= '{default: '{default: 0}};
        real_product <= '{default: '{default: 0}};
        imag_product <= '{default: '{default: 0}};
        realimag_product <= '{default: '{default: 0}};
        imagreal_product <= '{default: '{default: 0}};
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
    yreal_out_din = '0;
    yimag_out_din = '0;

    case(state)

        S0: begin
            if (xreal_in_empty == 1'b0 && ximag_in_empty == 1'b0) begin
                // Shift in data into shift register (NO DECIMATION because DECIMAITON == 1)
                xreal_in_rd_en = 1'b1;
                ximag_in_rd_en = 1'b1;
                realshift_reg_c[1:CHANNEL_COEFF_TAPS-1] = realshift_reg[0:CHANNEL_COEFF_TAPS-2];
                realshift_reg_c[0] = xreal_in_dout;
                imagshift_reg_c[1:CHANNEL_COEFF_TAPS-1] = imagshift_reg[0:CHANNEL_COEFF_TAPS-2];
                imagshift_reg_c[0] = ximag_in_dout;

                next_state = S1;
                for (int i = 0; i < UNROLL; i++) begin
                    // Assign first tap value to pipeline fetching of shift_reg value and MAC operation
                    realtap_value_c[i] = realshift_reg_c[i];
                    imagtap_value_c[i] = imagshift_reg_c[i];
                end
                // Increment taps_counter_c starting here so we always get the right value in S1
                taps_counter_c = taps_counter + UNROLL;
            end
        end

        S1: begin
            // This stage does both the multiplication and the dequantization + accumulation but pipelined to save cycles
            if (last_cycle == 1'b0) begin
                for (int i = 0; i < UNROLL; i++) begin
                    // If not on last cycle, perform everything
                    real_product_c[i] = $signed(realtap_value[i]) * $signed(CHANNEL_COEFFICIENTS_REAL[taps_counter-UNROLL+i]);
                    imag_product_c[i] = $signed(imagtap_value[i]) * $signed(CHANNEL_COEFFICIENTS_IMAG[taps_counter-UNROLL+i]);
                    realimag_product_c[i] = $signed(CHANNEL_COEFFICIENTS_REAL[taps_counter-UNROLL+i]) * $signed(imagtap_value[i]);
                    imagreal_product_c[i] = $signed(CHANNEL_COEFFICIENTS_IMAG[taps_counter-UNROLL+i]) * $signed(realtap_value[i]);
                end
                // Perform accumulation operation (including the subtraction)
                if (taps_counter != UNROLL) begin
                    for (int i = 0; i < UNROLL; i++) begin
                        // Don't perform acculumation in the first cycle since the first product is being calculatied in this current cycle
                        yreal_sum_c[i] = $signed(yreal_sum[i]) + DEQUANTIZE($signed(real_product[i]) - $signed(imag_product[i]));
                        yimag_sum_c[i] = $signed(yimag_sum[i]) + DEQUANTIZE($signed(realimag_product[i]) - $signed(imagreal_product[i]));
                    end
                end
                taps_counter_c = taps_counter + UNROLL;
                for (int i = 0; i < UNROLL; i++) begin
                    realtap_value_c[i] = realshift_reg[taps_counter+i];
                    imagtap_value_c[i] = imagshift_reg[taps_counter+i];
                end
                if (taps_counter == CHANNEL_COEFF_TAPS) 
                    // Trigger last_cycle flag when taps_counter has overflowed or is equal to CHANNEL_COEFF_TAPS
                    last_cycle_c = 1'b1;
            end else begin
                for (int i = 0; i < UNROLL; i++) begin
                    // If on last cycle, we only need to perform the accumulation (for the last cycle's products)
                    yreal_sum_c[i] = $signed(yreal_sum[i]) + DEQUANTIZE($signed(real_product[i]) - $signed(imag_product[i]));
                    yimag_sum_c[i] = $signed(yimag_sum[i]) + DEQUANTIZE($signed(realimag_product[i]) - $signed(imagreal_product[i]));
                end
                last_cycle_c = 1'b0;
                next_state = S2;
            end
        end

        S2: begin
            if (yreal_out_full == 1'b0 && yimag_out_full == 1'b0) begin
                // Write sum values to FIFO
                yreal_out_wr_en = 1'b1;
                yimag_out_wr_en = 1'b1;
                total_realsum = '0;
                total_imagsum = '0;
                for (int i = 0; i < UNROLL; i++) begin
                    total_realsum = $signed(total_realsum) + $signed(yreal_sum[i]);
                    total_imagsum = $signed(total_imagsum) + $signed(yimag_sum[i]);
                end
                yreal_out_din = total_realsum;
                yimag_out_din = total_imagsum;
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
            yreal_sum_c = '{default: '{default: 0}};
            yimag_sum_c = '{default: '{default: 0}};
            realtap_value_c = '{default: '{default: 0}};
            imagtap_value_c = '{default: '{default: 0}};
            real_product_c = '{default: '{default: 0}};
            imag_product_c = '{default: '{default: 0}};
            realimag_product_c = '{default: '{default: 0}};
            imagreal_product_c = '{default: '{default: 0}};
            last_cycle_c = 'X;
            realshift_reg_c = '{default: '{default: 0}};
            imagshift_reg_c = '{default: '{default: 0}};
        end
    endcase
end


endmodule