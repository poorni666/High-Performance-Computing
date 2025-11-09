# High-Performance-Computing

The project is organized into two main exercises:

## Repository Structure
├── ex1/ (Contains the parallel Game of Life simulation)
├── ex2/ (Contains the BLIS vs. OpenBLAS benchmark)
├── report_hpc.pdf 
└──README.md 
### Exercise 1: Game of Life
Implement and analyze the parallel performance of Conway’s Game of Life using **OpenMP**, **MPI**, and their hybrid combination on the Orfeo HPC cluster.

This excercise simulates the Game of Life on a 2D grid and evaluates:
- OpenMP strong scaling 
- MPI strong scaling 
- MPI weak scaling 

## How to Run
```bash
# Compile
module load
make clean
make 

# Submit jobs
sbatch openmp.sh
sbatch strong_scaling.sh
sbatch weak_scaling.sh
  bash ```

Exercise 2 – GEMV Benchmark (BLIS vs OpenBLAS)
Compare the performance of **BLIS** and **OpenBLAS** libraries for the matrix–vector multiplication (GEMV) operation.

This benchmark measures floating-point performance of GEMV under different:
- fixed_matrix
- fixed_core
- Libraries (BLIS vs OpenBLAS)

## How to Run
```bash
module load ( library )
make 




### Exercise 2: BLIS vs. OpenBLAS GEMM Benchmark
