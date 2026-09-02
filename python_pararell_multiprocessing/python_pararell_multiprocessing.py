import sys
from multiprocessing import Pool

def main():
    pass


if __name__ == "__main__":
    num_processos = 0

    if len(sys.argv) < 2:
        num_processos = 2
  
    num_processos = int(sys.argv[1])

    print("Number of processes:", num_processos)
    
    main()