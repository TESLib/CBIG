function CBIG_LBC_KRR_example_wrapper(out_dir)

% CBIG_LBC_KRR_example_wrapper(out_dir)
%
% This function generates the KRR results for the example in Xie2025_LBC.
% This example uses simulated data.
%
% Input:
%  - out_dir
%    A path where the results of the example will be saved.
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

% define directories and set up dependencies
parent_dir = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', ...
    'Xie2025_LBC', 'examples');
input_dir = fullfile(parent_dir, 'example_data', 'sim_data');

% load input
load(fullfile(input_dir, 'no_relative_2_fold_sub_list.mat'))
load(fullfile(input_dir, 'y.mat'))
load(fullfile(input_dir, 'covariates.mat'))
load(fullfile(input_dir, 'RSFC.mat'))

% prepare param for KRR
param.sub_fold = sub_fold;
param.y = y;
param.feature_mat = corr_mat;
param.covariates = covariates;
param.num_inner_folds = 5;
param.outdir = out_dir;
param.outstem = '2cog';
param.with_bias = 1;
param.ker_param.type = 'corr';
param.ker_param.scale = nan;
param.lambda_set = [0 0.01 0.1 1 10 100 1000];
param.threshold_set = nan;
param.metric = 'corr';
param.cov_X = [];

% create outdir
if(exist(param.outdir, 'dir'))
    rmdir(param.outdir, 's')
end
mkdir(param.outdir)
save(fullfile(param.outdir, 'setup.mat'), '-struct', 'param')

% call the KRR workflow function
CBIG_KRR_workflow_LITE( fullfile(param.outdir, 'setup.mat') )
end
