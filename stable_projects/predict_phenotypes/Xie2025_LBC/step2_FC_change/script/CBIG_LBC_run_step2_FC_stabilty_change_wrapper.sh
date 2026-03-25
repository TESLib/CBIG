#!/bin/bash
# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
#
# Combined wrapper for FC harmonization and stability:
#   Step 1: Prepare FC_Y0Y2.csv                  (MATLAB, inline)
#   Step 2: Run longCombat on FC_Y0Y2.csv         (R,      cluster job)
#   Step 3: Compute FC stability                  (MATLAB, cluster job)
#   Step 4: Compute FC Cohen's d                  (MATLAB, cluster job)
#   Step 5: Compute FC stability sex-stratified   (MATLAB, cluster job x2)
#   Step 6: Compute FC change sex effect          (MATLAB, cluster job x chunks)
#   Step 6-merge: Merge Step 6 chunk results      (MATLAB, inline)
#   Step 7: Compute individual FC change          (MATLAB, cluster job x batches)
#   Step 8: Compute FC change std and residuals   (MATLAB, cluster job)
#
# Usage:
#   source config.sh && source CBIG_LBC_tested_config.sh
#   bash CBIG_LBC_step2_FC_change.sh --step1       # run Step 1 only (compiler ok)
#   bash CBIG_LBC_step2_FC_change.sh --step2       # run Step 2 only (head node)
#   bash CBIG_LBC_step2_FC_change.sh --step3       # after Step 2 completes
#   bash CBIG_LBC_step2_FC_change.sh --step4       # after Step 2 completes
#   bash CBIG_LBC_step2_FC_change.sh --step5       # after Step 2 completes
#   bash CBIG_LBC_step2_FC_change.sh --step6       # after Step 2 completes
#   bash CBIG_LBC_step2_FC_change.sh --step6-merge # after Step 6 completes
#   bash CBIG_LBC_step2_FC_change.sh --step7       # no dependency on Steps 3-6
#   bash CBIG_LBC_step2_FC_change.sh --step8       # after Step 7 completes

# -- Source config ----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../replication/config/CBIG_LBC_tested_config.sh"

# -- Environment ------------------------------------------------------------
if [ -z "${LBC_rep_dir}" ]; then
    echo "ERROR: LBC_rep_dir not set. Did you source config.sh?"
    exit 1
fi
if [ -z "${CBIG_CODE_DIR}" ]; then
    echo "ERROR: CBIG_CODE_DIR not set. Did you source CBIG_LBC_tested_config.sh?"
    exit 1
fi

export LBC_rep_dir
export CBIG_CODE_DIR

REPO_ROOT="${CBIG_CODE_DIR}/stable_projects/predict_phenotypes/Xie2025_LBC"
STEP_DIR="${REPO_ROOT}/step2_FC_change/script"
LOG_DIR="${LBC_rep_dir}/logs"
ABCD_PREPROCESSED="${LBC_rep_dir}/ABCD_preprocessed"   # adjust if path differs
mkdir -p "${LOG_DIR}"
mkdir -p "${LBC_rep_dir}/Results"
# Steps that submit cluster jobs must be run from the head node.
# If you are on a compute node or compiler, please run: ssh headnode
HEADNODE="headnode"   # adjust to your actual head node hostname

if [ -z "${1}" ]; then
    echo 'Usage: bash CBIG_LBC_run_step2_FC_stabilty_change_wrapper.sh --stepN'
    echo '  --step1       : Prepare FC_Y0Y2.csv (compiler ok)'
    echo '  --step2       : Run longCombat (head node required)'
    echo '  --step3       : FC stability (head node required)'
    echo '  --step4       : FC Cohens d (head node required)'
    echo '  --step5       : FC stability sex-stratified (head node required)'
    echo '  --step6       : FC change sex effect (head node required)'
    echo '  --step6-merge : Merge Step 6 chunks (compiler ok)'
    echo '  --step7       : Individual FC change (head node required)'
    echo '  --step8       : FC change std (head node required)'
    exit 0
fi

