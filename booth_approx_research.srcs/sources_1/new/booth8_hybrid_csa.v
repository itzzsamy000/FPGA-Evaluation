module booth8_hybrid_csa #(
    parameter integer APPROX_COLS = 6,
    parameter integer L_COLS      = 6
)(
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    output wire signed [15:0] product
);

    // Valid parameters:
    // 0 <= L_COLS <= APPROX_COLS <= 16

    wire [15:0] a_ext;
    wire [8:0]  booth_bits;

    wire [15:0] raw_pp [0:3];
    wire [15:0] weighted_pp [0:3];

    wire [15:0] correction;

    wire [15:0] sum1, carry1;
    wire [15:0] sum2, carry2;
    wire [15:0] sum3, carry3;

    assign a_ext      = {{8{a[7]}}, a};
    assign booth_bits = {b, 1'b0};

    genvar row, col;

    generate
        for (row = 0; row < 4; row = row + 1) begin : GEN_ROW

            wire [2:0] code;
            assign code = booth_bits[2*row +: 3];

            for (col = 0; col < 16; col = col + 1) begin : GEN_COL

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

            // Shift raw rows without separate row additions.
            assign weighted_pp[row] = raw_pp[row] << (2*row);

        end
    endgenerate

    // Four +1 correction bits at weights 0, 2, 4, 6.
    // Booth sign bits are b[1], b[3], b[5], b[7].
    assign correction = {
        9'b0,
        b[7], 1'b0,
        b[5], 1'b0,
        b[3], 1'b0,
        b[1]
    };

    // CSA stage 1: three partial-product rows.
    assign sum1 =
        weighted_pp[0] ^
        weighted_pp[1] ^
        weighted_pp[2];

    assign carry1 = (
        (weighted_pp[0] & weighted_pp[1]) |
        (weighted_pp[0] & weighted_pp[2]) |
        (weighted_pp[1] & weighted_pp[2])
    ) << 1;

    // CSA stage 2: first sum, fourth row, corrections.
    assign sum2 =
        sum1 ^ weighted_pp[3] ^ correction;

    assign carry2 = (
        (sum1 & weighted_pp[3]) |
        (sum1 & correction) |
        (weighted_pp[3] & correction)
    ) << 1;

    // CSA stage 3: reduce the remaining three vectors.
    assign sum3 = carry1 ^ sum2 ^ carry2;

    assign carry3 = (
        (carry1 & sum2) |
        (carry1 & carry2) |
        (sum2 & carry2)
    ) << 1;

    // Final carry-propagate addition.
    // Arithmetic is modulo 2^16, matching the original design.
    assign product = sum3 + carry3;

endmodule