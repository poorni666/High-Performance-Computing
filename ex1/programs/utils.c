#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <stdio.h>
#include "utils.h"

Config parse_args(int argc, char *argv[]) {
    Config cfg = {0};
    cfg.e = STATIC;  // Default to static evolution
    cfg.n = 1000;
    cfg.s = 0;
    strcpy(cfg.fname, "game_of_life.pgm");

    char *optstring = "irk:e:f:n:s:";
    int c;
    while ((c = getopt(argc, argv, optstring)) != -1) {
        switch (c) {
            case 'i': cfg.action = INIT; break;
            case 'r': cfg.action = RUN; break;
            case 'k': cfg.k = atoi(optarg); break;
            case 'e': cfg.e = atoi(optarg); break;
            case 'f': strncpy(cfg.fname, optarg, FNAME_MAX - 1); break;
            case 'n': cfg.n = atoi(optarg); break;
            case 's': cfg.s = atoi(optarg); break;
            default: 
                fprintf(stderr, "Usage: %s [-i] [-r] [-k size] [-e type] [-f file] [-n steps] [-s seed]\n", argv[0]);
                exit(1);
        }
    }

    //FIX
    if (cfg.action == INIT && cfg.k <= 0) {
        fprintf(stderr, "Error: Grid size -k must be specified and positive in -i mode\n");
        exit(1);
    }

    // In RUN mode, cfg.k can be 0 — it will be read from the PGM file later

    if (cfg.action == 0) {
        fprintf(stderr, "Error: specify -i (initialize) or -r (run)\n");
        exit(1);
    }

    return cfg;
}