mkdir -p "${LOG_DIR}"
mkdir -p "${LBC_rep_dir}/Results"
for flag in --step2 --step3 --step4 --step5 --step6 --step7 --step8; do
    if [ "${1}" == "${flag}" ] || [ -z "${1}" ]; then
        requires_submission=true
        break
    fi
done

if [ "${requires_submission}" == "true" ]; then
    current_host=$(hostname -s)
    if [ "${current_host}" != "${HEADNODE}" ]; then
        echo "ERROR: Job submission must be run from the head node."
        echo "Please run: ssh ${HEADNODE}"
        echo "Then re-run: bash $(realpath $0) ${1}"
        exit 1
    fi
fi

# -- Step 1: Prepare FC_Y0Y2.csv (MATLAB, inline) --------------------------
if [ "${1}" == "--step1" ] || \
   ([ "${1}" != "--step3" ] && [ "${1}" != "--step4" ] && \
   [ "${1}" != "--step5" ] && [ "${1}" != "--step6" ] && \
   [ "${1}" != "--step6-merge" ] && [ "${1}" != "--step7" ] && \
   [ "${1}" != "--step8" ]); then
    echo "=========================================="
    echo "Step 1: Preparing FC_Y0Y2.csv"
    echo "Started: $(date)"
    echo "=========================================="

    matlab -nodisplay -nosplash -r \
        "addpath(genpath('${STEP_DIR}')); \
         CBIG_LBC_prepare_FC_LongCombatTable('${LBC_rep_dir}'); exit;" \
        2>&1 | tee "${LOG_DIR}/prepare_FC_LongCombatTable.log"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "ERROR: Step 1 failed."
        echo "Check ${LOG_DIR}/prepare_FC_LongCombatTable.log"
        exit 1
    fi

    FC_CSV="${LBC_rep_dir}/Data/FC_Y0Y2.csv"
    if [ ! -f "${FC_CSV}" ]; then
        echo "ERROR: Expected output not found: ${FC_CSV}"
        exit 1
    fi
    echo "Step 1 complete: ${FC_CSV}"

    # If --step1 only, stop here
    if [ "${1}" == "--step1" ]; then
        echo "Step 1 complete. Run Step 2 from head node:"
        echo "  ssh headnode"
        echo "  bash CBIG_LBC_run_step2_FC_stabilty_change.sh --step2"
        exit 0
    fi

# -- Step 2: Run longCombat FC (R, cluster job) -----------------------------
    echo ""
    echo "=========================================="
    echo "Step 2: Submitting longCombat FC job"
    echo "Started: $(date)"
    echo "=========================================="

    combat_cmd="Rscript ${STEP_DIR}/CBIG_LBC_longComBat_FC_wrapper.R"

    $CBIG_CODE_DIR/setup/CBIG_pbsubmit \
        -cmd  "$combat_cmd" \
        -walltime 24:00:00 \
        -mem  64G \
        -name longCombat_FC \
        -ncpus 1 \
        -joberr "${LOG_DIR}/longCombat_FC_err.txt" \
        -jobout "${LOG_DIR}/longCombat_FC_out.txt"

    if [ $? -ne 0 ]; then
        echo "ERROR: Step 2 job submission failed."
        exit 1
    fi

    echo "Step 2 job submitted. Monitor with: qstat"
    echo "Logs: ${LOG_DIR}/longCombat_FC_out.txt / longCombat_FC_err.txt"
    echo ""
    echo "When Step 2 is done, run Steps 3-6 (independent of each other):"
    echo "  bash CBIG_LBC_step2_FC_change.sh --step3"
    echo "  bash CBIG_LBC_step2_FC_change.sh --step4"
    echo "  bash CBIG_LBC_step2_FC_change.sh --step5"
    echo "  bash CBIG_LBC_step2_FC_change.sh --step6"

