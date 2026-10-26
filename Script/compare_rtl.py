import csv
from pathlib import Path

import numpy as np

from booth_model import booth_multiply


# H12/M0/L4 configuration
APPROX_COLS = 4
L_COLS = 4

PROJECT_DIR = Path(__file__).resolve().parent.parent

CSV_PATH = (
    PROJECT_DIR
    / "results"
    / "python_model"
    / "rtl_products_H12_M0_L4.csv"
)

EXPECTED_COLUMNS = [
    "a",
    "b",
    "exact_product",
    "approximate_product",
]


def main():
    print("Configuration: H12/M0/L4")
    print(f"Reading: {CSV_PATH}")

    if not CSV_PATH.is_file():
        raise SystemExit(
            "\nFAIL: CSV file nahi mili.\n"
            "Vivado se generated rtl_products_H12_M0_L4.csv ko "
            "results/python_model folder mein check karo."
        )

    records = []
    seen_pairs = set()

    with CSV_PATH.open(
        "r", newline="", encoding="utf-8-sig"
    ) as csv_file:
        reader = csv.DictReader(csv_file)

        if reader.fieldnames != EXPECTED_COLUMNS:
            raise SystemExit(
                "FAIL: CSV columns incorrect.\n"
                f"Expected: {EXPECTED_COLUMNS}\n"
                f"Found: {reader.fieldnames}"
            )

        for line_number, row in enumerate(reader, start=2):
            if None in row:
                raise SystemExit(
                    f"FAIL: Extra CSV values at line {line_number}."
                )

            try:
                a = int(row["a"])
                b = int(row["b"])
                rtl_exact = int(row["exact_product"])
                rtl_approx = int(row["approximate_product"])
            except (ValueError, TypeError):
                raise SystemExit(
                    f"FAIL: Invalid integer or X/Z value "
                    f"at CSV line {line_number}."
                )

            if not (-128 <= a <= 127 and -128 <= b <= 127):
                raise SystemExit(
                    f"FAIL: Input outside signed 8-bit range "
                    f"at line {line_number}: a={a}, b={b}"
                )

            if not (
                -32768 <= rtl_exact <= 32767
                and -32768 <= rtl_approx <= 32767
            ):
                raise SystemExit(
                    f"FAIL: Output outside signed 16-bit range "
                    f"at line {line_number}."
                )

            pair = (a, b)

            if pair in seen_pairs:
                raise SystemExit(
                    f"FAIL: Duplicate input pair at line "
                    f"{line_number}: a={a}, b={b}"
                )

            seen_pairs.add(pair)
            records.append((a, b, rtl_exact, rtl_approx))

    if len(records) != 65536:
        raise SystemExit(
            f"FAIL: Expected 65,536 rows, found {len(records):,}."
        )

    # Valid range + 65,536 unique pairs ensures full input coverage.
    values = np.asarray(records, dtype=np.int64)

    a_values = values[:, 0]
    b_values = values[:, 1]
    rtl_exact = values[:, 2]
    rtl_approx = values[:, 3]

    # Exact mathematical multiplication
    expected_exact = a_values * b_values

    # Python approximate multiplier model: H12/M0/L4
    expected_approx = np.asarray(
        booth_multiply(
            a_values,
            b_values,
            approx_cols=APPROX_COLS,
            l_cols=L_COLS,
        ),
        dtype=np.int64,
    )

    if expected_approx.shape != rtl_approx.shape:
        raise SystemExit(
            "FAIL: Python model returned an unexpected output shape."
        )

    exact_bad = rtl_exact != expected_exact
    approx_bad = rtl_approx != expected_approx
    any_bad = exact_bad | approx_bad

    exact_mismatches = int(np.count_nonzero(exact_bad))
    approx_mismatches = int(np.count_nonzero(approx_bad))
    mismatched_pairs = int(np.count_nonzero(any_bad))

    print()
    print(f"Unique input pairs checked: {len(seen_pairs)}")
    print(f"Exact mismatches          : {exact_mismatches}")
    print(f"Approximate mismatches    : {approx_mismatches}")
    print(f"Mismatched input pairs    : {mismatched_pairs}")

    if mismatched_pairs:
        print("\nFirst mismatched cases:")

        for index in np.flatnonzero(any_bad)[:10]:
            print(
                f"a={int(a_values[index])}, "
                f"b={int(b_values[index])} | "
                f"RTL exact={int(rtl_exact[index])}, "
                f"expected exact={int(expected_exact[index])} | "
                f"RTL approx={int(rtl_approx[index])}, "
                f"Python approx={int(expected_approx[index])}"
            )

        raise SystemExit(
            "\nFAIL: RTL and Python outputs do not match."
        )

    # Calculate approximation error relative to exact multiplication.
    errors = rtl_approx - expected_exact
    absolute_errors = np.abs(errors)

    print()
    print(
        "PASS: All 65,536 exact and approximate outputs matched."
    )
    print()
    print(
        f"Inexact products       : "
        f"{int(np.count_nonzero(errors))}"
    )
    print(
        f"Error rate             : "
        f"{100.0 * np.count_nonzero(errors) / len(errors):.6f} percent"
    )
    print(
        f"Mean absolute error    : "
        f"{float(np.mean(absolute_errors)):.6f}"
    )
    print(
        f"Mean signed error      : "
        f"{float(np.mean(errors)):.6f}"
    )
    print(
        f"Maximum absolute error : "
        f"{int(np.max(absolute_errors))}"
    )


if __name__ == "__main__":
    main()