`timescale 1ns / 1ps

module sobel5x5_exact_shiftadd (
    // 25 unsigned grayscale pixels, 8 bits each.
    // Pixel 0: window_pixels[7:0]
    // Pixel 1: window_pixels[15:8], and so on.
    // Pixels are arranged row by row.
    input wire [199:0] window_pixels,

    output wire signed [19:0] gx,
    output wire signed [19:0] gy
);

    // Smoothing vector: [1, 4, 6, 4, 1]
    function integer smoothing;
        input integer index;
        begin
            case (index)
                0, 4: smoothing = 1;
                1, 3: smoothing = 4;
                2:    smoothing = 6;
                default: smoothing = 0;
            endcase
        end
    endfunction

    // Derivative vector: [-1, -2, 0, 2, 1]
    function integer derivative;
        input integer index;
        begin
            case (index)
                0: derivative = -1;
                1: derivative = -2;
                2: derivative = 0;
                3: derivative = 2;
                4: derivative = 1;
                default: derivative = 0;
            endcase
        end
    endfunction

    // Exact constant multiplication using shifts and additions.
    function signed [19:0] multiply_constant;
        input signed [7:0] pixel;
        input integer coefficient;

        reg signed [19:0] extended_pixel;
        reg signed [19:0] value;
        integer magnitude;

        begin
            // Extend BEFORE shifting to avoid 8-bit overflow.
            extended_pixel = {{12{pixel[7]}}, pixel};

            if (coefficient < 0)
                magnitude = -coefficient;
            else
                magnitude = coefficient;

            case (magnitude)
                0:  value = 20'sd0;
                1:  value = extended_pixel;
                2:  value = extended_pixel <<< 1;
                4:  value = extended_pixel <<< 2;

                6:  value = (extended_pixel <<< 2)
                          + (extended_pixel <<< 1);

                8:  value = extended_pixel <<< 3;

                12: value = (extended_pixel <<< 3)
                          + (extended_pixel <<< 2);

                default: value = 20'sd0;
            endcase

            if (coefficient < 0)
                multiply_constant = -value;
            else
                multiply_constant = value;
        end
    endfunction

    // Balanced addition trees:
    // Leaves: indices 32..63; root: index 1.
    wire signed [19:0] tree_x [1:63];
    wire signed [19:0] tree_y [1:63];

    genvar p;
    generate
        for (p = 0; p < 32; p = p + 1) begin : GEN_TERMS

            if (p < 25) begin : VALID_PIXEL

                localparam integer ROW = p / 5;
                localparam integer COL = p % 5;

                // These are elaboration-time constants.
                localparam integer COEFF_X =
                    smoothing(ROW) * derivative(COL);

                localparam integer COEFF_Y =
                    derivative(ROW) * smoothing(COL);

                wire signed [7:0] centered_pixel;

                // Unsigned pixel minus 128, represented as signed.
                assign centered_pixel =
                    window_pixels[p*8 +: 8] ^ 8'h80;

                assign tree_x[32+p] =
                    multiply_constant(centered_pixel, COEFF_X);

                assign tree_y[32+p] =
                    multiply_constant(centered_pixel, COEFF_Y);

            end else begin : ZERO_PADDING

                assign tree_x[32+p] = 20'sd0;
                assign tree_y[32+p] = 20'sd0;

            end
        end
    endgenerate

    genvar n;
    generate
        for (n = 1; n < 32; n = n + 1) begin : GEN_ADDERS
            assign tree_x[n] =
                tree_x[2*n] + tree_x[2*n+1];

            assign tree_y[n] =
                tree_y[2*n] + tree_y[2*n+1];
        end
    endgenerate

    assign gx = tree_x[1];
    assign gy = tree_y[1];

endmodule