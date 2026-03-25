#!/bin/bash
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
#
# Combined wrapper for FC stability and change analyses.
# All steps submit cluster jobs via qsub with PBS afterok dependencies.
# MATLAB jobs include a random sleep (0-60s) to avoid simultaneous startup crashes.
# Input FC_Y0Y2_combat.csv is assumed to be already prepared under Data/.
#
# Usage:
#   ssh headnode
#   bash CBIG_LBC_step2_FC_change.sh --all        # one-click full pipeline
#   bash CBIG_LBC_step2_FC_change.sh --step1      # run individual step
#   ...

# -- Source config ----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config/CBIG_LBC_tested_config.sh"

# -- Environment ------------------------------------------------------------
if [ -z "${LBC_rep_dir}" ]; then
    echo "ERROR: LBC_rep_dir not set. Did you source config.sh?"; exit 1
fi
if [ -z "${CBIG_CODE_DIR}" ]; then
    echo "ERROR: CBIG_CODE_DIR not set. Did you source CBIG_LBC_tested_config.sh?"; exit 1
fi

export LBC_rep_dir
export CBIG_CODE_DIR

REPO_ROOT="${SCRIPT_DIR}/.."
STEP_DIR="${REPO_ROOT}/step2_FC_change/script"
LOG_DIR="${LBC_rep_dir}/logs"

mkdir -p "${LOG_DIR}"
mkdir -p "${LBC_rep_dir}/Results"

# -- All steps require head node --------------------------------------------
HEADNODE="headnode"
current_host=$(hostname -s)
if [ "${current_host}" != "${HEADNODE}" ]; then
    echo "ERROR: All steps must be run from the head node."
    echo "Please run: ssh ${HEADNODE}"
    echo "Then re-run: bash $(realpath $0) ${1}"
    exit 1
fi

if [ -z "${1}" ]; then
    echo 'Usage: bash CBIG_LBC_step2_FC_change.sh --stepN'
    echo '  --all         : Run full pipeline (assumes FC_Y0Y2_combat.csv exists under Data/)'
    echo '  --step1       : FC stability (cluster job)'
    echo '  --step2       : FC Cohens d (cluster job)'
    echo '  --step3       : FC stability sex-stratified (cluster job x2)'
    echo '  --step4       : FC change sex effect (cluster job x chunks)'
    echo '  --step4-merge : Merge Step 4 chunks (cluster job)'
    echo '  --step5       : Individual FC change (cluster job x batches)'
    echo '  --step6       : FC change std (cluster job)'
    exit 0
fi

# ---------------------------------------------------------------------------
# Helper: wrap a matlab command with a random sleep to stagger startup
# ---------------------------------------------------------------------------
matlab_cmd() {
    local mf="$1"
    local delay=$((RANDOM % 60))
    echo "sleep ${delay} && matlab -nodisplay -nosplash -r "\
"\"addpath(genpath('${STEP_DIR}')); "\
"addpath(genpath('${REPO_ROOT}/util')); ${mf} exit;\""
}

# ---------------------------------------------------------------------------
# Helper: submit a job via qsub with optional PBS afterok dependency.
# Args: <name> <walltime> <mem> <hold_ids> <cmd>
#   hold_ids: colon-separated numeric PBS job IDs, or "" for no dependency
# Sets LAST_JOB_ID to the numeric job ID of the submitted job.
# ---------------------------------------------------------------------------
submit_job() {
    local name="$1"
    local walltime="$2"
    local mem="$3"
    local hold="$4"
    local cmd="$5"

    local depend_flag=""
    if [ -n "${hold}" ]; then
        depend_flag="-W depend=afterok:${hold}"
    fi

    local job_id
    job_id=$(echo "$cmd" | qsub \
        -N  "$name" \
        -l  "walltime=${walltime},mem=${mem},nodes=1:ppn=1" \
        -V \
        -m  ae \
        -e  "${LOG_DIR}/${name}_err.txt" \
        -o  "${LOG_DIR}/${name}_out.txt" \
        ${depend_flag})

    if [ $? -ne 0 ] || [ -z "$job_id" ]; then
        echo "ERROR: Job submission failed for ${name}."; exit 1
    fi
    job_id="${job_id%%.*}"
    echo "Submitted job: ${name} [ID: ${job_id}]"
    LAST_JOB_ID="${job_id}"
}

# ---------------------------------------------------------------------------
# Step submission functions  each accepts an optional hold_ids argument.
# ---------------------------------------------------------------------------

submit_step1() {
    local hold="${1:-}"
    local mf="CBIG_LBC_compute_FC_stability("
    mf="${mf}'${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv', "
    mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Y0.csv', "
    mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Y2.csv', "
    mf="${mf}'${LBC_rep_dir}/Results/FC_stability.mat');"
    submit_job "FC_stability" "24:00:00" "128G" "${hold}" "$(matlab_cmd "$mf")"
}

