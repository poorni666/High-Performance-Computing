#ifndef GAME_OF_LIFE_H
#define GAME_OF_LIFE_H

#include <mpi.h>
#include "utils.h"

void initialize_random_grid(unsigned char *grid, int k);
void evolve_static_mpi(unsigned char *local_grid, int k, int local_rows, 
                      int rank, int size, double *comm_time);
void run_simulation(Config *cfg, int rank, int size);

#endif
