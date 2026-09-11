#!/bin/bash

# Aborta o script em caso de erro
set -e

echo "========================================================="
echo "Executando análises do Código C Paralelo..."
echo "========================================================="

make analyze-c-parallel

echo "========================================================="
echo "Testes do C Paralelo concluídos com sucesso!"
echo "========================================================="
