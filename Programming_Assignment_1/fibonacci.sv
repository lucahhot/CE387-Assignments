module fibonacci(
    input logic clk, 
    input logic reset,
    input logic [15:0] din,
    input logic start,
    output logic [15:0] dout,
    output logic done );

    // TODO: Add local logic signals
    enum logic [1:0] {S0, S1, S2} state, next_state;
    logic done_c;
    logic [15:0] counter, counter_c;
    logic [15:0] first_num, first_num_c;
    logic [15:0] second_num, second_num_c;
    logic [15:0] sum, sum_c;

    always_ff @(posedge clk, posedge reset) begin
        if ( reset == 1'b1 ) begin
            state <= S0;
            done <= 1'b0;
            counter <= 1'b0;
            first_num <= 1'b0;
            second_num <= 1'b0;
            sum <= 1'b0;
        end else begin
            state <= next_state;
            done <= done_c;
            dout <= sum;
            counter <= counter_c;
            first_num <= first_num_c;
            second_num <= second_num_c;
            sum <= sum_c;
        end
    end

    always_comb begin
        next_state = state;
        done_c = done;
        counter_c = counter;
        first_num_c = first_num;
        second_num_c = second_num;
        sum_c = sum;
        case (state)
            S0: begin
                next_state = (start) ? S1 : S0;
                done_c = 1'b0;
                counter_c = 16'd1;
                first_num_c = 16'd0;
                second_num_c = 16'd1;
                sum_c = 16'd0;
            end
            S1: begin
                if (counter == din) 
                    next_state = S2;
                else  begin
                    sum_c = first_num + second_num;
                    first_num_c = second_num;
                    second_num_c = first_num + second_num;
                    counter_c = counter + 1'b1;
                end            
            end
            S2: begin
                done_c = 1'b1;
                next_state = S0;
            end
            default:
                next_state = S0;
        endcase
    end
endmodule
