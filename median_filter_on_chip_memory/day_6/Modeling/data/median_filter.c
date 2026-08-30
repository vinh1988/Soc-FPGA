#include <stdio.h>
#include <stdlib.h>

#define WIDTH  128
#define HEIGHT 128
#define KERNEL_SIZE 3
#define WINDOW_ELEMENTS (KERNEL_SIZE * KERNEL_SIZE)

/**
 * Hardware-friendly 9-element Sorting Network / Bubble Sort
 * In RTL/FPGA, this can be mapped into a pipeline of compare-and-swap (CAS) units.
 */
unsigned char median_sort9(unsigned char window[9]) {
    unsigned char arr[9];
    for (int i = 0; i < 9; i++) {
        arr[i] = window[i];
    }
    
    // Bubble sort algorithm (equivalent to combinational Compare-and-Swap stages)
    for (int i = 0; i < 9 - 1; i++) {
        for (int j = 0; j < 9 - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                // Swap logic (Compare-And-Swap unit in hardware)
                unsigned char temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
    // The median value is the middle element (index 4)
    return arr[4];
}

/**
 * Models 2D Sliding Window Memory (Line Buffers) & Median Filtering.
 * In FPGA/RTL:
 *  - Input stream provides 1 pixel per clock cycle.
 *  - 2 Line Buffers store previous rows to create 3x3 window dynamically.
 */
void median_filter_hardware_model(
    const unsigned char input_img[HEIGHT][WIDTH],
    unsigned char output_img[HEIGHT][WIDTH]
) {
    // Process pixel-by-pixel, simulating line buffers & sliding window
    for (int r = 0; r < HEIGHT; r++) {
        for (int c = 0; c < WIDTH; c++) {
            
            // Handle boundary conditions (Zero Padding or Copy border)
            if (r == 0 || r == HEIGHT - 1 || c == 0 || c == WIDTH - 1) {
                output_img[r][c] = input_img[r][c]; // Border pixels copied directly
                continue;
            }

            // Extract 3x3 window around (r, c)
            unsigned char window[9];
            int idx = 0;
            for (int kr = -1; kr <= 1; kr++) {
                for (int kc = -1; kc <= 1; kc++) {
                    window[idx++] = input_img[r + kr][c + kc];
                }
            }

            // Perform median selection (Hardware Sorting Unit)
            output_img[r][c] = median_sort9(window);
        }
    }
}

int main(int argc, char *argv[]) {
    const char *input_filename = "noisy_image.hex";
    const char *output_filename = "denoised_image.hex";

    if (argc > 1) input_filename = argv[1];
    if (argc > 2) output_filename = argv[2];

    // Allocate memory for image buffers
    unsigned char (*input_img)[WIDTH] = malloc(HEIGHT * WIDTH);
    unsigned char (*output_img)[WIDTH] = malloc(HEIGHT * WIDTH);

    if (!input_img || !output_img) {
        fprintf(stderr, "Error: Memory allocation failed.\n");
        return 1;
    }

    // Read noisy input hex image data
    FILE *fin = fopen(input_filename, "r");
    if (!fin) {
        fprintf(stderr, "Error: Cannot open input file %s\n", input_filename);
        free(input_img);
        free(output_img);
        return 1;
    }

    int read_count = 0;
    for (int r = 0; r < HEIGHT; r++) {
        for (int c = 0; c < WIDTH; c++) {
            unsigned int pixel_val;
            if (fscanf(fin, "%x", &pixel_val) == 1) {
                input_img[r][c] = (unsigned char)pixel_val;
                read_count++;
            }
        }
    }
    fclose(fin);

    if (read_count != HEIGHT * WIDTH) {
        fprintf(stderr, "Error: Read incomplete hex data (%d elements, expected %d).\n", read_count, HEIGHT * WIDTH);
        free(input_img);
        free(output_img);
        return 1;
    }

    printf("[C Hardware Model] Processing %dx%d image using 3x3 Median Filter...\n", WIDTH, HEIGHT);

    // Apply Median Filter hardware model
    median_filter_hardware_model(input_img, output_img);

    // Write denoised hex image data
    FILE *fout = fopen(output_filename, "w");
    if (!fout) {
        fprintf(stderr, "Error: Cannot open output file %s\n", output_filename);
        free(input_img);
        free(output_img);
        return 1;
    }

    for (int r = 0; r < HEIGHT; r++) {
        for (int c = 0; c < WIDTH; c++) {
            fprintf(fout, "%02X\n", output_img[r][c]);
        }
    }
    fclose(fout);

    printf("[C Hardware Model] Saved denoised image to %s\n", output_filename);

    free(input_img);
    free(output_img);
    return 0;
}
