#include <mpi.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils.h"
#include "io.h"
#include "game_of_life.h"

int main(int argc, char *argv[]) {
    int provided;

    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    Config cfg = parse_args(argc, argv);
    
    if (cfg.action == INIT) {
        // Only rank 0 creates initial grid
        if (rank == 0) {
            unsigned char *grid = malloc(cfg.k * cfg.k * sizeof(unsigned char));
            srand(42);  // Fixed seed for reproducibility
            initialize_random_grid(grid, cfg.k);
            free(grid);
            printf("Initial grid %dx%d saved to: %s\n", cfg.k, cfg.k, cfg.fname);
        }
    } 
    else if (cfg.action == RUN) {
        int actual_k;
        
        if (rank == 0) {
            // Read the actual grid size from the PGM file
            unsigned char *test_grid = load_pgm(cfg.fname, &actual_k);
            free(test_grid); // to know just size
            printf("Running simulation: %d steps, grid %dx%d, %d MPI tasks\n",
                   cfg.n, actual_k, actual_k, size);
        }
        
        // Broadcast the actual grid size to all processes
        MPI_Bcast(&actual_k, 1, MPI_INT, 0, MPI_COMM_WORLD);
        
        // Update cfg with the actual grid size from the file
        cfg.k = actual_k;
        
        run_simulation(&cfg, rank, size);
    }
    
    MPI_Finalize();
    return 0;
}
