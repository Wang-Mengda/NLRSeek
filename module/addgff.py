import csv
import sys

# Process GFF file
def process_gff(gff_file):
    gene_dict = {}
    transcript_dict = {}
    protein_dict = {}

    with open(gff_file, 'r') as gff:
        for line in gff:
            if line.startswith('#') or not line.strip():  # Skip comment lines
                continue
            fields = line.strip().split('\t')
            seqid, source, feature_type, start, end, _, strand, _, attributes = fields
            start, end = int(start), int(end)

            # Extract ID and Parent information from attributes
            attributes = attributes.split(';')
            id_attr = next((item for item in attributes if item.startswith('ID=')), None)
            parent_attr = next((item for item in attributes if item.startswith('Parent=')), None)

            if id_attr:
                id_value = id_attr.split('=')[1]
            else:
                id_value = None

            if parent_attr:
                parent_value = parent_attr.split('=')[1]
            else:
                parent_value = None

            # Process gene information
            if feature_type == 'gene' and id_value:
                gene_dict[id_value] = {'chr': seqid, 'strand': strand, 'start': start, 'end': end}

            # Process transcript information (including 'transcript' and 'mRNA')
            if feature_type == 'transcript' or feature_type == 'mRNA':
                if id_value and parent_value:
                    transcript_dict[id_value] = {'gene_id': parent_value, 'start': start, 'end': end}

            # Process CDS information
            if feature_type == 'CDS' and id_value and parent_value:
                # The ID of CDS is cds-protein_name
                protein_dict[id_value] = parent_value

    return gene_dict, transcript_dict, protein_dict

# Read TSV file and add gene information
def process_tsv(tsv_file, gene_dict, transcript_dict, protein_dict, output_file):
    with open(tsv_file, 'r') as infile:
        tsv_reader = csv.reader(infile, delimiter='\t')
        header = next(tsv_reader)  # Read header

        # New header, add columns related to gene
        new_header = header + ['chr', 'strand', 'gene', 'gene_start', 'gene_end', 'transcript', 'trans_start', 'trans_end']

        with open(output_file, 'w', newline='') as outfile:
            tsv_writer = csv.writer(outfile, delimiter='\t')
            tsv_writer.writerow(new_header)  # Write new header

            for row in tsv_reader:
                protein_name = row[0]  # Assume protein name is in the first column

                # Find corresponding transcript and gene information through protein name
                # Look for protein ID in the form 'cds-protein_name'
                transcript_id = f"{protein_name}"  # Get transcript ID
                if transcript_id:
                    gene_id = transcript_dict.get(transcript_id, {}).get('gene_id')  # Get gene ID
                    transcript_info = transcript_dict.get(transcript_id, {})
                    gene_info = gene_dict.get(gene_id, {})

                    # Extract relevant gene and transcript information
                    chr_ = gene_info.get('chr', '')
                    strand = gene_info.get('strand', '')
                    gene = gene_id if gene_id else ''
                    gene_start = gene_info.get('start', '')
                    gene_end = gene_info.get('end', '')
                    transcript = transcript_id if transcript_id else ''
                    trans_start = transcript_info.get('start', '')
                    trans_end = transcript_info.get('end', '')

                    # Add new information to the current row
                    new_row = row + [chr_, strand, gene, gene_start, gene_end, transcript, trans_start, trans_end]
                else:
                    # If related information is not found, fill with empty values
                    new_row = row + ['', '', '', '', '', '', '', '']

                tsv_writer.writerow(new_row)

# Main function
def main():
    # Get file names from command line
    if len(sys.argv) != 4:
        print("Usage: python script.py <tsv_file> <gff_file> <output_file>")
        sys.exit(1)

    tsv_file = sys.argv[1]
    gff_file = sys.argv[2]
    output_file = sys.argv[3]

    # Process GFF file
    gene_dict, transcript_dict, protein_dict = process_gff(gff_file)

    # Process TSV file and output new TSV
    process_tsv(tsv_file, gene_dict, transcript_dict, protein_dict, output_file)

# Example run: run `python script.py your_gff_file.gff your_tsv_file.tsv output_file.tsv` in the command line
if __name__ == "__main__":
    main()