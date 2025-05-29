#!/bin/bash

dir_name=`dirname $0`

# Parse command-line arguments
while getopts ":c:n:f:" opt; do
  case $opt in
    c)
      wholecdna="$OPTARG"
      ;;
    n)
      cpus="$OPTARG"
      ;;
    f)
      PREFIX="$OPTARG"
      ;;
    \?)
      echo "无效选项: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "选项 -$OPTARG 需要一个参数" >&2
      exit 1
      ;;
  esac
done

# maker ctl
maker -CTL

SCRIPT_DIR=$(dirname "$0")
snaphmm=../snap/${PREFIX}.hmm

# write maker_opts.ctl
sed -e "0,/est=/s|est=|est=${wholecdna}|" \
    -e "0,/protein=/s|protein=|protein=${dir_name}/homopep.fa|" \
    -e "0,/snaphmm=/s|snaphmm=|snaphmm=${snaphmm}|" \
    -e "0,/augustus_species=/s|augustus_species=|augustus_species=${PREFIX}_Seeker|" \
    -e '0,/est2genome=0/s|est2genome=0|est2genome=1|' \
    -e '0,/protein2genome=0/s|protein2genome=0|protein2genome=1|' \
    -e "0,/cpus=1/s|cpus=1|cpus=${cpus}|" \
    maker_opts.ctl > tmp

rm -rf maker_opts.ctl
mv tmp maker_opts.ctl

# runningmaker
maker -base nlr_4k_${PREFIX} -genome ../../annotator/NLR_4k_seq/${PREFIX}.NLR.4k.fa  -cpus ${cpus} maker_opts.ctl maker_bopts.ctl maker_exe.ctl

# After maker processing finished

# maker get fasta
fasta_merge -d nlr_4k_${PREFIX}.maker.output/nlr_4k_${PREFIX}_master_datastore_index.log

# mv file
mkdir -p gff2pro  gff2ann && mv ./*.fasta gff2pro
cd gff2ann

# maker get gff
gff3_merge -d ../nlr_4k_${PREFIX}.maker.output/nlr_4k_${PREFIX}_master_datastore_index.log

# filter
awk '$2=="maker"' nlr_4k_${PREFIX}.all.gff > nlr_4k_${PREFIX}.purged.all.NLR.gff

sed 's/;/%3B/' ../../../annotator/NLR_4k_gff/${PREFIX}.NLR.4k.gff3 > convert_${PREFIX}.NLR.4k.gff

sed 's/;/%3B/' ../gff2pro/nlr_4k_${PREFIX}.all.maker.proteins.fasta > ${PREFIX}.NLR.pep.fa

python $SCRIPT_DIR/new_convert_NLR_gff_coordinates.py convert_${PREFIX}.NLR.4k.gff nlr_4k_${PREFIX}.purged.all.NLR.gff > ${PREFIX}.NLR.gff

maker_map_ids --prefix ${PREFIX} --justify 6 ${PREFIX}.NLR.gff > genome.all.id.map

map_gff_ids genome.all.id.map ${PREFIX}.NLR.gff

map_fasta_ids genome.all.id.map  ${PREFIX}.NLR.pep.fa

gffread ${PREFIX}.NLR.gff -g ../../../data/whole.dna.fasta -x  ${PREFIX}.NLR.cds.fa


