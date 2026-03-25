function CBIG_LBC_compute_cog_change_std_sex_stratify(cogY0_path, ...
                                                       CogChange_path, ...
                                                       resid_mat_path_F, ...
                                                       std_mat_path_F, ...
                                                       resid_mat_path_M, ...
                                                       std_mat_path_M)
% CBIG_LBC_compute_cog_change_std_sex_stratify(cogY0_path, CogChange_path,
%     resid_mat_path_F, std_mat_path_F, resid_mat_path_M, std_mat_path_M)
%
% Regress out covariates from cognitive change scores, compute residuals and
% standard deviation, then split by sex and save separately.
%
% Input:
%     - cogY0_path: (string)
%           Full path to cogY0 harmonized .csv file.
%
%     - CogChange_path: (string)
%           Full path to CogChange harmonized .csv file.
%
%     - resid_mat_path_F: (string)
%           Full path to save female residual matrix (.mat, variable: CogChange_resid_F).
%
%     - std_mat_path_F: (string)
%           Full path to save female std vector (.mat, variable: cog_change_std).
%
%     - resid_mat_path_M: (string)
%           Full path to save male residual matrix (.mat, variable: CogChange_resid_M).
%
%     - std_mat_path_M: (string)
%           Full path to save male std vector (.mat, variable: cog_change_std).
%
% Output:
%     - .mat files saved to resid_mat_path_F, std_mat_path_F, resid_mat_path_M,
%       and std_mat_path_M.
%
% Example:
%     CBIG_LBC_compute_cog_change_std_sex_stratify('cogY0.csv', 'CogChange.csv', ...
%         'resid_F.mat', 'std_F.mat', 'resid_M.mat', 'std_M.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

%% Load data
cog_change = readtable(CogChange_path);
cog_change_score = cog_change{:, 15:22};
age_y0       = cog_change{:, 12};
age_interval = cog_change{:, 13};
sex          = cog_change{:, 7};
sex_dummy    = zeros(size(sex));
sex_dummy(strcmp(sex, 'F')) = 1;
sex_dummy(strcmp(sex, 'M')) = 0;
regressors = [age_y0, age_interval, sex_dummy];

n_subjects = size(cog_change_score, 1);
cog_change_resid = zeros(n_subjects, 8);

%% Regress out covariates and compute adjusted residuals
for i = 1:8
    lm = fitlm(regressors, cog_change_score(:, i));
    cog_change_resid(:, i) = lm.Residuals.Raw + lm.Coefficients.Estimate(1);
end

CogMeasures_Y0 = readtable(cogY0_path);
CogY0 = CogMeasures_Y0{:, 15:22};
CogY0_std = std(CogY0);
cog_change_resid_z = cog_change_resid ./ repmat(CogY0_std, length(cog_change_resid), 1);

%% Split by sex
CogChange_resid_F = cog_change_resid_z(sex_dummy == 1, :);
CogChange_resid_M = cog_change_resid_z(sex_dummy == 0, :);

%% Save female results
save(resid_mat_path_F, 'CogChange_resid_F');
cog_change_std = std(CogChange_resid_F);
save(std_mat_path_F, 'cog_change_std');

%% Save male results
save(resid_mat_path_M, 'CogChange_resid_M');
cog_change_std = std(CogChange_resid_M);
save(std_mat_path_M, 'cog_change_std');
end