# -- Step 3: FC stability (MATLAB, cluster job) -----------------------------
elif [ "${1}" == "--step3" ]; then
    echo "=========================================="
    echo "Step 3: Submitting FC stability job"
    echo "Started: $(date)"
    echo "=========================================="

    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    if [ ! -f "${FC_COMBAT}" ]; then
        echo "ERROR: Combat output not found: ${FC_COMBAT}"
        echo "Has the longCombat job (Step 2) finished?"
        exit 1
    fi

    matlab_func="CBIG_LBC_compute_FC_stability("
    matlab_func="${matlab_func}'${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_Y0.csv', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_Y2.csv', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Results/FC_stability.mat');"

    stability_cmd="matlab -nodisplay -nosplash -r \"addpath(genpath('${STEP_DIR}')); ${matlab_func} exit;\""

    $CBIG_CODE_DIR/setup/CBIG_pbsubmit \
        -cmd  "$stability_cmd" \
        -walltime 24:00:00 \
        -mem  128G \
        -name FC_stability \
        -ncpus 1 \
        -joberr "${LOG_DIR}/FC_stability_err.txt" \
        -jobout "${LOG_DIR}/FC_stability_out.txt"

    if [ $? -ne 0 ]; then
        echo "ERROR: Step 3 job submission failed."
        exit 1
    fi

    echo "Step 3 job submitted. Monitor with: qstat"
    echo "Logs: ${LOG_DIR}/FC_stability_out.txt / FC_stability_err.txt"

# -- Step 4: FC Cohen's d (MATLAB, cluster job) -----------------------------
elif [ "${1}" == "--step4" ]; then
    echo "=========================================="
    echo "Step 4: Submitting FC Cohen's d job"
    echo "Started: $(date)"
    echo "=========================================="

    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    if [ ! -f "${FC_COMBAT}" ]; then
        echo "ERROR: Combat output not found: ${FC_COMBAT}"
        echo "Has the longCombat job (Step 2) finished?"
        exit 1
    fi

    matlab_func="CBIG_LBC_compute_FC_Cohen_d("
    matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_Y0.csv', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_Y2.csv', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Results/FC_Cohen_d.mat');"

    cohend_cmd="matlab -nodisplay -nosplash -r \"addpath(genpath('${STEP_DIR}')); ${matlab_func} exit;\""

    $CBIG_CODE_DIR/setup/CBIG_pbsubmit \
        -cmd  "$cohend_cmd" \
        -walltime 24:00:00 \
        -mem  128G \
        -name FC_Cohen_d \
        -ncpus 1 \
        -joberr "${LOG_DIR}/FC_Cohen_d_err.txt" \
        -jobout "${LOG_DIR}/FC_Cohen_d_out.txt"

    if [ $? -ne 0 ]; then
        echo "ERROR: Step 4 job submission failed."
        exit 1
    fi

    echo "Step 4 job submitted. Monitor with: qstat"
    echo "Logs: ${LOG_DIR}/FC_Cohen_d_out.txt / FC_Cohen_d_err.txt"

# -- Step 5: FC stability sex-stratified (MATLAB, cluster job x2) -----------
elif [ "${1}" == "--step5" ]; then
    echo "=========================================="
    echo "Step 5: Submitting FC stability sex-stratified jobs (F and M)"
    echo "Started: $(date)"
    echo "=========================================="

    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    if [ ! -f "${FC_COMBAT}" ]; then
        echo "ERROR: Combat output not found: ${FC_COMBAT}"
        echo "Has the longCombat job (Step 2) finished?"
        exit 1
    fi

    for sex in F M; do
        matlab_func="CBIG_LBC_compute_FC_stability_sex_stratify("
        matlab_func="${matlab_func}'${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv', "
        matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_Y0.csv', "
        matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_Y2.csv', "
        matlab_func="${matlab_func}'${sex}', "
        matlab_func="${matlab_func}'${LBC_rep_dir}/Results/FC_stability_${sex}.mat');"

        stability_sex_cmd="matlab -nodisplay -nosplash -r \"addpath(genpath('${STEP_DIR}')); ${matlab_func} exit;\""

        $CBIG_CODE_DIR/setup/CBIG_pbsubmit \
            -cmd  "$stability_sex_cmd" \
            -walltime 24:00:00 \
            -mem  128G \
            -name FC_stability_${sex} \
            -ncpus 1 \
            -joberr "${LOG_DIR}/FC_stability_${sex}_err.txt" \
            -jobout "${LOG_DIR}/FC_stability_${sex}_out.txt"

        if [ $? -ne 0 ]; then
            echo "ERROR: Step 5 job submission failed for sex=${sex}."
            exit 1
        fi
        echo "Submitted FC stability job for sex=${sex}"
    done

    echo "Step 5 jobs submitted. Monitor with: qstat"
    echo "Logs: ${LOG_DIR}/FC_stability_F_out.txt / FC_stability_M_out.txt"

