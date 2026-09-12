# Paralelismo com Memória Compartilhada - Mandelbrot

Este repositório contém a implementação do algoritmo do Conjunto de Mandelbrot em cinco diferentes versões, com o objetivo de analisar e comparar o desempenho entre linguagens compiladas (C) e interpretadas (Python), bem como as diferenças entre execução serial e paralela (memória compartilhada).

## Versões Implementadas

O projeto inclui as 5 abordagens exigidas pelo trabalho:
1. **C Serial**: Implementação base compilada com `-O2`.
2. **C Paralelo (OpenMP)**: Paralelização via diretivas OpenMP.
3. **Python Serial**: Implementação puramente em Python (sem bibliotecas externas).
4. **Python Paralelo (Multithreading)**: Concorrência em Python gerenciada via threads.
5. **Python Paralelo (Multiprocessing)**: Paralelismo real burlando as restrições do GIL do Python via processos.

## Executando as Análises

O projeto foi configurado com um `Makefile` unificado e um script bash que executam todas as baterias de testes e profiling de forma automatizada, garantindo a reprodutibilidade exigida.

Para rodar **todas** as análises de uma vez, basta executar:

```bash
./run_all.sh
```

Alternativamente, você pode rodar os testes isolados usando os comandos do `make`:

```bash
make analyze-c-serial
make analyze-c-parallel
make python-serial
make python-parallel-multithreading
make python-parallel-multiprocessing
```

## O Que Está Sendo Analisado?

A execução do `run_all.sh` gera uma pasta `reports/$(MACHINE_NAME)/` contendo os resultados para os testes solicitados, cumprindo rigorosamente os requisitos do trabalho:

### Medição de Tempo e Escalabilidade (Todas as versões)
Utilizamos o utilitário `/usr/bin/time -v` para medir:
- **Wall-clock time** (tempo real de execução)
- **User / System time** (modo usuário vs kernel)
- **Maximum resident set size** (consumo de memória RAM)
- **Context switches / Page faults**
- *Para as versões paralelas, os testes de escalabilidade são feitos utilizando 1, 2, 4 e 8 threads/processos (via variáveis de ambiente ou argumentos).*

### Profiling do C Serial e Paralelo
- **gprof**: Para identificar as funções hotspot do programa através de amostragem de chamadas (versão serial).
- **perf stat**: Contabiliza eventos de hardware, como ciclos de CPU, IPC, `cache-misses` e `branch-misses`. No C Paralelo, avaliamos também o aumento de migrations/context switches.
- **perf record & report**: Coleta o call graph estatístico para identificar não só os gargalos seriais, mas também o overhead provocado pelas funções internas do OpenMP (como `GOMP_parallel`).
- **Valgrind (Callgrind / Cachegrind)**: Ferramentas de análise detalhada das instruções executadas, falhas de cache L1 e LLC (localidade espacial e temporal).
- **strace**: Contagem das chamadas de sistema (syscalls) e tempo em kernel mode.

### Profiling do Python (Serial e Paralelo)
- **cProfile**: Profiling nativo do Python usado para monitorar o tempo cumulativo de chamadas de funções. Útil para comparar com o `gprof` do C e identificar gargalos.
- **perf stat & record**: Análise análoga à do C, mas voltada para monitorar a execução das operações virtuais e identificar possíveis contenções do **GIL (Global Interpreter Lock)** no caso de uso de threads (ex: funções `_PyEval_EvalFrameDefault`, `PyThread_acquire_lock`).
- **strace**: Medição das syscalls adicionais feitas pelo interpretador Python no startup e nas serializações de processos/memória partilhada.

## Estrutura de Diretórios
- `build/`: Binários em C gerados na compilação.
- `pictures/`: Imagens fractais (.ppm) geradas por cada versão, assegurando que as saídas e cálculos estejam sempre consistentes entre execuções.
- `reports/`: Contém os relatórios gerados por todas as ferramentas (time, perf, gprof, cprofile, etc), organizados por versão e máquina analisada.
