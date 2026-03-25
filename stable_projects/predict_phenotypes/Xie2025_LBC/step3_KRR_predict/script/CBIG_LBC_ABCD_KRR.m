function CBIG_LBC_ABCD_KRR(sites, innerFolds, feature_path, featurebase, outdir, ...
    subtxt, subcsv, predvar, covtxt, ymat, covmat, cov_types, keep_fsm)
% CBIG_LBC_ABCD_KRR(sites, innerFolds, feature_path, featurebase, outdir,
%     subtxt, subcsv, predvar, covtxt, ymat, covmat, cov_types, keep_fsm)
%
% Prepare input parameters and run the single-kernel ridge regression (KRR)
% leave-p-out workflow for predicting cognitive measures from FC.
%
% Input:
%     - sites: (scalar)
%           Number of sites used in each test fold for leave-p-out CV.
%
%     - innerFolds: (scalar)
%           Number of inner-loop cross-validation folds.
%
%     - feature_path: (string)
%           Full path (without .mat extension) to the feature file. The .mat
%           file must contain a variable named featurebase of size
%           (#features x #subjects).
%
%     - featurebase: (string)
%           Variable name for the feature matrix inside feature_path.mat.
%           Output folder will be named 'KRR_<featurebase>'.
%
%     - outdir: (string)
%           Full path of output directory where 'KRR_<featurebase>' will be created.
%
%     - subtxt: (string)
%           Full path to the subject ID list (one ID per line).
%
%     - subcsv: (string)
%           Full path to CSV file containing behavioral data and covariates.
%
%     - predvar: (string)
%           Full path to a text file listing behavioral measure names to predict
%           (one name per line; must appear as headers in subcsv).
%
%     - covtxt: (string)
%           Full path to a text file listing covariate names (one per line;
%           must appear as headers in subcsv).
%
%     - ymat: (string)
%           Filename for the output behavioral variable .mat file.
%
%     - covmat: (string)
%           Filename for the output covariate .mat file.
%
%     - cov_types: (cell array of strings)
%           Type of each covariate in covtxt, in order. Each entry must be
%           'continuous' or 'categorical'.
%           e.g., {'continuous', 'categorical', 'continuous'}
%
% Optional input:
%     - keep_fsm: (scalar, default = 0)
%           If 1, copy FSM_innerloop and FSM_test kernel folders to outdir.
%           These are large (~15 GB); set to 0 to delete after copying results.
%
% Output:
%     - KRR results saved under [outdir]/KRR_<featurebase>/results/.
%
% Example:
%     CBIG_LBC_ABCD_KRR(3, 10, '/path/FC_final_Y0', 'FC_final_Y0', '/path/out', ...
%         'sub_list.txt', 'demo.csv', 'predvar.txt', 'cov.txt', ...
%         'y.mat', 'cov.mat', {'continuous','categorical','continuous'}, 0)
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

if nargin < 13 || isempty(keep_fsm)
    keep_fsm = 0;
end

%% add utility path
script_dir = fileparts(mfilename('fullpath'));         % Get directory of this script
repo_root = fileparts(fileparts(script_dir));         % Go up 2 levels to reach Xie2025_LBC

addpath(genpath(fullfile(repo_root,'util','stats')));

%% format params that are read in
% folds
num_sites = sites;
param.num_inner_folds = innerFolds;
% feature details
outstem = convertStringsToChars(strcat("KRR_", featurebase));
feature_name = featurebase;
param.outstem = outstem;
param.outdir = fullfile(outdir, outstem, 'results');
% subject details
sub_txt = subtxt;
sub_csv = {subcsv};
pred_var_txt = predvar;
cov_txt = covtxt;
y_mat = ymat;
cov_mat = covmat;
% regression settings
lambda_set = [ 0 0.00001 0.0001 0.001 0.004 0.007 0.01 0.04 0.07 0.1 0.4 0.7 1 1.5 2 2.5 3 3.5 4 5 10 15 20];
param.with_bias = 1;
param.ker_param.type = 'corr';
param.ker_param.scale = NaN;
param.lambda_set = lambda_set;
param.threshold_set = [];
param.cov_X = [];
param.metric = 'predictive_COD';

%% get subfold
fprintf('[1] Generate subfold... \n')

% generate folds
fold_mat = 'no_relative_3_fold_sub_list.mat';
if ~exist(fullfile(outdir, fold_mat))
    sub_fold = CBIG_LBC_ABCD_LpOCV_split( sub_txt, sub_csv{1}, ...
        'src_subject_id', 'SiteCluster', num_sites, outdir, ',' );
else
    fprintf('Using existing sub_fold file \n')
    fold_temp = load(fullfile(outdir,fold_mat));
    sub_fold = fold_temp.sub_fold;
end
param.sub_fold  = sub_fold;

%% generate y matrix
fprintf('[2] Generate y matrix... \n')

if ~exist(fullfile(outdir, y_mat))
    % get names of tasks to predict
    fid = fopen(pred_var_txt,'r'); % variable names text file
    score_list = textscan(fid,'%s');
    score_names = score_list{1};
    fclose(fid);
    num_scores = size(score_names,1);
    % generate y
    score_types = cell(1,num_scores); % define score types
    score_types(:) = {'continuous'};
    y = CBIG_read_y_from_csv(sub_csv, 'src_subject_id', score_names, score_types,...
        sub_txt, fullfile(outdir, y_mat), ',');
else
    fprintf('Using existing y file \n')
    y_temp = load(fullfile(outdir,y_mat));
    y = y_temp.y;
end
param.y = y;

%% generate covariate matrix
fprintf('[3] Generate covariate matrix... \n')
if ~exist(fullfile(outdir,cov_mat))
    % get covariate names
    fid = fopen(cov_txt,'r'); % covariate names text file
    cov_list = textscan(fid,'%s');
    cov_names = cov_list{1};
    fclose(fid);
    % validate cov_types length matches cov_names
    if length(cov_types) ~= length(cov_names)
        error('cov_types has %d entries but covtxt has %d covariates.', ...
            length(cov_types), length(cov_names));
    end
    cov = CBIG_generate_covariates_from_csv(sub_csv, 'src_subject_id', cov_names, cov_types, ...
        sub_txt, 'none', 'none', fullfile(outdir,cov_mat), ',');
else
    fprintf('Using existing covariate file \n')
    cov_temp = load(fullfile(outdir, cov_mat));
    cov = cov_temp.covariates;
end
param.covariates = cov;

%% set other params for setup
fprintf('[4] Loading features... \n')
% load features
features = load(strcat(feature_path ,'.mat'));
param.feature_mat = features.(feature_name);

%% KRR workflow
fprintf('[5] Run KRR workflow...\n')

% Use local node scratch for kernel files to avoid NAS I/O contention
% when multiple jobs run in parallel. Kernel matrices are large (~15GB
% per job) and are only needed during computation, not as final outputs.
% Include a hash of outdir to prevent collisions when jobs with the same
% feature file (same outstem) land on the same compute node.
nas_results_dir = fullfile(outdir, outstem, 'results');
outdir_hash     = dec2hex(sum(double(outdir)), 8);
local_scratch    = fullfile(tempdir, [outstem '_' outdir_hash], 'results');
mkdir(local_scratch);
param.outdir = local_scratch;

CBIG_KRR_workflow(param);

% Copy results (excluding large kernel matrices) back to NAS
fprintf('[6] Copying results to NAS...\n')
mkdir(nas_results_dir);
result_subdirs = {'y', 'innerloop_cv', 'test_cv'};
if keep_fsm
    result_subdirs = [result_subdirs, {'FSM_innerloop', 'FSM_test'}];
end
for d = 1:length(result_subdirs)
    src = fullfile(local_scratch, result_subdirs{d});
    if exist(src, 'dir')
        copyfile(src, fullfile(nas_results_dir, result_subdirs{d}));
    end
end
% copy final result and setup mat files
for f = dir(fullfile(local_scratch, '*.mat'))'
    copyfile(fullfile(local_scratch, f.name), nas_results_dir);
end

% Clean up local scratch
rmdir(local_scratch, 's');
fprintf('[6] Done.\n')

% remove utility path
rmpath(genpath(fullfile(repo_root,'util','stats')));
end
