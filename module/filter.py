import sys
import csv

def filter_tsv(input_filename, output_filename):
    try:
        with open(input_filename, 'r', encoding='utf-8') as infile:
            reader = csv.DictReader(infile, delimiter='\t')
            # Read all rows and sort by chromosome and start position
            data = sorted(list(reader), key=lambda row: (row['chr'], int(row['gene_start'])))

        filtered_rows = []
        for i, row in enumerate(data):
            if row['software'] == 'a':
                chromosome = row['chr']
                start = int(row['gene_start'])
                end = int(row['gene_end'])

                prev_non_a = None
                next_non_a = None

                # Find the previous non-'a' row
                for j in range(i - 1, -1, -1):
                    if data[j]['chr'] == chromosome and data[j]['software'] != 'a':
                        prev_non_a = data[j]
                        break

                # Find the next non-'a' row
                for j in range(i + 1, len(data)):
                    if data[j]['chr'] == chromosome and data[j]['software'] != 'a':
                        next_non_a = data[j]
                        break

                if (prev_non_a is None or start > int(prev_non_a['gene_end'])) and \
                   (next_non_a is None or end < int(next_non_a['gene_start'])):
                    filtered_rows.append(row)
            else:
                filtered_rows.append(row)

        with open(output_filename, 'w', encoding='utf-8', newline='') as outfile:
            fieldnames = data[0].keys() if data else [] # Get header
            writer = csv.DictWriter(outfile, delimiter='\t', fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(filtered_rows)

        print(f"Filtering complete. Results saved to {output_filename}")

    except FileNotFoundError:
        print(f"Error: Input file '{input_filename}' not found")
        sys.exit(1)
    except (ValueError, KeyError) as e: # Added capture for value conversion and key errors
        print(f"File format error or column name error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)


if len(sys.argv) != 3:
    print("Usage: python script.py <input_filename> <output_filename>")
    sys.exit(1)

input_filename = sys.argv[1]
output_filename = sys.argv[2]

filter_tsv(input_filename, output_filename)
