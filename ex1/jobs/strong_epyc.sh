#!/bin/bash
# Strong scaling for EPYC - optimized for 2 sockets, 8 NUMA nodes
GRID=24000  # Larger grid for EPYC's 512GB memory
STEPS=500
EXEC="../gol"
RESULTS_DIR="./results/EPYC"
LOGS_DIR="${RESULTS_DIR}/logs"
INIT_DIR="${RESULTS_DIR}/initials"
CSV="${RESULTS_DIR}/static_strong.csv"

mkdir -p "$LOGS_DIR" "$INIT_DIR"
echo "nodes,tasks,threads,total_time,comp_time,comm_time" > "$CSV"

# Pre-generate init file
INIT="${INIT_DIR}/init_strong_${GRID}.pgm"
if [ ! -f "$INIT" ]; then
    $EXEC -i -k $GRID -f "$INIT"
fi

# 8 tasks/node (1 per NUMA node) with 16 threads each
for nodes in 1 2 4; do
    tasks=$((nodes * 8))
    THREADS=16

    sbatch <<EOF
#!/bin/bash
#SBATCH --partition=EPYC
#SBATCH --nodes=$nodes
#SBATCH --ntasks=$tasks
#SBATCH --cpus-per-task=$THREADS
#SBATCH --time=01:30:00
#SBATCH --job-name=gol_strong_epyc_${nodes}N
#SBATCH --output=${LOGS_DIR}/strong_${nodes}N_%j.out

# Optimize for EPYC NUMA architecture
export OMP_NUM_THREADS=$THREADS
export OMP_PLACES=cores
export OMP_PROC_BIND=close

echo "Running EPYC strong scaling: $nodes nodes, $tasks tasks, $THREADS threads"
echo "EPYC Architecture: 2 sockets, 8 NUMA nodes, 128 cores total"

srun --cpu-bind=cores \
     $EXEC -r -f "$INIT" -n $STEPS
EOF
done

echo "Submitted EPYC strong scaling jobs"
