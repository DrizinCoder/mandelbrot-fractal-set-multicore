from multiprocessing import Process, Queue
from multiprocessing.shared_memory import SharedMemory

def worker(nome_memoria, fila):
    shm = SharedMemory(name=nome_memoria)

    while True:
        tarefa = fila.get()
        if tarefa is None:  # Sinal de que o trabalho acabou
            break

        posicao, numeros = tarefa
        shm.buf[posicao] = sum(numeros)  # Grava direto na RAM

    shm.close()

if __name__ == '__main__':
    # 6 tarefas diferentes para executar
    tarefas = [
        (0, [1, 2]),    # soma = 3  -> guarda no byte 0
        (1, [3, 4]),    # soma = 7  -> guarda no byte 1
        (2, [5, 6]),    # soma = 11 -> guarda no byte 2
        (3, [7, 8]),    # soma = 15 -> guarda no byte 3
        (4, [9, 10]),   # soma = 19 -> guarda no byte 4
        (5, [11, 12]),  # soma = 23 -> guarda no byte 5
    ]

    NUM_PROCESSOS = 2  

    # 1. Aloca 6 bytes na memória RAM (1 byte para cada resposta)
    shm = SharedMemory(create=True, size=len(tarefas))

    # 2. Coloca todas as tarefas na fila
    fila = Queue()
    for t in tarefas:
        fila.put(t)

    for _ in range(NUM_PROCESSOS):
        fila.put(None)

    processos = []
    for _ in range(NUM_PROCESSOS):
        p = Process(target=worker, args=(shm.name, fila))
        p.start()
        processos.append(p)

    for p in processos:
        p.join()

    # 5. Lê os 6 resultados direto da memória compartilhada
    resultados = list(shm.buf[:len(tarefas)])
    print("Resultados na memória:", resultados)
    print("Soma total:", sum(resultados))

    # Limpeza obrigatória
    shm.close()
    shm.unlink()