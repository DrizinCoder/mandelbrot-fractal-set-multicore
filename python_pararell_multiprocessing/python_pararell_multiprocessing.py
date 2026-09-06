import sys
import time
from multiprocessing import Process, Queue, set_start_method
from multiprocessing.shared_memory import SharedMemory


def check_mandelbrot(cx, cy, max_iter: int):
    fr = 0.0
    fi = 0.0


    for i in range(max_iter):
        fr2 = fr * fr
        fi2 = fi * fi
        
        if fr2 + fi2 > 4.0:
                return i+1

        fi = 2.0 * fr * fi + cy  
        fr = fr2 - fi2 + cx        

    return max_iter


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

    iterations = check_mandelbrot(cx, cy, max_iter)
    
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
                            max_iter: int, color_table):
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
            
            tom = color_table[iters]
            r = g = b = tom
            
            pos = (py * width + px) * 3
            shm.buf[pos]     = r
            shm.buf[pos + 1] = g
            shm.buf[pos + 2] = b
            
    shm.close()


def generate_image_parallel(width: int, height: int,
                            min_x: float, max_x: float,
                            min_y: float, max_y: float,
                            max_iter: int, filename: str, color_table,
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
            args=(shm.name, queue, width, height, min_x, max_x, min_y, max_y, max_iter, color_table)
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



    color_table = []
    for i in range(max_iter + 1):
        if i == max_iter:
            color_table.append(0)
        else:
            color_table.append(int(taylor_series_sin(0.1 * i) * 127.5 + 127.5))

    start_time = time.perf_counter()

    generate_image_parallel(
        width, height,
        min_x, max_x, min_y, max_y,
        max_iter, filename, color_table, num_processos
    )

    end_time = time.perf_counter()
    elapsed_time = end_time - start_time

    print(f"Tempo de processamento (perf_counter): {elapsed_time:.4f} segundos\n")

if __name__ == "__main__":
    try:
        set_start_method('fork')
    except RuntimeError:
        pass
    main()