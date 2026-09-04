CC     = gcc
CFLAGS = -O2 -g
LIBS   = -lm

# ── Configurações do Fractal ──────────────────────────────────────────────────
WIDTH    ?= 30720
HEIGHT   ?= 17280
MIN_X    ?= -2
MAX_X    ?= 1
MIN_Y    ?= -1
MAX_Y    ?= 1
MAX_ITER ?= 500
NUM_PROCESSOS ?= 4

MACHINE_NAME := $(shell hostname)
TIMESTAMP    := $(shell date +%Y%m%d_%H%M%S)

ARGS = $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) pictures/$(MACHINE_NAME)/fractal_$(WIDTH)_$(HEIGHT)_iter$(MAX_ITER)_$(TIMESTAMP).ppm
VALGRIND_ARGS = 768 432 $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) 100 pictures/$(MACHINE_NAME)/fractal_valgrind_768_432_iter100_$(TIMESTAMP).ppm
PYTHON_PARALLEL_OUTPUT = pictures/$(MACHINE_NAME)/fractal_multiprocessing_$(WIDTH)_$(HEIGHT)_iter$(MAX_ITER)_$(TIMESTAMP).ppm
PYTHON_PARALLEL_ARGS = $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $(MAX_ITER) $(PYTHON_PARALLEL_OUTPUT) $(NUM_PROCESSOS)

.PHONY: compile run hardware-info time gprof perf valgrind strace analyze-all benchmark-iter clean python-cprofile python-perf python-strace python-multiprocessing python-parallel

# ── Build principal (requisito do enunciado) ──────────────────────────────────
compile:
	mkdir -p build
	$(CC) $(CFLAGS)  serial_c_code/complex.c serial_c_code/image_generator.c serial_c_code/mandelbrot.c -o build/programa $(LIBS)

run:
	mkdir -p pictures/$(MACHINE_NAME)
	./build/programa $(ARGS)

# ── Medição de tempo com /usr/bin/time ───────────────────────────────────────
time: compile hardware-info
	mkdir -p pictures/$(MACHINE_NAME) reports/$(MACHINE_NAME)/time
	@echo "Executando com /usr/bin/time (medição detalhada de tempo e recursos)..."
	/usr/bin/time -v ./build/programa $(ARGS) 2>&1 | tee reports/$(MACHINE_NAME)/time/time_report.txt
	@echo "---------------------------------------------------------"
	@echo "Relatório salvo em reports/$(MACHINE_NAME)/time/time_report.txt."
	@echo "---------------------------------------------------------"

# ── Relatório de Hardware ───────────────────────────────────────────────────────
hardware-info:
	@mkdir -p reports/$(MACHINE_NAME)
	@echo "# Especificações de Hardware - $(MACHINE_NAME)" > reports/$(MACHINE_NAME)/README.md
	@echo "" >> reports/$(MACHINE_NAME)/README.md
	@echo "## CPU" >> reports/$(MACHINE_NAME)/README.md
	@lscpu | grep "Model name" >> reports/$(MACHINE_NAME)/README.md || true
	@echo "" >> reports/$(MACHINE_NAME)/README.md
	@echo "## Caches" >> reports/$(MACHINE_NAME)/README.md
	@lscpu | grep -i cache >> reports/$(MACHINE_NAME)/README.md || true
	@echo "" >> reports/$(MACHINE_NAME)/README.md
	@echo "## RAM (Memória)" >> reports/$(MACHINE_NAME)/README.md
	@echo -n "- Total Disponível: " >> reports/$(MACHINE_NAME)/README.md
	@dmidecode -t memory 2>/dev/null | awk '/Size:/ && !/No Module/ {sum+=$$2} END {print sum "GB"}' >> reports/$(MACHINE_NAME)/README.md || true
	@dmidecode -t memory 2>/dev/null | awk '/Type:/ && !/Unknown/ && !/Error/ {print "- Type: " $$2; exit}' >> reports/$(MACHINE_NAME)/README.md || true
	@echo "" >> reports/$(MACHINE_NAME)/README.md
	@echo "## GPU (Vídeo)" >> reports/$(MACHINE_NAME)/README.md
	@lshw -C display 2>/dev/null | awk '/product:|vendor:|configuration:/ {gsub(/^[ \t]+/, "- "); print}' >> reports/$(MACHINE_NAME)/README.md || true

# ── gprof ─────────────────────────────────────────────────────────────────────
compile-profile:
	mkdir -p build
	$(CC) $(CFLAGS) -pg serial_c_code/complex.c serial_c_code/image_generator.c serial_c_code/mandelbrot.c -o build/programa_profile $(LIBS)

