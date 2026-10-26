import argparse
import csv
from pathlib import Path

import numpy as np
from PIL import Image
from skimage import data
from skimage.metrics import (
    peak_signal_noise_ratio,
    structural_similarity,
)

from booth_model import booth_multiply


# H12/M0/L4: four approximate columns, all using AR4BE2.
APPROX_COLS = 4
L_COLS = 4

CONFIG_NAME = "H12_M0_L4"
CONFIG_LABEL = "H12/M0/L4"

PROJECT_DIR = Path(__file__).resolve().parent.parent


def load_image(image_path):
    if image_path is None:
        return data.camera(), "camera"

    path = Path(image_path).expanduser()

    if not path.is_file():
        raise SystemExit(f"Image file nahi mili:\n{path}")

    with Image.open(path) as image:
        image = image.convert("L")
        image.thumbnail(
            (512, 512),
            Image.Resampling.LANCZOS,
        )
        gray = np.array(image, dtype=np.uint8)

    return gray, path.stem


def build_lookup_tables():
    signed_values = np.arange(-128, 128, dtype=np.int64)

    a = signed_values[:, None]
    b = signed_values[None, :]

    exact_table = a * b

    approximate_table = np.asarray(
        booth_multiply(
            a,
            b,
            approx_cols=APPROX_COLS,
            l_cols=L_COLS,
        ),
        dtype=np.int64,
    )

    if approximate_table.shape != (256, 256):
        raise SystemExit(
            "FAIL: Approximate lookup table shape incorrect."
        )

    return exact_table, approximate_table


def sobel_5x5(gray, lookup_table):
    smoothing = np.array([1, 4, 6, 4, 1], dtype=np.int64)
    derivative = np.array([-1, -2, 0, 2, 1], dtype=np.int64)

    kernel_x = np.outer(smoothing, derivative)
    kernel_y = kernel_x.T

    # Map unsigned pixels into the signed 8-bit input range.
    signed_pixels = gray.astype(np.int64) - 128
    padded = np.pad(signed_pixels, 2, mode="reflect")

    height, width = gray.shape

    gx = np.zeros((height, width), dtype=np.int64)
    gy = np.zeros((height, width), dtype=np.int64)

    for row in range(5):
        for column in range(5):
            pixels = padded[
                row:row + height,
                column:column + width,
            ]

            pixel_indices = pixels + 128
            coefficient_x = int(kernel_x[row, column])
            coefficient_y = int(kernel_y[row, column])

            # Include zero coefficients to preserve the same
            # operation sequence for both multiplier models.
            gx += lookup_table[
                pixel_indices,
                coefficient_x + 128,
            ]

            gy += lookup_table[
                pixel_indices,
                coefficient_y + 128,
            ]

    # Identical fixed scaling for exact and approximate outputs.
    magnitude = np.abs(gx) + np.abs(gy)

    edges = np.clip(
        np.rint(magnitude / 96.0),
        0,
        255,
    ).astype(np.uint8)

    return gx, gy, edges


def save_png(path, pixels):
    Image.fromarray(
        np.asarray(pixels, dtype=np.uint8)
    ).save(path)


