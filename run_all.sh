#!/bin/bash

# Aborta o script em caso de erro
set -e

echo "========================================================="
echo "Iniciando bateria completa de testes e análises (Mandelbrot)"
echo "========================================================="

# 1. Análises do Código C Serial
echo ""
echo "-> 1/5 Executando análises do Código C Serial..."
make analyze-c-serial

# 2. Análises do Código C Paralelo
echo ""
echo "-> 2/5 Executando análises do Código C Paralelo..."
make analyze-c-parallel

# 3. Análises do Código Python Serial
echo ""
echo "-> 3/5 Executando análises do Código Python Serial..."
make python-serial

# 4. Análises do Código Python Multithreading
echo ""
echo "-> 4/5 Executando análises do Código Python Multithreading..."
make python-parallel-multithreading

# 5. Análises do Código Python Multiprocessing
echo ""
echo "-> 5/5 Executando análises do Código Python Multiprocessing..."
make python-parallel-multiprocessing

echo "========================================================="
echo "Todas as baterias de testes foram concluídas com sucesso!"
echo "Verifique as pastas 'reports' e 'pictures' para os resultados."
echo "========================================================="
