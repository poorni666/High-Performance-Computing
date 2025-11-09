#!/bin/bash
#SBATCH -A dssc
#SBATCH -p THIN
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --time=01:30:00
#SBATCH --output=THIN/%j.out
#SBATCH --error=THIN/%j.err

cd "$SLURM_SUBMIT_DIR"

module load openBLAS/0.3.29
export LD_LIBRARY_PATH="$HOME/myblis/lib:$LD_LIBRARY_PATH"

export OMP_NUM_THREADS=12
export BLIS_NUM_THREADS=12

SIZES=(1000 2000 3000 4000 5000 6000 8000 10000 12000 14000 16000 18000)

# Function to extract both time and GFLOPS
extract_metrics() {
    local output="$1"
    local time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+')
    local gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f", $1}')
    echo "$time_sec,$gf"
}

# =============== CLOSE BINDING ===============
echo "[$(date)] Running CLOSE binding..."
export OMP_PROC_BIND=close
export OMP_PLACES=cores
OUT="THIN/close_cores"
LOGDIR="$OUT/logs"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in "${SIZES[@]}"; do
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=12 ./gemm_oblas.x $size $size $size 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_d.txt"
    echo "$size,$time_sec,$gf" >> "$OUT/openblas_d.csv"  # Added time_sec
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=12 ./gemm_blis.x $size $size $size 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_d.txt"
    echo "$size,$time_sec,$gf" >> "$OUT/blis_d.csv"  # Added time_sec
  done
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in "${SIZES[@]}"; do
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=12 ./gemm_oblas.x $size $size $size 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_f.txt"
    echo "$size,$time_sec,$gf" >> "$OUT/openblas_f.csv"  # Added time_sec
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=12 ./gemm_blis.x $size $size $size 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_f.txt"
    echo "$size,$time_sec,$gf" >> "$OUT/blis_f.csv"  # Added time_sec
  done
done

# =============== SPREAD BINDING ===============
echo "[$(date)] Running SPREAD binding..."
export OMP_PROC_BIND=spread
export OMP_PLACES=cores
OUT="THIN/spread_cores"
LOGDIR="$OUT/logs"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in "${SIZES[@]}"; do
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=12 ./gemm_oblas.x $size $size $size 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_d.txt"
    echo "$size,$time_sec,$gf" >> "$OUT/openblas_d.csv"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=12 ./gemm_blis.x $size $size $size 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_d.txt"
    echo "$size,$time_sec,$gf" >> "$OUT/blis_d.csv"
  done
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in "${SIZES[@]}"; do
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=12 ./gemm_oblas.x $size $size $size 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_f.txt"
    echo "$size,$time_sec,$gf" >> "$OUT/openblas_f.csv"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=12 ./gemm_blis.x $size $size $size 2>&1)
    metrics=$(extract_metrics "$output")
    time_sec=$(echo "$metrics" | cut -d',' -f1)
    gf=$(echo "$metrics" | cut -d',' -f2)
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_f.txt"
    echo "$size,$time_sec,$gf" >> "$OUT/blis_f.csv"
  done
done

echo "completed"
