# Verify exact shift-add multiplication for our 5x5 Sobel kernels.
# Python integers have unlimited width.
# RTL mein signed intermediate widths explicitly define karenge.

SMOOTHING = [1, 4, 6, 4, 1]
DERIVATIVE = [-1, -2, 0, 2, 1]

KERNEL_X = [
    [s * d for d in DERIVATIVE]
    for s in SMOOTHING
]

KERNEL_Y = [
    list(column)
    for column in zip(*KERNEL_X)
]

COEFFICIENTS = sorted({
    coefficient
    for kernel in (KERNEL_X, KERNEL_Y)
    for row in kernel
    for coefficient in row
})


def shift_add_multiply(x, coefficient):
    magnitude = abs(coefficient)

    if magnitude == 0:
        result = 0
    elif magnitude == 1:
        result = x
    elif magnitude == 2:
        result = x << 1
    elif magnitude == 4:
        result = x << 2
    elif magnitude == 6:
        result = (x << 2) + (x << 1)
    elif magnitude == 8:
        result = x << 3
    elif magnitude == 12:
        result = (x << 3) + (x << 2)
    else:
        raise ValueError(f"Unsupported coefficient: {coefficient}")

    return -result if coefficient < 0 else result


def main():
    tests = 0

    for x in range(-128, 128):
        for coefficient in COEFFICIENTS:
            expected = x * coefficient
            actual = shift_add_multiply(x, coefficient)

            if actual != expected:
                raise SystemExit(
                    f"FAIL: x={x}, coefficient={coefficient}, "
                    f"got={actual}, expected={expected}"
                )

            tests += 1

    # Centering pixels by subtracting 128 preserves the exact
    # gradient because each derivative kernel sums to zero.
    for kernel in (KERNEL_X, KERNEL_Y):
        if sum(map(sum, kernel)) != 0:
            raise SystemExit("FAIL: Kernel sum must be zero.")

    print("Coefficients:", COEFFICIENTS)
    print(f"Input/coefficient combinations checked: {tests}")
    print("PASS: Shift-add matched exact multiplication.")
    print("PASS: Both Sobel kernels have zero coefficient sum.")
    print("Software arithmetic verification only.")
    print("Next: RTL implementation and resource comparison.")


if __name__ == "__main__":
    main()