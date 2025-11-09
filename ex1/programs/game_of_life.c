#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <mpi.h>
#include <stdio.h>
#include "game_of_life.h"
#include "io.h"
#include "utils.h"

void initialize_random_grid(unsigned char *grid, int k) {
    for (int i = 0; i < k * k; i++) {
        grid[i] = (rand() % 100 < 30) ? 255 : 0;  // 30% alive
    }
}

// Count neighbors for local grid with halo data
int count_neighbors(unsigned char *local_grid, int k, int i, int j,
                   unsigned char *halo_top, unsigned char *halo_bottom, int local_rows) {
    int count = 0;
    for (int di = -1; di <= 1; di++) {
        for (int dj = -1; dj <= 1; dj++) {
            if (di == 0 && dj == 0) continue;

            int ni = i + di;
            int nj = (j + dj + k) % k;  // Periodic in columns
            
            unsigned char cell;
            if (ni < 0) {
                cell = halo_top[nj];  // Top halo
            } else if (ni >= local_rows) {  // FIXED: use local_rows instead of k
                cell = halo_bottom[nj];  // Bottom halo
            } else {
                cell = local_grid[ni * k + nj];  // Local data
            }

            count += (cell == 255);
        }
    }
    return count;
}

// Apply Game of Life rules
unsigned char apply_rules(unsigned char current, int neighbors) {
    if (current == 255) {  // Cell is alive
        return (neighbors == 2 || neighbors == 3) ? 255 : 0;
    } else {  // Cell is dead
        return (neighbors == 3) ? 255 : 0;
    }
}

// Static evolution with MPI 
void evolve_static_mpi(unsigned char *local_grid, int k, int local_rows, 
                      int rank, int size, double *comm_time) {
    printf("DEBUG Rank %d: evolve_static_mpi START - k=%d, local_rows=%d\n", rank, k, local_rows);
    
    unsigned char *next_grid = malloc(local_rows * k * sizeof(unsigned char));
    printf("DEBUG Rank %d: next_grid allocated - %lu bytes\n", rank, (size_t)local_rows * k * sizeof(unsigned char));
    
    unsigned char *halo_top = malloc(k * sizeof(unsigned char));
    printf("DEBUG Rank %d: halo_top allocated\n", rank);
    
    unsigned char *halo_bottom = malloc(k * sizeof(unsigned char));
    printf("DEBUG Rank %d: halo_bottom allocated\n", rank);
    
    //To Calculate neighbor ranks with periodic boundaries
    int up_rank = (rank - 1 + size) % size;
    int down_rank = (rank + 1) % size;
    
    MPI_Request requests[4];
    double comm_start = MPI_Wtime();
    
    printf("DEBUG Rank %d: Starting halo exchange\n", rank);
    
    // Non-blocking halo exchange
    MPI_Isend(local_grid, k, MPI_UNSIGNED_CHAR, up_rank, 0, MPI_COMM_WORLD, &requests[0]);
    MPI_Isend(&local_grid[(local_rows - 1) * k], k, MPI_UNSIGNED_CHAR, down_rank, 1, MPI_COMM_WORLD, &requests[1]);
    MPI_Irecv(halo_bottom, k, MPI_UNSIGNED_CHAR, down_rank, 0, MPI_COMM_WORLD, &requests[2]);
    MPI_Irecv(halo_top, k, MPI_UNSIGNED_CHAR, up_rank, 1, MPI_COMM_WORLD, &requests[3]);
    
    printf("DEBUG Rank %d: Halo exchange initiated, computing interior\n", rank);
    
    //To Compute interior rows while communication happens
    #pragma omp parallel for collapse(2)
    for (int i = 1; i < local_rows - 1; i++) {
        for (int j = 0; j < k; j++) {
            int neighbors = count_neighbors(local_grid, k, i, j, halo_top, halo_bottom, local_rows);
            int idx = i * k + j;
            next_grid[idx] = apply_rules(local_grid[idx], neighbors);
        }
    }
    
    printf("DEBUG Rank %d: Interior computed, waiting for halo\n", rank);
    
    // Wait for halo exchange to complete
    MPI_Waitall(4, requests, MPI_STATUSES_IGNORE);
    *comm_time = MPI_Wtime() - comm_start;
    
    printf("DEBUG Rank %d: Halo exchange complete, computing boundaries\n", rank);
    
    // Compute boundary rows (need halos) - FIXED: removed OpenMP to avoid race conditions
    for (int j = 0; j < k; j++) {
        // Top boundary (row 0)
        int neighbors = count_neighbors(local_grid, k, 0, j, halo_top, halo_bottom, local_rows);
        next_grid[j] = apply_rules(local_grid[j], neighbors);
    }

    // Bottom boundary (only if we have multiple rows)
    if (local_rows > 1) {
        for (int j = 0; j < k; j++) {
            int idx = (local_rows - 1) * k + j;
            int neighbors = count_neighbors(local_grid, k, local_rows - 1, j, halo_top, halo_bottom, local_rows);
            next_grid[idx] = apply_rules(local_grid[idx], neighbors);
        }
    }
    
    printf("DEBUG Rank %d: Boundaries computed, copying grid\n", rank);
    
    // Copy next grid to current
    memcpy(local_grid, next_grid, local_rows * k * sizeof(unsigned char));
    
    free(next_grid);
    free(halo_top);
    free(halo_bottom);
    
    printf("DEBUG Rank %d: evolve_static_mpi END\n", rank);
}

