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

export OMP_NUM_THREADS=16
export BLIS_NUM_THREADS=16

SIZES=(1000 1500 2000 3000 4000 5000 6000 8000 10000 12000)

# =============== CLOSE BINDING ===============
echo "[$(date)] Running CLOSE binding..."
export OMP_PROC_BIND=close
export OMP_PLACES=cores
OUT="THIN/close_cores"
LOGDIR="$OUT/logs"
mkdir -p "$LOGDIR"  # Create logs/ folder

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in "${SIZES[@]}"; do
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_oblas.x $size $size $size 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_d.log"
    echo "$size,$gf" >> "$OUT/openblas_d.csv"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_blis.x $size $size $size 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_d.log"
    echo "$size,$gf" >> "$OUT/blis_d.csv"
  done
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in "${SIZES[@]}"; do
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_oblas.x $size $size $size 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_f.log"
    echo "$size,$gf" >> "$OUT/openblas_f.csv"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_blis.x $size $size $size 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_f.log"
    echo "$size,$gf" >> "$OUT/blis_f.csv"
  done
done

# =============== MIGRATE BINDING ===============
echo "[$(date)] Running MIGRATE binding..."
unset OMP_PROC_BIND OMP_PLACES
OUT="THIN/migrate_cores"
LOGDIR="$OUT/logs"
mkdir -p "$LOGDIR"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in "${SIZES[@]}"; do
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_oblas.x $size $size $size 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_d.log"
    echo "$size,$gf" >> "$OUT/openblas_d.csv"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_blis.x $size $size $size 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_d.log"
    echo "$size,$gf" >> "$OUT/blis_d.csv"
  done
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in "${SIZES[@]}"; do
  for iter in {1..5}; do
    # OpenBLAS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_oblas.x $size $size $size 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_oblas_f.log"
    echo "$size,$gf" >> "$OUT/openblas_f.csv"
    
    # BLIS
    output=$(srun -n1 --cpus-per-task=16 ./gemm_blis.x $size $size $size 2>&1)
    time_sec=$(echo "$output" | grep -oE 'Time:[[:space:]]*[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$')
    gf=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+ GFLOPS' | awk '{printf "%.2f\n", $1}')
    
    echo -e "$iter\t$size\t$size\t$size\t$time_sec\t$gf" >> "$LOGDIR/raw_blis_f.log"
    echo "$size,$gf" >> "$OUT/blis_f.csv"
  done
done

echo "completed"
