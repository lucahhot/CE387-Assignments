module matmul
# ( parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter VECTOR_SIZE = 1024,
    parameter MATRIX_SIZE = 8)
(
    input logic clock,
    input logic reset,
    input logic start,
    input logic [DATA_WIDTH-1:0] x_dout,
    input logic [DATA_WIDTH-1:0] y_dout,
    output logic done,
    output logic [ADDR_WIDTH-1:0] x_addr,
    output logic [ADDR_WIDTH-1:0] y_addr,
    output logic [DATA_WIDTH-1:0] z_din,
    output logic [ADDR_WIDTH-1:0] z_addr,
    output logic z_wr_en
);

typedef enum logic [1:0] {S0, S1, S2} state_type;
state_type state, next_state;
logic [ADDR_WIDTH-1:0] i, i_c;
logic done_c;

// Variables to traverse through rows and columns
logic [$clog2(MATRIX_SIZE):0] j, j_c;
logic [$clog2(MATRIX_SIZE)-1:0] row, row_c;
logic [$clog2(MATRIX_SIZE)-1:0] col, col_c;
logic [DATA_WIDTH-1:0] sum, sum_c;
// Temp variables to hold x and y values for 1 clock cycle
logic [DATA_WIDTH-1:0] x_temp, x_temp_c, y_temp, y_temp_c;
// Temp variable to hold store value to pipeline the writing back into BRAM
logic [DATA_WIDTH-1:0] store, store_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        state <= S0;
        done <= 1'b0;
        i <= '0;
        j <= '0;
        row <= '0;
        col <= '0;
        sum <= '0;
        x_temp <= '0;
        y_temp <= '0;
        store <= '0;
    end else begin
        state <= next_state;
        done  <= done_c;
        i <= i_c;
        j <= j_c;
        row <= row_c;
        col <= col_c;
        sum <= sum_c;
        x_temp <= x_temp_c;;
        y_temp <= y_temp_c;
        store <= store_c;
    end
end

always_comb begin
    z_din = 'b0;
    z_wr_en = 'b0;
    z_addr = 'b0;
    x_addr = 'b0;
    y_addr = 'b0;

    next_state = state;
    i_c = i;
    done_c = done;
    j_c = j;
    row_c = row;
    col_c = col;
    sum_c = sum;
    x_temp_c = x_temp;
    y_temp_c = y_temp;
    store_c = store;

    case (state)
        // Start state to initialize multiplication
        S0: begin
            i_c = 0;
            j_c = 0;
            row_c = 0;
            col_c = 0;
            sum_c = 0;
            x_temp_c = 0;
            y_temp_c = 0;
            store_c = 0;
            if (start == 1'b1) begin
                next_state = S1;
                done_c = 1'b0;
            end else begin
                next_state = S0;
            end
        end

        S1: begin
            if ($unsigned(i) < $unsigned(VECTOR_SIZE)) begin
                // Fetch inputs from x_dout and y_dout for the next cycle
                x_temp_c = $signed(x_dout);
                y_temp_c = $signed(y_dout);
                // Calculate MAC with the last cycle's values of x_dout and y_dout
                sum_c = sum + x_temp * y_temp;
                if (j == (MATRIX_SIZE + 1'b1)) begin // When j == 9
                    j_c = 1'b1;
                    z_din = store; // Store sum into z matrix
                    sum_c = '0; // Reset sum_c back to 0
                    z_addr = i;
                    z_wr_en = 1'b1;
                    i_c = i + 1'b1;
                    x_addr = (8*row) + (1'b1);
                    y_addr = (8*(1'b1)) + col;
                end else if(j == (MATRIX_SIZE)) begin // When j == 8
                    // Increment index
                    j_c = j + 1'b1;
                    // Since we've completed 1 full dot product, we can store it into store_c, a temp store register
                    store_c = sum_c;
                    // Need 2 cycles for the BRAM to output the correct addresses to maintain the same addresses as when j == 7
                    if (col == 0) begin
                        x_addr = (8*(row));
                        y_addr = 1'b0;
                    end else begin
                        x_addr = (8*row);
                        y_addr = col;
                    end
                end else begin
                    // Increment index
                    j_c = j + 1'b1;
                    if (j == (MATRIX_SIZE-1)) begin // When j == 7
                        if (col + 1'b1 > (MATRIX_SIZE-1)) begin
                            // We've reached the last column for this row so reset col to 0 and increment row
                            col_c = 1'b0;
                            row_c = row + 1'b1;
                            // Reset addresses
                            x_addr = (8*(row + 1'b1));
                            y_addr = 1'b0;
                        end else begin
                            // There are still columns for this row so only increment col
                            col_c = col + 1'b1;
                            // Reset addresses
                            x_addr = (8*row);
                            y_addr = col + 1'b1;
                        end
                    end else begin // Increment addresses
                        x_addr = (8*row) + (j + 1'b1);
                        y_addr = (8*(j + 1'b1)) + col;
                    end
                end
                next_state = S1;
            end else begin
                done_c = 1'b1;
                next_state = S0;
            end
        end


        default: begin
            z_din = 'x;
            z_wr_en = 'x;
            z_addr = 'x;
            x_addr = 'x;
            y_addr = 'x;
            next_state = S0;
            i_c = 'x;
            j_c = 'x;
            done_c = 1'bx;
            sum_c = 'x;
            row_c = 'x;
            col_c = 'x;
            x_temp_c = 'x;
            y_temp_c = 'x;
            store_c = 'x;
        end

    endcase
end

endmodule