function CBIG_LBC_compute_FC_change_std(REPO_ROOT, LBC_rep_dir, cog_csv_path, save_resid_path, save_std_path)
% CBIG_LBC_compute_FC_change_std(REPO_ROOT, LBC_rep_dir, cog_csv_path, save_resid_path, save_std_path)
%
% Regress out nuisance variables (baseline age, age interval, sex, motion)
% from individual-level FC changes, then calculate standard deviation across
% subjects for the full cohort and sex-stratified groups.
%
% Input:
%     - REPO_ROOT: (string)
%           Path to repo root (Xie2025_LBC directory).
%
%     - LBC_rep_dir: (string)
%           Path to replication directory containing 'Data/SubID_final.txt'
%           and per-subject 'FC_change/<subID>/FC_diff.mat' files.
%
%     - cog_csv_path: (string)
%           Full path to DemoCog_change.csv with demographic and motion covariates.
%
%     - save_resid_path: (string)
%           Output path to save residual matrices (.mat, variables: FCChange_resid,
%           FCChange_resid_F, FCChange_resid_M).
%
%     - save_std_path: (string)
%           Output path to save standard deviation vectors (.mat, variables:
%           FC_diff_Std, FC_diff_Std_F, FC_diff_Std_M).
%
% Output:
%     - .mat files saved to save_resid_path and save_std_path.
%
% Example:
%     CBIG_LBC_compute_FC_change_std('/path/to/Xie2025_LBC', '/path/to/rep', ...
%         'DemoCog_change.csv', 'FC_resid.mat', 'FC_std.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

addpath(genpath(fullfile(REPO_ROOT, 'util')));

%% Load subject list and stack FC change matrices
SubID = CBIG_text2cell(fullfile(LBC_rep_dir, 'Data', 'SubID_final.txt'));
SubID = strrep(SubID, 'NDAR_', 'NDAR');

FC_diff_z = zeros(length(SubID), 87571);
for counter = 1:length(SubID)
    load(fullfile(LBC_rep_dir, 'FC_change', SubID{counter}, 'FC_diff.mat'));
    FC_diff_z(counter, :) = squareform(FC_diff.z);
end

%% Load covariates
CogChange = readtable(cog_csv_path);

Age_Y0       = CogChange{:, 12};
Age_interval = CogChange{:, 13};
sex          = CogChange{:, 7};
sex_dummy    = zeros(size(sex));
sex_dummy(strcmp(sex, 'F')) = 1;
sex_dummy(strcmp(sex, 'M')) = 0;
MeanFD_Y0    = CogChange.MeanFD_Y0;
MeanFD_Y2    = CogChange.MeanFD_Y2;

regressors = [Age_Y0, Age_interval, sex_dummy, MeanFD_Y0, MeanFD_Y2];

%% Regress out covariates and extract residuals
FCChange_resid = zeros(size(FC_diff_z));
for counter = 1:size(FC_diff_z, 2)
    LM = fitlm(regressors, FC_diff_z(:, counter));
    FCChange_resid(:, counter) = LM.Residuals.Raw + LM.Coefficients.Estimate(1);
end

%% Compute standard deviation across subjects
FC_diff_Std     = std(FCChange_resid,                        0, 1);
FCChange_resid_F = FCChange_resid(sex_dummy == 1, :);
FCChange_resid_M = FCChange_resid(sex_dummy == 0, :);
FC_diff_Std_F   = std(FCChange_resid_F, 0, 1);
FC_diff_Std_M   = std(FCChange_resid_M, 0, 1);

%% Save results
save(save_resid_path, 'FCChange_resid', 'FCChange_resid_F', 'FCChange_resid_M', '-v7.3');
save(save_std_path,   'FC_diff_Std',    'FC_diff_Std_F',    'FC_diff_Std_M',    '-v7.3');

fprintf('Saved residuals to:  %s\n', save_resid_path);
fprintf('Saved std to:        %s\n', save_std_path);

rmpath(genpath(fullfile(REPO_ROOT, 'util')));

end
