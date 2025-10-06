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
N=8000

# (my  core count)
THREADS=(1 2 4 8 16)

# =============== CLOSE BINDING ===============
echo "[$(date)] Running CLOSE binding (N=$N)..."
export OMP_PROC_BIND=close
export OMP_PLACES=cores
OUT="THIN/close_cores"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  srun -n1 --cpus-per-task=16 ./gemm_oblas.x $N $N $N > "$OUT/raw_oblas_d_t${t}.log" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$OUT/raw_oblas_d_t${t}.log" | awk '{printf "%.2f\n", $1}')
  echo "$t,$gf" >> "$OUT/openblas_d.csv"

  srun -n1 --cpus-per-task=16 ./gemm_blis.x $N $N $N > "$OUT/raw_blis_d_t${t}.log" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$OUT/raw_blis_d_t${t}.log" | awk '{printf "%.2f\n", $1}')
  echo "$t,$gf" >> "$OUT/blis_d.csv"
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  srun -n1 --cpus-per-task=16 ./gemm_oblas.x $N $N $N > "$OUT/raw_oblas_f_t${t}.log" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$OUT/raw_oblas_f_t${t}.log" | awk '{printf "%.2f\n", $1}')
  echo "$t,$gf" >> "$OUT/openblas_f.csv"

  srun -n1 --cpus-per-task=16 ./gemm_blis.x $N $N $N > "$OUT/raw_blis_f_t${t}.log" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$OUT/raw_blis_f_t${t}.log" | awk '{printf "%.2f\n", $1}')
  echo "$t,$gf" >> "$OUT/blis_f.csv"
done

# =============== MIGRATE BINDING ===============
echo "[$(date)] Running MIGRATE (default) binding (N=$N)..."
unset OMP_PROC_BIND OMP_PLACES
OUT="THIN/migrate_cores"
mkdir -p "$OUT"

# Double precision
sed -i 's/-DUSE_FLOAT/-DUSE_DOUBLE/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  srun -n1 --cpus-per-task=16 ./gemm_oblas.x $N $N $N > "$OUT/raw_oblas_d_t${t}.log" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$OUT/raw_oblas_d_t${t}.log" | awk '{printf "%.2f\n", $1}')
  echo "$t,$gf" >> "$OUT/openblas_d.csv"

  srun -n1 --cpus-per-task=16 ./gemm_blis.x $N $N $N > "$OUT/raw_blis_d_t${t}.log" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$OUT/raw_blis_d_t${t}.log" | awk '{printf "%.2f\n", $1}')
  echo "$t,$gf" >> "$OUT/blis_d.csv"
done

# Float precision
sed -i 's/-DUSE_DOUBLE/-DUSE_FLOAT/g' Makefile
make clean && make gemm_oblas.x gemm_blis.x

for t in "${THREADS[@]}"; do
  export OMP_NUM_THREADS=$t
  export BLIS_NUM_THREADS=$t
  
  srun -n1 --cpus-per-task=16 ./gemm_oblas.x $N $N $N > "$OUT/raw_oblas_f_t${t}.log" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$OUT/raw_oblas_f_t${t}.log" | awk '{printf "%.2f\n", $1}')
  echo "$t,$gf" >> "$OUT/openblas_f.csv"

  srun -n1 --cpus-per-task=16 ./gemm_blis.x $N $N $N > "$OUT/raw_blis_f_t${t}.log" 2>&1
  gf=$(grep -oE '[0-9]+\.[0-9]+ GFLOPS' "$OUT/raw_blis_f_t${t}.log" | awk '{printf "%.2f\n", $1}')
  echo "$t,$gf" >> "$OUT/blis_f.csv"
done

echo "completed"