gprof: compile-profile hardware-info
	mkdir -p pictures/$(MACHINE_NAME) reports/$(MACHINE_NAME)/gprof
	@echo "Executando para coletar dados de profiling..."
	./build/programa_profile $(ARGS)
	@if [ -f gmon.out ]; then mv gmon.out reports/$(MACHINE_NAME)/gprof/; fi
	@echo "Gerando relatório do gprof..."
	gprof ./build/programa_profile reports/$(MACHINE_NAME)/gprof/gmon.out > reports/$(MACHINE_NAME)/gprof/profiling_report.txt
	@echo "---------------------------------------------------------"
	@echo "Relatório salvo em reports/$(MACHINE_NAME)/gprof/profiling_report.txt."
	@echo "Top 10 gargalos (flat profile):"
	@head -n 15 reports/$(MACHINE_NAME)/gprof/profiling_report.txt
	@echo "---------------------------------------------------------"

# ── perf ──────────────────────────────────────────────────────────────────────
perf: compile hardware-info
	mkdir -p pictures/$(MACHINE_NAME) reports/$(MACHINE_NAME)/perf
	@echo "Executando com perf stat (coletando métricas de hardware)..."
	perf stat -e cycles,instructions,cache-misses,cache-references,branch-misses,branches,L1-dcache-load-misses,LLC-load-misses -o reports/$(MACHINE_NAME)/perf/perf_stat.txt ./build/programa $(ARGS)
	@echo "Executando com perf record (coletando call graph)..."
	perf record -o reports/$(MACHINE_NAME)/perf/perf.data -g ./build/programa $(ARGS)
	@echo "Gerando relatório do perf..."
	perf report -f -i reports/$(MACHINE_NAME)/perf/perf.data --stdio > reports/$(MACHINE_NAME)/perf/perf_report.txt
	@echo "---------------------------------------------------------"
	@echo "Relatório perf stat salvo em reports/$(MACHINE_NAME)/perf/perf_stat.txt:"
	@cat reports/$(MACHINE_NAME)/perf/perf_stat.txt
	@echo "---------------------------------------------------------"
	@echo "Relatório perf record (amostragem) salvo em reports/$(MACHINE_NAME)/perf/perf_report.txt."
	@head -n 30 reports/$(MACHINE_NAME)/perf/perf_report.txt
	@echo "---------------------------------------------------------"

# ── Valgrind (Callgrind + Cachegrind) ────────────────────────────────────────
valgrind: compile hardware-info
	mkdir -p pictures/$(MACHINE_NAME) reports/$(MACHINE_NAME)/valgrind
	@echo "[Callgrind] Contando instruções e chamadas por função..."
	valgrind --tool=callgrind \
		--callgrind-out-file=reports/$(MACHINE_NAME)/valgrind/callgrind.out \
		./build/programa $(VALGRIND_ARGS)
	@echo "[Callgrind] Gerando relatório de texto..."
	callgrind_annotate --auto=yes reports/$(MACHINE_NAME)/valgrind/callgrind.out \
		> reports/$(MACHINE_NAME)/valgrind/callgrind_report.txt
	@echo "---------------------------------------------------------"
	@echo "Top funções (Callgrind):"
	@head -n 40 reports/$(MACHINE_NAME)/valgrind/callgrind_report.txt
	@echo "---------------------------------------------------------"
	@echo "[Cachegrind] Analisando acessos e misses de cache (L1/L2)..."
	valgrind --tool=cachegrind \
		--cachegrind-out-file=reports/$(MACHINE_NAME)/valgrind/cachegrind.out \
		./build/programa $(VALGRIND_ARGS)
	@echo "[Cachegrind] Gerando relatório anotado por linha..."
	cg_annotate --auto=yes reports/$(MACHINE_NAME)/valgrind/cachegrind.out \
		> reports/$(MACHINE_NAME)/valgrind/cachegrind_report.txt
	@echo "---------------------------------------------------------"
	@echo "Resumo de cache (Cachegrind):"
	@head -n 30 reports/$(MACHINE_NAME)/valgrind/cachegrind_report.txt
	@echo "---------------------------------------------------------"
	@echo "Relatórios salvos em reports/$(MACHINE_NAME)/valgrind/"

# ── strace ───────────────────────────────────────────────────────────────────
strace: compile hardware-info
	mkdir -p pictures/$(MACHINE_NAME) reports/$(MACHINE_NAME)/strace
	@echo "[strace] Rastreando syscalls do programa..."
	strace -c -o reports/$(MACHINE_NAME)/strace/strace_report.txt \
		./build/programa $(ARGS)
	@echo "---------------------------------------------------------"
	@echo "Resumo de syscalls:"
	@cat reports/$(MACHINE_NAME)/strace/strace_report.txt
	@echo "---------------------------------------------------------"
	@echo "Top 3 syscalls mais frequentes:"
	@tail -n +3 reports/$(MACHINE_NAME)/strace/strace_report.txt \
		| grep -v 'total\|calls\|errors\|---' \
		| sort -k4 -rn \
		| head -n 3
	@echo "---------------------------------------------------------"
	@echo "Relatório salvo em reports/$(MACHINE_NAME)/strace/strace_report.txt"

