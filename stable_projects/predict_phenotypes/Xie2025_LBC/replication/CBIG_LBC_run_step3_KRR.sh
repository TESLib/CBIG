#!/bin/bash
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
# Master KRR submission script.
# Usage: bash CBIG_LBC_run_step3_KRR.sh <mode>
#   mode = main       : standard 8-condition prediction
#   mode = transfer   : model transfer (FC_Y0 model applied to Y2)
#   mode = sex        : sex-stratified prediction (male/female, 7 conditions)
#   mode = generalize : generalization prediction (replication sample, 7 conditions)
#   mode = all        : run all 4 analyses above

# load config
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_DIR}/config/CBIG_LBC_tested_config.sh"

mode=${1:-main}

krr_script="${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/"\
"Xie2025_LBC/step3_KRR_predict/script/CBIG_LBC_ABCD_KRR.sh"
KRR_SCRIPT_DIR="${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC/step3_KRR_predict/script"
ncpus='1'
mem='64G'
walltime='16:00:00'
submit_delay=600

sites=3
innerFolds=10
predvar="${LBC_rep_dir}/Data/BehaviorName.txt"
ymat="BehaviorVar.mat"
covmat="CovarateVar.mat"

##########################################################################
# Helper: submit one KRR job
##########################################################################
submit_krr_job() {
    local feature_path=$1 outdir=$2 subtxt=$3 subcsv=$4 covtxt=$5
    local cov_types=$6 keep_fsm=$7 name=$8

    mkdir -p "${outdir}" "${outdir}/LogInfo"
    local cmd="${krr_script} ${feature_path} ${outdir} ${sites} ${innerFolds} \
${subtxt} ${subcsv} ${predvar} ${covtxt} ${ymat} ${covmat} ${cov_types} ${keep_fsm}"
    $CBIG_CODE_DIR/setup/CBIG_pbsubmit -cmd "$cmd" -walltime ${walltime} -mem ${mem} \
        -name ${name} \
        -joberr "${outdir}/LogInfo/predict_err.txt" \
        -jobout "${outdir}/LogInfo/predict_out.txt" \
        -ncpus ${ncpus}
    echo "Submitted [${name}]: $(basename ${feature_path}) -> ${outdir}"
    sleep ${submit_delay}
}

