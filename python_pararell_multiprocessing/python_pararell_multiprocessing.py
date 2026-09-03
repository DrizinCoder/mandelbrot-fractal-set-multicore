import sys
from multiprocessing import Process, Queue
from multiprocessing.shared_memory import SharedMemory


def check_mandelbrot(c: complex, max_iter: int):
    fr = 0.0
    fi = 0.0

    for i in range(max_iter):
        fr2 = fr * fr
        fi2 = fi * fi
        fi = 2.0 * fr * fi + c.imag   
        fr = fr2 - fi2 + c.real        

        if fr * fr + fi * fi > 4.0:
            return (False, complex(fr, fi), i + 1)

    return (True, complex(fr, fi), max_iter)


def mandelbrot_pixel(px: int, py: int,
                     width: int, height: int,
                     min_x: float, max_x: float,
                     min_y: float, max_y: float,
                     max_iter: int) -> int:

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


def worker_mandelbrot_line(shm_name: str, queue: Queue,
                            width: int, height: int,
                            min_x: float, max_x: float,
                            min_y: float, max_y: float,
                            max_iter: int):
    shm = SharedMemory(name=shm_name)
    
    while True:
        py = queue.get()
        if py is None:  # Sinal de parada
            break
            
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
            
            pos = (py * width + px) * 3
            shm.buf[pos]     = r
            shm.buf[pos + 1] = g
            shm.buf[pos + 2] = b
            
    shm.close()


def generate_image_parallel(width: int, height: int,
                            min_x: float, max_x: float,
                            min_y: float, max_y: float,
                            max_iter: int, filename: str,
                            num_processos: int = 4) -> float:

    total_bytes = width * height * 3
    shm = SharedMemory(create=True, size=total_bytes)
    
    queue = Queue()
    for py in range(height):
        queue.put(py)
        
    for _ in range(num_processos):
        queue.put(None)
    
    processos = []
    for _ in range(num_processos):
        p = Process(
            target=worker_mandelbrot_line,
            args=(shm.name, queue, width, height, min_x, max_x, min_y, max_y, max_iter)
        )
        p.start()
        processos.append(p)

    for p in processos:
        p.join()
    
    with open(filename, "wb") as img:
        header = f"P6\n{width} {height}\n255\n"
        img.write(header.encode("ascii"))
        img.write(bytes(shm.buf[:total_bytes]))

    shm.close()
    shm.unlink()

def main():
    if len(sys.argv) < 9:
        print(
            f"Uso: python3 {sys.argv[0]} "
            "<width> <height> <minX> <maxX> <minY> <maxY> <max_iter> <output_filename> [num_processos]"
        )
        sys.exit(1)

    width         = int(sys.argv[1])
    height        = int(sys.argv[2])
    min_x         = float(sys.argv[3])
    max_x         = float(sys.argv[4])
    min_y         = float(sys.argv[5])
    max_y         = float(sys.argv[6])
    max_iter      = int(sys.argv[7])
    filename      = sys.argv[8]
    num_processos = int(sys.argv[9]) if len(sys.argv) > 9 else 4

    print(f"width:         {width}")
    print(f"height:        {height}")
    print(f"minX:          {min_x}")
    print(f"maxX:          {max_x}")
    print(f"minY:          {min_y}")
    print(f"maxY:          {max_y}")
    print(f"max_iter:      {max_iter}")
    print(f"num_processos: {num_processos}")
    print(f"Salvando imagem em: {filename}")

    generate_image_parallel(
        width, height,
        min_x, max_x, min_y, max_y,
        max_iter, filename, num_processos
    )

if __name__ == "__main__":
    main()