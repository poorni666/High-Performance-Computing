#!/bin/bash
# OpenMP Strong scaling for THIN - using existing THIN folder
GRID=8000
STEPS=500
EXEC="../gol"
RESULTS_DIR="./results/THIN"  # Use existing THIN folder
LOGS_DIR="${RESULTS_DIR}/logs"
CSV="${RESULTS_DIR}/omp_strong.csv"  # OpenMP CSV in THIN folder

# CSV header
echo "threads,total_time,comp_time,comm_time" > "$CSV"

# Pre-generate init file - use existing initials folder
INIT="${RESULTS_DIR}/initials/init_omp_${GRID}.pgm"  # Store in existing initials
if [ ! -f "$INIT" ]; then
    echo "Creating initial file: $INIT"
    mkdir -p "$(dirname "$INIT")"
    $EXEC -i -k $GRID -f "$INIT"
    echo "Initial grid created successfully"
fi

echo "Using initial file: $INIT"

# Test different thread counts
for threads in 1 2 4 6 8 12 16 24; do
    sbatch <<EOF
#!/bin/bash
#SBATCH --partition=THIN
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=$threads
#SBATCH --time=00:30:00
#SBATCH --job-name=omp_${threads}t
#SBATCH --output=${LOGS_DIR}/omp_${threads}t_%j.out  # Logs go to existing logs folder

export OMP_NUM_THREADS=$threads
export OMP_PLACES=cores
export OMP_PROC_BIND=close

echo "Running with OMP_NUM_THREADS=\$OMP_NUM_THREADS"
srun --cpu-bind=cores $EXEC -r -f "$INIT" -n $STEPS
EOF
done

echo "Submitted OpenMP scaling jobs"
