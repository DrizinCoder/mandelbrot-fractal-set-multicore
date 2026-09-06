# Makefile para facilitar a execução dos testes com Multiprocessing em Python

# Parâmetros padrão do fractal de Mandelbrot
WIDTH = 800
HEIGHT = 600
MIN_X = -2.0
MAX_X = 1.0
MIN_Y = -1.0
MAX_Y = 1.0
MAX_ITER = 1000
OUTPUT = output.ppm

# Script Python
SCRIPT = python_pararell_multiprocessing.py

# Comando base para execução e medição de tempo
CMD_TIME = /usr/bin/time -v
PYTHON = python3

.PHONY: test_all test1 test2 test4 test8 clean

# Testa todas as variações de processos (1, 2, 4 e 8)
measure_time: test1 test2 test4 test8

# Teste com 1 processo (Sequencial Base)
test1:
	@echo "\n=== Executando com 1 processo ==="
	$(CMD_TIME) $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(OUTPUT) 1

# Teste com 2 processos
test2:
	@echo "\n=== Executando com 2 processos ==="
	$(CMD_TIME) $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(OUTPUT) 2

# Teste com 4 processos
test4:
	@echo "\n=== Executando com 4 processos ==="
	$(CMD_TIME) $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(OUTPUT) 4

# Teste com 8 processos
test8:
	@echo "\n=== Executando com 8 processos ==="
	$(CMD_TIME) $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(OUTPUT) 8

# Remove o arquivo de imagem gerado
clean:
	rm -f $(OUTPUT)
