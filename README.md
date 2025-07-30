# NLRSeek

We provide a plant NLR gene identification tool optimized for non-model plant species. The pipeline can be executed via a one-step Linux shell script or as a series of modular scripts for more flexible usage.

## Requirements & Installation
It's a pipeline to be run on unix based machines. The following software must be available.
NLRtracker and NLR-Annotator should be placed in specific locations.
```
git clone https://github.com/learning666666/NLRSeek.git
cd NLRSeek
git clone https://github.com/slt666666/NLRtracker.git
cd module
git clone https://github.com/steuernb/NLR-Annotator.git
```
-   [NLRtracker](https://github.com/slt666666/NLRtracker)
    -   Requires Java 11
    -   [InterProScan](https://www.ebi.ac.uk/interpro/download/)
	-   [HMMER](https://github.com/EddyRivasLab/hmmer) 
	-   [R](https://www.r-project.org/) version >= 4.1.0
	-   R package ( with packages: [tidyverse](https://www.tidyverse.org/), [Bioconductor](https://bioconductor.org/), [Biostrings](https://bioconductor.org/packages/release/bioc/html/Biostrings.html) )
	-   [FIMO](https://meme-suite.org/meme/)  (MEME Suite version 5.2.0)
-	[NLR-Annotator](https://github.com/steuernb/NLR-Annotator)
-	[Samtools](https://www.htslib.org/)
-	[gffread](https://github.com/gpertea/gffread)
-	[MAKER](https://www.yandell-lab.org/software/maker.html) (version 2.31.11)
	-	[Augustus](https://github.com/Gaius-Augustus/Augustus)
	-	[SNAP](https://github.com/KorfLab/SNAP)
-	[Python](https://www.python.org/downloads/) ( with package: `pandas` )
## Using one-step script
`-h` can see the usage. 
```
./NLRSeek.sh -h
```
```
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
```

## Example of directory

###	An example of the script directory is shown below
```
.
├── NLRSeek
│   ├── NLRSeek.sh
│   ├── NLRtracker
│   │   └── ... ( NLRtracker's files )
│   └── module
│       ├── NLR-Annotator
│       │   └── ... ( NLR-Annotator's files )
│       └── ... ( NLRSeek's modular scripts )

```
###	An example of the complete project directory is shown below
Show directories only.
```
.
├── output-dir
│   ├── Annotator
│   │   ├── NLR_4k_gff
│   │   └── NLR_4k_seq
│   ├── data
│   ├── reannotation
│   │   ├── augustus
│   │   ├── makernlr
│   │   └── snap
│   ├── summary
│   │   └── processfile
│   ├── tracker
│   │   ├── whole
│   │   │   ├── log
│   │   │   ├── Seek_reann
│   │   │   └── temp
│   │   └── reann
│   │   │   ├── log
│   │   │   ├── Seek_whole
│   │   │   └── temp
```
## Using modular scripts

All the modular scripts are in the module directory.

###	Step 0:  Create directory
```
outdir=/path/to/output/directory

mkdir -p "$outdir"
mkdir -p "$outdir/data" "$outdir/annotator" "$outdir/reannotation"  "$outdir/tracker"  "$outdir/summary"
```
###	Step 1:  Prepare data 
```
# Copy files to the data directory
wholedna=/path/to/GenomeFile
wholegff=/path/to/AnnotationFile

# Copy files to the data directory
cp "$wholedna" "$outdir/data/whole.dna.fasta"
wholedna="$(realpath "$outdir/data/whole.dna.fasta")"

cp  "$wholegff"  "$outdir/data/whole.gff"
wholegff="$(realpath "$outdir/data/whole.gff")"

#  GFF files with trans-spliced genes, when containing '?' characters, can cause gffread to generate erroneous output. The provided code can resolve this.
#cp "$wholegff" "$outdir/data/tmp.whole.gff"
#sed 's/\t?\t/\t.\t/' "$outdir/data/tmp.whole.gff" > "$outdir/data/whole.gff"
#rm -rf "$outdir/data/tmp.whole.gff"
#wholegff="$(realpath "$outdir/data/whole.gff")"

# Generate files
gffread  "$wholegff"  -g  "$wholedna"  -y  "$outdir/data/whole.pep.fasta"
wholepep="$(realpath "$outdir/data/whole.pep.fasta")"

gffread  "$wholegff"  -g  "$wholedna"  -w  "$outdir/data/whole.cdna.fasta"  
wholecdna="$(realpath "$outdir/data/whole.cdna.fasta")"

gffread  "$wholegff"  -g  "$wholedna"  -x  "$outdir/data/whole.cds.fasta"  
wholecds="$(realpath "$outdir/data/whole.cds.fasta")"
```
###	Step 2:  Search NLR loc
```
dir_name=/path/to/NLRSeek
cpus=n ( n= Number of CPUs )
prefix=Seek  ( The prefix of the output file, default: "Seek" )

cd  "$outdir/annotator"
bash ${dir_name}/module/annotator.sh -g $wholedna -n $cpus -f $prefix
```
###	Step 3:  Training model and reannotation
If you wish to enhance the performance of the AUGUSTUS training model, you may uncomment the lines following line 68 in the `train_augustus.sh` script. These additional steps can lead to better model accuracy in some cases. To further improve annotation quality, consider tuning parameters — such as model_org and the amount of intergenic sequence included on each side of a gene — in `reannotation.sh` and `train_snap.sh`, based on your species or the characteristics of your dataset.
```
cd "$outdir/reannotation"
mkdir -p snap augustus makernlr

#  Train SNAP
cd snap
bash ${dir_name}/module/train_snap.sh -g $wholedna -a $wholegff -f $prefix

#  Train Augustus
cd "$outdir/augustus"
bash ${dir_name}/module/train_augustus.sh -g $wholedna -a $wholegff -f $prefix

#  Reannotation
cd "$outdir/makernlr"
bash ${dir_name}/module/reannotation.sh -c $wholecdna -n $cpus -f $prefix

# Copy files to the data directory
cp gff2ann/${prefix}.NLR.gff gff2ann/${prefix}.NLR.pep.fa gff2ann/${prefix}.NLR.cds.fa $outdir/data
```
###	Step 4:  Identification of NLR genes
```
cd "$outdir/tracker"
mkdir -p whole reann

#  Identification of reannotated NLRs
cd "$outdir/tracker/reann"
bash ${dir_name}/NLRtracker/NLRtracker.sh -s $outdir/data/${prefix}.NLR.pep.fa -c $cpus -o $outdir/tracker/reann/${prefix}_reann

#  Identification of initial NLRs
cd "$outdir/tracker/whole"
bash ${dir_name}/NLRtracker/NLRtracker.sh -s $wholepep -c $cpus -o $outdir/tracker/whole/${prefix}_whole

#  Copy files to the summary directory
cp $outdir/tracker/reann/${prefix}_reann/NLRtracker.tsv $outdir/summary/ann_NLRtracker.tsv
cp $outdir/tracker/whole/${prefix}_whole/NLRtracker.tsv $outdir/summary/whole_NLRtracker.tsv
```
###	Step 5:  Merge and remove duplicates
Default to the initial NLR, remove overlapping reannotated NLR. 
This step is designed to accommodate protein sequence files generated from GFF files using `gffread`, as well as some user-provided GFF and protein sequence files. However, it may not be compatible with all GFF formats, so adjustments might be needed based on the input data.
```
cd "$outdir/summary" 

#  Extract proteins that have NBARC domain
python ${dir_name}/module/sum.py

#  Add gff information
python ${dir_name}/module/addgff.py whole.tsv $wholegff whole_addgff.tsv
python ${dir_name}/module/addgff.py ann.tsv $outdir/data/${prefix}.NLR.gff ann_addgff.tsv

#  Add protein suquences
python ${dir_name}/module/addpep.py $wholepep whole_addgff.tsv whole_addgffpep.tsv
python ${dir_name}/module/addpep.py $outdir/data/${prefix}.NLR.pep.fa ann_addgff.tsv ann_addgffpep.tsv

#  Add CDS suquences
python ${dir_name}/module/addcds.py $wholecds whole_addgffpep.tsv whole_addgffpepcds.tsv
python ${dir_name}/module/addcds.py $outdir/data/${prefix}.NLR.cds.fa  ann_addgffpep.tsv ann_addgffpepcds.tsv

#  Check codons
python ${dir_name}/module/checkATG.py ann_addgffpepcds.tsv ann_addgffpepcds_check.tsv

#  Merge
awk 'NR==1 || FNR>1' ann_addgffpepcds_check.tsv whole_addgffpepcds.tsv > merge.tsv

#  Identify the type of NLRs
python ${dir_name}/module/type_simple.py merge.tsv merge_simple.tsv

#  Remove duplicates
python ${dir_name}/module/filter.py merge_simple.tsv ${prefix}.tsv

#  Move intermediate files
mkdir -p processfile
mv ./*.tsv processfile
mv processfile/${prefix}.tsv .
```
## Citation & Contribution

Thanks for all the open source tools used in the process.
Special thanks to the following projects for their inspiration and code references used in the development of this tool:
 -	[**HRP**](https://github.com/AndolfoG/HRP) 
  -	[**PotatoPanNLRome**](https://github.com/HongboDoll/PotatoPanNLRome) 
  
## Contact
Thank you for your interest in **NLRSeek**!  
If you have any questions, suggestions, or collaboration ideas, feel free to reach out:

Email: Mengda Wang (2023122009@stu.njau.edu.cn)
