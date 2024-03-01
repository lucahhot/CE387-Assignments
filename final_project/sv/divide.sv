module divide #(
    parameter DATA_SIZE,
    paramteer DATA_SIZE_2,
    parameter BITS
) (
    input   logic                           clock,
    input   logic                           reset,
    input   logic                           start,
    output  logic                           busy,
    output  logic                           fin,
    input   logic signed [DATA_SIZE-1:0]    dividend,
    input   logic signed [DATA_SIZE-1:0]    divisor,
    output  logic signed [DATA_SIZE-1:0]    quotient
);

logic sign;
logic [DATA_SIZE_2-1:0] a, b;
logic [DATA_SIZE_2-1:0] a_c, b_c
logic [DATA_SIZE_2-1:0] q, q_c;
logic [DATA_SIZE_2-1:0] r, r_c;
logic [DATA_SIZE-1:0] x, y;


always_ff @( posedge clock or posedge reset ) begin
    if (reset == 1'b1) begin
        q <= '0;
        r <= '0;
        a <= '0;
        b <= '0;
    end else begin
        q <= q_c;
        r <= r_c;
        a <= a_c;
        b <= b_c;
    end
end

always_comb begin
    q_c = q;
    r_c = r;

    case (state)
        IDLE: begin
            if (start == 1'b1) begin
                next_state = START;
            end else begin
                next_state = IDLE;
            end
        end

        START: begin
            // Get MSB and perform XOR to find the sign
            sign = (dividend >> DATA_SIZE-1) ^ (divisor >> DATA_SIZE-1);
            x = (dividend < 0) -dividend : dividend;
            y = (divisor < 0) -divisor : divisor;

            // quantize inputs? I think we need this, inputs do not seem to be quantized
            a_c = DATA_SIZE_2'(QUANTIZE(x));
            b_c = DATA_SIZE_2'(QUANTIZE(y));

            // adding b/2 to give correct rounding (look at quantization division example slides)
            a_c += b_c >> 1;

            next_state = CALC;
        end

        CALC: begin
            
        end
        
    endcase
end



endmodule