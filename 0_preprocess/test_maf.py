import pandas as pd
import sys

def test_maf_file(maf_path):
    print(f"Testing MAF file: {maf_path}")
    try:
        df = pd.read_csv(maf_path, sep="\t")
        print(f"Successfully read MAF file")
        print(f"Shape: {df.shape}")
        print(f"Columns: {df.columns}")
        print("\nFirst few rows:")
        print(df.head())
        return True
    except Exception as e:
        print(f"Error reading MAF file: {str(e)}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python test_maf.py <maf_file_path>")
        sys.exit(1)
    
    success = test_maf_file(sys.argv[1])
    sys.exit(0 if success else 1) 