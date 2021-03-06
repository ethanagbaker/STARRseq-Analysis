#!/bin/bash
#BSUB -q week
#BSUB -W 136:57
#BSUB -M 102400
#BSUB -J bow2_1
#BSUB -R "span[hosts=1]"
#BSUB -e /project/fas/gerstein/eab232/enhancerSeq/analysis/logs/%J.err
#BSUB -o /project/fas/gerstein/eab232/enhancerSeq/analysis/logs/%J.out

ENHANCERSEQ_DIR='/gpfs/scratch/fas/gerstein/common/KW_EnhancerSeq'
GENOME_DIR="/project/fas/gerstein/eab232/enhancerSeq/data/genomes/Homo_sapiens/hg19"
GENOME_FASTA="hg19.fa" 
ANALYSIS_DIR="/project/fas/gerstein/eab232/enhancerSeq/analysis"
BEDTOOLS_PATH="/home/fas/gerstein/eab232/software/bedtools2-2.25.0/bin"
MACS_PATH="/home/fas/gerstein/eab232/software/MACS-1.3.7.1/bin"

#Build bowtie2 index of hg19
module load Apps/Bowtie2
cd $GENOME_DIR
bowtie2-build -f $GENOME_FASTA .

#Perform alignment (default mode is unique mapping, -M deprecated)
bowtie2 -x $GENOME_DIR/$GENOME_FASTA -1 $ENHANCERSEQ_DIR/H1.SCP1.WGscreenLib.R1.1.fastq.gz -2 $ENHANCERSEQ_DIR/H1.SCP1.WGscreenLib.R1.2.fastq.gz -S $ANALYSIS_DIR/H1.SCP1.WGscreenLib.R1.sam -p 8 

cd $ANALYSIS_DIR
module load Tools/SAMtools
samtools view -Sb H1.SCP1.WGscreenLib.R1.sam > H1.SCP1.WGscreenLib.R1.bam 
$BEDTOOLS_PATH/bedtools bamtobed -i H1.SCP1.WGscreenLib.R1.bam > H1.SCP1.WGscreenLib.R1.bed 
gzip H1.SCP1.WGscreenLib.R1.sam

#This breaks under large files...replaced with SAMtools
"""sort -k 1,1 H1WG.SCP1.H1.R2.bed > H1WG.SCP1.H1.R2.sorted.bed
awk '{print $0 >> $1".bed"}' H1WG.SCP1.H1.R2.sorted.bed
ls chr*.bed | cut -f 1 -d '.' > bednames.txt
cat bednames.txt | while read x ; do `sort -k 1,1 $x.bed > $x.sorted.bed`; done
cat bednames.txt | while read x; do `$BEDTOOLS_PATH/coverageBed -a ../hg19_5kbWindows.bed -b $x.bed > $x.vs5kbWindowsCoverage.bed`; done"""

#Tile the genome with 5kb windows, calculate coverage in each. 
module load Tools/SAMtools
samtools sort H1.SCP1.WGscreenLib.R1.bam  >  H1.SCP1.WGscreenLib.R1.sorted.bam
samtools index H1.SCP1.WGscreenLib.R1.sorted.bam
$BEDTOOLS_PATH -g $GENOME_DIR/$GENOME_FASTA.fai -w 5000 > hg19_5kbWindows.bed
samtools bedcov hg19_5kbWindows.bed H1.SCP1.WGscreenLib.R1.sorted.bam > H1.SCP1.WGscreenLib.R1_5kpWindowCov.bed

#Process coverage bedfiles and make a simplified bedfile w/ FoldChange
python meanConservationFromSamtools.py
python topCoverageDecile.py
cut -f 1,2,3,7 H1WG.SCP1.H1.R1_5kbWindowsVsControl_Calculations_top10.txt > H1WG.SCP1.H1.R1_5kbWindowsVsControl_Calculations_top10.bed
cut -f 1,2,3,7 H1WG.SCP1.H1.R2_5kbWindowsVsControl_Calculations_top10.txt > H1WG.SCP1.H1.R2_5kbWindowsVsControl_Calculations_top10.bed

#Merge adjacent bins. Calculate mean|min|max FoldChange
$BEDTOOLS_PATH/bedtools merge -i H1WG.SCP1.H1.R1_5kbWindowsVsControl_Calculations_top10.bed -c 4 -o mean,min,max -delim "|" > H1WG.SCP1.H1.R1_5kbWindowsVsControl_Calculations_top10_merged.bed
$BEDTOOLS_PATH/bedtools merge -i H1WG.SCP1.H1.R2_5kbWindowsVsControl_Calculations_top10.bed -c 4 -o mean,min,max -delim "|" > H1WG.SCP1.H1.R2_5kbWindowsVsControl_Calculations_top10_merged.bed
cut -f 1,2,3,4 H1WG.SCP1.H1.R1_5kbWindowsVsControl_Calculations_top10_merged.bed > H1WG.SCP1.H1.R1_peaks.bed 
cut -f 1,2,3,4 H1WG.SCP1.H1.R2_5kbWindowsVsControl_Calculations_top10_merged.bed > H1WG.SCP1.H1.R2_peaks.bed 


