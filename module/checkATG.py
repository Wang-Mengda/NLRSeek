import pandas as pd
import sys

def filter_cds_sequences(input_file, output_file):
    # Read TSV file
    df = pd.read_csv(input_file, sep='\t')

    # Check if 'CDS_Sequence' column exists
    if 'CDS_Sequence' not in df.columns:
        raise ValueError("Column 'CDS_Sequence' not found in the input file!")

    # Define the set of stop codons
    stop_codons = {'TAA', 'TAG', 'TGA'}

    # Filter rows that meet the criteria
    def is_valid_sequence(sequence):
        return sequence.startswith('ATG') and sequence[-3:] in stop_codons

    filtered_df = df[df['CDS_Sequence'].apply(is_valid_sequence)]

    # Write the filtered data to a new TSV file
    filtered_df.to_csv(output_file, sep='\t', index=False)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    try:
        filter_cds_sequences(input_file, output_file)
        print(f"Filtering complete! Results saved to {output_file}")
    except Exception as e:
        print(f"An error occurred: {e}")

