#!/bin/bash
# Strong scaling - 3 nodes only
GRID=16000
STEPS=500
THREADS=12
EXEC="../gol"
RESULTS_DIR="./results/THIN"
LOGS_DIR="${RESULTS_DIR}/logs"
INIT_DIR="${RESULTS_DIR}/initials"

# Pre-generate init file (if not exists)
INIT="${INIT_DIR}/init_strong_${GRID}.pgm"
if [ ! -f "$INIT" ]; then
    $EXEC -i -k $GRID -f "$INIT"
fi

# Submit only the 3-node job
nodes=3
tasks=$((nodes * 2))

sbatch <<EOF
#!/bin/bash
#SBATCH --partition=THIN
#SBATCH --nodes=$nodes
#SBATCH --ntasks=$tasks
#SBATCH --cpus-per-task=$THREADS
#SBATCH --time=01:30:00
#SBATCH --job-name=gol_strong_3N
#SBATCH --output=${LOGS_DIR}/strong_3N_%j.out

# Set OpenMP environment
export OMP_NUM_THREADS=$THREADS
export OMP_PLACES=cores
export OMP_PROC_BIND=close

# Debug info
echo "JOB_DEBUG: OMP_NUM_THREADS = \$OMP_NUM_THREADS"
echo "JOB_DEBUG: SLURM_CPUS_PER_TASK = \$SLURM_CPUS_PER_TASK"
echo "JOB_DEBUG: Running with nodes=$nodes, tasks=$tasks, threads=$THREADS"

srun --cpu-bind=cores \
     $EXEC -r -f "$INIT" -n $STEPS
EOF

echo "Submitted 3-node job"
