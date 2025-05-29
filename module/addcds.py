import csv
import sys

# Read FASTA file and store it as a dictionary,
# with protein names (without description) as keys and protein sequences as values.
def read_fasta(fasta_file):
    fasta_dict = {}
    with open(fasta_file, 'r') as f:
        protein_name = ""
        sequence = ""
        for line in f:
            line = line.strip()
            if line.startswith(">"):  # Protein name line in FASTA file
                if protein_name:  # Save the sequence of the previous protein
                    fasta_dict[protein_name] = sequence
                # Extract protein name, keeping only the part before the first space
                protein_name = line[1:].split()[0]  # Extract protein name before the first space
                sequence = ""
            else:
                sequence += line  # Concatenate protein sequence
        if protein_name:  # The sequence of the last entry needs to be saved
            fasta_dict[protein_name] = sequence
    return fasta_dict

# Read TSV file and add protein sequences
def add_protein_sequences(tsv_file, fasta_dict, output_file):
    with open(tsv_file, 'r') as infile, open(output_file, 'w', newline='') as outfile:
        reader = csv.reader(infile, delimiter='\t')
        writer = csv.writer(outfile, delimiter='\t')

        header = next(reader)  # Read header
        header.append("CDS_Sequence")  # Add a new column for protein sequence
        writer.writerow(header)  # Write updated header

        # Iterate through each row in the TSV file and add the protein sequence
        for row in reader:
            protein_name = row[0]  # Assume protein name is in the first column
            sequence = fasta_dict.get(protein_name, "Not Found")  # If sequence is not found, fill in "Not Found"
            row.append(sequence)
            writer.writerow(row)  # Write updated data row

# Main program, receives command line arguments
if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python script.py <fasta_file> <tsv_file> <output_file>")
        sys.exit(1)

    fasta_file = sys.argv[1]  # Get FASTA file name from command line argument
    tsv_file = sys.argv[2]    # Get TSV file name from command line argument
    output_file = sys.argv[3] # Get output file name from command line argument

    fasta_dict = read_fasta(fasta_file)
    add_protein_sequences(tsv_file, fasta_dict, output_file)
    print(f"CDS sequences have been added and saved to {output_file}")