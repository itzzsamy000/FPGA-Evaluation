# Approximate Radix-4 Booth Multiplier: Results

## Experimental setup
- Signed 8-bit inputs and signed 16-bit output
- Vivado 2026.1
- FPGA: xczu7ev-ffvc1156-2-e
- Carry-save reduction architecture
- Same timing constraints across configurations

## Hardware and arithmetic results

| Metric | Exact CSA | H10/M0/L6 | H12/M0/L4 |
|---|---:|---:|---:|
| LUTs | 74 | 72 | 76 |
| CARRY8 | 2 | 2 | 2 |
| Routed delay (ns) | 6.533 | 6.466 | 6.465 |
| Estimated dynamic power (mW) | 20 | 20 | 21 |
| Estimated total on-chip power (W) | 0.612 | 0.612 | 0.612 |
| Arithmetic error rate (%) | 0 | 60.937500 | 42.187500 |
| Arithmetic MAE | 0 | 15.251465 | 2.429688 |
| Maximum absolute arithmetic error | 0 | 125 | 17 |

Arithmetic metrics cover all 65,536 signed input pairs.
Approximate results were checked against Python models per input.

## Software 5x5 Sobel results

PSNR and SSIM use the exact Sobel output as the reference.

| Image | H10 PSNR (dB) | H12 PSNR (dB) | H10 SSIM | H12 SSIM |
|---|---:|---:|---:|---:|
| Camera | 33.855322 | 50.822072 | 0.656578 | 0.979787 |
| Test1 | 33.187618 | 51.440885 | 0.728962 | 0.989989 |
| Test2 | 33.036493 | 48.882936 | 0.640461 | 0.945286 |

## Findings
- H10 used two fewer LUTs than exact CSA, with arithmetic error.
- H12 used four more LUTs than H10 and gave better quality
  on all three tested images.
- H10 and H12 had practically identical routed delays.
- The current power estimates do not establish power savings.

## Limitations
- Power values are estimates, not physical board measurements.
- RTL SAIF used shared random inputs updated every 10 ns.
- Approximately 55% of design nets were directly annotated;
  Vivado estimated activity for the remaining nets.
- Reported power values are rounded.
- Timing results represent individual implementation runs.
- Image processing was evaluated in software, not on FPGA.
- Only three images were evaluated.
- This implements encoder approximation with exact reduction;
  it is not a complete reproduction of the reference paper.
- Publication novelty has not been established.