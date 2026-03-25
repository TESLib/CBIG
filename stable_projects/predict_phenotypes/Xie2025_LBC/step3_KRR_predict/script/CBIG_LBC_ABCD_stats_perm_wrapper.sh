#!/bin/sh
# Written by Yapei Xie and CBIG under MIT license:
# https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
#####
# This script calls the matlab function to run generate the null models. User needs to provide the following variables.
# 1. feature_path: path to feature mat file
# 2. outdir: output directory
# 3. sites: number of sites used for the test fold
# 4. innerFold: number of inner folds
# 5. subtxt: list of subjects
# 6. subcsv: table of behaviour scores
# 7. predvar: txt file of names of behaviours to predict from subcsv
# 8. covtxt: txt file of names of covariates to regress from y variables
# 9. ymat: output name of behaviours to be predicted
# 10. covmat: output name of covariates to control for
# 
# EXAMPLE: 
#    CBIG_MMP_ABCD_KRR.sh $feature_path $outdir $sites $innerFolds \
#        $subtxt $subcsv $predvar $covtxt $ymat $covmat
# Written by Leon Ooi and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
#####

# set directories
script_dir=$(dirname "$(readlink -f "$0")")

# set outstem
outstem=$1
# set params
model_dir=$2
outdir=$3
site_list=$4
score_ind=$5
perm_seed_start=1
N_perm=1000

# Create log file and save params
mkdir -p $outdir/logs
LF="$outdir/logs/${outstem}_${score_ind}.log"
if [ -f $LF ]; then rm $LF; fi

echo "outstem = $outstem" >> $LF
echo "outdir = $outdir" >> $LF
echo "model_dir = $model_dir" >> $LF
echo "site_list = $site_list" >> $LF
echo "score_ind = $score_ind" >> $LF
echo "perm_seed_start = $perm_seed_start" >> $LF
echo "N_perm = $N_perm" >> $LF

# Call matlab function

matlab -nodesktop -nosplash -nodisplay -r " try addpath('$script_dir'); CBIG_LBC_ABCD_compute_singleKRR_perm_stats(\
'$model_dir', '$outstem', $score_ind, $perm_seed_start, $N_perm, '$site_list', \
'$outdir'); catch ME; display(ME.message); end; exit; " >> $LF 2>&1

