#!/bin/bash
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

id=$1
sub_dir=$2
bold=$3
FD_th=$4
DV_th=$5
output_dir=$6

${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/\
step4_FC_change_reliability/script/CBIG_LBC_FCmetrics_Nmin_wrapper.csh \
    -s ${id} -d ${sub_dir} -bld "${bold}" \
    -BOLD_stem _rest_mc_skip_residc_interp_FDRMS${FD_th}_DVARS${DV_th}_bp_0.009_0.08 \
    -SURF_stem _rest_mc_skip_residc_interp_FDRMS${FD_th}_DVARS${DV_th}_bp_0.009_0.08_fs6_sm6 \
    -OUTLIER_stem _FDRMS${FD_th}_DVARS${DV_th}_motion_outliers.txt \
    -Pearson_r -o ${output_dir} -censor
