import pandas as pd
import numpy as np

# File paths
metadata_file = "../Data/human_extended_wide_2025-12-14.tsv"
taxonomy_file = "../Data/human_metaphlan4_species_2025-12-14.tsv"
output_file = "../Data/metalog_subset.csv"

def read_tsv_robust(filepath):
    """
    Reads a TSV file that might be GZIP compressed despite having a .tsv extension.
    """
    print(f"Loading {filepath}...")
    try:
        # Attempt 1: Read as plain text (standard TSV)
        # We use iterator=True to read just a chunk first to fail fast on encoding? 
        # No, let's just try reading.
        return pd.read_csv(filepath, sep='\t', low_memory=False)
    except UnicodeDecodeError:
        print("  -> UnicodeDecodeError encountered. The file is likely compressed (GZIP).")
        print("  -> Retrying with compression='gzip'...")
        try:
            return pd.read_csv(filepath, sep='\t', compression='gzip', low_memory=False)
        except Exception as e:
            print(f"  -> Failed with GZIP compression too: {e}")
            raise ValueError(f"CRITICAL: Could not read {filepath}. Please check if the file is corrupted or in a different format (e.g., zip instead of gzip).")
    except Exception as e:
        # Check if it's a parser error that might indicate compression
        print(f"  -> Unknown error: {e}")
        print("  -> Retrying with compression='gzip' just in case...")
        try:
            return pd.read_csv(filepath, sep='\t', compression='gzip', low_memory=False)
        except:
             raise e

# --- Main Logic ---

# 1. Load Metadata
meta = read_tsv_robust(metadata_file)
print(f"Metadata Columns: {meta.columns.tolist()}")

# Identify the correct ID column in metadata
# We prefer 'sample_alias' if available to match taxonomy, otherwise 'sample_id'
id_col = None
for col in ['sample_alias', 'sample_id', 'run_accession']:
    if col in meta.columns:
        id_col = col
        break

if not id_col:
    # Fallback: assume the first column unique enough? No, we saw that failed.
    print("CRITICAL WARNING: Could not find 'sample_alias', 'sample_id', or 'run_accession' in metadata.")
    print("Using first column as fallback, but this likely failed before:", meta.columns[0])
    id_col = meta.columns[0]

print(f"Using Metadata ID column: {id_col}")

# 2. Filter for BMI
bmi_cols = [col for col in meta.columns if 'bmi' in col.lower() or 'body_mass' in col.lower()]
if not bmi_cols:
    raise ValueError(f"No BMI column found in {metadata_file}!")
best_bmi_col = bmi_cols[0]
print(f"Selected BMI column: {best_bmi_col}")

# 3. Clean Metadata
meta = meta[[id_col, best_bmi_col]].dropna()
# Normalize ID column to 'sample_id' for merging
meta.rename(columns={id_col: 'sample_id', best_bmi_col: 'bmi'}, inplace=True)
# Ensure IDs are strings
meta['sample_id'] = meta['sample_id'].astype(str)
print(f"Samples with valid BMI: {len(meta)}")
print(f"Example Metrics IDs: {meta['sample_id'].head().tolist()}")


# 4. Load Taxonomy
tax = read_tsv_robust(taxonomy_file)
print(f"Taxonomy Columns: {tax.columns.tolist()}")

# Check for expected columns for pivoting
if 'species' in tax.columns and 'rel_abund' in tax.columns:
    print("Detected LONG format taxonomy. Pivoting to WIDE format...")
    # Identify the sample column in taxonomy
    tax_id_col = None
    for col in ['sample_alias', 'sample_id', 'sample']:
        if col in tax.columns:
            tax_id_col = col
            break
    if not tax_id_col:
        tax_id_col = tax.columns[0] # Fallback
    
    print(f"Using Taxonomy ID column: {tax_id_col}")
    
    # Pivot: Index=Sample, Columns=Species, Values=Abundance
    # This might take memory, so we be careful.
    tax_wide = tax.pivot(index=tax_id_col, columns='species', values='rel_abund')
    # Fill NAs with 0 (missing species means 0 abundance)
    tax_wide = tax_wide.fillna(0)
    
    # Reset index to make sample_id a column again
    tax_wide.reset_index(inplace=True)
    tax_wide.rename(columns={tax_id_col: 'sample_id'}, inplace=True)
    tax_wide['sample_id'] = tax_wide['sample_id'].astype(str)
    
    print(f"Pivoted Taxonomy shape: {tax_wide.shape}")
    tax = tax_wide # Replace header for merging step

else:
    print("Taxonomy seems to be already WIDE (or unknown format).")
    # Just rename first column
    tax.rename(columns={tax.columns[0]: 'sample_id'}, inplace=True)
    tax['sample_id'] = tax['sample_id'].astype(str)


# 5. Merge
print("Merging metadata and taxonomy...")
merged = pd.merge(meta, tax, on='sample_id', how='inner')
print(f"Final merged dataset size: {len(merged)} samples")

if len(merged) == 0:
    print("WARNING: The merged dataset is empty!") 
    print("DEBUG: Checking for ID overlap...")
    meta_ids = set(meta['sample_id'])
    tax_ids = set(tax['sample_id'].head(1000)) # Check first 1000
    overlap = meta_ids.intersection(tax_ids)
    print(f"Example Meta IDs: {list(meta_ids)[:3]}")
    print(f"Example Tax IDs: {list(tax_ids)[:3]}")
else:
    print(f"Saving to {output_file}...")
    merged.to_csv(output_file, index=False)
    print("Done!")
