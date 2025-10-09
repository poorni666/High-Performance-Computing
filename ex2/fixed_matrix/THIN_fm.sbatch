#!/bin/bash
#SBATCH -A dssc
#SBATCH -p THIN
#SBATCH -N 1
#SBATCH --cpus-per-task=16   
#SBATCH --time=02:00:00
#SBATCH --output=THIN/%j.out
#SBATCH --error=THIN/%j.err

cd "$SLURM_SUBMIT_DIR"

module load openBLAS/0.3.29
export LD_LIBRARY_PATH="$HOME/myblis/lib:$LD_LIBRARY_PATH"

# Fixed matrix size
N=5000

# Thread counts
THREADS=(1 2 4 8 16)  

# logs folders
mkdir -p THIN/close_cores/logs THIN/migrate_cores/logs

# =============== CLOSE BINDING ===============
echo "[$(date)] Running CLOSE binding (fixed N=$N)..."
export OMP_PROC_BIND=close
export OMP_PLACES=cores
OUT="THIN/close_cores"
LOGDIR="$OUT/logs"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_oblas.x $N $N $N 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    # CSV: threads,GFLOPS
    echo "$t,$gf" >> "$OUT/openblas_d.csv"
    # Raw log: iter, M, K, N, time, GFLOPS
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_d.log"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_blis.x $N $N $N 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo "$t,$gf" >> "$OUT/blis_d.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_d.log"
  done
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_oblas.x $N $N $N 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo "$t,$gf" >> "$OUT/openblas_f.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_f.log"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_blis.x $N $N $N 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo "$t,$gf" >> "$OUT/blis_f.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_f.log"
  done
done

# =============== MIGRATE BINDING ===============
echo "[$(date)] Running MIGRATE binding (fixed N=$N)..."
unset OMP_PROC_BIND OMP_PLACES
OUT="THIN/migrate_cores"
LOGDIR="$OUT/logs"
mkdir -p "$LOGDIR"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_oblas.x $N $N $N 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo "$t,$gf" >> "$OUT/openblas_d.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_d.log"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_blis.x $N $N $N 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo "$t,$gf" >> "$OUT/blis_d.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_d.log"
  done
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_oblas.x $N $N $N 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo "$t,$gf" >> "$OUT/openblas_f.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_f.log"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_blis.x $N $N $N 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo "$t,$gf" >> "$OUT/blis_f.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_f.log"
  done
done

echo "completed"
