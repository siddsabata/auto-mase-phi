#!/bin/bash

# Error handling: exit if any command fails
set -e

# Check if required environment variables are set
if [ -z "$DATA_DIR" ]; then
    echo "ERROR: DATA_DIR environment variable not set"
    exit 1
fi

if [ -z "$PATIENT_ID" ]; then
    echo "ERROR: PATIENT_ID environment variable not set"
    exit 1
fi

# Debug: Show environment and installation
echo "DEBUG: Environment variables:"
env | sort

echo "DEBUG: Current working directory: $(pwd)"
echo "DEBUG: PhyloWGS directory contents:"
ls -la

echo "DEBUG: Checking PhyloWGS installation:"
echo "DEBUG: mh.o exists: $(test -f mh.o && echo 'Yes' || echo 'No')"
echo "DEBUG: multievolve.py exists: $(test -f multievolve.py && echo 'Yes' || echo 'No')"

# Process each bootstrap
for bootstrap in $(seq 1 5); do
    echo "Processing bootstrap ${bootstrap} for patient ${PATIENT_ID}"
    
    # Set paths
    BOOTSTRAP_DIR="${DATA_DIR}/${PATIENT_ID}/common/bootstrap${bootstrap}"
    SSM_FILE="${BOOTSTRAP_DIR}/ssm_data_bootstrap${bootstrap}.txt"
    CNV_FILE="${BOOTSTRAP_DIR}/cnv_data_bootstrap${bootstrap}.txt"
    
    echo "DEBUG: Bootstrap directory: ${BOOTSTRAP_DIR}"
    echo "DEBUG: SSM file: ${SSM_FILE}"
    echo "DEBUG: CNV file: ${CNV_FILE}"
    
    # Check files
    if [ ! -f "$SSM_FILE" ]; then
        echo "ERROR: SSM file not found at ${SSM_FILE}"
        echo "DEBUG: Directory contents:"
        ls -la "${BOOTSTRAP_DIR}"
        exit 1
    fi
    
    echo "DEBUG: SSM file contents:"
    cat "$SSM_FILE"
    
    # Create directories
    mkdir -p "${BOOTSTRAP_DIR}/chains"
    mkdir -p "${BOOTSTRAP_DIR}/tmp"
    
    # Run PhyloWGS
    echo "Running multievolve.py for bootstrap ${bootstrap}"
    python2 multievolve.py \
        --num-chains 5 \
        --ssms "$SSM_FILE" \
        --cnvs "$CNV_FILE" \
        --output-dir "${BOOTSTRAP_DIR}/chains" \
        --tmp-dir "${BOOTSTRAP_DIR}/tmp"
done

echo "All bootstraps completed successfully"