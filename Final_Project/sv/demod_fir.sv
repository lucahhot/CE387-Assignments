`include "globals.sv" 

module demod_fir #(
    parameter NUM_TAPS = 32,
    parameter DECIMATION = 8,
    parameter logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] COEFFICIENTS = '{default: '{default: 0}}
) (
    input   logic clock,
    input   logic reset,
    input   logic [DATA_SIZE-1:0] x_in_dout,   // Quantized input 
    input   logic x_in_empty,
    output  logic x_in_rd_en,
    output  logic y_out_wr_en,
    input   logic y_out_full,
    output  logic [DATA_SIZE-1:0] y_out_din,  // Quantized output

    input   logic fir_a_ready,
    input   logic fir_b_ready,
    output  logic demod_fir_ready
);

typedef enum logic [1:0] {S0, S1, S2, S3} state_types;
state_types state, next_state;

logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] shift_reg ;
logic [0:NUM_TAPS-1][DATA_SIZE-1:0] shift_reg_c ;
logic [$clog2(DECIMATION)-1:0] decimation_counter, decimation_counter_c;
logic [$clog2(NUM_TAPS)-1:0] taps_counter, taps_counter_c;
logic [DATA_SIZE-1:0] y_sum, y_sum_c; 

// Register to hold shift_reg value to be used in MAC since reading from shift_reg takes forever
logic [DATA_SIZE-1:0] tap_value, tap_value_c;

// Registers to hold product value from multiplication to accumulate stage
logic signed [DATA_SIZE-1:0] product, product_c;

// Last cycle flag to indicate when we should be doing the last accumulation for the MAC pipeline
logic last_cycle, last_cycle_c;

// Extra register to count taps (that's not offset)
logic [$clog2(NUM_TAPS)-1:0] coefficient_counter, coefficient_counter_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        shift_reg <= '{default: '{default: 0}};
        decimation_counter <= '0;
        taps_counter <= '0;
        y_sum <= '0;
        tap_value <= '0;
        product <= '0;
        last_cycle <= '0;
        coefficient_counter <= '0;
    end else begin
        state <= next_state;
        shift_reg <= shift_reg_c;
        decimation_counter <= decimation_counter_c;
        taps_counter <= taps_counter_c;
        y_sum <= y_sum_c;
        tap_value <= tap_value_c;
        product <= product_c;
        last_cycle <= last_cycle_c;
        coefficient_counter <= coefficient_counter_c;
    end
end

always_comb begin
    next_state = state;
    x_in_rd_en = 1'b0;
    y_out_wr_en = 1'b0;
    decimation_counter_c = decimation_counter;
    shift_reg_c = shift_reg;
    taps_counter_c = taps_counter;
    y_sum_c = y_sum;
    tap_value_c = tap_value;
    product_c = product;
    last_cycle_c = last_cycle;
    coefficient_counter_c = coefficient_counter;
    demod_fir_ready = 1'b0;

    case(state)

        S0: begin
            demod_fir_ready = 1'b1;
            if (fir_a_ready == 1'b1 && fir_b_ready == 1'b1) begin
                if (x_in_empty == 1'b0) begin
                    // Read data only when other FIRs are ready
                    // Shift in data into shift register and downsample according to DECIMATION constant
                    x_in_rd_en = 1'b1;
                    shift_reg_c[1:NUM_TAPS-1] = shift_reg[0:NUM_TAPS-2];
                    shift_reg_c[0] = x_in_dout;
                    decimation_counter_c = decimation_counter + 1'b1;

                    if (decimation_counter == DECIMATION - 1) begin
                        next_state = S1;
                        // Assign first tap value to pipeline fetching of shift_reg value and MAC operation
                        tap_value_c = shift_reg_c[0];
                        // Increment taps_counter_c starting here so we always get the right value in S1
                        taps_counter_c = taps_counter + 1'b1;
                    end else
                        next_state = S0;
                end
            end
        end
        

        S1: begin
            // This stage does both the multiplication and the dequantization + accumulation but pipelined to save cycles
            if (last_cycle == 1'b0) begin
                // If not on last cycle, perform everything
                product_c = $signed(tap_value) * $signed(COEFFICIENTS[NUM_TAPS-coefficient_counter-1]);
                if (taps_counter != 1'b1)
                    // Don't perform acculumation in the first cycle since the first product is being calculatied in this current cycle
                    y_sum_c = $signed(y_sum) + DEQUANTIZE(product);
                taps_counter_c = taps_counter + 1'b1;
                coefficient_counter_c = coefficient_counter + 1'b1;
                tap_value_c = shift_reg[taps_counter];
                // Trigger last_cycle flag when taps_counter has overflowed (will always do so because we are using 5 bits for 32 tap values)
                if (taps_counter == 0)
                    last_cycle_c = 1'b1;
            end else begin
                // If on last cycle, we only need to perform the accumulation (for the last cycle's products)
                y_sum_c = $signed(y_sum) + DEQUANTIZE(product);
                last_cycle_c = 1'b0;
                next_state = S2;
            end            
        end

        S2: begin
            if (y_out_full == 1'b0) begin
                // Write y_out value to FIFO
                y_out_wr_en = 1'b1;
                y_out_din = y_sum;
                // Reset all the values for the next set of data
                taps_counter_c = '0;
                coefficient_counter_c = '0;
                decimation_counter_c = '0;
                y_sum_c = '0;
                next_state = S0;
            end
        end

        default: begin
            next_state = S0;
            x_in_rd_en = 1'b0;
            y_out_wr_en = 1'b0;
            y_out_din = '0;
            decimation_counter_c = 'X;
            taps_counter_c = 'X;
            y_sum_c = 'X;
            shift_reg_c = '{default: '{default: 0}};
            tap_value_c = 'X;
            product_c = 'X;
            last_cycle_c = 'X;
            coefficient_counter_c = 'X;
            demod_fir_ready = 1'b0;
        end
    endcase
end


endmodule