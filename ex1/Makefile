CC = mpicc
CFLAGS = -O3 -fopenmp -std=c99 -Iinclude
LIBS = -lm

SOURCES = programs/main.c \
          programs/utils.c \
          programs/io.c \
          programs/game_of_life.c 

TARGET = gol

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

clean:
	rm -f $(TARGET) snapshot_*.pgm

.PHONY: clean
