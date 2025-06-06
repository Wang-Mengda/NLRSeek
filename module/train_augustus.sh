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


# Generate gb file, keeping 2000bp upstream and downstream of each gene for model training
gff2gbSmallDNA.pl ${wholegff} ${GENOME_FA} 2000 ${PREFIX}.gb

# Check if the corresponding species already exists in the Augustus model library
# ls -ort $AUGUSTUS_CONFIG_PATH/species

# Delete old default model
if [ -d "$AUGUSTUS_CONFIG_PATH/species/${PREFIX}_Seeker" ]; then
    echo "Species already exists. Delete."
    rm -r $AUGUSTUS_CONFIG_PATH/species/${PREFIX}_Seeker
fi
# Create a new Augustus species
new_species.pl --species=${PREFIX}_Seeker

# Initial training
etraining --species=${PREFIX}_Seeker ${PREFIX}.gb 2> train.err

# Extract error genes
awk '{print $7}' train.err | sed 's/://' > cleaned_badgenes_list.txt

# Filter out genes that caused errors
filterGenes.pl cleaned_badgenes_list.txt ${PREFIX}.gb > fixed_${PREFIX}.gb

# Randomly split out 200 genes for the test set
randomSplit.pl fixed_${PREFIX}.gb 200

# Rename the training set
mv fixed_${PREFIX}.gb.train fixed_${PREFIX}.gb.retrain

# Train again
etraining --species=${PREFIX}_Seeker fixed_${PREFIX}.gb.retrain

# Rename the test set to validation set
mv fixed_${PREFIX}.gb.test fixed_${PREFIX}.gb.evaluation

# Test genes in the validation set to evaluate the model
augustus --species=${PREFIX}_Seeker fixed_${PREFIX}.gb.evaluation >& first_evaluate.out

# Move previous validation files aside to avoid affecting results
mkdir evaluation && mv fixed_${PREFIX}.gb.evaluation fixed_${PREFIX}.gb.retrain evaluation

### ---------------------------------------------------------------------------------------------------------- ###
### Optimization model steps, extremely time-consuming but can improve model performance, please use as needed ###
### ---------------------------------------------------------------------------------------------------------- ###

# Randomly split out 1000 genes for the test set
#randomSplit.pl fixed_${PREFIX}.gb 1000

# Optimize the model, this step is extremely time-consuming
#optimize_augustus.pl --species=${PREFIX}_Seeker --kfold=24 --cpus=4 --rounds=5 --onlytrain=fixed_${PREFIX}.gb.train fixed_${PREFIX}.gb.test

# Retrain the optimized model and test again
#etraining --species=${PREFIX}_Seeker fixed_${PREFIX}.gb
#augustus --species=${PREFIX}_Seeker fixed_${PREFIX}.gb.test >& second_evaluate.out
