#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include "complex.h"
#include "mandelbrot.h"
#include <omp.h>

int main(int argc, char *argv[]) {
    if (argc < 9) {
        printf("Uso: %s <width> <height> <minX> <maxX> <minY> <maxY> <max_iter> <output_filename>\n", argv[0]);
        return 1;
    }

    omp_set_num_threads(4);

    int width = atoi(argv[1]);
    printf("width: %d\n", width);
    int height = atoi(argv[2]);
    printf("height: %d\n", height);
    double minX = atof(argv[3]);
    printf("minX: %f\n", minX);
    double maxX = atof(argv[4]);
    printf("maxX: %f\n", maxX);
    double minY = atof(argv[5]);
    printf("minY: %f\n", minY);
    double maxY = atof(argv[6]);
    printf("maxY: %f\n", maxY);
    int max_iter = atoi(argv[7]);
    printf("max_iter: %d\n", max_iter);
    char *filename = argv[8];

    FILE *file_image = fopen(filename, "wb");
    unsigned char *image = (unsigned char *) malloc(width * height * 3 * sizeof(unsigned char));
    if (!image) { perror("malloc"); return 1; }
    
    if (!file_image) {
        perror("Erro ao abrir arquivo");
        return 1;
    }
    printf("Salvando imagem em: %s\n", filename);

    fprintf(file_image, "P6\n%d %d\n255\n", width, height);

    // --- Medição interna de tempo (clock_gettime) ---
    struct timespec t_start, t_end;
    clock_gettime(CLOCK_MONOTONIC, &t_start);

    double unidades_largura = maxX - minX;
    double unidades_altura  = maxY - minY;

    #pragma omp parallel for schedule(dynamic, 1)
    for (int py = 0; py < height; py++) {
        double proporcao_y          = py / (double)height;
        double enquadramento_eixo_y = maxY - (unidades_altura * proporcao_y);

        for (int px = 0; px < width; px++) {
            double proporcao_x          = px / (double)width;
            double enquadramento_eixo_x = minX + (unidades_largura * proporcao_x);

            Complex_number c = {enquadramento_eixo_x, enquadramento_eixo_y};
            Mandelbrot_check_return result = check_mandelbrot(c, max_iter);

            unsigned char r, g, b;

            if (result.iterations_to_scape == max_iter) {
                r = g = b = 0;
            } else {
                unsigned char tom = (unsigned char)(sin(0.1 * result.iterations_to_scape) * 127.5 + 127.5);
                r = g = b = tom;
            }

            int idx = (py * width + px) * 3;
            image[idx + 0] = r;
            image[idx + 1] = g;
            image[idx + 2] = b;
        }
    }

    fwrite(image, sizeof(unsigned char), width * height * 3, file_image);
    free(image);
    fclose(file_image);   // ← você esqueceu isso também

    clock_gettime(CLOCK_MONOTONIC, &t_end);
    double elapsed = (t_end.tv_sec - t_start.tv_sec) +
                     (t_end.tv_nsec - t_start.tv_nsec) / 1e9;
    printf("Tempo de processamento (clock_gettime): %.6f segundos\n", elapsed);
    // -------------------------------------------------

    return 0;
}
