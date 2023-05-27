from PIL import Image

# Abrir la imagen y redimensionarla a 96x48 píxeles
image = Image.open('/home/xhapa/Documents/EMBEDDED/Zephyr_Litex/Image-converter/Noload2.jpg')  # Cambia 'ruta_de_tu_imagen.jpg' por la ruta de tu imagen
image = image.resize((96, 48))

# Convertir la imagen a modo RGB
image = image.convert('RGB')

# Obtener los datos de la imagen en formato RGB444 binario
pixel_data = []
for y in range(48):
    for x in range(96):
        r, g, b = image.getpixel((x, y))
        r = (r >> 4) & 0b1111  # Obtener los 4 bits más significativos de cada componente de color
        g = (g >> 4) & 0b1111
        b = (b >> 4) & 0b1111
        rgb444 = (r << 8) | (g << 4) | b  # Combinar los componentes en un solo valor RGB444
        pixel_data.append(rgb444)

# Reorganizar los datos de los píxeles
reordered_data = []
for i in range(0, 2304, 1):
    pixel1 = pixel_data[i]  # Los 12 bits más significativos
    pixel2 = pixel_data[i + 2304]  # Los 12 bits menos significativos
    reordered_data.append((pixel1 << 12) | pixel2)

# Convertir los datos reordenados a formato binario
binary_data = [bin(pixel)[2:].zfill(24) for pixel in reordered_data]

# Crear un archivo de texto para guardar el vector de píxeles reordenado en formato binario
with open('/home/xhapa/Documents/EMBEDDED/Zephyr_Litex/verilog/image.mem', 'w') as file:
    for pixel in binary_data:
        file.write(pixel + '\n')