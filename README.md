# MASE-PHI Pipeline

This pipeline processes patient data through multiple steps: preprocessing, PhyloWGS analysis, aggregation, and marker selection.

## Local Development (Docker)

### Prerequisites
- Docker
- Docker Compose

### Running Locally
1. Build and run all services:
```bash
docker-compose up --build
```

2. For a specific patient:
```bash
DATA_DIR=/path/to/data PATIENT_ID=ppi_975 docker-compose up
```

## HPC Deployment (Slurm + Singularity)

The pipeline is configured to run on HPC clusters using Slurm for job scheduling. Node selection is handled automatically by Slurm based on the partition and resource requirements specified in the script.

### Job Queuing System

The pipeline uses Slurm's array job feature to efficiently process multiple patients:
```bash
#SBATCH --partition=pool1    # Queue jobs in pool1 partition
#SBATCH --array=0-2         # Process multiple patients in parallel
```

When you submit the job with `sbatch process_patients.sh`:
1. Slurm creates separate jobs for each patient
2. Jobs are queued in the pool1 partition
3. Each job runs when resources are available
4. Progress can be monitored with `squeue -u $USER`

Example queue output:
```
JOBID    PARTITION  NAME      USER     ST  TIME  NODES  NODELIST
123_0    pool1      mase_phi  ssabata  R   0:01  1     compute-0-3
123_1    pool1      mase_phi  ssabata  PD  0:00  1     (None)
123_2    pool1      mase_phi  ssabata  PD  0:00  1     (None)
```
Where `R`=running, `PD`=pending in queue

### Prerequisites
- Access to an HPC cluster with Slurm
- Access to a Singularity module (e.g., `singularity/gcc-v8.3.0`)
- Your data directory containing patient folders

Note: If your HPC doesn't have a generic `singularity` module, you'll need to use one of the available Singularity modules. The scripts are configured to use `singularity/gcc-v8.3.0`, but you can modify this to use any available Singularity module on your system. Check available modules with:
```bash
module avail singularity
```

### Setup Steps

1. Clone this repository on the HPC:
```bash
git clone <repository-url>
cd mase_phi_app
```

2. Make the scripts executable:
```bash
chmod +x setup_mase_phi.sh process_patients.sh
```

3. Edit the data directory path in `process_patients.sh`:
```bash
# Change this line:
export DATA_DIR=/path/to/data  # Set to your actual data path
```

4. Run the setup script (only once):
```bash
./setup_mase_phi.sh
```
This will:
- Create necessary directories
- Convert Docker images to Singularity format
- Prepare the environment

### Running the Pipeline

1. Submit the job to process all patients:
```bash
sbatch process_patients.sh
```

2. Monitor progress:
```bash
# View running jobs
squeue -u $USER

# Check log files
ls logs/

# View specific job output
tail -f logs/mase_phi_*.out
tail -f logs/mase_phi_*.err
```

### Pipeline Configuration

The following parameters can be adjusted in `process_patients.sh`:
- `NUM_BOOTSTRAPS`: Number of bootstrap iterations (default: 5)
- `NUM_CHAINS`: Number of chains for PhyloWGS (default: 5)
- `--array=0-2`: Adjust based on number of patients
- `--cpus-per-task`: CPU cores per task (default: 4)
- `--mem`: Memory per task (default: 16G)
- `--time`: Time limit per task (default: 24:00:00)

### Directory Structure

Your data directory should be organized as follows:
```
data/
├── ppi_975/
│   ├── mafs/
│   │   ├── *CF-*.maf.*
│   │   ├── *ST-*.maf.*
│   │   └── *BC-*.maf.*
│   └── common/
├── ppi_976/
└── ppi_977/
```

### Checkpoint System

The pipeline includes a checkpoint system that:
- Tracks completed steps for each patient
- Allows for job recovery if interrupted
- Skips already completed steps on restart

### Troubleshooting

1. If a job fails:
- Check the error logs in `logs/`
- Remove the corresponding `.completed` marker file to retry a step
- Resubmit the job

2. Common issues:
- Insufficient memory: Adjust `--mem` in `process_patients.sh`
- Time limit exceeded: Adjust `--time` in `process_patients.sh`
- Missing data files: Check your data directory structure

### Notes

- The pipeline processes each patient independently
- Each step creates a marker file upon completion
- Failed steps can be retried by removing the marker file
- All output is preserved in the patient's directory

### 1- PhyloWGS
how to run PhyloWGS:

```
# 1. Navigate to the phylowgs directory
cd /Users/siddharthsabata/Documents/mase_phi_app/1_phylowgs

# 2. Build the Docker image
docker build -t phylowgs .

# 3. Run the container with your data
```
### Run with specific bootstraps (e.g., 1, 3, and 5)
docker run -v /Users/siddharthsabata/Documents/mase_phi_app/data:/data phylowgs 7 1 3 5
```

### how to run app

from the root directory of the project: 
```
docker-compose up --build
``` 