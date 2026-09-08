# Testes de Multiprocessing em Python

O objetivo deste diretório é entender de forma direta e prática como funcionam os principais componentes do módulo `multiprocessing` em Python.

---

## 🎯 Conceitos Estudados

1. **`Process`**
   - Permite a criação e execução de processos independentes (paralelismo real em múltiplos núcleos da CPU).
2. **`Queue`**
   - Fila de tarefas/mensagens (*FIFO*) usada para distribuir o trabalho entre os processos de forma segura.
3. **`SharedMemory`**
   - Espaço de memória RAM compartilhado diretamente entre processos, permitindo escrita e leitura direta sem a necessidade de copiar dados entre eles.

---

## 📁 Arquivos de Teste

- **[`test_without_worker.py`](file:///home/robson/Desktop/github/robson-carvalho/mandelbrot-fractal-set-multicore/python_pararell_multiprocessing/test/test_without_worker.py)**:
  - Demonstra o uso de `Process` e `SharedMemory` de forma direta. Cada processo é instanciado para calcular uma parte específica dos dados e escrever o resultado na sua respetiva posição da memória compartilhada.

- **[`test_with_worker.py`](file:///home/robson/Desktop/github/robson-carvalho/mandelbrot-fractal-set-multicore/python_pararell_multiprocessing/test/test_with_worker.py)**:
  - Implementa um padrão de trabalhadores (*workers*) usando `Queue` e `SharedMemory`. Os processos consumidores recebem tarefas da fila continuamente e gravam os resultados diretamente na memória compartilhada.
