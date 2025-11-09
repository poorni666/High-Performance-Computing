#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mpi.h>
#include "io.h"

// PGM functions from your friend's working code
void write_pgm_image(void *image, int maxval, int xsize, int ysize, const char *image_name) {
    FILE* image_file = fopen(image_name, "wb");
    if (!image_file) {
        perror("Error: Failed to open image file for writing");
        return;
    }
    fprintf(image_file, "P5\n%d %d\n%d\n", xsize, ysize, maxval);
    fwrite(image, 1, xsize * ysize, image_file);
    fclose(image_file);
}

void read_pgm_image(void **image, int *maxval, int *xsize, int *ysize, const char *image_name) {
    FILE* image_file = fopen(image_name, "rb");
    if (image_file == NULL) {
        perror("Error opening file for reading");
        *maxval = -1;
        return;
    }

    char magic[3];
    fscanf(image_file, "%2s", magic);
    if (magic[0] != 'P' || magic[1] != '5') {
        fprintf(stderr, "Error: Incorrect file format (not a P5 PGM).\n");
        *maxval = -1;
        fclose(image_file);
        return;
    }

    // Skip whitespace and comments
    int c;
    while ((c = fgetc(image_file)) == ' ' || c == '\n' || c == '\r' || c == '\t');
    if (c == '#') {
        while (fgetc(image_file) != '\n');
    } else {
        ungetc(c, image_file);
    }

    if (fscanf(image_file, "%d %d", xsize, ysize) != 2) {
        fprintf(stderr, "Error: Could not read width and height.\n");
        *maxval = -1;
        fclose(image_file);
        return;
    }

    if (fscanf(image_file, "%d", maxval) != 1) {
        fprintf(stderr, "Error: Could not read max value.\n");
        *maxval = -1;
        fclose(image_file);
        return;
    }

    fgetc(image_file); // Consume whitespace

    size_t size = (size_t)(*xsize) * (*ysize);
    *image = malloc(size);
    if (*image == NULL) {
        fprintf(stderr, "Error: Could not allocate memory for image.\n");
        *maxval = -2;
        fclose(image_file);
        return;
    }

    if (fread(*image, 1, size, image_file) != size) {
        fprintf(stderr, "Error: Mismatch in image size while reading.\n");
        free(*image);
        *image = NULL;
        *maxval = -3;
        fclose(image_file);
        return;
    }

    fclose(image_file);
}

// Use the direct functions
unsigned char* load_pgm(const char *filename, int *k) {
    unsigned char *img = NULL;
    int maxval, x, y;
    
    read_pgm_image((void**)&img, &maxval, &x, &y, filename);
    
    if (maxval < 0) {
        fprintf(stderr, "Error reading PGM file\n");
        exit(1);
    }
    if (x != y) {
        fprintf(stderr, "Error: Grid must be square (got %dx%d)\n", x, y);
        exit(1);
    }
    *k = x;
    return img;
}

void save_pgm(const char *filename, unsigned char *grid, int k) {
    write_pgm_image(grid, 255, k, k, filename);
}

void save_snapshot(unsigned char *grid, int k, int step) {
    char name[64];
    snprintf(name, sizeof(name), "snapshot_%05d.pgm", step);
    save_pgm(name, grid, k);
}

// MPI version: load and scatter grid to all processes
void load_pgm_mpi(const char *filename, unsigned char **local_grid, int *k, 
                  int *local_rows, int rank, int size) {
    unsigned char *global_grid = NULL;
    
    if (rank == 0) {
        global_grid = load_pgm(filename, k);
    }
    
    // Broadcast grid size to all processes
    MPI_Bcast(k, 1, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Calculate local dimensions
    *local_rows = (*k) / size;
    int remainder = (*k) % size;
    if (rank < remainder) {
        (*local_rows)++;
    }
    
    // Allocate local grid
    *local_grid = malloc((*local_rows) * (*k) * sizeof(unsigned char));
    
    // Create send counts and displacements
    int *sendcounts = NULL;
    int *displs = NULL;
    
    if (rank == 0) {
    sendcounts = malloc(size * sizeof(int));
    displs = malloc(size * sizeof(int));

    for (int i = 0; i < size; i++) {
        int rows_for_task = (*k) / size + (i < remainder ? 1 : 0);
        sendcounts[i] = rows_for_task * (*k);
        displs[i] = (i * ((*k) / size) + (i < remainder ? i : remainder)) * (*k);
    }
}

    // Scatter data
    MPI_Scatterv(global_grid, sendcounts, displs, MPI_UNSIGNED_CHAR,
                 *local_grid, (*local_rows) * (*k), MPI_UNSIGNED_CHAR,
                 0, MPI_COMM_WORLD);

    if (rank == 0) {
        free(global_grid);
        free(sendcounts);
        free(displs);
    }
}

// MPI version: gather all local grids and save
void save_pgm_mpi(const char *filename, unsigned char *local_grid, int k, 
                  int local_rows, int rank, int size) {
    unsigned char *global_grid = NULL;
    
    if (rank == 0) {
        global_grid = malloc(k * k * sizeof(unsigned char));
    }

    // Create receive counts and displacements
    int *recvcounts = NULL;
    int *displs = NULL;
    
    if (rank == 0) {
        recvcounts = malloc(size * sizeof(int));
        displs = malloc(size * sizeof(int));

        int offset = 0;
        for (int i = 0; i < size; i++) {
            int rows_for_task = k / size + (i < (k % size) ? 1 : 0);
            recvcounts[i] = rows_for_task * k;
            displs[i] = offset * k;
            offset += rows_for_task;
        }
    }
    
    // Gather data
    MPI_Gatherv(local_grid, local_rows * k, MPI_UNSIGNED_CHAR,
                global_grid, recvcounts, displs, MPI_UNSIGNED_CHAR,
                0, MPI_COMM_WORLD);
    
    if (rank == 0) {
        save_pgm(filename, global_grid, k);
        free(global_grid);
        free(recvcounts);
        free(displs);
    }
}

void save_snapshot_mpi(unsigned char *local_grid, int k, int local_rows, 
                       int step, int rank, int size) {
    char name[64];
    snprintf(name, sizeof(name), "snapshot_%05d.pgm", step);
    save_pgm_mpi(name, local_grid, k, local_rows, rank, size);
}
