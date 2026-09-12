#!/bin/bash

# Aborta o script em caso de erro
set -e

echo "========================================================="
echo "Executando análises do Código C Serial..."
echo "========================================================="

make analyze-c-serial

echo "========================================================="
echo "Testes do C Serial concluídos com sucesso!"
echo "Verifique a pasta 'reports' para os resultados gerados."
echo "========================================================="
