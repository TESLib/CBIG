function CBIG_LBC_regress_covariates_Y2_wrapper(krr_y0_dir, subcsv_y2, subtxt, ...
    predvar, covtxt_y2, ymat_y0, covmat_y0, ymat_y2, covmat_y2, cov_types_y2, outstem, outdir)
% CBIG_LBC_regress_covariates_Y2_wrapper(krr_y0_dir, subcsv_y2, subtxt,
%     predvar, covtxt_y2, ymat_y0, covmat_y0, ymat_y2, covmat_y2, cov_types_y2, outstem, outdir)
%
% Wrapper for CBIG_LBC_crossvalid_regress_covariates_Y2. Loads Y0 behavioral
% and covariate matrices from an existing KRR output directory, generates Y2
% matrices from CSV, and regresses out covariates from Y2 data using
% regression coefficients learned from Y0 training folds.
%
% Input:
%     - krr_y0_dir: (string)
%           Full path to the Y0 KRR output directory. Must contain ymat_y0,
%           covmat_y0, and no_relative_3_fold_sub_list.mat.
%
%     - subcsv_y2: (string)
%           Full path to the CSV file containing Y2 behavioral and covariate data.
%
%     - subtxt: (string)
%           Full path to the subject ID list (one ID per line).
%
%     - predvar: (string)
%           Full path to a text file listing behavioral variable names (one per line).
%
%     - covtxt_y2: (string)
%           Full path to a text file listing Y2 covariate names (one per line).
%
%     - ymat_y0: (string)
%           Filename (not full path) of the Y0 behavioral .mat inside krr_y0_dir
%           (variable: 'y').
%
%     - covmat_y0: (string)
%           Filename (not full path) of the Y0 covariate .mat inside krr_y0_dir
%           (variable: 'covariates').
%
%     - ymat_y2: (string)
%           Output filename for the Y2 behavioral .mat (saved in outdir).
%
%     - covmat_y2: (string)
%           Output filename for the Y2 covariate .mat (saved in outdir).
%
%     - cov_types_y2: (cell array of strings)
%           Type of each Y2 covariate in covtxt_y2, in order.
%           Each entry must be 'continuous' or 'categorical'.
%
%     - outstem: (string)
%           String appended to output filenames (e.g. 'cognition8').
%
%     - outdir: (string)
%           Full path of output directory for Y2 regression results.
%
% Output:
%     - Per-fold residual .mat files saved under [outdir]/y/fold_N/.
%
% Example:
%     CBIG_LBC_regress_covariates_Y2_wrapper('/path/KRR_FC_Y0', 'demo_Y2.csv', ...
%         'sub_list.txt', 'predvar.txt', 'cov_Y2.txt', 'y.mat', 'cov.mat', ...
%         'y_Y2.mat', 'cov_Y2.mat', {'continuous','categorical'}, 'cognition8', '/path/out')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% add paths
script_dir = fileparts(mfilename('fullpath'));
addpath(script_dir);
repo_root = fileparts(fileparts(script_dir));
addpath(genpath(fullfile(repo_root, 'util', 'stats')));

%% load Y0 behavioral matrix
fprintf('[1] Loading Y0 behavioral matrix...\n');
y0_mat = load(fullfile(krr_y0_dir, ymat_y0));
y0_in = y0_mat.y;

%% load Y0 covariate matrix
fprintf('[2] Loading Y0 covariate matrix...\n');
cov0_mat = load(fullfile(krr_y0_dir, covmat_y0));
y0_regressors = cov0_mat.covariates;

%% load sub_fold
fprintf('[3] Loading cross-validation fold structure...\n');
fold_temp = load(fullfile(krr_y0_dir, 'no_relative_3_fold_sub_list.mat'));
sub_fold = fold_temp.sub_fold;

%% generate Y2 behavioral matrix
fprintf('[4] Generating Y2 behavioral matrix...\n');
mkdir(outdir);
if ~exist(fullfile(outdir, ymat_y2), 'file')
    fid = fopen(predvar, 'r');
    score_list = textscan(fid, '%s');
    score_names = score_list{1};
    fclose(fid);
    num_scores = size(score_names, 1);
    score_types = repmat({'continuous'}, 1, num_scores);
    y2_in = CBIG_read_y_from_csv({subcsv_y2}, 'src_subject_id', score_names, score_types, ...
        subtxt, fullfile(outdir, ymat_y2), ',');
else
    fprintf('Using existing Y2 behavioral file.\n');
    y2_temp = load(fullfile(outdir, ymat_y2));
    y2_in = y2_temp.y;
end

%% generate Y2 covariate matrix
fprintf('[5] Generating Y2 covariate matrix...\n');
if ~exist(fullfile(outdir, covmat_y2), 'file')
    fid = fopen(covtxt_y2, 'r');
    cov_list = textscan(fid, '%s');
    cov_names = cov_list{1};
    fclose(fid);
    y2_regressors = CBIG_generate_covariates_from_csv({subcsv_y2}, 'src_subject_id', cov_names, ...
        cov_types_y2, subtxt, 'none', 'none', fullfile(outdir, covmat_y2), ',');
else
    fprintf('Using existing Y2 covariate file.\n');
    cov2_temp = load(fullfile(outdir, covmat_y2));
    y2_regressors = cov2_temp.covariates;
end

%% run cross-validated covariate regression
fprintf('[6] Running cross-validated covariate regression...\n');
CBIG_LBC_crossvalid_regress_covariates_Y2(y0_in, y2_in, y0_regressors, y2_regressors, ...
    sub_fold, outdir, outstem);

fprintf('[Done]\n');

%% clean up
rmpath(script_dir);
rmpath(genpath(fullfile(repo_root, 'util', 'stats')));
end