submit_step2() {
    local hold="${1:-}"
    local mf="CBIG_LBC_compute_FC_Cohen_d("
    mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Y0.csv', "
    mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Y2.csv', "
    mf="${mf}'${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv', "
    mf="${mf}'${LBC_rep_dir}/Results/FC_Cohen_d.mat');"
    submit_job "FC_Cohen_d" "24:00:00" "128G" "${hold}" "$(matlab_cmd "$mf")"
}

submit_step3() {
    local hold="${1:-}"
    for sex in F M; do
        local mf="CBIG_LBC_compute_FC_stability_sex_stratify("
        mf="${mf}'${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv', "
        mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Y0.csv', "
        mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Y2.csv', "
        mf="${mf}'${sex}', "
        mf="${mf}'${LBC_rep_dir}/Results/FC_stability_${sex}.mat');"
        submit_job "FC_stability_${sex}" "24:00:00" "128G" "${hold}" "$(matlab_cmd "$mf")"
    done
}

submit_step4() {
    local hold="${1:-}"
    mkdir -p "${LBC_rep_dir}/Results/FC_sex_effect_chunks"
    local total_edges=87571 chunk_size=5000 start=1
    STEP4_JOB_IDS=""

    while [ $start -le $total_edges ]; do
        local end=$(( start + chunk_size - 1 ))
        [ $end -gt $total_edges ] && end=$total_edges
        local chunk_save="${LBC_rep_dir}/Results/FC_sex_effect_chunks/FC_sex_effect_${start}_${end}.mat"
        local mf="CBIG_LBC_compute_FC_change_sex_effect("
        mf="${mf}${start}, ${end}, "
        mf="${mf}'${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv', "
        mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Y0.csv', "
        mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Y2.csv', "
        mf="${mf}'${chunk_save}');"
        submit_job "FC_sex_${start}_${end}" "24:00:00" "32G" "${hold}" "$(matlab_cmd "$mf")"
        STEP4_JOB_IDS="${STEP4_JOB_IDS:+${STEP4_JOB_IDS}:}${LAST_JOB_ID}"
        start=$(( end + 1 ))
    done
}

submit_step4_merge() {
    local hold="${1:-}"
    local chunk_dir="${LBC_rep_dir}/Results/FC_sex_effect_chunks"
    local mf="\
        chunk_dir = '${chunk_dir}'; \
        save_path = '${LBC_rep_dir}/Results/FC_sex_effect.mat'; \
        files = dir(fullfile(chunk_dir, 'FC_sex_effect_*.mat')); \
        starts = zeros(length(files), 1); \
        for i = 1:length(files); \
            tok = regexp(files(i).name, 'FC_sex_effect_(\d+)_\d+\.mat', 'tokens'); \
            starts(i) = str2double(tok{1}{1}); \
        end; \
        [~, idx] = sort(starts); files = files(idx); \
        t_all = []; p_all = []; b_all = []; \
        for i = 1:length(files); \
            chunk = load(fullfile(chunk_dir, files(i).name)); \
            t_all = [t_all, chunk.t]; \
            p_all = [p_all, chunk.p]; \
            b_all = [b_all, chunk.b]; \
        end; \
        fdr_index = CBIG_LBC_run_FDR(0.05, p_all(1,:), p_all(2,:), p_all(3,:)); \
        t = t_all; p = p_all; b = b_all; \
        save(save_path, 't', 'p', 'b', 'fdr_index', '-v7.3'); \
        fprintf('Merged %d chunks. Saved to: %s\n', length(files), save_path);"
    submit_job "FC_sex_effect_merge" "6:00:00" "64G" "${hold}" "$(matlab_cmd "$mf")"
}

submit_step5() {
    local hold="${1:-}"
    local SUB_TXT="${LBC_rep_dir}/Data/SubID_final.txt"
    if [ ! -f "${SUB_TXT}" ]; then
        echo "ERROR: Subject list not found: ${SUB_TXT}"; exit 1
    fi

    local batch_size=100 batch_num=0 batch_subs="" n_jobs=0
    STEP5_JOB_IDS=""

    _submit_batch() {
        batch_num=$(( batch_num + 1 ))
        local mf="subs = strsplit('${batch_subs}'); "
        mf="${mf}subs = strrep(subs, 'NDAR_', 'NDAR'); "
        mf="${mf}for i = 1:length(subs); "
        mf="${mf}CBIG_LBC_compute_FC_change(subs{i}, "
        mf="${mf}'${REPO_ROOT}', '${LBC_rep_dir}', '${ABCD_preprocessed}'); end;"
        submit_job "FC_change_batch${batch_num}" "24:00:00" "32G" "${hold}" "$(matlab_cmd "$mf")"
        STEP5_JOB_IDS="${STEP5_JOB_IDS:+${STEP5_JOB_IDS}:}${LAST_JOB_ID}"
        n_jobs=$(( n_jobs + 1 ))
        batch_subs=""
    }

    while IFS= read -r subname || [ -n "${subname}" ]; do
        [ -z "${subname}" ] && continue
        batch_subs="${batch_subs:+${batch_subs} }${subname}"
        [ "$(echo "${batch_subs}" | wc -w)" -ge "${batch_size}" ] && _submit_batch
    done < "${SUB_TXT}"
    [ -n "${batch_subs}" ] && _submit_batch

    echo "Submitted ${n_jobs} batch jobs for Step 5."
}