# -- Step 6: FC change sex effect (MATLAB, cluster job x chunks) ------------
elif [ "${1}" == "--step6" ]; then
    echo "=========================================="
    echo "Step 6: Submitting FC change sex effect jobs (chunked)"
    echo "Started: $(date)"
    echo "=========================================="

    FC_COMBAT="${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv"
    if [ ! -f "${FC_COMBAT}" ]; then
        echo "ERROR: Combat output not found: ${FC_COMBAT}"
        echo "Has the longCombat job (Step 2) finished?"
        exit 1
    fi

    mkdir -p "${LBC_rep_dir}/Results/FC_sex_effect_chunks"

    total_edges=87571
    chunk_size=5000
    start=1

    while [ $start -le $total_edges ]; do
        end=$(( start + chunk_size - 1 ))
        if [ $end -gt $total_edges ]; then
            end=$total_edges
        fi

        chunk_save="${LBC_rep_dir}/Results/FC_sex_effect_chunks"
        chunk_save="${chunk_save}/FC_sex_effect_${start}_${end}.mat"

        matlab_func="CBIG_LBC_compute_FC_change_sex_effect("
        matlab_func="${matlab_func}${start}, ${end}, "
        matlab_func="${matlab_func}'${LBC_rep_dir}/Data/FC_Y0Y2_combat.csv', "
        matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_Y0.csv', "
        matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_Y2.csv', "
        matlab_func="${matlab_func}'${chunk_save}');"

        sex_effect_cmd="matlab -nodisplay -nosplash -r \"addpath(genpath('${STEP_DIR}')); ${matlab_func} exit;\""

        $CBIG_CODE_DIR/setup/CBIG_pbsubmit \
            -cmd  "$sex_effect_cmd" \
            -walltime 24:00:00 \
            -mem  32G \
            -name FC_sex_${start}_${end} \
            -ncpus 1 \
            -joberr "${LOG_DIR}/FC_sex_effect_${start}_${end}_err.txt" \
            -jobout "${LOG_DIR}/FC_sex_effect_${start}_${end}_out.txt"

        if [ $? -ne 0 ]; then
            echo "ERROR: Step 6 submission failed for chunk ${start}-${end}."
            exit 1
        fi
        echo "Submitted chunk: edges ${start} to ${end}"

        start=$(( end + 1 ))
    done

    echo ""
    echo "All Step 6 chunks submitted. Monitor with: qstat"
    echo "Results: ${LBC_rep_dir}/Results/FC_sex_effect_chunks/"
    echo ""
    echo "When all Step 6 jobs are done, run:"
    echo "  bash CBIG_LBC_step2_FC_change.sh --step6-merge"

