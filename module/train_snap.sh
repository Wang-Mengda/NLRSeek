#!/bin/bash

# Parse command-line arguments
while getopts ":g:a:f:" opt; do
  case $opt in
    g)
      GENOME_FA="$OPTARG"
      ;;
    a)
      wholegff="$OPTARG"
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

# Generate snap-specific zff file
chmod +x $SCRIPT_DIR/gff3_to_zff.pl
$SCRIPT_DIR/gff3_to_zff.pl $GENOME_FA $wholegff > at.zff

# Select only correct corresponding gene files and generate hmm file
fathom -validate at.zff $GENOME_FA > at.validate

fathom -categorize 100 at.zff $GENOME_FA

fathom -export 100 -plus uni.*

fathom -validate export.ann export.dna

forge export.ann export.dna

hmm-assembler.pl ${PREFIX} . > ${PREFIX}.hmm