import csv
import os

# Define the NP character set
NP_SET = set("NP")

def process_file(file_path, is_ann_group):
    """
    Processes a single file, classifying rows based on whether the last column
    contains characters from the NP set.

    Args:
        file_path (str): The path to the file.
        is_ann_group (bool): Whether the file belongs to the 'ann' group (starts with 'ann').

    Returns:
        tuple: Contains two dictionaries, storing rows that contain NP characters
               and rows that do not, respectively.
    """
    data_dict_contains = {}  # Stores rows containing NP characters
    data_dict_not_contains = {}  # Stores rows not containing NP characters
    letter = "a" if is_ann_group else "t"  # Determine if the letter is 'a' or 't' based on the file group

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    with open(file_path, 'r') as f:
        reader = csv.reader(f, delimiter='\t')
        headers = next(reader, None)  # Skip header row
        for row in reader:
            if row:  # Ensure the row is not empty
                key = row[0]  # First column as key
                last_column = row[-1]

                # Check if the last column contains NP characters
                if any(char in NP_SET for char in last_column):
                    data_dict_contains[key] = [last_column, letter]
                else:
                    data_dict_not_contains[key] = [last_column, letter]

    return data_dict_contains, data_dict_not_contains

def output_to_file(data_dict, output_filename):
    """
    Writes dictionary data to a file.

    Args:
        data_dict (dict): Dictionary storing row data.
        output_filename (str): Output file name.
    """
    with open(output_filename, 'w', newline='') as f:
        writer = csv.writer(f, delimiter='\t')
        writer.writerow(['pep', 'type', 'software'])  # Write header row
        for key, value in data_dict.items():
            writer.writerow([key] + value)

def main():
    """
    Main function: processes files and outputs results.
    """
    # Define file paths for files starting with 'ann' and those not
    ann_group_files = {
        'NLRtracker': 'ann_NLRtracker.tsv',
    }

    non_ann_group_files = {
        'NLRtracker': 'whole_NLRtracker.tsv',
    }

    # Process the 'ann' group files (pass is_ann_group=True)
    ann_data_dict_contains, ann_data_dict_not_contains = process_file(ann_group_files['NLRtracker'], is_ann_group=True)

    # Process the non-'ann' group files (pass is_ann_group=False)
    non_ann_data_dict_contains, non_ann_data_dict_not_contains = process_file(non_ann_group_files['NLRtracker'], is_ann_group=False)

    # Output to different files
    output_to_file(ann_data_dict_contains, 'ann.tsv')  # Part classified as 'a'
    output_to_file(non_ann_data_dict_contains, 'whole.tsv')  # Part classified as 't'

if __name__ == '__main__':
    main()