# -- Step 6-merge: Merge sex effect chunks (MATLAB, inline) -----------------
elif [ "${1}" == "--step6-merge" ]; then
    echo "=========================================="
    echo "Step 6-merge: Merging FC sex effect chunks"
    echo "Started: $(date)"
    echo "=========================================="

    CHUNK_DIR="${LBC_rep_dir}/Results/FC_sex_effect_chunks"
    if [ ! -d "${CHUNK_DIR}" ]; then
        echo "ERROR: Chunk directory not found: ${CHUNK_DIR}"
        echo "Has Step 6 been run?"
        exit 1
    fi

    n_chunks=$(ls "${CHUNK_DIR}"/FC_sex_effect_*.mat 2>/dev/null | wc -l)
    if [ "${n_chunks}" -eq 0 ]; then
        echo "ERROR: No chunk .mat files found in ${CHUNK_DIR}"
        exit 1
    fi
    echo "Found ${n_chunks} chunk files. Merging..."

    matlab -nodisplay -nosplash -r "
        chunk_dir = '${CHUNK_DIR}';
        save_path = '${LBC_rep_dir}/Results/FC_sex_effect.mat';
        files = dir(fullfile(chunk_dir, 'FC_sex_effect_*.mat'));
        starts = zeros(length(files), 1);
        for i = 1:length(files)
            tok = regexp(files(i).name, 'FC_sex_effect_(\d+)_\d+\.mat', 'tokens');
            starts(i) = str2double(tok{1}{1});
        end
        [~, idx] = sort(starts);
        files = files(idx);
        t_all = []; p_all = []; b_all = [];
        for i = 1:length(files)
            chunk = load(fullfile(chunk_dir, files(i).name));
            t_all = [t_all, chunk.t];
            p_all = [p_all, chunk.p];
            b_all = [b_all, chunk.b];
        end
        fdr_index = CBIG_LBC_run_FDR(0.05, p_all(1,:), p_all(2,:), p_all(3,:));
        t = t_all; p = p_all; b = b_all;
        save(save_path, 't', 'p', 'b', 'fdr_index', '-v7.3');
        fprintf('Merged %d chunks. Saved to: %s\n', length(files), save_path);
    " 2>&1 | tee "${LOG_DIR}/FC_sex_effect_merge.log"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "ERROR: Merge failed. Check ${LOG_DIR}/FC_sex_effect_merge.log"
        exit 1
    fi
    echo "Step 6-merge complete."
    echo "Result: ${LBC_rep_dir}/Results/FC_sex_effect.mat"

# -- Step 7: Individual FC change (MATLAB, cluster job x batches) -----------
elif [ "${1}" == "--step7" ]; then
    echo "=========================================="
    echo "Step 7: Submitting individual FC change jobs (batched)"
    echo "Started: $(date)"
    echo "=========================================="

    SUB_TXT="${LBC_rep_dir}/Data/SubID_final.txt"
    if [ ! -f "${SUB_TXT}" ]; then
        echo "ERROR: Subject list not found: ${SUB_TXT}"
        exit 1
    fi

    batch_size=100
    batch_num=0
    batch_subs=""
    n_jobs=0

    while IFS= read -r subname || [ -n "${subname}" ]; do
        [ -z "${subname}" ] && continue

        if [ -z "${batch_subs}" ]; then
            batch_subs="${subname}"
        else
            batch_subs="${batch_subs} ${subname}"
        fi

        n_in_batch=$(echo "${batch_subs}" | wc -w)

        if [ "${n_in_batch}" -ge "${batch_size}" ]; then
            batch_num=$(( batch_num + 1 ))

            matlab_func="subs = strsplit('${batch_subs}'); "
            matlab_func="${matlab_func}subs = strrep(subs, 'NDAR_', 'NDAR'); "
            matlab_func="${matlab_func}for i = 1:length(subs); "
            matlab_func="${matlab_func}CBIG_LBC_compute_FC_change(subs{i}, "
            matlab_func="${matlab_func}'${REPO_ROOT}', "
            matlab_func="${matlab_func}'${LBC_rep_dir}', "
            matlab_func="${matlab_func}'${ABCD_PREPROCESSED}'); end;"

            fc_change_cmd="matlab -nodisplay -nosplash -r \"addpath(genpath('${STEP_DIR}')); ${matlab_func} exit;\""

            $CBIG_CODE_DIR/setup/CBIG_pbsubmit \
                -cmd  "$fc_change_cmd" \
                -walltime 24:00:00 \
                -mem  32G \
                -name FC_change_batch${batch_num} \
                -ncpus 1 \
                -joberr "${LOG_DIR}/FC_change_batch${batch_num}_err.txt" \
                -jobout "${LOG_DIR}/FC_change_batch${batch_num}_out.txt"

            if [ $? -ne 0 ]; then
                echo "ERROR: Job submission failed for batch ${batch_num}."
                exit 1
            fi

            echo "Submitted batch ${batch_num} (${n_in_batch} subjects)"
            n_jobs=$(( n_jobs + 1 ))
            batch_subs=""
        fi
    done < "${SUB_TXT}"

    # Submit remaining subjects in last partial batch
    if [ -n "${batch_subs}" ]; then
        batch_num=$(( batch_num + 1 ))

        matlab_func="subs = strsplit('${batch_subs}'); "
        matlab_func="${matlab_func}subs = strrep(subs, 'NDAR_', 'NDAR'); "
        matlab_func="${matlab_func}for i = 1:length(subs); "
        matlab_func="${matlab_func}CBIG_LBC_compute_FC_change(subs{i}, "
        matlab_func="${matlab_func}'${REPO_ROOT}', "
        matlab_func="${matlab_func}'${LBC_rep_dir}', "
        matlab_func="${matlab_func}'${ABCD_PREPROCESSED}'); end;"

        fc_change_cmd="matlab -nodisplay -nosplash -r \"addpath(genpath('${STEP_DIR}')); ${matlab_func} exit;\""

        $CBIG_CODE_DIR/setup/CBIG_pbsubmit \
            -cmd  "$fc_change_cmd" \
            -walltime 24:00:00 \
            -mem  32G \
            -name FC_change_batch${batch_num} \
            -ncpus 1 \
            -joberr "${LOG_DIR}/FC_change_batch${batch_num}_err.txt" \
            -jobout "${LOG_DIR}/FC_change_batch${batch_num}_out.txt"

        if [ $? -ne 0 ]; then
            echo "ERROR: Job submission failed for final batch ${batch_num}."
            exit 1
        fi

        echo "Submitted final batch ${batch_num}"
        n_jobs=$(( n_jobs + 1 ))
    fi

    echo ""
    echo "Submitted ${n_jobs} batch jobs (${batch_size} subjects/batch)."
    echo "Logs: ${LOG_DIR}/FC_change_batch*"
    echo ""
    echo "When all Step 7 jobs are done, run Step 8:"
    echo "  bash CBIG_LBC_step2_FC_change.sh --step8"

