#!/bin/bash
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
# Wrapper for MATLAB functions: extract combat cog, stability, Cohen's d, sex-stratified stability, sex effect
# source config
source ${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/replication/config/CBIG_LBC_tested_config.sh

# Define paths
Y0_csv="${LBC_rep_dir}/Data/DemoCog_Y0.csv"
Y2_csv="${LBC_rep_dir}/Data/DemoCog_Y2.csv"
combat_csv="${LBC_rep_dir}/Data/cog_Y0Y2_combat.csv"
output_Y0="${LBC_rep_dir}/Data/DemoCog_Y0_combat.csv"
output_Y2="${LBC_rep_dir}/Data/DemoCog_Y2_combat.csv"
output_change="${LBC_rep_dir}/Data/DemoCog_change_combat.csv"
save_stability="${LBC_rep_dir}/Results/cog_stability.mat"
save_cohen_d="${LBC_rep_dir}/Results/cog_cohen_d.mat"
save_stability_F="${LBC_rep_dir}/Results/cog_stability_female.mat"
save_stability_M="${LBC_rep_dir}/Results/cog_stability_male.mat"
save_sex_effect="${LBC_rep_dir}/Results/cog_change_sex_effect.mat"
resid_mat_path="${LBC_rep_dir}/Results/cog_change_resid.mat"
std_mat_path="${LBC_rep_dir}/Results/cog_change_std.mat"
resid_mat_path_F="${LBC_rep_dir}/Results/cog_change_resid_female.mat"
std_mat_path_F="${LBC_rep_dir}/Results/cog_change_std_female.mat"
resid_mat_path_M="${LBC_rep_dir}/Results/cog_change_resid_male.mat"
std_mat_path_M="${LBC_rep_dir}/Results/cog_change_std_male.mat"
save_sex_std_differ="${LBC_rep_dir}/Results/cog_sex_std_differ.mat"


# Helper function for error checking
check_output() {
    local file=$1
    local step=$2
    if [ ! -f "${file}" ]; then
        echo "ERROR: ${step} failed - output file not found: ${file}"
        exit 1
    else
        echo "OK: ${step} completed - ${file}"
    fi
}

# Generate temporary MATLAB script
MATLAB_SCRIPT=$(mktemp /tmp/run_cog_XXXXXX.m)

cat > ${MATLAB_SCRIPT} << EOF
addpath('${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/step1_cog_change/script');
addpath('${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/util/stats');

% Step 2: extract combat-corrected cognition features
CBIG_LBC_extract_combat_cognition('${Y0_csv}', '${Y2_csv}', '${combat_csv}', ...
    '${output_Y0}', '${output_Y2}', '${output_change}');

% Step 3: compute cognitive stability
CBIG_LBC_compute_cog_stability('${output_Y0}', '${output_Y2}', '${save_stability}');

% Step 4: compute Cohen's d
CBIG_LBC_compute_cog_Cohen_d('${output_Y0}', '${output_Y2}', '${save_cohen_d}');

% Step 5: compute sex-stratified cognitive stability
CBIG_LBC_compute_cog_stability_sex_stratify('${output_Y0}', '${output_Y2}', '${save_stability_F}', 'F');
CBIG_LBC_compute_cog_stability_sex_stratify('${output_Y0}', '${output_Y2}', '${save_stability_M}', 'M');

% Step 6: compute sex effects of cognitive change
CBIG_LBC_compute_cog_change_sex_effect('${output_Y0}', '${output_Y2}', '${save_sex_effect}');

% Step 7: compute cognitive change std
CBIG_LBC_compute_cog_change_std('${output_Y0}', '${output_change}', '${resid_mat_path}', '${std_mat_path}');

% Step 8: compute sex-stratified cognitive change std
CBIG_LBC_compute_cog_change_std_sex_stratify('${output_Y0}', '${output_change}', ...
    '${resid_mat_path_F}', '${std_mat_path_F}', '${resid_mat_path_M}', '${std_mat_path_M}');

% Step 9: compute sex difference in cognitive change std
CBIG_LBC_compute_cog_change_std_sex_differ('${resid_mat_path_F}', '${resid_mat_path_M}', '${save_sex_std_differ}');

exit;
EOF

# Run MATLAB script
echo "Running MATLAB steps 2-9..."
matlab -nodisplay -nosplash -r "run('${MATLAB_SCRIPT}');"

# Check outputs
check_output "${output_Y0}"      "Step 2 (extract combat cog)"
check_output "${save_stability}" "Step 3 (cog stability)"
check_output "${save_cohen_d}"   "Step 4 (Cohen's d)"
check_output "${save_stability_F}" "Step 5 (sex-stratified stability F)"
check_output "${save_stability_M}" "Step 5 (sex-stratified stability M)"
check_output "${save_sex_effect}"  "Step 6 (sex effect)"
check_output "${resid_mat_path}"   "Step 7 (cog change std)"
check_output "${resid_mat_path_F}" "Step 8 (sex-stratified std F)"
check_output "${resid_mat_path_M}" "Step 8 (sex-stratified std M)"
check_output "${save_sex_std_differ}" "Step 9 (sex std difference)"

echo "All steps completed successfully."

# Clean up temporary file
rm -f ${MATLAB_SCRIPT}
