`timescale 1ns / 1ps

module sobel5x5_booth #(
    parameter integer APPROX_COLS = 4,
    parameter integer L_COLS      = 4
)(
    input wire [199:0] window_pixels,

    output wire signed [19:0] gx,
    output wire signed [19:0] gy
);

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

    wire signed [19:0] tree_x [1:63];
    wire signed [19:0] tree_y [1:63];

    genvar p;
    generate
        for (p = 0; p < 32; p = p + 1) begin : GEN_TERMS

            if (p < 25) begin : VALID_PIXEL

                localparam integer ROW = p / 5;
                localparam integer COL = p % 5;

                localparam signed [7:0] COEFF_X =
                    smoothing(ROW) * derivative(COL);

                localparam signed [7:0] COEFF_Y =
                    derivative(ROW) * smoothing(COL);

                wire signed [7:0] centered_pixel;
                wire signed [15:0] product_x;
                wire signed [15:0] product_y;

                assign centered_pixel =
                    window_pixels[p*8 +: 8] ^ 8'h80;

                // Operand order matches the Python experiment:
                // a = centered pixel, b = coefficient.
                // Include zero coefficients: do not bypass them.
                booth8_hybrid_csa #(
                    .APPROX_COLS(APPROX_COLS),
                    .L_COLS(L_COLS)
                ) mult_x (
                    .a(centered_pixel),
                    .b(COEFF_X),
                    .product(product_x)
                );

                booth8_hybrid_csa #(
                    .APPROX_COLS(APPROX_COLS),
                    .L_COLS(L_COLS)
                ) mult_y (
                    .a(centered_pixel),
                    .b(COEFF_Y),
                    .product(product_y)
                );

                // Sign-extend before accumulation.
                assign tree_x[32+p] =
                    {{4{product_x[15]}}, product_x};

                assign tree_y[32+p] =
                    {{4{product_y[15]}}, product_y};

            end else begin : ZERO_PADDING

                assign tree_x[32+p] = 20'sd0;
                assign tree_y[32+p] = 20'sd0;

            end
        end
    endgenerate

    // Same balanced addition tree as the shift-add baseline.
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