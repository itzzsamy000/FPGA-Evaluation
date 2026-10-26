module booth_exact_bit (
    input  wire       a_j,
    input  wire       a_prev,
    input  wire [2:0] booth_code,
    output wire       pp
);

    wire select_one;
    wire select_two;
    wire magnitude_bit;

    // Select A for codes 001, 010, 101, 110.
    assign select_one = booth_code[1] ^ booth_code[0];

    // Select 2A for codes 011 and 100.
    assign select_two =
        (~booth_code[2] &  booth_code[1] &  booth_code[0])
        |
        ( booth_code[2] & ~booth_code[1] & ~booth_code[0]);

    assign magnitude_bit =
        (select_one & a_j)
        |
        (select_two & a_prev);

    // Invert negative partial products.
    // The +1 correction is added separately.
    assign pp = magnitude_bit ^ booth_code[2];

endmodule