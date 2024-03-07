`include "globals.sv"

module divide #(
    parameter DATA_SIZE,
    parameter DATA_SIZE_2,
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
logic [DATA_SIZE_2:0] a, a_c;
logic [DATA_SIZE_2-1:0] b, b_c;
logic [DATA_SIZE-1:0] x, y;
logic [DATA_SIZE_2-1:0] quotient_temp;      // need to reduce size of quotient_temp before outputting to quotient

logic [DATA_SIZE_2:0] [0:DATA_SIZE_2-1] dinl_temp;
logic [DATA_SIZE_2-1:0] [0:DATA_SIZE_2-1] dinr_temp;
logic [DATA_SIZE_2-1:0] [0:DATA_SIZE_2-1] dout_temp;

logic [6:0] count;

typedef enum logic[1:0] {IDLE, START, CALC, OUTPUT} state_types;
state_types state, next_state;


always_ff @( posedge clock or posedge reset ) begin
    if (reset == 1'b1) begin
        a <= '0;
        b <= '0;
    end else begin
        a <= a_c;
        b <= b_c;
    end
end

always_comb begin
    a_c = a;
    b_c = b;
    busy = 1'b0;
    fin = 1'b0;
    count = '0;

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
            x = (dividend < 0) ? -dividend : dividend;
            y = (divisor < 0) ?  -divisor : divisor;

            // quantize inputs? I think we need this, inputs do not seem to be quantized
            a_c = (DATA_SIZE_2+1)'(QUANTIZE(x));
            b_c = DATA_SIZE_2'(QUANTIZE(y));

            // adding b/2 to give correct rounding (look at quantization division example slides)
            a_c += b_c >> 1;

            next_state = CALC;

            busy = 1'b1;
            fin = 1'b0;
        end

        CALC: begin
            while (count < DATA_SIZE_2) begin
                if (count == DATA_SIZE_2-1) begin
                    dinl_temp[count] = {{1'b0}, a[count]};
                    dinr_temp[count] = b;           // dividend width and divisor width is the same (one bit added to dividend)
                end else if (count > 0 && count < DATA_SIZE_2-1) begin
                    dinl_temp[count] = dout_temp[count+1] & b[count];
                    dinr_temp[count] = b;
                end else if (count == 0) begin
                    dinl_temp[count] = dout_temp[count+1] & b[count];
                    dinr_temp[count] = b;
                end
                count++;
            end

            next_state = OUTPUT;
            busy = 1'b1;
            fin = 1'b0;
        end

        OUTPUT: begin
            quotient = (sign == 1'b1) ? -quotient_temp[DATA_SIZE-1:0] : quotient_temp[DATA_SIZE-1:0];
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
            count = '0;
            dinl_temp = '{default: '{default: 0}};
            dinr_temp = '{default: '{default: 0}};
            dout_temp = '{default: '{default: 0}};
        end
        
    endcase
end

genvar i;
    generate
        for (i = 0; i < DATA_SIZE_2; i++) begin
            comparator #(
                .DATA_SIZE_2(DATA_SIZE_2)
            ) comparator_inst (
                .dinr(dinr_temp[i]),
                .dinl(dinl_temp[i]),
                .d_out(dout_temp[i]),
                .isGreaterEq(quotient_temp[i])
            );
        end
    endgenerate



endmodule