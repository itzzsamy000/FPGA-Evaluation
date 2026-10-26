<div align="center">

<img src="https://img.shields.io/badge/FPGA-Xilinx%20Vivado-FF6B35?style=for-the-badge&logo=xilinx&logoColor=white"/>
<img src="https://img.shields.io/badge/Language-Verilog%20%7C%20Python-4A90D9?style=for-the-badge&logo=python&logoColor=white"/>
<img src="https://img.shields.io/badge/Device-Zynq%20UltraScale%2B-7B2FBE?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Research-Approximate%20Computing-00C9A7?style=for-the-badge"/>

<br/><br/>

# 🔬 Approximate Radix-4 Booth Multiplier
## FPGA Evaluation &amp; Image Quality Analysis

> **Evaluating approximate Radix-4 Booth encoding multipliers on Xilinx FPGA —**  
> trading arithmetic precision for hardware efficiency, validated through  
> exhaustive error analysis and 5×5 Sobel edge-detection image quality metrics.

<br/>

[![GitHub repo](https://img.shields.io/badge/GitHub-FPGA--Evaluation-181717?style=flat-square&logo=github)](https://github.com/itzzsamy000/FPGA-Evaluation)
[![Stars](https://img.shields.io/github/stars/itzzsamy000/FPGA-Evaluation?style=flat-square&color=FFD700)](https://github.com/itzzsamy000/FPGA-Evaluation/stargazers)

</div>

---

## 📋 Table of Contents

| # | Section |
|---|---------|
| 1 | [🧠 Overview](#-overview) |
| 2 | [🏗️ System Architecture Flowchart](#️-system-architecture-flowchart) |
| 3 | [🔄 Research Methodology Flowchart](#-research-methodology-flowchart) |
| 4 | [⚙️ Multiplier Design Flowchart](#️-multiplier-design-flowchart) |
| 5 | [📊 Key Results](#-key-results) |
| 6 | [🖼️ Visual Results — Sobel Edge Detection](#️-visual-results--sobel-edge-detection) |
| 7 | [🗂️ Repository Structure](#️-repository-structure) |
| 8 | [🚀 Installation & Setup](#-installation--setup) |
| 9 | [▶️ Running the Scripts](#️-running-the-scripts) |
| 10 | [⚠️ Limitations](#️-limitations) |

---

## 🧠 Overview

<div align="center">

| Property | Details |
|----------|---------|
| 🎯 **Goal** | Evaluate approximate Booth multipliers: area vs accuracy trade-off |
| 🔢 **Inputs** | Signed 8-bit × Signed 8-bit → Signed 16-bit output |
| 🏭 **Toolchain** | Xilinx Vivado 2026.1 |
| 💡 **Device** | xczu7ev-ffvc1156-2-e (Zynq UltraScale+) |
| 🐍 **Python** | NumPy · scikit-image · Pillow |
| ✅ **Verification** | Exhaustive — all 65,536 signed input pairs |

</div>

This project implements and evaluates **hybrid approximate Radix-4 Booth multipliers** by replacing exact Booth encoding cells with two approximate variants in the lower-significance columns:

<div align="center">

| Cell | Type | Behaviour |
|------|------|-----------|
| **AR4BE1** | Middle-tier approximation | Drops `×2` selection; treats `±2A` as `±A` |
| **AR4BE2** | Low-tier approximation | Further simplifies; treats `0` case as `±A` |
| **Exact** | Full precision | Standard Radix-4 Booth encoding |

</div>

Three configurations are compared against an **exact CSA baseline**:

<div align="center">

```
┌─────────────┬──────────────────────────────────────────────┐
│ Config      │ Column Split                                 │
├─────────────┼──────────────────────────────────────────────┤
│ Exact CSA   │ All 16 columns exact                         │
│ H10/M0/L6   │ 10 high exact + 6 low AR4BE2                 │
│ H12/M0/L4   │ 12 high exact + 4 low AR4BE2                 │
└─────────────┴──────────────────────────────────────────────┘
```

</div>

---

## 🏗️ System Architecture Flowchart

```mermaid
flowchart TD
    A["🔢 8-bit Signed Inputs\nA[7:0] and B[7:0]"] --> B["Radix-4 Booth Encoder\n(4 encoding groups)"]

    B --> C1["🟢 Row 0\nBits [2:0] of B×2"]
    B --> C2["🟡 Row 1\nBits [4:2] of B×2"]
    B --> C3["🟠 Row 2\nBits [6:4] of B×2"]
    B --> C4["🔴 Row 3\nBits [8:6] of B×2"]

    C1 --> D1{"Column\nType?"}
    C2 --> D2{"Column\nType?"}
    C3 --> D3{"Column\nType?"}
    C4 --> D4{"Column\nType?"}

    D1 -->|"Low cols\n(AR4BE2)"| E1["⚡ AR4BE2\nApprox Cell"]
    D1 -->|"High cols\n(Exact)"| F1["✅ Exact\nBooth Cell"]
    D2 -->|"Low cols"| E2["⚡ AR4BE2\nApprox Cell"]
    D2 -->|"High cols"| F2["✅ Exact\nBooth Cell"]
    D3 --> F3["✅ Exact\nBooth Cell"]
    D4 --> F4["✅ Exact\nBooth Cell"]

    E1 & F1 --> G1["Partial Product\nRow 0  (shift 0)"]
    E2 & F2 --> G2["Partial Product\nRow 1  (shift 2)"]
    F3 --> G3["Partial Product\nRow 2  (shift 4)"]
    F4 --> G4["Partial Product\nRow 3  (shift 6)"]

    G1 & G2 & G3 & G4 --> H["🔗 Carry-Save Array\nCSA Reduction Tree"]
    H --> I["⚡ Carry-Propagate\nFinal Adder"]
    I --> J["📤 16-bit Signed\nProduct Output"]

    style A fill:#4A90D9,color:#fff,stroke:#2c5f8a
    style B fill:#7B2FBE,color:#fff,stroke:#5a1f90
    style H fill:#FF6B35,color:#fff,stroke:#c44e20
    style I fill:#FF6B35,color:#fff,stroke:#c44e20
    style J fill:#00C9A7,color:#fff,stroke:#009f82
    style E1 fill:#e74c3c,color:#fff,stroke:#c0392b
    style E2 fill:#e74c3c,color:#fff,stroke:#c0392b
    style F1 fill:#27ae60,color:#fff,stroke:#1e8449
    style F2 fill:#27ae60,color:#fff,stroke:#1e8449
    style F3 fill:#27ae60,color:#fff,stroke:#1e8449
    style F4 fill:#27ae60,color:#fff,stroke:#1e8449
```

---

## 🔄 Research Methodology Flowchart

```mermaid
flowchart TD
    START(["🚀 Start Research"]) --> A

    A["📐 Design RTL\nVerilog Modules"] --> B["🧪 Simulate\nTestbenches in Vivado"]
    B --> C{"Pass\nAll Tests?"}
    C -->|"❌ No"| A
    C -->|"✅ Yes"| D

    D["🐍 Build Python\nBehavioural Model"] --> E["🔍 Cross-Verify RTL\nvs Python Model\n(65,536 pairs)"]
    E --> F{"Models\nMatch?"}
    F -->|"❌ No"| D
    F -->|"✅ Yes"| G

    G["⚡ Synthesise &\nImplement in Vivado"] --> H["📊 Collect Reports\nTiming · Power · LUTs"]
    H --> I["🖼️ Run Image\nExperiments\n(Python Sobel)"]
    I --> J["📈 Compute Metrics\nPSNR · SSIM · MAE"]
    J --> K["📝 Analyse & Compare\nConfigurations"]
    K --> END(["✅ Results Published"])

    style START fill:#00C9A7,color:#fff,stroke:#009f82
    style END fill:#00C9A7,color:#fff,stroke:#009f82
    style C fill:#FF6B35,color:#fff,stroke:#c44e20
    style F fill:#FF6B35,color:#fff,stroke:#c44e20
    style A fill:#4A90D9,color:#fff,stroke:#2c5f8a
    style D fill:#4A90D9,color:#fff,stroke:#2c5f8a
    style G fill:#7B2FBE,color:#fff,stroke:#5a1f90
    style H fill:#7B2FBE,color:#fff,stroke:#5a1f90
    style I fill:#f39c12,color:#fff,stroke:#c87f0a
    style J fill:#f39c12,color:#fff,stroke:#c87f0a
    style K fill:#27ae60,color:#fff,stroke:#1e8449
```

---

## ⚙️ Multiplier Design Flowchart

```mermaid
flowchart LR
    subgraph INPUT["📥 Input Stage"]
        A["A[7:0]\nSigned 8-bit"]
        B["B[7:0]\nSigned 8-bit"]
    end

    subgraph ENCODE["🧮 Encoding Stage  (Hybrid)"]
        direction TB
        ENC0["Enc Row 0\ncode = B×2[2:0]"]
        ENC1["Enc Row 1\ncode = B×2[4:2]"]
        ENC2["Enc Row 2\ncode = B×2[6:4]"]
        ENC3["Enc Row 3\ncode = B×2[8:6]"]

        subgraph CELLS["Cell Selection per Column"]
            EXACT["✅ Exact Cell\n+A / +2A / −A / −2A / 0"]
            AR4BE2["⚡ AR4BE2\n+A / −A+1 / 0 only"]
        end
    end

    subgraph REDUCE["🔗 Reduction Stage"]
        CSA1["CSA Level 1\n4→2 reduction"]
        FA["Final Adder\nCarry-Propagate"]
    end

    subgraph OUTPUT["📤 Output Stage"]
        P["P[15:0]\nSigned 16-bit Product"]
    end

    A & B --> ENCODE
    ENCODE --> REDUCE
    REDUCE --> OUTPUT

    style INPUT fill:#1a1a2e,color:#4A90D9,stroke:#4A90D9
    style ENCODE fill:#16213e,color:#7B2FBE,stroke:#7B2FBE
    style REDUCE fill:#0f3460,color:#FF6B35,stroke:#FF6B35
    style OUTPUT fill:#1a1a2e,color:#00C9A7,stroke:#00C9A7
    style EXACT fill:#27ae60,color:#fff,stroke:#1e8449
    style AR4BE2 fill:#e74c3c,color:#fff,stroke:#c0392b
```

---

## 📊 Key Results

### ⚡ Hardware & Arithmetic Performance

<div align="center">

| Metric | 🟢 Exact CSA | 🟡 H10/M0/L6 | 🟠 H12/M0/L4 |
|--------|:-----------:|:------------:|:------------:|
| **LUTs** | 74 | **72** ⬇️ | 76 ⬆️ |
| **CARRY8** | 2 | 2 | 2 |
| **Routed delay (ns)** | 6.533 | **6.466** ⚡ | **6.465** ⚡ |
| **Est. dynamic power (mW)** | 20 | 20 | 21 |
| **Error rate (%)** | **0** ✅ | 60.94 ❌ | 42.19 ⚠️ |
| **Mean absolute error** | **0** ✅ | 15.25 | 2.43 |
| **Max absolute error** | **0** ✅ | 125 | 17 |

> All arithmetic metrics cover the complete set of **65,536 signed input pairs (−128 to +127)**.

</div>

### 🖼️ Image Quality (5×5 Sobel, vs. Exact Reference)

<div align="center">

| Image | 🟡 H10 PSNR (dB) | 🟠 H12 PSNR (dB) | 🟡 H10 SSIM | 🟠 H12 SSIM |
|-------|:----------------:|:----------------:|:-----------:|:-----------:|
| 📷 Camera | 33.86 | **50.82** | 0.657 | **0.980** |
| 🌳 Test1 (Tree) | 33.19 | **51.44** | 0.729 | **0.990** |
| 🏙️ Test2 (City) | 33.04 | **48.88** | 0.640 | **0.945** |

> Higher PSNR and SSIM = better image quality (closer to exact output).

</div>

---

## 🖼️ Visual Results — Sobel Edge Detection

> Each comparison strip shows: **Input Image → Exact Sobel → Approximate Sobel → Difference ×8**

---

### 📷 Camera Image

<table>
<tr>
<td align="center"><b>🟡 H10/M0/L6 Configuration</b><br/><sub>PSNR: 33.86 dB · SSIM: 0.657</sub></td>
</tr>
<tr>
<td>

![H10 Camera Comparison](results/image_H10_M0_L6_camera/comparison.png)

</td>
</tr>
<tr>
<td align="center"><b>🟠 H12/M0/L4 Configuration</b><br/><sub>PSNR: 50.82 dB · SSIM: 0.980</sub></td>
</tr>
<tr>
<td>

![H12 Camera Comparison](results/image_H12_M0_L4_camera/comparison.png)

</td>
</tr>
</table>

---

### 🌳 Test1 — Tree Image

<table>
<tr>
<td align="center"><b>🟡 H10/M0/L6 Configuration</b><br/><sub>PSNR: 33.19 dB · SSIM: 0.729</sub></td>
</tr>
<tr>
<td>

![H10 Test1 Comparison](results/image_H10_M0_L6_test1/comparison.png)

</td>
</tr>
<tr>
<td align="center"><b>🟠 H12/M0/L4 Configuration</b><br/><sub>PSNR: 51.44 dB · SSIM: 0.990</sub></td>
</tr>
<tr>
<td>

![H12 Test1 Comparison](results/image_H12_M0_L4_test1/comparison.png)

</td>
</tr>
</table>

---

### 🏙️ Test2 — City Image

<table>
<tr>
<td align="center"><b>🟡 H10/M0/L6 Configuration</b><br/><sub>PSNR: 33.04 dB · SSIM: 0.640</sub></td>
</tr>
<tr>
<td>

![H10 Test2 Comparison](results/image_H10_M0_L6_test2/comparison.png)

</td>
</tr>
<tr>
<td align="center"><b>🟠 H12/M0/L4 Configuration</b><br/><sub>PSNR: 48.88 dB · SSIM: 0.945</sub></td>
</tr>
<tr>
<td>

![H12 Test2 Comparison](results/image_H12_M0_L4_test2/comparison.png)

</td>
</tr>
</table>

---

### 🔬 Python Error Comparison Plot

<div align="center">

![Error Comparison](Script/comparison.png)

*Python model error distribution comparison across multiplier configurations*

</div>

---

## 🗂️ Repository Structure

```
booth_approx_research/
│
├── 📄 booth_approx_research.xpr          ← Vivado project file
│
├── 📁 booth_approx_research.srcs/
│   ├── 📁 sources_1/new/                 ← RTL Design Sources (Verilog)
│   │   ├── ar4be1.v                      ← Approximate encoder 1
│   │   ├── ar4be2.v                      ← Approximate encoder 2
│   │   ├── booth8_cell_exact.v           ← Exact Booth cell
│   │   ├── booth8_hybrid_enc.v           ← Hybrid encoder multiplier
│   │   ├── booth8_hybrid_csa.v           ← Hybrid CSA multiplier
│   │   ├── booth_exact_bit.v             ← Exact bit-level Booth
│   │   ├── sobel5x5_booth.v              ← Sobel (Booth multiply)
│   │   └── sobel5x5_exact_shiftadd.v    ← Sobel exact reference
│   │
│   ├── 📁 sim_1/new/                     ← Testbenches
│   │   ├── tb_ar4be1.v
│   │   ├── tb_ar4be2.v
│   │   ├── tb_booth8_cell_exact.v
│   │   ├── tb_booth8_hybrid_csa.v
│   │   ├── tb_booth8_hybrid_enc.v
│   │   ├── tb_booth8_power.v
│   │   ├── tb_booth_exact_bit.v
│   │   ├── tb_sobel5x5_booth.v
│   │   └── tb_sobel5x5_exact_shiftadd.v
│   │
│   └── 📁 constrs_1/new/                ← Timing Constraints (XDC)
│       ├── booth_timing.xdc
│       └── sobel_timing.xdc
│
├── 📁 Script/                            ← Python Scripts
│   ├── booth_model.py                    ← Behavioural model + error metrics
│   ├── compare_rtl.py                    ← RTL vs Python comparison
│   ├── image_experiment.py               ← Image-quality evaluation
│   └── verify_sobel_shiftadd.py         ← Sobel verification
│
├── 📁 images/                            ← Input Test Images
│   ├── input.png
│   ├── test1.png
│   └── test2.png
│
├── 📁 results/                           ← All Experimental Results
│   ├── CSA_Exact/                        ← Exact baseline reports
│   ├── CSA_H10_M0_L6/                   ← H10 CSA reports
│   ├── CSA_H12_M0_L4/                   ← H12 CSA reports
│   ├── image_H10_M0_L6_*/               ← H10 Sobel image outputs
│   ├── image_H12_M0_L4_*/               ← H12 Sobel image outputs
│   ├── python_model/                     ← Python error CSVs
│   └── timing_synth.rpt                  ← Global timing report
│
└── 📁 docs/
    └── results_summary.md               ← Summary of all results
```

---

## 🚀 Installation & Setup

### Prerequisites

<div align="center">

| Tool | Purpose | Version |
|------|---------|---------|
| 🔴 **Xilinx Vivado** | RTL simulation & synthesis | 2026.1+ |
| 🐍 **Python** | Behavioural model & evaluation | 3.9+ |

</div>

### Python Dependencies

```bash
pip install numpy scikit-image pillow
```

### Clone the Repository

```bash
git clone https://github.com/itzzsamy000/FPGA-Evaluation.git
cd FPGA-Evaluation
```

---

## ▶️ Running the Scripts

### 🐍 Python Behavioural Model

```bash
# Exhaustive error-metric verification (all 65,536 pairs)
python Script/booth_model.py

# RTL vs Python cross-verification
python Script/compare_rtl.py

# 5x5 Sobel image-quality evaluation
python Script/image_experiment.py

# Sobel shift-add verification
python Script/verify_sobel_shiftadd.py
```

### 🔴 Vivado RTL Simulation

```
1. Open  booth_approx_research.xpr  in Vivado
2. Select a testbench from sim_1/new/
   e.g.  tb_booth8_hybrid_enc.v
3. Run Behavioural Simulation
```

### 🔴 Synthesis & Implementation

```
1. Open the project in Vivado
2. Run: Synthesis → Implementation
3. Constraints: constrs_1/new/*.xdc
4. Reports: results/ directory
```

---

## ⚠️ Limitations

<div align="center">

| ⚠️ Limitation | Details |
|--------------|---------|
| 🔌 **Power** | Estimates only — no physical board measurement |
| 💻 **Image processing** | Evaluated in Python software, not on-chip |
| 🖼️ **Images** | Only 3 test images evaluated |
| 📐 **Architecture** | Encoder approximation with exact reduction only |
| 📚 **Publication** | Novelty vs. prior art not formally established |

</div>

---

<div align="center">

**🔬 Research Project · Approximate Computing · FPGA · Booth Multiplier**

<img src="https://img.shields.io/badge/Made%20with-Verilog%20%26%20Python-4A90D9?style=flat-square"/>
<img src="https://img.shields.io/badge/FPGA-Xilinx%20Vivado-FF6B35?style=flat-square"/>
<img src="https://img.shields.io/badge/License-Academic%20Research-00C9A7?style=flat-square"/>

</div>