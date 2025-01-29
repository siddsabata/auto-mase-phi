# Use Python 3.9 base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all Python files
COPY *.py .

# Create a shell script to run the aggregation
RUN echo '#!/bin/bash\n\
# Get command line arguments\n\
patient_id="$1"\n\
num_bootstraps="${2:-5}"\n\
\n\
# Setup paths\n\
data_dir="/data/${patient_id}"\n\
common_dir="${data_dir}/common"\n\
\n\
# Check if directories exist\n\
if [ ! -d "$data_dir" ] || [ ! -d "$common_dir" ]; then\n\
    echo "Error: Required directories not found"\n\
    echo "Looking for: $data_dir and $common_dir"\n\
    exit 1\n\
fi\n\
\n\
# Run the aggregation script\n\
echo "Running aggregation for patient ${patient_id} with ${num_bootstraps} bootstraps..."\n\
python process_tracerx_bootstrap.py \\\n\
    ${patient_id} \\\n\
    --bootstrap-list $(seq -s " " 1 ${num_bootstraps}) \\\n\
    --base-dir /data\n\
' > /app/run_aggregation.sh

# Make the script executable
RUN chmod +x /app/run_aggregation.sh

# Set volume for data
VOLUME ["/data"]

# Default command
ENTRYPOINT ["/app/run_aggregation.sh"]

# Build command: docker build -t mase_phi_app-aggregation .
# Run command: docker run --rm -v /path/to/data:/data mase_phi_app-aggregation ppi_975 5