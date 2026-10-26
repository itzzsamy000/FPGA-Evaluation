module booth8_cell_exact (
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    output wire signed [15:0] product
);

    wire [15:0] a_ext;
    wire [8:0]  booth_bits;

    wire [15:0] raw_pp [0:3];
    wire [15:0] corrected_pp [0:3];
    wire [15:0] shifted_pp [0:3];

    // Extend A before generating A or 2A.
    assign a_ext = {{8{a[7]}}, a};

    // Append b(-1) = 0.
    assign booth_bits = {b, 1'b0};

    genvar row, col;

    generate
        for (row = 0; row < 4; row = row + 1) begin : GEN_ROW

            wire [2:0] code;

            assign code = booth_bits[2*row +: 3];

            for (col = 0; col < 16; col = col + 1) begin : GEN_COL

                if (col == 0) begin : LOWEST_BIT

                    booth_exact_bit cell_inst (
                        .a_j        (a_ext[col]),
                        .a_prev     (1'b0),
                        .booth_code (code),
                        .pp         (raw_pp[row][col])
                    );

                end else begin : OTHER_BITS

                    booth_exact_bit cell_inst (
                        .a_j        (a_ext[col]),
                        .a_prev     (a_ext[col-1]),
                        .booth_code (code),
                        .pp         (raw_pp[row][col])
                    );

                end
            end

            // Inverted negative rows need +1.
            // Code 111: 16'hFFFF + 1 wraps to zero.
            assign corrected_pp[row] =
                raw_pp[row] + {15'b0, code[2]};

            // Weight each Booth row by 2^(2*row).
            assign shifted_pp[row] =
                corrected_pp[row] << (2*row);

        end
    endgenerate

    // Fixed-width arithmetic retains the exact 16-bit product.
    assign product =
        shifted_pp[0] +
        shifted_pp[1] +
        shifted_pp[2] +
        shifted_pp[3];

endmodule