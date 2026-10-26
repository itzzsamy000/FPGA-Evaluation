`timescale 1ns / 1ps

module tb_booth_exact_bit;

    reg        a_j;
    reg        a_prev;
    reg  [2:0] booth_code;
    wire       pp;

    reg expected;
    integer inputs;
    integer errors;

    booth_exact_bit dut (
        .a_j(a_j),
        .a_prev(a_prev),
        .booth_code(booth_code),
        .pp(pp)
    );

    initial begin
        errors = 0;

        for (inputs = 0; inputs < 32; inputs = inputs + 1) begin
            {a_j, a_prev, booth_code} = inputs;

            // Raw partial-product bit before +1 correction.
            case (booth_code)
                3'b000: expected = 1'b0;
                3'b001: expected = a_j;
                3'b010: expected = a_j;
                3'b011: expected = a_prev;
                3'b100: expected = ~a_prev;
                3'b101: expected = ~a_j;
                3'b110: expected = ~a_j;
                3'b111: expected = 1'b1;
                default: expected = 1'bx;
            endcase

            #1;

            if (pp !== expected) begin
                errors = errors + 1;

                $display(
                    "FAIL: a_j=%b a_prev=%b code=%b pp=%b expected=%b",
                    a_j, a_prev, booth_code, pp, expected
                );
            end
        end

        if (errors == 0)
            $display(
                "PASS: All 32 exact Booth bit combinations matched."
            );
        else
            $display("FAIL: %0d mismatches.", errors);

        $finish;
    end

endmodule