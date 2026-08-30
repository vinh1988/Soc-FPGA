# Median Filter Hardware Model

This repository contains a beginner-friendly simulation and hardware model for a **3x3 Median Filter** designed for image denoising (removing salt-and-pepper noise).

## Project Overview & Data Flow

```text
Original Image -> Grayscale -> Add Noise -> Export Hex (.hex) -> C Median Filter -> Denoised Hex (.hex) -> Visualization
```

1. **Python Preprocessing**: Converts an input image to 8-bit Grayscale ($128 \times 128$).
2. **Noise Simulation**: Adds salt-and-pepper noise and exports ASCII hex memory data (`.hex`).
3. **C Hardware Model**: Processes hex pixel streams using a hardware-friendly $3 \times 3$ sliding window and 9-element Compare-and-Swap sorting network.
4. **Visualization**: Reconstructs the denoised image from hex data and displays a side-by-side comparison.

---

## File Structure

- `process_image.py`: Python script for image loading, grayscale conversion, adding salt-and-pepper noise, and hex file export/import functions.
- `median_filter.c`: C code modeling FPGA/RTL line buffer sliding window and sorting network logic.
- `run_pipeline.py`: Automated pipeline runner executing Python and C steps end-to-end.
- `output_comparison.png`: Generated side-by-side image comparison result.

---

## Prerequisites

- GCC compiler
- Python 3.x (`numpy`, `pillow`)
- `uv` (optional, recommended package runner)

---

## How to Run

### Option 1: Using `uv` (Recommended)

Run the entire end-to-end pipeline with one command:

```bash
uv run python run_pipeline.py
```

### Option 2: Manual Execution

1. **Generate noisy hex image data:**
   ```bash
   python3 process_image.py
   ```

2. **Compile and run the C Hardware Model:**
   ```bash
   gcc -O2 median_filter.c -o median_filter
   ./median_filter noisy_image.hex denoised_image.hex
   ```

3. **Reconstruct and view final denoised result:**
   ```bash
   python3 run_pipeline.py
   ```

Check `output_comparison.png` to inspect the results!
