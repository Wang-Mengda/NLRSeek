import sys

def fix_fasta(input_file, output_file):
    # Define illegal characters
    illegal_chars = 'RYKMSWBDHV'

    # Open input and output files
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if line.startswith('>'):
                # If it is a sequence name line, write it directly
                outfile.write(line)
            else:
                # Otherwise, replace illegal characters and write them
                fixed_line = ''.join(['N' if char in illegal_chars else char for char in line.strip()])
                outfile.write(fixed_line + '\n')
# Main program, receives command line arguments
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_fasta> <output_fasta>")
        sys.exit(1)

    input_fasta = sys.argv[1]  # Get input_fasta file name from command line argument
    output_fasta = sys.argv[2]    # Get output_fasta file name from command line argument
    # Call function to modify FASTA file
    fix_fasta(input_fasta, output_fasta)
    print("FASTA file modification completed, output file is:", output_fasta)


