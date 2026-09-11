# Makefile para facilitar a execução dos testes com Multiprocessing em Python

MACHINE_NAME := $(shell hostname)
TIMESTAMP    := $(shell date +%Y%m%d_%H%M%S)

# Parâmetros padrão do fractal de Mandelbrot
WIDTH = 15360
HEIGHT = 10240
MIN_X = -2.0
MAX_X = 1.0
MIN_Y = -1.0
MAX_Y = 1.0
MAX_ITER = 250

# Diretórios de saída
REPORTS_DIR = ../../reports/$(MACHINE_NAME)/python_multiprocessing
PICTURES_DIR = ../../pictures/$(MACHINE_NAME)

# Script Python
SCRIPT = python_pararell_multiprocessing.py

# Comando base para execução e medição de tempo
CMD_TIME = /usr/bin/time -v
PYTHON = python3

.PHONY: test_all test1 test2 test4 test8 clean run_analysis profile_cprofile profile_perf_stat profile_perf_record system_info init_dirs run_all

init_dirs:
	@mkdir -p $(REPORTS_DIR)
	@mkdir -p $(PICTURES_DIR)

# Roda tanto a medição de tempo quanto as análises
run_all: measure_time run_analysis

# Testa todas as variações de processos (1, 2, 4 e 8)
measure_time: init_dirs test1 test2 test4 test8
	@echo "\n--> Tempos de execução salvos em '$(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt'"

# Teste com 1 processo (Sequencial Base)
test1: init_dirs
	@echo "\n=== Executando com 1 processo ===" | tee -a $(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt
	$(CMD_TIME) $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(PICTURES_DIR)/output_1_$(TIMESTAMP).ppm 1 2>&1 | tee -a $(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt

# Teste com 2 processos
test2: init_dirs
	@echo "\n=== Executando com 2 processos ===" | tee -a $(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt
	$(CMD_TIME) $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(PICTURES_DIR)/output_2_$(TIMESTAMP).ppm 2 2>&1 | tee -a $(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt

# Teste com 4 processos
test4: init_dirs
	@echo "\n=== Executando com 4 processos ===" | tee -a $(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt
	$(CMD_TIME) $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(PICTURES_DIR)/output_4_$(TIMESTAMP).ppm 4 2>&1 | tee -a $(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt

# Teste com 8 processos
test8: init_dirs
	@echo "\n=== Executando com 8 processos ===" | tee -a $(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt
	$(CMD_TIME) $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(PICTURES_DIR)/output_8_$(TIMESTAMP).ppm 8 2>&1 | tee -a $(REPORTS_DIR)/measure_time_$(TIMESTAMP).txt

# Remove o arquivo de imagem gerado
clean:
	rm -rf reports pictures
	rm -f *.ppm *.txt perf.data*

# --- ANÁLISES (Profiling e Automação) ---

# Roda todas as análises de uma vez
run_analysis: init_dirs profile_cprofile profile_perf_stat profile_perf_record

# 3.7.1 cProfile (Analisa chamadas de funções e overhead do multiprocessing)
profile_cprofile: init_dirs
	@echo "\n=== Executando cProfile (4 processos) ==="
	$(PYTHON) -m cProfile -s cumulative $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(PICTURES_DIR)/output_cprofile_$(TIMESTAMP).ppm 4 > $(REPORTS_DIR)/cprofile_output.txt
	@echo "--> Relatório completo salvo em '$(REPORTS_DIR)/cprofile_output.txt'"
	@echo "--> Filtrando funções alvo do relatório (overhead de IPC):"
	@grep -iE "process.py.*start|queues.py.*put|queues.py.*get|connection.py.*send|connection.py.*recv|pool.py.*map|pickle.*dumps|pickle.*loads" $(REPORTS_DIR)/cprofile_output.txt || echo "(Funções não encontradas ou no final da lista)"

# 3.7.2 perf stat (Analisa IPC, Instructions, etc)
profile_perf_stat: init_dirs
	@echo "\n=== Executando perf stat (4 processos) ==="
	perf stat -o $(REPORTS_DIR)/perf_stat_output.txt $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(PICTURES_DIR)/output_perf_stat_$(TIMESTAMP).ppm 4
	@echo "--> Resultado salvo em '$(REPORTS_DIR)/perf_stat_output.txt'"
	@cat $(REPORTS_DIR)/perf_stat_output.txt

# 3.7.2 perf record e report (Analisa onde a CPU está gastando tempo)
profile_perf_record: init_dirs
	@echo "\n=== Executando perf record (4 processos) ==="
	perf record -o $(REPORTS_DIR)/perf.data -g $(PYTHON) $(SCRIPT) $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(PICTURES_DIR)/output_perf_record_$(TIMESTAMP).ppm 4
	@echo "\n=== Gerando perf report ==="
	perf report -i $(REPORTS_DIR)/perf.data -f --stdio > $(REPORTS_DIR)/perf_report_output.txt
	@echo "--> Relatório completo salvo em '$(REPORTS_DIR)/perf_report_output.txt'"
	@echo "--> Buscando funções do GIL/Locks (PyThread_acquire_lock, sem_wait):"
	@grep -iE "PyThread_acquire_lock|sem_wait" $(REPORTS_DIR)/perf_report_output.txt || echo "SUCESSO: Funções de lock/GIL não dominaram o profile (como esperado em Multiprocessing)."

# Organização: Info do processador e Liberação do perf
system_info:
	@echo "\n=== Informações do Processador ==="
	lscpu
	@echo "\n=== Configurando permissão para o perf (pode pedir senha de sudo) ==="
	sudo sysctl -w kernel.perf_event_paranoid=-1
