#!/bin/bash

# Error handling: exit if any command fails
set -e

# Variables
DATA_PATH="/data"  # Mount point in Docker container
PHYLOWGS_PATH="/app/phylowgs"  # PhyloWGS code location in container
PATIENT=$1  # first argument is patient ID
NUM_CHAINS=${2:-4}  # second argument is number of chains, default to 4 if not provided
NUM_BOOTSTRAPS=${3:-1}  # third argument is number of bootstraps to process, default to 1

# Debug: Show mount points
echo "Mount points:"
mount

# Debug: Show environment
echo "Environment:"
env

# Check arguments
if [ -z "$PATIENT" ]; then
    echo "Usage: script.sh <PATIENT> <NUM_CHAINS> <NUM_BOOTSTRAPS>"
    echo "Example: script.sh ppi_975 4 5"
    exit 1
fi

# Create patient directory if it doesn't exist
PATIENT_DIR="$DATA_PATH/$PATIENT"
mkdir -p "$PATIENT_DIR/common"

echo "Processing patient $PATIENT with $NUM_CHAINS chains for $NUM_BOOTSTRAPS bootstraps"

# Process bootstraps sequentially from 1 to NUM_BOOTSTRAPS
for ((i=1; i<=$NUM_BOOTSTRAPS; i++)); do
    echo "Processing bootstrap $i for patient $PATIENT"
    
    # Debug: Show exact paths and file contents
    SSM_FILE="$DATA_PATH/$PATIENT/common/bootstrap$i/ssm_data_bootstrap$i.txt"
    echo "Looking for SSM file at: $SSM_FILE"
    echo "Directory contents:"
    ls -la "$DATA_PATH/$PATIENT/common/bootstrap$i/" || true
    
    if [ -f "$SSM_FILE" ]; then
        echo "File exists. First few lines:"
        head "$SSM_FILE"
    else
        echo "File does not exist. Parent directory contents:"
        ls -la "$DATA_PATH/$PATIENT/common/"
        echo "Skipping bootstrap $i - SSM file not found"
        continue
    fi
    
    # Create bootstrap directory and empty cnv file
    BOOTSTRAP_DIR="$DATA_PATH/$PATIENT/common/bootstrap$i"
    mkdir -p "$BOOTSTRAP_DIR"
    touch "$BOOTSTRAP_DIR/cnv_data.txt"

    # Run PhyloWGS for this bootstrap
    cd $PHYLOWGS_PATH
    echo "Running multievolve.py for bootstrap $i"
    python2 ./multievolve.py --num-chains $NUM_CHAINS \
        --ssms "$SSM_FILE" \
        --cnvs "$BOOTSTRAP_DIR/cnv_data.txt" \
        --output-dir "$BOOTSTRAP_DIR/chains"

    echo "Running write_results.py for bootstrap $i"
    python2 ./write_results.py --include-ssm-names result \
        "$BOOTSTRAP_DIR/chains/trees.zip" \
        "$BOOTSTRAP_DIR/result.summ.json.gz" \
        "$BOOTSTRAP_DIR/result.muts.json.gz" \
        "$BOOTSTRAP_DIR/result.mutass.zip"
        
    echo "Completed bootstrap $i"
done

echo "All bootstraps completed successfully"