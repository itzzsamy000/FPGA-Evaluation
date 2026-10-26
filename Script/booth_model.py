from pathlib import Path
import csv
import numpy as np


def booth_multiply(a, b, approx_cols=6, l_cols=6):
    """
    Signed 8x8 hybrid Booth multiplier model.

    Low columns: AR4BE2
    Middle columns: AR4BE1
    High columns: exact Booth encoding

    Sign correction and addition are exact.
    """

    if not 0 <= l_cols <= approx_cols <= 16:
        raise ValueError(
            "Required: 0 <= l_cols <= approx_cols <= 16"
        )

    a = np.asarray(a, dtype=np.int64)
    b = np.asarray(b, dtype=np.int64)

    if np.any((a < -128) | (a > 127)):
        raise ValueError("A must be between -128 and 127.")

    if np.any((b < -128) | (b > 127)):
        raise ValueError("B must be between -128 and 127.")

    a, b = np.broadcast_arrays(a, b)

    a_ext = a & 0xFFFF
    booth_bits = (b & 0xFF) << 1
    total = np.zeros_like(a, dtype=np.int64)

    for row in range(4):
        shift = 2 * row
        code = (booth_bits >> shift) & 0b111

        select_a = (
            (code == 1)
            | (code == 2)
            | (code == 5)
            | (code == 6)
        )

        select_2a = (code == 3) | (code == 4)

        magnitude = np.where(
            select_a,
            a_ext,
            np.where(select_2a, a_ext << 1, 0),
        ) & 0xFFFF

        negative = (code >> 2) & 1

        exact_raw = np.where(
            negative != 0,
            magnitude ^ 0xFFFF,
            magnitude,
        )

        ar4be1_raw = np.where(
            (code == 0) | (code == 7),
            0,
            np.where(code < 4, a_ext, a_ext ^ 0xFFFF),
        )

        ar4be2_raw = np.where(
            code == 0,
            0,
            np.where(code < 4, a_ext, a_ext ^ 0xFFFF),
        )

        # Convert global column boundaries to row-local masks.
        approx_width = max(0, approx_cols - shift)
        l_width = max(0, l_cols - shift)

        approx_mask = (1 << approx_width) - 1
        l_mask = (1 << l_width) - 1
        m_mask = approx_mask & ~l_mask
        exact_mask = 0xFFFF ^ approx_mask

        raw_row = (
            (exact_raw & exact_mask)
            | (ar4be1_raw & m_mask)
            | (ar4be2_raw & l_mask)
        )

        corrected_row = (raw_row + negative) & 0xFFFF
        total += corrected_row << shift

    unsigned_product = total & 0xFFFF

    return np.where(
        unsigned_product >= 0x8000,
        unsigned_product - 0x10000,
        unsigned_product,
    )


def calculate_metrics(product, exact):
    error = product - exact
    absolute_error = np.abs(error)

    worst_index = np.unravel_index(
        np.argmax(absolute_error),
        absolute_error.shape,
    )

    return {
        "input_pairs": int(error.size),
        "inexact_products": int(np.count_nonzero(error)),
        "error_rate_percent": float(
            100.0 * np.count_nonzero(error) / error.size
        ),
        "mae": float(np.mean(absolute_error)),
        "mean_signed_error": float(np.mean(error)),
        "maximum_absolute_error": int(np.max(absolute_error)),
        "first_worst_a": int(worst_index[0] - 128),
        "first_worst_b": int(worst_index[1] - 128),
    }


def main():
    values = np.arange(-128, 128, dtype=np.int64)

    # Same enumeration order as the Verilog testbench.
    a = values[:, None]
    b = values[None, :]
    exact = a * b

    exact_model = booth_multiply(a, b, 0, 0)

    if not np.array_equal(exact_model, exact):
        raise RuntimeError("Exact Python model verification failed.")

    print("PASS: Exact model matched all 65,536 products.")

    configurations = [
        (0, 0),
        (6, 0),
        (6, 2),
        (6, 4),
        (6, 6),
    ]

    results = []

    for approx_cols, l_cols in configurations:
        label = (
            f"H{16 - approx_cols}"
            f"_M{approx_cols - l_cols}"
            f"_L{l_cols}"
        )

        product = booth_multiply(a, b, approx_cols, l_cols)
        metrics = calculate_metrics(product, exact)

        results.append({
            "configuration": label,
            **metrics,
        })

        print(f"\nConfiguration: {label}")
        print(f"Input pairs             : {metrics['input_pairs']}")
        print(f"Inexact products        : {metrics['inexact_products']}")
        print(
            "Error rate              : "
            f"{metrics['error_rate_percent']:.6f} percent"
        )
        print(f"Mean absolute error     : {metrics['mae']:.6f}")
        print(
            "Mean signed error       : "
            f"{metrics['mean_signed_error']:.6f}"
        )
        print(
            "Maximum absolute error  : "
            f"{metrics['maximum_absolute_error']}"
        )
        print(
            "First worst-case inputs : "
            f"a={metrics['first_worst_a']} "
            f"b={metrics['first_worst_b']}"
        )

        if (approx_cols, l_cols) == (6, 6):
            matches_verilog_metrics = (
                metrics["inexact_products"] == 39936
                and abs(
                    metrics["mae"] - 15.25146484375
                ) < 1e-12
                and metrics["mean_signed_error"] == -6.875
                and metrics["maximum_absolute_error"] == 125
                and metrics["first_worst_a"] == -81
                and metrics["first_worst_b"] == -66
            )

            if not matches_verilog_metrics:
                raise RuntimeError(
                    "H10/M0/L6 metrics differ from Verilog results."
                )

            print("PASS: Metrics match reported Verilog results.")

    output_dir = (
        Path(__file__).resolve().parent.parent
        / "results"
        / "python_model"
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    csv_path = output_dir / "error_metrics.csv"

    with csv_path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(
            file,
            fieldnames=list(results[0].keys()),
        )
        writer.writeheader()
        writer.writerows(results)

    print(f"\nResults saved to:\n{csv_path}")
    print(
        "\nAggregate metric agreement does not replace "
        "per-input RTL/Python equivalence verification."
    )


if __name__ == "__main__":
    main()