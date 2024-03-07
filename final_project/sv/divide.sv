module divide #(
    parameter DATA_SIZE = 32,
    parameter DATA_SIZE_2 = 64,
    parameter BITS = 10
) (
    input   logic                   clock,
    input   logic                   reset,
    input   logic                   start,
    output  logic                   busy,
    output  logic                   done,
    input   logic [DATA_SIZE-1:0]   dividend,
    input   logic [DATA_SIZE-1:0]   divisor,
    output  logic [DATA_SIZE-1:0]   d_out
);

logic [DATA_SIZE-1:0] au;
logic [DATA_SIZE_2-1:0] au_quant;
logic [DATA_SIZE-1:0] bu;
logic [DATA_SIZE_2-1:0] bu_sub;
logic [DATA_SIZE_2:0] acc, acc_next;
logic [DATA_SIZE_2-1:0] quo, quo_next;
logic [$clog2(DATA_SIZE_2):0] count, count_c;
logic sign;

localparam ITER = DATA_SIZE_2;

typedef enum logic[1:0] {IDLE, INIT, CALC, OUT} state_types;
state_types state, next_state;

always_ff @( posedge clock or posedge reset ) begin 
    if (reset == 1'b1) begin
        acc <= '0;
        quo <= '0;
        count <= '0;
        state <= IDLE;
    end else begin
        acc <= acc_next;
        quo <= quo_next;
        count <= count_c;
        state <= next_state;
    end
    
end

always_comb begin
    acc_next = acc;
    quo_next = quo;
    count_c = count;

    case(state) 
        IDLE: begin
            if (start == 1'b1) begin
                next_state = INIT;
            end else begin
                next_state = IDLE;
            end

            busy = 1'b0;
            done = 1'b0;
        end

        INIT: begin
            sign = dividend[DATA_SIZE-1] ^ divisor[DATA_SIZE-1];
            au = (dividend[DATA_SIZE-1] == 1'b1) ? -dividend : dividend;    // getting unsigned value, au gets shifted before input? check c code
            bu = (divisor[DATA_SIZE-1] == 1'b1) ? -divisor : divisor;
            bu_sub = {{DATA_SIZE{1'b0}}, bu};
            au_quant = {{DATA_SIZE{1'b0}}, au};    // quantize au
            au_quant = au_quant << BITS;
            au_quant += bu >> 1;            // for rounding
            busy = 1'b1;
            done = 1'b0;
            next_state = CALC;
            count_c = 0;
            {acc_next, quo_next} = {{DATA_SIZE_2{1'b0}}, au_quant, 1'b0};
        end

        CALC: begin
            if (count == ITER - 1) begin
                next_state = OUT;
            end else begin
                next_state = CALC;
            end

            if (acc >= {1'b0, bu}) begin
                acc_next = acc - bu_sub;
                {acc_next, quo_next} = {acc_next[DATA_SIZE_2-1:0], quo, 1'b1};
            end else begin
                {acc_next, quo_next} = {acc, quo} << 1;
            end

            count_c++;
        end 

        OUT: begin
            busy = 1'b0;
            done = 1'b1;
            next_state = IDLE;
            d_out = (sign == 1'b1) ? -quo[DATA_SIZE-1:0] : quo[DATA_SIZE-1:0];
            count_c = '0;
        end

        default: begin
            acc_next = '0;
            d_out = '0;
            quo_next = '0;
            count_c = '0;
            busy = 1'b0;
            done = 1'b0;
            next_state = IDLE;
        end
    endcase
end



endmodule