#!/bin/bash

# Create necessary directories
echo "Creating directories..."
mkdir -p logs

# Load a Singularity module (using one of the available modules)
echo "Loading Singularity module..."
module load singularity/gcc-v8.3.0  # Using gcc version as it's a basic toolchain

echo "Converting Docker images to Singularity..."
# Pull and convert each image
for service in preprocess phylowgs aggregation markers; do
    echo "Converting mase_phi_app-${service}..."
    if [ ! -f "mase_phi_app-${service}.sif" ]; then
        singularity pull docker://mase_phi_app-${service}
        if [ $? -ne 0 ]; then
            echo "Error converting ${service} image"
            exit 1
        fi
    else
        echo "Image mase_phi_app-${service}.sif already exists, skipping..."
    fi
done

echo "Setup completed successfully!"
echo "You can now run the pipeline using:"
echo "sbatch process_patients.sh" 