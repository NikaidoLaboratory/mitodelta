import os
import pandas as pd
import glob

# Output directory
output_dir = "./result"
os.makedirs(output_dir, exist_ok=True)

# Search for all eKLIPse_deletions.csv in the current directory and subdirectories
for file_path in glob.glob('*/**/eKLIPse_deletions.csv', recursive=True):
    # Read csv
    df = pd.read_csv(file_path, delimiter=';', decimal=',')
    df_sorted = df.sort_values(by=['Title','Freq'], ascending=[True,False])
    # Extract the directory structure
    top_dir = os.path.basename(os.path.dirname(os.path.dirname(file_path)))
    sub_dir = os.path.basename(os.path.dirname(file_path))
    # Construct the new filename
    output_file_name = f"{top_dir}_{sub_dir}.tsv"
    output_file_path = os.path.join(output_dir, output_file_name)
    # Save file
    df_sorted.to_csv(output_file_path, sep='\t', index=False)

print("Processing completed for all files.")
