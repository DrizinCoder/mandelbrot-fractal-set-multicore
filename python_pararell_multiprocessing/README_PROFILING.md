# Guia de Profiling - Multiprocessing

Este documento explica como ler e interpretar os dados gerados pelas ferramentas de profiling (`cProfile` e `perf`), essenciais para preencher o relatório do item **3.7**.

---

## 1. cProfile (Compreendendo o Overhead do Python)

O comando `make profile_cprofile` utiliza o profiler embutido do Python para contar quantas vezes cada função foi chamada e quanto tempo gastou. Como usamos a flag `-s cumulative`, as funções que mais consumiram tempo no geral aparecem no topo.

### Entendendo as Colunas do cProfile:
Quando você analisa o arquivo `cprofile_output.txt` (ou a saída filtrada), você verá as seguintes colunas:
```text
ncalls  tottime  percall  cumtime  percall filename:lineno(function)
```

- **ncalls (Number of Calls):** O número de vezes que essa função foi chamada. Se houver dois números (ex: `605/604`), significa que a função é recursiva (o primeiro é o total de chamadas, o segundo são chamadas não-recursivas primitivas).
- **tottime (Total Time):** O tempo total gasto **dentro** desta função específica, *excluindo* o tempo gasto nas sub-funções que ela chama. 
- **percall (Per Call - Tottime):** É a divisão simples: `tottime / ncalls`. O tempo médio por execução da função isolada.
- **cumtime (Cumulative Time):** O tempo total gasto nesta função **incluindo** todas as sub-funções chamadas por ela. Esse é o número mais importante para ver de onde o tempo está sendo drenado.
- **percall (Per Call - Cumtime):** É a divisão: `cumtime / ncalls`.
- **filename:lineno(function):** Qual é o arquivo, linha e nome da função sendo executada.

### O que observar para o Relatório (Item 3.7.1):
No relatório filtrado pelo `Makefile`, observe o `cumtime` das funções:
- `process.py(start)`: Tempo gasto criando os novos processos no SO.
- `queues.py(put)` e `connection.py(send)`: Tempo gasto serializando (`pickle.dumps`) e enviando blocos de dados entre processos.
**Conclusão para o texto:** Todo esse tempo é o "Overhead de IPC" (Inter-Process Communication). Na versão Multithreading, esse overhead é próximo de zero porque as threads compartilham a mesma área de memória e não precisam empacotar (serializar) e desempacotar (desserializar) os dados.

---

## 2. perf stat (Estatísticas de Instruções da CPU)

O comando `make profile_perf_stat` interage direto com os contadores de hardware do seu processador (Hardware Performance Counters).

### O que observar para o Relatório (Item 3.7.2):
- **instructions:** O total de instruções de máquina que a CPU executou. 
  - *Comparação:* Esse número será **muito maior** do que na versão Sequencial ou Multithreading. O motivo é que no Multiprocessing, o SO precisa subir múltiplos interpretadores Python (`python3`) inteiros na memória, e gerenciar a comunicação entre eles gera milhões de instruções a mais.
- **insn_per_cycle (IPC):** Instruções por Ciclo de Clock. Um número alto (acima de 2.0 ou 3.0) indica que a CPU está conseguindo despachar instruções rapidamente, sem grandes gargalos de memória (cache misses) nas lógicas internas.
- **seconds time elapsed (Wall-clock time):** O tempo real no relógio de parede.
  - *Conclusão:* Apesar do código executar **muito mais instruções** (pelo overhead dos 4 processos), o tempo total (`time elapsed`) **caiu drasticamente** em relação ao sequencial, pois essas instruções estão sendo resolvidas por núcleos físicos diferentes de forma simultânea (Paralelismo Real).

---

## 3. perf record / report (Gargalos de Sistema / GIL)

O `perf report` cria uma árvore de chamadas do nível do sistema operacional (C/C++). 

Como o Python é interpretado, o `perf` verá principalmente a `libc` e as chamadas internas do interpretador Python (geralmente executando bytecode). Muitos nomes aparecem em hexadecimal porque os binários padrão do Python e do SO não carregam a "tabela de símbolos" completa para leitura humana.

### O que observar para o Relatório (Item 3.7.2):
A grande questão aqui é **o que NÃO aparece**.
- Na versão **Multithreading** em Python, múltiplas threads de um mesmo processo brigam pelo GIL (Global Interpreter Lock). Isso faz com que funções do sistema operacional ligadas ao travamento de memória (como `PyThread_acquire_lock`, `sem_wait`, `futex`) pulem para o topo do perfil, consumindo muita CPU inutilmente.
- Na versão **Multiprocessing**, cada processo tem sua própria memória isolada e seu próprio GIL. O script do Makefile faz uma busca por essas palavras e constata que **elas quase não existem**. 
  - *Conclusão:* O perfil de CPU é limpo, provando que não há contenção (briga por recursos protegidos) entre as unidades de processamento. A CPU fica livre para focar na matemática do fractal.