# -- Step 8: FC change std and residuals (MATLAB, cluster job) --------------
elif [ "${1}" == "--step8" ]; then
    echo "=========================================="
    echo "Step 8: Submitting FC change std job"
    echo "Started: $(date)"
    echo "=========================================="

    if [ -z "$(ls ${LBC_rep_dir}/FC_change/*/FC_diff.mat 2>/dev/null | head -1)" ]; then
        echo "ERROR: No FC_diff.mat files found in ${LBC_rep_dir}/FC_change/"
        echo "Has Step 7 finished?"
        exit 1
    fi

    matlab_func="CBIG_LBC_compute_FC_change_std("
    matlab_func="${matlab_func}'${REPO_ROOT}', "
    matlab_func="${matlab_func}'${LBC_rep_dir}', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Data/DemoCog_change.csv', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Results/FCChange_resid.mat', "
    matlab_func="${matlab_func}'${LBC_rep_dir}/Results/FC_diff_Std.mat');"

    fc_std_cmd="matlab -nodisplay -nosplash -r \"addpath(genpath('${STEP_DIR}')); ${matlab_func} exit;\""

    $CBIG_CODE_DIR/setup/CBIG_pbsubmit \
        -cmd  "$fc_std_cmd" \
        -walltime 12:00:00 \
        -mem  128G \
        -name FC_change_std \
        -ncpus 1 \
        -joberr "${LOG_DIR}/FC_change_std_err.txt" \
        -jobout "${LOG_DIR}/FC_change_std_out.txt"

    if [ $? -ne 0 ]; then
        echo "ERROR: Step 8 job submission failed."
        exit 1
    fi

    echo "Step 8 job submitted. Monitor with: qstat"
    echo "Logs: ${LOG_DIR}/FC_change_std_out.txt / FC_change_std_err.txt"
fi

exit 0
