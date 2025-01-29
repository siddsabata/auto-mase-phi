# Use Python 3.9 base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy preprocessing scripts
COPY maf_agg.py .
COPY bootstrap_maf.py .

# Create a shell script to run the preprocessing in order
RUN echo '#!/bin/bash\n\
# Get command line arguments\n\
patient_dir="$1"\n\
num_bootstraps="${2:-10}"\n\
\n\
# Extract patient ID from directory name\n\
patient_id=$(basename "$patient_dir")\n\
\n\
# Setup directory structure\n\
input_dir="/data/${patient_dir}"\n\
mafs_dir="${input_dir}/mafs"\n\
common_dir="${input_dir}/common"\n\
output_csv="${common_dir}/patient_${patient_id}.csv"\n\
\n\
# Check if input directory exists\n\
if [ ! -d "$input_dir" ]; then\n\
    echo "Error: Patient directory ${input_dir} does not exist"\n\
    exit 1\n\
fi\n\
\n\
# Check if MAFs directory exists\n\
if [ ! -d "$mafs_dir" ]; then\n\
    echo "Error: MAFs directory ${mafs_dir} does not exist"\n\
    exit 1\n\
fi\n\
\n\
# Create required directories\n\
echo "Creating directory structure..."\n\
mkdir -p "${common_dir}"\n\
\n\
# Find MAF files\n\
echo "Looking for MAF files in ${mafs_dir}..."\n\
cf_maf=$(find "${mafs_dir}" -name "*CF-*.maf.*" -type f)\n\
st_maf=$(find "${mafs_dir}" -name "*ST-*.maf.*" -type f)\n\
bc_maf=$(find "${mafs_dir}" -name "*BC-*.maf.*" -type f)\n\
\n\
if [ -z "$cf_maf" ] || [ -z "$st_maf" ] || [ -z "$bc_maf" ]; then\n\
    echo "Error: Could not find all required MAF files in ${mafs_dir}"\n\
    echo "CF MAF: ${cf_maf:-not found}"\n\
    echo "ST MAF: ${st_maf:-not found}"\n\
    echo "BC MAF: ${bc_maf:-not found}"\n\
    exit 1\n\
fi\n\
\n\
echo "Found MAF files:"\n\
echo "CF MAF: ${cf_maf}"\n\
echo "ST MAF: ${st_maf}"\n\
echo "BC MAF: ${bc_maf}"\n\
\n\
# Run MAF aggregation first\n\
echo "Running MAF aggregation for patient ${patient_id}..."\n\
python maf_agg.py \\\n\
    --cf_maf "$cf_maf" \\\n\
    --st_maf "$st_maf" \\\n\
    --bc_maf "$bc_maf" \\\n\
    --output_dir "$output_csv" \\\n\
    --method "inner"\n\
\n\
# Check if the CSV file was created\n\
if [ ! -f "$output_csv" ]; then\n\
    echo "Error: MAF aggregation failed to create output file: ${output_csv}"\n\
    exit 1\n\
fi\n\
\n\
# Then run bootstrap processing with PhyloWGS output\n\
echo "Running bootstrap processing for patient ${patient_id} with ${num_bootstraps} bootstraps..."\n\
python bootstrap_maf.py \\\n\
    --input "$output_csv" \\\n\
    --output "${common_dir}" \\\n\
    --num_bootstraps "$num_bootstraps" \\\n\
    --phylowgs\n\
\n\
echo "Preprocessing completed successfully"\n\
' > /app/run_preprocess.sh

# Make the script executable
RUN chmod +x /app/run_preprocess.sh

# Default command (can be overridden)
ENTRYPOINT ["/app/run_preprocess.sh"]

# Build and run instructions:
# 1. Build the image (from 0_preprocess directory):
#    docker build -t mase_phi_app-preprocess .
#
# 2. Run the container (from any directory):
#    docker run --rm -v /absolute/path/to/data:/data mase_phi_app-preprocess ppi_975 5
#
# Example for your setup:
#    docker run --rm -v /Users/siddharthsabata/Documents/mase_phi_app/data:/data mase_phi_app-preprocess ppi_975 5 