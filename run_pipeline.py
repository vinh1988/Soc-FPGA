import os
import numpy as np
from PIL import Image
from process_image import preprocess_image, add_salt_and_pepper_noise, export_image_raw, import_image_raw, create_sample_image

def main():
    width, height = 128, 128
    input_png = "input.png"
    noisy_raw = "noisy_image.raw"
    denoised_raw = "denoised_image.raw"
    
    # 1. Create sample image if missing
    if not os.path.exists(input_png):
        create_sample_image(input_png, width, height)
        
    # 2. Step 1: Preprocess to Grayscale
    print("Step 1: Grayscale Preprocessing...")
    gray_img = preprocess_image(input_png, width, height)
    
    # 3. Step 2: Add Salt-and-Pepper Noise
    print("Step 2: Adding Salt-and-Pepper Noise...")
    noisy_img = add_salt_and_pepper_noise(gray_img, salt_prob=0.03, pepper_prob=0.03)
    export_image_raw(noisy_img, noisy_raw)
    
    # 4. Step 3: Run C Hardware Model
    print("Step 3: Compiling and Running C Median Filter Model...")
    os.system("gcc -O2 median_filter.c -o median_filter")
    ret = os.system(f"./median_filter {noisy_raw} {denoised_raw}")
    if ret != 0:
        print("Error executing C program!")
        return
        
    # 5. Step 4: Import & Visualize Denoised Result
    print("Step 4: Reconstructing and Visualizing Denoised Image...")
    denoised_img = import_image_raw(denoised_raw, height, width)
    
    # Create side-by-side comparison image
    combined_width = width * 3 + 20
    combined_height = height + 40
    
    canvas = Image.new('L', (combined_width, combined_height), color=255)
    
    img_gray = Image.fromarray(gray_img)
    img_noisy = Image.fromarray(noisy_img)
    img_denoised = Image.fromarray(denoised_img)
    
    canvas.paste(img_gray, (0, 30))
    canvas.paste(img_noisy, (width + 10, 30))
    canvas.paste(img_denoised, (width * 2 + 20, 30))
    
    canvas.save("output_comparison.png")
    print("Successfully generated 'output_comparison.png' showing Original, Noisy, and Denoised images!")

if __name__ == "__main__":
    main()
