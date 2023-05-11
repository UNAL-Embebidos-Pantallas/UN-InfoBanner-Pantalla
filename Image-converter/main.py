from PIL import Image
import numpy as np

# Cargar imagen
img = Image.open('images.jpeg')

# Cambiar tamaño a 96x48
img = img.resize((96, 48))

# Convertir a modo RGB
img = img.convert('RGB')

# Convertir a arreglo de numpy
img_array = np.array(img)

# Redondear valores a los valores posibles de 2 bits
img_array = np.round(img_array / 16) * 64

# Convertir de vuelta a imagen de PIL
img = Image.fromarray(np.uint8(img_array))

# Guardar imagen en formato BMP
img.save('imagen_4bits.bmp')

# Exportar datos a archivo de texto
with open('imagen_2bits.txt', 'w') as f:
    for row in img_array:
        for pixel in row:
            # Obtener valores de cada canal en binario de 2 bits
            r, g, b = format(int(pixel[0] // 64), '02b'), format(int(pixel[1] // 64), '02b'), format(int(pixel[2] // 64), '02b')

            # Escribir valores en archivo de texto en orden R, G, B
            f.write(f"{r}{g}{b} ")
        f.write('\n')
