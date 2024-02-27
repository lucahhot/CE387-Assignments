module fir #(
    parameter TAPS,
    parameter DECIMATION,
    parameter COEFFICIENT,
    parameter BITS
) (
    input logic clock,
    input logic reset,
    input logic [19:0] x_in,   // 20 bit data element, need to multiply (qunatization)
    output logic in_rd_en,
    output logic out_wr_en,
    output logic [19:0] y_out
);

// have a counter from 0 to decimation - 1, 
// shift register to store values

typedef enum logic [1:0] {S0, S1, S2} state_types;
state_types state, next_state;

parameter QUANT_LEN = BITS * 2;
parameter COUNTER_LEN = $clog2(DECIMATION);
parameter TAPS_LEN = $clog2(TAPS);


logic [QUANT_LEN - 1:0] shift_reg [0 : DECIMATION - 1];
logic [QUANT_LEN - 1:0] shift_reg_c [0 : DECIMATION - 1];
logic [COUNTER_LEN - 1:0] counter, counter_c;
logic [TAPS_LEN - 1:0] taps_counter, taps_counter_c;


always_ff @(posedge clk or posedge reset) begin
    if (reset == 1'b1) begin
        shift_reg <= '{deafult: '{default: 0}};
        state <= S0;    
        counter <= '0;
        taps_counter <= '0;

    end else begin
        shift_reg <= shift_reg_c;
        state <= next_state;
        counter <= counter_c;
        taps_counter_c <= taps_counter;
    end
end

always_comb begin
    next_state = state;
    in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    counter_c = counter;
    shift_reg_c = shift_reg;
    taps_counter_c = taps_counter;

    case(state)
        S0: begin
            // shifting then reading in data, counting until counter == decimation - 1
            in_rd_en = 1'b1;
            out_wr_en = 1'b0;
            shift_reg_c[1 : DECIMATION - 1] = shift_reg[0 : DECIMATION - 2];
            shift_reg_c[0] = x_in;
            counter_c++;
            if (counter == DECIMATION - 1) begin
                next_state = S1;
            end else begin
                next_state = S0;
            end
        end

        S1: begin
            // multiplying stage
            in_rd_en = 1'b0;
            out_wr_en = 1'b0;
            y_out += x_in[taps_counter] * COEFFICIENT[taps_counter];
            taps_counter_c++;
            if (taps_counter == TAPS - 1) begin
                next_state = S2;
            end else begin
                next_state = S1;
            end
        end

        S2: begin
            out_wr_en = 1'b1;
            shift_reg_c = '{default: '{default: 0}};
            taps_counter_c = '0;
            counter_c = '0;
            next_state = S0;
        end

        default: begin
            next_state = S0;
            in_rd_en = 1'b0;
            out_wr_en = 1'b0;
            y_out = '0;
            counter_c = 'X;
            taps_counter_c = 'X;
            shift_reg_c = '{default: '{default : 0}};
        end
    endcase
end


endmodule