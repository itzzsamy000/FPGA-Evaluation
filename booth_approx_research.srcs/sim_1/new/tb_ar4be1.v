`timescale 1ns / 1ps

module tb_ar4be1;

    reg        a_j;
    reg  [2:0] booth_code;
    wire       pp;

    reg expected;
    integer a_value, code_value;
    integer errors;

    ar4be1 dut (
        .a_j(a_j),
        .booth_code(booth_code),
        .pp(pp)
    );

    initial begin
        errors = 0;

        for (a_value = 0; a_value < 2; a_value = a_value + 1) begin
            for (code_value = 0; code_value < 8;
                 code_value = code_value + 1) begin

                a_j        = a_value;
                booth_code = code_value;

                // Independent truth-table reference.
                // Negative rows contain inverted data bits;
                // the +1 correction is handled separately.
                case (booth_code)
                    3'b000, 3'b111: expected = 1'b0;
                    3'b001, 3'b010,
                    3'b011:         expected = a_j;
                    3'b100, 3'b101,
                    3'b110:         expected = ~a_j;
                    default:        expected = 1'bx;
                endcase

                #1;

                if (pp !== expected) begin
                    errors = errors + 1;
                    $display("FAIL: a_j=%b code=%b pp=%b expected=%b",
                             a_j, booth_code, pp, expected);
                end
            end
        end

        if (errors == 0)
            $display("PASS: All 16 AR4BE1 input combinations matched.");
        else
            $display("FAIL: %0d mismatches.", errors);

        $finish;
    end

endmodule`timescale 1ns / 1ps

module tb_ar4be1;

    reg        a_j;
    reg  [2:0] booth_code;
    wire       pp;

    reg expected;
    integer a_value, code_value;
    integer errors;

    ar4be1 dut (
        .a_j(a_j),
        .booth_code(booth_code),
        .pp(pp)
    );

    initial begin
        errors = 0;

        for (a_value = 0; a_value < 2; a_value = a_value + 1) begin
            for (code_value = 0; code_value < 8;
                 code_value = code_value + 1) begin

                a_j        = a_value;
                booth_code = code_value;

                // Independent truth-table reference.
                // Negative rows contain inverted data bits;
                // the +1 correction is handled separately.
                case (booth_code)
                    3'b000, 3'b111: expected = 1'b0;
                    3'b001, 3'b010,
                    3'b011:         expected = a_j;
                    3'b100, 3'b101,
                    3'b110:         expected = ~a_j;
                    default:        expected = 1'bx;
                endcase

                #1;

                if (pp !== expected) begin
                    errors = errors + 1;
                    $display("FAIL: a_j=%b code=%b pp=%b expected=%b",
                             a_j, booth_code, pp, expected);
                end
            end
        end

        if (errors == 0)
            $display("PASS: All 16 AR4BE1 input combinations matched.");
        else
            $display("FAIL: %0d mismatches.", errors);

        $finish;
    end

endmodule