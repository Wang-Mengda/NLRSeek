#!/bin/bash

# Parse command-line arguments
while getopts ":g:n:f:" opt; do
  case $opt in
    g)
      GENOME_FA="$OPTARG"
      ;;
    n)
      THREADS="$OPTARG"
      ;;
    f)
      PREFIX="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      exit 1
      ;;
  esac
done


# Get the directory where the current script is located (i.e., the path of the Bash script)

SCRIPT_DIR=$(dirname "$0")

echo "Running NLR-Annotator..."
java -jar "$SCRIPT_DIR/NLR-Annotator/NLR-Annotator-v2.1b.jar" \
    -i "$GENOME_FA" \
    -x "$SCRIPT_DIR/NLR-Annotator/src/mot.txt" \
    -t "$THREADS" \
    -y "$SCRIPT_DIR/NLR-Annotator/src/store.txt" \
    -o "./${PREFIX}.nlr.txt" \
    -g "./${PREFIX}.nlr.gff" 

# Create output directories
mkdir -p NLR_4k_gff
mkdir -p NLR_4k_seq

# ===== Process a single GFF file =====
gff_file="./${PREFIX}.nlr.gff"

echo "Processing: $gff_file"

# Exclude comments, sort, and call Python script to extract 4k upstream and downstream regions
grep -v '^#' "$gff_file" | sort -k1,1 -k4,4n -k5,5n | \
python "$SCRIPT_DIR/remove_nested_NLR_revise_flanking.py" 4000 > "NLR_4k_gff/${PREFIX}.NLR.4k.gff3"

# Iterate through extracted regions and use samtools to extract sequences
while read n; do
    seq=$(echo "$n" | awk -F '=' '{print $2}')
    chr=$(echo "$n" | awk '{print $1}')
    start=$(echo "$n" | awk '{print $4}')
    end=$(echo "$n" | awk '{print $5}')

    samtools faidx "$GENOME_FA" "${chr}:${start}-${end}" | \
    awk -v s="$seq" '{if($1 ~ /^>/) print ">"s; else print $0}' >> "NLR_4k_seq/${PREFIX}.NLR.4k.fa"

done < "NLR_4k_gff/${PREFIX}.NLR.4k.gff3"

echo "Finished processing $gff_file"
