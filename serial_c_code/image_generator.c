#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include "complex.h"
#include "mandelbrot.h"

int mandelbrot(int px, int py, int width, int height, double minX, double maxX, double minY, double maxY, int max_iter) {
    Complex_number c;

    double unidades_largura = maxX - minX; // Quantidade de unidades de largura do plano
    double unidades_altura = maxY - minY; // Quantidade de unidades de altura do plano

    double proporcao_x = (px / (double)width); // De 0 a 1
    double proporcao_y = (py / (double)height); // De 0 a 1

    // Multiplica a proporção pelo tamanho total do plano matemático
    double deslocamento_x = unidades_largura * proporcao_x; 
    double deslocamento_y = unidades_altura * proporcao_y;

    // Soma o ponto de início (minX) para o X, mas subtrai do topo (maxY) para o Y
    double enquadramento_eixo_x = minX + deslocamento_x;
    double enquadramento_eixo_y = maxY - deslocamento_y;

    // Número complexo que será calculado
    c = (Complex_number){enquadramento_eixo_x, enquadramento_eixo_y};

    Mandelbrot_check_return result = check_mandelbrot(c, max_iter);
    
    int iter = result.iterations_to_scape;

    return iter;
}

int main(int argc, char *argv[]) {
    if (argc < 9) {
        printf("Uso: %s <width> <height> <minX> <maxX> <minY> <maxY> <max_iter> <output_filename>\n", argv[0]);
        return 1;
    }

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
    if (!file_image) {
        perror("Erro ao abrir arquivo");
        return 1;
    }
    printf("Salvando imagem em: %s\n", filename);

    fprintf(file_image, "P6\n%d %d\n255\n", width, height);

    // --- Medição interna de tempo (clock_gettime) ---
    struct timespec t_start, t_end;
    clock_gettime(CLOCK_MONOTONIC, &t_start);

    for (int py = 0; py < height; py++) {

         for (int px = 0; px < width; px++) {

            int iter = mandelbrot(px, py, width, height, minX, maxX, minY, maxY, max_iter);
           
            unsigned char r, g, b;

            //  dentro do limite (faz parte do conjunto)
            if (iter == max_iter) { 
                r = g = b = 0;
            } 
            // fora do limite (não faz parte do conjunto)
            else {
                double iterm = iter / (double)max_iter;
                
                unsigned char tom = (unsigned char)(sin(0.1 * iter) * 127.5 + 127.5);
                r = g = b = tom;
            }       

            fputc(r, file_image);
            fputc(g, file_image);
            fputc(b, file_image);
         }
    }

    clock_gettime(CLOCK_MONOTONIC, &t_end);
    double elapsed = (t_end.tv_sec - t_start.tv_sec) +
                     (t_end.tv_nsec - t_start.tv_nsec) / 1e9;
    printf("Tempo de processamento (clock_gettime): %.6f segundos\n", elapsed);
    // -------------------------------------------------

    fclose(file_image);
    return 0;
}