##########################################################################
# MODE: main — standard 8-condition prediction
##########################################################################
run_main() {
    echo "=== Submitting main KRR jobs ==="
    local subtxt="${LBC_rep_dir}/Data/SubID_final.txt"

    local feature_paths=(
        "${LBC_rep_dir}/Data/FC_final_Y0"    # 0: FC_Y0    -> CogY0
        "${LBC_rep_dir}/Data/FC_final_Y2"    # 1: FC_Y2    -> CogY2
        "${LBC_rep_dir}/Data/Delta_FC"       # 2: DeltaFC  -> CogY2
        "${LBC_rep_dir}/Data/FC_final_Y0"    # 3: FC_Y0    -> CogY2
        "${LBC_rep_dir}/Data/FC_final_Y2"    # 4: FC_Y2    -> CogY0
        "${LBC_rep_dir}/Data/Delta_FC"       # 5: DeltaFC  -> DeltaCog
        "${LBC_rep_dir}/Data/FC_final_Y0"    # 6: FC_Y0    -> DeltaCog
        "${LBC_rep_dir}/Data/FCY0_4min"      # 7: FCY04min -> CogY2
    )
    local outdirs=(
        "${LBC_rep_dir}/Results/KRR_results/FC_Y0"
        "${LBC_rep_dir}/Results/KRR_results/FC_Y2"
        "${LBC_rep_dir}/Results/KRR_results/FC_DeltaCogY2"
        "${LBC_rep_dir}/Results/KRR_results/FC_Y0Y2"
        "${LBC_rep_dir}/Results/KRR_results/FCY2_CogY0"
        "${LBC_rep_dir}/Results/KRR_results/FC_DeltaCogDelta"
        "${LBC_rep_dir}/Results/KRR_results/FCY0_CogDelta"
        "${LBC_rep_dir}/Results/KRR_results/FCY04min_CogY2"
    )
    local subcsv_list=(
        "${LBC_rep_dir}/Data/DemoCog_Y0.csv"
        "${LBC_rep_dir}/Data/DemoCog_Y2.csv"
        "${LBC_rep_dir}/Data/DemoCog_Y2.csv"
        "${LBC_rep_dir}/Data/DemoCog_Y2.csv"
        "${LBC_rep_dir}/Data/DemoCog_Y0_AgeInterval.csv"
        "${LBC_rep_dir}/Data/DemoCog_Delta.csv"
        "${LBC_rep_dir}/Data/DemoCog_Delta.csv"
        "${LBC_rep_dir}/Data/DemoCog_Y2.csv"
    )
    local covtxt_list=(
        "${LBC_rep_dir}/Data/CovName_Y0.txt"
        "${LBC_rep_dir}/Data/CovName_Y2.txt"
        "${LBC_rep_dir}/Data/CovName_FCdelta_CogY2.txt"
        "${LBC_rep_dir}/Data/CovName_FCY0_CogY2.txt"
        "${LBC_rep_dir}/Data/CovName_FCY2_CogY0.txt"
        "${LBC_rep_dir}/Data/CovName_FCdelta_CogDelta.txt"
        "${LBC_rep_dir}/Data/CovName_FCY0_CogDelta.txt"
        "${LBC_rep_dir}/Data/CovName_FCY0_CogY2.txt"
    )
    local cov_types_list=(
        "continuous,categorical,continuous"
        "continuous,categorical,continuous"
        "continuous,continuous,categorical,continuous,continuous"
        "continuous,continuous,categorical,continuous"
        "continuous,continuous,categorical,continuous"
        "continuous,continuous,categorical,continuous,continuous"
        "continuous,continuous,categorical,continuous"
        "continuous,continuous,categorical,continuous"
    )
    local keep_fsm_list=(1 0 0 0 0 0 0 0)

    for i in "${!feature_paths[@]}"; do
        submit_krr_job "${feature_paths[$i]}" "${outdirs[$i]}" "${subtxt}" \
            "${subcsv_list[$i]}" "${covtxt_list[$i]}" \
            "${cov_types_list[$i]}" "${keep_fsm_list[$i]}" "predict"
    done
}

