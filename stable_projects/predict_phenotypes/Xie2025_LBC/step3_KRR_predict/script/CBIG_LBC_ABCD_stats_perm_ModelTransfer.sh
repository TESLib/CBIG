#!/bin/sh
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
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

# set params
singleKRR_dir_y0=$1
FC_Y0=$2
FC_Y2=$3
y2_resid_dir=$4
outstem_y0=$5
score_ind=$6
site_list=$7
outdir=$8
perm_seed_start=1
N_perm=1000

# Create log file and save params
mkdir -p $outdir/logs
LF="$outdir/logs/score_${score_ind}.log"
if [ -f $LF ]; then rm $LF; fi

echo "outstem_y0 = $outstem_y0" >> $LF
echo "outdir = $outdir" >> $LF
echo "singleKRR_dir_y0 = $singleKRR_dir_y0" >> $LF
echo "FC_Y0 = $FC_Y0" >> $LF
echo "FC_Y2 = $FC_Y2" >> $LF
echo "y2_resid_dir = $y2_resid_dir" >> $LF
echo "site_list = $site_list" >> $LF
echo "score_ind = $score_ind" >> $LF
echo "perm_seed_start = $perm_seed_start" >> $LF
echo "N_perm = $N_perm" >> $LF

# Call matlab function
matlab -nodesktop -nosplash -nodisplay -r " try addpath('$script_dir'); "\
"CBIG_LBC_compute_singleKRR_modelTransferY2('$singleKRR_dir_y0', '$FC_Y0',"\
" '$FC_Y2', '$y2_resid_dir', '$outstem_y0', '$score_ind',"\
" '$site_list', '$outdir', $perm_seed_start, $N_perm);"\
" catch ME; display(ME.message); end; exit; " >> $LF 2>&1

