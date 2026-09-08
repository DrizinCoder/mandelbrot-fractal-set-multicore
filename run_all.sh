#!/bin/bash

# Aborta o script em caso de erro
set -e

echo "========================================================="
echo "Iniciando bateria completa de testes e análises (Mandelbrot)"
echo "========================================================="

# 1. Análises do Código C Serial
echo ""
echo "-> 1/4 Executando análises do Código C Serial..."
make analyze-all

# 2. Análises do Código Python Serial
echo ""
echo "-> 2/4 Executando análises do Código Python Serial..."
make python-analyze

# 3. Análises do Código Python Multiprocessing
echo ""
echo "-> 3/4 Executando análises do Código Python Multiprocessing..."
cd python_pararell/python_pararell_multiprocessing
make run_all
cd ../..

# 4. Análises do Código Python Multithreading
echo ""
echo "-> 4/4 Executando análises do Código Python Multithreading..."
cd python_pararell/python_pararell_multithreading
make run_all
cd ../..

echo "========================================================="
echo "Todas as baterias de testes foram concluídas com sucesso!"
echo "Verifique as pastas 'reports' e 'pictures' para os resultados."
echo "========================================================="