void run_simulation(Config *cfg, int rank, int size) {
    printf("DEBUG Rank %d: run_simulation START - k=%d, file=%s\n", rank, cfg->k, cfg->fname);
    
    unsigned char *local_grid = NULL;
    int local_rows;
    int k = cfg->k;
    
    // Load initial grid using MPI
    printf("DEBUG Rank %d: Calling load_pgm_mpi\n", rank);
    load_pgm_mpi(cfg->fname, &local_grid, &k, &local_rows, rank, size);
    printf("DEBUG Rank %d: After load_pgm_mpi - k=%d, local_rows=%d\n", rank, k, local_rows);
    // ADD VERIFICATION CODE RIGHT HERE 
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Each process verifies its boundary matches neighbors
    if (rank == 0) {
        printf("=== GLOBAL GRID VERIFICATION ===\n");
    }
    
    // Process 0 sends its last row to Process 1 for verification
    if (size > 1) {
        if (rank == 0) {
            // Send last row to process 1
            MPI_Send(&local_grid[(local_rows-1)*k], k, MPI_UNSIGNED_CHAR, 1, 0, MPI_COMM_WORLD);
            printf("Rank 0: Sent my last row to Rank 1\n");
        }
        else if (rank == 1) {
            unsigned char *rank0_last_row = malloc(k * sizeof(unsigned char));
            MPI_Recv(rank0_last_row, k, MPI_UNSIGNED_CHAR, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            
            // Compare with my first row
            int match = 1;
            for (int j = 0; j < k; j++) {
                if (rank0_last_row[j] != local_grid[j]) {
                    match = 0;
                    printf("ERROR: Rank 1 first row[%d] = %d, but Rank 0 last row[%d] = %d\n", 
                           j, local_grid[j], j, rank0_last_row[j]);
                    break;
                }
            }
            
            if (match) {
                printf("SUCCESS: Rank 1 first row MATCHES Rank 0 last row - Global grid is consistent!\n");
            }
            
            free(rank0_last_row);
        }
    }
    MPI_Barrier(MPI_COMM_WORLD);
    // END VERIFICATION CODE    
    double total_time = 0.0, comp_time = 0.0, comm_time = 0.0;
    double start_time = MPI_Wtime();
    
    for (int step = 1; step <= cfg->n; step++) {
        printf("DEBUG Rank %d: Starting step %d\n", rank, step);
        
        double step_comm_time = 0.0;
        double step_comp_start = MPI_Wtime();

        // Static evolution (required by PDF)
        evolve_static_mpi(local_grid, k, local_rows, rank, size, &step_comm_time);
        double step_comp_end = MPI_Wtime();
        comp_time += (step_comp_end - step_comp_start);
        comm_time += step_comm_time;

        // Save snapshot if needed
        if (cfg->s > 0 && step % cfg->s == 0) {
            save_snapshot_mpi(local_grid, k, local_rows, step, rank, size);
        }
        
        printf("DEBUG Rank %d: Completed step %d\n", rank, step);
    }
    
    double end_time = MPI_Wtime();
    total_time = end_time - start_time;
    
    // DEBUG OpenMP
    printf("RANK %d: omp_get_max_threads() = %d\n", rank, omp_get_max_threads());
    printf("RANK %d: OMP_NUM_THREADS = %s\n", rank, getenv("OMP_NUM_THREADS"));

    int nthreads = omp_get_max_threads();
    printf("RANK %d: Using %d threads\n", rank, nthreads);
    
    // Reduce timings to rank 0
    double global_total, global_comp, global_comm;
    MPI_Reduce(&total_time, &global_total, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    MPI_Reduce(&comp_time, &global_comp, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    MPI_Reduce(&comm_time, &global_comm, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    
    if (rank == 0) {
        // Calculate nodes (2 tasks per node as in your job script)
        int nodes = size / 2;
        
        printf("%d,%d,%d,%.6f,%.6f,%.6f\n", 
               nodes, size, nthreads, global_total, global_comp, global_comm);
    }    
    // Save final state
    if (cfg->s == 0) {
        save_snapshot_mpi(local_grid, k, local_rows, cfg->n, rank, size);
    }
    
    free(local_grid);
    printf("DEBUG Rank %d: run_simulation END\n", rank);
}
