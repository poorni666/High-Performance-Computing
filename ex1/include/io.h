#ifndef IO_H
#define IO_H

#include <mpi.h>

unsigned char* load_pgm(const char *filename, int *k);
void save_pgm(const char *filename, unsigned char *grid, int k);
void save_snapshot(unsigned char *grid, int k, int step);

// MPI versions
void load_pgm_mpi(const char *filename, unsigned char **local_grid, int *k, 
                  int *local_rows, int rank, int size);
void save_pgm_mpi(const char *filename, unsigned char *local_grid, int k, 
                  int local_rows, int rank, int size);
void save_snapshot_mpi(unsigned char *local_grid, int k, int local_rows, 
                       int step, int rank, int size);

#endif