submit_step6() {
    local hold="${1:-}"
    local mf="CBIG_LBC_compute_FC_change_std("
    mf="${mf}'${REPO_ROOT}', '${LBC_rep_dir}', "
    mf="${mf}'${LBC_rep_dir}/Data/DemoCog_Delta.csv', "
    mf="${mf}'${LBC_rep_dir}/Results/FCChange_resid.mat', "
    mf="${mf}'${LBC_rep_dir}/Results/FC_diff_Std.mat');"
    submit_job "FC_change_std" "12:00:00" "128G" "${hold}" "$(matlab_cmd "$mf")"
}

# ---------------------------------------------------------------------------
# --all: submit full pipeline with job dependencies
# ---------------------------------------------------------------------------
if [ "${1}" == "--all" ]; then
    echo "=========================================="
    echo "Submitting full pipeline"
    echo "Started: $(date)"
    echo "=========================================="

    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    if [ ! -f "${FC_COMBAT}" ]; then
        echo "ERROR: ${FC_COMBAT} not found. Please prepare it manually first."
        exit 1
    fi

    submit_step1 ""
    submit_step2 ""
    submit_step3 ""
    submit_step4 ""
    submit_step4_merge "${STEP4_JOB_IDS}"
    submit_step5 ""
    submit_step6 "${STEP5_JOB_IDS}"

    echo ""
    echo "=========================================="
    echo "All jobs submitted. Monitor with: qstat"
    echo "Logs: ${LOG_DIR}/"
    echo "=========================================="

# ---------------------------------------------------------------------------
# Individual steps (no dependency, run immediately)
# ---------------------------------------------------------------------------
elif [ "${1}" == "--step1" ]; then
    echo "Step 1: FC stability"
    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    [ ! -f "${FC_COMBAT}" ] && echo "ERROR: ${FC_COMBAT} not found." && exit 1
    submit_step1 ""
    echo "Logs: ${LOG_DIR}/FC_stability_out.txt"

elif [ "${1}" == "--step2" ]; then
    echo "Step 2: FC Cohen's d"
    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    [ ! -f "${FC_COMBAT}" ] && echo "ERROR: ${FC_COMBAT} not found." && exit 1
    submit_step2 ""
    echo "Logs: ${LOG_DIR}/FC_Cohen_d_out.txt"

elif [ "${1}" == "--step3" ]; then
    echo "Step 3: FC stability sex-stratified"
    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    [ ! -f "${FC_COMBAT}" ] && echo "ERROR: ${FC_COMBAT} not found." && exit 1
    submit_step3 ""
    echo "Logs: ${LOG_DIR}/FC_stability_F_out.txt / FC_stability_M_out.txt"

elif [ "${1}" == "--step4" ]; then
    echo "Step 4: FC change sex effect (chunked)"
    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    [ ! -f "${FC_COMBAT}" ] && echo "ERROR: ${FC_COMBAT} not found." && exit 1
    submit_step4 ""
    echo "Logs: ${LOG_DIR}/FC_sex_*_out.txt"

elif [ "${1}" == "--step4-merge" ]; then
    echo "Step 4-merge: Merging FC sex effect chunks"
    CHUNK_DIR="${LBC_rep_dir}/Results/FC_sex_effect_chunks"
    [ ! -d "${CHUNK_DIR}" ] && echo "ERROR: ${CHUNK_DIR} not found. Has Step 4 run?" && exit 1
    n_chunks=$(ls "${CHUNK_DIR}"/FC_sex_effect_*.mat 2>/dev/null | wc -l)
    [ "${n_chunks}" -eq 0 ] && echo "ERROR: No chunk .mat files found in ${CHUNK_DIR}" && exit 1
    echo "Found ${n_chunks} chunk files."
    submit_step4_merge ""
    echo "Logs: ${LOG_DIR}/FC_sex_effect_merge_out.txt"

elif [ "${1}" == "--step5" ]; then
    echo "Step 5: Individual FC change (batched)"
    submit_step5 ""
    echo "Logs: ${LOG_DIR}/FC_change_batch*_out.txt"

elif [ "${1}" == "--step6" ]; then
    echo "Step 6: FC change std"
    [ -z "$(ls ${LBC_rep_dir}/FC_change/*/FC_diff.mat 2>/dev/null | head -1)" ] && \
        echo "ERROR: No FC_diff.mat found. Has Step 5 finished?" && exit 1
    submit_step6 ""
    echo "Logs: ${LOG_DIR}/FC_change_std_out.txt"

else
    echo "ERROR: Unknown flag: ${1}"
    echo "Run without arguments to see usage."
    exit 1
fi

exit 0
