#include <stdio.h>
#include <omp.h>
#include <stdlib.h>

#define N 1000000

int main() {

    int i;
    double *a = (double *) malloc(N * sizeof(double));
    double *b = (double *) malloc(N * sizeof(double));
    double *c = (double *) malloc(N * sizeof(double));

    omp_set_num_threads(4);

    for (i = 0; i < N; i++) {
        a[i] = i * 1.0;
        b[i] = i * 2.0;
    }

    #pragma omp parallel for
    for (i = 0; i < N; i++) {
        c[i] = a[i] + b[i];
    }

    printf("Primeiro elemento: %f, Último elemento: %f\n", c[0], c[N-1]);
    
    free(a);free(b);free(c);

    return 0;
}