#!/bin/bash

# Aborta o script em caso de erro
set -e

echo "========================================================="
echo "Executando análises do Código Python Serial..."
echo "========================================================="

make python-serial

echo "========================================================="
echo "Testes do Python Serial concluídos com sucesso!"
echo "========================================================="
