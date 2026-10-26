`timescale 1ns / 1ps

module tb_booth8_cell_exact;

    reg  signed [7:0]  a;
    reg  signed [7:0]  b;
    wire signed [15:0] product;

    reg signed [15:0] expected;

    integer i, j;
    integer tests;
    integer errors;

    booth8_cell_exact dut (
        .a       (a),
        .b       (b),
        .product (product)
    );

    initial begin
        a        = 0;
        b        = 0;
        expected = 0;
        tests    = 0;
        errors   = 0;

        for (i = -128; i <= 127; i = i + 1) begin
            for (j = -128; j <= 127; j = j + 1) begin

                a = i;
                b = j;

                // Independent arithmetic reference.
                expected = i * j;

                #1;

                tests = tests + 1;

                if (product !== expected) begin
                    errors = errors + 1;

                    // Limit console output if many errors occur.
                    if (errors <= 10) begin
                        $display(
                            "FAIL: a=%0d b=%0d got=%0d expected=%0d",
                            a, b, product, expected
                        );
                    end
                end
            end
        end

        if (errors == 0) begin
            $display(
                "PASS: All 65,536 cell-based signed products matched."
            );
        end else begin
            $display(
                "FAIL: %0d mismatches out of %0d tests.",
                errors, tests
            );
        end

        $finish;
    end

endmodule