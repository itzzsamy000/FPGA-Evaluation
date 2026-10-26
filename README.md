# Approximate Radix-4 Booth Multiplier: FPGA Evaluation

> A research project evaluating approximate Radix-4 Booth encoding multiplier designs on Xilinx FPGA, including hardware resource usage, arithmetic error metrics, and image-quality evaluation via Sobel edge detection.

---

## Overview

This project implements and evaluates **hybrid approximate Radix-4 Booth multipliers** targeting 8-bit signed inputs. It explores the trade-offs between hardware efficiency (LUT count, timing) and arithmetic accuracy when replacing exact Booth encoding cells with two approximate variants:

- **AR4BE1** – Approximate Radix-4 Booth Encoder 1 (middle accuracy tier)
- **AR4BE2** – Approximate Radix-4 Booth Encoder 2 (lower accuracy tier)

Three multiplier configurations are compared against an exact Carry-Save Array (CSA) baseline:

| Configuration | Description |
|---|---|
| Exact CSA | Fully exact Booth multiplier with CSA reduction |
| H10/M0/L6 | 10 high exact bits, 6 low AR4BE2 bits |
| H12/M0/L4 | 12 high exact bits, 4 low AR4BE2 bits |

---

## Features

- Signed 8×8 Booth multiplier RTL in Verilog (synthesisable)
- Approximate encoder cells: AR4BE1 and AR4BE2
- Hybrid multiplier: configurable exact / approximate column split
- 5×5 Sobel edge-detection core implemented with approximate Booth multiplication
- Exact 5×5 Sobel shift-add reference implementation
- Python behavioural model for exhaustive error-metric verification
- RTL–Python cross-verification across all 65,536 signed input pairs
- Image-quality evaluation (PSNR / SSIM) on three test images
- Timing constraints (XDC) and post-route timing reports

---

## Technology Stack

| Layer | Technology |
|---|---|
| Hardware Description | Verilog (RTL) |
| FPGA Toolchain | Xilinx Vivado 2026.1 |
| Target Device | xczu7ev-ffvc1156-2-e (Zynq UltraScale+) |
| Behavioural Model | Python 3, NumPy |
| Image Evaluation | Python 3, scikit-image, Pillow |

---

## Repository Structure

```
booth_approx_research/
├── booth_approx_research.xpr          # Vivado project file
├── booth_approx_research.srcs/
│   ├── sources_1/new/                 # RTL design sources (Verilog)
│   │   ├── ar4be1.v                   # Approximate encoder 1
│   │   ├── ar4be2.v                   # Approximate encoder 2
│   │   ├── booth8_cell_exact.v        # Exact Booth cell
│   │   ├── booth8_hybrid_enc.v        # Hybrid encoder multiplier
│   │   ├── booth8_hybrid_csa.v        # Hybrid CSA multiplier
│   │   ├── booth_exact_bit.v          # Exact bit-level Booth
│   │   ├── sobel5x5_booth.v           # Sobel using Booth multiplication
│   │   └── sobel5x5_exact_shiftadd.v  # Exact Sobel reference
│   ├── sim_1/new/                     # Testbenches
│   └── constrs_1/new/                 # Timing constraints (XDC)
├── Script/                            # Python scripts
│   ├── booth_model.py                 # Behavioural model + error metrics
│   ├── compare_rtl.py                 # RTL vs Python comparison
│   ├── image_experiment.py            # Image-quality evaluation
│   └── verify_sobel_shiftadd.py       # Sobel shift-add verification
├── images/                            # Test images for evaluation
│   ├── input.png
│   ├── test1.png
│   └── test2.png
├── results/                           # Experimental results
│   └── timing_synth.rpt               # Post-route timing report
└── docs/
    └── results_summary.md             # Summary of hardware & image results
```

---

## Key Results

### Hardware & Arithmetic

| Metric | Exact CSA | H10/M0/L6 | H12/M0/L4 |
|---|---:|---:|---:|
| LUTs | 74 | 72 | 76 |
| CARRY8 | 2 | 2 | 2 |
| Routed delay (ns) | 6.533 | 6.466 | 6.465 |
| Arithmetic error rate (%) | 0 | 60.94 | 42.19 |
| Mean absolute error | 0 | 15.25 | 2.43 |
| Maximum absolute error | 0 | 125 | 17 |

### Image Quality (5×5 Sobel, vs. exact reference)

| Image | H10 PSNR (dB) | H12 PSNR (dB) | H10 SSIM | H12 SSIM |
|---|---:|---:|---:|---:|
| Camera | 33.86 | 50.82 | 0.657 | 0.980 |
| Test1 | 33.19 | 51.44 | 0.729 | 0.990 |
| Test2 | 33.04 | 48.88 | 0.640 | 0.945 |

---

## Installation & Setup

### Prerequisites

- **Xilinx Vivado 2026.1** (or compatible version) for RTL simulation and synthesis
- **Python 3.9+** for behavioural modelling and image evaluation

### Python dependencies

```bash
pip install numpy scikit-image pillow
```

### Clone the repository

```bash
git clone https://github.com/itzzsamy000/FPGA-Evaluation.git
cd FPGA-Evaluation
```

---

## Running the Python Model

```bash
# Exhaustive error-metric verification across all 65,536 input pairs
python Script/booth_model.py

# RTL vs Python cross-verification
python Script/compare_rtl.py

# Image-quality evaluation
python Script/image_experiment.py

# Sobel shift-add verification
python Script/verify_sobel_shiftadd.py
```

---

## Running RTL Simulation (Vivado)

1. Open `booth_approx_research.xpr` in Vivado.
2. Select a testbench from `sim_1/new/` (e.g., `tb_booth8_hybrid_enc.v`).
3. Run behavioural simulation.

---

## Synthesis & Implementation (Vivado)

1. Open the project in Vivado.
2. Run **Synthesis → Implementation**.
3. Timing constraints are in `constrs_1/new/` (`.xdc` files).
4. Post-route timing report is available at `results/timing_synth.rpt`.

---

## Limitations

- Power values are Vivado estimates, not physical board measurements.
- Image processing was evaluated in software (Python), not on FPGA hardware.
- Only three test images were evaluated.
- This implements encoder approximation with exact reduction; it is not a full reproduction of any reference paper.
- Publication novelty has not been established.

---

## License

This project is for academic research purposes.

---

## Author

Research project on approximate computing for FPGA — Booth multiplier approximation study.