#!/bin/bash
set -e  # Exit on error
set -x  # Print commands as they're executed

# Get command line arguments
patient_id="$1"
num_bootstraps="${2:-10}"

# Setup directory structure
input_dir="/data/${patient_id}"
mafs_dir="${input_dir}/mafs"
common_dir="${input_dir}/common"
output_csv="${common_dir}/patient_${patient_id}.csv"

echo "DEBUG: Input directory: ${input_dir}"
echo "DEBUG: MAFs directory: ${mafs_dir}"
echo "DEBUG: Common directory: ${common_dir}"

# Check if input directory exists
if [ ! -d "$input_dir" ]; then
    echo "Error: Patient directory ${input_dir} does not exist"
    exit 1
fi

# Check if MAFs directory exists
if [ ! -d "$mafs_dir" ]; then
    echo "Error: MAFs directory ${mafs_dir} does not exist"
    exit 1
fi

# Find MAF files
echo "Looking for MAF files in ${mafs_dir}..."
cf_maf=$(find "${mafs_dir}" -name "*CF-*.maf.*" -type f)
st_maf=$(find "${mafs_dir}" -name "*ST-*.maf.*" -type f)
bc_maf=$(find "${mafs_dir}" -name "*BC-*.maf.*" -type f)

echo "Found MAF files:"
echo "CF MAF: ${cf_maf}"
echo "ST MAF: ${st_maf}"
echo "BC MAF: ${bc_maf}"

if [ -z "$cf_maf" ] || [ -z "$st_maf" ] || [ -z "$bc_maf" ]; then
    echo "Error: Could not find all required MAF files in ${mafs_dir}"
    echo "CF MAF: ${cf_maf:-not found}"
    echo "ST MAF: ${st_maf:-not found}"
    echo "BC MAF: ${bc_maf:-not found}"
    exit 1
fi

# Create temporary directory for output
temp_dir=$(mktemp -d)
temp_csv="${temp_dir}/temp_output.csv"

# Run MAF aggregation first
echo "Running MAF aggregation for patient ${patient_id}..."
if ! python maf_agg.py \
    --cf_maf "$cf_maf" \
    --st_maf "$st_maf" \
    --bc_maf "$bc_maf" \
    --output_dir "$temp_csv" \
    --method "inner"; then
    echo "ERROR: MAF aggregation failed. No mutations available for analysis."
    rm -rf "$temp_dir"
    exit 1
fi

# Check if output file exists and has content
if [ ! -s "$temp_csv" ]; then
    echo "ERROR: No mutations found in output file"
    rm -rf "$temp_dir"
    exit 1
fi

# Count number of lines (excluding header)
num_mutations=$(( $(wc -l < "$temp_csv") - 1 ))
if [ "$num_mutations" -eq 0 ]; then
    echo "ERROR: No mutations found after filtering"
    rm -rf "$temp_dir"
    exit 1
fi

# If we get here, we have valid mutations
echo "Found $num_mutations mutations"

# Create output directory and move file
mkdir -p "${common_dir}"
mv "$temp_csv" "$output_csv"
rm -rf "$temp_dir"

# Then run bootstrap processing with PhyloWGS output
echo "Running bootstrap processing for patient ${patient_id} with ${num_bootstraps} bootstraps..."
if ! python bootstrap_maf.py \
    --input "$output_csv" \
    --output "${common_dir}" \
    --num_bootstraps "$num_bootstraps" \
    --phylowgs; then
    echo "ERROR: Bootstrap processing failed"
    exit 1
fi

# Only print success if we actually found mutations
if [ "$num_mutations" -gt 0 ]; then
    echo "Preprocessing completed successfully with $num_mutations mutations"
else
    echo "ERROR: No mutations found for analysis"
    exit 1
fi 