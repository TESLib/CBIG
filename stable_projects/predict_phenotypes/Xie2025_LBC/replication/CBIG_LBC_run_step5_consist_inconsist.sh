#!/bin/bash
# Wrapper script for Step 5: PNF consistency/inconsistency analysis.
#
# Computes predictive network features (PNF) for two models:
#   Model 1: FC_Y0 -> CogY0
#   Model 2: FC_Delta -> CogDelta
# Then compares sign consistency across models.
# Network matrix plots can be generated locally without cluster submission.
#
# Steps:
#   step1 : PNF block for FC_Y0 -> CogY0      (model 1, measure index 2)
#   step2 : PNF block for FC_Delta -> CogDelta (model 2, measure index 2)
#   step3 : PNF sign consistency/inconsistency comparison (depends on step1+2)
#   --all : Submit full pipeline with PBS dependencies
#
# Usage:
#   bash CBIG_LBC_run_step5_consist_inconsist.sh --all
#   bash CBIG_LBC_run_step5_consist_inconsist.sh --step1
#   ...
#
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

# ---------------------------------------------------------------------------
# Load environment config
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config/CBIG_LBC_tested_config.sh"

if [ -z "${LBC_rep_dir}" ]; then
    echo "ERROR: LBC_rep_dir not set. Did you source config?"; exit 1
fi
if [ -z "${CBIG_CODE_DIR}" ]; then
    echo "ERROR: CBIG_CODE_DIR not set. Did you source CBIG_LBC_tested_config.sh?"; exit 1
fi

export LBC_rep_dir
export CBIG_CODE_DIR

REPO_ROOT="${SCRIPT_DIR}/.."
STEP_DIR="${REPO_ROOT}/step5_consist_inconsist_PNF/script"
LOG_DIR="${LBC_rep_dir}/logs"
PNF_DIR="${LBC_rep_dir}/Results/PNF"
KRR_DIR="${LBC_rep_dir}/Results/KRR_results"

mkdir -p "${LOG_DIR}"
mkdir -p "${PNF_DIR}/FC_Y0"
mkdir -p "${PNF_DIR}/FC_DeltaCogDelta"

# ---------------------------------------------------------------------------
# Input / output paths
# ---------------------------------------------------------------------------
# Model 1: FC_Y0 -> CogY0
cov_mat_model1="${KRR_DIR}/FC_Y0/interpretation/FC_final_Y0/cov_mat.mat"
pnf_standard_model1="${PNF_DIR}/FC_Y0/PNF_FCY0_CogY0_standard_M2.mat"
pnf_networkblock_model1="${PNF_DIR}/FC_Y0/PNF_FCY0_CogY0_NetworkBlock_M2.mat"

# Model 2: FC_Delta -> CogDelta
cov_mat_model2="${KRR_DIR}/FC_DeltaCogDelta/interpretation/Delta_FC/cov_mat.mat"
pnf_standard_model2="${PNF_DIR}/FC_DeltaCogDelta/PNF_FC_Delta_CogDelta_standard_M2.mat"
pnf_networkblock_model2="${PNF_DIR}/FC_DeltaCogDelta/PNF_FC_Delta_CogDelta_NetworkBlock_M2.mat"

# Compare output
compare_output="${PNF_DIR}/Compare_FCY0CogY0_FCdeltaCogDelta_PNFoverlap.mat"

# Measure index (LMT)
MEASURE_INDEX=2

# ---------------------------------------------------------------------------
# Cluster resource settings
# ---------------------------------------------------------------------------
walltime_pnf="4:00:00"
mem_pnf="32G"
walltime_compare="1:00:00"
mem_compare="16G"

# ---------------------------------------------------------------------------
# Helper: build a MATLAB command string with addpath and random sleep
# ---------------------------------------------------------------------------
matlab_cmd() {
    local mf="$1"
    local delay=$((RANDOM % 60))
    echo "sleep ${delay} && matlab -nodisplay -nosplash -r \"\
addpath(genpath('${STEP_DIR}')); \
addpath(genpath('${REPO_ROOT}/util')); \
${mf} exit;\""
}

# ---------------------------------------------------------------------------
# Helper: submit a PBS job with optional afterok dependency
#   Args: <name> <walltime> <mem> <hold_ids> <cmd>
#   Sets LAST_JOB_ID to the submitted numeric job ID
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
# Step submission functions
# ---------------------------------------------------------------------------

