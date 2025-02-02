#!/bin/bash
set -e

# Initialize the module system
if [ -f /etc/profile.d/modules.sh ]; then
    source /etc/profile.d/modules.sh
elif [ -f /usr/share/Modules/init/bash ]; then
    source /usr/share/Modules/init/bash
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p logs
mkdir -p singularity

echo "Loading Singularity module..."
# First purge any loaded modules to start clean
module purge

# Load the singularity module
if ! module load singularity; then
    echo "Error: Could not load singularity module"
    echo "Available modules:"
    module avail
    exit 1
fi

# Verify singularity is available
if ! command -v singularity &> /dev/null; then
    echo "Error: singularity command not found after loading module"
    echo "Available modules:"
    module avail
    exit 1
fi

echo "Converting Docker images to Singularity..."
# Pull and convert each image
for service in preprocess phylowgs aggregation markers; do
    echo "Converting mase_phi_app-${service}..."
    sif_file="singularity/mase_phi_app-${service}.sif"
    if [ ! -f "$sif_file" ]; then
        # Assuming your Docker images are in a registry. Replace YOUR_REGISTRY with actual registry
        apptainer pull --dir singularity/ sif:mase_phi_app-${service}.sif docker://YOUR_REGISTRY/mase_phi_app-${service}:latest
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