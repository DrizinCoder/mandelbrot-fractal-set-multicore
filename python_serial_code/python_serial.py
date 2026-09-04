"""
Gerador serial do Conjunto de Mandelbrot – versão Python puro
Espelha fielmente o algoritmo da versão C (image_generator.c / mandelbrot.c).

Uso:
    python3 programa_serial.py <width> <height> <minX> <maxX> <minY> <maxY> <max_iter> <output.ppm>

Exemplo (mesmos parâmetros da versão C):
    python3 programa_serial.py 800 600 -2.5 1.0 -1.25 1.25 256 mandelbrot.ppm
"""

import sys
import math
import time
import struct



# Verificação do conjunto de Mandelbrot
def check_mandelbrot(c: complex, max_iter: int):
    """
    Itera z = z² + c partindo de z = 0.

    Retorna (in_set, fval, iterations) onde:
        in_set     – True se o ponto pertence ao conjunto
        fval       – complex com o valor final de z
        iterations – número de iterações até escapar (ou max_iter se não escapou)
    """
    fr = 0.0
    fi = 0.0

    for i in range(max_iter):
        # z² = (fr + fi·i)² = (fr²-fi²) + (2·fr·fi)·i
        fr2 = fr * fr
        fi2 = fi * fi
        fi = 2.0 * fr * fi + c.imag   # parte imaginária nova
        fr = fr2 - fi2 + c.real        # parte real nova

        if fr * fr + fi * fi > 4.0:
            return (False, complex(fr, fi), i + 1)

    return (True, complex(fr, fi), max_iter)


# Mapeamento pixel
def mandelbrot_pixel(px: int, py: int,
                     width: int, height: int,
                     min_x: float, max_x: float,
                     min_y: float, max_y: float,
                     max_iter: int) -> int:
    """
    Converte as coordenadas do pixel (px, py) para o plano complexo
    e retorna o número de iterações até a fuga (ou max_iter se pertence ao conjunto).
    """
    unidades_largura = max_x - min_x
    unidades_altura  = max_y - min_y

    proporcao_x = px / width   # de 0 a 1
    proporcao_y = py / height  # de 0 a 1

    deslocamento_x = unidades_largura * proporcao_x
    deslocamento_y = unidades_altura  * proporcao_y

    cx = min_x + deslocamento_x
    cy = max_y - deslocamento_y

    c = complex(cx, cy)
    _, _, iterations = check_mandelbrot(c, max_iter)
    
    return iterations

def taylor_series_sin(x: float) -> float:
    PI = 3.141592653589793
    x = x % (2 * PI)
    if x > PI:
        x -= 2 * PI
        
    x3 = x * x * x
    x5 = x3 * x * x
    x7 = x5 * x * x
    x9 = x7 * x * x

    return x - (x3 / 6.0) + (x5 / 120.0) - (x7 / 5040.0) + (x9 / 362880.0)

# Geração da imagem PPM 
def generate_image(width: int, height: int,
                   min_x: float, max_x: float,
                   min_y: float, max_y: float,
                   max_iter: int,
                   filename: str) -> float:
    """
    Gera o conjunto de Mandelbrot e salva no arquivo PPM (P6).
    Retorna o tempo de processamento em segundos.
    """
    with open(filename, "wb") as img:
        # Cabeçalho PPM
        header = f"P6\n{width} {height}\n255\n"
        img.write(header.encode("ascii"))

        # Início da medição de tempo 
        t_start = time.perf_counter()

        for py in range(height):
            linha = bytearray()
            for px in range(width):
                iters = mandelbrot_pixel(
                    px, py, width, height,
                    min_x, max_x, min_y, max_y,
                    max_iter
                )

                if iters == max_iter:
                    r = g = b = 0
                else:
                    tom = int(taylor_series_sin(0.1 * iters) * 127.5 + 127.5)
                    r = g = b = tom

                linha.extend((r, g, b))
            img.write(linha)

        t_end = time.perf_counter()
        # Fim da medição de tempo

    return t_end - t_start

# Ponto de entrada
def main():
    if len(sys.argv) < 9:
        print(
            f"Uso: python3 {sys.argv[0]} "
            "<width> <height> <minX> <maxX> <minY> <maxY> <max_iter> <output_filename>"
        )
        sys.exit(1)

    width    = int(sys.argv[1])
    height   = int(sys.argv[2])
    min_x    = float(sys.argv[3])
    max_x    = float(sys.argv[4])
    min_y    = float(sys.argv[5])
    max_y    = float(sys.argv[6])
    max_iter = int(sys.argv[7])
    filename = sys.argv[8]

    print(f"width:    {width}")
    print(f"height:   {height}")
    print(f"minX:     {min_x}")
    print(f"maxX:     {max_x}")
    print(f"minY:     {min_y}")
    print(f"maxY:     {max_y}")
    print(f"max_iter: {max_iter}")
    print(f"Salvando imagem em: {filename}")

    elapsed = generate_image(
        width, height,
        min_x, max_x, min_y, max_y,
        max_iter, filename
    )

    print(f"Tempo de processamento (perf_counter): {elapsed:.6f} segundos")


if __name__ == "__main__":
    main()
