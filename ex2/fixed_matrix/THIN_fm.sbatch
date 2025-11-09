#!/bin/bash
#SBATCH -A dssc
#SBATCH -p THIN
#SBATCH -N 1
#SBATCH --cpus-per-task=24   # 12 cores per socket × 2 sockets
#SBATCH --time=01:30:00
#SBATCH --output=THIN/%j.out
#SBATCH --error=THIN/%j.err

cd "$SLURM_SUBMIT_DIR"

module load openBLAS/0.3.29
export LD_LIBRARY_PATH="$HOME/myblis/lib:$LD_LIBRARY_PATH"

# Fixed matrix size
N=5000

# Thread counts - from 1 to 24 cores
THREADS=(1 2 4 6 8 12 16 24)

# Create logs folders
mkdir -p THIN/close_cores/logs THIN/spread_cores/logs

# Function to extract both time and GFLOPS - FIXED
extract_metrics() {
    local output="$1"
    local time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+')
    local gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{print $1}')
    echo "$time_sec,$gf"
}

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
    output=$(srun -n1 --cpus-per-task=24 ./gemm_oblas.x $N $N $N 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    # CSV: threads,time_seconds,gflops
    echo "$t,$time_sec,$gf" >> "$OUT/openblas_d.csv"
    # Raw log: iter, M, K, N, time, GFLOPS
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_d.log"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=24 ./gemm_blis.x $N $N $N 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo "$t,$time_sec,$gf" >> "$OUT/blis_d.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_d.log"
  done
done

# Float precision - FIXED
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=24 ./gemm_oblas.x $N $N $N 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo "$t,$time_sec,$gf" >> "$OUT/openblas_f.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_f.log"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=24 ./gemm_blis.x $N $N $N 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo "$t,$time_sec,$gf" >> "$OUT/blis_f.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_f.log"
  done
done

# =============== SPREAD BINDING ===============
echo "[$(date)] Running SPREAD binding (fixed N=$N)..."
export OMP_PROC_BIND=spread
export OMP_PLACES=cores
OUT="THIN/spread_cores"
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
    output=$(srun -n1 --cpus-per-task=24 ./gemm_oblas.x $N $N $N 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo "$t,$time_sec,$gf" >> "$OUT/openblas_d.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_d.log"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=24 ./gemm_blis.x $N $N $N 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo "$t,$time_sec,$gf" >> "$OUT/blis_d.csv"
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
    output=$(srun -n1 --cpus-per-task=24 ./gemm_oblas.x $N $N $N 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo "$t,$time_sec,$gf" >> "$OUT/openblas_f.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_f.log"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=24 ./gemm_blis.x $N $N $N 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo "$t,$time_sec,$gf" >> "$OUT/blis_f.csv"
    echo -e "$iter\t$N\t$N\t$N\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_f.log"
  done
done

echo "completed"
