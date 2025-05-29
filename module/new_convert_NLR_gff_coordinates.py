#!/usr/bin/env python3

import sys

# Open the two input files passed from the command line.
i1 = open(sys.argv[1])  # Input file 1:  contains basic position information.
i2 = open(sys.argv[2])  # Input file 2:  contains additional annotation information.

# Initialize an empty dictionary to store data from the first file (i1).
d = {}

# Read and process the first file (i1) line by line.
for line in i1:
    if '#' not in line:  # Skip comment lines starting with '#'.
        line = line.strip().split()  # Split the line into a list of fields by whitespace.
        name = line[-1].split('=')[1]  # Extract the gene name from the last field (take the part after '=').
        d[name] = [line[0], line[3], line[4]]  # Store chromosome number, start position, and end position as a list.

# Read and process the second file (i2) line by line.
for line in i2:
    line = line.strip().split()  # Split the line into a list of fields by whitespace.
    if line[0] in d:  # Check if the first column of the current line is in the dictionary keys extracted from i1.
        # Extract corresponding data from the dictionary.
        chrom = d[line[0]][0]  # Get the chromosome identifier from the dictionary.
        start_offset = int(d[line[0]][1])  # Get the start position from the dictionary and convert to integer.

        # Calculate new start and end positions using the offset from the dictionary.
        new_start = int(line[3]) + start_offset - 1  # Adjusted start position.
        new_end = int(line[4]) + start_offset - 1  # Adjusted end position.

        # Extract other fields needed for output from the current line (i2).
        rest = '\t'.join(line[5:8])  # Join fields 5, 6, and 7 with tabs into a string.
        gene_name = line[8]  # Keep the original form of the gene name.

        # Output in tab-separated format, combining data from both files.
        print(chrom, '\t'.join(line[1:3]), new_start, new_end, rest, gene_name, sep='\t')