#!/bin/bash
# OpenMP Strong scaling for EPYC - test NUMA-aware configurations
GRID=8000  # Larger grid for EPYC
STEPS=500
EXEC="../gol"
RESULTS_DIR="./results/EPYC"
LOGS_DIR="${RESULTS_DIR}/logs"
CSV="${RESULTS_DIR}/omp_strong.csv"

mkdir -p "$LOGS_DIR"
echo "threads,total_time,comp_time,comm_time" > "$CSV"

INIT="${RESULTS_DIR}/initials/init_omp_${GRID}.pgm"
if [ ! -f "$INIT" ]; then
    $EXEC -i -k $GRID -f "$INIT"
fi

# Test thread counts that match EPYC's 8 NUMA nodes
for threads in 1 2 4 8 16 32 64 128; do
    sbatch <<EOF
#!/bin/bash
#SBATCH --partition=EPYC
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=$threads
#SBATCH --time=00:30:00
#SBATCH --job-name=omp_epyc_${threads}t
#SBATCH --output=${LOGS_DIR}/omp_${threads}t_%j.out

export OMP_NUM_THREADS=$threads
export OMP_PLACES=cores
export OMP_PROC_BIND=close

echo "Running EPYC OpenMP scaling: 1 node, 1 task, $threads threads"
echo "EPYC Architecture: 2 sockets, 8 NUMA nodes, 128 cores"

srun --cpu-bind=cores \
     $EXEC -r -f "$INIT" -n $STEPS
EOF
done

echo "Submitted EPYC OpenMP scaling jobs"
