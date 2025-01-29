#!/bin/bash

# Create necessary directories
echo "Creating directories..."
mkdir -p logs
mkdir -p singularity

# Load a Singularity module (using one of the available modules)
echo "Loading Singularity module..."
module load singularity/gcc-v8.3.0

echo "Converting Docker images to Singularity..."
# Pull and convert each image
for service in preprocess phylowgs aggregation markers; do
    echo "Converting mase_phi_app-${service}..."
    sif_file="singularity/mase_phi_app-${service}.sif"
    if [ ! -f "$sif_file" ]; then
        # Assuming your Docker images are in a registry. Replace YOUR_REGISTRY with actual registry
        singularity pull --dir singularity/ sif:mase_phi_app-${service}.sif docker://YOUR_REGISTRY/mase_phi_app-${service}:latest
        if [ $? -ne 0 ]; then
            echo "Error converting ${service} image"
            exit 1
        fi
    else
        echo "Image ${sif_file} already exists, skipping..."
    fi
done

echo "Setup completed successfully!"
echo "You can now run the pipeline using:"
echo "sbatch process_patients.sh" 