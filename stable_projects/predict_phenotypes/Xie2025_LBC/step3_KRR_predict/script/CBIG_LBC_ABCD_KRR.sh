#!/bin/sh
#####
# This script calls the matlab function to run KRR. User needs to provide the following variables.
#  1. feature_path: path to feature mat file (without .mat extension)
#  2. outdir:       output directory
#  3. sites:        number of sites used for the test fold
#  4. innerFolds:   number of inner folds
#  5. subtxt:       list of subjects (full path)
#  6. subcsv:       table of behaviour scores (full path)
#  7. predvar:      txt file of names of behaviours to predict from subcsv
#  8. covtxt:       txt file of names of covariates to regress from y variables
#  9. ymat:         output name of behaviours mat file
# 10. covmat:       output name of covariates mat file
# 11. cov_types:    comma-separated list of covariate types, in the same order as covtxt.
#                   Each entry must be 'continuous' or 'categorical'. No spaces, no braces.
#                   e.g.: continuous,categorical,continuous
# 12. keep_fsm:     (optional, default 0) set to 1 to copy FSM kernel folders back to NAS.
#                   FSM folders are large (~15GB); only enable when needed.
#
# EXAMPLE:
#    CBIG_LBC_ABCD_KRR.sh $feature_path $outdir $sites $innerFolds \
#        $subtxt $subcsv $predvar $covtxt $ymat $covmat $cov_types $keep_fsm
# EXAMPLE OF HOW TO CALL FUNCTION:
#    CBIG_LBC_ABCD_KRR.sh data_dir/features/rs output_dir 3 10 data_dir/subs.txt \
#        data_dir/scores.csv data_dir/prediction_variables.txt \
#        data_dir/covariates.txt output_y.mat output_cov.mat \
#        continuous,categorical,continuous 1
#
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
#####

# set directories
script_dir=$(dirname "$(readlink -f "$0")")

# set params
feature_path=$1
featurebase=$(basename "${feature_path%.mat}")
outstem="KRR_$featurebase"
outdir=$2
sites=$3
innerFolds=$4
subtxt=$5
subcsv=$6
predvar=$7
covtxt=$8
ymat=$9
covmat=${10}
cov_types=${11}
keep_fsm=${12:-0}

# Convert comma-separated cov_types to MATLAB cell array syntax
# e.g. continuous,categorical,continuous -> {'continuous','categorical','continuous'}
matlab_cov_types="{$(echo "$cov_types" | sed "s/\([^,]*\)/'\1'/g")}"

# Create log file and save params
mkdir -p "$outdir/$outstem/logs"
LF="$outdir/$outstem/logs/$outstem.log"
if [ -f "$LF" ]; then rm "$LF"; fi
echo "outstem    = $outstem"    >> "$LF"
echo "outdir     = $outdir"     >> "$LF"
echo "sites      = $sites"      >> "$LF"
echo "innerFolds = $innerFolds" >> "$LF"
echo "subtxt     = $subtxt"     >> "$LF"
echo "subcsv     = $subcsv"     >> "$LF"
echo "predvar    = $predvar"    >> "$LF"
echo "covtxt     = $covtxt"     >> "$LF"
echo "ymat       = $ymat"       >> "$LF"
echo "covmat     = $covmat"     >> "$LF"
echo "cov_types  = $matlab_cov_types" >> "$LF"
echo "keep_fsm   = $keep_fsm"        >> "$LF"

# Call matlab function
echo "Running KRR for: $featurebase"
matlab -nodesktop -nosplash -nodisplay -r " \
    try; \
        addpath('$script_dir'); \
        CBIG_LBC_ABCD_KRR($sites, $innerFolds, '$feature_path', '$featurebase', \
            '$outdir', '$subtxt', '$subcsv', '$predvar', '$covtxt', \
            '$ymat', '$covmat', $matlab_cov_types, $keep_fsm); \
    catch ME; \
        fprintf('ERROR: %s\n', ME.message); \
    end; \
    exit; " >> "$LF" 2>&1
