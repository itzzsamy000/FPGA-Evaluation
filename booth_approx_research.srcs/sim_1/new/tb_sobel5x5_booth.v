`timescale 1ns / 1ps

module tb_sobel5x5_booth;

    reg [199:0] window_pixels;

    wire signed [19:0] gx_exact, gy_exact;
    wire signed [19:0] gx_h10,   gy_h10;
    wire signed [19:0] gx_h12,   gy_h12;

    integer smooth [0:4];
    integer deriv  [0:4];

    integer row, col;
    integer pixel_value;
    integer centered;
    integer cx, cy;

    integer expected_exact_x, expected_exact_y;
    integer expected_h10_x, expected_h10_y;
    integer expected_h12_x, expected_h12_y;

    integer tests;
    integer errors_exact;
    integer errors_h10;
    integer errors_h12;

    integer test_id;
    integer pixel_id;
    integer seed;

    sobel5x5_booth #(
        .APPROX_COLS(0),
        .L_COLS(0)
    ) dut_exact (
        .window_pixels(window_pixels),
        .gx(gx_exact),
        .gy(gy_exact)
    );

    sobel5x5_booth #(
        .APPROX_COLS(6),
        .L_COLS(6)
    ) dut_h10 (
        .window_pixels(window_pixels),
        .gx(gx_h10),
        .gy(gy_h10)
    );

    sobel5x5_booth #(
        .APPROX_COLS(4),
        .L_COLS(4)
    ) dut_h12 (
        .window_pixels(window_pixels),
        .gx(gx_h12),
        .gy(gy_h12)
    );

    // Independent bit-level behavioral reference.
    // Does not instantiate the RTL multiplier or encoder modules.
    function integer model_product;
        input integer x;
        input integer y;
        input integer approx_cols;
        input integer l_cols;

        integer a16;
        integer booth_bits;
        integer r, c;
        integer code;
        integer aj, aprev;
        integer one_select, two_select;
        integer bit_value;
        integer raw;
        integer total;
        integer negative;
        integer weight;

        begin
            a16 = x & 65535;
            booth_bits = (y & 255) << 1;
            total = 0;

            for (r = 0; r < 4; r = r + 1) begin
                code = (booth_bits >> (2*r)) & 7;
                negative = (code >> 2) & 1;
                raw = 0;

                for (c = 0; c < 16; c = c + 1) begin
                    aj = (a16 >> c) & 1;

                    if (c == 0)
                        aprev = 0;
                    else
                        aprev = (a16 >> (c-1)) & 1;

                    weight = c + 2*r;

                    if (weight < l_cols) begin
                        // AR4BE2 truth table.
                        case (code)
                            0:       bit_value = 0;
                            1, 2, 3: bit_value = aj;
                            default: bit_value = 1 - aj;
                        endcase

                    end else if (weight < approx_cols) begin
                        // AR4BE1 truth table.
                        case (code)
                            0, 7:    bit_value = 0;
                            1, 2, 3: bit_value = aj;
                            default: bit_value = 1 - aj;
                        endcase

                    end else begin
                        // Exact raw Booth partial-product bit.
                        one_select = ((code >> 1) ^ code) & 1;

                        if ((code == 3) || (code == 4))
                            two_select = 1;
                        else
                            two_select = 0;

                        bit_value =
                            ((one_select & aj) |
                             (two_select & aprev)) ^ negative;
                    end

                    raw = raw | (bit_value << c);
                end

                // Exact negation correction and row alignment.
                total = total
                    + (((raw + negative) & 65535) << (2*r));
            end

            total = total & 65535;

            if (total >= 32768)
                model_product = total - 65536;
            else
                model_product = total;
        end
    endfunction

    task check_window;
        begin
            expected_exact_x = 0;
            expected_exact_y = 0;
            expected_h10_x = 0;
            expected_h10_y = 0;
            expected_h12_x = 0;
            expected_h12_y = 0;

            for (row = 0; row < 5; row = row + 1) begin
                for (col = 0; col < 5; col = col + 1) begin

                    pixel_value =
                        window_pixels[(row*5+col)*8 +: 8];

                    centered = pixel_value - 128;

                    cx = smooth[row] * deriv[col];
                    cy = deriv[row] * smooth[col];

                    // Direct exact Sobel on unsigned pixels.
                    expected_exact_x =
                        expected_exact_x + pixel_value * cx;

                    expected_exact_y =
                        expected_exact_y + pixel_value * cy;

                    expected_h10_x = expected_h10_x
                        + model_product(centered, cx, 6, 6);

                    expected_h10_y = expected_h10_y
                        + model_product(centered, cy, 6, 6);

                    expected_h12_x = expected_h12_x
                        + model_product(centered, cx, 4, 4);

                    expected_h12_y = expected_h12_y
                        + model_product(centered, cy, 4, 4);
                end
            end

            #1;
            tests = tests + 1;

            if ((gx_exact !== expected_exact_x) ||
                (gy_exact !== expected_exact_y)) begin

                errors_exact = errors_exact + 1;

                if (errors_exact <= 5)
                    $display(
                        "EXACT FAIL test=%0d gx=%0d ref=%0d gy=%0d ref=%0d",
                        tests, $signed(gx_exact), expected_exact_x,
                        $signed(gy_exact), expected_exact_y
                    );
            end

            if ((gx_h10 !== expected_h10_x) ||
                (gy_h10 !== expected_h10_y)) begin

                errors_h10 = errors_h10 + 1;

                if (errors_h10 <= 5)
                    $display(
                        "H10 FAIL test=%0d gx=%0d ref=%0d gy=%0d ref=%0d",
                        tests, $signed(gx_h10), expected_h10_x,
                        $signed(gy_h10), expected_h10_y
                    );
            end

            if ((gx_h12 !== expected_h12_x) ||
                (gy_h12 !== expected_h12_y)) begin

                errors_h12 = errors_h12 + 1;

                if (errors_h12 <= 5)
                    $display(
                        "H12 FAIL test=%0d gx=%0d ref=%0d gy=%0d ref=%0d",
                        tests, $signed(gx_h12), expected_h12_x,
                        $signed(gy_h12), expected_h12_y
                    );
            end
        end
    endtask

    initial begin
        smooth[0] = 1;
        smooth[1] = 4;
        smooth[2] = 6;
        smooth[3] = 4;
        smooth[4] = 1;

        deriv[0] = -1;
        deriv[1] = -2;
        deriv[2] = 0;
        deriv[3] = 2;
        deriv[4] = 1;

        window_pixels = 200'd0;

        tests = 0;
        errors_exact = 0;
        errors_h10 = 0;
        errors_h12 = 0;
        seed = 12345;

        // Every constant-intensity window.
        for (test_id = 0; test_id < 256;
             test_id = test_id + 1) begin

            for (pixel_id = 0; pixel_id < 25;
                 pixel_id = pixel_id + 1)
                window_pixels[pixel_id*8 +: 8] = test_id;

            check_window;
        end

        // One bright pixel in a black window.
        for (pixel_id = 0; pixel_id < 25;
             pixel_id = pixel_id + 1) begin

            window_pixels = 200'd0;
            window_pixels[pixel_id*8 +: 8] = 8'd255;
            check_window;
        end

        // One dark pixel in a white window.
        for (pixel_id = 0; pixel_id < 25;
             pixel_id = pixel_id + 1) begin

            window_pixels = {25{8'hFF}};
            window_pixels[pixel_id*8 +: 8] = 8'd0;
            check_window;
        end

        // Reproducible random windows.
        for (test_id = 0; test_id < 1000;
             test_id = test_id + 1) begin

            for (pixel_id = 0; pixel_id < 25;
                 pixel_id = pixel_id + 1)
                window_pixels[pixel_id*8 +: 8] = $random(seed);

            check_window;
        end

        $display("----------------------------------------");
        $display("Total windows checked : %0d", tests);
        $display("Exact mismatches      : %0d", errors_exact);
        $display("H10/M0/L6 mismatches  : %0d", errors_h10);
        $display("H12/M0/L4 mismatches  : %0d", errors_h12);

        if ((errors_exact == 0) &&
            (errors_h10 == 0) &&
            (errors_h12 == 0))
            $display(
                "PASS: All three Sobel configurations matched their reference models."
            );
        else
            $display("FAIL: Sobel verification found mismatches.");

        $display(
            "Approximate-model agreement does not mean zero arithmetic error."
        );

        $finish;
    end

endmodule