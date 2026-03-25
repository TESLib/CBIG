#!/bin/bash
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

# load config
source ${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/replication/config/CBIG_LBC_tested_config.sh

# run longitudinal ComBat on cognition data
Rscript "${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/"\
"step1_cog_change/script/CBIG_LBC_longComBat_cog_wrapper.R"

# compute cognitive stability and change
bash "${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/"\
"step1_cog_change/script/CBIG_LBC_cog_stabilty_change_wrapper.sh"


