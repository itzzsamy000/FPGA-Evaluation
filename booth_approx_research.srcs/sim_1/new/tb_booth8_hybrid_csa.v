`timescale 1ns / 1ps

module tb_booth8_hybrid_csa;

    // H12/M0/L4 configuration
    localparam integer APPROX_COLS = 4;
    localparam integer L_COLS      = 4;

    reg signed [7:0] a, b;

    wire signed [15:0] original_exact;
    wire signed [15:0] csa_exact;
    wire signed [15:0] original_approx;
    wire signed [15:0] csa_approx;

    reg signed [15:0] expected;

    integer i, j;
    integer tests;
    integer csv_file;
    integer errors_exact;
    integer errors_equivalence;
    integer unknown_outputs;

    integer inexact_products;
    integer error_value;
    integer absolute_error;
    integer maximum_error;

    real sum_absolute_error;
    real sum_signed_error;

    // Exact encoder architecture
    booth8_hybrid_enc #(
        .APPROX_COLS(0),
        .L_COLS(0)
    ) ref_exact (
        .a(a),
        .b(b),
        .product(original_exact)
    );

    // Exact CSA architecture
    booth8_hybrid_csa #(
        .APPROX_COLS(0),
        .L_COLS(0)
    ) dut_exact (
        .a(a),
        .b(b),
        .product(csa_exact)
    );

    // Approximate encoder architecture: H12/M0/L4
    booth8_hybrid_enc #(
        .APPROX_COLS(APPROX_COLS),
        .L_COLS(L_COLS)
    ) ref_approx (
        .a(a),
        .b(b),
        .product(original_approx)
    );

    // Approximate CSA architecture: H12/M0/L4
    booth8_hybrid_csa #(
        .APPROX_COLS(APPROX_COLS),
        .L_COLS(L_COLS)
    ) dut_approx (
        .a(a),
        .b(b),
        .product(csa_approx)
    );

    initial begin
        a = 0;
        b = 0;
        expected = 0;

        tests              = 0;
        errors_exact       = 0;
        errors_equivalence = 0;
        unknown_outputs    = 0;
        inexact_products   = 0;
        maximum_error      = 0;
        sum_absolute_error = 0.0;
        sum_signed_error   = 0.0;

        // This folder must already exist.
        csv_file = $fopen(
            "C:/Users/Satish/booth_approx_research/results/python_model/rtl_products_H12_M0_L4.csv",
            "w"
        );

        if (csv_file == 0) begin
            $display("FAIL: Could not open CSV file.");
            $display("Check that results/python_model exists.");
            $finish;
        end

        $fdisplay(
            csv_file,
            "a,b,exact_product,approximate_product"
        );

        for (i = -128; i <= 127; i = i + 1) begin
            for (j = -128; j <= 127; j = j + 1) begin
                a = i;
                b = j;
                expected = i * j;

                #1;
                tests = tests + 1;

                // Exact circuits must match mathematical multiplication.
                if ((original_exact !== expected) ||
                    (csa_exact !== expected)) begin
                    errors_exact = errors_exact + 1;

                    if (errors_exact <= 5)
                        $display(
                            "EXACT FAIL: a=%0d b=%0d encoder=%0d CSA=%0d expected=%0d",
                            a, b, original_exact, csa_exact, expected
                        );
                end

                // CSA must preserve the approximate encoder output.
                if (csa_approx !== original_approx) begin
                    errors_equivalence = errors_equivalence + 1;

                    if (errors_equivalence <= 5)
                        $display(
                            "CSA FAIL: a=%0d b=%0d encoder=%0d CSA=%0d",
                            a, b, original_approx, csa_approx
                        );
                end

                // Detect unknown or high-impedance outputs.
                if ((^original_exact  === 1'bx) ||
                    (^csa_exact       === 1'bx) ||
                    (^original_approx === 1'bx) ||
                    (^csa_approx      === 1'bx)) begin
                    unknown_outputs = unknown_outputs + 1;
                end else begin
                    // Use an integer to avoid 16-bit subtraction overflow.
                    error_value = $signed(csa_approx);
                    error_value = error_value - (i * j);

                    if (error_value < 0)
                        absolute_error = -error_value;
                    else
                        absolute_error = error_value;

                    if (error_value != 0)
                        inexact_products = inexact_products + 1;

                    if (absolute_error > maximum_error)
                        maximum_error = absolute_error;

                    sum_absolute_error =
                        sum_absolute_error + absolute_error;

                    sum_signed_error =
                        sum_signed_error + error_value;
                end

                // Export actual RTL outputs as signed decimal.
                $fdisplay(
                    csv_file,
                    "%0d,%0d,%0d,%0d",
                    $signed(a),
                    $signed(b),
                    $signed(csa_exact),
                    $signed(csa_approx)
                );
            end
        end

        $fclose(csv_file);

        $display("Configuration: H12/M0/L4");
        $display("Input pairs checked       : %0d", tests);
        $display("Exact errors              : %0d", errors_exact);
        $display("CSA/encoder mismatches    : %0d", errors_equivalence);
        $display("Unknown output cases      : %0d", unknown_outputs);

        if ((errors_exact == 0) &&
            (errors_equivalence == 0) &&
            (unknown_outputs == 0)) begin

            $display(
                "PASS: H12/M0/L4 CSA verified across all 65,536 input pairs."
            );

            $display("Inexact products          : %0d", inexact_products);
            $display(
                "Error rate                : %0.6f percent",
                100.0 * inexact_products / tests
            );
            $display(
                "Mean absolute error       : %0.6f",
                sum_absolute_error / tests
            );
            $display(
                "Mean signed error         : %0.6f",
                sum_signed_error / tests
            );
            $display("Maximum absolute error    : %0d", maximum_error);
        end else begin
            $display("FAIL: Verification found errors.");
        end

        $display("CSV export finished: rtl_products_H12_M0_L4.csv");
        $finish;
    end

endmodule