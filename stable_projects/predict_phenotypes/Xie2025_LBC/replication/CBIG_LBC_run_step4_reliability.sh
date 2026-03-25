#!/bin/bash
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
# Master step 4 reliability pipeline.
# Usage: bash CBIG_LBC_run_step4_reliability.sh <step>
#   step = 1 : submit per-subject FC compute jobs (4 conditions x all subjects)
#   step = 2 : submit combine jobs (after step 1 finishes)
#   step = 3 : submit reliability analysis (extract FC, ICC, fit model, Rd/T)

script_dir=$(dirname "$(readlink -f "$0")")
source ${script_dir}/config/CBIG_LBC_tested_config.sh

step=${1:-1}
ncpus='1'
FD_th="0.3"
DV_th="50"
test_mode=0   # set to 1 to test with first subject only

matlab_script_dir=${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/step4_FC_change_reliability/script
lbc_dir=${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC
sub_id_file=${LBC_rep_dir}/Data/SubID_4run_final.txt

##########################################################################
# Step 1: Submit per-subject FC compute jobs
##########################################################################
if [ ${step} -eq 1 ]; then
    echo "=== Step 1: Submitting per-subject FC compute jobs ==="
    for year in y0 y2; do
        case ${year} in
            y0) name_combine='CombY0' ;;
            y2) name_combine='CombY2' ;;
        esac

        for half in FirstHalf LastHalf; do
            name_compute="FC${year^^}${half:0:2}Nmin"
            output_dir=${LBC_rep_dir}/Reliability/FC${year^^}_${half}_Nmin
            mkdir -p ${output_dir}

            mem='12G'
            sub_dir=${ABCD_preprocessed}/${year}/rs_GSR_mf_FD0.3_DVARS50/mproc_R4
            sub_list=$([ ${test_mode} -eq 1 ] && head -1 ${sub_id_file} || cat ${sub_id_file})
            job_counter=0

            for id in ${sub_list}; do
                flag_file="${output_dir}/${id}/FC_metrics/${id}"\
"_rest_mc_skip_residc_interp_FDRMS${FD_th}_DVARS${DV_th}_bp_0.009_0.08_fs6_sm6.flag"
                if [ -f "${flag_file}" ]; then
                    echo "Skipping ${id}: results already exist."
                    continue
                fi

                bold=$(cat ${LBC_rep_dir}/Data/RunNum/${year}/${id}_${half}.bold | xargs)
                bold="\"${bold}\""
                cmd_script="${matlab_script_dir}/CBIG_LBC_compute_FC_Nmin.sh "\
"${id} ${sub_dir} ${bold} ${FD_th} ${DV_th} ${output_dir}"

                mkdir -p ${output_dir}/FC_Log/${id}
                $CBIG_CODE_DIR/setup/CBIG_pbsubmit -cmd "$cmd_script" -walltime 00:20:00 -mem $mem \
                    -name ${name_compute} \
                    -joberr "${output_dir}/FC_Log/${id}/err.txt" \
                    -jobout "${output_dir}/FC_Log/${id}/out.txt" \
                    -ncpus ${ncpus}

                job_counter=$((job_counter + 1))
                if (( job_counter % 200 == 0 )); then
                    echo "Submitted 200 jobs. Sleeping for 60 seconds..."
                    sleep 60
                fi
            done
        done
    done

##########################################################################
# Step 2: Submit combine jobs (run after step 1 finishes)
##########################################################################
elif [ ${step} -eq 2 ]; then
    echo "=== Step 2: Submitting combine jobs ==="
    for year in y0 y2; do
        case ${year} in
            y0) name_combine='CombY0' ;;
            y2) name_combine='CombY2' ;;
        esac

        for half in FirstHalf LastHalf; do
            output_dir=${LBC_rep_dir}/Reliability/FC${year^^}_${half}_Nmin
            log_dir=${output_dir}/Combine_Log
            mkdir -p ${log_dir}

            cmd_script="matlab -nodesktop -nodisplay -nosplash -r \
\"addpath(genpath('${matlab_script_dir}')); \
CBIG_LBC_combine_FC_Nmin('${output_dir}', '${sub_id_file}'); exit;\""

            $CBIG_CODE_DIR/setup/CBIG_pbsubmit -cmd "$cmd_script" -walltime 00:30:00 -mem '10G' \
                -name ${name_combine} \
                -joberr ${log_dir}/err.txt -jobout ${log_dir}/out.txt \
                -ncpus ${ncpus}
            echo "Submitted combine: FC${year^^}_${half}_Nmin"
        done
    done

##########################################################################
# Step 3: Submit reliability analysis (after step 2 finishes)
##########################################################################
elif [ ${step} -eq 3 ]; then
    echo "=== Step 3: Submitting reliability analysis job ==="
    cog_file=${LBC_rep_dir}/Data/DemoCog_Y2.csv
    FCY0_file=${LBC_rep_dir}/Data/FC_final_Y0.mat
    FCY2_file=${LBC_rep_dir}/Data/FC_final_Y2.mat
    reliability_dir=${LBC_rep_dir}/Reliability
    output_dir=${LBC_rep_dir}/Reliability/Results
    mkdir -p ${output_dir}

    fc_struct_file=${output_dir}/FC_Nmin.mat
    icc_file=${output_dir}/ICC_Nmin.mat
    fitmodel_file=${output_dir}/Reliability_FitModel.mat
    output_Rd_file=${output_dir}/Rd_mat.mat
    output_T_file=${output_dir}/T_mat.mat
    log_dir=${output_dir}/Log
    mkdir -p ${log_dir}

    cmd_script="matlab -nodesktop -nodisplay -nosplash -r \
\"addpath(genpath('${lbc_dir}')); \
fprintf('Step 3a: Extract FC\\n'); \
CBIG_LBC_extract_FC_Nmin('${reliability_dir}', '${sub_id_file}', '${fc_struct_file}'); \
fprintf('Step 3b: Compute ICC\\n'); \
CBIG_LBC_compute_ICC_Nmin('${fc_struct_file}', '${sub_id_file}', '${icc_file}'); \
fprintf('Step 3c: Fit reliability model\\n'); \
CBIG_LBC_reliability_fitmodel('${icc_file}', '${fitmodel_file}'); \
fprintf('Step 3d: Compute Rd and T estimate\\n'); \
CBIG_LBC_compute_Rd_and_Testimate('${sub_id_file}', '${cog_file}', \
'${FCY0_file}', '${FCY2_file}', '${fitmodel_file}', \
'${output_Rd_file}', '${output_T_file}'); \
exit;\""

    $CBIG_CODE_DIR/setup/CBIG_pbsubmit -cmd "$cmd_script" -walltime 24:00:00 -mem '80G' \
        -name 'RelNmin' -joberr ${log_dir}/err.txt -jobout ${log_dir}/out.txt -ncpus ${ncpus}
    echo "Submitted reliability analysis job."

else
    echo "Unknown step: ${step}"
    echo "Usage: bash $(basename $0) <1|2|3>"
    exit 1
fi

echo "Done."
exit 0
