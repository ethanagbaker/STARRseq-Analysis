#!/bin/bash
#BSUB -q shared
#BSUB -W 23:55
#BSUB -J MACS
#BSUB -R "span[hosts=1]"
#BSUB -e /project/fas/gerstein/eab232/starrseq/analysis/logs/%J.err
#BSUB -o /project/fas/gerstein/eab232/starrseq/analysis/logs/%J.out

ANALYSIS_DIR="/project/fas/gerstein/eab232/starrseq/analysis"
MACS_PATH="/home/fas/gerstein/eab232/software/MACS-1.3.7.1/bin"
CONTROL_BED="/project/fas/gerstein/eab232/starrseq/analysis/inputData/S2_STARRseq_input_Dmel_map.sorted.bed"

python $MACS_PATH/macs -t $ANALYSIS_DIR/S2_STARRseq_rep1_Dmel_map.bed -c $CONTROL_BED --name S2_STARRseq_rep1_vsControl  --gsize 120000000 --pvalue .00001 --bw 500 --mfold 3 

#Here, the control data is the BED result of the bowtie2 alignment of the input data. 