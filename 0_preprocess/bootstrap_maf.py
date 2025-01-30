import pandas as pd
import numpy as np
import os
import argparse
from pathlib import Path
import logging
import sys

"""
The purpose of this script is to perform bootstrapping on the aggregated MAF data. 

This is the second step in the Mase-phi pipeline, as we are processing the aggregated MAF data to 
be used in PhyloWGS (or whatever other model we want to use). 

The script will take in the aggregated MAF data (from maf_agg.py). 

This script will then output an original SSM file given by the inputted MAF file, a CSV file with the bootstrapped data, 
and n directories, each containing a bootstrapped SSM file to be used by PhyloWGS. 

example: usage 
python bootstrap_maf.py -i <merged csv file> -o <output directory> -n <number of bootstraps> -p <generate phylowgs input>

NOTE: for -p you don't have to add anything after the flag. If you want phylowgs output, you must add the flag. 

The bootstrapping process:
1. First resamples read depths while maintaining total coverage
2. Then resamples variant frequencies using the new depths
3. Repeats this process n times to create bootstrap replicates

TODO: is there a better way to do this? scipy.stats.bootstrap?
"""

# Set up logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def bootstrap_va_dt(AF_list, Depth_list, bootstrap_num):
    """
    Advanced bootstrapping of both depths and frequencies
    
    Args:
        AF_list: List of allele frequencies
        Depth_list: List of read depths
        bootstrap_num: Number of bootstrap samples
    
    Returns:
        Tuple of (bootstrapped frequencies, bootstrapped depths)
    """
    AF_array = np.array(AF_list)
    Depth_array = np.array(Depth_list)
    total_depth = sum(Depth_list)
    
    count = 0
    while True:
        count += 1
        new_Depth_list = np.random.multinomial(n=total_depth, 
                                             pvals=np.array(Depth_list)/total_depth, 
                                             size=bootstrap_num)
        
        if not np.any(new_Depth_list == 0):
            break
            
        if count >= 10:
            new_Depth_list[np.where(new_Depth_list == 0)] = 1
            break
    
    AF_list_update = np.zeros((len(AF_list), bootstrap_num))
    for i in range(len(AF_list)):
        for j in range(bootstrap_num):
            sample = np.random.binomial(n=new_Depth_list[j, i], 
                                      p=AF_list[i], 
                                      size=1)[0]
            AF_list_update[i, j] = sample / new_Depth_list[j, i]
    
    new_Depth_list = new_Depth_list.T
    return AF_list_update, new_Depth_list

def bootstrap_maf(maf_df, num_bootstraps):
    """Performs bootstrapping on aggregated MAF data"""
    logging.debug("Starting bootstrap process...")
    logging.debug(f"Input DataFrame shape: {maf_df.shape}")
    print("DEBUG: Input columns:")
    print(maf_df.columns)
    
    df_bootstrap = maf_df.copy()
    
    # Process tissue data
    tissue_af = maf_df["Variant_Frequencies_st"].tolist()
    tissue_depth = maf_df["Total_Depth_st"].tolist()
    
    print("DEBUG: Tissue data:")
    print(f"Number of VAFs: {len(tissue_af)}")
    print(f"Number of depths: {len(tissue_depth)}")
    
    tissue_af_boot, tissue_depth_boot = bootstrap_va_dt(tissue_af, tissue_depth, num_bootstraps)
    
    print("DEBUG: Bootstrap results:")
    print(f"VAF bootstrap shape: {tissue_af_boot.shape}")
    print(f"Depth bootstrap shape: {tissue_depth_boot.shape}")
    
    # Create column names
    tissue_af_cols = [f"Variant_Frequencies_st_bootstrap_{i+1}" for i in range(num_bootstraps)]
    tissue_depth_cols = [f"Total_Depth_st_bootstrap_{i+1}" for i in range(num_bootstraps)]
    
    # Add bootstrapped columns
    df_bootstrap = pd.concat([
        df_bootstrap,
        pd.DataFrame(tissue_af_boot, columns=tissue_af_cols),
        pd.DataFrame(tissue_depth_boot, columns=tissue_depth_cols)
    ], axis=1)
    
    print("DEBUG: Final DataFrame shape:", df_bootstrap.shape)
    print("DEBUG: Final columns:", df_bootstrap.columns)
    
    return df_bootstrap

