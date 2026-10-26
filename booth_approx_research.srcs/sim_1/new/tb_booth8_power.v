`timescale 1ns / 1ps

module tb_booth8_power;

    reg signed [7:0] a, b;

    wire signed [15:0] product_exact;
    wire signed [15:0] product_h10;
    wire signed [15:0] product_h12;

    integer seed;
    integer k;

    booth8_hybrid_csa #(
        .APPROX_COLS(0),
        .L_COLS(0)
    ) dut_exact (
        .a(a),
        .b(b),
        .product(product_exact)
    );

    booth8_hybrid_csa #(
        .APPROX_COLS(6),
        .L_COLS(6)
    ) dut_h10 (
        .a(a),
        .b(b),
        .product(product_h10)
    );

    booth8_hybrid_csa #(
        .APPROX_COLS(4),
        .L_COLS(4)
    ) dut_h12 (
        .a(a),
        .b(b),
        .product(product_h12)
    );

    initial begin
        // Fixed seed makes this stimulus reproducible.
        seed = 12345;
        a = 0;
        b = 0;

        // Initial settling interval.
        #100;

        // Same input sequence reaches all three architectures.
        for (k = 0; k < 65536; k = k + 1) begin
            a = $random(seed);
            b = $random(seed);
            #10;
        end

        $display("POWER STIMULUS COMPLETE: 65,536 random input pairs.");
        $display("Input update interval: 10 ns.");
        $finish;
    end

endmodule