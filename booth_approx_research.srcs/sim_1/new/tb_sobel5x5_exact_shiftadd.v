`timescale 1ns / 1ps

module tb_sobel5x5_exact_shiftadd;

    reg [199:0] window_pixels;

    wire signed [19:0] gx;
    wire signed [19:0] gy;

    integer smooth [0:4];
    integer deriv  [0:4];

    integer expected_gx;
    integer expected_gy;

    integer row, col;
    integer test_id;
    integer pixel_id;
    integer pixel_value;

    integer tests;
    integer errors;
    integer seed;

    sobel5x5_exact_shiftadd dut (
        .window_pixels(window_pixels),
        .gx(gx),
        .gy(gy)
    );

    // Independent reference:
    // Use unsigned pixel values and direct multiplication.
    // The DUT instead centers pixels and uses shift-add logic.
    task check_window;
        begin
            expected_gx = 0;
            expected_gy = 0;

            for (row = 0; row < 5; row = row + 1) begin
                for (col = 0; col < 5; col = col + 1) begin
                    pixel_value =
                        window_pixels[(row*5+col)*8 +: 8];

                    expected_gx = expected_gx
                        + pixel_value * smooth[row] * deriv[col];

                    expected_gy = expected_gy
                        + pixel_value * deriv[row] * smooth[col];
                end
            end

            #1;
            tests = tests + 1;

            if ((gx !== expected_gx) ||
                (gy !== expected_gy)) begin

                errors = errors + 1;

                if (errors <= 10) begin
                    $display(
                        "FAIL test=%0d gx=%0d expected_gx=%0d gy=%0d expected_gy=%0d",
                        tests, $signed(gx), expected_gx,
                        $signed(gy), expected_gy
                    );
                end
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
        errors = 0;
        seed = 12345;

        // Test every constant-intensity window.
        // Both gradients should be zero.
        for (test_id = 0; test_id < 256;
             test_id = test_id + 1) begin

            for (pixel_id = 0; pixel_id < 25;
                 pixel_id = pixel_id + 1)
                window_pixels[pixel_id*8 +: 8] = test_id;

            check_window;
        end

        // Isolated bright pixel at each of the 25 positions.
        for (pixel_id = 0; pixel_id < 25;
             pixel_id = pixel_id + 1) begin

            window_pixels = 200'd0;
            window_pixels[pixel_id*8 +: 8] = 8'd255;

            check_window;
        end

        // Isolated dark pixel in a white window.
        for (pixel_id = 0; pixel_id < 25;
             pixel_id = pixel_id + 1) begin

            window_pixels = {25{8'hFF}};
            window_pixels[pixel_id*8 +: 8] = 8'd0;

            check_window;
        end

        // Horizontal intensity ramp: varying by column.
        for (row = 0; row < 5; row = row + 1)
            for (col = 0; col < 5; col = col + 1)
                window_pixels[(row*5+col)*8 +: 8] = col * 63;

        check_window;

        // Vertical intensity ramp: varying by row.
        for (row = 0; row < 5; row = row + 1)
            for (col = 0; col < 5; col = col + 1)
                window_pixels[(row*5+col)*8 +: 8] = row * 63;

        check_window;

        // Positive and negative horizontal-gradient extremes.
        for (test_id = 0; test_id < 2;
             test_id = test_id + 1) begin

            for (row = 0; row < 5; row = row + 1) begin
                for (col = 0; col < 5; col = col + 1) begin

                    if (deriv[col] > 0)
                        window_pixels[(row*5+col)*8 +: 8] =
                            (test_id == 0) ? 8'd255 : 8'd0;
                    else if (deriv[col] < 0)
                        window_pixels[(row*5+col)*8 +: 8] =
                            (test_id == 0) ? 8'd0 : 8'd255;
                    else
                        window_pixels[(row*5+col)*8 +: 8] =
                            8'd128;
                end
            end

            check_window;
        end

        // Positive and negative vertical-gradient extremes.
        for (test_id = 0; test_id < 2;
             test_id = test_id + 1) begin

            for (row = 0; row < 5; row = row + 1) begin
                for (col = 0; col < 5; col = col + 1) begin

                    if (deriv[row] > 0)
                        window_pixels[(row*5+col)*8 +: 8] =
                            (test_id == 0) ? 8'd255 : 8'd0;
                    else if (deriv[row] < 0)
                        window_pixels[(row*5+col)*8 +: 8] =
                            (test_id == 0) ? 8'd0 : 8'd255;
                    else
                        window_pixels[(row*5+col)*8 +: 8] =
                            8'd128;
                end
            end

            check_window;
        end

        // Checkerboard and its inverse.
        for (test_id = 0; test_id < 2;
             test_id = test_id + 1) begin

            for (row = 0; row < 5; row = row + 1)
                for (col = 0; col < 5; col = col + 1)
                    window_pixels[(row*5+col)*8 +: 8] =
                        ((row + col + test_id) % 2)
                        ? 8'd255 : 8'd0;

            check_window;
        end

        // Reproducible random windows.
        for (test_id = 0; test_id < 10000;
             test_id = test_id + 1) begin

            for (pixel_id = 0; pixel_id < 25;
                 pixel_id = pixel_id + 1)
                window_pixels[pixel_id*8 +: 8] = $random(seed);

            check_window;
        end

        $display("----------------------------------------");
        $display("Total windows checked: %0d", tests);
        $display("Mismatched windows   : %0d", errors);

        if (errors == 0)
            $display(
                "PASS: All Sobel shift-add outputs matched the direct mathematical reference."
            );
        else
            $display("FAIL: Sobel verification found mismatches.");

        $display(
            "Directed and random testing; not exhaustive over all possible windows."
        );

        $finish;
    end

endmodule