def write_phylowgs_input(bootstrap_df, output_path):
    """Write PhyloWGS input files"""
    print("DEBUG: Writing PhyloWGS input files...")
    print(f"DEBUG: Output path: {output_path}")
    print(f"DEBUG: DataFrame shape: {bootstrap_df.shape}")
    print("DEBUG: DataFrame columns:")
    print(bootstrap_df.columns)
    
    try:
        # Process each bootstrap
        for i in range(1, 6):  # 5 bootstraps
            print(f"DEBUG: Processing bootstrap {i}")
            
            # Get bootstrap-specific columns
            tissue_depth_col = f"Total_Depth_st_bootstrap_{i}"
            tissue_vaf_col = f"Variant_Frequencies_st_bootstrap_{i}"
            
            if tissue_depth_col not in bootstrap_df.columns or tissue_vaf_col not in bootstrap_df.columns:
                print(f"ERROR: Missing columns for bootstrap {i}")
                print(f"Looking for: {tissue_depth_col} and {tissue_vaf_col}")
                print("Available columns:", bootstrap_df.columns)
                continue
            
            # Create PhyloWGS input
            boot_phylowgs = []
            for idx, row in bootstrap_df.iterrows():
                # Calculate variant reads from VAF and total depth
                tissue_depth = int(row[tissue_depth_col])
                tissue_vaf = float(row[tissue_vaf_col])
                var_reads = int(round(tissue_depth * tissue_vaf))
                
                # Create mutation entry in PhyloWGS format
                mutation = {
                    'id': f"s{idx}",
                    'gene': row['Hugo_Symbol'],
                    'a': str(tissue_depth - var_reads),  # reference reads
                    'd': str(tissue_depth),  # total reads
                    'mu_r': '0.999',  # probability of no error in reference observation
                    'mu_v': '0.499'   # probability of no error in variant observation
                }
                boot_phylowgs.append(mutation)
            
            print(f"DEBUG: Created {len(boot_phylowgs)} mutations for bootstrap {i}")
            
            # Create directory and save file
            boot_dir = os.path.join(output_path, f'bootstrap{i}')
            os.makedirs(boot_dir, exist_ok=True)
            
            ssm_file = os.path.join(boot_dir, f'ssm_data_bootstrap{i}.txt')
            df_boot = pd.DataFrame(boot_phylowgs)
            
            # Save with tab separator and no index
            df_boot.to_csv(ssm_file, sep='\t', index=False)
            
            print(f"DEBUG: Wrote SSM file to {ssm_file}")
            print("DEBUG: SSM file contents:")
            with open(ssm_file, 'r') as f:
                print(f.read())
            
            # Create empty CNV file
            cnv_file = os.path.join(boot_dir, f'cnv_data_bootstrap{i}.txt')
            with open(cnv_file, 'w') as f:
                pass
            
    except Exception as e:
        print(f"ERROR: Failed to write PhyloWGS input: {str(e)}")
        raise

def main():
    parser = argparse.ArgumentParser(description='Bootstrap MAF data and create phyloWGS input')
    parser.add_argument('-i', '--input', required=True,
                       help='Input MAF CSV file (output from maf_agg.py)')
    parser.add_argument('-o', '--output', required=True,
                       help='Output directory for bootstrapped files')
    parser.add_argument('-n', '--num_bootstraps', type=int, default=100,
                       help='Number of bootstrap iterations')
    parser.add_argument('-p', '--phylowgs', action='store_true',
                       help='Generate phyloWGS input files')
    args = parser.parse_args()

    try:
        # Read merged MAF data
        logging.debug(f"Reading input file: {args.input}")
        if not os.path.exists(args.input):
            logging.error(f"Input file does not exist: {args.input}")
            sys.exit(1)
            
        maf_df = pd.read_csv(args.input)
        if maf_df.empty:
            logging.error("Input file is empty - no mutations found")
            sys.exit(1)
            
        logging.debug(f"Read {len(maf_df)} mutations from input file")
        print(f"\nFirst few mutations from input file:")
        print(maf_df.head().to_string())
        
        if len(maf_df) == 0:
            print("\nERROR: No mutations found in input file")
            sys.exit(1)
            
        # Perform bootstrapping
        bootstrap_df = bootstrap_maf(maf_df, args.num_bootstraps)
        
        # Save bootstrapped data
        os.makedirs(args.output, exist_ok=True)
        bootstrap_df.to_csv(os.path.join(args.output, 'bootstrapped_maf.csv'), index=False)
        
        # Generate phyloWGS input if requested
        if args.phylowgs:
            write_phylowgs_input(bootstrap_df, args.output)

    except Exception as e:
        print(f"\nERROR: Bootstrap processing failed: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main() 