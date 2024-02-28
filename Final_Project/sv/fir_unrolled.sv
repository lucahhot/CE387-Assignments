module fir #(
    parameter NUM_TAPS = 32,
    parameter DECIMATION = 10,
    parameter QUANTIZATION_BITS = 32
) (
    input logic clock,
    input logic reset,
    input logic [QUANTIZATION_BITS-1:0] x_in_dout,   // Quantized input 
    input logic x_in_empty,
    output logic x_in_rd_en,
    output logic y_out_wr_en,
    input logic y_out_full,
    output logic [QUANTIZATION_BITS-1:0] y_out_din  // Quantized output
);

// Test 32-bit paramater values
parameter logic signed [QUANTIZATION_BITS-1:0] [0:NUM_TAPS-1] COEFFICIENTS = '{
    'hfffffffd, 'hfffffffa, 'hfffffff4, 'hffffffed, 'hffffffe5, 'hffffffdf, 'hffffffe2, 'hfffffff3, 
    'h00000015, 'h0000004e, 'h0000009b, 'h000000f9, 'h0000015d, 'h000001be, 'h0000020e, 'h00000243, 
    'h00000243, 'h0000020e, 'h000001be, 'h0000015d, 'h000000f9, 'h0000009b, 'h0000004e, 'h00000015, 
    'hfffffff3, 'hffffffe2, 'hffffffdf, 'hffffffe5, 'hffffffed, 'hfffffff4, 'hfffffffa, 'hfffffffd
};

typedef enum logic [1:0] {S0, S1, S2, S3} state_types;
state_types state, next_state;

logic [QUANTIZATION_BITS-1:0] [0:NUM_TAPS-1] shift_reg;
logic [QUANTIZATION_BITS-1:0] [0:NUM_TAPS-1] shift_reg_c;
logic [$clog2(DECIMATION)-1:0] decimation_counter, decimation_counter_c;
logic [$clog2(NUM_TAPS)-1:0] taps_counter, taps_counter_c;
logic [QUANTIZATION_BITS-1:0] y_sum, y_sum_c; 

// Register to hold all the products of x_in and coefficients so they can be calculated in parallel
logic [QUANTIZATION_BITS-1:0] [0:NUM_TAPS-1] products ;
logic [QUANTIZATION_BITS-1:0] [0:NUM_TAPS-1] products_c ;


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        shift_reg <= '{default: '{default: 0}};
        decimation_counter <= '0;
        taps_counter <= '0;
        y_sum <= '0;
        products <= '{default: '{default: 0}};
    end else begin
        state <= next_state;
        shift_reg <= shift_reg_c;
        decimation_counter <= decimation_counter_c;
        taps_counter <= taps_counter_c;
        y_sum <= y_sum_c;
        products <= products_c;
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
    products_c = products;

    case(state)

        S0: begin
            x_in_rd_en = 1'b0;
            y_out_wr_en = 1'b0;
            if (x_in_empty == 1'b0) begin
                // Shift in data into shift register and adjust for decimation (take 1 sample in 10 samples)
                x_in_rd_en = 1'b1;
                shift_reg_c[NUM_TAPS-1:1] = shift_reg[NUM_TAPS-2:0];
                shift_reg_c[0] = x_in_dout;
                decimation_counter_c++;
            end
            if (decimation_counter == DECIMATION - 1) begin
                next_state = S1;
            end else begin
                next_state = S0;
            end
        end

        S1: begin
            x_in_rd_en = 1'b0;
            y_out_wr_en = 1'b0;
            // Multiply in parallel
            for (int i = 0; i < NUM_TAPS; i++)
                products_c[i] = shift_reg[i] * COEFFICIENTS[i];
            next_state = S2;
        end

        S2: begin
            x_in_rd_en = 1'b0;
            y_out_wr_en = 1'b0;
            // Accumulate state
            for (int i = 0; i < NUM_TAPS; i++)
                y_sum_c = y_sum + products[i];
            next_state = S3;
        end

        S3: begin
            x_in_rd_en = 1'b0;
            y_out_wr_en = 1'b0;
            if (y_out_full == 1'b0) begin
                // Write y_out value to FIFO
                y_out_wr_en = 1'b1;
                y_out_din = y_sum;
                // Reset all the values for the next set of data
                taps_counter_c = '0;
                decimation_counter_c = '0;
                y_sum_c = '0;
                products_c = '{default: '{default : 0}};
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
            shift_reg_c = '{default: '{default : 0}};
            products_c = '{default: '{default : 0}};
        end
    endcase
end


endmodule