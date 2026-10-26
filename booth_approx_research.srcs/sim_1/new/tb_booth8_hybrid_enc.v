`timescale 1ns / 1ps

module tb_booth8_hybrid_enc;

    localparam integer APPROX_COLS = 4;
    localparam integer L_COLS      = 4;

    reg  signed [7:0]  a, b;
    wire signed [15:0] product;

    reg signed [15:0] model_product;

    integer i, j;
    integer tests;
    integer model_mismatches;
    integer arithmetic_errors;

    integer exact_product;
    integer observed_product;
    integer error_value;
    integer abs_error;
    integer max_abs_error;
    integer worst_a, worst_b;

    real sum_abs_error;
    real sum_signed_error;

    booth8_hybrid_enc #(
        .APPROX_COLS (APPROX_COLS),
        .L_COLS      (L_COLS)
    ) dut (
        .a       (a),
        .b       (b),
        .product (product)
    );

    // Independent truth-table reference.
    function [15:0] reference_model;
        input [7:0] x;
        input [7:0] y;

        reg [15:0] x_ext;
        reg [8:0] y_bits;
        reg [2:0] code;

        reg [15:0] raw_row;
        reg [15:0] corrected_row;
        reg [15:0] total;

        reg current_bit;
        reg previous_bit;
        reg result_bit;

        integer r, c;
        integer global_col;

        begin
            x_ext  = {{8{x[7]}}, x};
            y_bits = {y, 1'b0};
            total  = 16'b0;

            for (r = 0; r < 4; r = r + 1) begin

                code    = (y_bits >> (2*r)) & 3'b111;
                raw_row = 16'b0;

                for (c = 0; c < 16; c = c + 1) begin

                    global_col = c + 2*r;
                    current_bit = x_ext[c];

                    if (c == 0)
                        previous_bit = 1'b0;
                    else
                        previous_bit = x_ext[c-1];

                    if (global_col < L_COLS) begin

                        // AR4BE2 region.
                        case (code)
                            3'b000:
                                result_bit = 1'b0;

                            3'b001, 3'b010, 3'b011:
                                result_bit = current_bit;

                            default:
                                result_bit = ~current_bit;
                        endcase

                    end else if (global_col < APPROX_COLS) begin

                        // AR4BE1 region.
                        case (code)
                            3'b000, 3'b111:
                                result_bit = 1'b0;

                            3'b001, 3'b010, 3'b011:
                                result_bit = current_bit;

                            default:
                                result_bit = ~current_bit;
                        endcase

                    end else begin

                        // Exact region.
                        case (code)
                            3'b000: result_bit = 1'b0;
                            3'b001: result_bit = current_bit;
                            3'b010: result_bit = current_bit;
                            3'b011: result_bit = previous_bit;
                            3'b100: result_bit = ~previous_bit;
                            3'b101: result_bit = ~current_bit;
                            3'b110: result_bit = ~current_bit;
                            3'b111: result_bit = 1'b1;
                        endcase

                    end

                    raw_row[c] = result_bit;
                end

                corrected_row = raw_row + {15'b0, code[2]};
                total = total + (corrected_row << (2*r));

            end

            reference_model = total;
        end
    endfunction

    initial begin

        if ((L_COLS < 0) ||
            (APPROX_COLS < L_COLS) ||
            (APPROX_COLS > 16)) begin

            $display("FAIL: Invalid region parameters.");
            $finish;
        end

        a = 0;
        b = 0;

        tests             = 0;
        model_mismatches  = 0;
        arithmetic_errors = 0;

        max_abs_error    = 0;
        worst_a          = 0;
        worst_b          = 0;
        sum_abs_error    = 0.0;
        sum_signed_error = 0.0;

        for (i = -128; i <= 127; i = i + 1) begin
            for (j = -128; j <= 127; j = j + 1) begin

                a = i;
                b = j;

                model_product = reference_model(a, b);
                exact_product = i * j;

                #1;

                tests = tests + 1;

                if (product !== model_product) begin

                    model_mismatches = model_mismatches + 1;

                    if (model_mismatches <= 10)
                        $display(
                            "MODEL FAIL: a=%0d b=%0d RTL=%0d model=%0d",
                            a, b, product, model_product
                        );

                end else begin

                    observed_product = $signed(product);

                    error_value =
                        observed_product - exact_product;

                    if (error_value < 0)
                        abs_error = -error_value;
                    else
                        abs_error = error_value;

                    if (abs_error != 0)
                        arithmetic_errors = arithmetic_errors + 1;

                    sum_abs_error =
                        sum_abs_error + abs_error;

                    sum_signed_error =
                        sum_signed_error + error_value;

                    if (abs_error > max_abs_error) begin
                        max_abs_error = abs_error;
                        worst_a = i;
                        worst_b = j;
                    end

                end
            end
        end

        $display("Configuration: H%0d M%0d L%0d",
                 16 - APPROX_COLS,
                 APPROX_COLS - L_COLS,
                 L_COLS);

        if (model_mismatches == 0) begin

            $display(
                "PASS: All 65,536 hybrid outputs matched the reference model."
            );

            $display("Total input pairs       = %0d", tests);

            $display("Inexact products        = %0d",
                     arithmetic_errors);

            $display("Error rate              = %0.6f percent",
                     100.0 * arithmetic_errors / tests);

            $display("Mean absolute error     = %0.6f",
                     sum_abs_error / tests);

            $display("Mean signed error       = %0.6f",
                     sum_signed_error / tests);

            $display("Maximum absolute error  = %0d",
                     max_abs_error);

            $display("First worst-case inputs = a:%0d b:%0d",
                     worst_a, worst_b);

        end else begin

            $display("FAIL: %0d reference-model mismatches.",
                     model_mismatches);

            $display(
                "Accuracy metrics withheld because RTL verification failed."
            );

        end

        $finish;
    end

endmodule