from PIL import Image

# Abrir la imagen y redimensionarla a 96x48 píxeles
image = Image.open('/home/xhapa/Documents/EMBEDDED/Zephyr_Litex/Image-converter/Noload2.jpg')  # Cambia 'ruta_de_tu_imagen.jpg' por la ruta de tu imagen
image = image.resize((96, 48))

# Convertir la imagen a modo RGB
image_rgb444 = image.convert('RGB')
image_rgb222 = image.convert('RGB')

# Obtener los datos de la imagen en formato RGB444 binario
pixel_data_rgb444 = []
for y in range(48):
    for x in range(96):
        r, g, b = image_rgb444.getpixel((x, y))
        r = (r >> 4) & 0b1111  # Obtener los 4 bits más significativos de cada componente de color
        g = (g >> 4) & 0b1111
        b = (b >> 4) & 0b1111
        rgb444 = (r << 8) | (g << 4) | b  # Combinar los componentes en un solo valor RGB444
        pixel_data_rgb444.append(rgb444)

# Reorganizar los datos de los píxeles para RGB444
reordered_data_rgb444 = []
for i in range(0, 2304, 1):
    pixel1 = pixel_data_rgb444[i]  # Los 12 bits más significativos
    pixel2 = pixel_data_rgb444[i + 2304]  # Los 12 bits menos significativos
    reordered_data_rgb444.append((pixel1 << 12) | pixel2)

# Convertir los datos reordenados a formato binario para RGB444
binary_data_rgb444 = [bin(pixel)[2:].zfill(24) for pixel in reordered_data_rgb444]

# Guardar el vector de píxeles reordenado en formato binario para RGB444
with open('vector24_pixeles_rgb444.txt', 'w') as file_rgb444:
    for pixel in binary_data_rgb444:
        file_rgb444.write(pixel + '\n')

# Obtener los datos de la imagen en formato RGB222 binario
pixel_data_rgb222 = []
for y in range(48):
    for x in range(96):
        r, g, b = image_rgb222.getpixel((x, y))
        r = (r >> 6) & 0b11  # Obtener los 2 bits más significativos de cada componente de color
        g = (g >> 6) & 0b11
        b = (b >> 6) & 0b11
        rgb222 = (r << 4) | (g << 2) | b  # Combinar los componentes en un solo valor RGB222
        pixel_data_rgb222.append(rgb222)

# Reorganizar los datos de los píxeles para RGB222
reordered_data_rgb222 = []
for i in range(0, 2304, 1):
    pixel1 = pixel_data_rgb222[i]  # Los 6 bits más significativos
    pixel2 = pixel_data_rgb222[i + 2304]  # Los 6 bits menos significativos
    reordered_data_rgb222.append((pixel1 << 6) | pixel2)

# Convertir los datos reordenados a formato binario para RGB222
binary_data_rgb222 = [bin(pixel)[2:].zfill(12) for pixel in reordered_data_rgb222]

# Guardar el vector de píxeles reordenado en formato binario para RGB222
with open('/home/xhapa/Documents/EMBEDDED/Zephyr_Litex/verilog/image.mem', 'w') as file_rgb222:
    for pixel in binary_data_rgb222:
        file_rgb222.write(pixel + '\n')