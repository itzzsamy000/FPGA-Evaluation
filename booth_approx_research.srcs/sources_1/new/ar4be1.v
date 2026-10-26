module ar4be1 (
    input  wire       a_j,
    input  wire [2:0] booth_code,
    output wire       pp
);

    // booth_code[2] = b(2i+1)
    // booth_code[1] = b(2i)
    // booth_code[0] = b(2i-1)

    assign pp =
        (a_j & ~booth_code[2] &
         (booth_code[0] | booth_code[1]))
        |
        (~a_j & booth_code[2] &
         ~(booth_code[1] & booth_code[0]));

endmodule