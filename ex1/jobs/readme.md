
> **Note**: The `gol` executable is compiled from source in `programs/` using `Makefile`.  
> The `jobs/` folder contains SLURM scripts used to submit scaling experiments on THIN and EPYC partitions.

---

### File organization :

- **`include/`**  
  Contains header files of programs.

- **`jobs/`**  
  SLURM job scripts for running:
  - OpenMP strong scaling (`openmp_thin.sh`, `openmp_epyc.sh`)
  - MPI strong/weak scaling (`mpi_strong_thin.sh`, `mpi_weak_epyc.sh`)
  - Architecture tests (`test_epyc_arch.sh`)

  It also contains the `jobs/results/` inside where all the outputs are stored.

- **`programs/`**  
Contains game_of_life.c , io.c , utils.c , main.c
  Source code and compiled binaries. The main program `gol` accepts flags:
  - `-i` to initialize a grid
  - `-r` to run evolution
  - `-k` for grid size
  - `-f` for input/output file
  - `-n` for number of steps
  - `-e` for evolution type (0=ordered, 1=static)

- **`Makefile`**  
  Compiles `gol` with MPI and OpenMP support.
