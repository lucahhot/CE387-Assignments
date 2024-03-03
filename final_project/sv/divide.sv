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
logic [DATA_SIZE_2-1:0] quotient_temp;      // need to reduce size of quotient_temp before outputting to quotient

logic [DATA_SIZE_2:0] [DATA_SIZE_2-1:0] dinl_temp;
logic [DATA_SIZE_2-1:0] [DATA_SIZE_2-1:0] dinr_temp;
logic [DATA_SIZE_2-1:0] [DATA_SIZE_2-1:0] dout_temp;

typedef enum logic[1:0] {IDLE, START, CALC, OUTPUT} state_types;
state_types state, next_state;


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
    a_c = a;
    b_c = b;
    busy = 1'b0;
    fin = 1'b0;

    case (state)
        IDLE: begin
            if (start == 1'b1) begin
                next_state = START;
            end else begin
                next_state = IDLE;
            end

            busy = 1'b0;
            fin = 1'b0;
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

            busy = 1'b1;
            fin = 1'b0;
        end

        CALC: begin
            for (i = 0; i < DATA_SIZE_2; i++) begin
                if (i == DATA_SIZE_2-1) begin
                    dinl_temp[i] = {{DATA_SIZE_2-i{1'b0}}, a[i]};
                    dinr_temp[i] = b;           // dividend width and divisor width is the same (one bit added to dividend)
                end else if (i > 0 && i < DATA_SIZE_2-1) begin
                    dinl_temp[i] = dout_temp[i+1] & b[i];
                    dinr_temp[i] = b;
                end else if (i == 0) begin
                    dinl_temp[i] = dout_temp[i+1] & b[i];
                    dinr_temp[i] = b;
                end
            end

            next_state = OUTPUT;
            busy = 1'b1;
            fin = 1'b0;
        end

        OUTPUT: begin
            quotient = (sign == 1'b1) ? -[DATA_SIZE-1:0]quotient_temp : [DATA_SIZE-1:0]quotient_temp;
            next_state = IDLE;

            busy = 1'b0;
            fin = 1'b1;
        end

        default: begin
            busy = 1'b0;
            fin = 1'b0;
            a_c = '0;
            b_c = '0;
            x = '0;
            y = '0;
            dinl_temp = '{default: '{default: 0}};
            dinr_temp = '{default: '{default: 0}};
            dout_temp = '{default: '{default: 0}};
        end
        
    endcase
end

genvar i;
    generate
        comparator #(
            .DATA_SIZE_2(DATA_SIZE_2)
        ) comparator_inst (
            .divisor(dinr_temp[i]),
            .dividend(dinl_temp[i]),
            .d_out(dout_temp[i]),
            .isGreaterEq(quotient_temp[i])
        );
    endgenerate



endmodule