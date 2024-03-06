module div #(
    parameter DIVIDEND_WIDTH = 64,
    parameter DIVISOR_WIDTH = 32
) (
    input  logic                        clk,
    input  logic                        reset,
    input  logic                        valid_in,
    input  logic [DIVIDEND_WIDTH-1:0]   dividend,
    input  logic [DIVISOR_WIDTH-1:0]    divisor,
    output logic [DIVIDEND_WIDTH-1:0]   quotient,
    output logic [DIVISOR_WIDTH-1:0]    remainder,
    output logic                        valid_out,
    output logic                        overflow
);

    // Define the state machine states
    typedef enum logic [2:0] {
        INIT, IDLE, B_EQ_1, LOOP, EPILOGUE, DONE
    } state_t;
    state_t state, state_c;

    // Define internal signals
    logic [DIVIDEND_WIDTH-1:0] a, a_c;
    logic [DIVISOR_WIDTH-1:0] b, b_c;
    logic [DIVIDEND_WIDTH-1:0] q, q_c;
    logic internal_sign;
    integer p;
    integer a_minus_b;
    integer remainder_condition;

    // State machine and calculation logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            state <= IDLE;
            a <= '0;
            b <= '0;
            q <= '0;
        end else begin
            state <= state_c;
            a <= a_c;
            b <= b_c;
            q <= q_c;
        end
    end

    // Calculate the most significant bit position of a non-negative number
    function automatic int get_msb_pos(logic [DIVIDEND_WIDTH-1:0] num);
        int pos;
        for (pos = DIVIDEND_WIDTH-1; pos >= 0; pos--) begin
            if (num[pos] == 1'b1) begin
                return pos;
            end
        end
        return -1; // Return -1 if the number is zero
    endfunction

    always_comb begin
        b_c = b;
        q_c = q;
        valid_out = '0;
        state_c = state; // Default next state is the current state

        case (state)
            IDLE: begin
                if (valid_in == 1'b1) begin
                    state_c = INIT;
                end
            end

            INIT: begin
                overflow = 1'b0;
                a_c = (dividend[DIVIDEND_WIDTH-1] == 1'b0) ? dividend : -dividend;
                b_c = (divisor[DIVISOR_WIDTH-1] == 1'b0) ? divisor : -divisor;
                q_c = '0;
                p = 0;

                if (divisor == 1) begin
                    state_c = B_EQ_1;
                end else if (divisor == 0) begin
                    overflow = 1'b1;
                    state_c = B_EQ_1;
                end else begin
                    state_c = LOOP;
                end
            end

            B_EQ_1: begin
                q_c = dividend;
                a_c = '0;
                b_c = b;
                state_c = EPILOGUE;
            end

            LOOP: begin
                p = get_msb_pos(a) - get_msb_pos(b);
                if ((b << p) > a) begin
                    p = p - 1;
                end

                q_c = q + (1 << p);

                if ((b != '0) && (b <= a)) begin
                    a_minus_b = a - (b << p);
                    a_c = a_minus_b;
                end else begin
                    state_c = EPILOGUE;
                end
            end

            EPILOGUE: begin
                internal_sign = dividend[DIVIDEND_WIDTH-1] ^ divisor[DIVISOR_WIDTH-1];
                quotient = (internal_sign == 1'b0) ? q : -q;
                remainder_condition = dividend[DIVIDEND_WIDTH-1];
                remainder = (remainder_condition == 1'b0) ? a : -a;
                valid_out = 1'b1;
                state_c = IDLE;
            end

            default: begin
                state_c = IDLE;
            end
        endcase
    end

endmodule
