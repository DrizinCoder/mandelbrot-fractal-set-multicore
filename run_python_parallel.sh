#!/bin/bash

# Aborta o script em caso de erro
set -e

echo "========================================================="
echo "Executando análises do Código Python Paralelo..."
echo "========================================================="

echo "-> Iniciando testes de Multithreading (1, 2, 4, 8 threads)..."
make python-parallel-multithreading

echo ""
echo "-> Iniciando testes de Multiprocessing (1, 2, 4, 8 processos)..."
make python-parallel-multiprocessing

echo "========================================================="
echo "Testes do Python Paralelo concluídos com sucesso!"
echo "========================================================="
