#ifndef UTILS_H
#define UTILS_H

#define FNAME_MAX 256

// Give explicit non-zero values
typedef enum {
    INIT = 1,
    RUN = 2
} ActionType;

typedef enum {
    ORDERED = 0,
    STATIC = 1
} EvolutionType;

typedef struct {
    ActionType action;
    int k;
    EvolutionType e;
    char fname[FNAME_MAX];
    int n;
    int s;
} Config;

Config parse_args(int argc, char *argv[]);

#endif