##########################################################################
# MODE: transfer — model transfer Y0 -> Y2
##########################################################################
run_transfer() {
    echo "=== Submitting model transfer jobs ==="
    local y0_csv="${LBC_rep_dir}/Data/DemoCog_Y0.csv"
    local y2_csv="${LBC_rep_dir}/Data/DemoCog_Y2.csv"
    local y_col_start=15
    local y_col_end=22
    local covmat_y0="${LBC_rep_dir}/Results/KRR_results/FC_Y0/CovarateVar.mat"
    local covmat_y2="${LBC_rep_dir}/Results/KRR_results/FC_Y2/CovarateVar.mat"
    local subfold_mat="${LBC_rep_dir}/Results/KRR_results/FC_Y0/no_relative_3_fold_sub_list.mat"
    local outstem="cognition8"
    local y2_resid_dir="${LBC_rep_dir}/Results/KRR_results/ModelTransfer/regress_Y2"
    local singleKRR_dir_y0="${LBC_rep_dir}/Results/KRR_results/FC_Y0/KRR_FC_final_Y0"
    local FC_Y0="${LBC_rep_dir}/Data/FC_final_Y0"
    local FC_Y2="${LBC_rep_dir}/Data/FC_final_Y2"
    local outstem_y0="KRR_FC_final_Y0"
    local site_list="${LBC_rep_dir}/Data/DemoCog_Y0.csv"
    local transfer_outdir="${LBC_rep_dir}/Results/KRR_results/ModelTransfer"
    local N_scores=8
    local walltime_regress="1:00:00" mem_regress="32G"
    local walltime_perm="2:00:00"   mem_perm="16G"

    mkdir -p "${y2_resid_dir}/LogInfo" "${transfer_outdir}/LogInfo"

    local regress_cmd="matlab -nodesktop -nosplash -nodisplay -r \" \
        try; \
            addpath('${KRR_SCRIPT_DIR}'); \
            CBIG_LBC_crossvalid_regress_covariates_Y2('${y0_csv}', '${y2_csv}', \
                ${y_col_start}, ${y_col_end}, \
                '${covmat_y0}', '${covmat_y2}', '${subfold_mat}', \
                '${y2_resid_dir}', '${outstem}'); \
        catch ME; \
            fprintf('ERROR: %s\n', ME.message); \
        end; \
        exit; \""

    local y2_job_id=$(echo "#!/bin/bash
${regress_cmd}" | qsub -V \
        -l "walltime=${walltime_regress}" -l "mem=${mem_regress}" \
        -l "nodes=1:ppn=${ncpus}" -N "regress_Y2" \
        -o "${y2_resid_dir}/LogInfo/regress_Y2_out.txt" \
        -e "${y2_resid_dir}/LogInfo/regress_Y2_err.txt")
    echo "Submitted Y2 regression job: ${y2_job_id}"

    local transfer_wrapper="${KRR_SCRIPT_DIR}/CBIG_LBC_ABCD_stats_perm_ModelTransfer.sh"
    for score_ind in $(seq 1 ${N_scores}); do
        local transfer_cmd="${transfer_wrapper} ${singleKRR_dir_y0} ${FC_Y0} ${FC_Y2} \
            ${y2_resid_dir} ${outstem_y0} ${score_ind} ${site_list} ${transfer_outdir}"
        local transfer_job_id=$(echo "#!/bin/bash
${transfer_cmd}" | qsub -V \
            -W "depend=afterok:${y2_job_id}" \
            -l "walltime=${walltime_perm}" -l "mem=${mem_perm}" \
            -l "nodes=1:ppn=${ncpus}" -N "modeltransfer_score${score_ind}" \
            -o "${transfer_outdir}/LogInfo/modeltransfer_score${score_ind}_out.txt" \
            -e "${transfer_outdir}/LogInfo/modeltransfer_score${score_ind}_err.txt")
        echo "Submitted model-transfer score ${score_ind}: ${transfer_job_id}"
    done
}

##########################################################################
# MODE: sex — sex-stratified prediction (7 conditions x male/female)
##########################################################################
run_sex() {
    echo "=== Submitting sex-stratified KRR jobs ==="
    local sex_dir="${LBC_rep_dir}/Data/KRR_sex"

    local feature_names=(
        "FC_final_Y0" "FC_final_Y2" "Delta_FC" "FC_final_Y0"
        "Delta_FC" "FC_final_Y0" "FCY0_4min"
    )
    local outdirs=(
        "${LBC_rep_dir}/Results/KRR_results_sex/FC_Y0"
        "${LBC_rep_dir}/Results/KRR_results_sex/FC_Y2"
        "${LBC_rep_dir}/Results/KRR_results_sex/FC_DeltaCogY2"
        "${LBC_rep_dir}/Results/KRR_results_sex/FC_Y0Y2"
        "${LBC_rep_dir}/Results/KRR_results_sex/FC_DeltaCogDelta"
        "${LBC_rep_dir}/Results/KRR_results_sex/FCY0_CogDelta"
        "${LBC_rep_dir}/Results/KRR_results_sex/FCY04min_CogY2"
    )
    local subcsv_names=(
        "Demo_CogY0" "Demo_CogY2" "Demo_CogY2" "Demo_CogY2"
        "Demo_CogDelta" "Demo_CogDelta" "Demo_CogY2"
    )
    local covtxt_names=(
        "CovName_Y0" "CovName_Y2" "CovName_FCdelta_CogY2" "CovName_FCY0_CogY2"
        "CovName_FCdelta_CogDelta" "CovName_FCY0_CogDelta" "CovName_FCY0_CogY2"
    )
    local cov_types_list=(
        "continuous,continuous"
        "continuous,continuous"
        "continuous,continuous,continuous,continuous"
        "continuous,continuous,continuous"
        "continuous,continuous,continuous,continuous"
        "continuous,continuous,continuous"
        "continuous,continuous,continuous"
    )
    local keep_fsm_list=(1 0 0 0 0 0 0)

    for sex in male female; do
        local subtxt="${sex_dir}/SubID_final_${sex}.txt"
        for i in "${!feature_names[@]}"; do
            submit_krr_job \
                "${sex_dir}/${feature_names[$i]}_${sex}" \
                "${outdirs[$i]}_${sex}" \
                "${subtxt}" \
                "${sex_dir}/${subcsv_names[$i]}_${sex}.csv" \
                "${sex_dir}/${covtxt_names[$i]}.txt" \
                "${cov_types_list[$i]}" "${keep_fsm_list[$i]}" "predictSex"
        done
    done
}

##########################################################################
# MODE: generalize — generalization prediction (7 conditions)
##########################################################################
run_generalize() {
    echo "=== Submitting generalization KRR jobs ==="
    local gen_dir="${LBC_rep_dir}/Data/KRR_generalize"
    local subtxt="${gen_dir}/SubID_rep_sub.txt"

    local feature_paths=(
        "${gen_dir}/FC_final_Y0.mat"
        "${gen_dir}/FC_final_Y2.mat"
        "${gen_dir}/Delta_FC.mat"
        "${gen_dir}/FC_final_Y0.mat"
        "${gen_dir}/Delta_FC.mat"
        "${gen_dir}/FC_final_Y0.mat"
        "${gen_dir}/FCY0_4min_subset.mat"
    )
    local outdirs=(
        "${LBC_rep_dir}/Results/KRR_results_generalize/FC_Y0"
        "${LBC_rep_dir}/Results/KRR_results_generalize/FC_Y2"
        "${LBC_rep_dir}/Results/KRR_results_generalize/FC_DeltaCogY2"
        "${LBC_rep_dir}/Results/KRR_results_generalize/FC_Y0Y2"
        "${LBC_rep_dir}/Results/KRR_results_generalize/FC_DeltaCogDelta"
        "${LBC_rep_dir}/Results/KRR_results_generalize/FCY0_CogDelta"
        "${LBC_rep_dir}/Results/KRR_results_generalize/FCY04min_CogY2"
    )
    local subcsv_list=(
        "${gen_dir}/DemoCog_Y0_rep_sub.csv"
        "${gen_dir}/DemoCog_Y2_rep_sub.csv"
        "${gen_dir}/DemoCog_Y2_rep_sub.csv"
        "${gen_dir}/DemoCog_Y2_rep_sub.csv"
        "${gen_dir}/DemoCog_Delta_rep_sub.csv"
        "${gen_dir}/DemoCog_Delta_rep_sub.csv"
        "${gen_dir}/DemoCog_Y2_rep_sub.csv"
    )
    local covtxt_list=(
        "${LBC_rep_dir}/Data/CovName_Y0.txt"
        "${LBC_rep_dir}/Data/CovName_Y2.txt"
        "${LBC_rep_dir}/Data/CovName_FCdelta_CogY2.txt"
        "${LBC_rep_dir}/Data/CovName_FCY0_CogY2.txt"
        "${LBC_rep_dir}/Data/CovName_FCdelta_CogDelta.txt"
        "${LBC_rep_dir}/Data/CovName_FCY0_CogDelta.txt"
        "${LBC_rep_dir}/Data/CovName_FCY0_CogY2.txt"
    )
    local cov_types_list=(
        "continuous,categorical,continuous"
        "continuous,categorical,continuous"
        "continuous,continuous,categorical,continuous,continuous"
        "continuous,continuous,categorical,continuous"
        "continuous,continuous,categorical,continuous,continuous"
        "continuous,continuous,categorical,continuous"
        "continuous,continuous,categorical,continuous"
    )
    local keep_fsm_list=(1 0 0 0 0 0 0)

    for i in "${!feature_paths[@]}"; do
        submit_krr_job "${feature_paths[$i]}" "${outdirs[$i]}" "${subtxt}" \
            "${subcsv_list[$i]}" "${covtxt_list[$i]}" \
            "${cov_types_list[$i]}" "${keep_fsm_list[$i]}" "predictGen"
    done
}

##########################################################################
# Dispatch
##########################################################################
case ${mode} in
    main)       run_main ;;
    transfer)   run_transfer ;;
    sex)        run_sex ;;
    generalize) run_generalize ;;
    all)        run_main; run_transfer; run_sex; run_generalize ;;
    *)
        echo "Unknown mode: ${mode}"
        echo "Usage: bash $(basename $0) <main|transfer|sex|generalize|all>"
        exit 1 ;;
esac

echo "Done."
exit 0