def main():
    parser = argparse.ArgumentParser(
        description="Exact and approximate 5x5 Sobel comparison."
    )

    parser.add_argument(
        "--image",
        type=str,
        default=None,
        help="Input image path. Default: camera test image.",
    )

    args = parser.parse_args()
    gray, image_name = load_image(args.image)

    if min(gray.shape) < 7:
        raise SystemExit(
            "Image kam se kam 7 x 7 pixels ki honi chahiye."
        )

    # Each configuration and image gets a separate output folder.
    output_dir = (
        PROJECT_DIR
        / "results"
        / f"image_{CONFIG_NAME}_{image_name}"
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Building multiplier lookup tables...")
    exact_table, approximate_table = build_lookup_tables()

    print("Running exact 5x5 Sobel...")
    exact_gx, exact_gy, exact_edges = sobel_5x5(
        gray,
        exact_table,
    )

    print("Running approximate 5x5 Sobel...")
    approx_gx, approx_gy, approx_edges = sobel_5x5(
        gray,
        approximate_table,
    )

    gx_error = np.abs(approx_gx - exact_gx)
    gy_error = np.abs(approx_gy - exact_gy)

    raw_gradient_mae = float(
        (np.mean(gx_error) + np.mean(gy_error)) / 2.0
    )

    raw_gradient_maximum_error = int(
        max(np.max(gx_error), np.max(gy_error))
    )

    # Convert before subtracting to avoid unsigned overflow.
    difference = np.abs(
        approx_edges.astype(np.int64)
        - exact_edges.astype(np.int64)
    )

    edge_mae = float(np.mean(difference))

    changed_pixels_percent = float(
        100.0 * np.count_nonzero(difference) / difference.size
    )

    if np.array_equal(exact_edges, approx_edges):
        psnr = float("inf")
    else:
        psnr = float(
            peak_signal_noise_ratio(
                exact_edges,
                approx_edges,
                data_range=255,
            )
        )

    ssim = float(
        structural_similarity(
            exact_edges,
            approx_edges,
            data_range=255,
        )
    )

    difference_x8 = np.clip(
        difference * 8,
        0,
        255,
    ).astype(np.uint8)

    comparison = np.concatenate(
        [
            gray,
            exact_edges,
            approx_edges,
            difference_x8,
        ],
        axis=1,
    )

    save_png(output_dir / "input.png", gray)
    save_png(output_dir / "exact_edges.png", exact_edges)
    save_png(output_dir / "approximate_edges.png", approx_edges)
    save_png(output_dir / "absolute_difference.png", difference)
    save_png(output_dir / "difference_x8.png", difference_x8)
    save_png(output_dir / "comparison.png", comparison)

    np.savez_compressed(
        output_dir / "raw_gradients.npz",
        exact_gx=exact_gx,
        exact_gy=exact_gy,
        approximate_gx=approx_gx,
        approximate_gy=approx_gy,
    )

    metrics = {
        "configuration": CONFIG_NAME,
        "approx_cols": APPROX_COLS,
        "l_cols": L_COLS,
        "experiment": "encoder_only_software_sobel",
        "input_image": (
            str(Path(args.image).resolve())
            if args.image
            else "skimage.data.camera"
        ),
        "width": int(gray.shape[1]),
        "height": int(gray.shape[0]),
        "raw_gradient_mae": raw_gradient_mae,
        "raw_gradient_maximum_error": raw_gradient_maximum_error,
        "edge_image_mae": edge_mae,
        "changed_pixels_percent": changed_pixels_percent,
        "psnr_db": psnr,
        "ssim": ssim,
    }

    with (output_dir / "image_metrics.csv").open(
        "w",
        newline="",
        encoding="utf-8",
    ) as csv_file:
        writer = csv.DictWriter(
            csv_file,
            fieldnames=list(metrics.keys()),
        )
        writer.writeheader()
        writer.writerow(metrics)

    print()
    print(f"Configuration: {CONFIG_LABEL}, encoder-only")
    print(f"Image size: {gray.shape[1]} x {gray.shape[0]}")
    print(f"Raw gradient MAE: {raw_gradient_mae:.6f}")
    print(
        f"Raw gradient maximum error: "
        f"{raw_gradient_maximum_error}"
    )
    print(f"Edge-image MAE: {edge_mae:.6f}")
    print(f"Changed pixels: {changed_pixels_percent:.6f} percent")
    print(f"PSNR: {psnr:.6f} dB")
    print(f"SSIM: {ssim:.6f}")

    print("\nResults saved to:")
    print(output_dir)

    print("\ncomparison.png order:")
    print("Input | Exact edges | Approximate edges | Difference x8")

    print("\nSoftware application experiment only.")
    print(
        "PSNR/SSIM compare against exact Sobel output, "
        "not against a manually labelled edge map."
    )


if __name__ == "__main__":
    main()