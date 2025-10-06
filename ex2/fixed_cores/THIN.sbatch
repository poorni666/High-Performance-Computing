#!/bin/bash
#SBATCH -A dssc
#SBATCH -p THIN
#SBATCH -N 1
#SBATCH --cpus-per-task=16
#SBATCH --time=01:30:00
#SBATCH --output=THIN/%j.out
#SBATCH --error=THIN/%j.err

cd "$SLURM_SUBMIT_DIR"

# Load modules
module load openBLAS/0.3.29

# Use your pre-built BLIS
export LD_LIBRARY_PATH="$HOME/myblis/lib:$LD_LIBRARY_PATH"

# Ensure executables are rebuilt cleanly
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export BLIS_NUM_THREADS=$SLURM_CPUS_PER_TASK

# =============== CLOSE BINDING ===============
echo "Running CLOSE binding policy..."
export OMP_PROC_BIND=close
export OMP_PLACES=cores
OUT="THIN/close_cores"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in 2000 5000 8000 10000; do
  # OpenBLAS
  RAW_LOG="$OUT/raw_oblas_d_${size}.log"
  srun -n1 --cpus-per-task="$SLURM_CPUS_PER_TASK" ./gemm_oblas.x $size $size $size > "$RAW_LOG" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$RAW_LOG" | awk '{print $1}')
  echo "$size,$gf" >> "$OUT/openblas_d.csv"

  # BLIS
  RAW_LOG="$OUT/raw_blis_d_${size}.log"
  srun -n1 --cpus-per-task="$SLURM_CPUS_PER_TASK" ./gemm_blis.x $size $size $size > "$RAW_LOG" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$RAW_LOG" | awk '{print $1}')
  echo "$size,$gf" >> "$OUT/blis_d.csv"
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in 2000 5000 8000 10000; do
  # OpenBLAS
  RAW_LOG="$OUT/raw_oblas_f_${size}.log"
  srun -n1 --cpus-per-task="$SLURM_CPUS_PER_TASK" ./gemm_oblas.x $size $size $size > "$RAW_LOG" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$RAW_LOG" | awk '{print $1}')
  echo "$size,$gf" >> "$OUT/openblas_f.csv"

  # BLIS
  RAW_LOG="$OUT/raw_blis_f_${size}.log"
  srun -n1 --cpus-per-task="$SLURM_CPUS_PER_TASK" ./gemm_blis.x $size $size $size > "$RAW_LOG" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$RAW_LOG" | awk '{print $1}')
  echo "$size,$gf" >> "$OUT/blis_f.csv"
done

# =============== MIGRATE BINDING ===============
echo "Running MIGRATE binding policy..."
unset OMP_PROC_BIND OMP_PLACES
OUT="THIN/migrate_cores"
mkdir -p "$OUT"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in 2000 5000 8000 10000; do
  # OpenBLAS
  RAW_LOG="$OUT/raw_oblas_d_${size}.log"
  srun -n1 --cpus-per-task="$SLURM_CPUS_PER_TASK" ./gemm_oblas.x $size $size $size > "$RAW_LOG" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$RAW_LOG" | awk '{print $1}')
  echo "$size,$gf" >> "$OUT/openblas_d.csv"

  # BLIS
  RAW_LOG="$OUT/raw_blis_d_${size}.log"
  srun -n1 --cpus-per-task="$SLURM_CPUS_PER_TASK" ./gemm_blis.x $size $size $size > "$RAW_LOG" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$RAW_LOG" | awk '{print $1}')
  echo "$size,$gf" >> "$OUT/blis_d.csv"
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for size in 2000 5000 8000 10000; do
  # OpenBLAS
  RAW_LOG="$OUT/raw_oblas_f_${size}.log"
  srun -n1 --cpus-per-task="$SLURM_CPUS_PER_TASK" ./gemm_oblas.x $size $size $size > "$RAW_LOG" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$RAW_LOG" | awk '{print $1}')
  echo "$size,$gf" >> "$OUT/openblas_f.csv"

  # BLIS
  RAW_LOG="$OUT/raw_blis_f_${size}.log"
  srun -n1 --cpus-per-task="$SLURM_CPUS_PER_TASK" ./gemm_blis.x $size $size $size > "$RAW_LOG" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$RAW_LOG" | awk '{print $1}')
  echo "$size,$gf" >> "$OUT/blis_f.csv"
done

echo "completed"

