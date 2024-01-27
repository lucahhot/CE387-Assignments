module motion_detect (
    input  logic        clock,
    input  logic        reset,

    output logic        base_rd_en,
    input  logic        base_empty,
    input  logic [23:0] base_dout, // Base input

    output logic        img_in_rd_en,
    input  logic        img_in_empty,
    input  logic [23:0] img_in_dout, // Image input

    output logic        img_out_wr_en,
    input  logic        img_out_full,
    output logic [23:0] img_out_din // Image output
    
);

localparam THRESHOLD = 50;

typedef enum logic [0:0] {S0, S1} state_types;
state_types state, next_state;

logic [7:0] diff; // Difference between grayscaled image and grayscaled background
logic [7:0] base_gray, base_gray_c, image_gray, image_gray_c; // Temporary registers to hold grayscaled pixels
logic [23:0] original, original_c; // To store the original RGB input

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0;
        original <= 24'h0;
        base_gray <= 8'h0;
        image_gray <= 8'h0;
    end else begin
        state <= next_state;
        original <= original_c;
        base_gray <= base_gray_c;
        image_gray <= image_gray_c;
    end
end

always_comb begin

    base_rd_en = 1'b0;
    img_in_rd_en = 1'b0;
    img_out_wr_en = 1'b0;
    img_out_din = 24'h0;
    base_gray_c = base_gray;
    image_gray_c = image_gray;
    original_c = original;

    case (state)

        // Read from the FIFOs 
        S0: begin
            if (base_empty == 1'b0 && img_in_empty == 1'b0) begin
                // Store the original base background image locally
                original_c = img_in_dout;
                // Gray scale both input images
                base_gray_c = 8'(($unsigned({2'b0, base_dout[23:16]}) + $unsigned({2'b0, base_dout[15:8]}) + $unsigned({2'b0, base_dout[7:0]})) / $unsigned(10'd3));
                base_rd_en = 1'b1;
                image_gray_c = 8'(($unsigned({2'b0, img_in_dout[23:16]}) + $unsigned({2'b0, img_in_dout[15:8]}) + $unsigned({2'b0, img_in_dout[7:0]})) / $unsigned(10'd3));
                img_in_rd_en = 1'b1;
                next_state = S1;
            end
        end

        S1: begin
            if (img_out_full == 1'b0) begin
                img_out_wr_en = 1'b1;
                // Finding the difference in gray scale values
                diff = ($unsigned(image_gray) > $unsigned(base_gray)) ? ($unsigned(image_gray) - $unsigned(base_gray)) : ($unsigned(base_gray) - $unsigned(image_gray));
                // If difference is above THRESHOLD, change the pixel to be only red
                if ($unsigned(diff) > THRESHOLD) begin
                    img_out_din[23:16] = 8'h00; 
                    img_out_din[15:8] = 8'h00;
                    img_out_din[7:0] = 8'hFF; // Full red
                end else 
                    // img_out_din is the original base background pixel
                    img_out_din = original;
                next_state = S0;
            end
        end

        default: begin
            next_state = S0;
            original_c = 24'hx;
            base_rd_en = 1'b0;
            img_in_rd_en = 1'b0;
            img_out_wr_en = 1'b0;
            img_out_din = 24'h0;
            base_gray_c = 8'hx;
            image_gray_c = 8'hx;
        end

    endcase

end

endmodule