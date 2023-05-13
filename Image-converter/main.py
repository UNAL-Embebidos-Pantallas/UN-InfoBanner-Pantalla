from PIL import Image
import numpy as np

# Load image
img = Image.open('/home/xhapa/Documents/EMBEDDED/Zephyr_Litex/Image-converter/images.png')

# Resize image to 96x48
img = img.resize((96, 48))
rows = int(48/2)
cols = 96

# Convert to RGB mode
img = img.convert("RGB")

# Convert to numpy array
img_array = np.array(img)

# Create Image object from numpy array
img_out = Image.fromarray(img_array)

# Save image as .bmp
img_out.save('Image-converter/output.bmp')

# Scale RGB values to 4 bits (range 0-15)
img_array_444 = np.round(img_array * 15/255).astype(np.uint8)

# Create text file
with open('Image-converter/output.txt', 'w') as f:
    # Iterate over each row and column of the image
    for idx in range(rows):
        for px_idx in range(cols):
            # Scale R, G, B values to 4 bits and convert to binary format
            r_bin = bin(img_array_444[idx][px_idx][0])[2:].zfill(4)
            g_bin = bin(img_array_444[idx][px_idx][1])[2:].zfill(4)
            b_bin = bin(img_array_444[idx][px_idx][2])[2:].zfill(4)
            r2_bin = bin(img_array_444[idx+rows][px_idx][0])[2:].zfill(4)
            g2_bin = bin(img_array_444[idx+rows][px_idx][1])[2:].zfill(4)
            b2_bin = bin(img_array_444[idx+rows][px_idx][2])[2:].zfill(4)

            # Write R, G, B values to a line concatenated with a space
            f.write(f"{r_bin}{g_bin}{b_bin}{r2_bin}{g2_bin}{b2_bin}\n")
