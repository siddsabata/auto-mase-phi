# Use Python 3.9 base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    graphviz \
    python3-pyqt5 \
    qtbase5-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all Python files
COPY *.py .

# Create a shell script to run the marker selection
RUN echo '#!/bin/bash\n\
# Get command line arguments\n\
patient_id="$1"\n\
num_bootstraps="${2:-5}"\n\
\n\
# Setup paths\n\
data_dir="/data/${patient_id}"\n\
common_dir="${data_dir}/common"\n\
aggregation_dir="${common_dir}/aggregation"\n\
\n\
# Check if directories exist\n\
if [ ! -d "$data_dir" ] || [ ! -d "$common_dir" ] || [ ! -d "$aggregation_dir" ]; then\n\
    echo "Error: Required directories not found"\n\
    echo "Looking for: $data_dir, $common_dir, and $aggregation_dir"\n\
    exit 1\n\
fi\n\
\n\
# Check if required files exist\n\
csv_file="${common_dir}/patient_${patient_id}.csv"\n\
pkl_file="${aggregation_dir}/phylowgs_bootstrap_aggregation.pkl"\n\
\n\
if [ ! -f "$csv_file" ] || [ ! -f "$pkl_file" ]; then\n\
    echo "Error: Required files not found"\n\
    echo "Looking for:"\n\
    echo "  - $csv_file"\n\
    echo "  - $pkl_file"\n\
    exit 1\n\
fi\n\
\n\
# Run the marker selection script\n\
echo "Running marker selection for patient ${patient_id}..."\n\
python run_data.py \\\n\
    ${patient_id} \\\n\
    --bootstrap-list $(seq -s " " 1 ${num_bootstraps})\n\
' > /app/run_markers.sh

# Make the script executable
RUN chmod +x /app/run_markers.sh

# Set volume for data
VOLUME ["/data"]

# Default command
ENTRYPOINT ["/app/run_markers.sh"]

# Build command: docker build -t mase_phi_app-markers .
# Run command: docker run --rm -v /path/to/data:/data mase_phi_app-markers ppi_975 5 