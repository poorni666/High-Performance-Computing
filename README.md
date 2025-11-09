# High-Performance-Computing

The project is organized into two main exercises:

## Repository Structure
├── ex1/ (Contains the parallel Game of Life simulation)  
├── ex2/ (Contains the BLIS vs. OpenBLAS benchmark)   
├── report_hpc.pdf   
└──README.md   
### Exercise 1: Game of Life
Implement and analyze the parallel performance of Conway’s Game of Life using hybrid **OpenMP**, **MPI** on the Orfeo HPC cluster.

This excercise simulates the Game of Life on a 2D grid and evaluates:
- OpenMP strong scaling 
- MPI strong scaling 
- MPI weak scaling 

## How to Run
```bash
# Compile
module load <module>
make clean
make 

# Submit jobs
sbatch openmp.sh
sbatch strong_scaling.sh
sbatch weak_scaling.sh
```

### Exercise 2 : GEMM Benchmark (BLIS vs OpenBLAS)
Compare the performance of **BLIS** and **OpenBLAS** libraries for the matrix–vector multiplication (GEMM) operation.

This benchmark measures floating-point performance  of GEMV under different (Libraries (BLIS vs OpenBLAS):
- fixed_matrix
- fixed_core

## How to Run
```bash
module load ( library )
make 
# Submit jobs
sbatch fixed_matrix.sh
sbatch fixed_cores.sh
