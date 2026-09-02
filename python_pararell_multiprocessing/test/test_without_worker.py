from multiprocessing import Process
from multiprocessing.shared_memory import SharedMemory

# 1. Função que roda no processo filho
def somar_pedaco(nome_memoria, posicao, numeros):
    shm = SharedMemory(name=nome_memoria)
   
    resultado = sum(numeros)
    shm.buf[posicao] = resultado
    
    shm.close()

if __name__ == '__main__':
    # Cria um espaço de 2 bytes na memória RAM
    shm = SharedMemory(create=True, size=2)

    parte1 = [1, 2, 3]  # soma = 6
    parte2 = [4, 5, 6]  # soma = 15

    # Cria 2 processos: 
    # Um vai gravar na posição 0, o outro na posição 1 da memória
    p1 = Process(target=somar_pedaco, args=(shm.name, 0, parte1))
    p2 = Process(target=somar_pedaco, args=(shm.name, 1, parte2))

    p1.start()
    p2.start()
    p1.join()
    p2.join()

    print("Valor na posição 0:", shm.buf[0])
    print("Valor na posição 1:", shm.buf[1])
    print("Soma total:", shm.buf[0] + shm.buf[1])

    # Limpa e devolve a memória para o computador
    shm.close()
    shm.unlink()