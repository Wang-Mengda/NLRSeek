#!/bin/bash

# help
function usage {
  cat <<EOM
Example: ./NLRSeek.sh -g genome.fasta -a annotation.gff -o test

Usage: NLRSeek.sh [OPTION]...

  -h                               Display help
  
  (required)
  
  -g GenomeFilepath                File path to your genome file (.fasta)

  -a AnnotationFilepath            File path to annotation file (.gff)

  -o String                        Directory name to save output

  (optional)

  -n cpus                          Numbers of cpus, default: 4
  
  -c cDNAFilepath                  File path to cDNA file (.fasta) ; it can be created by gffread
  
  -p ProteinFilepath               File path to Protein file (.fasta) ; it can be created by gffread
  
  -f prefix                        The prefix of the output file, default: "Seek"
EOM
  exit 2 
}

# First, check if there is a - h option
for arg in "$@"; do
  if [ "$arg" == "-h" ] || [ "$arg" == "--help" ]; then
    usage
    exit 0
  fi
done

# If there is no - h option, continue with log creation and other operations
# log
if [ ! -d log ]; then
  mkdir log
fi
LOG_DATE=`date '+%Y-%m-%d-%H:%M:%S'`
exec 1> >(tee -a log/${LOG_DATE}_out.log)
exec 2> >(tee -a log/${LOG_DATE}_err.log)

# directory name
dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# check options
echo -e "\n---------------------- input & option -----------------------";
while getopts ":g:a:c:p:o:f:n:h" optKey; do
  case "$optKey" in
    g)
      if [ -f ${OPTARG} ]; then
        echo "Genome fasta file    = ${OPTARG}"
        wholedna=${OPTARG}
        FLG_G=1
      else
        echo "${OPTARG} does not exits."
      fi
      ;;
    a)
      if [ -f ${OPTARG} ]; then
        echo "Annotation gff file  = ${OPTARG}"
        wholegff=${OPTARG}
        FLG_A=1
      else
        echo "${OPTARG} does not exits."
      fi
      ;;
    c)
      if [ -f ${OPTARG} ]; then
        echo "cDNA fasta file      = ${OPTARG}"
        wholecdna=${OPTARG}
        FLG_C=1
      else
        echo "${OPTARG} does not exits. It will be created by gffread."
      fi
      ;;
    p)
      if [ -f ${OPTARG} ]; then
        echo "Protein fasta file   = ${OPTARG}"
        wholepep=${OPTARG}
        FLG_P=1
      else
        echo "${OPTARG} does not exits. It will be created by gffread."
      fi
      ;;
    f)
      echo "Prefix       = ${OPTARG}"
      prefix=${OPTARG}
      ;;
    n)
      echo "cpus       = ${OPTARG}"
      cpus=${OPTARG}
      ;;
    o)
      FLG_O=1
      echo "output directory     = ${OPTARG}"
      outdir=${OPTARG}
      ;;
    '-h'|'--help' )
        usage
      ;;
    *)
      echo "Unknown option: -$OPTARG"
      usage
      ;;

  esac
done
echo -e "\n---------------------- input & option -----------------------";

# Set prefix default values
if [ -z "${prefix}" ]; then
  prefix="Seek"
  echo "Prefix not provided. Using default prefix = ${prefix}"
fi

# Set cpus default values
if [ -z "${cpus}" ]; then
  cpus="4"
  echo "Cpus not provided. Using default cpus = ${cpus}"
fi

# check genome fasta file
if [ -z $FLG_G ]; then
  echo -e "$(basename $0) : -g option is required\n"
  usage
  exit 1
fi

# check gff file
if [ -z $FLG_A ]; then
  echo -e "$(basename $0) : -a option is required\n"
  usage
  exit 1
fi

# check output dir
if [ -z $FLG_O ]; then
  echo -e "$(basename $0) : -o option is required\n"
  usage
  exit 1
fi

