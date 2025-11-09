#!/bin/bash
# Weak scaling for EPYC nodes - multiple thread counts like friend
#SBATCH --partition=EPYC
BASE_LOCAL=4000  # Local grid per MPI task: 4000x4000
STEPS=500
THREADS_LIST=(4 8 12 16 32 64)  # Multiple thread counts like your friend
EXEC="../gol"
RESULTS_DIR="./results/EPYC"
LOGS_DIR="${RESULTS_DIR}/logs"
INIT_DIR="${RESULTS_DIR}/initials"
CSV="${RESULTS_DIR}/static_weak.csv"

# Create directories
mkdir -p "$RESULTS_DIR" "$LOGS_DIR" "$INIT_DIR"

# Create CSV header
echo "nodes,tasks,threads,local_size,global_size,total_time,comp_time,comm_time" > "$CSV"

for nodes in 1 2 3; do
    tasks=$((nodes * 2))  # 2 MPI tasks per node
    
    # Weak scaling - keep work per process constant
    scale=$(echo "scale=5; sqrt($nodes)" | bc -l)
    global_k=$(printf "%.0f" "$(echo "$BASE_LOCAL * $scale" | bc -l)")
    
    # Local size per process (for CSV)
    local_rows=$((global_k / tasks))
    local_size="${global_k}x${local_rows}"
    global_size="${global_k}x${global_k}"
    
    INIT="${INIT_DIR}/init_weak_${global_k}.pgm"

    # Create init file
    if [ ! -f "$INIT" ]; then
        $EXEC -i -k $global_k -f "$INIT"
    fi

    # Submit jobs for EACH thread count
    for threads in "${THREADS_LIST[@]}"; do
        sbatch <<EOF
#!/bin/bash
#SBATCH --partition=EPYC
#SBATCH --nodes=$nodes
#SBATCH --ntasks=$tasks
#SBATCH --cpus-per-task=$threads
#SBATCH --time=01:30:00
#SBATCH --job-name=gol_weak_${nodes}N_${threads}t
#SBATCH --output=${LOGS_DIR}/weak_${nodes}N_${threads}t_%j.out

export OMP_NUM_THREADS=$threads
export OMP_PLACES=cores
export OMP_PROC_BIND=close

echo "Running EPYC weak scaling: $nodes nodes, $tasks tasks, $threads threads, global size ${global_k}x${global_k}"

srun --cpu-bind=cores \
     $EXEC -r -f "$INIT" -n $STEPS
EOF
    done
done
