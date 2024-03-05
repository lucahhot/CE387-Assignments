`include "globals.sv" 

module fir #(
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
    output  logic [DATA_SIZE-1:0] y_out_din  // Quantized output
);

typedef enum logic [1:0] {S0, S1, S2} state_types;
state_types state, next_state;

logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] shift_reg ;
logic [0:NUM_TAPS-1][DATA_SIZE-1:0] shift_reg_c ;
logic [$clog2(DECIMATION)-1:0] decimation_counter, decimation_counter_c;
logic [$clog2(NUM_TAPS)-1:0] taps_counter, taps_counter_c;
logic [DATA_SIZE-1:0] y_sum, y_sum_c; 

// Register to hold shift_reg value to be used in MAC since reading from shift_reg takes forever
logic [DATA_SIZE-1:0] tap_value, tap_value_c;


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        shift_reg <= '{default: '{default: 0}};
        decimation_counter <= '0;
        taps_counter <= '0;
        y_sum <= '0;
        tap_value <= '0;
    end else begin
        state <= next_state;
        shift_reg <= shift_reg_c;
        decimation_counter <= decimation_counter_c;
        taps_counter <= taps_counter_c;
        y_sum <= y_sum_c;
        tap_value <= tap_value_c;
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

    case(state)

        S0: begin
            if (x_in_empty == 1'b0) begin
                // Shift in data into shift register and downsample according to DECIMATION constant
                x_in_rd_en = 1'b1;
                shift_reg_c[1:NUM_TAPS-1] = shift_reg[0:NUM_TAPS-2];
                shift_reg_c[0] = x_in_dout;
                decimation_counter_c = decimation_counter + 1'b1;
            end
            if (decimation_counter == DECIMATION - 1) begin
                next_state = S1;
                // Assign first tap value to pipeline fetching of shift_reg value and MAC operation
                tap_value_c = x_in_dout;
                // Increment taps_counter_c starting here so we always get the right value in S1
                taps_counter_c = taps_counter + 1'b1;
            end
            else
                next_state = S0;
        end

        S1: begin
            // Perform MAC operation (more accurate using MULTIPLY_ROUNDING vs. normal *)
            // If taps_counter == 0, it means it overflowed (should be 32 if NUM_TAPS == 32) and this is our last calculation but we need to use 32 for the COEFFICIENTS index instead of 0
            if (taps_counter == 0)
                y_sum_c = $signed(y_sum) + MULTIPLY_ROUNDING(tap_value,COEFFICIENTS[NUM_TAPS-NUM_TAPS]);
            else 
                y_sum_c = $signed(y_sum) + MULTIPLY_ROUNDING(tap_value,COEFFICIENTS[NUM_TAPS-taps_counter]);
            // y_sum_c = $signed(y_sum) + DEQUANTIZE($signed(shift_reg[taps_counter]) * $signed(COEFFICIENTS[NUM_TAPS-taps_counter-1]));
            taps_counter_c = taps_counter + 1'b1;
            tap_value_c = shift_reg[taps_counter];
            // Change state when taps_counter has overflowed or is equal to NUM_TAPS
            if (taps_counter == NUM_TAPS || taps_counter == 0)
                next_state = S2;
            else
                next_state = S1;
        end

        S2: begin
            if (y_out_full == 1'b0) begin
                // Write y_out value to FIFO
                y_out_wr_en = 1'b1;
                y_out_din = y_sum;
                // Reset all the values for the next set of data
                taps_counter_c = '0;
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
            tap_value = 'X;
        end
    endcase
end


endmodule