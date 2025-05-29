import pandas as pd
import sys

def classify_type(value):
    # Replace P with N
    value = value.replace('P', 'N')
    value = value.replace('B', 'C') # Replace B with C (based on the pattern of the comment above)

    # Classification rules
    if 'CNL' in value:
        return 'CNL'
    elif 'TNL' in value:
        return 'TNL'
    elif 'RNL' in value:
        return 'RNL'
    elif 'NL' in value and not any(x in value for x in ['CNL', 'TNL', 'RNL']):
        return 'NL'
    elif 'CN' in value and 'CNL' not in value:
        return 'CN'
    elif 'TN' in value and 'TNL' not in value:
        return 'TN'
    elif 'RN' in value and 'RNL' not in value:
        return 'RN'
    elif 'N' in value and not any(x in value for x in ['CNL', 'TNL', 'RNL', 'NL']):
        return 'N'
    else:
        return 'without_N'  # Unmatched case, keep as is

def process_tsv(input_file, output_file):
    # Read TSV file
    df = pd.read_csv(input_file, sep='\t')

    # Create a new column 'type_simple', apply the classification function
    df['type_simple'] = df['type'].apply(classify_type)

    # Insert the 'type_simple' column after the 'type' column
    cols = df.columns.tolist()
    cols.insert(cols.index('type') + 1, cols.pop(cols.index('type_simple')))
    df = df[cols]

    # Write the results to a new TSV file
    df.to_csv(output_file, sep='\t', index=False)

if __name__ == "__main__":
    # Check if command-line arguments are sufficient
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_file> <output_file>")
        sys.exit(1)

    # Get input and output file names
    input_file = sys.argv[1]
    output_file = sys.argv[2]

    # Process the TSV file
    process_tsv(input_file, output_file)