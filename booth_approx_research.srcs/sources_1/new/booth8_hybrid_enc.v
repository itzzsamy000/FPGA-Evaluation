module booth8_hybrid_enc #(
    parameter integer APPROX_COLS = 6,
    parameter integer L_COLS      = 0
)(
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    output wire signed [15:0] product
);

    // Valid configuration:
    // 0 <= L_COLS <= APPROX_COLS <= 16
    //
    // H columns = 16 - APPROX_COLS
    // M columns = APPROX_COLS - L_COLS
    // L columns = L_COLS

    wire [15:0] a_ext;
    wire [8:0]  booth_bits;

    wire [15:0] raw_pp       [0:3];
    wire [15:0] corrected_pp [0:3];
    wire [15:0] shifted_pp   [0:3];

    assign a_ext      = {{8{a[7]}}, a};
    assign booth_bits = {b, 1'b0};

    genvar row, col;

    generate
        for (row = 0; row < 4; row = row + 1) begin : GEN_ROW

            wire [2:0] code;
            assign code = booth_bits[2*row +: 3];

            for (col = 0; col < 16; col = col + 1) begin : GEN_COL

                // Global product-weight column = col + 2*row.
                // Select the encoder using that global column.

                if ((col + 2*row) < L_COLS) begin : REGION_L

                    ar4be2 enc (
                        .a_j        (a_ext[col]),
                        .booth_code (code),
                        .pp         (raw_pp[row][col])
                    );

                end else if ((col + 2*row) < APPROX_COLS) begin : REGION_M

                    ar4be1 enc (
                        .a_j        (a_ext[col]),
                        .booth_code (code),
                        .pp         (raw_pp[row][col])
                    );

                end else begin : REGION_H

                    if (col == 0) begin : FIRST_BIT

                        booth_exact_bit enc (
                            .a_j        (a_ext[col]),
                            .a_prev     (1'b0),
                            .booth_code (code),
                            .pp         (raw_pp[row][col])
                        );

                    end else begin : OTHER_BITS

                        booth_exact_bit enc (
                            .a_j        (a_ext[col]),
                            .a_prev     (a_ext[col-1]),
                            .booth_code (code),
                            .pp         (raw_pp[row][col])
                        );

                    end
                end
            end

            // Exact two's-complement correction.
            assign corrected_pp[row] =
                raw_pp[row] + {15'b0, code[2]};

            assign shifted_pp[row] =
                corrected_pp[row] << (2*row);

        end
    endgenerate

    // Exact accumulation of approximate partial products.
    assign product =
        shifted_pp[0] +
        shifted_pp[1] +
        shifted_pp[2] +
        shifted_pp[3];

endmodule