if [[ "$outdir" != /* ]]; then
  # If it is not an absolute path, build an absolute path based on the current working directory
  outdir="$(pwd)/$outdir"
fi
outdir="$(realpath -m "$outdir")"
echo "Normalized output directory will be: $outdir"

# Main pipeline

# Create directory

mkdir -p "$outdir"
mkdir -p "$outdir/data" "$outdir/annotator" "$outdir/reannotation" "$outdir/tracker" "$outdir/summary"

#  0.Prepare data

python ${dir_name}/module/Modifynucleotides.py "$wholedna" "$outdir/data/whole.dna.fasta"
wholedna="$(realpath "$outdir/data/whole.dna.fasta")"

cp "$wholegff" "$outdir/data/whole.gff"
wholegff="$(realpath "$outdir/data/whole.gff")"

if [ -z "$FLG_P" ]; then
    gffread "$wholegff" -g "$wholedna" -y "$outdir/data/tmp.whole.pep.fasta" || { echo "gffread failed"; exit 1; }
    sed '/^>/! s/[*.]//g' "$outdir/data/tmp.whole.pep.fasta" > "$outdir/data/whole.pep.fasta"
    rm -rf "$outdir/data/tmp.whole.pep.fasta"
    wholepep="$(realpath "$outdir/data/whole.pep.fasta")"
else
    sed '/^>/! s/[*.]//g' "$wholepep" "$outdir/data/whole.pep.fasta"
    wholepep="$(realpath "$outdir/data/whole.pep.fasta")"
fi

#gffread "$wholegff" -g "$wholedna" -y "$outdir/data/whole.pep.fasta"
#wholepep="$(realpath "$outdir/data/whole.pep.fasta")"

#seqkit seq -t protein -i -g "$wholepep" | sed 's/\*$//g' > "$outdir/data/whole.pep.fasta"
#wholepep="$(realpath "$outdir/data/whole.pep.fasta")"

if [ -z "$FLG_C" ]; then
    gffread "$wholegff" -g "$wholedna" -w "$outdir/data/tmp.whole.cdna.fasta" || { echo "gffread failed"; exit 1; }
    python ${dir_name}/module/Modifynucleotides.py "$outdir/data/tmp.whole.cdna.fasta" "$outdir/data/whole.cdna.fasta"
    rm -rf "$outdir/data/tmp.whole.cdna.fasta"
    wholecdna="$(realpath "$outdir/data/whole.cdna.fasta")"
else
    python ${dir_name}/module/Modifynucleotides.py "$wholecdna" "$outdir/data/whole.cdna.fasta"
    wholecdna="$(realpath "$outdir/data/whole.cdna.fasta")"
fi

gffread  "$wholegff"  -g  "$wholedna"  -x  "$outdir/data/whole.cds.fasta"  
wholecds="$(realpath "$outdir/data/whole.cds.fasta")"

#  1.Search NLR loc

echo -e "\nRunning NLR-Annotator to search NLR loc......"

cd "$outdir/annotator"
bash ${dir_name}/module/annotator.sh -g $wholedna -n $cpus -f $prefix 
cd $outdir

echo -e "\nFinish NLR-Annotator!"

#  2.Training model and reannotation

echo -e "\nTraining models......"

cd "$outdir/reannotation"
mkdir -p snap augustus makernlr
cd snap
bash ${dir_name}/module/train_snap.sh -g $wholedna -a $wholegff -f $prefix
cd "$outdir/reannotation/augustus"
bash ${dir_name}/module/train_augustus.sh -g $wholedna -a $wholegff -f $prefix
cd "$outdir/reannotation/makernlr"

echo -e "\nReannotating NLRs......"

bash ${dir_name}/module/reannotation.sh -c $wholecdna -n $cpus -f $prefix
cp "$outdir/reannotation/makernlr/gff2ann/${prefix}.NLR.gff" "$outdir/reannotation/makernlr/gff2ann/${prefix}.NLR.pep.fa" "$outdir/reannotation/makernlr/gff2ann/${prefix}.NLR.cds.fa" $outdir/data
cd $outdir

echo -e "\nFinish reannotation!"

#  3.NLRtracker identify NLR

echo -e "\nIdentifing NLR......"

cd "$outdir/tracker"
mkdir -p whole reann
cd "$outdir/tracker/reann"
bash ${dir_name}/NLRtracker/NLRtracker.sh -s $outdir/data/${prefix}.NLR.pep.fa -c $cpus -o $outdir/tracker/reann/${prefix}_reann

cd "$outdir/tracker/whole"
bash ${dir_name}/NLRtracker/NLRtracker.sh -s $wholepep -c $cpus -o $outdir/tracker/whole/${prefix}_whole


echo -e "\nFinish Identifing NLR!"

#  4.summary

echo -e "\nDoing Summary......"

cd "$outdir/summary" 
cp $outdir/tracker/reann/${prefix}_reann/NLRtracker.tsv $outdir/summary/ann_NLRtracker.tsv
cp $outdir/tracker/whole/${prefix}_whole/NLRtracker.tsv $outdir/summary/whole_NLRtracker.tsv

#extract the pep's name from tsv file
python ${dir_name}/module/sum.py
#add information
python ${dir_name}/module/addgff.py whole.tsv $wholegff whole_addgff.tsv
python ${dir_name}/module/addgff.py ann_choose.tsv $outdir/data/${prefix}.NLR.gff ann_addgff.tsv

python ${dir_name}/module/addpep.py $wholepep whole_addgff.tsv whole_addgffpep.tsv
python ${dir_name}/module/addpep.py $outdir/data/${prefix}.NLR.pep.fa ann_addgff.tsv ann_addgffpep.tsv

python ${dir_name}/module/addcds.py $wholecds whole_addgffpep.tsv whole_addgffpepcds.tsv
python ${dir_name}/module/addcds.py $outdir/data/${prefix}.NLR.cds.fa  ann_addgffpep.tsv ann_addgffpepcds.tsv

python ${dir_name}/module/checkATG.py ann_addgffpepcds.tsv ann_addgffpepcds_check.tsv

awk 'NR==1 || FNR>1' ann_addgffpepcds_check.tsv whole_addgffpepcds.tsv > merge.tsv

python ${dir_name}/module/type_simple.py merge.tsv merge_simple.tsv

python ${dir_name}/module/filter.py merge_simple.tsv ${prefix}.tsv

mkdir -p processfile
mv ./*.tsv processfile
mv processfile/${prefix}.tsv .

echo -e "All completed! "