# ── cProfile (Python) ────────────────────────────────────────────────────────
python-cprofile: hardware-info
	mkdir -p pictures/$(MACHINE_NAME) reports/$(MACHINE_NAME)/python_serial
	@echo "Executando cProfile no script serial..."
	python3 -m cProfile -s cumulative python_serial_code/python_serial.py $(ARGS) > reports/$(MACHINE_NAME)/python_serial/cprofile_report.txt
	@echo "---------------------------------------------------------"
	@echo "Relatório salvo em reports/$(MACHINE_NAME)/python_serial/cprofile_report.txt"
	@head -n 25 reports/$(MACHINE_NAME)/python_serial/cprofile_report.txt
	@echo "---------------------------------------------------------"

# ── perf (Python) ────────────────────────────────────────────────────────────
python-perf: hardware-info
	mkdir -p pictures/$(MACHINE_NAME) reports/$(MACHINE_NAME)/python_serial
	@echo "Executando perf stat no script serial Python..."
	perf stat -e cycles,instructions,cache-misses,cache-references,branch-misses,branches,L1-dcache-load-misses,LLC-load-misses -o reports/$(MACHINE_NAME)/python_serial/perf_stat.txt python3 python_serial_code/python_serial.py $(ARGS)
	@echo "---------------------------------------------------------"
	@echo "Relatório perf stat salvo em reports/$(MACHINE_NAME)/python_serial/perf_stat.txt:"
	@cat reports/$(MACHINE_NAME)/python_serial/perf_stat.txt
	@echo "---------------------------------------------------------"

# ── strace (Python) ──────────────────────────────────────────────────────────
python-strace: hardware-info
	mkdir -p pictures/$(MACHINE_NAME) reports/$(MACHINE_NAME)/python_serial
	@echo "Executando strace no script serial Python..."
	strace -c -o reports/$(MACHINE_NAME)/python_serial/strace_report.txt python3 python_serial_code/python_serial.py $(ARGS)
	@echo "---------------------------------------------------------"
	@echo "Resumo de syscalls (strace):"
	@cat reports/$(MACHINE_NAME)/python_serial/strace_report.txt
	@echo "---------------------------------------------------------"

# ── Análises Python ──────────────────────────────────────────────────────────
python-analyze: python-cprofile python-perf python-strace
	@echo "========================================================="
	@echo "Todas as análises Python (cProfile, perf, strace) concluídas!"
	@echo "Relatórios em: reports/$$(hostname)/python_serial/"
	@echo "========================================================="

# ── Todas as análises ─────────────────────────────────────────────────────────
analyze-all: clean time gprof perf valgrind strace
	@echo "========================================================="
	@echo "Todas as análises (time, gprof, perf, valgrind, strace) foram concluídas!"
	@echo "Os relatórios estão salvos na pasta reports/$(MACHINE_NAME)/"
	@echo "========================================================="

# ── Benchmark de Iterações (Gráfico Log) ──────────────────────────────────────
benchmark-iter: compile
	mkdir -p reports/$(MACHINE_NAME)/benchmark pictures/$(MACHINE_NAME)
	@echo "iter_max,tempo_segundos" > reports/$(MACHINE_NAME)/benchmark/iter_log.txt
	@for iter in 10 100 1000 10000; do \
		echo "Executando iter=$$iter..."; \
		OUTPUT_FILE=pictures/$(MACHINE_NAME)/fractal_$(WIDTH)_$(HEIGHT)_iter$${iter}_$(TIMESTAMP).ppm; \
		tempo=$$(./build/programa $(WIDTH) $(HEIGHT) $(MIN_X) $(MAX_X) $(MIN_Y) $(MAX_Y) $$iter $$OUTPUT_FILE | grep "clock_gettime" | awk '{print $$5}'); \
		echo "$$iter,$$tempo" >> reports/$(MACHINE_NAME)/benchmark/iter_log.txt; \
	done
	@echo "Dados salvos em reports/$(MACHINE_NAME)/benchmark/iter_log.txt"
# ── Execução Python Multiprocessing ───────────────────────────────────────────
python-multiprocessing python-parallel:
	mkdir -p pictures/$(MACHINE_NAME)
	python3 python_pararell_multiprocessing/python_pararell_multiprocessing.py $(PYTHON_PARALLEL_ARGS)

# ── Limpeza ───────────────────────────────────────────────────────────────────
clean:
	rm -f build/programa build/programa_profile
	rm -rf reports/$(MACHINE_NAME)

