import pandas as pd
import numpy as np
import argparse
import logging
import sys

"""
The purpose of this script is to aggregate meaningful mutation data from multiple MAF files. 

This is the first step in the Mase-phi pipeline, as we are proecessing raw Illumina sequencing data to 
be used in the next file (bootstrap.py). 

This file takes in 3 different MAF files: 
The files are titled `MAFconversion_<sample type>....txt`
1) Blood maf (MAFconversion_CF....txt)
2) Tissue maf (MAFconversion_ST....txt)
3) Germline maf (MAFconversion_BC....txt)

The script will perform an inner join (common) or outer join (union) on the blood and tissue mafs, 
and then perform a set difference between the joined blood and tissue mafs and the germline maf. 

Results will be saved as a .csv file to an inputted directory. 

You can run this script with the following command: 

python maf_agg.py -c <blood(cf) maf> -s <tissue(st) maf> -b <germline(bc) maf> -o <output directory> -m <method>
"""

# Set up logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def merge_mafs(cf, st, bc, method="inner"):
    """
    Merge MAF files following biological rules:
    1. Find common mutations between blood (CF) and tissue (ST)
    2. Remove germline (BC) mutations
    """
    # columns to identify a mutation 
    mut_cols = ['Hugo_Symbol', "Entrez_Gene_Id", "NCBI_Build", "Chromosome", 
                "Start_Position", "End_Position", "Reference_Allele", "Allele"]
    
    # Step 1: Find common mutations between blood and tissue
    common = cf.merge(st, on=mut_cols, how="inner", suffixes=("_cf", "_st"))
    
    # Step 2: Remove germline mutations
    outer = common.merge(bc, on=mut_cols, indicator=True, how="outer")
    anti_join = outer[outer._merge == "left_only"].drop("_merge", axis=1)
    
    # Reset index and return relevant columns
    anti_join = anti_join.reset_index(drop=True)
    result = anti_join[['Hugo_Symbol', "Entrez_Gene_Id", "NCBI_Build", "Chromosome",
                       "Start_Position", "End_Position", "Reference_Allele", "Allele",
                       "Variant_Frequencies_st", "Variant_Frequencies_cf",
                       "Total_Depth_st", "Total_Depth_cf"]]
    
    return result

def validate_result(result_df):
    """Validate the merged result"""
    if result_df.empty:
        raise ValueError("No mutations found after merging and filtering. Check input MAF files.")
    
    if result_df['Variant_Frequencies_st'].max() == 0 and result_df['Variant_Frequencies_cf'].max() == 0:
        raise ValueError("No variants found with non-zero frequency.")
    
    logging.debug(f"Found {len(result_df)} mutations")
    logging.debug(f"ST VAF range: {result_df['Variant_Frequencies_st'].min():.3f} - {result_df['Variant_Frequencies_st'].max():.3f}")
    logging.debug(f"CF VAF range: {result_df['Variant_Frequencies_cf'].min():.3f} - {result_df['Variant_Frequencies_cf'].max():.3f}")

def main():
    parser = argparse.ArgumentParser(description='Merge MAF files following biological rules')
    parser.add_argument("-c", "--cf_maf", type=str, required=True,
                       help='Blood (CF) MAF file')
    parser.add_argument("-s", "--st_maf", type=str, required=True,
                       help='Tissue (ST) MAF file')
    parser.add_argument("-b", "--bc_maf", type=str, required=True,
                       help='Germline (BC) MAF file')
    parser.add_argument("-o", "--output_dir", type=str, required=True,
                       help='Output directory for merged MAF')
    parser.add_argument("-m", "--method", type=str, default="inner",
                       choices=["inner", "outer"],
                       help='Method for merging MAFs (default: inner)')
    args = parser.parse_args()

    try:
        print("\nReading MAF files...")
        cf = pd.read_csv(args.cf_maf, sep="\t")
        st = pd.read_csv(args.st_maf, sep="\t")
        bc = pd.read_csv(args.bc_maf, sep="\t")
        
        # Merge MAFs following biological rules
        maf_agg = merge_mafs(cf, st, bc)
        
        if maf_agg is None or maf_agg.empty:
            print("\nERROR: No valid mutations found after merging")
            sys.exit(1)
            
        validate_result(maf_agg)
        
        print(f"\nWriting {maf_agg.shape[0]} mutations to {args.output_dir}")
        maf_agg.to_csv(args.output_dir, index=False)
        print("\nMAF aggregation completed successfully")
        
    except Exception as e:
        print(f"\nERROR: MAF aggregation failed: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()