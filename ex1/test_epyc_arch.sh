#!/bin/bash
# Test job to check EPYC architecture
#SBATCH --partition=EPYC
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --job-name=epyc_test
#SBATCH --output=results/EPYC/epyc_arch_test.out

echo "=== EPYC Node Architecture ==="
echo "Hostname: $(hostname)"
echo

echo "=== CPU Information ==="
lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket|NUMA node"
echo

echo "=== Memory Information ==="
numactl -H
echo

echo "=== SLURM Environment ==="
env | grep SLURM | sort
echo

echo "=== OMP Environment ==="
env | grep OMP | sort

