module fir #(
    parameter NUM_TAPS,
    parameter DECIMATION,
    parameter COEFFICIENTS,
    parameter QUANTIZATION_BITS
) (
    input logic clock,
    input logic reset,
    input logic [QUANTIZATION_BITS-1:0] x_in,  
    output logic in_rd_en,
    output logic out_wr_en,
    output logic [QUANTIZATION_BITS-1:0] y_out
);

typedef enum logic [1:0] {S0, S1, S2} state_types;
state_types state, next_state;

logic [QUANTIZATION_BITS-1:0] shift_reg [0:NUM_TAPS-1];
logic [QUANTIZATION_BITS-1:0] shift_reg_c [0:NUM_TAPS-1];
logic [$clog2(DECIMATION)-1:0] decimation_counter, decimation_counter_c;
logic [$clog2(NUM_TAPS)-1:0] taps_counter, taps_counter_c;
logic [QUANTIZATION_BITS-1:0] y_sum, y_sum_c; 


always_ff @(posedge clk or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        shift_reg <= '{deafult: '{default: 0}};
        decimation_counter <= '0;
        taps_counter <= '0;
        y_sum <= '0;
    end else begin
        state <= next_state;
        shift_reg <= shift_reg_c;
        decimation_counter <= decimation_counter_c;
        taps_counter_c <= taps_counter;
        y_sum_c <= y_sum;
    end
end

always_comb begin
    next_state = state;
    in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    decimation_counter_c = decimation_counter;
    shift_reg_c = shift_reg;
    taps_counter_c = taps_counter;
    y_sum_c = y_sum;

    case(state)

        in_rd_en = 1'b0;
        out_wr_en = 1'b0;

        S0: begin
            // Shift in data into shift register and adjust for decimation (take 1 sample in 10 samples)
            in_rd_en = 1'b1;
            shift_reg_c[1:DECIMATION-1] = shift_reg[0:DECIMATION-2];
            shift_reg_c[0] = x_in;
            decimation_counter_c++;
            if (decimation_counter == DECIMATION - 1) begin
                next_state = S1;
            end else begin
                next_state = S0;
            end
        end

        S1: begin
            // Multiply and accumulate state
            y_sum_c = y_sum + x_in[taps_counter] * COEFFICIENTS[taps_counter];
            taps_counter_c++;
            if (taps_counter == TAPS - 1) begin
                next_state = S2;
            end else begin
                next_state = S1;
            end
        end

        S2: begin
            // Write y_out value to FIFO
            out_wr_en = 1'b1;
            y_out = y_sum;
            // Reset all the values for the next set of data
            taps_counter_c = '0;
            decimation_counter_c = '0;
            y_sum_c = '0;
            next_state = S0;
        end

        default: begin
            next_state = S0;
            in_rd_en = 1'b0;
            out_wr_en = 1'b0;
            y_out = '0;
            decimation_counter_c = 'X;
            taps_counter_c = 'X;
            y_sum_c = 'X;
            shift_reg_c = '{default: '{default : 0}};
        end
    endcase
end


endmodule