submit_step1() {
    local hold="${1:-}"
    local mf="CBIG_LBC_ABCD_PNF_block("
    mf="${mf}'${cov_mat_model1}', "
    mf="${mf}${MEASURE_INDEX}, "
    mf="${mf}'${pnf_standard_model1}', "
    mf="${mf}'${pnf_networkblock_model1}');"
    submit_job "PNF_block_model1" "${walltime_pnf}" "${mem_pnf}" "${hold}" "$(matlab_cmd "$mf")"
}

submit_step2() {
    local hold="${1:-}"
    local mf="CBIG_LBC_ABCD_PNF_block("
    mf="${mf}'${cov_mat_model2}', "
    mf="${mf}${MEASURE_INDEX}, "
    mf="${mf}'${pnf_standard_model2}', "
    mf="${mf}'${pnf_networkblock_model2}');"
    submit_job "PNF_block_model2" "${walltime_pnf}" "${mem_pnf}" "${hold}" "$(matlab_cmd "$mf")"
}

submit_step3() {
    local hold="${1:-}"
    local mf="CBIG_LBC_ABCD_PNF_compare("
    mf="${mf}'${pnf_networkblock_model1}', "
    mf="${mf}'${pnf_networkblock_model2}', "
    mf="${mf}'${pnf_standard_model1}', "
    mf="${mf}'${pnf_standard_model2}', "
    mf="${mf}'${compare_output}');"
    submit_job "PNF_compare" "${walltime_compare}" "${mem_compare}" "${hold}" "$(matlab_cmd "$mf")"
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
if [ -z "${1}" ]; then
    echo "Usage: bash CBIG_LBC_run_step5_consist_inconsist.sh --stepN"
    echo "  --all   : Submit full pipeline with PBS dependencies"
    echo "  --step1 : PNF block for FC_Y0 -> CogY0 (model 1)"
    echo "  --step2 : PNF block for FC_Delta -> CogDelta (model 2)"
    echo "  --step3 : PNF sign consistency comparison (requires step1+2 outputs)"
    exit 0
fi

# ---------------------------------------------------------------------------
# --all: submit full pipeline with job dependencies
# ---------------------------------------------------------------------------
if [ "${1}" == "--all" ]; then
    echo "=========================================="
    echo "Submitting Step 5 PNF pipeline"
    echo "Started: $(date)"
    echo "=========================================="

    # Validate inputs
    [ ! -f "${cov_mat_model1}" ] && echo "ERROR: ${cov_mat_model1} not found." && exit 1
    [ ! -f "${cov_mat_model2}" ] && echo "ERROR: ${cov_mat_model2} not found." && exit 1

    # Steps 1 and 2 are independent — submit in parallel
    submit_step1 ""
    JOB1="${LAST_JOB_ID}"
    submit_step2 ""
    JOB2="${LAST_JOB_ID}"

    # Step 3 depends on both step 1 and step 2
    submit_step3 "${JOB1}:${JOB2}"

    echo ""
    echo "=========================================="
    echo "All jobs submitted. Monitor with: qstat"
    echo "Output directory: ${PNF_DIR}"
    echo "Logs: ${LOG_DIR}/"
    echo "=========================================="

# ---------------------------------------------------------------------------
# Individual steps
# ---------------------------------------------------------------------------
elif [ "${1}" == "--step1" ]; then
    echo "Step 1: PNF block for FC_Y0 -> CogY0 (model 1)"
    [ ! -f "${cov_mat_model1}" ] && echo "ERROR: ${cov_mat_model1} not found." && exit 1
    submit_step1 ""
    echo "Logs: ${LOG_DIR}/PNF_block_model1_out.txt"

elif [ "${1}" == "--step2" ]; then
    echo "Step 2: PNF block for FC_Delta -> CogDelta (model 2)"
    [ ! -f "${cov_mat_model2}" ] && echo "ERROR: ${cov_mat_model2} not found." && exit 1
    submit_step2 ""
    echo "Logs: ${LOG_DIR}/PNF_block_model2_out.txt"

elif [ "${1}" == "--step3" ]; then
    echo "Step 3: PNF sign consistency comparison"
    [ ! -f "${pnf_networkblock_model1}" ] && \
        echo "ERROR: ${pnf_networkblock_model1} not found. Has step1 finished?" && exit 1
    [ ! -f "${pnf_networkblock_model2}" ] && \
        echo "ERROR: ${pnf_networkblock_model2} not found. Has step2 finished?" && exit 1
    submit_step3 ""
    echo "Logs: ${LOG_DIR}/PNF_compare_out.txt"

else
    echo "ERROR: Unknown flag: ${1}"
    echo "Run without arguments to see usage."
    exit 1
fi

exit 0
