#!/bin/bash
#SBATCH --partition=pool1           # Use pool1 partition (3-day time limit)
#SBATCH --array=0-2%50             # Adjust based on number of patients
#SBATCH --cpus-per-task=5
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=logs/mase_phi_%A_%a_%j.out
#SBATCH --error=logs/mase_phi_%A_%a_%j.err
#SBATCH --job-name=mase_phi

# Load necessary modules
module load singularity/gcc-v8.3.0  # Using gcc version as it's a basic toolchain

# Configuration
export DATA_DIR=/path/to/data  # CHANGE THIS to your data directory
export NUM_BOOTSTRAPS=5
export NUM_CHAINS=5
STEPS=("preprocess" "phylowgs" "aggregation" "markers")

# Get patient ID from array index
patients=($(ls ${DATA_DIR} | grep -v "\."))
patient_id=${patients[$SLURM_ARRAY_TASK_ID]}
patient_dir="${DATA_DIR}/${patient_id}"

# Function to check if step is completed
check_step_completed() {
    local step=$1
    local marker_file="${patient_dir}/.${step}_completed"
    if [ -f "$marker_file" ]; then
        return 0  # Step completed
    fi
    return 1  # Step not completed
}

# Function to mark step as completed
mark_step_completed() {
    local step=$1
    touch "${patient_dir}/.${step}_completed"
}

# Function to run a step
run_step() {
    local step=$1
    local image="mase_phi_app-${step}.sif"
    
    if check_step_completed "$step"; then
        echo "Step $step already completed for patient $patient_id, skipping..."
        return 0
    fi

    echo "Running $step for patient $patient_id"
    
    # Set step-specific parameters
    local cmd_args="${patient_id} ${NUM_BOOTSTRAPS}"
    if [ "$step" == "phylowgs" ]; then
        cmd_args="${patient_id} ${NUM_CHAINS} ${NUM_BOOTSTRAPS}"
    fi

    # Run the step
    if singularity run --bind ${DATA_DIR}:/data "$image" $cmd_args; then
        mark_step_completed "$step"
        return 0
    else
        echo "Error in $step for patient $patient_id"
        return 1
    fi
}

# Create logs directory if it doesn't exist
mkdir -p logs

# Process each step
for step in "${STEPS[@]}"; do
    if ! run_step "$step"; then
        echo "Failed at step $step for patient $patient_id"
        exit 1
    fi
done

echo "Successfully completed all steps for patient $patient_id"

# run with 
# sbatch process_patients.sh

# monitor progress with
# squeue -u $USER  # See running jobs
# ls logs/         # Check log files